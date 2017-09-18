//
//  PluginLoader.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 8/20/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Foundation
import TarantulaPluginCore

class PluginLoader {

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
                // FIXME: fire()
                throw outerError
            }

            for plugin in plugins {
                state = .loading(path: plugin)
                pluginLoadingObservable.fire()

                guard plugin.pathExtension == "bundle" else {
                    continue
                }

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
                switch (object) {
                case let tarantulaPlugin as TarantulaCrawlingPlugin:
                    crawlers.append(tarantulaPlugin)
                default:
                    let outerError = LoadingError.incompatiblePlugin(plugin: object)
                    state = .error(outerError)
                    throw outerError
                }
            }
        }

        state = .success
        pluginLoadingObservable.fire()

        // FIXME: reset state
    }

    lazy var defaultLocation: URL = {
        let fileManager = FileManager.default
        let list = fileManager.urls(for: .applicationSupportDirectory,
                                    in: .userDomainMask)
        assert(list.count == 1, "Wrong number of items for single-directory search")
        let rootPath = list.first!
        let path = rootPath.appendingPathComponent(NSApplication.shared.name, isDirectory: true).appendingPathComponent(PluginLoader.pluginsDirectoryName, isDirectory: true)
        return path
    }()

    private func ensureDefaultLocationExists() throws {
        let fileManager = FileManager.default
        let path = defaultLocation

        try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
    }

    private lazy var defaultPluginUrls: [URL] = {
        let fileManager = FileManager.default
        let list = fileManager.urls(for: .applicationSupportDirectory,
                                    in: FileManager.SearchPathDomainMask([.allDomainsMask]).subtracting([.systemDomainMask, .networkDomainMask]))

        return list.map { u in
            u.appendingPathComponent(NSApplication.shared.name, isDirectory: true).appendingPathComponent(PluginLoader.pluginsDirectoryName, isDirectory: true)
        } + [Bundle.main.builtInPlugInsURL!]
    }()

    enum LoadingState {
        // FIXME: rename to 'na'
        case waiting
        case enumerating(directory: URL)
        case skipping(directory: URL)
        case loading(path: URL)
        // FIXME: no Error required. Remove here
        case error(Error)
        case success
    }

    enum LoadingError: Error {
        case directoryNotEnumerated(directoryUrl: URL, internalError: Error)
        case bundleNotLoaded(bundleUrl: URL)
        case principalClassNotObjC(principal: AnyClass)
        case incompatiblePlugin(plugin: NSObject)
    }
}


extension PluginLoader.LoadingError: LocalizedError {
    var errorDescription: String? {
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

