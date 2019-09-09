import numpy as np
import matplotlib.pyplot as plt
import pandas as pd 
import os
import random
from shapely.geometry import Point, MultiPoint

def read(filename):
    """
    Reads a file extracting the colums that has relevant information,
    the output is a list of len 6.
    """
    date_a = pd.read_fwf(filename, comment='#', usecols=[0], keep_default_na=False )
    date_b = date_a.convert_objects(convert_numeric=True)
    date = np.asarray(date_b)
    hour_a = pd.read_fwf(filename, comment='#', keep_default_na=False, usecols=[1] )
    hour_b = hour_a.convert_objects(convert_numeric=True)
    hour = np.asarray(hour_b)

    mag_a = pd.read_fwf(filename, comment='#', keep_default_na=False, usecols=[4])
    mag_b = mag_a.convert_objects(convert_numeric=True)
    mag = np.asarray(mag_b)

    lat_a = pd.read_fwf(filename, comment='#', keep_default_na=False, usecols=[6])
    lat_b = lat_a.convert_objects(convert_numeric=True)
    lat = np.asarray(lat_b)

    lon_a = pd.read_fwf(filename, comment='#', keep_default_na=False, usecols=[7])
    lon_b = lon_a.convert_objects(convert_numeric=True)
    lon = np.asarray(lon_b)

    depth_a = pd.read_fwf(filename, comment='#', keep_default_na=False, usecols=[8])
    depth_b = depth_a.convert_objects(convert_numeric=True)
    depth = np.asarray(depth_b)   
    mask = np.all(np.isnan(mag) | np.equal(mag, 0), axis=1)
    mag = mag[~mask]
    date = date[~mask]
    hour = hour[~mask]
    lat = lat[~mask]
    lon = lon[~mask]
    depth =depth [~mask]
    
    data = []
    data.append(date)
    data.append(hour)    
    data.append(mag)
    data.append(lat)
    data.append(lon)
    data.append(depth)    
    

    return data

#Read all the files in the directory
directory = os.getcwd()
years = np.round(np.linspace(1932, 2019, 87))


title = []
lon = []
lat = []
mag =[]

for filename in sorted(os.listdir(directory)):
    if filename.endswith(".catalog"): 
        year = []
        year.append(read(filename))
        name = filename.replace(".catalog", "")
        print(name)
        title.append(name)
        lon.append(year[0][3])
        lat.append(year[0][4])
        mag.append(year[0][2])
        #plt.figure(1)
        
colors = np.linspace(1, 10, 88)

#Turn lat and lon data into GeoDataFrame
# for j in range(len(title)):
# 	location_ = [Point(xy) for xy in zip(lon[i], lon[i])]
# 	location = GeoDataFrame(location, geometry=location)

for j in range(len(title)):
    longitude_array = []
    latitude_array = []
    magnitude_array = []
    for k in range(len(lon)):
        longitude_array_point = lon[k][0]
        latitude_array_point = lat[k][0]
        magnitude_array_point = mon[k][0]

        longitude_array.append(longitude_array_point)
        latitude_array.append(latitude_array_point)
        
    d = {
    'longitude': longitude_array,
    'latitude': latitude_array,
    'magnitude': magnitude_array,
    }

    location_df = pd.DataFrame(data=d)
    location_df.index.name = str(1932 + j)
    location_ = [Point(xy) for xy in zip(location_df['longitude'], location_df['latitude'])]
    location = gpd.GeoDataFrame(geometry=location_)

#Plot all the data
for i in range(len(title)): 
    #size = mag[i]**2  
    plt.scatter(lat[i], lon[i], marker = 'o', alpha= 0.7, label = title[i], s=mag[i]**2)     
    plt.title("Earthquakes in " + title[i], fontsize=15) 
    plt.ylabel("Lat", fontsize=15)
    plt.xlabel("Lon", fontsize=15)
    plt.pause(0.05)

       
    #plt.scatter(lat[i], lon[i], s=size, marker='o', alpha=0.3, label=title[i], c=colors)
#sns.jointplot(lat[0], lon[0], kind="kde", height=7, space=0)


plt.legend(ncol=3, handleheight=2.4, labelspacing=0.05)
#plt.colorbar().ax.set_ylabel('Mag', rotation=90)


plt.show()
