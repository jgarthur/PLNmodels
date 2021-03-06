% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/PLNfit-class.R
\docType{data}
\name{PLNfit}
\alias{PLNfit}
\title{An R6 Class to represent a PLNfit in a standard, general framework}
\format{An object of class \code{R6ClassGenerator} of length 24.}
\usage{
PLNfit
}
\description{
The function \code{\link{PLN}} produces a collection of models which are instances of object with class \code{PLNfit}.
Objects produced by the functions \code{\link{PLNnetwork}}, \code{\link{PLNPCA}} and \code{\link{PLNLDA}} also enjoy the method of \code{\link{PLNfit}}
by inheritance.

This class comes with a set of methods, some of them being useful for the user: plot_model, plot_variational_par

Fields are accessed via active binding and cannot be changed by the user.
}
\section{Fields}{

\describe{
\item{\code{model_par}}{a list with two matrices, B and Theta, which are the estimated parameters of the pPCA model}

\item{\code{var_par}}{a list with two matrices, M and S, which are the estimated parameters in the variational approximation}

\item{\code{optim_par}}{a list with parameters useful for monitoring the optimization}

\item{\code{model}}{character: the model used for the coavariance (either "spherical", "diagonal" or "full")}

\item{\code{loglik}}{variational lower bound of the loglikelihood}

\item{\code{loglik_vec}}{element-wise variational lower bound of the loglikelihood}

\item{\code{BIC}}{variational lower bound of the BIC}

\item{\code{ICL}}{variational lower bound of the ICL}

\item{\code{R_squared}}{approximated goodness-of-fit criterion}

\item{\code{degrees_freedom}}{number of parameters in the current PLN model}

\item{\code{criteria}}{a vector with loglik, BIC, ICL, R_squared and degrees of freedom}
}}

\keyword{datasets}
