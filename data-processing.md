Processing EGM5 data
================

We’ll load the functions from the script on GitHub.

``` r
library(devtools)
```

    ## Warning: package 'devtools' was built under R version 4.1.2

    ## Loading required package: usethis

    ## Warning: package 'usethis' was built under R version 4.1.2

``` r
source("functions.R")
#source_url("https://github.com/deonlum/irga-data-processing/blob/main/functions.R")
```

We’ll have a look at some raw IRGA data I collected.

``` r
file_name = "./sample_data/sample_data.txt"
raw_data = read.table(file_name, fill = TRUE, sep = ",")
```

    ## Warning in scan(file = file, what = what, sep = sep, quote = quote, dec = dec, :
    ## embedded nul(s) found in input

``` r
head(raw_data)
```

    ##     V1       V2       V3 V4  V5  V6      V7   V8   V9 V10 V11 V12 V13 V14 V15
    ## 1 Zero                   NA  NA  NA                    NA  NA  NA  NA  NA  NA
    ## 2   M5 15/10/23 10:49:01  1 648 476  1024.4  329  0.0   0   0  50   0   0   0
    ## 3   M5 15/10/23 10:49:05  1 652 479  1024.5  329  0.0   0   0   0   0   0   0
    ## 4   M5 15/10/23 10:49:09  1 656 478  1024.5  329  0.0   0   0   0   0   0   0
    ## 5   M5 15/10/23 10:49:13  1 660 481  1024.6  329  0.0   0   0  24   0   0   0
    ## 6   M5 15/10/23 10:49:17  1 664 481  1024.6  329  0.0   0   0   0   0   0   0
    ##   V16 V17 V18 V19   V20   V21 V22
    ## 1  NA  NA  NA  NA    NA    NA  NA
    ## 2   0   0   0  88 85.26 8.065 583
    ## 3   0   0   0  88 85.26 8.068 612
    ## 4   0   0   0  88 85.26 8.071 644
    ## 5   0   0   0  88 85.26 8.074 676
    ## 6   0   0   0  88 85.26 8.077 711

In this particular file, there are some encoding errors. I’m not sure
what causes it but I’ve had it in a few of my files. Some examples:

``` r
raw_data[11:16,]
```

    ##       V1       V2       V3    V4      V5  V6      V7       V8       V9 V10 V11
    ## 11    M5 15/10/23 10:49:37  1.00 684.000 485  1024.8      329      0.0   0   0
    ## 12    M5 15/10/23 10:49:41  1.00 688.000 485  1024.8      329      0.0   0   0
    ## 13 M24.7      329      0.0  0.00   0.000   0  0.0000        0      0.0   0   0
    ## 14    M5 15/10/23 10:49:33  1.00 680.000 484     1M5 15/10/23 10:49:49   1 696
    ## 15   0.0        0       88 85.26   8.087 956                            NA  NA
    ## 16    M5 15/10/23 10:49:53  1.00 700.000 486  1024.8      329      0.0   0   0
    ##    V12    V13    V14   V15 V16 V17 V18 V19   V20   V21 V22
    ## 11   0    0.0   0.00 0.000   0   0   0  88 85.26 8.084 882
    ## 12   0    0.0   0.00 0.000   0   0   0  88 85.26 8.086 908
    ## 13   0   88.0  85.26 8.082 818  NA  NA  NA    NA    NA  NA
    ## 14 486 1024.8 329.00 0.000   0   0   0   0  0.00 0.000   0
    ## 15  NA     NA     NA    NA  NA  NA  NA  NA    NA    NA  NA
    ## 16   0    0.0   0.00 0.000   0   0   0  88 85.26 8.087 974

``` r
raw_data[641:646,]
```

    ##        V1       V2       V3  V4        V5       V6      V7       V8       V9
    ## 641    M5 15/10/23 11:05:45  15 1649.0000 477.0000  1025.2      327      0.0
    ## 642    M5 15/10/23 11:05:46  15 1650.0000 477.0000  1025.2      327      0.0
    ## 643 M55.2      327      0.0  21    0.0000   0.0000  0.0000        0      0.0
    ## 644    M5 15/10/23 11:05:44  15 1648.0000 477.0000     1M5 15/10/23 11:05:48
    ## 645   0.0       65        9 157    0.1427   0.1223                          
    ## 646    M5 15/10/23 11:05:49  15 1653.0000 478.0000  1025.2      328      0.0
    ##     V10  V11 V12    V13 V14    V15     V16 V17 V18 V19 V20    V21    V22
    ## 641  21    0   0    0.0   0 0.0000  0.0000   0  65   9 154 0.1417 0.1249
    ## 642  21    0   0    0.0   0 0.0000  0.0000   0  65   9 155 0.1420 0.1240
    ## 643   0    0  65    9.0 152 0.1408  0.1274  NA  NA  NA  NA     NA     NA
    ## 644  15 1652 477 1025.2 327 0.0000 21.0000   0   0   0   0 0.0000 0.0000
    ## 645  NA   NA  NA     NA  NA     NA      NA  NA  NA  NA  NA     NA     NA
    ## 646  21    0   0    0.0   0 0.0000  0.0000   0  65   9 158 0.1432 0.1208

