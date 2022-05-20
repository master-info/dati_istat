########################################
# DATI ISTAT Bilancio Demografico #
########################################

masteRfun::load_pkgs(master = FALSE, 'data.table')

tmpd <- tempdir()
tmpf <- tempfile()
y <- rbindlist(lapply(
            2012:2020,
            \(yr) {
                message('Processing ', yr)
                download.file(paste0('https://demo.istat.it/bil', yr, '/dati/comuni.zip'), tmpf, quiet = TRUE)
                unzip(tmpf, exdir = tmpd)
                fn <- unzip(tmpf, list = TRUE)$Name
                yt <- fread(file.path(tmpd, fn))
                names(yt)
            }
))
unlink(tmpd)
unlink(tmpf)

setnames(y, c('anno', 'CMN', 'eta', 'celibi', 'coniugati', 'divorziati', 'vedovi', 'maschi', 'nubili', 'coniugate', 'divorziate', 'vedove', 'femmine'))
y <- melt(y, id.vars = c('anno', 'CMN', 'eta'), variable.name = 'dato', variable.factor = FALSE, value.name = 'valore')
y <- y[eta <= 100]
y <- rbindlist(list(y, y[dato %in% c('maschi', 'femmine'), .(dato = 'totale', valore = sum(valore)), .(CMN, anno, eta)]))

setcolorder(y, c('CMN', 'anno', 'eta', 'dato'))
setorderv(y, c('CMN', 'anno', 'eta', 'dato'))
fst::write_fst(y, file.path(data_path, 'istat', 'pop_eta'))

