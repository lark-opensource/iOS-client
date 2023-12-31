//
//  ShareCanvasAlertController.swift
//  LarkCore
//
//  Created by Saafo on 2021/2/25.
//

import UIKit
import EditTextView
import Foundation
import Homeric
import LarkBizAvatar
import LarkModel
import LarkSDKInterface
import LKCommonsTracker
import LKCommonsLogging
import UniverseDesignColor
import UniverseDesignDialog
import ByteWebImage
import LarkSendMessage // ImageMessageInfo

public final class ShareCanvasAlertController: UDDialog {

    static let logger = Logger.log(ShareCanvasAlertController.self,
                                   category: "Module.LarkCore.ShareCanvasAlertController")

    /// 留言框
    public var textInputView: LarkEditTextView = LarkEditTextView()

    public init(for chat: Chat,
                drawingImage: UIImage,
                dismissTitle: String,
                canvasShouldDismissCallback: @escaping (Bool) -> Void,
                sendCanvasImageAndTextBlock: @escaping (ImageMessageInfo, String?) -> Void) {
        super.init()
        self.setContent(chat: chat, image: drawingImage)
        self.addCancelButton(dismissCompletion: {
            canvasShouldDismissCallback(false)
        })
        self.setSendCanvasWithTextDismissButton(title: dismissTitle,
                                                drawingImage: drawingImage,
                                                sendCanvasImageAndTextBlock: sendCanvasImageAndTextBlock)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 设置「发送到」标题、接受者头像名称、画板图片预览和留言框
    public func setContent(chat: Chat, image: UIImage) {

        // 设置 title
        self.setTitle(text: BundleI18n.LarkCore.Lark_Core_SendImageTo, alignment: .left)

        // 整体垂直排布
        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.alignment = .leading
        verticalStack.spacing = 10

        // 头像横向排布
        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.spacing = 10

        let avatarView = BizAvatar()
        avatarView.setAvatarByIdentifier(chat.type == .p2P ? chat.chatterId : chat.id, avatarKey: chat.avatarKey,
                                         avatarViewParams: .init(sizeType: .size(32)))
        horizontalStack.addArrangedSubview(avatarView)
        avatarView.snp.makeConstraints {
            $0.size.equalTo(32)
        }

        let nameLabel = UILabel()
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.textAlignment = .left
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.text = chat.displayName
        horizontalStack.addArrangedSubview(nameLabel)
        verticalStack.addArrangedSubview(horizontalStack)
        horizontalStack.snp.makeConstraints {
            $0.width.equalToSuperview()
        }

        // 图片预览
        // add 4px radius to image
        /// 实际的大小 比 原图的大小
        let scale = min(Cons.maxImageWidth / image.size.width, Cons.maxImageHeight / image.size.height)
        /// 显示在屏幕上的大小
        let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 4
        imageView.layer.masksToBounds = true
        /// imageView 因为要做圆角处理需要和图片尺寸相同，所以还需要有一个 wrapperView 来撑起宽度或高度
        let wrapper = UIView()
        wrapper.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.height.equalTo(scaledSize.height)
            $0.center.equalToSuperview()
            $0.width.equalTo(scaledSize.width)
        }
        verticalStack.addArrangedSubview(wrapper)
        wrapper.snp.makeConstraints {
            $0.height.equalTo(Cons.maxImageHeight)
            $0.centerX.equalToSuperview()
            $0.width.lessThanOrEqualTo(Cons.maxImageWidth)
        }

        // 留言框
        let font = UIFont.systemFont(ofSize: 14)
        let defaultTypingAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.textTitle,
            .paragraphStyle: {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = 2
                return paragraphStyle
            }()
        ]
        textInputView.defaultTypingAttributes = defaultTypingAttributes
        textInputView.font = font
        textInputView.placeholder = BundleI18n.LarkCore.Lark_Legacy_ADDNOTE
        textInputView.placeholderTextColor = UIColor.ud.textPlaceholder
        textInputView.textContainerInset = UIEdgeInsets(top: 11, left: 10, bottom: 11, right: 10)
        textInputView.layer.borderWidth = 1
        textInputView.layer.ud.setBorderColor(UIColor.ud.N300)
        textInputView.layer.cornerRadius = 6
        textInputView.maxHeight = 55
        verticalStack.addArrangedSubview(textInputView)
        textInputView.snp.makeConstraints {
            $0.width.equalTo(279)
            $0.height.greaterThanOrEqualTo(36)
            $0.height.lessThanOrEqualTo(55)
        }

        self.setContent(view: verticalStack)
    }

    public func setSendCanvasWithTextDismissButton(
        title: String,
        drawingImage: UIImage,
        sendCanvasImageAndTextBlock: @escaping (ImageMessageInfo, String?) -> Void
    ) {
        self.addPrimaryButton(
            text: title,
            dismissCompletion: { [weak self] in
                guard let `self` = self else {
                    Self.logger.error("Cannot find self(ShareCanvasAlertController) on alertController dismissing")
                    return
                }
                Tracker.post(TeaEvent(Homeric.IM_WHITEBOARD_SENT_CLICK))
                // Compose message
                let imageSourceFunc: ImageSourceFunc = {
                    ImageSourceResult(sourceType: .png, data: drawingImage.pngData(), image: drawingImage)
                }
                let imageMessageInfo = ImageMessageInfo(originalImageSize: drawingImage.size, sendImageSource: SendImageSource(cover: imageSourceFunc, origin: imageSourceFunc))
                let rawText = self.textInputView.text ?? ""
                let text: String? = rawText.isEmpty ? nil : rawText
                // Send message
                sendCanvasImageAndTextBlock(imageMessageInfo, text)
            }
        )
    }
    private enum Cons {
        static let maxImageHeight: CGFloat = 200
        static let maxImageWidth: CGFloat = 260
    }
}
