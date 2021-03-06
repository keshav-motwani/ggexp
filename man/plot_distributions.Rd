% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/distributions.R
\name{plot_distributions}
\alias{plot_distributions}
\title{Plot distributions with pairwise annotations and flexibility}
\usage{
plot_distributions(
  data,
  x,
  y,
  type = "quasirandom",
  add_boxplot = ifelse(type \%in\% c("density", "ridge", "line"), FALSE, TRUE),
  group = NULL,
  color = NULL,
  fill = NULL,
  alpha = 1,
  point_size = 1,
  text_size = 2,
  scale = "default",
  annotate_counts = TRUE,
  pairwise_annotation = NULL,
  pairwise_annotation_label = "p_signif",
  pairwise_annotation_exclude = c(),
  pairwise_annotation_tier_width = 0.16,
  lower_quantile = 0,
  upper_quantile = 1,
  drop_outliers = FALSE,
  facet_rows = c(),
  facet_columns = c(),
  facet_type = "grid",
  ...
)
}
\arguments{
\item{data}{data frame containing dataset to use for plotting}

\item{x}{column for x-axis}

\item{y}{column for y-axis}

\item{type}{type of plot - can be "line", "sina", "quasirandom", "density", "violin", "box", or "ridge"}

\item{add_boxplot}{boolean to add boxplot on top of selected plot type}

\item{group}{column for group aesthethic, used if type == "line"}

\item{color}{column for color}

\item{fill}{column for fill}

\item{alpha}{alpha of points}

\item{point_size}{size of points for plot types with individual points}

\item{text_size}{text size for count annotations}

\item{scale}{either "default" for linearly-spaced scale or "log" for log-spaced}

\item{annotate_counts}{boolean whether to annotate counts per group or not}

\item{pairwise_annotation}{data frame containing pairwise annotations}

\item{pairwise_annotation_label}{column of pairwise_annotation data to use for annotation text}

\item{pairwise_annotation_exclude}{values to not annotate on pairwise annotations}

\item{pairwise_annotation_tier_width}{relative distance between tiers for pairwise annotations, between 0 and 1}

\item{lower_quantile}{lower quantile beyond which to limit axis}

\item{upper_quantile}{upper quantile beyond which to limit axis}

\item{drop_outliers}{whether to drop outliers, or not (mask values at the limits)}

\item{facet_rows}{columns for faceting by row}

\item{facet_columns}{columns for faceting by column}

\item{facet_type}{either "wrap" or "grid", corresponding to facet_wrap and facet_grid respectively}

\item{...}{params passed into either facet_wrap or facet_grid, depending on facet_type parameter}
}
\value{
ggplot object
}
\description{
Plot distributions with pairwise annotations and flexibility
}
