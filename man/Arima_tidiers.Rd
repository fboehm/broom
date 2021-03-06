% Generated by roxygen2 (4.0.2): do not edit by hand
\name{Arima_tidiers}
\alias{Arima_tidiers}
\alias{glance.Arima}
\alias{tidy.Arima}
\title{Tidying methods for ARIMA modeling of time series}
\usage{
\method{tidy}{Arima}(x, conf.int = FALSE, conf.level = 0.95, ...)

\method{glance}{Arima}(x, ...)
}
\arguments{
\item{x}{An object of class "Arima"}

\item{conf.int}{whether to include a confidence interval}

\item{conf.level}{confidence level of the interval, used only if
\code{conf.int=TRUE}}

\item{...}{extra arguments (not used)}
}
\value{
All tidying methods return a data.frame without rownames, whose
structure depends on the method chosen.

\code{tidy} returns one row for each coefficient in the model,
with five columns:
  \item{term}{The term in the nonlinear model being estimated and tested}
  \item{estimate}{The estimated coefficient}
  \item{std.error}{The standard error from the linear model}

If \code{conf.int = TRUE}, also returns
  \item{conf.low}{low end of confidence interval}
  \item{conf.high}{high end of confidence interval}

\code{glance} returns one row with the columns
  \item{sigma}{the square root of the estimated residual variance}
  \item{logLik}{the data's log-likelihood under the model}
  \item{AIC}{the Akaike Information Criterion}
  \item{BIC}{the Bayesian Information Criterion}
}
\description{
These methods tidy the coefficients of ARIMA models of univariate time
series.
}
\details{
\code{augment} is not currently implemented, as it is not clear
whether ARIMA predictions can or should be merged with the original
data frame.
}
\examples{
fit <- arima(lh, order = c(1, 0, 0))
tidy(fit)
glance(fit)
}
\seealso{
\link{arima}
}

