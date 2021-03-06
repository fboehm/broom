#' Tidying methods for a linear model
#' 
#' These methods tidy the coefficients of a linear model into a summary,
#' augment the original data with information on the fitted values and
#' residuals, and construct a one-row glance of the model's statistics.
#'
#' @details If you have missing values in your model data, you may need to refit
#' the model with \code{na.action = na.exclude}.
#'
#' @return All tidying methods return a \code{data.frame} without rownames.
#' The structure depends on the method chosen.
#'
#' @seealso \code{\link{summary.lm}}
#'
#' @name lm_tidiers
#' 
#' @param x lm object
#' @param data Original data, defaults to the extracting it from the model
#' @param newdata If provided, performs predictions on the new data
#' @param type.predict Type of prediction to compute for a GLM; passed on to
#'   \code{\link{predict.glm}}
#' @param type.residuals Type of residuals to compute for a GLM; passed on to
#'   \code{\link{residuals.glm}}
#'
#' @examples
#'
#' library(ggplot2)
#' library(dplyr)
#'
#' mod <- lm(mpg ~ wt + qsec, data = mtcars)
#' 
#' tidy(mod)
#' glance(mod)
#' 
#' # coefficient plot
#' d <- tidy(mod) %>% mutate(low = estimate - std.error,
#'                           high = estimate + std.error)
#' ggplot(d, aes(estimate, term, xmin = low, xmax = high, height = 0)) +
#'      geom_point() + geom_vline() + geom_errorbarh()
#' 
#' head(augment(mod))
#' head(augment(mod, mtcars))
#' 
#' # predict on new data
#' newdata <- mtcars %>% head(6) %>% mutate(wt = wt + 1)
#' augment(mod, newdata = newdata)
#'
#' au <- augment(mod, data = mtcars)
#' 
#' plot(mod, which = 1)
#' qplot(.fitted, .resid, data = au) +
#'   geom_hline(yintercept = 0) +
#'   geom_smooth(se = FALSE)
#' qplot(.fitted, .std.resid, data = au) +
#'   geom_hline(yintercept = 0) +
#'   geom_smooth(se = FALSE)
#' qplot(.fitted, .std.resid, data = au,
#'   colour = factor(cyl))
#' qplot(mpg, .std.resid, data = au, colour = factor(cyl))
#'
#' plot(mod, which = 2)
#' qplot(sample =.std.resid, data = au, stat = "qq") +
#'     geom_abline()
#'
#' plot(mod, which = 3)
#' qplot(.fitted, sqrt(abs(.std.resid)), data = au) + geom_smooth(se = FALSE)
#'
#' plot(mod, which = 4)
#' qplot(seq_along(.cooksd), .cooksd, data = au, geom = "bar",
#'  stat="identity")
#'
#' plot(mod, which = 5)
#' qplot(.hat, .std.resid, data = au) + geom_smooth(se = FALSE)
#' ggplot(au, aes(.hat, .std.resid)) +
#'   geom_vline(size = 2, colour = "white", xintercept = 0) +
#'   geom_hline(size = 2, colour = "white", yintercept = 0) +
#'   geom_point() + geom_smooth(se = FALSE)
#'
#' qplot(.hat, .std.resid, data = au, size = .cooksd) +
#'   geom_smooth(se = FALSE, size = 0.5)
#'
#' plot(mod, which = 6)
#' ggplot(au, aes(.hat, .cooksd)) +
#'   geom_vline(xintercept = 0, colour = NA) +
#'   geom_abline(slope = seq(0, 3, by = 0.5), colour = "white") +
#'   geom_smooth(se = FALSE) +
#'   geom_point()
#' qplot(.hat, .cooksd, size = .cooksd / .hat, data = au) + scale_size_area()
NULL


