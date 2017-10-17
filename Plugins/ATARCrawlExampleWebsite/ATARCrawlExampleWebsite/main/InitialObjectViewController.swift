//
//  InitialObjectViewController.swift
//  ATARCrawlExampleWebsite
//
//  Created by Ilya Mikhaltsou on 9/11/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Cocoa

class InitialObjectViewController: NSViewController {
    var plugin: ATARCrawlExampleWebsiteCrawlerPlugin!
    @IBOutlet var errorShow: NSButton!
    @objc dynamic var urlString: String? = nil

    @IBAction func ok(_ sender: Any?) {
        view.window?.endEditing()
        guard let urlString = urlString else {
            presentError(InputError.noInput)
            return
        }
        guard let url = URL(string: urlString) else {
            presentError(InputError.invalidUrl)
            return
        }
        guard let reposotiry = plugin.repository else {
            fatalError("Repository uninitialized")
        }

        reposotiry.perform {
            let treatment = reposotiry.newObject(forUrl: url, type: Treatment.self)
            treatment.objectIsCrawled = false
            treatment.objectIsSelected = false
        }

        dismiss(self)
    }

    @discardableResult
    override func presentError(_ error: Error) -> Bool {
        errorShow.isHidden = false
        errorShow.alphaValue = 0.0
        errorShow.title = error.localizedDescription

        NSAnimationContext.runAnimationGroup({ (context) in
            context.allowsImplicitAnimation = true
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            self.errorShow.animator().alphaValue = 1.0
        }) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.seconds(4), execute: {
                NSAnimationContext.runAnimationGroup({ (context) in
                    context.allowsImplicitAnimation = true
                    context.duration = 1.0
                    context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
                    self.errorShow.animator().alphaValue = 0.0
                }) {
                    self.errorShow.isHidden = true
                }
            })
        }
        return false
    }

    enum InputError: LocalizedError {
        case noInput
        case invalidUrl
        case urlUnreachable

        var errorDescription: String? {
            switch (self) {
            case .noInput:
                return "Empty URL"
            case .invalidUrl:
                return "Invalid URL"
            case .urlUnreachable:
                return "Resource is unreachable"
            }
        }
    }
}
