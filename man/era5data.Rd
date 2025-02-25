% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{era5data}
\alias{era5data}
\title{A list of ERA5 climate data}
\format{
a list with the following elements:
\describe{
\item{tme}{POSIXlt object of dates and times}
\item{climarray}{a list of arrays of climate variables with the following variables:}
\describe{
\item{temp}{Temperature (deg C)}
\item{relhum}{Relative humidity (Percentage)}
\item{pres}{Sea-level atmospheric pressure (kPa)}
\item{swrad}{Total downward shortwave radiation (W/m^2)}
\item{difrad}{Downward diffuse radiation (W / m^2)}
\item{lwrad}{Total downward longwave radiation (W/m^2)}
\item{windspeed at 2m (m/s)}
\item{winddir}{Wind direction (decimal degrees)}
}
\item{dtmc}{a wrapped SpatRast object of elevations (m) matching the extent and resolution of climate data}
}
}
\source{
\url{https://cds.climate.copernicus.eu//}
}
\usage{
era5data
}
\description{
A list of hourly ERA5 climata data for May 2018 for Cornwall, UK (lat, long boundary) as
returned by \code{\link[=era5toclimarray]{era5toclimarray()}}
}
\keyword{datasets}
