#' An R6 Class to represent a collection of PLNPCAfit
#'
#' @description The function \code{\link{PLNPCA}} produces an instance of this class.
#'
#' This class comes with a set of methods, some of them being useful for the user:
#' See the documentation for \code{\link[=PLNfamily_getBestModel]{getBestModel}},
#' \code{\link[=PLNfamily_getModel]{getModel}}, \code{\link[=plot.PLNfamily]{plot}}
#' and \code{\link[=predict.PLNfit]{predict}}.
#'
#' @field responses the matrix of responses common to every models
#' @field covariates the matrix of covariates common to every models
#' @field offsets the matrix of offsets common to every models
#' @field ranks the dimensions of the successively fitted models
#' @field models a list of \code{\link[=PLNPCAfit]{PLNPCAfit}} object, one per rank.
#' @field inception a \code{\link[=PLNfit]{PLNfit}} object, obtained when full rank is considered.
#' @field criteria a data frame with the value of some criteria (variational lower bound J, BIC, ICL and R2) for the different models.
#' @include PLNfamily-class.R
#' @importFrom R6 R6Class
#' @import ggplot2
#' @seealso The function \code{\link{PLNPCA}}, the class \code{\link[=PLNPCAfit]{PLNPCAfit}}
PLNPCAfamily <-
  R6Class(classname = "PLNPCAfamily",
    inherit = PLNfamily,
     active = list(
      ranks = function() private$params
    )
)

PLNPCAfamily$set("public", "initialize",
  function(ranks, responses, covariates, offsets, weights, control) {

  ## initialize the required fields
  super$initialize(responses, covariates, offsets, weights, control)
  private$params <- ranks

  ## instantiate as many models as ranks
  control$inception <-
  self$models <- lapply(ranks, function(rank){
    model <- PLNPCAfit$new(rank, responses, covariates, offsets, weights, control)
    model
  })

})

PLNPCAfamily$set("public", "optimize",
  function(control) {
    self$models <- mclapply(self$models, function(model) {
    if (control$trace == 1) {
      cat("\t Rank approximation =",model$rank, "\r")
      flush.console()
    }
    if (control$trace > 1) {
      cat(" Rank approximation =",model$rank)
      cat("\n\t conservative convex separable approximation for gradient descent")
    }
    model$optimize(self$responses, self$covariates, self$offsets, self$weights, control)
    model
  }, mc.cores = control$cores, mc.allow.recursive = FALSE)
})

PLNPCAfamily$set("public", "plot",
function(criteria = c("loglik", "BIC", "ICL")) {
  vlines <- sapply(criteria, function(crit) self$getBestModel(crit)$rank)
  p <- super$plot(criteria) + xlab("rank") + geom_vline(xintercept = vlines, linetype = "dashed", alpha = 0.25)
  p
})

PLNPCAfamily$set("public", "show",
function() {
  super$show()
  cat(" Task: Principal Component Analysis\n")
  cat("========================================================\n")
  cat(" - Ranks considered: from", min(self$ranks), "to", max(self$ranks),"\n")
  cat(" - Best model (regarding BIC): rank =", self$getBestModel("BIC")$rank, "- R2 =", round(self$getBestModel("BIC")$R_squared, 2), "\n")
  cat(" - Best model (regarding ICL): rank =", self$getBestModel("ICL")$rank, "- R2 =", round(self$getBestModel("ICL")$R_squared, 2), "\n")
})

PLNPCAfamily$set("public", "print", function() self$show())
