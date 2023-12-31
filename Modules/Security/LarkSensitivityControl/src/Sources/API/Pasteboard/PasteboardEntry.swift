//
//  PasteboardEntry.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/24.
//

import UIKit

@objc
final public class PasteboardEntry: NSObject, PasteboardApi {

    private static func getService() -> PasteboardApi.Type {
        if let service = LSC.getService(forTag: tag) as? PasteboardApi.Type {
            return service
        }
        return PasteboardWrapper.self
    }

    /// UIPasteboard string
    public static func string(ofToken token: Token, pasteboard: UIPasteboard) throws -> String? {
        let context = Context([AtomicInfo.Pasteboard.string.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().string(ofToken: token, pasteboard: pasteboard)
    }

    /// UIPasteboard setString
    @objc
    public static func setString(forToken token: Token, pasteboard: UIPasteboard, string: String?) throws {
        let context = Context([AtomicInfo.Pasteboard.setString.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().setString(forToken: token, pasteboard: pasteboard, string: string)
    }

    /// UIPasteboard strings
    public static func strings(ofToken token: Token, pasteboard: UIPasteboard) throws -> [String]? {
        let context = Context([AtomicInfo.Pasteboard.strings.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().strings(ofToken: token, pasteboard: pasteboard)
    }

    /// UIPasteboard setStrings
    @objc
    public static func setStrings(forToken token: Token, pasteboard: UIPasteboard, strings: [String]?) throws {
        let context = Context([AtomicInfo.Pasteboard.setStrings.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().setStrings(forToken: token, pasteboard: pasteboard, strings: strings)
    }

    /// UIPasteboard url
    public static func url(ofToken token: Token, pasteboard: UIPasteboard) throws -> URL? {
        let context = Context([AtomicInfo.Pasteboard.url.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().url(ofToken: token, pasteboard: pasteboard)
    }

    /// UIPasteboard setUrl
    @objc
    public static func setUrl(forToken token: Token, pasteboard: UIPasteboard, url: URL?) throws {
        let context = Context([AtomicInfo.Pasteboard.setUrl.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().setUrl(forToken: token, pasteboard: pasteboard, url: url)
    }

    /// UIPasteboard urls
    public static func urls(ofToken token: Token, pasteboard: UIPasteboard) throws -> [URL]? {
        let context = Context([AtomicInfo.Pasteboard.urls.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().urls(ofToken: token, pasteboard: pasteboard)
    }

    /// UIPasteboard setUrls
    @objc
    public static func setUrls(forToken token: Token, pasteboard: UIPasteboard, urls: [URL]?) throws {
        let context = Context([AtomicInfo.Pasteboard.setUrls.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().setUrls(forToken: token, pasteboard: pasteboard, urls: urls)
    }

    /// UIPasteboard image
    public static func image(ofToken token: Token, pasteboard: UIPasteboard) throws -> UIImage? {
        let context = Context([AtomicInfo.Pasteboard.image.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().image(ofToken: token, pasteboard: pasteboard)
    }

    /// UIPasteboard setImage
    @objc
    public static func setImage(forToken token: Token, pasteboard: UIPasteboard, image: UIImage?) throws {
        let context = Context([AtomicInfo.Pasteboard.setImage.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().setImage(forToken: token, pasteboard: pasteboard, image: image)
    }

    /// UIPasteboard images
    public static func images(ofToken token: Token, pasteboard: UIPasteboard) throws -> [UIImage]? {
        let context = Context([AtomicInfo.Pasteboard.images.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().images(ofToken: token, pasteboard: pasteboard)
    }

    /// UIPasteboard setImages
    @objc
    public static func setImages(forToken token: Token, pasteboard: UIPasteboard, images: [UIImage]?) throws {
        let context = Context([AtomicInfo.Pasteboard.setImages.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().setImages(forToken: token, pasteboard: pasteboard, images: images)
    }

    /// UIPasteboard items
    @objc
    public static func items(ofToken token: Token, pasteboard: UIPasteboard) throws -> [[String: Any]] {
        let context = Context([AtomicInfo.Pasteboard.items.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().items(ofToken: token, pasteboard: pasteboard)
    }

    /// UIPasteboard setItems
    @objc
    public static func setItems(forToken token: Token, pasteboard: UIPasteboard, _ items: [[String: Any]]) throws {
        let context = Context([AtomicInfo.Pasteboard.setItems.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().setItems(forToken: token, pasteboard: pasteboard, items)
    }

    /// UIPasteboard addItems
    @objc
    public static func addItems(forToken token: Token, pasteboard: UIPasteboard, _ items: [[String: Any]]) throws {
        let context = Context([AtomicInfo.Pasteboard.addItems.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().addItems(forToken: token, pasteboard: pasteboard, items)
    }

    /// UIPasteboard setItemsWithOptions
    @objc
    public static func setItems(forToken token: Token,
                                pasteboard: UIPasteboard,
                                _ items: [[String: Any]],
                                options: [UIPasteboard.OptionsKey: Any]) throws {
        let context = Context([AtomicInfo.Pasteboard.setItemsWithOptions.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().setItems(forToken: token, pasteboard: pasteboard, items, options: options)
    }

    /// UIPasteboard itemProviders
    public static func itemProviders(forToken token: Token, pasteboard: UIPasteboard) throws -> [NSItemProvider]? {
        let context = Context([AtomicInfo.Pasteboard.itemProviders.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().itemProviders(forToken: token, pasteboard: pasteboard)
    }

    /// UIPasteboard setItemProviders
    public static func setItemProviders(forToken token: Token,
                                        pasteboard: UIPasteboard,
                                        _ itemProviders: [NSItemProvider],
                                        localOnly: Bool,
                                        expirationDate: Date?) throws {
        let context = Context([AtomicInfo.Pasteboard.setItemProviders.rawValue])
        try Assistant.checkToken(token, context: context)
        try getService().setItemProviders(forToken: token, pasteboard: pasteboard,
                                          itemProviders, localOnly: localOnly, expirationDate: expirationDate)
    }

    /// UIPasteboard data
    public static func data(forToken token: Token,
                            pasteboard: UIPasteboard,
                            forPasteboardType pasteboardType: String) throws -> Data? {
        let context = Context([AtomicInfo.Pasteboard.data.rawValue])
        try Assistant.checkToken(token, context: context)
        return try getService().data(forToken: token, pasteboard: pasteboard, forPasteboardType: pasteboardType)
    }
}
