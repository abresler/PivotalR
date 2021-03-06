
## ------------------------------------------------------------------------
## Array operation utilities
## ------------------------------------------------------------------------

.array.udt <- c("_int4", "_bool", "_float8", "_text", "_varchar", "_int8",
               "int2")

.array.dat <- c("integer", "boolean", "double precision", "text", "bigint",
               "smallint")

## get each element in an array expression
## returns an array of string
.get.array.elements <- function (expr, tbl, where.str, conn.id)
{
    s <- gsub("array\\[(.*)\\]", "\\1", expr)
    if (s == expr) {
        n1 <- as.integer(.db.getQuery(paste0(
            "select array_upper(\"", .strip(s, "\""),
            "\", 1) from ",
            tbl, where.str, " limit 1"), conn.id))
        n2 <- as.integer(.db.getQuery(paste0(
            "select array_lower(\"",
            .strip(s, "\""), "\", 1) from ",
            tbl, where.str, " limit 1"), conn.id))
        n <- n1 - n2 + 1
        paste("\"", .strip(s, "\""), "\"[", seq_len(n) - 1 + n2,
              "]", sep = "")
    } else {
        regmatches(s, gregexpr("[^,\\s][^,]*[^,\\s]", s, perl=T))[[1]]
    }
}

## ------------------------------------------------------------------------

## expand a db.Rquery's array column
.expand.array <- function (x)
{
    if (!is(x, "db.obj")) return (x)
    x <- x[,]
    if (x@.source == x@.parent)
        parent <- x@.parent
    else
        parent <- paste("(", x@.parent, ") s", sep = "")
    src <- x@.source
    where <- x@.where
    if (x@.where != "")
        where.str <- paste(" where", x@.where)
    else
        where.str <- ""

    sort <- .generate.sort(x)

    expr <- character(0)
    col.name <- character(0)
    data.type <- character(0)
    udt.name <- character(0)
    is.factor <- logical(0)
    factor.suffix <- character(0)
    no.array <- TRUE
    for (i in seq_len(length(names(x)))) {
        if (x@.col.data_type[i] != "array") {
            expr <- c(expr, x@.expr[i])
            col.name <- c(col.name, (names(x))[i])
            data.type <- c(data.type, x@.col.data_type[i])
            udt.name <- c(udt.name, x@.col.udt_name[i])
            is.factor <- c(is.factor, x@.is.factor[i])
            factor.suffix <- c(factor.suffix, x@.factor.suffix[i])
            next
        }
        no.array <- FALSE
        arr <- .get.array.elements(x@.expr[i], parent, where.str,
                                   conn.id(x))
        expr <- c(expr, arr)
        col.name <- c(col.name, paste(x@.col.name[i], "[",
                                      seq_len(length(arr)), "]", sep = ""))
        data.type <- c(data.type,
                       rep(.find.array.data.type(x@.col.udt_name[i]),
                           length(arr)))
        udt.name <- c(udt.name, rep(gsub("_", "", x@.col.udt_name[i]),
                                    length(arr)))
        is.factor <- c(is.factor, rep(FALSE, length(arr)))
        factor.suffix <- c(factor.suffix, rep("", length(arr)))
    }

    if (no.array) return (x)

    content <- paste("select ", paste(expr, " as \"", col.name, "\"",
                                      collapse = ", ", sep = ""),
                     " from ", parent, where.str, sort$str, sep = "")

    new("db.Rquery",
        .content = content,
        .expr = expr,
        .source = src,
        .parent = parent,
        .conn.id = conn.id(x),
        .col.name = col.name,
        .key = x@.key,
        .where = where,
        .col.data_type = data.type,
        .col.udt_name = udt.name,
        .is.factor = is.factor,
        .factor.suffix = factor.suffix,
        .sort = sort)
}

## ------------------------------------------------------------------------

.find.array.data.type <- function(udt)
{
    if (gsub("int", "", udt) != udt)
        "integer"
    else if (gsub("float", "", udt) != udt)
        "double precision"
    else if (udt %in% c("_bool"))
        "boolean"
    else
        "text"
}
