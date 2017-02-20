---
title: "Scalable plotting with ggplot2 - Part II"
description: How can you take advantage of integrating ggplot with core 
  elements of the R language to create more flexible and adaptive plots while 
  reducing redundancy? This series discusses how we can use an lapply approach
  to create column-wise visualizations that adapt to data characteristics such 
  as the class. Part II extends concepts from part I and shows how further 
  customization can be achieved.
permalink: /scaleggplotII/
tags: ggplot2
layout: post
comments: true
---
## Introduction
<br/>

This blog post is the follow-up on [part I](/scaleggplotI/) on programming with ggplot2. 
After having developed a scalable approach to column-wise and data 
type-dependent visualization, we will continue to customize our plots. Specifically,
the focus of this post is how we can use a log-transformed x-axis with nice 
breakpoints for continuous data. The principles developed here can be 
generalized well to customize the plots regarding other aspects in which 
the customization depends on the data itself.

## The problem
<br/>
Recall from part one that we ended 
up with the following code to produce graphs for two different data types in 
our data frame with four columns.

{% highlight r %}
##  ............................................................................
##  get set up
library(tidyverse)
source("multiplot.R") # http://www.cookbook-r.com/Graphs/Multiple_graphs_on_one_page_(ggplot2)/
dta <- select(diamonds, price, cut, carat, color)


##  ............................................................................
##  ............................................................................
##  define helper functions
current_class <- function() {
  # returns the first class of the current iteration*
  class(dta[[get("g", parent.frame(n = 2))]])[1]
}
# * first element since object can have multiple classes

geom_hist_or_bar <- function() {
  color <- "gray"
  if (current_class() %in% c("integer", "numeric")) {
  geom_density(color = color, fill = color)
  } else if(current_class() %in% c("factor", "ordered")){
  geom_bar(color = color, fill = color)
  }
}

##  ............................................................................
##  create all plots
all_plots <- lapply(names(dta), function(g) {
  ggplot(dta, aes_(as.name(g))) + 
    geom_hist_or_bar()
  }
)


##  ............................................................................
##  compose plots
# use plotlist not ... as input
do.call("multiplot", list(plotlist = all_plots, cols = 2)) 
{% endhighlight %}

![plot of chunk unnamed-chunk-1](/figure/source/2016-10-11-ggplot2II-draft/unnamed-chunk-1-1.png)

Our goal is to alter the x-axis from a linear to a log-transformed scale.


## A fist solution
<br/>

On the first glance, this seems easy. Similarly to the first post of this series, 
we can create a new function `scale_x_adapt` which returns a continuous scale 
with a log transformation for continuous data and a discrete scale otherwise.
Then we can integrate it in our current framework.

{% highlight r %}
##  ............................................................................
##  create a scale function 
scale_x_adapt <- function(...) {
  if (current_class() %in% c("integer", "numeric")) {
    scale_x_continuous(...)
  } else {
    scale_x_discrete()
  }
}


##  ............................................................................
##  integrate this function in our lapply framework
all_plots <- lapply(names(dta), function(g) { 
  ggplot(dta, aes_(as.name(g))) + 
    geom_hist_or_bar() +
    scale_x_adapt(trans = "log")
})
all_plots[[1]]
{% endhighlight %}

![plot of chunk unnamed-chunk-2](/figure/source/2016-10-11-ggplot2II-draft/unnamed-chunk-2-1.png)

This seems fine, except for the fact that the break ticks are not really chosen
wisely. There are various ways to go about that:

- Resort to functionality from existing packages like `trans_breaks` (from the 
  scales package), `annotation_logticks` (ggplot2) and others.
- create your own function that returns pretty breaks.

We go for the second one because it is a slightly more general approach and I 
was not able to find a solution that pleased me four our specific case.

## A second solution
<br/>
We need to change the way the breaks are created within `scale_x_adapt`. 
To produce appropriate breaks, we need to know the maximum and the minimum of the 
data we are dealing (that is, the column that `lapply` currently passes over) 
and then create a sequence between the minimum and the maximum with some function.
Recall that we use a function `current_class` that does 
something similar to what we want. It get the class of the current data. Hence,
we can expand this function to get any property from our current data (and 
give the function a more general name).

{% highlight r %}
current_property <- function(f) {
  # returns a property of the current iteration object
  f(dta[[get("g", parent.frame(n = 2))]])[1]
}

