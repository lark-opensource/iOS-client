//
//  FontStyleItemProvider.swift
//  LarkRichTextCore
//
//  Created by liluobin on 2021/9/28.
//

import Foundation
import UIKit

public final class FontStyleItemProvider: NSObject, NSItemProviderReading {
    public static let typeIdentifier: String = "style.json"
    // Reading
    public static let readableTypeIdentifiersForItemProvider: [String] = [typeIdentifier]
    public static let fontStyleItemProviderKey = NSAttributedString.Key(rawValue: "font.style.item.provider.key")

    enum FontStyleError: Error {
        case invalidTypeIdentifier
        case decodingFailure
    }

    var json: String

    required init(_ json: String) {
        self.json = json
    }

    public func attributeStringWithAttributes(_ attributes: [NSAttributedString.Key: Any]) -> NSAttributedString? {
        guard !json.isEmpty else {
            return nil
        }
        if let data = json.data(using: .utf8) {
            let dic = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            if let obj = dic as? [String: Any],
               !obj.isEmpty,
               let style = obj["style"] as? [String: [String]],
               let content = obj["content"] as? String,
               let font = attributes[.font] as? UIFont {
               let attr = NSMutableAttributedString(string: content)
                attr.addAttributes(attributes, range: NSRange(location: 0, length: attr.length))
                style.forEach { (key: String, value: [String]) in
                    if let range = rangeWithStyleKey(key) {
                        attr.addAttributes(attributesForValue(value, font: font), range: range)
                    }
                }
                attr.addAttributes([Self.fontStyleItemProviderKey: ""], range: NSRange(location: 0, length: attr.length))
                return attr
            }
        }
        return nil
    }

   private func rangeWithStyleKey(_ key: String) -> NSRange? {
        let rangeStrs = key.components(separatedBy: "_")
        guard rangeStrs.count == 2 else {
            return nil
        }
        if let location = Int(rangeStrs[0]), let length = Int(rangeStrs[1]) {
            return NSRange(location: location, length: length)
        }
        return nil
    }

    private func attributesForValue(_ value: [String], font: UIFont) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]
        value.forEach { attributedStringkey in
            switch attributedStringkey {
            case FontStyleConfig.underlineAttributedKey.rawValue:
                attributes[.underlineStyle] = FontStyleConfig.underlineStyle
                attributes[FontStyleConfig.underlineAttributedKey] = FontStyleConfig.underlineAttributedValue
            case FontStyleConfig.strikethroughAttributedKey.rawValue:
                attributes[.strikethroughStyle] = FontStyleConfig.strikethroughStyle
                attributes[FontStyleConfig.strikethroughAttributedKey] = FontStyleConfig.strikethroughAttributedValue
            case FontStyleConfig.boldAttributedKey.rawValue:
                attributes[FontStyleConfig.boldAttributedKey] = FontStyleConfig.boldAttributedValue
                if let font = attributes[.font] as? UIFont, font.isItalic {
                    attributes[.font] = font.boldItalic
                } else {
                    attributes[.font] = font.bold
                }
            case FontStyleConfig.italicAttributedKey.rawValue:
                attributes[FontStyleConfig.italicAttributedKey] = FontStyleConfig.italicAttributedValue
                if let font = attributes[.font] as? UIFont, font.isBold {
                    attributes[.font] = font.boldItalic
                } else {
                    attributes[.font] = font.italic
                }
            default:
                break
            }
        }
        return attributes
    }

    public static func styleForAttributedString(_ attributedString: NSAttributedString) -> [NSRange: [String]] {
        let muAttributedString = NSMutableAttributedString(attributedString: attributedString)
        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { (attributes, range, _) in
            let keys: [NSAttributedString.Key] = [FontStyleConfig.underlineAttributedKey,
                                                  FontStyleConfig.strikethroughAttributedKey,
                                                  FontStyleConfig.italicAttributedKey,
                                                  FontStyleConfig.boldAttributedKey]
            let invalidAttributes = attributes.filter { !keys.contains($0.key) }
            invalidAttributes.forEach { muAttributedString.removeAttribute($0.key, range: range) }
        }
        var styles: [NSRange: [String]] = [:]
        muAttributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { (attributes, range, _) in
            if !attributes.isEmpty {
                styles[range] = Array(attributes.keys).map({ $0.rawValue })
            }
        }
        return styles
    }

    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        guard self.readableTypeIdentifiersForItemProvider.contains(typeIdentifier) else {
            throw FontStyleError.invalidTypeIdentifier
        }
        if let json = String(data: data, encoding: .utf8) {
            return Self(json)
        } else {
            throw FontStyleError.decodingFailure
        }
    }
    public static func JSONDataWithObject(object: Any) -> Data? {
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [])
            return data
        } catch {
            return nil
        }
    }

    public static func JSONStringWithStyle(_ style: [NSRange: [String]], content: String) -> String? {
        var obj: [String: [String]] = [:]
        style.forEach { (key: NSRange, value: [String]) in
            obj["\(key.location)_\(key.length)"] = value
        }
        guard let data = JSONDataWithObject(object: ["style": obj, "content": content]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    public static func isStyleItemProviderCreateAttr(_ attr: NSAttributedString?) -> Bool {
        guard let attr = attr, attr.length > 0 else {
            return false
        }
        var isFromProvider = false
        attr.enumerateAttribute(fontStyleItemProviderKey, in: NSRange(location: 0, length: 1), options: []) { value, _, _ in
            if value != nil {
                isFromProvider = true
            }
        }
        return isFromProvider
    }

    public static func removeStyleTagKeyFor(attr: NSAttributedString) -> NSAttributedString {
        let muAttr = NSMutableAttributedString(attributedString: attr)
        muAttr.removeAttribute(Self.fontStyleItemProviderKey, range: NSRange(location: 0, length: muAttr.length))
        return muAttr
    }
}
