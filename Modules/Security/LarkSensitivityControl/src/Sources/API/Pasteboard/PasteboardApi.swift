//
//  PasteboardApi.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/24.
//

import UIKit

public extension PasteboardApi {
    /// 外部注册自定义api使用的key值
    static var tag: String {
        "pasteboard"
    }
}

/// Pasteboard
public protocol PasteboardApi: SensitiveApi {
    /// UIPasteboard string
    static func string(ofToken token: Token, pasteboard: UIPasteboard) throws -> String?

    /// UIPasteboard setString
    static func setString(forToken token: Token, pasteboard: UIPasteboard, string: String?) throws

    /// UIPasteboard strings
    static func strings(ofToken token: Token, pasteboard: UIPasteboard) throws -> [String]?

    /// UIPasteboard setStrings
    static func setStrings(forToken token: Token, pasteboard: UIPasteboard, strings: [String]?) throws

    /// UIPasteboard url
    static func url(ofToken token: Token, pasteboard: UIPasteboard) throws -> URL?

    /// UIPasteboard setUrl
    static func setUrl(forToken token: Token, pasteboard: UIPasteboard, url: URL?) throws

    /// UIPasteboard urls
    static func urls(ofToken token: Token, pasteboard: UIPasteboard) throws -> [URL]?

    /// UIPasteboard setUrls
    static func setUrls(forToken token: Token, pasteboard: UIPasteboard, urls: [URL]?) throws

    /// UIPasteboard image
    static func image(ofToken token: Token, pasteboard: UIPasteboard) throws -> UIImage?

    /// UIPasteboard setImage
    static func setImage(forToken token: Token, pasteboard: UIPasteboard, image: UIImage?) throws

    /// UIPasteboard images
    static func images(ofToken token: Token, pasteboard: UIPasteboard) throws -> [UIImage]?

    /// UIPasteboard setImages
    static func setImages(forToken token: Token, pasteboard: UIPasteboard, images: [UIImage]?) throws

    /// UIPasteboard items
    static func items(ofToken token: Token, pasteboard: UIPasteboard) throws -> [[String: Any]]

    /// UIPasteboard setItems
    static func setItems(forToken token: Token, pasteboard: UIPasteboard, _ items: [[String: Any]]) throws

    /// UIPasteboard addItems
    static func addItems(forToken token: Token, pasteboard: UIPasteboard, _ items: [[String: Any]]) throws

    /// UIPasteboard setItems
    static func setItems(forToken token: Token,
                         pasteboard: UIPasteboard,
                         _ items: [[String: Any]],
                         options: [UIPasteboard.OptionsKey: Any]) throws

    /// lark itemProviders
    static func itemProviders(forToken token: Token, pasteboard: UIPasteboard) throws -> [NSItemProvider]?

    /// lark setItemProviders
    static func setItemProviders(forToken token: Token,
                                 pasteboard: UIPasteboard,
                                 _ itemProviders: [NSItemProvider],
                                 localOnly: Bool,
                                 expirationDate: Date?) throws

    /// lark data
    static func data(forToken token: Token,
                     pasteboard: UIPasteboard,
                     forPasteboardType pasteboardType: String) throws -> Data?
}
