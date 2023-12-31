//
//  ViewFactory.swift
//  LarkBadge
//
//  Created by KT on 2020/3/4.
//

import UIKit
import Foundation

// swiftlint:disable missing_docs
public extension BadgeType {
    // 根据Type 实例化对应View
    var view: UIView? {
        switch self {
        case .none, .clear: return nil
        case .dot: return UIView()
        case let .view(view): return _copyView(view)
        case .image: return _defaultImageView
        case .icon: return _defaultImageView
        case .label: return _defaultLabel
        }
    }

    private var _defaultLabel: UILabel {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }

    private var _defaultImageView: UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    // 自定义View，copy一份，因为可能所有路径都需要显示
    private func _copyView(_ view: UIView) -> UIView? {
        let data = NSKeyedArchiver.archivedData(withRootObject: view)
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? UIView
    }
}
// swiftlint:enable missing_docs
