//
//  PluginLoader.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 8/20/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import TarantulaPluginCore

class PluginController {

    init() throws {
        debugPrint(defaultPluginUrls)

        ensureDefaultLocationExists()
    }

    var pluginLoadingObservable = Observable(PluginController)

    private static let pluginsDirectoryName = "Plugins"

    private func loadPlugins() throws {
        for url in self.defaultPluginUrls {
            let plugins: [URL]
            do {
                var isDirectory = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                    plugins = try FileManager.default.contentsOfDirectory(at: url,
                                                                           includingPropertiesForKeys: [.pathKey],
                                                                           options: [.skipsHiddenFiles])
                }
            }
            catch let error {
                throw LoadingError.directoryNotEnumerated(directoryUrl: url, internalError: error)
            }

            for plugin in plugins {
                let bundle = Bundle(url: plugin)
                guard let principal = bundle?.principalClass else {
                    throw LoadingError.bundleNotLoaded(bundleUrl: plugin)
                }
                guard let pobjclass = principal as? NSObject.Type else {
                    throw LoadingError.principalClassNotObjC(principal: principal)
                }
                let object = pobjclass.init()
                guard let tarantulaPlugin = object as? TarantulaCrawlingPlugin else {
                    debugPrint("Unable to load \(object) as CrawlingPluginProtocol")
                    abort()
                }
            }
        }
    }

    private func ensureDefaultLocationExists() throws {
        let fileManager = FileManager.default
        let list = fileManager.urls(for: .applicationSupportDirectory,
                                    in: .userDomainMask)
        assert(list.count == 1, "Wrong number of items for single-directory search")
        let rootPath = list.first!
        let path = rootPath.appendingPathComponent(NSApplication.shared.name, isDirectory: true).appendingPathComponent(PluginController.pluginsDirectoryName, isDirectory: true)

        try fileManager.createDirectory(at: path, withIntermediateDirectories: true, attributes: [])
    }

    private lazy var defaultPluginUrls: [URL] = {
        let fileManager = FileManager.default
        let list = fileManager.urls(for: .applicationSupportDirectory,
                                    in: FileManager.SearchPathDomainMask([.allDomainsMask]).subtracting([.systemDomainMask, .networkDomainMask]))

        return list.map { u in
            u.appendingPathComponent(NSApplication.shared.name, isDirectory: true).appendingPathComponent(PluginController.pluginsDirectoryName, isDirectory: true)
        } + [Bundle.main.builtInPlugInsURL!]
    }()
//        NSString *appSupportSubpath = @"Application Support/KillerApp/PlugIns";
//        NSArray *librarySearchPaths;
//        NSEnumerator *searchPathEnum;
//        NSString *currPath;
//        NSMutableArray *bundleSearchPaths = [NSMutableArray array];
//
//        // Find Library directories in all domains except /System
//        librarySearchPaths = NSSearchPathForDirectoriesInDomains(
//            NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES);
//
//        // Copy each discovered path into an array after adding
//        // the Application Support/KillerApp/PlugIns subpath
//        searchPathEnum = [librarySearchPaths objectEnumerator];
//        while(currPath = [searchPathEnum nextObject])
//        {
//            [bundleSearchPaths addObject:
//                [currPath stringByAppendingPathComponent:appSupportSubpath]];
//        }

    func loadPlugin(fromPath path: String) {

    }

    var exporters: [Any] = []
    var crawlers: [TarantulaCrawlingPlugin] = []

    enum LoadingState {
        case waiting
        case loading(directory: URL, path: URL)
    }

    enum LoadingError: Error {
        case directoryNotEnumerated(directoryUrl: URL, internalError: Error)
        case bundleNotLoaded(bundleUrl: URL)
        case principalClassNotObjC(principal: AnyClass)

        var localizedDescription: String {
            switch (self) {
            case let .directoryNotEnumerated(directoryUrl: url, internalError: error):
                return "Unable to enumerate directory contents at \(url.path): \(error.localizedDescription)"
            case let .bundleNotLoaded(bundleUrl: url):
                return "Unable to load plugin bundle at \(url.path)"
            case let .principalClassNotObjC(principal: p):
                return "Principal class \(p) in plugin \(Bundle(for: p)) is not NSObject-compatible"
            }
        }
    }
}
