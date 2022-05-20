##############################
# DATI ISTAT Popolazione Eta #
##############################

masteRfun::load_pkgs(master = FALSE, 'data.table')

fpath <- file.path(ext_path, 'istat', 'decessi')

y <- rbindlist(lapply(
        list.files(fpath, 'xlsx$', full.names = TRUE),
        \(x) {
            message('Processo ', x)
            yt <- as.data.table( readxl::read_xlsx(x) )[, c(1:5, 7) := NULL]
            yt[, grep('^[^T]', names(yt), value = TRUE), with = FALSE]
        }
))
y[y == 'n.d.'] <- NA
y <- melt(y, id.vars = 1:3, na.rm = TRUE, variable.factor = FALSE)[value > 0]
y[, c('sesso', 'anno') := tstrsplit(variable, split = '_')][, periodo := as.Date(paste0(GE, anno), '%m%d%y')][, c('GE', 'anno', 'variable') := NULL]
setnames(y, c('CMN', 'eta', 'valore', 'sesso', 'periodo'))
setcolorder(y, c('CMN', 'periodo', 'sesso', 'eta', 'valore'))
y[, `:=`( CMN = as.integer(CMN), valore = as.integer(valore) )]
setorderv(y)
fst::write_fst(y, file.path(fpath, 'decessi'))

# library(parallel)
# cl <- makeCluster(4)
# clusterEvalQ(cl, library(data.table))
# y1 <- rbindlist(parLapply(cl, 
#         list.files(fpath, 'xlsx$', full.names = TRUE),
#         \(x) {
#             yt <- as.data.table( readxl::read_xlsx(x) )[, c(1:5, 7) := NULL]
#             yt[, grep('^[^T]', names(yt), value = TRUE), with = FALSE]
#         }
# ))
# stopCluster(cl)

# do <- function(x, fun, ncl = 4){
#             library(doFuture)
#             registerDoFuture()
#             cl <- parallel::makeCluster(ncl)
#             old_plan <- plan(cluster, workers = cl)
#             on.exit({
#                 plan(old_plan)
#                 parallel::stopCluster(cl)
#             })
#             foreach(i = x) %dopar% fun(i)
# }
