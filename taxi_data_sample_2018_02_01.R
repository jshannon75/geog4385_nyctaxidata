library(tidyverse)
library(sf)
library(lubridate)
library(stringr)

taxi_data <- read_csv("2016_Yellow_Taxi_Trip_Data.csv") %>%
  filter(trip_distance>0 & fare_amount>0) %>%
  mutate(pickup_time=parse_date_time(tpep_pickup_datetime, '%m/%d/%y %I:%M:%S %p'),
         dropoff_time=parse_date_time(tpep_dropoff_datetime, '%m/%d/%y %I:%M:%S %p'))

start<-as.Date("2016/04/02")
cutoff<-as.Date("2016/04/08")

taxi_data_sample<- taxi_data %>%
  filter(pickup_time >=start & pickup_time <= cutoff &
         pickup_longitude> -74.1 & pickup_longitude< -73.66 &
         pickup_latitude>40.6 & pickup_latitude<40.9 &
         dropoff_longitude> -74.1 & dropoff_longitude< -73.66 &
         dropoff_latitude>40.6 & dropoff_latitude<40.9) %>%
  sample_n(200000) %>%
  mutate(recordIDnum=c(1:nrow(.)),
         recordID=paste("T",str_pad(recordIDnum, 6, pad = "0"),sep=""),
         tipfare_rat=tip_amount/fare_amount)

taxi_data_select<- taxi_data_sample %>%
  select(recordID,pickup_time,dropoff_time,pickup_longitude,pickup_latitude,dropoff_longitude,dropoff_latitude,tipfare_rat)

write_csv(taxi_data_select,"taxi_data_subset_nyc_ratios_200k.csv")

taxi_data_sf<-st_as_sf(taxi_data_select,coords=c("pickup_longitude","pickup_latitude"),crs=4326)

st_write(taxi_data_sf,"taxi_data_subset_nyc_ratios_100k_shp.shp")

#Make data long
taxi_data_drop<-taxi_data_select %>%
  select(recordID,dropoff_latitude,dropoff_longitude) %>%
  mutate(type="dropoff") %>%
  rename("Y"=dropoff_latitude,
         "X"=dropoff_longitude)

taxi_data_pickup<-taxi_data_select %>%
  select(recordID,pickup_latitude,pickup_longitude) %>%
  mutate(type="pickup") %>%
  rename("Y"=pickup_latitude,
         "X"=pickup_longitude)

taxi_data_long<-rbind(taxi_data_pickup,taxi_data_drop)

write_csv(taxi_data_long,"taxi_data_nyc_long_1k.csv")

taxi_data_long_sf<-st_as_sf(taxi_data_long,coords=c("X","Y"),crs=4326)

st_write(taxi_data_long_sf,"taxi_data_nyx_long_1k_shp.shp")
