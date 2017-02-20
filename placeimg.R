placeimg <- function(type = "agepyr", settlement = c("kiandutu", "sepu"), number = 1, extension = ".png") {
        
        g <- knitr::include_graphics(paste0(sapply(settlement, get), paste0(type, "-", number, extension)))
        
        return(g)
}