
## ------------------------------------------------------------------------
## utility functions exposed to the users
## ------------------------------------------------------------------------

is.db.data.frame <- function (x)
{
    is(x, "db.data.frame")
}

## ------------------------------------------------------------------------

## cut the data into k pieces
## mainly used for cross-validation
.cut.data <- function (x, k)
{
    ## randomize the data when creating serial index
    y <- .create.inter.table(x, TRUE)
    n <- dim(y)[1]

    if (n < k) stop("data dimension is even smaller than k!")

    id <- y@.dim[2]
    size <- n %/% k
    tick <- c(0, seq(size, length.out = k-1, by = size), n)
    valid <- list()
    train <- list()
    for (i in 1:k) {
        valid[[i]] <- y[y[,id]>tick[i] & y[,id]<=tick[i+1],-id]
        train[[i]] <- y[!(y[,id]>tick[i] & y[,id]<=tick[i+1]),-id]
    }

    list(train = train, valid = valid, inter = y)
}
