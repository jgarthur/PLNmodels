#' An R6 Class to represent a PLNfit in a standard, general framework
#'
#' @description The function \code{\link{PLN}} produces a collection of models which are instances of object with class \code{PLNfit}.
#' Objects produced by the functions \code{\link{PLNnetwork}}, \code{\link{PLNPCA}} and \code{\link{PLNLDA}} also enjoy the method of \code{\link{PLNfit}}
#' by inheritance.
#'
#' This class comes with a set of methods, some of them being useful for the user: plot_model, plot_variational_par
#'
#' Fields are accessed via active binding and cannot be changed by the user.
#'
#' @field model_par a list with two matrices, B and Theta, which are the estimated parameters of the pPCA model
#' @field var_par a list with two matrices, M and S, which are the estimated parameters in the variational approximation
#' @field optim_par a list with parameters useful for monitoring the optimization
#' @field model character: the model used for the coavariance (either "spherical", "diagonal" or "full")
#' @field loglik variational lower bound of the loglikelihood
#' @field loglik_vec element-wise variational lower bound of the loglikelihood
#' @field BIC variational lower bound of the BIC
#' @field ICL variational lower bound of the ICL
#' @field R_squared approximated goodness-of-fit criterion
#' @field degrees_freedom number of parameters in the current PLN model
#' @field criteria a vector with loglik, BIC, ICL, R_squared and degrees of freedom
#' @include PLNfit-class.R
#' @importFrom R6 R6Class
#' @importFrom corrplot corrplot
PLNfit <-
   R6Class(classname = "PLNfit",
    public = list(
      ## constructor: function initialize, see below
      ## "setter" function
      update = function(Theta=NA, Sigma=NA, M=NA, S=NA, J=NA, Ji=NA, R2=NA, monitoring=NA) {
        if (!anyNA(Theta))      private$Theta  <- Theta
        if (!anyNA(Sigma))      private$Sigma  <- Sigma
        if (!anyNA(M))          private$M      <- M
        if (!anyNA(S))          private$S      <- S
        if (!anyNA(J))          private$J      <- J
        if (!anyNA(Ji))         private$Ji     <- Ji
        if (!anyNA(R2))         private$R2     <- R2
        if (!anyNA(monitoring)) private$monitoring <- monitoring
      }
    ),
    private = list(
      Theta      = NA, # the model parameters for the covariable
      Sigma      = NA, # the covariance matrix
      S          = NA, # the variational parameters for the variances
      M          = NA, # the variational parameters for the means
      R2         = NA, # approximated goodness of fit criterion
      J          = NA, # approximated weighted loglikelihood
      Ji         = NA, # element-wise approximated loglikelihood
      covariance = NA, # a string describing the covariance model
      monitoring = NA  # a list with optimization monitoring quantities
    ),
    ## use active bindings to access private members like fields
    active = list(
      n = function() {nrow(private$M)},
      q = function() {ncol(private$M)},
      p = function() {nrow(private$Theta)},
      d = function() {ncol(private$Theta)},
      ## model_par and var_par allow write access for bootstrapping purposes
      model_par = function(value) {
        if (!missing(value)) {
          if (is.list(value) & all(names(value) %in% c("Sigma", "Theta"))) {
            if (nrow(value$Theta) == self$p & ncol(value$Theta) == self$d) {
              private$Theta <- value$Theta
            }
            if (nrow(value$Sigma) == self$q & ncol(value$Sigma) == self$q) {
              private$Sigma <- value$Sigma
            }
          }
        }
        list(Theta = private$Theta, Sigma = private$Sigma)
      },
      var_par   = function(value) {
        if (!missing(value)) {
          if (is.list(value) & all(names(value) %in% c("S", "M"))) {
            if ((private$covariance == "spherical" & nrow(value$S) == self$n & ncol(value$S) == 1) |
                (private$covariance != "spherical" & nrow(value$S) == self$n & ncol(value$S) == self$q) ) {
              private$S <- value$S
            }
            if (nrow(value$M) == self$n & ncol(value$M) == self$q) {
              private$M <- value$M
            }
          }
        }
        list(M = private$M, S = private$S)
      },
      degrees_freedom = function() {self$p * self$d + switch(private$covariance, "full" = self$p * (self$p + 1)/2, "diagonal" = self$p, "spherical" = 1)},
      model      = function() {private$covariance},
      optim_par  = function() {private$monitoring},
      loglik     = function() {private$J },
      loglik_vec = function() {private$Ji},
      BIC        = function() {self$loglik - .5 * log(self$n) * self$degrees_freedom},
      entropy    = function() {.5 * (self$n * self$q * log(2*pi*exp(1)) + sum(log(private$S)) * ifelse(private$covariance == "spherical", self$q, 1))},
      ICL        = function() {self$BIC - self$entropy},
      R_squared  = function() {private$R2},
      criteria   = function() {c(degrees_freedom = self$degrees_freedom, loglik = self$loglik, BIC = self$BIC, ICL = self$ICL, R_squared = self$R_squared)}
    )
  )

