//
//  JoinRoomPopoverButton.swift
//  ByteView
//
//  Created by kiri on 2023/6/9.
//

import Foundation
import UniverseDesignIcon

final class JoinRoomPopoverButton: UIButton {
    private static let highlightBgImg = UIImage.vc.fromColor(.ud.udtokenBtnTextBgNeutralHover)
    private static let normalRegularImg = UDIcon.getIconByKey(.videoSystemOutlined, iconColor: .ud.iconN1, size: CGSize(width: 20, height: 20))
    private static let normalCompactImg = UDIcon.getIconByKey(.videoSystemOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24))
    private static let connectedRegularImg = UDIcon.getIconByKey(.videoSystemOutlined, iconColor: .ud.functionSuccessContentDefault,
                                                                 size: CGSize(width: 20, height: 20))
    private static let connectedCompactImg = UDIcon.getIconByKey(.videoSystemOutlined, iconColor: .ud.functionSuccessContentDefault,
                                                                 size: CGSize(width: 24, height: 24))

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        self.setBackgroundImage(nil, for: .normal)
        self.setBackgroundImage(Self.highlightBgImg, for: .highlighted)
        self.setBackgroundImage(Self.highlightBgImg, for: .selected)
        self.layer.cornerRadius = 8.0
        self.layer.masksToBounds = true
        self.contentEdgeInsets = UIEdgeInsets(horizontal: 10.0, vertical: 6.0)
        self.setImage(normalImg, for: .normal)
    }

    var isConnected: Bool = false {
        didSet {
            if isConnected != oldValue {
                self.setImage(isConnected ? connectedImg : normalImg, for: .normal)
            }
        }
    }

    var isInNavigation: Bool = false {
        didSet {
            if isInNavigation != oldValue {
                self.setImage(isConnected ? connectedImg : normalImg, for: .normal)
            }
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != self.traitCollection.horizontalSizeClass {
            self.setImage(isConnected ? connectedImg : normalImg, for: .normal)
            self.setNeedsLayout()
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 44, height: 36)
    }

    private var normalImg: UIImage {
        if isInNavigation { return Self.normalCompactImg }
        return traitCollection.horizontalSizeClass == .regular ? Self.normalRegularImg : Self.normalCompactImg
    }

    private var connectedImg: UIImage {
        if isInNavigation { return Self.connectedCompactImg }
        return traitCollection.horizontalSizeClass == .regular ? Self.connectedRegularImg : Self.connectedCompactImg
    }
}
