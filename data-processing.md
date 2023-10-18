Processing EGM5 data
================
deon

-   <a href="#1-tldr-workflow" id="toc-1-tldr-workflow">1 TL;DR workflow</a>
-   <a href="#2-overview" id="toc-2-overview">2 Overview</a>
    -   <a href="#21-a-look-at-some-data" id="toc-21-a-look-at-some-data">2.1 A
        look at some data</a>
    -   <a href="#22-resolving-encoding-errors"
        id="toc-22-resolving-encoding-errors">2.2 Resolving encoding errors</a>
    -   <a href="#23-cleaning-up-data" id="toc-23-cleaning-up-data">2.3 Cleaning
        up data</a>
    -   <a href="#24-analysing-the-data" id="toc-24-analysing-the-data">2.4
        Analysing the data</a>

# 1 TL;DR workflow

1)  Get the functions from the source file
2)  Input the irga file_name and run the functions in order.

``` r
source("functions.R")
file_name = "./sample_data/sample_data.txt"
fixed_data = fix_my_file(file_name)
clean_data = clean_my_file(fixed_data)
final_data = plot_my_data(clean_data, start_time = 31, end_time = 211, show_plots = FALSE)
final_data
```

    ##    plot_no delta       grad session
    ## 1       18    11 0.06479671       1
    ## 2       15    11 0.05712723       2
    ## 3       22     9 0.04880192       3
    ## 4       13     9 0.06027159       4
    ## 5        7    16 0.08527190       5
    ## 6        9    17 0.09013822       6
    ## 7        6    22 0.12339117       7
    ## 8       17    13 0.07624107       8
    ## 9       19    11 0.06298747       9
    ## 10      12    14 0.07540526      10
    ## 11      11    14 0.08890071      11
    ## 12      23    12 0.06795580      12
    ## 13      16    14 0.08128832      13
    ## 14      24    10 0.05373219      14
    ## 15      20    10 0.06082812      15
    ## 16       3    16 0.09321029      16
    ## 17      14    16 0.08824294      17
    ## 18       4    19 0.10432680      18
    ## 19      10    16 0.09770708      19
    ## 20      21     9 0.05597312      20
    ## 21       1    16 0.09010382      21
    ## 22       5    14 0.07560008      22
    ## 23       8    16 0.08754579      23
    ## 24       2    16 0.08773099      24

# 2 Overview

This is a set of three functions to help with processing the EGM5 data.
The functions take in the raw .txt files that are output by the machine
and help get it to a usable format. The first function “fix_my_file”
helps resolve the encoding issues that I encountered. The second
function “clean_my_file” helps remove any unnecessary rows in the raw
.txt files and produces a data.frame for downstream analysis. Finally,
the last function “plot_my_data” helps to plot the data, run a linear
model, and output a data.frame with some results.

We’ll begin my loading the functions. This can be done by sourcing from
the GitHub URL or the R script itself.

``` r
source("functions.R")

#library(devtools)
#source_url("https://github.com/deonlum/irga-data-processing/blob/main/functions.R")
```

## 2.1 A look at some data

We’ll have a look at some data I collected. Note the warning message
below.

``` r
file_name = "./sample_data/sample_data.txt"
raw_data = read.table(file_name, fill = TRUE, sep = ",")
```

    ## Warning in scan(file = file, what = what, sep = sep, quote = quote, dec = dec, :
    ## embedded nul(s) found in input

``` r
head(raw_data[,1:7]) # truncating the output for neatness
```

    ##     V1       V2       V3 V4  V5  V6      V7
    ## 1 Zero                   NA  NA  NA        
    ## 2   M5 15/10/23 10:49:01  1 648 476  1024.4
    ## 3   M5 15/10/23 10:49:05  1 652 479  1024.5
    ## 4   M5 15/10/23 10:49:09  1 656 478  1024.5
    ## 5   M5 15/10/23 10:49:13  1 660 481  1024.6
    ## 6   M5 15/10/23 10:49:17  1 664 481  1024.6

In this particular file, there are some encoding errors (which also
causes the “embedded nul(s)” warning). I’m not sure what exactly causes
it but I’ve had it in a few of my files. Some examples are in lines
14/15 and 644/645, where there appears to be some data that’s been cut
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
results much, but in any case, we can fix this by running fix_my_file.
The function makes sure each line of data is entered properly as a new
line. This doesn’t remove the encoding gibberish which appears in some
lines but is good enough for now - we can remove these later.

