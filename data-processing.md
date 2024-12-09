Processing EGM5 data
================

- [1 TL;DR workflow](#1-tldr-workflow)
- [2 Overview](#2-overview)
  - [2.1 A look at some data](#21-a-look-at-some-data)
  - [2.2 Resolving encoding errors](#22-resolving-encoding-errors)
  - [2.3 Cleaning up data](#23-cleaning-up-data)
  - [2.4 Analysing the data](#24-analysing-the-data)
  - [2.5 Varying start and end times in
    plot_my_data](#25-varying-start-and-end-times-in-plot_my_data)

# 1 TL;DR workflow

1)  Get the functions from the source file
2)  Input the appropriate `file_name` and run the functions in order.

``` r
devtools::source_url("https://raw.githubusercontent.com/deonlum/irga-data-processing/main/functions.R")
```

``` r
file_name = "./sample_data/sample_data_updated.txt"
fixed_data = fix_my_file(file_name)
clean_data = clean_my_file(fixed_data)
final_data = plot_my_data(clean_data, start_time = 31, end_time = 211, show_plots = FALSE)
final_data
```

    ##    plot_no delta       grad        r2 session start_time end_time
    ## 1       18    11 0.06479671 0.9834629       1         31      211
    ## 2       15    11 0.05693479 0.9693733       2         31      211
    ## 3       22     9 0.04884671 0.9693819       3         31      211
    ## 4       13     9 0.06027159 0.9640789       4         31      211
    ## 5        7    16 0.08515439 0.9763935       5         31      211
    ## 6        9    17 0.09013822 0.9769603       6         31      211
    ## 7        6    21 0.12318932 0.9918772       7         31      211
    ## 8       17    13 0.07624107 0.9859947       8         31      211
    ## 9       19    11 0.06298747 0.9841913       9         31      211
    ## 10      12    14 0.07540526 0.9819641      10         31      211
    ## 11      11    14 0.08876596 0.9570105      11         31      211
    ## 12      23    12 0.06795580 0.9804856      12         31      211
    ## 13      16    14 0.08128832 0.9562424      13         31      211
    ## 14      24    10 0.05368267 0.9764279      14         31      211
    ## 15      20    10 0.06082812 0.9689407      15         31      211
    ## 16       3    16 0.09321029 0.9867619      16         31      211
    ## 17      14    16 0.08824896 0.9902119      17         31      211
    ## 18       4    19 0.10432680 0.9889139      18         31      211
    ## 19      10    16 0.09770708 0.9786230      19         31      211
    ## 20      21     9 0.05589825 0.9627311      20         31      211
    ## 21       1    16 0.09010382 0.9885939      21         31      211
    ## 22       5    14 0.07546372 0.9765239      22         31      211
    ## 23       8    16 0.08754579 0.9875822      23         31      211
    ## 24       2    16 0.08762793 0.9894345      24         31      211

# 2 Overview

This is a set of three functions to help with processing the EGM5 data.
The functions take in the raw .txt files that are output by the machine
and help get it to a usable format. The first function `fix_my_file`
helps resolve the encoding issues that I encountered. The second
function `clean_my_file` helps remove any unnecessary rows in the raw
.txt files and produces a data.frame for downstream analysis. Finally,
the last function `plot_my_data` helps to plot the data, run a linear
model, and output a data.frame with some results.

We’ll begin by loading in the functions from `functions.R`. This can be
done in a few ways: (1) sourcing from the GitHub URL (simpler, always
updated; just make sure devtools is installed), (2) sourcing it from a
downloaded copy in your working directory, or (3) downloading the R
script and running it.

``` r
devtools::source_url("https://raw.githubusercontent.com/deonlum/irga-data-processing/main/functions.R") ## Source from URL

#source("functions.R") ## Or if sourcing from R script
```

## 2.1 A look at some data

We’ll have a look at some data I collected. Note the warning message
below.

``` r
file_name = "./sample_data/sample_data_updated.txt"
raw_data = read.table(file_name, fill = TRUE, sep = ",")
```

    ## Warning in scan(file = file, what = what, sep = sep, quote = quote, dec = dec,
    ## : embedded nul(s) found in input

``` r
head(raw_data[,1:8]) # truncating the output for neatness
```

    ##     V1       V2       V3 V4  V5  V6      V7   V8
    ## 1 Zero                   NA  NA  NA             
    ## 2   M5 15/10/23 10:49:01  1 648 476  1024.4  329
    ## 3   M5 15/10/23 10:49:05  1 652 479  1024.5  329
    ## 4   M5 15/10/23 10:49:09  1 656 478  1024.5  329
    ## 5   M5 15/10/23 10:49:13  1 660 481  1024.6  329
    ## 6   M5 15/10/23 10:49:17  1 664 481  1024.6  329

In this particular file, there are some encoding errors (which also
causes the “embedded nul(s)” warning). I’m not sure what exactly causes
it but I’ve had it in a few of my files. Some examples are in lines
14-15 and 644-645, where there appears to be some data that’s been cut
off or merged into the same line:

``` r
raw_data[12:15,1:8]
```

    ##       V1       V2       V3    V4      V5  V6      V7       V8
    ## 12    M5 15/10/23 10:49:41  1.00 688.000 485  1024.8      329
    ## 13 M24.7      329      0.0  0.00   0.000   0  0.0000        0
    ## 14    M5 15/10/23 10:49:33  1.00 680.000 484     1M5 15/10/23
    ## 15   0.0        0       88 85.26   8.087 956

``` r
raw_data[642:645,1:8]
```

    ##        V1       V2       V3  V4        V5       V6      V7       V8
    ## 642    M5 15/10/23 11:05:46  15 1650.0000 477.0000  1025.2      327
    ## 643 M55.2      327      0.0  21    0.0000   0.0000  0.0000        0
    ## 644    M5 15/10/23 11:05:44  15 1648.0000 477.0000     1M5 15/10/23
    ## 645   0.0       65        9 157    0.1427   0.1223

## 2.2 Resolving encoding errors

These lines can probably be completely removed without hindering the
results much, but in any case, we can fix this by running `fix_my_file`.
The function makes sure each line of data is entered properly as a new
line. This doesn’t remove the encoding gibberish which appears in some
lines but is good enough for now - we can remove these later.

Note that this fix won’t work properly if your measurement type is
different from mine (i.e., not M5… although it’s simple to change this),
or if you have other encoding issues. I’ve not come across others but if
you do, you could also perform this step manually by editing the .txt
file directly. I was originally processing files manually but it gets
tedious if you have to sift through a bunch of data files to check - and
could cause issues if data are erroneously deleted.

If you’re not sure if your file has similar issues, you can (should?)
run this anyway - it shouldn’t change your data if there aren’t issues.
At worst, there’s a (very low) possibility it’ll add some empty lines in
your file that get taken out with the next function. Also, the function
makes sure the data is in an appropriate format for `clean_my_file` by
giving it appropriate column names, so maybe just run this anyway.

``` r
fixed_data = fix_my_file(file_name)
fixed_data[11:16,1:8]
```

    ##    mtype     date     time plot_no rec_no. CO2_ppm atm_pressure sample_flow
    ## 11    M5 15/10/23 10:49:37       1     684     485       1024.8         329
    ## 12    M5 15/10/23 10:49:41       1     688     485       1024.8         329
    ## 13 M24.7      329      0.0       0       0       0          0.0           0
    ## 14    M5 15/10/23 10:49:33       1     680     484          1.0          NA
    ## 15    M5 15/10/23 10:49:49       1     696     486       1024.8         329
    ## 16    M5 15/10/23 10:49:53       1     700     486       1024.8         329

``` r
fixed_data[641:646,1:8]
```

    ##     mtype     date     time plot_no rec_no. CO2_ppm atm_pressure sample_flow
    ## 641    M5 15/10/23 11:05:44      15    1648     477       1025.2         327
    ## 642    M5 15/10/23 11:05:45      15    1649     477       1025.2         327
    ## 643    M5 15/10/23 11:05:46      15    1650     477       1025.2         327
    ## 644 M55.2      327      0.0      21       0       0          0.0           0
    ## 645    M5 15/10/23 11:05:44      15    1648     477          1.0          NA
    ## 646    M5 15/10/23 11:05:48      15    1652     477       1025.2         327

Lines 14 and 644 look fixed so we can move on to the next step.

Note that `fix_my_file` can be run without specifying the file name.
This will open a pop up window that you can navigate to select your data
file. I’ve also included an option to save out the fixed file into your
working directory, with “\_fixed” appended to the end (so e.g., if your
file is `my_data.txt` the new file will be `my_data_fixed.txt`). This
just allows for a more manual check to see if everything’s alright.

``` r
#fixed_data = fix_my_file() ## to choose a file
#fixed_data = fix_my_file(, save_file = TRUE) ## to save out a file
```

## 2.3 Cleaning up data

With the errors now fixed, we can run `clean_my_file`, which helps to
remove irrelevant rows and prepare the data for analysis. Note that
unlike `fix_my_file` which takes in a file name, `clean_my_file` takes
in an already read-in .txt file. We can just input `fixed_data` here.

``` r
clean_data = clean_my_file(fixed_data)
```

    ## Measurement duration ranges from 244 to 370 
    ## 545 rows removed

``` r
head(clean_data)
```

    ##   mtype     date     time plot_no rec_no. CO2_ppm atm_pressure sample_flow
    ## 1    M5 15/10/23 10:56:32      18    1098     466       1026.4         329
    ## 2    M5 15/10/23 10:56:33      18    1099     466       1026.3         329
    ## 3    M5 15/10/23 10:56:34      18    1100     467       1026.2         329
    ## 4    M5 15/10/23 10:56:35      18    1101     467       1026.2         329
    ## 5    M5 15/10/23 10:56:36      18    1102     467       1026.1         329
    ## 6    M5 15/10/23 10:56:37      18    1103     467       1026.1         329
    ##   H2O_mb RH_temp O2_perc error_code voltage PAR soil_temp air_temp RH p1 p2 p3
    ## 1      0      21       0          0       0   0         0        0  0 60  0  1
    ## 2      0      21       0          0       0   0         0        0  0 60  0  2
    ## 3      0      21       0          0       0   0         0        0  0 60  1  3
    ## 4      0      21       0          0       0   0         0        0  0 60  1  4
    ## 5      0      21       0          0       0   0         0        0  0 60  1  5
    ## 6      0      21       0          0       0   0         0        0  0 60  1  6
    ##   p4 p5 m_session
    ## 1  0  0         1
    ## 2  0  0         1
    ## 3  0  0         1
    ## 4  0  0         1
    ## 5  0  0         1
    ## 6  0  0         1

After running the function, only rows between “Start”s and “End”s are
retained. The function also prints the range of measurement duration -
this should be the length of time you measured for but can vary due to
issues with the data file - and tells you how many rows were removed
during the clean-up.

Additionally, a measurement session variable is appended which will
allow us to distinguish all the different sessions (i.e., one start/end
cycle). For example, `m_session` 1 was the first measurement I took that
day, which was for plot 18 at 10:56AM and `m_session` 2 was the second
one for plot 15 at 11:03AM. This might be useful in case you have
multiple measurements for the same plot (in my case, I sometimes abort
and rerun the same plot, so there’ll be two sessions with the same plot
number).

I have sometimes faced issues with unequal numbers of “Start”s and
“End”s from the raw file. Again, I’m not sure why this happens, but the
function will throw an error if they’re different. I can’t be confident
of when this issue pops up, so don’t want to automate this bit. To
resolve, you can manually edit the raw .txt file to delete the extra
“Start”s or “End”s and rerun the functions.

## 2.4 Analysing the data

After running `clean_my_file`, the data can be analysed in any way you
want. I wrote this final function `plot_my_data` for my own purpose. It
helps take a quick first look at the data so that I know whether I need
to rerun a measurement on that day (e.g., if there was a leak). As such,
it’s quite rigid in what it does, but could still be useful for analysis
depending on what you need.

`plot_my_data` has a few arguments you can input:

- `start_time` and `end_time` can be altered to limit analysis to the
  desired time. For example, if I wanted to discard the first 30
  seconds, I’d set `start_time = 31`, and if I wanted to end if 3
  minutes after, I’d set `end_time = 211`.

- `show_plots = TRUE` will allow you to run through all the individual
  plots, pressing enter each time to move to the next plot (hit esc to
  quit out of it). Informative but probably set `show_plots = FALSE` if
  you have a ton of plots. Note that it plots all measurements, ignoring
  the start/end time arguments.

As an example, here’s the final data set for the start and end times I
mention earlier:

``` r
final_data = plot_my_data(clean_data, start_time = 31, end_time = 211, show_plots = FALSE)
final_data
```

    ##    plot_no delta       grad        r2 session start_time end_time
    ## 1       18    11 0.06479671 0.9834629       1         31      211
    ## 2       15    11 0.05693479 0.9693733       2         31      211
    ## 3       22     9 0.04884671 0.9693819       3         31      211
    ## 4       13     9 0.06027159 0.9640789       4         31      211
    ## 5        7    16 0.08515439 0.9763935       5         31      211
    ## 6        9    17 0.09013822 0.9769603       6         31      211
    ## 7        6    21 0.12318932 0.9918772       7         31      211
    ## 8       17    13 0.07624107 0.9859947       8         31      211
    ## 9       19    11 0.06298747 0.9841913       9         31      211
    ## 10      12    14 0.07540526 0.9819641      10         31      211
    ## 11      11    14 0.08876596 0.9570105      11         31      211
    ## 12      23    12 0.06795580 0.9804856      12         31      211
    ## 13      16    14 0.08128832 0.9562424      13         31      211
    ## 14      24    10 0.05368267 0.9764279      14         31      211
    ## 15      20    10 0.06082812 0.9689407      15         31      211
    ## 16       3    16 0.09321029 0.9867619      16         31      211
    ## 17      14    16 0.08824896 0.9902119      17         31      211
    ## 18       4    19 0.10432680 0.9889139      18         31      211
    ## 19      10    16 0.09770708 0.9786230      19         31      211
    ## 20      21     9 0.05589825 0.9627311      20         31      211
    ## 21       1    16 0.09010382 0.9885939      21         31      211
    ## 22       5    14 0.07546372 0.9765239      22         31      211
    ## 23       8    16 0.08754579 0.9875822      23         31      211
    ## 24       2    16 0.08762793 0.9894345      24         31      211

- `plot_no` = plot number
- `delta` = total change in CO2 from start to end time
- `grad` = gradient of the fitted linear model (note this says nothing
  about the fit of the line)
- `r2` = R squared value of the fitted linear model
- `session` = measurement session

## 2.5 Varying start and end times in plot_my_data

Start and end times can now be varied in `plot_my_data` by entering them
as a vector in the start or end time argument.

``` r
# Arbitrarily setting some start and end times
my_start_times = 1:24
my_end_times = 120-1:24

final_data = plot_my_data(clean_data, start_time = my_start_times, end_time = my_end_times, show_plots = FALSE)
final_data
```

    ##    plot_no delta       grad        r2 session start_time end_time
    ## 1       18     6 0.04266486 0.8486891       1          1      119
    ## 2       15     7 0.05231608 0.9216851       2          2      118
    ## 3       22     6 0.05588297 0.8618288       3          3      117
    ## 4       13     5 0.04145319 0.8817171       4          4      116
    ## 5        7     8 0.06521587 0.9275215       5          5      115
    ## 6        9     7 0.08026133 0.9252733       6          6      114
    ## 7        6    10 0.09948767 0.9725055       7          7      113
    ## 8       17     8 0.06559196 0.9095944       8          8      112
    ## 9       19     8 0.06624786 0.9394579       9          9      111
    ## 10      12     7 0.06722190 0.9637371      10         10      110
    ## 11      11     6 0.05090909 0.8090733      11         11      109
    ## 12      23     8 0.08503840 0.9652318      12         12      108
    ## 13      16     6 0.06132419 0.9023766      13         13      107
    ## 14      24     7 0.06459073 0.9477380      14         14      106
    ## 15      20     5 0.04271381 0.8897932      15         15      105
    ## 16       3     6 0.07858359 0.9468011      16         16      104
    ## 17      14     9 0.09887366 0.9758248      17         17      103
    ## 18       4     8 0.09542701 0.9603205      18         18      102
    ## 19      10     6 0.07058898 0.9237426      19         19      101
    ## 20      21     4 0.03852755 0.7866383      20         20      100
    ## 21       1     8 0.09754138 0.9317145      21         21       99
    ## 22       5     6 0.05983490 0.8297346      22         22       98
    ## 23       8     6 0.08694168 0.9278745      23         23       97
    ## 24       2     5 0.07379983 0.9355765      24         24       96
