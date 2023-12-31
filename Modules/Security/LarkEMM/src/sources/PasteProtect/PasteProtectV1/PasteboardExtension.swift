//
//  PasteboardExtension.swift
//  EnterpriseMobilityManagement
//
//  Created by WangXijing on 2022/7/6.
//

import Foundation
import UIKit

public enum PasteType: Int {
    case all
    case string
    case color
    case image
    case url
}

extension UIPasteboard {

    private struct AssociatedKey {
        static var identifier: String?
    }
    var scUid: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKey.identifier) as? String
        }

        set {
            objc_setAssociatedObject(self, &AssociatedKey.identifier, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    public func hasNewValue(_ type: PasteType) -> Bool {
        switch type {
        case .string:
            return self.hasStrings
        case .color:
            return self.hasColors
        case .image:
            return self.hasImages
        case .url:
            return self.hasURLs
        case .all:
            let hasContent: Bool = self.hasStrings || self.hasColors || self.hasImages || self.hasURLs
            return hasContent
        }
    }

    public func clearPasteboard() {
        self.strings = nil
        self.colors = nil
        self.images = nil
        self.urls = nil
        self.items = []
    }
}
