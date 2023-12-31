//
//  CountDownBoardButton.swift
//  ByteView
//
//  Created by wulv on 2022/5/1.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon
import UIKit

class CountDownBoardButton: UIButton {

    enum Style {
        /// 延长
        case prolong
        /// 提前结束
        case preEnd
        /// 重设
        case reset
        /// 关闭
        case close

        var image: UIImage {
            switch self {
            case .prolong:
                return UDIcon.getIconByKey(.addOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: Layout.imageWidth, height: Layout.imageWidth))
            case .preEnd:
                return UDIcon.getIconByKey(.stopOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: Layout.imageWidth, height: Layout.imageWidth))
            case .reset:
                return UDIcon.getIconByKey(.burnlifeNotimeOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: Layout.imageWidth, height: Layout.imageWidth))
            case .close:
                return UDIcon.getIconByKey(.moreCloseOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: Layout.imageWidth, height: Layout.imageWidth))
            }
        }

        var highlightImage: UIImage {
            switch self {
            case .prolong:
                return UDIcon.getIconByKey(.addOutlined, iconColor: UIColor.ud.N500, size: CGSize(width: Layout.imageWidth, height: Layout.imageWidth))
            case .preEnd:
                return UDIcon.getIconByKey(.stopOutlined, iconColor: UIColor.ud.N500, size: CGSize(width: Layout.imageWidth, height: Layout.imageWidth))
            case .reset:
                return UDIcon.getIconByKey(.burnlifeNotimeOutlined, iconColor: UIColor.ud.N500, size: CGSize(width: Layout.imageWidth, height: Layout.imageWidth))
            case .close:
                return UDIcon.getIconByKey(.moreCloseOutlined, iconColor: UIColor.ud.N500, size: CGSize(width: Layout.imageWidth, height: Layout.imageWidth))
            }
        }

        var title: String {
            switch self {
            case .prolong:
                return I18n.View_G_Extend_Button
            case .preEnd:
                return I18n.View_G_EndButton
            case .reset:
                return I18n.View_G_Reset_Icon
            case .close:
                return I18n.View_G_CloseButton
            }
        }
    }

    struct Layout {
        static let imageToTitle: CGFloat = 4.0
        static let imageWidth: CGFloat = 12.0
        static let cornerRadius: CGFloat = 6.0
        static let imageLeft: CGFloat = 4.0
        static let titleRight: CGFloat = 4.0
        static let height: CGFloat = 22.0
    }

    private(set) var style: Style = .prolong
    private let font = UIFont.systemFont(ofSize: 12)

    override init(frame: CGRect) {
        super.init(frame: frame)

        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setTitleColor(UIColor.ud.textTitle, for: .normal)
        setTitleColor(UIColor.ud.N500, for: .highlighted)
        titleLabel?.font = font
        contentEdgeInsets = UIEdgeInsets(top: 0, left: Layout.imageLeft, bottom: 0, right: Layout.titleRight)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -Layout.imageToTitle, bottom: 0, right: 0)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: Layout.imageToTitle, bottom: 0, right: 0)
        vc.setBackgroundColor(.clear, for: .normal)
        layer.cornerRadius = Layout.cornerRadius
        layer.masksToBounds = true
        addInteraction(type: .highlight)
        update(style, forced: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(_ style: Style, forced: Bool = false) {
        if !forced, style == self.style { return }
        self.style = style
        let title = style.title
        let size = size(by: style)
        snp.remakeConstraints {
            $0.size.equalTo(size)
        }
        setTitle(title, for: .normal)
        setImage(style.image, for: .normal)
        setImage(style.highlightImage, for: .highlighted)
    }

     func size(by style: Style) -> CGSize {
        let title = style.title
        let titleSize = title.size(withAttributes: [NSAttributedString.Key.font: font])
        let width = Layout.imageLeft + Layout.imageWidth + Layout.imageToTitle + ceil(titleSize.width) + Layout.titleRight
        let size = CGSize(width: width, height: Layout.height)
        return size
    }

    func updateWidth(_ width: CGFloat) {
        snp.remakeConstraints {
            $0.size.equalTo(CGSize(width: width, height: Layout.height))
        }
    }
}
