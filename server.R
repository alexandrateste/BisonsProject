library(stringr)
library(lubridate)
library(aspace)
library(plyr)
library(sp)
library(rgdal)
library(ggplot2)
library(scales)
library(xts)
library(gridExtra)

# Load data from file
merged_data<-read.csv(file="DunnRanchBisonTrackingProject_2013_DataOnly.csv", header=TRUE, sep=",")

# Distance function to be used in the cumulative distance calculations
ddistance <- function(lat1,long1,lat2,long2){
        lat1<-as_radians(lat1)
        lat2<-as_radians(lat2)
        long1<-as_radians(long1)
        long2<-as_radians(long2)
        R <- 6371000 # Earth mean radius [m]
        delta.long <- (long2 - long1)
        delta.lat <- (lat2 - lat1)
        a <- sin(delta.lat/2)^2 + cos(lat1) * cos(lat2) * sin(delta.long/2)^2
        c <- 2 * atan2(sqrt(a),sqrt(1-a))
        dist = R * c
        return(dist) # Distance in m
}


shinyServer(
        function(input, output, session) {
                output$replicateddate  <- renderText({
                        paste("You chose the date of", as.character(format(input$chosendate, "%B %d, %Y")))
                })
                actualdate<- reactive({as.Date(as.character(input$chosendate))})
                output$yyear <- renderText({year(actualdate())})
                output$mois <- renderText({as.numeric(format(actualdate(), "%m"))})
                output$dday <- renderText({day(actualdate())})

                # Extraction of data for the specific day selected by the user
                daily_df0 <- reactive({
                        subset_df<-subset(merged_data, year == as.numeric(format(actualdate(), "%Y")) & month == as.numeric(format(actualdate(), "%m")) & day == as.numeric(format(actualdate(), "%d")))
                })

                # List of animals for which data are present for that day
                uniqnames <- reactive({
                        daily_df <- daily_df0()
                        uniq_names <- unique(factor(daily_df$animal.id))
                })

                observe({
                        daily_df <- daily_df0()
                        par(mfrow=c(1,1))
                        })

                        # Display of the map centered on the Dunn Ranch Prairie
                        output$mymap <- renderLeaflet({
                                daily_df <- daily_df0()
                        leaflet(daily_df) %>% addTiles(urlTemplate="http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}") %>% 
                                        fitBounds(~-94.12, ~40.47, ~-94.078, ~40.487)
                        })

                
                
                observe({
                        daily_df <- daily_df0()
                        
                        # Definition of the color palette
                        pal <- colorFactor(
                                        palette = "RdYlBu",
                                domain = factor(daily_df$animal.id)
                        )
                        
                        # Plot of the actual trajectory of each of the bisons with data for that day
                        for (uni in uniqnames()){
                                indiv_df <- subset(daily_df,animal.id == uni)
                                # Removal of NAs to allow for actual display on the Shiny App
                                indiv_df <- indiv_df[!is.na(indiv_df$location.lat),]
                                indiv_df <- indiv_df[!is.na(indiv_df$location.long),]
                                leafletProxy("mymap", data = indiv_df) %>% addTiles(urlTemplate="http://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}") %>% 
                                        addPolylines(lng = ~location.long, lat = ~location.lat, 
                                                     color = ~pal(uni), weight = 2,fillOpacity = 10.)
                        }
                        
                        # Addition of the map legend
                        leafletProxy("mymap", data = daily_df) %>% addLegend(position = "bottomleft", pal = pal, values = ~animal.id)
                        
                })

                # Calculation of the cumulative distance travelled & graphical representation
                output$travdist <- renderPlot({
                        if (input$travbox){
                                counter <- 0
                                daily_df <- daily_df0()
                                for (uni in uniqnames()){
                                        # Extraction of the data for bison #uni
                                        indiv_df <- subset(daily_df,animal.id == uni)
                                        nbertimes<-dim(indiv_df)[1]
                                        distovertime_each <- numeric(nbertimes)
                                        distovertime_each[1]<-NA
                                        distovertime <- numeric(nbertimes)
                                        distovertime[1] <- 0
                                        counter <- counter +1
                                        summ <- 0
                                        # Calculation of the distance between 2 consecutive points
                                        # and of the cumulative distance
                                        for (j in 2:nbertimes){
                                                latt1<-indiv_df$location.lat[j-1]
                                                latt2<-indiv_df$location.lat[j]
                                                longg1<-indiv_df$location.long[j-1]
                                                longg2<-indiv_df$location.long[j]
                                                distovertime_each[j]<-ddistance(latt1,longg1,latt2,longg2)
                                                if (!is.na(distovertime_each[j])){
                                                        summ <- summ + distovertime_each[j]
                                                }
                                                distovertime[j]<-summ/1000.
                                                
                                        }
                                        # Construction of a dataframe that contains the cumulative distances of bison #uni
                                        dist_df <-data.frame(timestamp=indiv_df$timestamp,value=distovertime,animal.id=rep(uni,nbertimes))
                                        names(dist_df)[2] <- "travelled.dist"
                                        
                                        # Resampling at 15 min to allow for an easier reading of the final plot
                                        dist_df$timestamp<-as.POSIXlt(as.character(dist_df$timestamp), format="%Y-%m-%d %H:%M:%S")
                                        tmpxts <- xts(dist_df[,2], order.by=dist_df[,1]) # Transformation of the column into a time series object
                                        ep <- endpoints(tmpxts,'minutes', 15) # Search for the last timestamp in a 15min time window
                                        convert<-period.apply(tmpxts, INDEX=ep, FUN=function(x) sum(x,na.rm=TRUE)) # Summation of all distances in that 15min window
                                        converted_df <-data.frame(timestamp=index(convert),value=coredata(convert),idd=rep(uni,length(index(convert)))) # Construction of a dataframe
                                        names(converted_df) <- c("timestamp","travelled.dist","animal.id")

                                        # Construction of a master dataframe with the cumulative distance of all animals
                                        if (counter == 1){
                                                master_dist_df <- converted_df
                                        }
                                        else{
                                                master_dist_df <- rbind(master_dist_df,converted_df)
                                        }
                                }
                                
                                # Conversion of the animal IDs into factors for better handling of the color palette
                                master_dist_df$animal.id <- factor(master_dist_df$animal.id)
                                # Removal of NAs
                                master_dist_df <- master_dist_df[!is.na(master_dist_df$travelled.dist),]

                                # Construction of the cumulative distance plot
                                p <- ggplot(master_dist_df, aes(x=timestamp, y=travelled.dist, group=animal.id)) + 
                                        geom_line(aes(colour = animal.id)) + 
                                        scale_color_brewer(palette="RdYlBu") + 
                                        labs(x = "Time of day", y ="Distance (km)") +
                                        ggtitle("Cumulative distance travelled over time")
                        }
                        
                        if (input$speedbox){
                                daily_df <- daily_df0()
                                counter <- 0
                                for (uni in uniqnames()){
                                        # Extraction of the data for bison #uni
                                        indiv_df <- subset(daily_df,animal.id == uni)
                                        
                                        # Resampling at 15 min to allow for an easier reading of the final plot                                        
                                        indiv_df$timestamp<-as.POSIXlt(as.character(indiv_df$timestamp), format="%Y-%m-%d %H:%M:%S")
                                        tmpxts <- xts(indiv_df$ground.speed, order.by=indiv_df$timestamp) # Transforms the column into a time series object
                                        ep <- endpoints(tmpxts,'minutes', 15) # Finds the last timestamp in a 15min time window
                                        convert2<-period.apply(tmpxts, INDEX=ep, FUN=function(x) mean(x,na.rm=TRUE)) # Average of all ground speeds in that 15min window
                                        converted_df2 <-data.frame(timestamp=index(convert2),value=coredata(convert2),idd=rep(uni,length(index(convert2)))) # Construction of a dataframe
                                        names(converted_df2) <- c("timestamp","ground.speed","animal.id")
                                        
                                        counter <- counter + 1
                                        
                                        # Construction of a master dataframe with the ground speed of all animals
                                        if (counter == 1){
                                                master_dist_df2 <- converted_df2
                                        }
                                        else{
                                                master_dist_df2 <- rbind(master_dist_df2,converted_df2)
                                        }                                        
                                }
                                # Conversion of the animal IDs into factors for better handling of the color palette
                                master_dist_df2$animal.id <- factor(master_dist_df2$animal.id)
                                
                                # Construction of the ground speed plot
                                p2 <- ggplot(master_dist_df2, aes(x=timestamp, y=ground.speed, group=animal.id)) + 
                                        geom_line(aes(colour = animal.id)) + scale_color_brewer(palette="RdYlBu") +
                                        labs(x = "Time of day", y ="Ground speed (km/h)") +
                                        ggtitle("Average speed")
                        }
                        
                        # Actual display of the plots
                        if ((input$travbox) & (input$speedbox)){
                                grid.arrange(p, p2, nrow=2)                                
                        }
                        else if (input$travbox){
                                print(p)                                
                                }
                        else if (input$speedbox){
                                print(p2)                               
                        }
                })
        }
)