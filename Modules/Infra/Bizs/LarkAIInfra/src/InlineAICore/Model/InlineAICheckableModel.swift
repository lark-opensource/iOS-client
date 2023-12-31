//
//  InlineAICheckableModel.swift
//  LarkInlineAI
//
//  Created by huayufan on 2023/6/19.
//  


import UIKit

public enum InlineAIImageData {
    case image(UIImage)
    case url(URL)
    case placeholder
    case error
    
    var isImage: Bool {
        switch self {
        case .image:
            return true
        default:
            return false
        }
    }
    
    var urlString: String? {
        switch self {
        case let .url(url):
            return url.absoluteString
        default:
            return nil
        }
    }
    
    var isPlaceholder: Bool {
        switch self {
        case .placeholder:
            return true
        default:
            return false
        }
    }
}

public struct InlineAICheckableModel: CustomStringConvertible {
    ///  大于0表示选中，0为反选，负数为不可选
    var checkNum: Int
    var source: InlineAIImageData
    public var id: String

    public var description: String {
        let urlString = source.urlString ?? ""
        return "id:\(urlString.md5()) num:\(checkNum)"
    }
    enum Style {
        case selected
        case unselected
        case disable
    }
    
    mutating func update(checkNum: Int) {
        self.checkNum = checkNum
    }
    
    var style: Style {
        let base = 0
        if checkNum == base {
            return .unselected
        } else if checkNum > base {
            return .selected
        } else {
            return .disable
        }
    }
}