## ----------------------------------------------------------------------
## PUBLIC METHODS FOR INTERNAL USE
## ----------------------------------------------------------------------

## an S3 function to check if an object is a PLNfit
isPLNfit <- function(Robject) { inherits(Robject, "PLNfit") }

## The PLN constructor either adjusts a log(transform) linear model to initialize its fields
## or take a user defined PLN model.
#' @importFrom stats lm.wfit lm.fit poisson residuals coefficients runif
PLNfit$set("public", "initialize",
function(responses, covariates, offsets, weights, control) {

  ## problem dimensions
  n <- nrow(responses); p <- ncol(responses); d <- ncol(covariates)

  ## initialize the covariance model
  private$covariance <- control$covariance

  if (isPLNfit(control$inception)) {
    if (control$trace > 1) cat("\n User defined inceptive PLN model")
    stopifnot(isTRUE(all.equal(dim(control$inception$model_par$Theta), c(p,d))))
    stopifnot(isTRUE(all.equal(dim(control$inception$var_par$M)      , c(n,p))))
    private$Theta <- control$inception$model_par$Theta
    private$M     <- control$inception$var_par$M
    private$S     <- control$inception$var_par$S
    private$Sigma <- control$inception$model_par$Sigma
    private$J     <- control$inception$loglik
    private$Ji    <- control$inception$loglik_vec
  } else {
    if (control$trace > 1) cat("\n Use LM after log transformation to define the inceptive model")
    LMs   <- lapply(1:p, function(j) lm.wfit(covariates, log(1 + responses[,j]), weights, offset =  offsets[,j]) )
    private$Theta <- do.call(rbind, lapply(LMs, coefficients))
    private$M     <- do.call(cbind, lapply(LMs, residuals))
    private$S     <- matrix(10 * max(control$lower_bound), n, ifelse(control$covariance == "spherical", 1, p))
    if (control$covariance == "spherical") {
      private$Sigma <- diag(crossprod(private$M)/n)
    } else  {
      private$Sigma <- crossprod(private$M)/n + diag(colMeans(private$S))
    }
  }

})

## Call to the C++ optimizer and update of the relevant fields
PLNfit$set("public", "optimize",
function(responses, covariates, offsets, weights, control) {

  optim_out <- optimization_PLN(
    unlist(c(private$Theta, private$M, private$S)),
    responses,
    covariates,
    offsets,
    weights,
    control
  )
  optim_out$message <- statusToMessage(optim_out$status)

  self$update(
    Theta      = optim_out$Theta,
    Sigma      = optim_out$Sigma,
    M          = optim_out$M,
    S          = optim_out$S,
    J          = sum(weights * optim_out$loglik),
    Ji         = optim_out$loglik,
    monitoring = list(
      iterations = optim_out$iterations,
      status     = optim_out$status,
      message    = statusToMessage(optim_out$status))
  )
})

