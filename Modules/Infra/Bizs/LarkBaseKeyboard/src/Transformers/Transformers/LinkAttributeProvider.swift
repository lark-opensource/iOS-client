//
//  LinkAttributeProvider.swift
//  LarkRichTextCore
//
//  Created by ByteDance on 2023/3/22.
//

import Foundation

public enum LinkAttributeValue {
    case at
    case sultString(sourceText: String, index: Int) //智能纠错
    case lingoHighlight(id: String, name: String, isSingleName: Bool, pinId: String? = nil)// 企业百科
    public var rawValue: URL? {
        switch self {
        case .at:
            return URL(string: "/at?\(Date().timeIntervalSince1970)") //加个时间戳作区分，以免把不同的at识别成同一个url
        case .sultString(let sourceText, let index):
            let string = "/sultString?sourceText=\(sourceText)&index=\(index)"
            if let newString = string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                return URL(string: newString)
            } else {
                return nil
            }
        case .lingoHighlight(let id, let name, let isSingleName, let pinId):
            var urlString: String
            if let pinId = pinId {
                urlString = "/lingo?id=\(id)&name=\(name)&isSingleName=\(isSingleName)&pinId=\(pinId)"
            } else {
                urlString = "/lingo?id=\(id)&name=\(name)&isSingleName=\(isSingleName)"
            }
            if let newString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                return URL(string: newString)
            } else {
                return nil
            }
        }
    }

    public init?(rawValue: URL?) {
        guard let rawValue = rawValue else { return nil }
        if rawValue.absoluteString.starts(with: "/at") {
            self = .at
        } else if rawValue.absoluteString.starts(with: "/sultString") {
            let queryItems = rawValue.queryItems
            var sourceText = ""
            var index = 0
            for queryItem in queryItems {
                if queryItem.name == "sourceText" {
                    sourceText = queryItem.value ?? ""
                } else if queryItem.name == "index" {
                    index = Int(queryItem.value ?? "") ?? 0
                }
            }
            self = .sultString(sourceText: sourceText, index: index)
        } else if rawValue.absoluteString.starts(with: "/lingo") {
            let queryItems = rawValue.queryItems
            var id = ""
            var name = ""
            var isSingleName = true
            var pinId: String?
            for queryItem in queryItems {
                if queryItem.name == "id" {
                    id = queryItem.value ?? ""
                } else if queryItem.name == "name" {
                    name = queryItem.value ?? ""
                } else if queryItem.name == "isSingleName" {
                    isSingleName = (queryItem.value as? NSString)?.boolValue ?? true
                } else if queryItem.name == "pinId" {
                    pinId = queryItem.value
                }
            }
            self = .lingoHighlight(id: id, name: name, isSingleName: isSingleName, pinId: pinId)
        } else {
            return nil
        }
    }
}
extension URL {
    var queryItems: [URLQueryItem] {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else { return [] }
        return queryItems
    }
}
