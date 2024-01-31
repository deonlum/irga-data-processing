## Functions

## Function to fix any encoding issues
fix_my_file = function(file_name = file.choose(), save_file = FALSE){
  
  ## storing filename and reading file in binary
  new_filename = paste0("./", gsub(".txt", "_fixed.txt", basename(file_name)))
  n = file.size(file_name)
  bin_file = readBin(file_name, 'raw', n = n)
  
  ## Removing nulls
  bin_file = bin_file[bin_file != 0L]
  
  ## Seems like the encoding issue mainly affects the reading of a new line
  ## (the entry is also replaced but not sure how to fix that)
  ## Fixing this by adding new lines to anything prior to a
  ## M5 value. Note this bit might need to change if measurement type != M5
  text = rawToChar(bin_file)
  fixed_data = gsub("(?<!\\r\\n)M5", "\r\nM5", text, perl = TRUE)
  
  fixed_data = read.table(text = fixed_data, fill = TRUE, quote = "",
                          sep = ",",
                          col.names = c("mtype", "date", "time", 
                                        "plot_no", "rec_no.",
                                        "CO2_ppm", "atm_pressure", 
                                        "sample_flow", "H2O_mb",
                                        "RH_temp", "O2_perc",
                                        "error_code", "voltage",
                                        "PAR", "soil_temp", 
                                        "air_temp", "RH",
                                        "p1", "p2", "p3",
                                        "p4", "p5"))
  
  if(save_file == TRUE){
    write.table(fixed_data, paste0(dropbox_path, "sample_data_fixed.txt"),
                quote = FALSE, row.names = FALSE)
  }
  
  fixed_data
}


## Function to retain only relevant rows. 
# This will work as long as there's no encoding issues with the txt file or if 
# there are, they are resolved such that any gibberish is in a single line 
# (run fix_my_file first). 
# Also this assumes that the measurement type is M5 (but this can be changed easily). 
# Measurements must have a start and end entry, which may not always be the case
# If so, could manually edit in your start/end values.
clean_my_file = function(my_data){
  
  # Numbers of starts and ends should correspond
  stopifnot(sum(my_data$mtype == "Start") == sum(my_data$mtype == "End"))
  
  start_indexes = which(my_data$mtype == "Start") 
  end_indexes = which(my_data$mtype == "End")
  
  cat("Measurement duration ranges from", min(end_indexes - start_indexes), 
      "to", max(end_indexes - start_indexes), "\n")
  
  ## We can pull out the relevant data with these indexes (we want one after start and one before end)
  # We'll also attach a label to each measurement session while doing this
  # so we can identify distinct measurement sessions
  my_data$m_session = 0
  for (i in 1:length(start_indexes)){
    my_data$m_session[(start_indexes[i]+1):(end_indexes[i]-1)] = i
  }
  
  ## Now we'll just keep all the measurement rows
  relevant_data = my_data[my_data$m_session != 0,]
  
  ## We'll now also ignore any rows that are not measurement M5
  relevant_data = relevant_data[relevant_data$mtype == "M5",]
  
  ## And also rows with NA (likely from encoding issues). We'll look at p3 for this.
  relevant_data = relevant_data[!is.na(relevant_data$p3),]
  
  ## Reindex data
  rownames(relevant_data) = 1:nrow(relevant_data)
  cat(nrow(my_data) - nrow(relevant_data), "rows removed", "\n")
  
  relevant_data
}


## This plots each measurement session (optional) and also returns a dataframe
# with the change in CO2 from start time to end time
plot_my_data = function(my_data, start_time = 1, end_time = 0, show_plots = TRUE){
  
  plot_val = numeric(length(unique(my_data$m_session)))
  delta_val = numeric(length(unique(my_data$m_session)))
  grad_val = numeric(length(unique(my_data$m_session)))
  r2_val = numeric(length(unique(my_data$m_session)))
  
  end_flag = TRUE
  if (end_time == 0){end_flag = FALSE} # Set a flag to know no end time provided
  
  for (my_session in unique(my_data$m_session)){
    
    curr_data = my_data[my_data$m_session == my_session,]
    curr_plot = curr_data$plot_no[1]
    
    # If end time is not provided, just use the whole dataset
    if(end_flag == FALSE) {end_time = nrow(curr_data)}
    
    plot_val[my_session] = curr_plot # Getting plot number
    calc_data = curr_data[start_time:end_time,] # Subsetting desired start/end
    delta_val[my_session] = tail(calc_data$p2, 1) - calc_data$p2[1]
    
    ## Fitting a lm, could cause errors here so doing a trycatch
    tryCatch({
      my_mod = lm(p2 ~ p3, data = calc_data)
      grad_val[my_session] = my_mod$coef[2]
      r2_val[my_session] = summary(my_mod)$r.squared
      
      pred_vals = data.frame(x = calc_data$p3,
                             y = predict(my_mod))
      
    }, error = function(e){cat("Issue fitting model:", conditionMessage(e), "\n")})
    
    
    if (show_plots == TRUE){
      my_title = paste("S:", my_session, "; Plot:", curr_plot)
      my_subtitle = paste("Total change =", delta_val[my_session])
      
      plot(curr_data$p3, curr_data$p2, xlab = "time", 
           ylab = expression(paste(Delta, " ppm")),
           type = 'l')
      mtext(side = 3, line = 2, cex = 1, my_title, font = 2)
      mtext(side = 3, line = 1, cex = 0.8, my_subtitle)
      
      tryCatch({lines(pred_vals$x, pred_vals$y, col = "red")})
      
      cat("plot", curr_plot, ": ", delta_val[my_session], "\n")
      
      readline("Press Enter to go to the next plot. Esc to stop.")
    }
    
  }
  
  data.frame(plot_no = plot_val, 
             delta = delta_val,
             grad = grad_val,
             r2 = r2_val,
             session = unique(my_data$m_session))
}
