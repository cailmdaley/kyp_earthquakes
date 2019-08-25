import numpy as np
import matplotlib.pyplot as plt
import pandas as pd 
import os
import seaborn as sns


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


def plot(filename):
    """
    This function plots the registered earthquakes in a year 
    """
    year = read(filename)
    title = filename.replace(".catalog", "")
    lon = year[3]
    lat = year[4]
    mag = year[2]
    
    plt.figure(1)
    plt.scatter(lat, lon, s=mag**2, marker='o', alpha=0.3, c='g')
    #plt.colorbar().ax.set_ylabel('Mag', rotation=90)
    plt.ylabel("Lat", fontsize=15)
    plt.xlabel("Lon", fontsize=15)
    plt.title('Earthquakes in ' + title, fontsize=15)
    
    plt.figure(2)
    g = sns.jointplot(lat, lon, kind="kde", color="b")
    g.plot_joint(plt.scatter, c="c", s=30, linewidth=1, marker="+")
    g.ax_joint.collections[0].set_alpha(0)
    g.set_axis_labels("$Lon$", "$Lat$", fontsize=15);
    g.fig.suptitle('Earthquakes in ' + title, fontsize=15)    
    
    plt.show()

directory = "/home/victoria/Descargas/data_science_school/earthquake_project/SCEDC_catalogs/SCEC_DC"
"""

years = np.round(np.linspace(1932, 2019, 87))
for file in os.listdir(directory):
    if file.endswith(".catalog"): 
        plot(file)
    else:
        continue
"""