PLNfit$set("public", "set_R2",
function(responses, covariates, offsets, weights) {
  loglik <- logLikPoisson(responses, self$latent_pos(covariates, offsets), weights)
  lmin   <- logLikPoisson(responses, nullModelPoisson(responses, covariates, offsets, weights))
  lmax   <- logLikPoisson(responses, fullModelPoisson(responses, weights))
  private$R2 <- (loglik - lmin) / (lmax - lmin)
})

PLNfit$set("public", "postTreatment",
function(responses, covariates, offsets, weights = rep(1, nrow(responses))) {
  ## compute R2
  self$set_R2(responses, covariates, offsets, weights)
  ## Set the name of the matrices according to those of the data matrices
  rownames(private$Theta) <- colnames(responses)
  colnames(private$Theta) <- colnames(covariates)
  rownames(private$Sigma) <- colnames(private$Sigma) <- colnames(responses)
  rownames(private$M) <- rownames(private$S) <- rownames(responses)
})

#' Positions in the (Euclidian) parameter space, noted as Z in the model. Used to compute the likelihood.
#'
#' @name PLNfit_latent_pos
#'
#' @param covariates a matrix of covariates. Will usually be extracted from the corresponding field in PLNfamily-class
#' @param offsets    a matrix of offsets. Will usually be extracted from the corresponding field in PLNfamily-class
#'
PLNfit$set("public", "latent_pos",
function(covariates, offsets) {
  latentPos <- private$M + tcrossprod(covariates, private$Theta) + offsets
  latentPos
})

#' Result of the VE step of the optimization procedure: optimal variational parameters (M, S)
#' and corresponding log likelihood values of new observations for fixed model parameters (Sigma, Theta)
#'
#' @name PLNfit_VEstep
#'
#' @param newdata A data frame in which to look for covariates.
#' @param newOffsets A matrix in which to look for offsets.
#' @param newCounts A matrix in which to look for counts.
#' @param control a list for controlling the optimization. See \code{\link[=PLN]{PLN}} for details.
#' @return A list with three components:
#'            the matrix M of variational means,
#'            the matrix S of variational variances
#'            the vector log.lik of (variational) log-likelihood of each new observation
#'
PLNfit$set("public", "VEstep",
function(newdata, newOffsets, newCounts, control = list()) {
  ## ===========================================
  ## OPTIMIZATION
  ##

  ## TODO
  ## Handle weigths in the model !!!
  ## Handle missing offsets and covariates

  ## Problem dimension
  n <- nrow(newCounts); p <- ncol(newCounts); d <- ncol(newdata)

  ## define default control parameters for optim and overwrite by user defined parameters
  control$covariance <- self$model
  ctrl <- PLN_param_VE(control, self$n, self$p, self$d)

  ## TODO Handle covariance model
  ## get an initial point for optimization
  M <- matrix(0, n, p)
  S <- switch(control$covariance,
              "full"      = matrix(10 * max(ctrl$lower_bound), n, p),
              "diagonal"  = matrix(10 * max(ctrl$lower_bound), n, p),
              "spherical" = matrix(10 * max(ctrl$lower_bound), n, 1))

  par0 <- c(M, S)

  optim.out <- optimization_VEstep_PLN(
    par0,
    newCounts, newdata, newOffsets,
    self$model_par$Theta, self$model_par$Sigma,
    ctrl
  )

  ## ===========================================
  ## POST-TREATMENT
  ##
  optim.out$message <- statusToMessage(optim.out$status)

  M <- optim.out$M
  S <- optim.out$S

  rownames(M) <- rownames(S) <- rownames(newdata)
  colnames(M) <- colnames(newCounts)

  log.lik <- optim.out$loglik
  names(log.lik) <- rownames(newdata)

  return(list(M       = M,
              S       = S,
              log.lik = log.lik))
})

## ----------------------------------------------------------------------
## PUBLIC METHODS FOR THE USERS
## ----------------------------------------------------------------------
## For each R6 method I define an S3 method and only document the latter

