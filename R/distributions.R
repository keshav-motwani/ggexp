#' Plot distributions with pairwise annotations and flexibility
#'
#' @param data data frame containing dataset to use for plotting
#' @param x column for x-axis
#' @param y column for y-axis
#' @param type type of plot - can be "line", "sina", "quasirandom", "density", "violin", "box", or "ridge"
#' @param add_boxplot boolean to add boxplot on top of selected plot type
#' @param group column for group aesthethic, used if type == "line"
#' @param color column for color
#' @param fill column for fill
#' @param alpha alpha of points
#' @param point_size size of points for plot types with individual points
#' @param text_size text size for count annotations
#' @param scale either "default" for linearly-spaced scale or "log" for log-spaced
#' @param annotate_counts boolean whether to annotate counts per group or not
#' @param pairwise_annotation data frame containing pairwise annotations
#' @param pairwise_annotation_label column of pairwise_annotation data to use for annotation text
#' @param pairwise_annotation_exclude values to not annotate on pairwise annotations
#' @param pairwise_annotation_tier_width relative distance between tiers for pairwise annotations, between 0 and 1
#' @param lower_quantile lower quantile beyond which to limit axis
#' @param upper_quantile upper quantile beyond which to limit axis
#' @param drop_outliers whether to drop outliers, or not (mask values at the limits)
#' @param facet_rows columns for faceting by row
#' @param facet_columns columns for faceting by column
#' @param facet_type either "wrap" or "grid", corresponding to facet_wrap and facet_grid respectively
#' @param ... params passed into either facet_wrap or facet_grid, depending on facet_type parameter
#'
#' @import ggplot2
#'
#' @return ggplot object
#' @export
plot_distributions = function(data,
                              x,
                              y,
                              type = "quasirandom",
                              add_boxplot = ifelse(type %in% c("density", "ridge", "line"), FALSE, TRUE),
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
                              ...) {
  data = .fix_outliers(data,
                       y,
                       lower_quantile,
                       upper_quantile,
                       drop_outliers,
                       c(facet_rows, facet_columns))

  plot = get(paste0(".plot_", type))(data,
                                     x,
                                     y,
                                     color,
                                     fill,
                                     group,
                                     alpha,
                                     point_size)

  if (add_boxplot & !(type %in% c("density", "ridge", "line"))) {
    plot = plot +
      geom_boxplot(
        alpha = 0,
        width = 0.3,
        outlier.size = 0,
        color = "black"
      )
  }

  plot = .plot_scale(plot, scale, type)


  if (length(c(facet_rows, facet_columns)) > 0) {
    plot = plot_facets(plot,
                       facet_rows,
                       facet_columns,
                       facet_type,
                       ...)
  }

  if (annotate_counts) {
    counts_annotation = .compute_counts_annotation_data(data, x, c(facet_rows, facet_columns))
    plot = .plot_counts_annotation(plot,
                                   x,
                                   counts_annotation,
                                   annotate_counts,
                                   type,
                                   text_size)
  }

  if (!is.null(pairwise_annotation) &
      (pairwise_annotation_label %in% colnames(pairwise_annotation)) &
      !(type %in% c("density", "ridge"))) {
    plot = plot_pairwise_annotation(
      plot,
      pairwise_annotation,
      pairwise_annotation_label,
      pairwise_annotation_exclude,
      pairwise_annotation_tier_width,
      scale
    )
  }

  plot = plot + theme_ggexp()

  if (!is.null(color) && color == x) {
    plot = plot + theme(legend.position = "none")
  }

  return(plot)
}

#' Remove or mask outliers based on quantiles in each group
#'
#' @param data data frame containing dataset to use for plotting
#' @param lower_quantile lower quantile beyond which to limit axis
#' @param upper_quantile upper quantile beyond which to limit axis
#' @param drop_outliers whether to drop outliers or not - if FALSE, then outliers are masked to the lower or upper quantile values
#' @param groups columns which to group on in computing outliers
#'
#' @importFrom dplyr group_by mutate filter
#'
#' @return
#' @keywords internal
.fix_outliers = function(data,
                         y,
                         lower_quantile,
                         upper_quantile,
                         drop_outliers,
                         groups) {
  data = data %>%
    group_by(.dots = groups) %>%
    mutate(
      upper_quantile = quantile(!!as.name(y), upper_quantile, na.rm = TRUE),
      lower_quantile = quantile(!!as.name(y), lower_quantile, na.rm = TRUE)
    ) %>%
    mutate(
      upper_outlier = !!as.name(y) > upper_quantile,
      lower_outlier = !!as.name(y) < lower_quantile
    ) %>%
    mutate(outlier = lower_outlier | upper_outlier)

  if (drop_outliers) {
    data = data %>%
      filter(!outlier)
  } else {
    data[, y] = ifelse(data$lower_outlier, lower_quantile, data[, y, drop = TRUE])
    data[, y] = ifelse(data$upper_outlier, upper_quantile, data[, y, drop = TRUE])
  }

  return(data)
}


