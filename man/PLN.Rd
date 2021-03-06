% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/PLN.R
\name{PLN}
\alias{PLN}
\title{Poisson lognormal model}
\usage{
PLN(formula, data, subset, weights, control = list())
}
\arguments{
\item{formula}{an object of class "formula": a symbolic description of the model to be fitted.}

\item{data}{an optional data frame, list or environment (or object coercible by as.data.frame to a data frame) containing the variables in the model. If not found in data, the variables are taken from environment(formula), typically the environment from which lm is called.}

\item{subset}{an optional vector specifying a subset of observations to be used in the fitting process.}

\item{weights}{an optional vector of weights to be used in the fitting process. Should be NULL or a numeric vector.}

\item{control}{a list for controlling the optimization. See details.}
}
\value{
an R6 object with class \code{\link[=PLNfit]{PLNfit}}
}
\description{
Fit the Poisson lognormal with a variational algorithm. Use the (g)lm syntax for model specification (covariates, offsets).
}
\details{
The parameter \code{control} is a list controlling the optimization with the following entries
\itemize{
 \item{"covariance"}{character setting the model for the covariance matrix. Either "full", "diagonal" or "spherical". Default is "full".}
 \item{"trace"}{integer for verbosity.}
 \item{"inception"}{Set up the intialization. By default, the model is initialized with a multivariate linear model applied on log-transformed data. However, the user can provide a PLNfit (typically obtained from a previsous fit), which often speed up the inference.}
 \item{"ftol_rel"}{stop when an optimization step changes the objective function by less than ftol multiplied by the absolute value of the parameter. Default is 1e-6 when n < p, 1e-8 otherwise.}
 \item{"ftol_abs"}{stop when an optimization step changes the objective function by less than ftol multiplied by the absolute value of the parameter. Default is 0}
 \item{"xtol_rel"}{stop when an optimization step changes every parameters by less than xtol multiplied by the absolute value of the parameter. Default is 1e-4}
 \item{"xtol_abs"}{stop when an optimization step changes every parameters by less than xtol multiplied by the absolute value of the parameter. Default is 1e-4}
 \item{"lower_bound"}{the lower bound (box constraint) for the variational variance parameters. Default is 1e-4.}
 \item{"maxeval"}{stop when the number of iteration exceeds maxeval. Default is 10000}
 \item{"maxtime"}{stop when the optimization time (in seconds) exceeds maxtime. Default is -1 (no restriction)}
 \item{"algorithm"}{the optimization method used by NLOPT among LD type, i.e. "CCSAQ", "MMA", "LBFGS",
    "TNEWTON", "TNEWTON_RESTART", "TNEWTON_PRECOND", "TNEWTON_PRECOND_RESTART",
    "TNEWTON_VAR1", "TNEWTON_VAR2". See NLOPT documentation for further details. Default is "CCSAQ".}
}
}
\examples{
data(trichoptera)
myPLN <- PLN(Abundance ~ 1, data = trichoptera)
}
\seealso{
The class  \code{\link[=PLNfit]{PLNfit}}
}
