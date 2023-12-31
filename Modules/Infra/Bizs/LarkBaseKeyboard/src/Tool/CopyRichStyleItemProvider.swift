//
//  CopyRichStyleItemProvider.swift
//  LarkRichTextCore
//
//  Created by liluobin on 2023/1/9.
//

import Foundation
import UIKit

public class CopyRichStyleItemProvider: NSObject, NSItemProviderReading {

    public static let typeIdentifier: String = "style.copy"

    public static var readableTypeIdentifiersForItemProvider: [String] = [typeIdentifier]

    enum RichStyleError: Error {
        case invalidTypeIdentifier
        case decodingFailure
    }

    public let json: String

    required init(_ json: String) {
        self.json = json
    }

    public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        guard self.readableTypeIdentifiersForItemProvider.contains(typeIdentifier) else {
            throw RichStyleError.invalidTypeIdentifier
        }
        if let json = String(data: data, encoding: .utf8) {
            return Self(json)
        } else {
            throw RichStyleError.decodingFailure
        }
    }

}