#' Compute number of values per group for count annotation
#'
#' @param data data frame from which to count observations
#' @param x column for x-axis
#' @param groups groups to facet by
#'
#' @importFrom stats na.omit
#' @importFrom dplyr group_by tally
#'
#' @return
#' @keywords internal
.compute_counts_annotation_data = function(data, x, groups) {
  counts = data[, unique(c(x, groups)), drop = FALSE] %>%
    na.omit()
  counts = counts %>%
    group_by(.dots = unique(c(x, groups))) %>%
    tally()
  return(counts)
}

#' Annotate number of values per group on plot
#'
#' @param plot plot with discrete x-axis to annotate counts on
#' @param x column for x-axis
#' @param counts_annotation annotation returned from compute_counts_annotation_data
#' @param annotate_counts whether to annotate counts or not
#' @param type type of plot, same as plot_distributions type
#'
#' @import ggplot2
#'
#' @return
#'
#' @examples
#' NULL
.plot_counts_annotation = function(plot,
                                   x,
                                   counts_annotation,
                                   annotate_counts,
                                   type,
                                   text_size) {
  if (annotate_counts &&
      !(type %in% c("density", "ridge"))) {
    plot = plot +
      geom_text(
        data = counts_annotation,
        aes_string(
          label = "n",
          x = x,
          y = -Inf
        ),
        hjust = 0.5,
        vjust = -0.5,
        size = text_size,
        color = "black",
        angle = 0
      )
  } else if (annotate_counts && type == "ridge") {
    plot = plot +
      geom_text(
        data = counts_annotation,
        aes_string(label = "n",
                   x = Inf,
                   y = x),
        hjust = 1.3,
        vjust = -1,
        size = 2,
        color = "black",
        angle = 0
      )
  }
  return(plot)
}

#' Transform scale based on scale type and plot type
#'
#' @param plot ggplot object
#' @param scale either "log" or "default"
#' @param type plot type, same as plot_distributions type
#'
#' @import ggplot2
#'
#' @return
#' @keywords internal
.plot_scale = function(plot, scale, type) {
  if (scale == "log") {
    plot = plot +
      scale_y_continuous(trans = 'log10')
  }
  if (!(type %in% c("density", "ridge"))) {
    plot = plot + scale_x_discrete(drop = FALSE)
  }
  return(plot)
}

#' Plot line graph
#'
#' @param data data frame for plotting
#' @param x column for x-axis
#' @param y column for y-axis
#' @param color column to color points by
#' @param fill column to fill points by
#' @param group column to group points by - line connects by this variable
#' @param alpha alpha for each point
#'
#' @import ggplot2
#'
#' @return
#'
#' @examples
#' NULL
.plot_line = function(data,
                      x,
                      y,
                      color,
                      fill,
                      group,
                      alpha,
                      point_size) {
  plot = ggplot(data) +
    geom_line(alpha = alpha,
              aes_string(
                x = x,
                y = y,
                group = group,
                color = color
              )) +
    geom_point(alpha = alpha,
               aes_string(x = x, y = y, col = color),
               shape = 1,
               size = point_size)
  return(plot)
}

#' Plot sina plot
#'
#' @param data Data frame for plotting
#' @param x Column for x-axis
#' @param y Column for y-axis
#' @param color Column to color points by
#' @param group Column to group points by - not relevant for this function
#' @param alpha Alpha for each point
#'
#' @import ggplot2
#' @importFrom ggforce geom_sina
#'
#' @return
#'
#' @examples
#' NULL
.plot_sina = function(data,
                      x,
                      y,
                      color,
                      fill,
                      group,
                      alpha,
                      point_size) {
  plot = ggplot(data, aes_string(
    x = x,
    y = y,
    col = color,
    group = group
  )) +
    geom_sina(alpha = alpha,
              shape = 1,
              position = position_dodge(width = 0),
              size = point_size)

  return(plot)
}

