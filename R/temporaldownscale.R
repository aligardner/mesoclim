# ******** NB - I think we are mostly talking about daily to hourly here ***** #

TESTTESTTEST

# ============================================================================ #
# ~~~~~~~~~~~~ Temperature downscale ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# ============================================================================ #
# Generates a plausable vector of hourly temperatures from daily data
# Inputs:
# tmn - a vector of daily maximum temperatures (deg C)
# tmx - a vector of daily minimum temperatures (deg C)
# julian - astronomical julian day - as returned by julday()
# lat - latitude of location (decimal degrees)
# long - longitude of location (decimal degrees)
# dl - otionally day length (decimal hours), calculated if not supplied
# adjust - optional logical (see details)
# strte - parameter controlling speed of decay of night time tmeperatures (see details)
# Details:
# Daytime temperatures are assumed to follow a sine curve with a peak s short while
# after solar noon. After dusk, the temperatures are assumed to decay exponentially reaching
# a minimum at dawn. The day in which tmx and tmn fall is assumed to match UTC days.
# If adjust is TRUE, the generated hourly values are adjusted to ensure max and min temperatures
# match tmx and tmn (slower, but sensible). The parameter stre controls the speed of decay of
# night time temperatures with time. A value of zero ensures values drop to dawn temperature at
# dawn the following day, but trial and error indicates in most circumstances temperatures decay
# faster than this. The current value of 0.09 is optimised using ERA5 data for western Europe, but
# should perform well globally
hourlytemp <- function(tmn, tmx, julian, lat, long, dl = NA, adjust = TRUE, srte = 0.09) {
  .sincf <- function(tmn, tmx, tmnn, dl, stt, ngtp, srte = 0.01)  {
    lt <- c(0:23)
    # Sunset and sunrise
    sr <- 12 - 0.5 * dl
    st <- lt + stt - sr # solar time after sunrise
    st <- st%%24
    if (dl == 24) {
      rho <- 28
      TD <- (tmx - tmn) * sin((pi * st) / rho) + tmn
      gr <- (tmnn - tmn) * (st / 24)
      TD <- TD + gr
    } else if (dl == 0) {
      sr <- 0
      st <- lt + stt - sr # solar time after sunrise
      st <- st%%24
      TD <- (tmx - tmn) * sin((pi * st) / 24) + tmn
      gr <- (tmnn - tmn) * (st / 24)
      TD <- TD + gr
    } else {
      k <- -(24 - dl) / log(srte / ngtp)
      ph <- -0.5 * dl * ((pi / (asin(ngtp) - pi)) + 1)
      rho <- dl + 2 * ph
      TD <- sin((pi * st) / rho)
      TN <- ngtp * exp(-(st - dl) / k)
      TD[st > dl] <- TN[st > dl]
      # Adjust by tmax and tmin
      TD <- (tmx - tmn) * TD + tmn
      # Apply gradient to times after sunset as tmn is next day
      gr <- (tmnn - tmn) * (st - dl) / (24 - dl)
      sel <- which ((lt + stt) > dl)
      TD[sel] <- TD[sel] + gr[sel]
    }
    return(TD)
  }
  # Calculate day length
  if (is.na(dl[1])) dl <- daylength(julian, lat)
  stt <- solartime(0, long, julian)
  # Calculate predicted night fraction
  ngtp <- 0.04187957*((tmx-tmn)*(1-dl/24))+0.4372056
  ngtp[ngtp<0.01]<-0.01
  ngtp[ngtp>0.99]<-0.99
  # Calculate mean sunrise time in time zone of tme
  msrtime <- mean(stt) + 12 - 0.5 * mean(dl)
  if (msrtime > 0) { # if sunrise in current day
    tmnn <-c(tmn, tmn[length(tmn)])
    tmnn <- tmnn[2:length(tmnn)]
  } else { # if sunrise in previous day
    tmnn <- tmn
    tmn <- c(tmn[1], tmn)
    tmn <- tmn[1:(length(tmn) - 1)]
  }
  # interpolate temprature
  thour <-mapply(.sincf, tmn, tmx, tmnn, dl, stt, ngtp, srte)
  thour <- as.vector(thour)
  # correct to ensure tmx and tmn are the same as in daily
  if (adjust) {
    td<-matrix(thour,ncol=24,byrow=T)
    ptmx<-apply(td,1,max)
    ptmn<-apply(td,1,min)
    b<-(ptmx-ptmn)/(tmx-tmn)
    a<-b*tmn-ptmn
    thour<-(thour+rep(a,each=24))/rep(b,each=24)
  }
  return(thour)
}
# Derives an array of hourly temperature values from daily maxima and minima. The
# function applies function hourlytemp() over all rid cells of an array of data
# Inputs:
# tasmin - an array of daily minimum temperature values (deg C)
# tasmax - an array of daily maximum temperature values (deg C)
# tme - POSIXlt object of dates corresponding to radsw
# r - a terra::SpatRaster object giving the extent of radsw -
#     used for deriving the lat and long of grid cells
# adjust - optional logical which if TRUE ensures that, after interpolation, returned
#          hourly values, when averaged to daily, match the input
# stre - coefficient controlling the rate of nightime temperature decay (see
# hourlytemp for details)
# Returns an array of hourly temperature values (deg C)
temp_dailytohourly <- function(tasmin, tasmax, tme, r, adjust = TRUE, srte = 0.09) {
  lat<-latsfromr(r)
  lon<-lonsfromr(r)
  jd<-julday(tme$year+1900,tme$mon+1,tme$mday)
  lats<-.mta(lat,length(jd))
  lons<-.mta(lon,length(jd))
  jd<-.vta(jd,lat)
  dls<-daylength(jd, lats)
  tmeh <- as.POSIXlt(seq(tme[1],tme[length(tme)]+23*3600, by = 3600))
  sel<-which(tmeh$year==tme$year[2])
  thout<-array(NA,dim=c(dim(tasmin)[1:2],length(sel)))
  for (i in 1:dim(r)[1]) {
    for (j in 1:dim(r)[2]) {
      tst<-mean(tasmin[i,j,],na.rm=T)
      if (is.na(tst) == F) {
        thout[i,j,]<-hourlytemp(tasmin[i,j,],tasmax[i,j,],jd[i,j,],lat[i,j],lon[i,j],dls[i,j,],adjust,srte)[sel]
      }
    }
  }
  return(thout)
}
# ============================================================================ #
# ~~~~~~~~~~~~~~~~ Relative humidity ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# ============================================================================ #
# ~~ Function should spline interpolate vapour pressure and use temperature cycle
# ~~ to calculate relative humidity
# Derives an array of hourly relative humidity values from daily values.
# Inputs:
# relhum - an array of daily relative humidity values (%)
# tasmin - an array of daily minimum temperature values (deg C)
# tasmax - an array of daily maximum temperature values (deg C)
# temph - an array of hourly temperature values (deg C)
# psl - an array of daily surface-level pressure values(kPa)
# presh - an aray of hourly surface-level pressure values (kPa)
# tme - POSIXlt object of dates corresponding to radsw
# relmin - minimum possible relative humidity value
# adjust - optional logical which if TRUE ensures that, after interpolation, returned
#          hourly values, when averaged to daily, match the input
# Returns an array of hourly relative humidity values (%)
# Details:
# Owing to the strong dependence of relative humidity on temperature, the the
# resulting diurnal patterns, prior to interpolation, relative humidity is first
# converted to specific humidity using tasmin, tasmax and psl. After interpolation,
# the data are back-converted to relative humidity, using temph and presh.
hum_dailytohourly <- function(relhum, tasmin, tasmax, temph, psl, presh, tme, relmin = 2, adjust = TRUE) {
  # Convert to specific humidity
  tc<-(tasmin+tasmax)/2
  hs<-converthumidity(relhum,intype="relative",outtype="specific",tc=tc,pk=psl)
  hr<-daytohour(hs)
  # select days in year only
  tmeh <- as.POSIXlt(seq(tme[1],tme[length(tme)]+23*3600, by = 3600))
  sel<-which(tmeh$year==tme$year[2])
  hr<-hr[,,sel]
  relh<-suppressWarnings(converthumidity(hr,intype="specific",outtype="relative",tc=temph,pk=presh))

  # make consistent with daily
  if (adjust) {
    if (length(unique(tme$year)) > 1) {
      sel2<-c(2:(length(tme)-1))
    } else sel2<-c(1:length(tme))

    reld <- hourtoday(relh)
    mult <- relhum[,,sel2] / reld
    mult[is.na(mult)] <- 1
    mult <- daytohour(mult, Spline = FALSE)
    relh <- relh * mult
  }
  relh[relh>100]<-100
  relh[relh<relmin]<-relmin
  return(relh)
}
# ============================================================================ #
# ~~~~~~~~~~~~ Atmospheric pressure downscale ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# ============================================================================ #
# Derives an array of hourly surface-level pressure values from an array of daily
# surface level pressure values
# Inputs:
# pres - an array of daily mean surface-level pressure values (kPa)
# tme - POSIXlt object of dates corresponding to radsw
# adjust - optional logical which if TRUE ensures that, after interpolation, returned
#          hourly values, when averaged to daily, match the input
# Returns an array of hourly surface-level pressure values (kPa)
# Details:
# note that, as in the era5 dataste, these are surface level pressures in kPa corrsponding to
# the elevation of each geographic location and not sea=level pressures. The
# conversion to millbars is mb = 10 kPa. The conversion to sea-level pressure (Psl) can be
# derived by reversing the equation Psl = pres*((293-0.0065z)/293)**5.26
pres_dailytohourly <- function(pres, tme, adjust = TRUE) {
  mn<-min(pres,na.rm=T)-1
  mx<-max(pres,na.rm=T)+1
  presh <- daytohour(pres)
  presh[presh<mn]<-mn
  presh[presh>mx]<-mx
  # make consistent with daily
  if (adjust) {
    presd <- hourtoday(presh)
    mult <- pres / presd
    mult[is.na(mult)] <- 1
    mult <- daytohour(mult, Spline = FALSE)
    presh <- presh * mult
  }
  tmeh <- as.POSIXlt(seq(tme[1],tme[length(tme)]+23*3600, by = 3600))
  yr<-tme$year[2]
  sel<-which(tmeh$year==yr)
  presh<-presh[,,sel]
  return(presh)
}
# ============================================================================ #
# ~~~~~~~~~~~~ Downward shortwave radiation downscale ~~~~~~~~~~~~~~~~~~~~~~~~ #
# ============================================================================ #
# NB - this assumes input radiation is downward flux, not net radiation (as assumed in UKCP)
# to get from net to downward flux we need to recognise that rswnet = (1-alb)*radsw, so
# radsw = rswnet/(1-alb), where alb is white sky albedo. White-sky albedo changes as a function
# of solar angle, but in a manner dependent on ground reflectance, leaf area, leaf inclination
# angles and leaf transmittance and the ratio of diffuse and direct. There are too
# many vegetation parameter unknowns to reverse engineer, so suggest ignoring this.
# discrepancies probably quite minor expect in areas with very low cover and will be handled
# mostly by bias correction anyway


