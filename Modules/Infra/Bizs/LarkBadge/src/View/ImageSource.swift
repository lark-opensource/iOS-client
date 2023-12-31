//
//  ImageSource.swift
//  Kingfisher
//
//  Created by KT on 2020/3/4.
//

import Foundation
import UIKit

// swiftlint:disable missing_docs
/// 图片资源
public enum ImageSource {
    case web(URL)                // 网络图片
    case locol(String)           // 本地图片 - name
    case key(String)             // rust icon key
    case `default`(DefaultImage) // 默认图片
    case image(UIImage)
}

extension ImageSource: Equatable {
    public static func ==(lhs: ImageSource, rhs: ImageSource) -> Bool {
        switch (lhs, rhs) {
        case let (.web(l), .web(r)):
            return l == r
        case let (.locol(l), .locol(r)):
            return l == r
        case let (.image(l), .image(r)):
            return l == r
        case let (.key(l), .key(r)):
            return l == r
        default:
            return false
        }
    }
}

/// 本地内置图片
public enum DefaultImage {
    case new        // NEW
    case edit       // SideBar Edit
    case more(More) // 更多"..." 超过BadgeType.maxNumber显示

    var source: UIImage? {
        switch self {
        case .new: return BundleResources.LarkBadge.cal_new
        case .edit: return BundleResources.LarkBadge.edit
        case .more(let more): return more.image
        }
    }
    // "..." 的三个样式
    public enum More {
        case strong
        case middle
        case weak

        var image: UIImage {
            switch self {
            case .strong: return BundleResources.LarkBadge.more_strong
            case .middle: return BundleResources.LarkBadge.more_middle
            case .weak: return BundleResources.LarkBadge.more_weak
            }
        }
    }
}
// swiftlint:enable missing_docs
