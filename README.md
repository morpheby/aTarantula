
## aTarantula ##

Universal data crawler scavenged from [morpheby/fanfiction-crawler](https://github.com/morpheby/fanfiction-crawler).

aTarantula is a web data crawler to be used in data mining applications.

### Features ###

* Designed for macOS
* Extensible using plugin architecture. Plugins can be written using Swift and Objective-C (and, notably,
   can use only Swift)
* Multi-threaded
* Using CoreData for storing crawled data
* Integrated data editor to edit data without exporting/importing the whole dataset or accessing through
   `sqlite` client (lifted from [Core Data Editor](https://github.com/ChristianKienle/Core-Data-Editor))
* Allows to crawl only required resources
* Integrated web view to login to websites requiring authorization
* Exporting and importing of the database store
* Various exporting methods *(coming soon)*

### Principle of operation ###

There are two types of resources: *crawlable* and *supplementary*. *Crawlable* resources are objects 
uniquely identifiable by the URL of the page the resource is located at. *Supplementary* resources are data
objects that are created to support different properties in crawlable resources.

Each *Crawlable* object is required to adopt `CrawlableObject` protocol and its type is to be present in the
`crawlableObjectTypes` property of the crawling plugin. `CrawlableObject` protocol declares 4 properties
that need to be defined in the CoreData model to support its operation:

* `id`: Uniquely identifiable object ID, derived from the URL of the resource
* `crawl_url`: Actual URL to use for crawling the object
	* `id` and `crawl_url` most of the time can be the same (which is a recommended usage), but in
	   some cases, there may be some differences. For example, one the resource may require certain
	   query string to be accessed, which is otherwise unnecessary (or even harmful) for object identification.
* `obj_deleted`: Specifies whether the object was already crawled or is yet unavailable
* `disabled`: Specifies whether the object satisfies the filtering condition or not

This protocol also provides convenient methods to use with those properties, so that internal layout and
logic of these properties may change, while external will remain and will be easier to understand.

The crawler needs one initial *Crawlable* object to be present in the database before starting the operation.
After that, it will continuously spawn plugins `crawl` method from different threads. Each `crawl` call
is supplied with the object to be crawled, and this method shall use dynamic type checks to determine
what object that is specifically, and then act accordingly.

## Documentation ##

### Contents ###

0. **This document**
1. [Building from source](/docs/building.md)
2. [Using aTarantula](/docs/using.md)
3. [Extending (creating plugins)](/docs/extending.md)
