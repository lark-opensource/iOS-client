//
//  FocusTagView.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/12/23.
//

import Foundation
import UIKit
import LarkEmotion
import UniverseDesignTag
import LarkFocusInterface

public final class FocusTagView: UDTag, FocusTagViewAPI {

    public enum LayoutStyle {
        case compact
        case normal
    }

    public var style: LayoutStyle = .normal {
        didSet {
            updateTagAppearance()
        }
    }

    private var status: ChatterFocusStatus = .init()

    /// 单独设定 icon 的大小
    private var preferredSingleIconSize: CGFloat?

    public var image: UIImage? {
        get {
            configuration.icon
        }
        set {
            var configuration = configuration
            configuration.icon = newValue
            updateConfiguration(configuration)
        }
    }

    public func config(with focusStatus: ChatterFocusStatus) {
        self.status = focusStatus
        updateTagAppearance()
    }
    
    public init() {
        let configuration = FocusTagView.getUDTagConfiguration(with: status, style: style)
        super.init(configuration: configuration)
    }

    public init(preferredSingleIconSize: CGFloat) {
        self.preferredSingleIconSize = preferredSingleIconSize
        let configuration = FocusTagView.getUDTagConfiguration(with: status, style: style, preferredSingleIconSize: preferredSingleIconSize)
        super.init(configuration: configuration)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateTagAppearance() {
        let configuration = FocusTagView.getUDTagConfiguration(with: status, style: style, preferredSingleIconSize: preferredSingleIconSize)
        updateConfiguration(configuration)
    }
}

// MARK: - Constraints Definition

extension FocusTagView {

    // swiftlint:disable all
    var Constraints: Cons.Type {
        switch style {
        case .compact:  return ConsCompact.self
        case .normal:   return ConsRegular.self
        }
    }
    // swiftlint:enable all

    class Cons {
        class var height: CGFloat { 18 }
        class var hMargin: CGFloat { 4 }
        class var tagIconSize: CGFloat { 14 }
        class var singleIconSize: CGFloat { 20 }
        class var tagCornerRadius: CGFloat { 4 }
        class var iconTitleSpacing: CGFloat { 2 }
        class var tagFont: UIFont { UIFont.ud.caption0(.fixed) }
    }

    final class ConsRegular: Cons {}

    final class ConsCompact: Cons {
        override class var height: CGFloat { 14 }
        override class var hMargin: CGFloat { 3 }
        override class var tagIconSize: CGFloat { 12 }
        override class var singleIconSize: CGFloat { 14 }
        override class var tagCornerRadius: CGFloat { 4 }
        override class var iconTitleSpacing: CGFloat { 1 }
        override class var tagFont: UIFont { UIFont.ud.caption2(.fixed) }
    }
    
    static func getUDTagConfiguration(with status: ChatterFocusStatus,
                                      style: LayoutStyle = .normal,
                                      preferredSingleIconSize: CGFloat? = nil) -> UDTag.Configuration {
        // swiftlint:disable all
        var Cons: Cons.Type = {
            switch style {
            case .compact:  return ConsCompact.self
            case .normal:   return ConsRegular.self
            }
        }()
        // swiftlint:enable all
        var showTag = status.tagInfo.isShowTag
        return UDTag.Configuration(
            icon: EmotionResouce.shared.imageBy(key: status.iconKey),
            text: showTag ? status.title : nil,
            height: showTag ? Cons.height : preferredSingleIconSize ?? Cons.singleIconSize,
            backgroundColor: showTag ? status.tagInfo.tagColor.backgroundColor : .clear,
            cornerRadius: showTag ? Cons.tagCornerRadius : 0,
            horizontalMargin: showTag ? Cons.hMargin : 0,
            iconTextSpacing: Cons.iconTitleSpacing,
            textAlignment: .center,
            textColor: showTag ? status.tagInfo.tagColor.textColor : .clear,
            iconSize: showTag ? CGSize.square(Cons.tagIconSize) : CGSize.square(preferredSingleIconSize ?? Cons.singleIconSize),
            iconColor: nil,
            font: Cons.tagFont
        )
    }

    static func getContentSize(with status: ChatterFocusStatus,
                               style: LayoutStyle = .normal,
                               preferredSingleIconSize: CGFloat? = nil) -> CGSize {
        let configuration = getUDTagConfiguration(with: status, style: style, preferredSingleIconSize: preferredSingleIconSize)
        return UDTag.sizeToFit(configuration: configuration)
    }
}
