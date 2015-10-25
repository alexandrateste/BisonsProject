### Context

This Shiny application allows the user to explore [American bison](http://www.nature.org/ourinitiatives/regions/northamerica/unitedstates/missouri/the-bison-are-coming.xml) tracking data via:
- the display of the animals' trajectories on top of a map
- the calculation and graphical representation of the cumulative distance travelled
- the display of their respective ground speeds.

The dataset used was obtained from the [MoveBank](https://www.movebank.org/panel_embedded_movebank_webapp) website. It was collected by [Dr Stephen Blake](http://www.peoplebehindthescience.com/dr-stephen-blake/) from the Max Planck Institute for Ornithology, Radolfzell, Germany, whom I thank very much for making his data publicly available!

These data report the movements of 15 American bisons that live in the Nature Conservancy’s [Dunn Ranch Prairie](http://www.nature.org/ourinitiatives/regions/northamerica/unitedstates/missouri/dunn-ranch-prairie-flyer.pdf) in Missouri. For the purpose of this application, I focused only on the latitude, longitude, ground speed and animal ID (which I simplified to an integer between 1 and 15 for an easier map representation).

The whole dataset covers the years 2012 to 2015, at a 15-min sampling rate. However, given its size and the calculations run in this app, I downsized the data file used to the points obtained in 2013 only (most complete year).

### Application utilization

#### Date selection
The user starts by selecting a date in the upper left corner of the application (the default is arbitrarily set to May 15, 2013). This allows for the display, on top of a map, of the trajectories of all bisons for which data are available on that day. In the default example, the movement of bisons #2, #5, #8 and #11 are represented.

#### Travel characteristics
The user can then choose to display the cumulative distance travelled, for that specific day, by each "available" bison by clicking on the top checkbox. This triggers the computation of the great-circle distance between two consecutive points (via the [Haversine formula](http://www.movable-type.co.uk/scripts/latlong.html)), and the summation of this distance to the ones travelled since the beginning of the day.

By checking the "Average speed" box, the user activates the display on the ground speed measurements obtained for each animal. The dataset did not provide units. I assume that the data were in km/h.

When one or the other box is selected, only the corresponding plot appears. When both boxes are checked, the 2 graphs are displayed as 2 parts of the same plot (i.e. their height is twice as small as each individual graph shown separately).

As the user changes the date of interest, both the map and the plot(s) get updated.

#### Observations and Remarks

All three representations clearly show the social aspect of the bisons studied:
- They tend to walk in the same direction and stop at about the same time
- They rest several times a day (cf. plateaus on the cumulative distance plot, and low ground speeds).

The user can see the correspondence between the two "Travel characteristics" plots. When the ground speed is close to zero (not necessarily null due to GPS imprecision), the cumulative distance shows a plateau. On the contrary, when the speed shows a peak (or high values), the cumulative distance increases in a short amount of time.

The differences seen between animals in the cumulative distance graph have 2 origins:
- Animals sometimes have trajectories that differ from one another (indeed males tend to be [more solitary](https://en.wikipedia.org/wiki/American_bison))
- The dataset contains missing data, which artificially reduces the cumulative distance travelled.

#### Improvements

This application is the result of a project developed as part of the Data Products Coursera course. Many aspects of the dataset can be explored. Potential additions and improvements include:
- computation of the inter-bison distance to see if males tend to be further than the rest of the group (mainly composed of females)
- further exploitation of gender data (also available in the MoveBank)
- analysis of altitude (also part of the original dataset)
- weekly, monthly, yearly statistics
- interactivity between the map and the graphs (if technically feasible)
- addition of a distance scale to the map (if technically feasible)
- thorough removal of outliers
- possible interpolation of positions when data are missing (vs. simple removal)
- etc.

*Alexandra Teste - October 2015*