#' Predict counts of a new sample
#'
#' @name predict.PLNfit
#'
#' @param object an R6 object with class PLNfit
#' @param newdata A data frame in which to look for variables with which to predict.
#' @param newOffsets A matrix in which to look for offsets with which to predict.
#' @param type The type of prediction required. The default is on the scale of the linear predictors (i.e. log average count);
#'                   the alternative "response" is on the scale of the response variable (i.e. average count)
#' @param ... additional parameters for S3 compatibility. Not used
#' @return A matrix of predicted log-counts (if type = "link") or predicted counts (if type = "response").
#' @export
predict.PLNfit <- function(object, newdata, newOffsets, type = c("link", "response"), ...) {
  stopifnot(isPLNfit(object))
  object$predict(newdata, newOffsets, type)
}

PLNfit$set("public", "predict",
  function(newdata, newOffsets, type = c("link", "response")) {
    type = match.arg(type)
    ## Are matrix conformable?
    stopifnot(ncol(newdata)    == ncol(private$Theta),
              nrow(newdata)    == nrow(newOffsets),
              ncol(newOffsets) == nrow(private$Theta))
    ## Mean latent positions in the parameter space
    EZ <- tcrossprod(newdata, private$Theta) + newOffsets
    results <- switch(type,
                      link     = EZ,
                      response = exp(EZ))
    ## output formatting
    rownames(results) <- rownames(newdata); colnames(results) <- rownames(private$Theta)
    attr(results, "type") <- type
    results
  }
)

#' Extracts model coefficients from objects returned by \code{\link[=PLN]{PLN}} and its variants
#'
#' @name coef.PLNfit
#'
#' @param object an R6 object with class PLNfit
#' @param ... additional parameters for S3 compatibility. Not used
#' @return A matrix of coefficients extracted from the PLNfit model.
#'
#' @export
coef.PLNfit <- function(object, ...) {
  stopifnot(isPLNfit(object))
  object$model_par$Theta
}

#' Display the model parameters of a PLNfit in a matrix fashion
#'
#' @name plot.PLNfit
#'
#' @param x an R6 object with class PLNfit
#' @param type character. Should the variational or the model parameters be plotted? default is "model".
#' @param ... additional parameters for S3 compatibility. Not used
#'
#' @export
plot.PLNfit <- function(x, type=c("model","variational"), ...) {
  stopifnot(isPLNfit(x))
  x$plot(type)
}

PLNfit$set("public", "plot",
  function(type=c("model", "variational")) {
    type <- match.arg(type)
    param <- switch(type,
               "model"       = self$model_par,
               "variational" = self$var_par)
    par1 <- param[[1]]; par2 <- param[[2]]
    rownames(par1) <- rep(" ", nrow(par1)) ; colnames(par1) <- rep(" ", ncol(par1))
    rownames(par2) <- rep(" ", nrow(par2)) ; colnames(par2) <- rep(" ", ncol(par2))

    par(mfrow = c(2,2))
    hist(par1           , breaks = sqrt(nrow(par1)), xlab = "", ylab = "", main = paste0(names(param)[1]))
    hist(par2[par2 != 0], breaks = sqrt(nrow(par2)), xlab = "", ylab = "", main = paste0(names(param)[2]))
    corrplot::corrplot(par1, is.corr = FALSE, method = "color", cl.pos = "n",
                       addgrid=ifelse(type == "model", "grey", NA))
    corrplot::corrplot(par2, is.corr = FALSE, method = "color", cl.pos = "n")
    title(main = paste0("\n",type," parameters"), outer = TRUE)
    par(mfrow = c(1,1))
  }
)

PLNfit$set("public", "show",
function(model = paste("A Poisson Lognormal fit with", self$model, "covariance model.\n")) {
  cat(model)
  cat("==================================================================\n")
  print(as.data.frame(t(self$criteria), row.names = ""))
  cat("==================================================================\n")
  cat("* Useful fields \n")
  cat("  $model_par, $var_par, $optim_par \n")
  cat("  $loglik, $BIC, $ICL, $degrees_freedom, $criteria \n")
  cat("* Useful methods\n")
  cat("    $plot(), $predict()\n")
})

PLNfit$set("public", "print", function() self$show())