# ~~ * Need to spline interpolate clear-sky fraction (bounding by 1 and 0) and
# ~~   then calculate clear-sky radiation
# ~~ * Need to spline interpolate sky emissvity (bounding by 1 and 0) and
# ~~   then calculate longwave
# Derives an array of hourly radiation values from an array of daily radiation values
# Inputs:
# radsw - an array of daily mean radiation values (W/m**2)
# tme - POSIXlt object of dates corresponding to radsw
# clearky - optionally an array with dimensions matching radsw of daily clearsky
#           radiation as returned by clearskyraddaily(). Calculated if not supplied
# r - a terra::SpatRaster object giving the extent of radsw -
#     used for deriving the lat and long of grid cells
# adjust - optional logical which if TRUE ensures that, after interpolation, returned
#          hourly values, when averaged to daily, match the input
# Returns an array of hourly radiation values (W/m**2)
swrad_dailytohourly <- function(radsw, tme, clearsky = NA, r = r, adjust = TRUE) {
  # If NA, calaculate daily clearsky radiation
  if (class(clearsky) == "logical") clearsky <- clearskyraddaily(radsw, tme, r)
  # Calculate clear sky fraction
  radf <- radsw/clearsky
  radf[radf > 1] <- 1
  radf[radf < 0] <- 0
  # Interpolate clear sky fraction to hourly
  radfh <- daytohour(radf)
  radfh[radfh > 1] <- 1
  radfh[radfh < 0] <- 0
  # Calculate hourly clear sky radiation
  lat <- latsfromr(r)
  lon <- lonsfromr(r)
  tmeh <- as.POSIXlt(seq(tme[1],tme[length(tme)]+23*3600, by = 3600))
  jd <- julday(tmeh$year + 1900, tmeh$mon + 1, tmeh$mday)
  lt <- tmeh$hour
  lats <- .mta(lat, length(lt))
  lons <- .mta(lon, length(lt))
  jd <- .vta(jd, lat)
  lt <- .vta(lt, lat)
  csh<-clearskyrad(lt, lats, lons, jd)
  csh[is.na(csh)] <- 0
  # Calculate hourly radiation
  radh <- csh * radfh
  # Make consistent with daily
  if (adjust) {
    radd <- hourtoday(radh)
    mult <- radsw / radd
    mult[is.na(mult)] <- 1
    mult <- daytohour(mult, Spline = FALSE)
    radh <- radh * mult
  }
  radh[radh > 1352.778] <- 1352.778
  radh[radh < 0] <- 0
  radh[is.na(radh)] <- 0
  msk<-.mta(radsw[,,1],dim(radh)[3])
  msk[is.na(msk)==F]<-1
  radh<-radh*msk
  yr<-tme$year[2]
  sel<-which(tmeh$year==yr)
  radh<-radh[,,sel]
  return(radh)
}
# ============================================================================ #
# ~~~~~~~~~~~~ Downward longwave radiation downscale ~~~~~~~~~~~~~~~~~~~~~~~~ #
# ============================================================================ #
# NB - more consistent to code this as downward longwave, but will essentially
# do the calaculations in the function below, but with temperature as an additional
' input'
# Derives an array of hourly effective sky-emissivity values
# Inputs:
# skyem - an array of daily mean sky-emissivity values values (0-1)
# tme - POSIXlt object of dates corresponding to radsw
# adjust - optional logical which if TRUE ensures that, after interpolation, returned
#          hourly values, when averaged to daily, match the input
# Returns an array of hourly sky-emissivity values values (0-1)
# Details:
#  Effective sky emissvity can be used to calaculate downward longwave radiation (Lwd).
#  The formula is Lwd = skyem * Lwu where Lwu is upward longwave radiation given
#  by Lwu=0.97*5.67*10**-8*(tc+273.15). Here tc is average surface temperature (deg C))
#  but an adequate approximation is derived if subtited by air temperature.
skyem_dailytohourly <- function(skyem, tme, adjust = TRUE) {
  skyemh <- daytohour(skyem)
  if (adjust) {
    skyemd <- hourtoday(skyemh)
    mult <- skyem / skyemd
    mult[is.na(mult)] <- 1
    mult <- daytohour(mult, Spline = FALSE)
    skyemh <- skyemh * mult
  }
  skyem[skyem>1] <- 1
  skyem[skyem < 0.2] <- 0.2
  tmeh <- as.POSIXlt(seq(tme[1],tme[length(tme)]+23*3600, by = 3600))
  yr<-tme$year[2]
  sel<-which(tmeh$year==yr)
  skyemh<-skyemh[,,sel]
  return(skyemh)
}
# ============================================================================ #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Wind speed downscale ~~~~~~~~~~~~~~~~~~~~~~~~~ #
# ============================================================================ #
# ~~ * Need to spline interpolate u and v wind vectors. We could simulate
# ~~   inter-hourly variability. Follows a Weiball distribution so quite easy I
# ~~   suspect.
# Derives arrays of hourly wind speed and direction from arrays of daily data
# Inputs:
# ws - an array of daily mean wind speed values (m/s)
# wd - an array of daily mean wind direction values (deg from N)
# tme - POSIXlt object of dates corresponding to radsw
# adjust - optional logical which if TRUE ensures that, after interpolation, returned
#          hourly values, when averaged to daily, match the input
# Returns an a list of two arrays:
# (1) hourly wind speed (m/s)
# (2) hourly wind direction (degrees from north)
# Details:
# For interpolation, u and v wind vectors are derived form wind speed andd direction
# and these are interpolated to hourly, with backward calculations then performed to
# derive wind speed and direction.
wind_dailytohourly <- function(ws, wd, tme, adjust = TRUE) {
  u<- -ws*sin(wd*pi/180)
  v<- -ws*cos(wd*pi/180)
  uh <- daytohour(u)
  vh <- daytohour(v)
  wdh <- (180+atan2(uh,vh)*(180/pi))%%360
  wsh <- sqrt(uh^2+vh^2)
  if (adjust) {
    wsd <- hourtoday(wsh)
    mult <- ws / wsd
    mult[is.na(mult)] <- 1
    mult <- daytohour(mult, Spline = FALSE)
    wsh <- wsh * mult
  }
  tmeh <- as.POSIXlt(seq(tme[1],tme[length(tme)]+23*3600, by = 3600))
  yr<-tme$year[2]
  sel<-which(tmeh$year==yr)
  wsh<-wsh[,,sel]
  wdh<-wdh[,,sel]
  return(list(wsh=wsh,wdh=wdh))
}
# ============================================================================ #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Precipitation downscale  ~~~~~~~~~~~~~~~~~~~~~ #
# ============================================================================ #
# ~~ * Need to use Bartlett-Lewis rectangular pulse model + HyetosMinute method.
# ~~   coding is very poor in that package so scope to imporve it.
# sequence of rainfalls
# Z higher level (e.g. storm) sum
.propadjust <- function(rainseq, Z) {
  Xs <- rainseq * (Z / sum(rainseq))
  Xs
}
# runs Bartlett-Lewis until sequence of L wet days is generated
# BLest = Bartlett lewis paramaters
# dailysteps = number of values per day (i.e. 24 for hourly)
# dn = number of days
.level0 <- function(BLest, dailyvals, dn) {
  wet <- function(rainseq) {
    wd <- ifelse(sum(rainseq) > 0, 1, 0)
    wd
  }
  sr <- NA
  w <- NULL
  iter <- 0
  while (length(w) < 1) {
    sim<-BLRPM.sim(BLest[1] / dailyvals, BLest[2] / dailyvals, BLest[3] / dailyvals,
                   BLest[4] / dailyvals, BLest[5] / dailyvals, dn * dailyvals * 100,
                   dn * dailyvals * 100, 1, 0)
    hr <- t(matrix(sim$RR, nrow = dailyvals))
    dr <- apply(hr, 1, wet)
    x <- rle(dr)
    w <- which(x$lengths == dn & x$values == 1)
    if (length(w) > 0) {
      v <- length(rep.int(x$values[1:w[1]], x$lengths[1:w[1]])) - dn + 1
      sr <- hr[v:(v + dn -1),]
    }
    iter <- iter + 1
  }
  return(sr)
}
.level1 <- function(rainseq, BLest, dailyvals, dlim, maxiter) {
  d <- dlim * 2
  iter <- 0
  while (d > dlim & iter < maxiter) {
    dn <- length(rainseq)
    l0 <- .level0(BLest, dailyvals, dn)
    if (length(rainseq) > 1) {
      dr <- apply(l0, 1, sum)
    } else dr <- sum(l0)
    d <- sum(log((rainseq + 0.1) / (dr + 0.1))^2)^0.5
    iter <- iter + 1
  }
  if (d > dlim) l0<-NA
  return(l0)
}
.oneday <- function(dayrain, BLest, dailyvals, dlim, maxiter) {
  l1 <- NA
  while (is.na(sum(l1))) {
    l1 <- .level1(dayrain, BLest, dailyvals, dlim, maxiter)
  }
  l1
}
.level3 <- function(rainseq, BLest, dailyvals, dlim, maxiter) {
  l1 <- matrix(NA, nrow = length(rainseq), ncol = 24)
  r <- matrix(rainseq, nrow = 1)
  while (is.na(sum(l1))) {
    for (i in 1:dim(r)[1]) {
      r1 <- r[i,]
      r1 <- r1[is.na(r1) == F]
      st <- 1
      if (i > 1) {
        xx <- r[1:(i-1),]
        xx <- xx[is.na(xx) == F]
        st <- st + length(xx)
      }
      xx <- r[i,]
      xx <- xx[is.na(xx) == F]
      ed <- st + length(xx) - 1
      if (length(r1) == 1) {
        if (is.na(sum(l1[st:ed,]))) l1[st:ed,] <- .oneday(r1, BLest, dailyvals, dlim, maxiter)
      }  else {
        if (is.na(sum(l1[st:ed,]))) {
          l1[st:ed,] <- .level1(r1, BLest, dailyvals, dlim, maxiter)
          if (is.na(sum(l1[st:ed,]))) {
            ii <- which(r1 == min(r1[1:(length(r1) - 1)]))
            r11 <- r1[1:ii]
            r12 <- r1[(ii + 1):length(r1)]
            rr <- matrix(r[-i,], ncol = ncol(r))
            nc <- max(length(r11),length(r12))
            dm <- dim(rr)[1]
            mxc <- apply(rr, 1, function(x) length(x[is.na(x) ==F]))
            if (dm > 0) nc <- max(nc, max(mxc))
            r <- matrix(NA, nrow = dm + 2, ncol = nc)
            if (dm > 0) r[1:dm,1:mxc] <- rr[1:dm,1:mxc]
            r[dm + 1, 1:length(r11)] <- r11
            r[dm + 2, 1:length(r12)] <- r12
            l1a <- .level1(r11, BLest, dailyvals, dlim, maxiter)
            l1b <- .level1(r12, BLest, dailyvals, dlim, maxiter)
            st2 <- st + length(r11)
            l1[st:(st2 -1), ] <- l1a
            l1[st2:(st2 + length(r12) - 1),] <- l1b
          }
        }
      }
    }
  }
  l1
}
#' Estimate sub-daily rainfall from daily rainfall
#'
#' @description
#' `subdailyrain` estimate sub-daily rainfall using Bartlett-Lewis rectangular pulse rainfall model.
#'
#' @param rain a vector time-series of rainfall
#' @param BLpar a data.frame of Bartlett-Lewis parameters as returned by [findBLpar()].
#' @param dailyvals the number of rainfall values required for each day (i.e. 24 for hourly).
#'
#' @return A matrix with `length(rain)` rows and `dailyvals` columns of sub-daily rainfall.
#'
#' @export
#'
#' @details The function is based on the Bartlett-Lewis Rectangular Pulse model described by
#' Rodriguez-Iturbe (1987 & 1988). The model has six parameters (see [findBLpar()]) and is
#' characterized as a particular form of clustering process in which each cluster of rainfall events
#' (hereafter storms) consists of one or more rainfall cells being generated in the start of the
#' process. The parameters of `BLpar` governs the frequency of storms, the start and end of rainfall
#' events associated with each storms, the intensity of rainfall associated with storms variation
#' in the duration of storms, and can be used to generate data for any time-interval. Since these
#' vary seasonally, or by month, it is wise to generate sb-daily data seperately for each month using
#' different parameter estimates.
#'
#' Singificant element sof the coding have been borrowed from from the HyetosMinute package, and
#' the library must be loaded and attached, i.e. `library(HyetosMinute)' as the function calls C++ code
#' included with the package. The package is not available on CRAN and must be obtained or installed
#' directly from here: http://www.itia.ntua.gr/en/softinfo/3/.
#'
#' @references
#' Rodriguez-Iturbe I, Cox DR & Isham V (1987) Some models for rainfall based on stochastic point
#' processes. Proc. R. Soc. Lond., A 410: 269-288.
#'
#' Rodriguez-Iturbe I, Cox DR & Isham V (1988) A point process model for rainfall: Further
#' developments. Proc. R. Soc. Lond., A 417: 283-298.
#'
#' @examples
#' # =========================================== #
#' # ~~~ Generate hourly data for March 2015 ~~~ #
#' # =========================================== #
#' # ~~~~ Get paramaters for March
#' tme <- as.POSIXlt(dailyrain$obs_time)
#' marchrain <- dailyrain$precipitation[which(tme$mon + 1 == 3)]
#' BLpar <- findBLpar(marchrain) # Takes ~ 30 seconds
#' # ~~~~ Generate hourly data for March 2015
#' sel <- which(tme$mon + 1 == 3 & tme$year + 1900 == 2015)
#' march2015 <- dailyrain$precipitation[sel]
#' hourly <- subdailyrain(march2015, BLpar)
#' # ~~~~ Plots comparing hourly and daily / 24 data
#' o <- as.vector(t(matrix(rep(c(1:31), 24), nrow = 31, ncol = 24)))
#' marchhfd <- march2015[o] / 24
#' hourlyv <-as.vector(t(hourly))
#' dd <- c(1:(31 * 24)) / 24
#' plot(hourlyv ~ dd, type = "l", ylim = c(0, max(hourlyv)),
#'      xlab = "Decimal day", ylab = "Rain (mm / hr)", col = "red")
#' par(new = T)
#' plot(marchhfd ~ dd, type = "l", ylim = c(0, max(hourlyv)),
#'      xlab = "", ylab = "", col = "blue", lwd = 2)