# where the follwing is equivalent
current_class() 
current_property(f = class) 
{% endhighlight %}
Note the new argument f, which allows us get a wider range of properties of
the current data, not just the class, as `current_class` did. This is key 
for every customization that depends on the input data, because this function
can now get us virtually any information out of the data we could possibly want.
In our case, we are interested in the minimal and maximal 
value of the current data batch.

Next, we need is to create a function that, given a range, computes
some nice break values we can pass to the `breaks` argument of
`scale_x_continuous`. This task is independent of the rest of the framework we
are developing here. One function that does something that is close to what
we want is the following.

{% highlight r %}
### .. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
### break calculation
calc_log_breaks <- function(min, max,
                        length = 5,
                        correction = 2) {
  
  # calculate sequence of log values
  sequence <- seq(log(min), log(max), length.out = length)
  
  # exponentiate sequcence and round depending on range
  round(exp(sequence), -log10(max - min) + correction)
}
{% endhighlight %}
Let me break these lines into pieces. 

- The basic idea is  to create a sequence of breaks between the minimal and the 
  maximal value of the current data batch using `seq`.
- Since our plot is going to be on a logarithmic x-axis, we need to create a linear sequence 
  between `log(start)` and `log(end)` and transform it with `exp` so we end up
  with breaks that have the same distance on the logarithmic scale. It becomes
  evident that the solution presented above is suitable for a log-transformed
  axis, but if you choose an other transformation, e.g. the square root- 
  transformation, you need to adapt the function.
- We want to round the values depending on their absolute value. For example, 
  the values for carat (which are in the range of 0.2 to 5) should be rounded to
  maybe one decimal point, whereas the values of price (ranging up to 18'000) 
  should be rounded to thousands or ten thousands. 
  So note that `log10(10)` is one, `log10(100) = 2` and `log10(0.1) = -1` etc, which 
  is exactly what we need. We choose the rounding such 
  that the range of values matters and we round with regard to the range.
  
Finally, we can put it all together:

{% highlight r %}
##  ............................................................................
##  define helper-funtions
current_property <- function(f, n = 2) {
  # returns a property of the current iteration object
  f(dta[[get("g", parent.frame(n = n))]])[1]
}

# returns a histogram or a bar geom, depending on class
geom_hist_or_bar <- function() {
  color <- "gray"
  if (current_property(class) %in% c("integer", "numeric")) {
  geom_density(color = color, fill = color)
  } else {
  geom_bar(color = color, fill = color)
  }
}

### .. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
### break calculation

calc_log_breaks <- function(min, max,
                        length = 5,
                        correction = 2) {
  
  # calculate sequence of log values
  sequence <- seq(log(min), log(max), length.out = length)
  
  # exponentiate sequcence and round depending on range
  round(exp(sequence), -log10(max - min) + correction)
}

### .. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
### returns appropriate scale 

scale_x_adapt <- function(...) {
  if (current_property(class) %in% c("integer", "numeric")) {
    scale_x_continuous(breaks = calc_log_breaks(min = current_property(min), 
                                                max = current_property(max)), ...)
  } else {
    scale_x_discrete()
  }
  
}


##  ............................................................................
##  generate plots
all_plots <- lapply(names(dta), function(g) { 
  ggplot(dta, aes_(as.name(g))) + 
    geom_hist_or_bar() +
    scale_x_adapt(trans = "log")
})


##  ............................................................................
##  compose the plots 
# use plotlist not ... as input
do.call("multiplot", list(plotlist = all_plots, cols = 2)) 
{% endhighlight %}

![plot of chunk unnamed-chunk-5](/figure/source/2016-10-11-ggplot2II-draft/unnamed-chunk-5-1.png)

## Conclusion
<br/>

In this blog post, we introduced a new function, `scale_x_adapt` that returns a 
predefined scale for a given data type. It can be integrated in our framework 
similarly to `geom_hist_or_bar`. We created a more general version of 
`current_class`, `current_property` which takes a function as an argument and 
allows us evaluate this function to the currently processed data column.
In our example, this is helpful because using `current_property(min)`
and `current_property(max)`, we found out the range of the column we are 
processing and hence construct nice breakpoints with `calc_log_breaks` that were
used in `scale_x_adapt`.