Note that this fix won’t work properly if your measurement type is
different from mine (i.e., not M5 although it’s simple to change it to
work for anything else), or if you have other encoding issues. I’ve not
come across others but if you do, you could also perform this step
manually by editing the .txt file directly. I was originally processing
files manually but it gets tedious if you have to sift through a bunch
of data files to check - and could cause issues if data are errorneously
deleted.

If you’re not sure if your file has similar issues, you can (should?)
run this anyway - it shouldn’t change your data if there aren’t issues.
At worst, there’s a (very low) possibility it’ll add some empty lines in
your file that get taken out with the next function. Also, the function
makes sure the data is in an appropriate format for clean_my_file by
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

Note that fix_my_file can be run without specifying the file name. This
will open a pop up where you can select your data file to input. I’ve
also included an option to save out the fixed file into your working
directory, with “\_fixed” appended to the end (so e.g., if your file is
“my_data.txt” the new file will be “my_data_fixed.txt”). This just
allows a more manual check to see if everything’s alright.

``` r
#fixed_data = fix_my_file()
#fixed_data = fix_my_file(, save_file = TRUE)
```

## 2.3 Cleaning up data

With the errors now fixed, we can now run clean_my_file, which helps to
remove irrelevant rows and prepare the data for analysis. Note that
unlike fix_my_file which takes in a file name, clean_my_file takes in an
already read-in .txt file. We can just input “fixed_data” here.

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

Only rows between “Start” and “End” are retained. Additionally, a
measurement session variable is appended which will allow us to
distinguish all the different sessions (i.e., one start/end cycle). For
example, m_session = 1 was the first measurement I took that day, which
was for plot 18 at 10:56AM and m_session = 2 was the second one for plot
15 at 11:03AM. This might be useful in case you have multiple
measurements for the same plot (in my case, I sometimes abort and rerun
the same plot, so there’ll be two sessions with the same plot number).

I have sometimes faced issues with unequal numbers of “Start”s and
“End”s. Again, I’m not sure why this happens, but it’s easy to fix by
manually editing the .txt file to delete the extra “Start”s or “End”s.

## 2.4 Analysing the data

After running clean_my_file, the data can be analysed in a number of
ways. This final function (plot_my_data) was written to be what I needed
it to be. But you can probably just process the clean_data dataframe in
any way you want.

plot_my_data has a few arguments you can input:

-   start_time and end_time can be altered to limit analysis to the
    desired time. For example, if I wanted to discard the first 30
    seconds, I’d set start_time = 31, and if I wanted to end if 3
    minutes after, I’d set end_time = 211.

-   show_plots = TRUE will allow you to run through all the individual
    plots, pressing enter each time to move to the next plot (hit esc to
    quit out of it). Informative but probably set show_plots = FALSE if
    you have a ton of plots. Note that it plots all measurements,
    ignoring the start_time/end_time arguments.

As an example, here’s the final data set for the start and end times I
mention earlier:

``` r
final_data = plot_my_data(clean_data, start_time = 31, end_time = 211, show_plots = FALSE)
final_data
```

    ##    plot_no delta       grad session
    ## 1       18    11 0.06479671       1
    ## 2       15    11 0.05712723       2
    ## 3       22     9 0.04880192       3
    ## 4       13     9 0.06027159       4
    ## 5        7    16 0.08527190       5
    ## 6        9    17 0.09013822       6
    ## 7        6    22 0.12339117       7
    ## 8       17    13 0.07624107       8
    ## 9       19    11 0.06298747       9
    ## 10      12    14 0.07540526      10
    ## 11      11    14 0.08890071      11
    ## 12      23    12 0.06795580      12
    ## 13      16    14 0.08128832      13
    ## 14      24    10 0.05373219      14
    ## 15      20    10 0.06082812      15
    ## 16       3    16 0.09321029      16
    ## 17      14    16 0.08824294      17
    ## 18       4    19 0.10432680      18
    ## 19      10    16 0.09770708      19
    ## 20      21     9 0.05597312      20
    ## 21       1    16 0.09010382      21
    ## 22       5    14 0.07560008      22
    ## 23       8    16 0.08754579      23
    ## 24       2    16 0.08773099      24

-   plot_no = plot number
-   delta = total change in CO2 from start to end time
-   grad = gradient of the fitted linear model (note this says nothing
    about the fit of the line)
-   session = measurement session
