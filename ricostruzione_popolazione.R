#################################################
# DATI ISTAT Ricostruzione Bilancio Demografico #
#################################################
# https://demo.istat.it/ricostruzione/download.php

masteRfun::load_pkgs(master = FALSE, 'data.table')

pulisci_file <- function(x, yini = 2002, yfine = 2018){
    message('Processing ', gsub('.*_(.*).csv', '\\1', x))
    y <- readr::read_csv(file.path(tmpd, x), skip = 6, col_names = FALSE, skip_empty_rows = TRUE, guess_max = 0, col_types = readr::cols())
    y <- y[grepl('^[0-9]', y$X1),]
    y <- rbindlist(lapply(1:nrow(y), \(x) tstrsplit(as.character(y[x,]), split = ';')))
    yn <- length(unique(y$V1))
    yc <- 0
    y[, c('anno', 'sesso', 'citt') := NA_character_]
    for(nz in c('T', 'I', 'S')){
        for(yr in yini:yfine){
            for(sx in c('T', 'M', 'F')){
                y[seq(yn * yc + 1, yn * (yc + 1)), c('anno', 'sesso', 'citt') := .(yr, sx, nz)]
                yc <- yc + 1
            }            
        }        
    }
    y[, `:=`( V1 = as.integer(V1), V2 = NULL)]
    y
}


# Ricostruzione intercensuaria della popolazione residente per età al 1° gennaio, anni 2002-2019
tmpf <- tempfile()
tmpd <- tempdir()
download.file('https://demo.istat.it/ricostruzione/dati/PopolazioneEta-Territorio-Comuni.zip', tmpf)
unzip(tmpf, exdir = tmpd)
unlink(tmpf)
fns <- list.files(tmpd)
y <- rbindlist(lapply(fns, pulisci_file, 2002, 2019))
unlink(tmpd)
setnames(y, 1, 'CMN')
y <- melt(y, id.vars = c('CMN', 'anno', 'sesso', 'citt'), variable.name = 'eta', variable.factor = FALSE, value.name = 'valore')
y[, `:=`( anno = as.integer(anno), eta = as.integer(gsub('V', '', eta)) - 3, valore = as.integer(valore) )]
y <- y[valore > 0]
setorderv(y, c('CMN', 'anno', 'sesso', 'citt'))
fst::write_fst(y, file.path(data_path, 'istat', 'pop_eta'))


# Ricostruzione intercensuaria del bilancio demografico, anni 2002-2018
tmpf <- tempfile()
tmpd <- tempdir()
download.file('https://demo.istat.it/ricostruzione/dati/BilancioDemografico-Territorio-Comuni.zip', tmpf)
unzip(tmpf, exdir = tmpd)
unlink(tmpf)
fns <- list.files(tmpd)
y <- rbindlist(lapply(fns, pulisci_file))
unlink(tmpd)
setnames(y, 1:10, c('CMN', 'pop_ini', 'nati', 'morti', 'isc_int', 'canc_int', 'isc_est', 'canc_est', 'nuova_citt', 'pop_fine'))
setcolorder(y, c('CMN', 'anno', 'sesso', 'citt'))
setorderv(y, c('CMN', 'anno', 'sesso', 'citt'))
fst::write_fst(y, file.path(data_path, 'istat', 'bilancio'))
    
    