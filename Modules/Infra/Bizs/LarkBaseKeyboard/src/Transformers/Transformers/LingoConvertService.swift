//
//  LingoConvertService.swift
//  LarkBaseKeyboard
//
//  Created by ByteDance on 2023/5/29.
//

import Foundation
import RustPB

public struct SingleLingoElement: Persistable {
    public static var `default` = SingleLingoElement()

    public var abbrId: String = ""  /// 词条ID
    public var name: String = ""  /// 词条内容
    public var isIgnore: Bool = false  /// 是否被忽略， 默认为false
    public var pinId: String = "" /// pin的内容
    public var location: Int = 0 /// 位置信息，用于从 model恢复到nsAttributedString的时候使用
    public var length: Int = 0 /// 位置信息
    public init(abbrId: String = "",
                name: String = "",
                isIgnore: Bool = false,
                pinId: String = "",
                location: Int = 0,
                length: Int = 0) {
        self.abbrId = abbrId
        self.name = name
        self.pinId = pinId
        self.isIgnore = isIgnore
        self.location = location
        self.length = length
    }
    public init(unarchive: [String : Any]) {
        guard let abbrId = unarchive["abbrId"] as? String,
              let name = unarchive["name"] as? String
        else {
            return
        }
        self.abbrId = abbrId
        self.name = name
        if let isIgnore = unarchive["isIgnore"] as? Bool {
            self.isIgnore = isIgnore
        }
        if let location = unarchive["location"] as? Int {
            self.location = location
        }
        if let length = unarchive["length"] as? Int {
            self.length = length
        }
        if let pinId = unarchive["pinId"] as? String {
            self.pinId = pinId
        }
    }

    public func archive() -> [String : Any] {
        return [
            "abbrId": self.abbrId,
            "name": self.name,
            "isIgnore": self.isIgnore,
            "location": location,
            "length": self.length,
            "pinId": self.pinId
        ]
    }
}

extension SingleLingoElement: Equatable {
    public static func == (lhs: SingleLingoElement, rhs: SingleLingoElement) -> Bool {
        return lhs.abbrId == rhs.abbrId &&
        lhs.name == rhs.name &&
        lhs.isIgnore == rhs.isIgnore &&
        lhs.location == rhs.location &&
        lhs.length == rhs.length &&
        lhs.pinId == rhs.pinId
    }
}

public final class LingoConvertService: NSObject {
    public static let LingoInfoKey = NSAttributedString.Key(rawValue: "lingoInfo")

    /// 将nsAttributedString转换为Model中SingleLingoElement， 用作保存草稿
    /// - Parameter text:  输入框文本
    /// - Returns:  保存的草稿模型
    public static func transformStringToDraftModel(_ text: NSAttributedString) -> [SingleLingoElement] {
        var draftModel: [SingleLingoElement] = []
        text.enumerateAttribute(LingoConvertService.LingoInfoKey, in: NSRange(location: 0, length: text.length), options: []) { info, _, _ in
            if let info = info as? SingleLingoElement {
                draftModel.append(info)
            }
        }
        return draftModel
    }

    /// 将Model中的singleLingoElement转换为NSAttributedString，用作从草稿恢复
    /// - Parameters:
    ///   - lingoElements: 草稿数据
    ///   - text: 输入框文本
    /// - Returns: 输入框文本--携带百科操作数据（样式不需要添加）
    public static func transformModelToString(elements lingoElements: [SingleLingoElement], text: NSAttributedString) -> NSAttributedString {
        var inputString = NSMutableAttributedString(attributedString: text)
        for lingoElement in lingoElements {
            if !lingoElement.name.isEmpty,
               let wordRange = text.string.range(of: lingoElement.name) {
                let wordNSRange = NSRange(wordRange, in: text.string)
                let storageRange = NSRange(location: lingoElement.location, length: lingoElement.length)
                if wordNSRange == storageRange {
                    inputString.addAttributes([LingoConvertService.LingoInfoKey: lingoElement], range: wordNSRange)
                }
            }
        }
        return inputString
    }

    /// 将nsAttributedString转换为QuasiContent.LingoOption
    public static func transformStringToQuasiContent(_ text: NSAttributedString) -> RustPB.Basic_V1_LingoOption {
        var highlightIgnoreWords: [String] = []
        var pinInfo: Dictionary<String,String> = [:]
        text.enumerateAttribute(LingoConvertService.LingoInfoKey, in: NSRange(location: 0, length: text.length), options: []) { info, _, _ in
            if let info = info as? SingleLingoElement, !info.name.isEmpty {
                if info.isIgnore {
                    highlightIgnoreWords.append(info.name)
                }
                if !info.pinId.isEmpty {
                    pinInfo = pinInfo.merging([info.name: info.pinId]){ $1 }
                }
            }
        }

        var lingoOption = RustPB.Basic_V1_LingoOption()
        lingoOption.highlightIgnoreWords = highlightIgnoreWords
        lingoOption.pinInfo = pinInfo
        return lingoOption
    }
}
