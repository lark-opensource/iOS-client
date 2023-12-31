//
// Created by liujianlong on 2022/8/23.
//

import UIKit
import UniverseDesignIcon
extension PadSwitchSceneButton.SceneType {

    var image: UIImage {
        switch self {
        case .gallery:
            return Self.galleryImage
        case .speech:
            return Self.speechImage
        case .thumbnailRow:
            return Self.thumbnailRowImage
        case .focus:
            return Self.focusImage
        case .webinarStage:
            return Self.stageImage
        }
    }

    private static let iconSize = CGSize(width: 24, height: 24)

    private static let galleryImage = UDIcon.getIconByKey(.gridViewOutlined, iconColor: UIColor.ud.iconN1, size: iconSize)

    private static let speechImage = UDIcon.getIconByKey(.floatingViewOutlined, iconColor: UIColor.ud.iconN1, size: iconSize)

    private static let thumbnailRowImage = UDIcon.getIconByKey(.activeSpeakerViewOutlined, iconColor: UIColor.ud.iconN1, size: iconSize)

    private static let focusImage = UDIcon.getIconByKey(.focusOutlined, iconColor: UIColor.ud.iconN1, size: iconSize)

    private static let stageImage = UDIcon.getIconByKey(.livestreamHybridOutlined, iconColor: UIColor.ud.iconN1, size: iconSize)
}

class PadSwitchSceneButton: UIButton {
    enum SceneType {
        // 宫格视图
        case gallery
        // 演讲者视图
        case speech
        // 缩略视图
        case thumbnailRow
        // 焦点视频
        case focus
        // Webinar 舞台模式
        case webinarStage
    }

    private static let highlightBgImg = UIImage.vc.fromColor(UIColor.ud.udtokenBtnTextBgNeutralHover)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        self.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        self.setBackgroundImage(nil, for: .normal)
        self.setBackgroundImage(Self.highlightBgImg, for: .highlighted)
        self.setBackgroundImage(Self.highlightBgImg, for: .selected)
        self.layer.cornerRadius = 8.0
        self.layer.masksToBounds = true
        self.contentEdgeInsets = UIEdgeInsets(horizontal: 10.0, vertical: 6.0)
        self.updateIcon()
        self.updateTitle(isRegular: self.isRegular)
    }

    var sceneType: SceneType = .gallery {
        didSet {
            guard self.sceneType != oldValue else {
               return
            }
            updateIcon()
            updateTitle(isRegular: self.isRegular)
        }
    }

    // 压缩模式（省略文字）
    var isCompressMode: Bool = false {
        didSet {
            guard self.isCompressMode != oldValue else { return }
            updateTitle(isRegular: self.isRegular)
        }
    }

    var totalWidth: CGFloat {
        let leftAndRightInset: CGFloat = 20
        let imageSize: CGFloat = 24
        let spacing: CGFloat = 4
        return leftAndRightInset + imageSize + spacing + I18n.View_G_Layout.vc.boundingWidth(height: 20, font: UIFont.systemFont(ofSize: 14, weight: .medium))
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != self.traitCollection.horizontalSizeClass {
            updateIcon()
            updateTitle(isRegular: self.isRegular)
            self.invalidateIntrinsicContentSize()
            self.setNeedsLayout()
        }
    }

    let titleSpacing = 4.0
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        let imageSize = super.imageRect(forContentRect: contentRect).size
        if self.isRegular {
            let labelSize = super.titleRect(forContentRect: contentRect).size
            return CGRect(origin: CGPoint(x: (contentRect.width - imageSize.width - labelSize.width - titleSpacing) * 0.5 + contentRect.origin.x,
                                          y: (contentRect.height - imageSize.height) * 0.5 + contentRect.origin.y),
                          size: imageSize)
        } else {
            return CGRect(origin: CGPoint(x: (contentRect.width - imageSize.width) * 0.5 + contentRect.origin.x,
                                          y: (contentRect.height - imageSize.height) * 0.5 + contentRect.origin.y),
                          size: imageSize)
        }
    }

    override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        let imageSize = super.imageRect(forContentRect: contentRect).size
        let labelSize = super.titleRect(forContentRect: contentRect).size
        if self.isRegular {
        return CGRect(origin: CGPoint(x: (contentRect.width - imageSize.width - labelSize.width - titleSpacing) * 0.5 + imageSize.width + titleSpacing + contentRect.origin.x,
                                      y: (contentRect.height - labelSize.height) * 0.5 + contentRect.origin.y),
                      size: labelSize)
        } else {
            return .zero
        }
    }

    private func updateIcon() {
        self.setImage(sceneType.image, for: .normal)
        self.setTitleColor(UIColor.ud.textTitle, for: .normal)
    }

    private func updateTitle(isRegular: Bool) {
        if self.sceneType == .focus {
            self.setTitle(isRegular && !isCompressMode ? I18n.View_G_Focus : nil, for: .normal)
        } else {
            self.setTitle(isRegular && !isCompressMode ? I18n.View_G_Layout : nil, for: .normal)
        }
    }

    override var intrinsicContentSize: CGSize {
        let imageSize = self.imageRect(forContentRect: CGRect(x: 0.0, y: 0.0, width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude)).size
        if self.isRegular {
            let titleSize = self.titleRect(forContentRect: CGRect(x: 0.0, y: 0.0, width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude)).size
            return CGSize(width: titleSize.width + imageSize.width + titleSpacing + contentEdgeInsets.left + contentEdgeInsets.right,
                          height: max(titleSize.height, imageSize.height) + contentEdgeInsets.top + contentEdgeInsets.bottom)
        } else {
            return CGSize(width: imageSize.width + contentEdgeInsets.left + contentEdgeInsets.right,
                          height: imageSize.height + contentEdgeInsets.top + contentEdgeInsets.bottom)
        }
    }
}
