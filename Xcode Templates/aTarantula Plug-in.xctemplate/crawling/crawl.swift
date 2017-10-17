//___FILEHEADER___

import Foundation
import TarantulaPluginCore

func crawl(object: CrawlableObject, usingRepository repository: Repository, withPlugin plugin: ___PACKAGENAMEASIDENTIFIER___CrawlerPlugin) throws {
    switch (object) {
    // TODO: Put here all compatible crawling functions
    default:
        let url = repository.performAndWait { object.objectUrl }
        throw CrawlError(url: url, info: "Unsupported object type \(type(of: object)) for \(type(of: plugin))")
    }
}

func checkLoggedIn(in data: String) -> Bool {
    // TODO: Enter something to check if the page asks for login
    return !data.contains("/sign_in")
}
