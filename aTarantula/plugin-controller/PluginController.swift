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

    var exporters: [Any] = []
    var crawlers: [TarantulaCrawlingPlugin] = []
    var state: LoadingState = .waiting

    init() throws {
        try ensureDefaultLocationExists()
    }

    lazy var pluginLoadingObservable = Observable(self)

    private static let pluginsDirectoryName = "Plugins"

    func loadPlugins() throws {
        for url in self.defaultPluginUrls {
            state = .enumerating(directory: url)
            pluginLoadingObservable.fire()

            let plugins: [URL]
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    plugins = try FileManager.default.contentsOfDirectory(at: url,
                                                                           includingPropertiesForKeys: [.pathKey],
                                                                           options: [.skipsHiddenFiles])
                } else {
                    state = .skipping(directory: url)
                    pluginLoadingObservable.fire()
                    continue
                }
            }
            catch let error {
                let outerError = LoadingError.directoryNotEnumerated(directoryUrl: url, internalError: error)
                state = .error(outerError)
                throw outerError
            }

            for plugin in plugins {
                state = .loading(path: plugin)
                pluginLoadingObservable.fire()

                let bundle = Bundle(url: plugin)
                guard let principal = bundle?.principalClass else {
                    let outerError = LoadingError.bundleNotLoaded(bundleUrl: plugin)
                    state = .error(outerError)
                    throw outerError
                }
                guard let pobjclass = principal as? NSObject.Type else {
                    let outerError = LoadingError.principalClassNotObjC(principal: principal)
                    state = .error(outerError)
                    throw outerError
                }
                let object = pobjclass.init()
                guard let tarantulaPlugin = object as? TarantulaCrawlingPlugin else {
                    let outerError = LoadingError.incompatiblePlugin(plugin: object)
                    state = .error(outerError)
                    throw outerError
                }
            }
        }

        state = .success
        pluginLoadingObservable.fire()
    }

    private func ensureDefaultLocationExists() throws {
        let fileManager = FileManager.default
        let list = fileManager.urls(for: .applicationSupportDirectory,
                                    in: .userDomainMask)
        assert(list.count == 1, "Wrong number of items for single-directory search")
        let rootPath = list.first!
        let path = rootPath.appendingPathComponent(NSApplication.shared.name, isDirectory: true).appendingPathComponent(PluginController.pluginsDirectoryName, isDirectory: true)

        try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
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

    enum LoadingState {
        case waiting
        case enumerating(directory: URL)
        case skipping(directory: URL)
        case loading(path: URL)
        case error(Error)
        case success
    }

    enum LoadingError: Error {
        case directoryNotEnumerated(directoryUrl: URL, internalError: Error)
        case bundleNotLoaded(bundleUrl: URL)
        case principalClassNotObjC(principal: AnyClass)
        case incompatiblePlugin(plugin: NSObject)

        var localizedDescription: String {
            switch (self) {
            case let .directoryNotEnumerated(directoryUrl: url, internalError: error):
                return "Unable to enumerate directory contents at \(url.path): \(error.localizedDescription)"
            case let .bundleNotLoaded(bundleUrl: url):
                return "Unable to load plugin bundle at \(url.path)"
            case let .principalClassNotObjC(principal: p):
                return "Principal class \(p) in plugin \(Bundle(for: p)) is not NSObject-compatible"
            case let .incompatiblePlugin(plugin: p):
                return "Plugin \"\(p.description)\" is incompatible"
            }
        }
    }
}
