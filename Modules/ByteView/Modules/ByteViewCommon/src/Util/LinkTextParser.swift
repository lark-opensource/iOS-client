//
//  LinkTextParser.swift
//  ByteView
//
//  Created by 李凌峰 on 2020/3/17.
//

import Foundation

public struct LinkComponent {
    public let text: String
    public let range: NSRange
    public let url: URL?

    public init(text: String, range: NSRange, url: URL? = nil) {
        self.text = text
        self.range = range
        self.url = url
    }
}

public struct LinkText {
    public let source: String
    public let result: String
    public let components: [LinkComponent]

    public init(source: String, result: String, components: [LinkComponent]) {
        self.source = source
        self.result = result
        self.components = components
    }
}

public struct LinkTextParser {

    public static func parsedLinkText(from source: String, by separator: String = "@@") -> LinkText {
        let substrings = source.components(separatedBy: separator)
        let count = substrings.count
        var result = ""
        var components: [LinkComponent] = []
        for (index, substring) in substrings.enumerated() {
            if index % 2 == 1 && index != count - 1 {
                // instead of using String.count, we should use NSString.length
                // it needs to be 16-bit code units within the string’s UTF-16 representation
                // and not the number of Unicode extended grapheme clusters within the string
                let location = NSString(string: result).length
                let length = NSString(string: substring).length
                let range = NSRange(location: location, length: length)
                let component = LinkComponent(text: substring, range: range)
                components.append(component)
            }
            result += substring
        }
        return LinkText(source: source, result: result, components: components)
    }
}
