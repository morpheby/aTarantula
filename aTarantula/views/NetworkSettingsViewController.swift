//
//  NetworkSettingsViewController.swift
//  aTarantula
//
//  Created by Ilya Mikhaltsou on 9/24/17.
//  Copyright © 2017 morpheby. All rights reserved.
//

import Cocoa
import TarantulaPluginCore

class NetworkSettingsViewController: NSViewController {
    var networkManager: DefaultNetworkManager!
    var plugin: TarantulaCrawlingPlugin!
    @IBOutlet var textView: NSView!

    @objc dynamic var cookieSetting: String? {
        get {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let cookies = NSApplication.shared.controller.cookies(inPlugin: plugin)
            let result = try? encoder.encode(cookies.map { c in HTTPCookieWrapper(cookie: c) })
            if let r = result {
                return String(data: r, encoding: .utf8)
            } else {
                return nil
            }
        }
        set {
            let cookies: [HTTPCookie]
            if let v = newValue {
                let decoder = JSONDecoder()
                guard let data = v.data(using: .utf8) else {
                    let alert = NSAlert()
                    alert.messageText = "Invalid characters for UTF-8 encoding"
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    return
                }
                guard let cookiesWrapped = try? decoder.decode([HTTPCookieWrapper].self, from: data) else {
                    let alert = NSAlert()
                    alert.messageText = "Invalid JSON value"
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                    return
                }
                cookies = cookiesWrapped.map { c in c.cookie }
            } else {
                cookies = []
            }
            NSApplication.shared.controller.setCookies(cookies, inPlugin: plugin)
        }
    }

    @IBAction func done(_ sender: Any) {
        view.window?.endEditing()
        self.dismiss(sender)
    }

    @IBAction func openBrowser(_ sender: Any) {
        
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        switch segue.identifier {
        case .some(.webviewSegue):
            view.window?.endEditing()
            guard let webviewController = segue.destinationController as? WebViewViewController else {
                fatalError("Invalid segue: \(segue)")
            }
            webviewController.plugin = plugin
            self.willChangeValue(for: \NetworkSettingsViewController.cookieSetting)
        default:
            break
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func mouseDown(with event: NSEvent) {
        view.window?.makeFirstResponder(self)
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func dismissViewController(_ viewController: NSViewController) {
        super.dismissViewController(viewController)

        NSApplication.shared.controller.mainQueue.addOperation {
            self.didChangeValue(for: \NetworkSettingsViewController.cookieSetting)
        }
    }
}

struct HTTPCookieWrapper: Codable {
    enum CodingKeys: String, CodingKey {
        case comment
        case commentURL
        case domain
        case expiresDate
        case isHTTPOnly
        case isSecure
        case isSessionOnly
        case name
        case path
        case portList
        case value
        case version
    }

    var cookie: HTTPCookie

    init(cookie: HTTPCookie) {
        self.cookie = cookie
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let comment = try values.decode(String?.self, forKey: .comment)
        let commentURL = try values.decode(URL?.self, forKey: .commentURL)
        let domain = try values.decode(String.self, forKey: .domain)
        let expiresDate = try values.decode(Date?.self, forKey: .expiresDate)
        let isHTTPOnly = try values.decode(Bool.self, forKey: .isHTTPOnly)
        let isSecure = try values.decode(Bool.self, forKey: .isSecure)
        let isSessionOnly = try values.decode(Bool.self, forKey: .isSessionOnly)
        let name = try values.decode(String.self, forKey: .name)
        let path = try values.decode(String.self, forKey: .path)
        let portList = try values.decode([Int]?.self, forKey: .portList)
        let value = try values.decode(String.self, forKey: .value)
        let version = try values.decode(Int.self, forKey: .version)

        cookie = HTTPCookie(properties: [
            HTTPCookiePropertyKey(rawValue: CodingKeys.comment.rawValue): comment as Any,
            HTTPCookiePropertyKey(rawValue: CodingKeys.commentURL.rawValue): commentURL as Any,
            HTTPCookiePropertyKey(rawValue: CodingKeys.domain.rawValue): domain as Any,
            HTTPCookiePropertyKey(rawValue: CodingKeys.expiresDate.rawValue): expiresDate as Any,
            HTTPCookiePropertyKey(rawValue: CodingKeys.isHTTPOnly.rawValue): isHTTPOnly as Any,
            HTTPCookiePropertyKey(rawValue: CodingKeys.isSecure.rawValue): isSecure as Any,
            HTTPCookiePropertyKey(rawValue: CodingKeys.isSessionOnly.rawValue): isSessionOnly as Any,
            HTTPCookiePropertyKey(rawValue: CodingKeys.name.rawValue): name as Any,
            HTTPCookiePropertyKey(rawValue: CodingKeys.path.rawValue): path as Any,
            HTTPCookiePropertyKey(rawValue: CodingKeys.portList.rawValue): portList as Any,
            HTTPCookiePropertyKey(rawValue: CodingKeys.value.rawValue): value as Any,
            HTTPCookiePropertyKey(rawValue: CodingKeys.version.rawValue): version as Any,
        ])!
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(cookie.comment, forKey: .comment)
        try container.encode(cookie.commentURL, forKey: .commentURL)
        try container.encode(cookie.domain, forKey: .domain)
        try container.encode(cookie.expiresDate, forKey: .expiresDate)
        try container.encode(cookie.isHTTPOnly, forKey: .isHTTPOnly)
        try container.encode(cookie.isSecure, forKey: .isSecure)
        try container.encode(cookie.isSessionOnly, forKey: .isSessionOnly)
        try container.encode(cookie.name, forKey: .name)
        try container.encode(cookie.path, forKey: .path)
        try container.encode(cookie.portList as! [Int]?, forKey: .portList)
        try container.encode(cookie.value, forKey: .value)
        try container.encode(cookie.version, forKey: .version)
    }
}
