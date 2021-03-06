% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/PLNfamily-class.R
\name{plot.PLNfamily}
\alias{plot.PLNfamily}
\title{Display the criteria associated with a collection of PLN fits (a PLNfamily)}
\usage{
\method{plot}{PLNfamily}(x, criteria = c("loglik", "BIC", "ICL"), ...)
}
\arguments{
\item{x}{an R6 object with class PLNfamily}

\item{criteria}{vector of characters. The criteria to plot in c("loglik", "BIC", "ICL", "R_squared", "EBIC", "pen_loglik")}

\item{...}{additional parameters for S3 compatibility. Not used
The two last are only available por PLNnetworkfamily. Default is c("loglik", "BIC", "ICL")}
}
\value{
Produces a plot  representing the evolution of the criteria of the different models considered,
highlighting the best model in terms of ICL for PLNPCA and EBIC for PLNnetwork.
}
\description{
Display the criteria associated with a collection of PLN fits (a PLNfamily)
}
