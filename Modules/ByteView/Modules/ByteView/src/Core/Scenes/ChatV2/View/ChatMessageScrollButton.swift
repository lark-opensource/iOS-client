//
//  ChatMessageScrollButton.swift
//  ByteView
//
//  Created by wulv on 2020/12/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import UniverseDesignIcon

extension ChatMessageScrollButton {
    enum Style {
        case normal
        case messageTip(count: Int)

        var title: String {
            switch self {
            case .normal:
                return I18n.View_G_BackToBottom
            case .messageTip(let count):
                if count > 1 {
                    return I18n.View_M_NewMessagesNumber(count)
                } else {
                    return I18n.View_M_NewMessageOne(count)
                }
            }
        }

        var titleColor: UIColor {
            switch self {
            case .normal:
                return UIColor.ud.primaryContentDefault
            case .messageTip:
                return UIColor.ud.primaryOnPrimaryFill
            }
        }

        var highlightedTitleColor: UIColor {
            switch self {
            case .normal:
                return UIColor.ud.primaryContentDefault
            case .messageTip:
                return UIColor.ud.primaryOnPrimaryFill
            }
        }

        var image: UIImage? {
            switch self {
            case .normal:
                return UDIcon.getIconByKey(.moveBottomFilled, iconColor: .ud.primaryContentDefault, size: CGSize(width: 16, height: 16))
            case .messageTip:
                return UDIcon.getIconByKey(.moveBottomFilled, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 16, height: 16))
            }
        }

        var highlightedImage: UIImage? {
            switch self {
            case .normal:
                return UDIcon.getIconByKey(.moveBottomFilled, iconColor: .ud.primaryContentDefault, size: CGSize(width: 16, height: 16))
            case .messageTip:
                return UDIcon.getIconByKey(.moveBottomFilled, iconColor: .ud.primaryOnPrimaryFill, size: CGSize(width: 16, height: 16))
            }
        }

        var color: UIColor {
            switch self {
            case .normal:
                return UIColor.ud.bgFloat
            case .messageTip:
                return UIColor.ud.primaryContentDefault
            }
        }

        var hightlightedColor: UIColor {
            switch self {
            case .normal:
                return UIColor.ud.primaryFillSolid02
            case .messageTip:
                return UIColor.ud.primaryContentPressed
            }
        }
    }
}

class ChatMessageScrollButton: UIButton {

    var style: Style = .normal {
        didSet {
            setTitle(style.title, for: .normal)
            setImage(style.image, for: .normal)
            setImage(style.highlightedImage, for: .highlighted)
            setTitleColor(style.titleColor, for: .normal)
            setTitleColor(style.highlightedTitleColor, for: .highlighted)
            vc.setBackgroundColor(style.color, for: .normal)
            vc.setBackgroundColor(style.hightlightedColor, for: .highlighted)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel?.font = UIFont.systemFont(ofSize: 12)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 12)
        style = .normal
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
