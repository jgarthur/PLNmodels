% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/PLNmodels-package.R
\docType{package}
\name{PLNmodels}
\alias{PLNmodels}
\alias{PLNmodels-package}
\title{PLNmodels}
\description{
The Poisson lognormal model and variants can be used for a variety of multivariate problems when count data are at play (including
PCA or LDA for count data, network inference). This package implements efficients
variational algorithms to fit such models accompanied with a set of functions for vizualisation and diagnostic.
}
\section{Unpenalized Poisson lognormal model (aka PLN)}{


See the main function \code{\link{PLN}} and the associated methods for manipulation.

Also try vignette("PLN_trichoptera", package="PLNmodels") for an overview.
}

\section{Rank Contraint Poisson lognormal for Poisson Principal Component Analysis (ala PLNPCA)}{


See the main function \code{\link{PLNPCA}} and the associated methods for manipulation.

The Poisson PCA and the associated variational inference is fully explained in CHiquet el al (2018), see reference below.

Also try vignette("PLNPCA_trichoptera", package="PLNmodels") for an overview.
}

\section{Sparse Poisson lognormal model for sparse covariance inference for counts (aka PLNnetwork)}{


See the main function \code{\link{PLNnetwork}} and the associated methods for manipulation.

Also try vignette("PLNnetwork_trichoptera", package="PLNmodels") for an overview.
}

\section{Poisson lognormal discriminant analysis (aka PLNLDA)}{


See the main function \code{\link{PLNLDA}} and the associated methods for manipulation.

Also try vignette("PLNLDA_trichoptera", package="PLNmodels") for an overview.
}

\references{
Julien Chiquet, Mahendra Mariadassou and Stéphane Robin. Variational inference for probabilistic Poisson PCA, to appear in the Annals of Applied Statistics <https://arxiv.org/abs/1703.06633>
}
\author{
Julien Chiquet \email{julien.chiquet@inra.fr}

Mahendra Mariadassou \email{mahendra.mariadassou@inra.fr}

Stéphane Robin \email{stephane.robin@inra.fr}
}
