% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/spatialdownscale.R
\name{tempcad}
\alias{tempcad}
\title{Downscale temperature with cold air drainage effects}
\usage{
tempcad(climdata, dtmf, basins = NA, refhgt = 2)
}
\arguments{
\item{climdata}{a model object containing climate data of the same format as \code{era5climdata}}

\item{dtmf}{a fine-resolution SpatRast of elevations. Temperatures down-scaled
to resolution of \code{dtmf}.}

\item{basins}{optionally, a fine-resolution SpatRast of basins matching the
coordinate reference system and extent of \code{dtmf}. Calculated if not supplied.}

\item{dtmc}{optionally, height of weather measurements in \code{climdata} (default 2m)}
}
\value{
a SpatRast of temperature differences owing to cold-air drainage (deg C).
}
\description{
Downscales an array of temperature data adjusting for cold-air drainage
}
\details{
Cold air drainage is calaculated by delineating hydrological basins and
calculating flow accumulation and the elevation difference from the highest point of the basin.
Cold-air drainage is assumed to occur when atmospheric stability is high, namely when
the radiation balance is negative and wind speeds are low,
}
