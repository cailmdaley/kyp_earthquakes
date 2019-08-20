# kyp_earthquakes
repository for LSSDS 2019 earthquake project

For the dataset, go to: http://scedc.caltech.edu/research-tools/eewtesting.html



## Statement of work

1. Get data
  - We have downloaded a catalogue of earthquakes in Southern California: the data is in a tabular format, with each earthquake event associated with a location, time, magnitude, depth, etc.
  - Get locations of fault lines (this exists, we don't know how to get it yet)
2. Visualization
  - Scatter plotting earthquake event quakes over time and distance
    - Movie/GIF to show evolution over time?
  - Overplot fault lines to see spatial correlations
3. Measure distance between earthquake and fault line
  - multiple methods for this. how do we define this distance?
  - do we need to worry about Earth's curvature?
4. Describe spatial and temporal correlations between earthquakes
  - along fault line distance? linear distance?
  - fit covariance functions? theoretically motivated?
  - look into geostatistical methods?
