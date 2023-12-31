//
//  CodeItemProvider.swift
//  LarkRichTextCore
//
//  Created by Bytedance on 2022/11/10.
//

import UIKit
import RustPB
import Foundation

/// 复制代码块时，向粘贴板设置代码块信息
public final class CodeItemProvider: NSObject, NSItemProviderReading {
    /// 直接使用static传递，避免序列化
    public static var codeInfo: [(NSRange, Basic_V1_RichTextElement.CodeBlockV2Property)] = []

    enum CodeStyleError: Error {
        case invalidTypeIdentifier
        case decodingFailure
    }
    /// 剪贴板标识，存储代码块相关内容
    public static let codeIdentifier: String = "code.json"
    public static var readableTypeIdentifiersForItemProvider: [String] = [CodeItemProvider.codeIdentifier]

    /// 按照loaction排序后的内容
    private let codeInfo: [(NSRange, Basic_V1_RichTextElement.CodeBlockV2Property)]

    // MARK: - init
    required init(_ codeInfo: [(NSRange, Basic_V1_RichTextElement.CodeBlockV2Property)]) {
        // 按照loaction从小往大排序
        self.codeInfo = codeInfo.sorted { $0.0.location < $1.0.location }
        super.init()
    }

    // MARK: - public
    public func transformPasteAttributedString(attributedString: NSAttributedString) -> NSAttributedString {
        let resultAttributedString = NSMutableAttributedString(attributedString: attributedString)
        // 指定reversed，需要从后往前进行替换
        self.codeInfo.reversed().forEach { (range, property) in
            let attachmentString = CodeTransformer.transformPropertyToTextAttachment(property)
            resultAttributedString.replaceCharacters(in: range, with: attachmentString)
        }
        return resultAttributedString
    }
    public func fixEmojiKeyMapping(map: [NSRange: String]) -> [NSRange: String] {
        // 先转换成数组，避免一个range修改后，写回map覆盖另一个range
        var mapArray = map.map { ($0, $1) }
        self.codeInfo.forEach { (range, _) in
            for index in 0..<mapArray.count {
                let element = mapArray[index]
                // mapArray中小于range的不用修改
                if element.0.location < range.location { continue }
                // 大于range的都需要减去代码块的长度
                mapArray[index] = (NSRange(location: element.0.location - range.length + 1, length: element.0.length), element.1)
            }
        }
        // 组装结果返回
        var map: [NSRange: String] = [:]
        mapArray.forEach { map[$0.0] = $0.1 }
        return map
    }

    // MARK: - static
    /// 调用itemProvider.loadObject(ofClass: CodeItemProvider.self)时会执行，读取剪贴板中指定provider的内容
    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        guard self.readableTypeIdentifiersForItemProvider.contains(typeIdentifier) else {
            throw CodeStyleError.invalidTypeIdentifier
        }
        if let json = String(data: data, encoding: .utf8), json == "CodeItemProvider" {
            return Self(CodeItemProvider.codeInfo)
        } else {
            throw CodeStyleError.decodingFailure
        }
    }
    public static func codeKeyForAttributedString(_ attributedString: NSAttributedString) -> [(NSRange, Basic_V1_RichTextElement.CodeBlockV2Property)] {
        var codeKeys: [(NSRange, Basic_V1_RichTextElement.CodeBlockV2Property)] = []
        let copyCodeKeyAttributedKey: NSAttributedString.Key = NSAttributedString.Key(rawValue: "message.copy.code.key")
        // 指定longestEffectiveRangeNotRequired，使相邻的代码块分开进行返回
        attributedString.enumerateAttribute(copyCodeKeyAttributedKey, in: NSRange(location: 0, length: attributedString.length), options: [.longestEffectiveRangeNotRequired]) { info, range, _ in
            // enumerateAttribute会遍历所有Range，并且都会输出，所以这里要做判断
            if let info = info as? Basic_V1_RichTextElement.CodeBlockV2Property { codeKeys.append((range, info)) }
        }
        return codeKeys
    }
    public static func JSONStringWithCode(_ code: [(NSRange, Basic_V1_RichTextElement.CodeBlockV2Property)], content: String) -> String? {
        // 写入静态变量，itemProvider.loadObject(ofClass: CodeItemProvider.self)时使用
        CodeItemProvider.codeInfo = code
        // 随意存一个值即可，之后CodeInputHandler.pasteboardContainsCode()能返回true即可
        return "CodeItemProvider"
    }
}
