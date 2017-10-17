//___FILEHEADER___

import Foundation

internal struct Configuration {
    // TODO: Setup plugin
    
    static let websiteBaseUrl = "https://www.example.com"

    static let pluginName = "___PRODUCTNAME___"

    static let specialButton: (___PACKAGENAMEASIDENTIFIER___CrawlerPlugin) -> () = { plugin in
        // Input here any code for the "Special Button" in Settings dialog
        guard let repo = plugin.repository else { fatalError("No repository") }

        repo.performAndWait {
        }
    }
}
