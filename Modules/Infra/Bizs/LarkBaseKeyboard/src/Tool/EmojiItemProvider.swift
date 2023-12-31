//
//  EmojiItemProvider.swift
//  LarkRichTextCore
//
//  Created by phoenix on 2022/3/24.
//

import Foundation
import UIKit

public final class EmojiItemProvider: NSObject, NSItemProviderReading {
    public static let emojiIdentifier: String = "emoji.json"
    // Reading
    public static let readableTypeIdentifiersForItemProvider: [String] = [emojiIdentifier]

    enum EmojiError: Error {
        case invalidTypeIdentifier
        case decodingFailure
    }

    var json: String

    required init(_ json: String) {
        self.json = json
    }
    
    public func emojiKeyMapping() -> [NSRange: String]? {
        guard !json.isEmpty else {
            return nil
        }
        if let data = json.data(using: .utf8) {
            let dic = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            if let obj = dic as? [String: Any], !obj.isEmpty, let emoji = obj["emoji"] as? [String: String] {
                var emojiKeys: [NSRange: String] = [:]
                emoji.forEach { (key: String, value: String) in
                    if let range = rangeWithEmojiKey(key) {
                        emojiKeys[range] = value
                    }
                }
                return emojiKeys
            }
        }
        return nil
    }

    private func rangeWithEmojiKey(_ key: String) -> NSRange? {
        let rangeStrs = key.components(separatedBy: "_")
        guard rangeStrs.count == 2 else {
            return nil
        }
        if let location = Int(rangeStrs[0]), let length = Int(rangeStrs[1]) {
            return NSRange(location: location, length: length)
        }
        return nil
    }

    public static func emojiKeyForAttributedString(_ attributedString: NSAttributedString) -> [NSRange: String] {
        let muAttributedString = NSMutableAttributedString(attributedString: attributedString)
        var emojiKeys: [NSRange: String] = [:]
        muAttributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { (attributes, range, _) in
            
            let copyEmojiKey: String = "message.copy.emoji.key"
            let copyEmojiKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: copyEmojiKey)
            let filterAttributes = attributes.filter { attribute in
                attribute.key == copyEmojiKeyAttributedKey
            }
            if let value = filterAttributes.first?.value as? String {
                emojiKeys[range] = value
            }
        }
        return emojiKeys
    }

    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        guard self.readableTypeIdentifiersForItemProvider.contains(typeIdentifier) else {
            throw EmojiError.invalidTypeIdentifier
        }
        if let json = String(data: data, encoding: .utf8) {
            return Self(json)
        } else {
            throw EmojiError.decodingFailure
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
    
    public static func JSONStringWithEmoji(_ emoji: [NSRange: String], content: String) -> String? {
        var obj: [String: String] = [:]
        emoji.forEach { (key: NSRange, value: String) in
            obj["\(key.location)_\(key.length)"] = value
        }
        guard let data = JSONDataWithObject(object: ["emoji": obj, "content": content]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