#' @rdname lm_tidiers
#' 
#' @param conf.int whether to include a confidence interval
#' @param conf.level confidence level of the interval, used only if
#' \code{conf.int=TRUE}
#' @param exponentiate whether to exponentiate the coefficient estimates
#' and confidence intervals (typical for logistic regression)
#' 
#' @details If \code{conf.int=TRUE}, the confidence interval is computed with
#' the \code{\link{confint}} function.
#' 
#' @return \code{tidy.lm} returns one row for each coefficient, with five columns:
#'   \item{term}{The term in the linear model being estimated and tested}
#'   \item{estimate}{The estimated coefficient}
#'   \item{std.error}{The standard error from the linear model}
#'   \item{statistic}{t-statistic}
#'   \item{p.value}{two-sided p-value}
#' 
#' If \code{cont.int=TRUE}, it also includes columns for \code{conf.low} and
#' \code{conf.high}, computed with \code{\link{confint}}.
#' 
#' @export
tidy.lm <- function(x, conf.int=FALSE, conf.level=.95,
                    exponentiate=FALSE, ...) {
    co <- coef(summary(x))
    nn <- c("estimate", "std.error", "statistic", "p.value")[1:ncol(co)]
    ret <- fix_data_frame(co, nn)

    if (exponentiate) {
        # save transformation function for use on confidence interval
        if (is.null(x$family) ||
                (x$family$link != "logit" && x$family$link != "log")) {
            warning(paste("Exponentiating coefficients, but model did not use",
                          "a log or logit link function"))
        }
        trans <- exp
    } else {
        trans <- identity
    }

    if (conf.int) {
        # avoid "Waiting for profiling to be done..." message
        CI <- suppressMessages(confint(x, level = conf.level))
        colnames(CI) = c("conf.low", "conf.high")
        ret <- cbind(ret, trans(unrowname(CI)))
    }
    ret$estimate <- trans(ret$estimate)

    ret
}


#' @rdname lm_tidiers
#' 
#' @template augment_NAs
#' 
#' @details Code and documentation for \code{augment.lm} originated in the
#' ggplot2 package, where it was called \code{fortify.lm}
#' 
#' @return When \code{newdata} is not supplied \code{augment.lm} returns
#' one row for each observation, with seven columns added to the original
#' data:
#'   \item{.hat}{Diagonal of the hat matrix}
#'   \item{.sigma}{Estimate of residual standard deviation when
#'     corresponding observation is dropped from model}
#'   \item{.cooksd}{Cooks distance, \code{\link{cooks.distance}}}
#'   \item{.fitted}{Fitted values of model}
#'   \item{.se.fit}{Standard errors of fitted values}
#'   \item{.resid}{Residuals}
#'   \item{.std.resid}{Standardised residuals}
#' 
#' (Some unusual "lm" objects, such as "rlm" from MASS, may omit
#' \code{.cooksd} and \code{.std.resid})
#' 
#' When \code{newdata} is supplied, \code{augment.lm} returns one row for each
#' observation, with three columns added to the new data:
#'   \item{.fitted}{Fitted values of model}
#'   \item{.se.fit}{Standard errors of fitted values}
#'   \item{.resid}{Residuals of fitted values on the new data}
#' 
#' @export
augment.lm <- function(x, data = model.frame(x), newdata,
                       type.predict, type.residuals, ...) {    
    augment_columns(x, data, newdata, type.predict = type.predict,
                           type.residuals = type.residuals)
}


#' @rdname lm_tidiers
#' 
#' @param ... extra arguments (not used)
#' 
#' @return \code{glance.lm} returns a one-row data.frame with the columns
#'   \item{r.squared}{The percent of variance explained by the model}
#'   \item{adj.r.squared}{r.squared adjusted based on the degrees of freedom}
#'   \item{sigma}{The square root of the estimated residual variance}
#'   \item{statistic}{F-statistic}
#'   \item{p.value}{p-value from the F test, describing whether the full
#'   regression is significant}
#'   \item{df}{Degrees of freedom used by the coefficients}
#'   \item{logLik}{the data's log-likelihood under the model}
#'   \item{AIC}{the Akaike Information Criterion}
#'   \item{BIC}{the Bayesian Information Criterion}
#'   \item{deviance}{deviance}
#'   \item{df.residual}{residual degrees of freedom}
#' 
#' @export
glance.lm <- function(x, ...) {
    s <- summary(x)
    ret <- with(s, data.frame(r.squared=r.squared,
                              adj.r.squared=adj.r.squared,
                              sigma=sigma,
                              statistic=fstatistic[1],
                              p.value=pf(fstatistic[1], fstatistic[2],
                                         fstatistic[3],
                              lower.tail=FALSE),
                              df=s$df[1]))
    ret <- finish_glance(unrowname(ret), x)
    ret
}
