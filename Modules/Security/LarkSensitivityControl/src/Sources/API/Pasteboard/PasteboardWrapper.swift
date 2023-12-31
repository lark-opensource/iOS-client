//
//  PasteboardWrapper.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/24.
//

import UIKit

final class PasteboardWrapper: NSObject, PasteboardApi {
    /// UIPasteboard string
    static func string(ofToken token: Token, pasteboard: UIPasteboard) throws -> String? {
        return pasteboard.string
    }

    /// UIPasteboard setString
    static func setString(forToken token: Token, pasteboard: UIPasteboard, string: String?) throws {
        pasteboard.string = string
    }

    /// UIPasteboard strings
    static func strings(ofToken token: Token, pasteboard: UIPasteboard) throws -> [String]? {
        return pasteboard.strings
    }

    /// UIPasteboard setStrings
    static func setStrings(forToken token: Token, pasteboard: UIPasteboard, strings: [String]?) throws {
        pasteboard.strings = strings
    }

    /// UIPasteboard url
    static func url(ofToken token: Token, pasteboard: UIPasteboard) throws -> URL? {
        return pasteboard.url
    }

    /// UIPasteboard setUrl
    static func setUrl(forToken token: Token, pasteboard: UIPasteboard, url: URL?) throws {
        pasteboard.url = url
    }

    /// UIPasteboard urls
    static func urls(ofToken token: Token, pasteboard: UIPasteboard) throws -> [URL]? {
        return pasteboard.urls
    }

    /// UIPasteboard setUrls
    static func setUrls(forToken token: Token, pasteboard: UIPasteboard, urls: [URL]?) throws {
        pasteboard.urls = urls
    }

    /// UIPasteboard image
    static func image(ofToken token: Token, pasteboard: UIPasteboard) throws -> UIImage? {
        return pasteboard.image
    }

    /// UIPasteboard setImage
    static func setImage(forToken token: Token, pasteboard: UIPasteboard, image: UIImage?) throws {
        pasteboard.image = image
    }

    /// UIPasteboard images
    static func images(ofToken token: Token, pasteboard: UIPasteboard) throws -> [UIImage]? {
        return pasteboard.images
    }

    /// UIPasteboard setImages
    static func setImages(forToken token: Token, pasteboard: UIPasteboard, images: [UIImage]?) throws {
        pasteboard.images = images
    }

    /// UIPasteboard items
    static func items(ofToken token: Token, pasteboard: UIPasteboard) throws -> [[String: Any]] {
        return pasteboard.items
    }

    /// UIPasteboard setItems
    static func setItems(forToken token: Token, pasteboard: UIPasteboard, _ items: [[String: Any]]) throws {
        pasteboard.items = items
    }

    /// UIPasteboard addItems
    static func addItems(forToken token: Token, pasteboard: UIPasteboard, _ items: [[String: Any]]) throws {
        pasteboard.addItems(items)
    }

    /// UIPasteboard setItems
    static func setItems(forToken token: Token,
                         pasteboard: UIPasteboard,
                         _ items: [[String: Any]],
                         options: [UIPasteboard.OptionsKey: Any]) throws {
        pasteboard.setItems(items, options: options)
    }

    /// UIPasteboard itemProviders
    static func itemProviders(forToken token: Token, pasteboard: UIPasteboard) throws -> [NSItemProvider]? {
        return pasteboard.itemProviders
    }

    /// UIPasteboard setItemProviders
    static func setItemProviders(forToken token: Token,
                                 pasteboard: UIPasteboard,
                                 _ itemProviders: [NSItemProvider],
                                 localOnly: Bool,
                                 expirationDate: Date?) throws {
        pasteboard.setItemProviders(itemProviders, localOnly: localOnly, expirationDate: expirationDate)
    }

    /// UIPasteboard data
    static func data(forToken token: Token,
                     pasteboard: UIPasteboard,
                     forPasteboardType pasteboardType: String) throws -> Data? {
        return pasteboard.data(forPasteboardType: pasteboardType)
    }
}