We can fix this by running fix_my_file. What this does is make sure
every proper data line is entered as a new line. So we don’t get issues
like in lines 14 and 644. It won’t work properly if your measurement
type is different (i.e., not M5), or if you have other encoding issues.
I’ve not come across others but if you do, you could also do this step
manually by editing the txt file directly.

If you’re not sure if you do have issues, you could run this anyway - it
shouldn’t change your data.

``` r
fixed_data = fix_my_file(file_name)
fixed_data[11:16,]
```

    ##    mtype     date     time plot_no rec_no. CO2_ppm atm_pressure sample_flow
    ## 11    M5 15/10/23 10:49:37       1     684     485       1024.8         329
    ## 12    M5 15/10/23 10:49:41       1     688     485       1024.8         329
    ## 13 M24.7      329      0.0       0       0       0          0.0           0
    ## 14    M5 15/10/23 10:49:33       1     680     484          1.0          NA
    ## 15    M5 15/10/23 10:49:49       1     696     486       1024.8         329
    ## 16    M5 15/10/23 10:49:53       1     700     486       1024.8         329
    ##    H2O_mb RH_temp O2_perc error_code voltage   PAR soil_temp air_temp RH p1 p2
    ## 11      0       0       0          0       0  0.00     0.000        0  0  0 88
    ## 12      0       0       0          0       0  0.00     0.000        0  0  0 88
    ## 13      0       0       0          0      88 85.26     8.082      818 NA NA NA
    ## 14     NA      NA      NA         NA      NA    NA        NA       NA NA NA NA
    ## 15      0       0       0          0       0  0.00     0.000        0  0  0 88
    ## 16      0       0       0          0       0  0.00     0.000        0  0  0 88
    ##       p3    p4  p5
    ## 11 85.26 8.084 882
    ## 12 85.26 8.086 908
    ## 13    NA    NA  NA
    ## 14    NA    NA  NA
    ## 15 85.26 8.087 956
    ## 16 85.26 8.087 974

``` r
fixed_data[641:646,]
```

    ##     mtype     date     time plot_no rec_no. CO2_ppm atm_pressure sample_flow
    ## 641    M5 15/10/23 11:05:44      15    1648     477       1025.2         327
    ## 642    M5 15/10/23 11:05:45      15    1649     477       1025.2         327
    ## 643    M5 15/10/23 11:05:46      15    1650     477       1025.2         327
    ## 644 M55.2      327      0.0      21       0       0          0.0           0
    ## 645    M5 15/10/23 11:05:44      15    1648     477          1.0          NA
    ## 646    M5 15/10/23 11:05:48      15    1652     477       1025.2         327
    ##     H2O_mb RH_temp O2_perc error_code voltage PAR soil_temp air_temp RH p1 p2
    ## 641      0      21       0          0       0   0    0.0000   0.0000  0 65  9
    ## 642      0      21       0          0       0   0    0.0000   0.0000  0 65  9
    ## 643      0      21       0          0       0   0    0.0000   0.0000  0 65  9
    ## 644      0       0       0         65       9 152    0.1408   0.1274 NA NA NA
    ## 645     NA      NA      NA         NA      NA  NA        NA       NA NA NA NA
    ## 646      0      21       0          0       0   0    0.0000   0.0000  0 65  9
    ##      p3     p4     p5
    ## 641 153 0.1413 0.1261
    ## 642 154 0.1417 0.1249
    ## 643 155 0.1420 0.1240
    ## 644  NA     NA     NA
    ## 645  NA     NA     NA
    ## 646 157 0.1427 0.1223

Lines 14 and 644 are now fixed. We can now run clean_my_file, which
helps to remove irrelevant rows and prepare it for analysis.

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

Only rows between start and stop are retained. Additionally, a
measurement session variable has now been included to allow us to
distinguish all the different sessions (i.e., one start/stop cycle). For
example, m_session = 1 was the first measurement I took that day, which
was for plot 18 at 10:56AM and m_session = 2 was the second one for plot
15 at 11:03AM. This might be useful in case you have multiple
measurements for the same plot (in my case, I sometimes abort and rerun
the same plot, so there’ll be two sessions with the same plot number).

The data can be analysed at this point. The final function plot_my_data
was written as what I needed it to be. But you can probably just process
the clean_data dataframe in anyway you want.

``` r
final_data = plot_my_data(clean_data, show_plots = FALSE)
final_data
```

    ##    plot_no resp       grad session
    ## 1       18   15 0.06631590       1
    ## 2       15   16 0.06308323       2
    ## 3       22   13 0.05598151       3
    ## 4       13   11 0.05541577       4
    ## 5        7   20 0.08688501       5
    ## 6        9   22 0.09687094       6
    ## 7        6   24 0.11892822       7
    ## 8       17   19 0.07514507       8
    ## 9       19   15 0.06701168       9
    ## 10      12   19 0.08170205      10
    ## 11      11   21 0.08830355      11
    ## 12      23   14 0.06094580      12
    ## 13      16   19 0.08391168      13
    ## 14      24   14 0.05721233      14
    ## 15      20   16 0.06160086      15
    ## 16       3   21 0.09425372      16
    ## 17      14   19 0.08376265      17
    ## 18       4   23 0.10348220      18
    ## 19      10   20 0.09472303      19
    ## 20      21   10 0.05336542      20
    ## 21       1   19 0.08817726      21
    ## 22       5   18 0.08023612      22
    ## 23       8   20 0.09068975      23
    ## 24       2   19 0.08689989      24