#'
subdailyrain <- function(rain, BLest, dailyvals = 24, dlim = 0.2, maxiter = 1000, splitthreshold = 0.2, trace = TRUE) {
  rain[is.na(rain)] <- 0
  srain <- matrix(0, ncol = dailyvals, nrow = length(rain))
  wd <- ifelse(rain > splitthreshold, 1, 0)
  st <- which(diff(c(0, wd)) == 1)
  ed <- which(diff(c(wd, 0)) == -1)
  if (trace) cat(paste("Number of rainfall events:",length(ed),"\n"))
  for (i in 1:length(ed)) {
    r <- rain[st[i]:ed[i]]
    rseq <- .level3(r, BLest, dailyvals, dlim, maxiter)
    for (j in 1:length(r)) rseq[j,] <- .propadjust(rseq[j,], r[j])
    srain[st[i]:ed[i],] <- rseq
    if (trace) cat(paste("Completed rainfall event:",i,"\n"))
  }
  if (trace) cat("Processing days with rain < splitthreshold \n")
  sel <- which(rain <= splitthreshold & rain > 0)
  if (length(sel) > 0) {
    for (i in 1:length(sel)) {
      r <- rain[sel[i]]
      rseq <- .level3(r, BLest, dailyvals, dlim, maxiter)
      srain[sel[i],] <-  .propadjust(rseq, r)
    }
  }
  srain
}
plotrain <- function(daily, subdaily) {
  dailyvals <- length(subdaily) / length(daily)
  d24 <- as.vector(t(matrix(rep(daily, dailyvals), ncol = dailyvals)))
  d24 <- d24 / dailyvals
  day <- c(0:(length(d24) - 1)) / dailyvals
  sday <-  as.vector(t(subdaily))
  xs <- c(day, max(day), 0)
  ys1 <- c(d24, 0, 0)
  ys2 <- c(sday, 0, 0)
  par(mar=c(5,5,5,5))
  plot(NA, xlim = c(0,max(day)), ylim = c(0,max(sday)),
       ylab = "Rainfall (mm)", xlab = "Day", cex.axis = 2, cex.lab = 2)
  polygon(xs, ys1, col = rgb(1,0,0,0.5))
  polygon(xs, ys2, col = rgb(0,0,1,0.5))
}
# ============================================================================ #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Downscale all ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# ============================================================================ #
# ~~ * Worth writing a wrapper function to combine all of above into a single
# ~~   function
