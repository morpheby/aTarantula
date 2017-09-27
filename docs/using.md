
## Using aTarantula ##

### Checking status and starting/stopping ###

After the database is loaded you will be greeted with aTarantula's main screen.

![Main screen](/docs/imgs/main_screen.png)

Here, blue progress bar indicates *crawlable* objects that were successfully crawled before. Yellow progress
bar illustrates the amount of *crawlable* that were rejected due to current filtering (or previous)

You can use *Active threads* slider to adjust the amount of crawling threads that can be run simultaneously.
*Maximum fetch* allows to regulate the amount of *Crawlable* objects to be fetched from the database
for each plugin.

Use *Start* button to start crawling and a *Stop* button to stop crawling.

While running, the green bar in the bottom will indicate the number of threads that are currently busy.

**Important note: if the plugin is not completely implemented and doesn't have the capability to crawl all
of the discovered objects, then the log will be constantly spammed with errors and the crawling will never
finish on itself. Use *Stop* button when it seems like it finished crawling all known objects.**

### Plugin list ###

Open *Plugin list* by pressing *Plugins* button in the bottom of the *Main screen*.

![Plugin list](/docs/imgs/plugin_list.png)

Provides several control methods for each plugin:

1. *Export Plugin Data*: Exports the whole contents of the database to a single `sqlite` file
2. *Import Plugin Data*: Allows to restore the database using the exported file
	* There is an option in the *Open* window  to erase the original database before importing
3. *Open Editor*: Opens *Core Data Editor* to edit the database for the plugin
4. *Settings*: Opens plugin-defined settings window to directly interface with the plugin
5. *Network settings*: Opens the window used to adjust network access for the plugin (including cookies)

### Inputting authorization credentials ###

Open *Plugin list* –> *Network Settings* for the desired plugin. 

![Network settings](/docs/imgs/network_settings.png)

Here is a JSON serialization of the cookies, associated with this plugin and an *Open login form* button.
This button will open a small web view, where you can browse to the website you wish to crawl. After
you have been authenticated and authorized, you should press `Done` button and you are all set!

### Sample plugin settings ###

Use plugin settings to create initial object to be crawled, completely erase database or assign filter (selection).

![Sample plugin Settings window](/docs/imgs/plugin_settings.png)

### Assigning filter ###

Open *Plugin Settings* –> *Settings* for the desired plugin.

There you will have following options:

1. Tune filter: Change settings to the right of the buttons in the *Selection* group (i.e. select *Filter by drug
   name* and enter some drug name below); then press *Assign filter setting* button
2. Mark all crawled and discovered objects as selected, but leave the filter in place for the crawling
   operation: Use *Reset selection (select all)* button
3. Change filter terms: First tune the filter, and then press *Update selection* button (may be slow for big
   databases, and will freeze the app during the process)

-----

### Contents ###

0. [Intro](/README.md)
1. [Building from source](/docs/building.md)
2. **This document**
3. [Extending (creating plugins)](/docs/extending.md)
