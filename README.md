A very simple Shiny app to upload tables and view some basic plots.

<h4>R</h4>

For the R version, you can check if the necessary packages are installed:

```r
pkgs <- c("DT", "plotly", "shiny", "shinydashboard")
pkgs %in% installed.packages()
```

and install missing packages like this:

```r
install.packages(pkgs[!pkgs %in% installed.packages()])
```

You can run the app by giving the name of its directory to the function <code><a href="https://www.rdocumentation.org/packages/shiny/versions/1.8.1.1/topics/runApp" class="external-link">runApp</a></code>. For example, if <code>app.R</code> is in a directory called <code>simple-visualizer</code>, run:

```r
library(shiny)
runApp("simple-visualizer")
```

<h4>Example</h4>

<p><a href="https://github.com/JeffSackmann/tennis_atp/blob/master/atp_matches_2023.csv" class="external-link">Tennis data</a> courtesy of <a href="https://github.com/JeffSackmann/tennis_atp" class="external-link">Jeff Sackmann</a>. Some <a href="https://github.com/awesomedata/awesome-public-datasets" class="external-link">public datasets</a> for more table examples.</p>