#' Plot quasirandom plot
#'
#' @param data Data frame for plotting
#' @param x Column for x-axis
#' @param y Column for y-axis
#' @param color Column to color points by
#' @param group Column to group points by - not relevant for this function
#' @param alpha Alpha for each point
#'
#' @import ggplot2
#' @importFrom  ggbeeswarm geom_quasirandom
#'
#' @return
#'
#' @examples
#' NULL
.plot_quasirandom = function(data,
                             x,
                             y,
                             color,
                             fill,
                             group,
                             alpha,
                             point_size) {
  plot = ggplot(data, aes_string(
    x = x,
    y = y,
    col = color,
    group = group
  )) +
    geom_quasirandom(
      method = "tukeyDense",
      alpha = alpha,
      shape = 1,
      position = position_dodge(width = 1),
      size = point_size
    )
  return(plot)
}

#' Plot jitter plot
#'
#' @param data Data frame for plotting
#' @param x Column for x-axis
#' @param y Column for y-axis
#' @param color Column to color points by
#' @param group Column to group points by - not relevant for this function
#' @param alpha Alpha for each point
#'
#' @import ggplot2
#' @importFrom  ggbeeswarm geom_quasirandom
#'
#' @return
#'
#' @examples
#' NULL
.plot_jitter = function(data,
                        x,
                        y,
                        color,
                        fill,
                        group,
                        alpha,
                        point_size) {
  plot = ggplot(data, aes_string(
    x = x,
    y = y,
    col = color,
    group = group
  )) +
    geom_jitter(alpha = alpha,
                shape = 1,
                size = point_size)
  return(plot)
}

#' Plot violin plot
#'
#' @param data Data frame for plotting
#' @param x Column for x-axis
#' @param y Column for y-axis
#' @param color Column to color points by
#' @param group Column to group points by - not relevant for this function
#' @param alpha Alpha for each point
#'
#' @import ggplot2
#'
#' @return
#'
#' @examples
#' NULL
.plot_violin = function(data,
                        x,
                        y,
                        color,
                        fill,
                        group,
                        alpha,
                        point_size) {
  plot = ggplot(data, aes_string(
    x = x,
    y = y,
    col = color,
    group = group,
    fill = fill
  )) +
    geom_violin(alpha = alpha)
  return(plot)
}

#' Plot box and whiskers plot
#'
#' @param data Data frame for plotting
#' @param x Column for x-axis
#' @param y Column for y-axis
#' @param color Column to color points by
#' @param group Column to group points by - not relevant for this function
#' @param alpha Alpha for each point
#'
#' @import ggplot2
#'
#' @return
#'
#' @examples
#' NULL
.plot_box = function(data,
                     x,
                     y,
                     color,
                     fill,
                     group,
                     alpha,
                     point_size) {
  plot = ggplot(data) +
    geom_boxplot(alpha = 1,
                 width = 0.3,
                 aes_string(
                   x = x,
                   y = y,
                   col = color,
                   group = group
                 ),
                 outlier.size = point_size)

  return(plot)
}

#' Plot density plot
#'
#' @param data Data frame for plotting
#' @param x Column for x-axis
#' @param y Column for y-axis
#' @param color Column to color points by
#' @param group Column to group points by - not relevant for this function
#' @param alpha Alpha for each point
#'
#' @import ggplot2
#'
#' @return
#'
#' @examples
#' NULL
.plot_density = function(data,
                         x,
                         y,
                         color,
                         fill,
                         group,
                         alpha,
                         point_size) {
  plot = ggplot(data, aes_string(
    x = y,
    col = color,
    fill = fill,
    group = group
  )) +
    geom_density(alpha = alpha)
  return(plot)
}

#' Plot ridge plot
#'
#' @param data Data frame for plotting
#' @param x Column for x-axis
#' @param y Column for y-axis
#' @param color Column to color points by
#' @param group Column to group points by - not relevant for this function
#' @param alpha Alpha for each point
#'
#' @import ggplot2
#' @importFrom ggridges geom_density_ridges
#'
#' @return
#'
#' @examples
#' NULL
.plot_ridge = function(data,
                       x,
                       y,
                       color,
                       fill,
                       group,
                       alpha,
                       point_size) {
  plot = ggplot(data, aes_string(
    x = y,
    y = x,
    col = color,
    fill = fill
  )) +
    geom_density_ridges(alpha = alpha)
  return(plot)
}
