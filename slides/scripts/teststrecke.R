library(semTools)
AVE(fit)

diag(lavInspect(fit, "est")$theta) 