---
title: "strcode - structure and abstract your code"
description: strcode provides tools to bring more structure into your code. 
  Its main functionality is inserting code breaks and summarising code.
permalink: /strcode_int/
tags: workflow
layout: post
comments: true
date: "2016-12-01 12:35"
---


## Introduction
I am pleased to announce my package strcode (short for structuring code), a package that should make structuring code easer. You can install it from github, a CRAN release is planned at a later stage.

{% highlight r %}
devtools::install_github("lorenzwalthert/strcode")
{% endhighlight %}


## Inserting code breaks with ease
The main feature of the package is its function to insert code breaks. These are helpful in breaking the code down to smaller sections. We suggest three levels of granularity for code structuring, whereas higher-level blocks can contain lower-level blocks:

- level 1 sections, which are high-level blocks that can be separated as follows:

{% highlight r %}
#   ________________________________________________________
#   A title                                             ####
{% endhighlight %}

- level 2 sections, which are medium-level blocks that can be separated as follows:

{% highlight r %}
##  ........................................................
##  A subtitle                                          ####
{% endhighlight %}


- level 3 sections, which are low-level blocks that can be separated as follows:

{% highlight r %}
### . . . . . . . . . . . . . . . . . . . . . . . . . . . ..
### Another one                                         ####
{% endhighlight %}


You can notice from the above that

* The number of `#` used in front of the break character (`___`, `...`, `. .`) corresponds to the level of granularity that is separated.
* The breaks characters `___`, `...`, `. .` were chosen such that they reflect the level of granularity, namely `___` has a much higher visual density than `. .`. 
* Each block has an (optional) short title on what that block is about.
* Every title ends with `####`. Therefore, the titles are recognized by RStudio as [sections](https://support.rstudio.com/hc/en-us/articles/200484568-Code-Folding-and-Sections). This has the advantages that you can get a quick summary of your code in Rstudio's code pane and you can fold sections as you can fold code or function declarations or if statements. See the pictures below for details.

The separators all have length 80. The value is looked up in the global option `strcode$char_length` and can therefore be changed by the user.






The `strcode` (short for structuring code) package contains tools to organize and abstract your code better. It consists of

- An [RStudio Add-in](https://rstudio.github.io/rstudioaddins/) that lets you quickly add code block separators and titles to break your work into sections. Optionally, these sections can have a unique identifier. The titles are recognized as sections by RStudio, which enhances the coding experience further.
- A function `sum_str` that summarizes the code structure based on the separators and their comments added with the Add-in. For one or more files, it can cat the structure to the console or a file.
- An [RStudio Add-in](https://rstudio.github.io/rstudioaddins/) that lets you insert a code anchor, that is, a hash sequence which can be used to uniquely identify a line in a large code base.
