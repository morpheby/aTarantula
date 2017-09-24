//
//  WebViewViewController.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 9/24/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Cocoa
import WebKit
import TarantulaPluginCore

class WebViewViewController: NSViewController {

    @IBOutlet var webViewContainer: NSView!
    @objc dynamic var webView: WKWebView

    let pool = WKProcessPool()
    let configuration = WKWebViewConfiguration()

    var dataStore: WKWebsiteDataStore!

    var plugin: TarantulaCrawlingPlugin!

    var cookies: [HTTPCookie] = []

    var oldCookies: [HTTPCookie] = []

    required init?(coder: NSCoder) {
        configuration.processPool = pool

        webView = WKWebView(frame: .zero, configuration: configuration)

        super.init(coder: coder)

        if #available(OSX 10.13, *) {
            dataStore = WKWebsiteDataStore.nonPersistent()
            dataStore.httpCookieStore.add(self)
        } else {
            dataStore = WKWebsiteDataStore.default()
        }

        configuration.websiteDataStore = dataStore
    }

    var url: URL?
    @objc dynamic var urlString: String? {
        set {
            guard let v = newValue else { return }
            guard let url = URL(string: v) else {
                let alert = NSAlert()
                alert.messageText = "Invalid URL"
                alert.addButton(withTitle: "OK")
                alert.runModal()
                return
            }
            self.url = url
        }
        get {
            return url?.absoluteString
        }
    }

    deinit {
        if #available(OSX 10.13, *) {
            dataStore.httpCookieStore.remove(self)
        }
    }

    @IBAction func load(_ sender: Any) {
        guard let url = url else { return }
        webView.load(URLRequest(url: url))
    }

    @IBAction func done(_ sender: Any) {
        availability: if #available(OSX 10.13, *) {
        } else {
            // Find difference with initial value
            guard let newCookies = URLSession.shared.configuration.httpCookieStorage?.cookies else { break availability }
            let difference = newCookies.filter({ (c) -> Bool in
                !self.oldCookies.contains(c)
            })
            cookies = difference
        }

        NSApplication.shared.controller.setCookies(cookies, inPlugin: plugin)

        dismiss(sender)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(OSX 10.13, *) {
            for cookie in NSApplication.shared.controller.cookies(inPlugin: plugin) {
                dataStore.httpCookieStore.setCookie(cookie, completionHandler: nil)
            }
        } else {
            // Rely on shared cookies only
            if URLSession.shared.configuration.httpCookieStorage == nil {
                URLSession.shared.configuration.httpCookieStorage = HTTPCookieStorage.shared
            }
            for cookie in NSApplication.shared.controller.cookies(inPlugin: plugin) {
                URLSession.shared.configuration.httpCookieStorage?.setCookie(cookie)
            }
            oldCookies = URLSession.shared.configuration.httpCookieStorage?.cookies ?? []
        }
        webViewContainer.addSubview(webView)
        webView.frame = webViewContainer.bounds
        webViewContainer.addConstraints([
            NSLayoutConstraint(item: webViewContainer, attribute: .top, relatedBy: .equal, toItem: webView, attribute: .top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: webViewContainer, attribute: .bottom, relatedBy: .equal, toItem: webView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: webViewContainer, attribute: .left, relatedBy: .equal, toItem: webView, attribute: .left, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: webViewContainer, attribute: .right, relatedBy: .equal, toItem: webView, attribute: .right, multiplier: 1.0, constant: 0.0),
        ])
    }

    @objc dynamic override var title: String? {
        get {
            return webView.title
        }
        set {
            // Ignore
        }
    }

    @objc static func keyPathsForValuesAffectingTitle() -> Set<String> {
        return Set(["\(#keyPath(webView.title))"])
    }

}

extension WebViewViewController: WKHTTPCookieStoreObserver {
    
    @available(OSX 10.13, *)
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        cookieStore.getAllCookies({ c in
            self.cookies = c
        })
    }
}
