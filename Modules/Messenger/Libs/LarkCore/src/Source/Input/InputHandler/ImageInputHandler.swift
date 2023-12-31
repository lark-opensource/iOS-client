//
//  ImageInputHandler.swift
//  LarkCore
//
//  Created by Saafo on 2021/6/16.
//

import UIKit
import Foundation
import LarkBizAvatar
import LarkModel
import UniverseDesignDialog
import ByteWebImage
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging

/// 处理单张图片的粘贴发送
public final class ImageInputHandler {

    public static func createSendAlert(userResolver: UserResolver, with image: UIImage, for chat: Chat, confirmCompletion: @escaping () -> Void
    ) -> UIViewController {
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.LarkCore.Lark_Legacy_ChatViewSendTo, alignment: .left)
        dialog.setContent(view: self.createConfirmContentView(userResolver: userResolver, chat: chat, image: image))
        dialog.addCancelButton()
        dialog.addPrimaryButton(text: BundleI18n.LarkCore.Lark_Legacy_LarkConfirm, dismissCompletion: {
            confirmCompletion()
        })
        return dialog
    }

    private static func createConfirmContentView(userResolver: UserResolver, chat: Chat, image: UIImage) -> UIView {
        let baseView = UIView()
        baseView.backgroundColor = UIColor.ud.N00

        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.alignment = .leading
        verticalStack.spacing = 0

        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.spacing = 10
        verticalStack.addArrangedSubview(horizontalStack)

        let avatarView: BizAvatar = BizAvatar()
        avatarView.setAvatarByIdentifier(chat.type == .p2P ? chat.chatterId : chat.id,
                                         avatarKey: chat.avatarKey, avatarViewParams: .init(sizeType: .size(32)))
        horizontalStack.addArrangedSubview(avatarView)
        avatarView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(32)
        }

        let nameLabel = UILabel()
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.textAlignment = .left
        nameLabel.font = UIFont.systemFont(ofSize: 15)
        nameLabel.text = chat.displayName
        horizontalStack.addArrangedSubview(nameLabel)

        verticalStack.setCustomSpacing(10, after: horizontalStack)
        // add 4px radius to image
        let wrapper = ImageConfirmFooter(userResolver: userResolver, image: image)
        verticalStack.addArrangedSubview(wrapper)
        wrapper.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.width.lessThanOrEqualTo(Cons.maxImageWidth)
        }

        return verticalStack
    }
}

enum Cons {
    static let maxImageHeight: CGFloat = 200
    static let maxImageWidth: CGFloat = 260
}

final class ImageConfirmFooter: UIView {
    let userResolver: UserResolver
    static let logger = Logger.log(ImageConfirmFooter.self, category: "InputHandler.ImageConfirmFooterView")
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(userResolver: UserResolver, image: UIImage) {
        self.userResolver = userResolver
        super.init(frame: .zero)
        let coverImage = hadPassCheck(image: image) ? image : getCompressImage(image: image)
        ImageConfirmFooter.logger.info("check end, coverImage: \(coverImage.size)")
        /// 实际的大小 比 原图的大小
        let scale = min(Cons.maxImageWidth / coverImage.size.width, Cons.maxImageHeight / coverImage.size.height)
        /// 显示在屏幕上的大小
        let scaledSize = CGSize(width: coverImage.size.width * scale, height: coverImage.size.height * scale)
        let imageView = UIImageView(image: coverImage)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 4
        imageView.layer.masksToBounds = true

        self.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.height.equalTo(scaledSize.height)
            $0.center.height.equalToSuperview()
            $0.width.equalTo(scaledSize.width)
        }
    }

    // 校验是否通过检查
    func hadPassCheck(image: UIImage) -> Bool {
        ImageConfirmFooter.logger.info("check image, origin image: \(image.size)")
        // 在chat列表内浏览图片，如果图片的像素大于750 * 1500就会使用降采样图片。此处保持一致
        let limitImageResolution = 750 * 1500
        if CGFloat(image.size.width * image.size.height) > CGFloat(limitImageResolution) {
            return false
        }
        return true
    }

    // 获取压缩降采样的图
    func getCompressImage(image: UIImage) -> UIImage {
        if let sendImageProcessor = try? userResolver.resolve(assert: SendImageProcessor.self),
           let processorResult = sendImageProcessor.process(source: .image(image), option: LarkImageService.shared.imageUploadWebP ? [.needConvertToWebp] : [], scene: .Chat) {
            return processorResult.image
        }
        return image
    }
}
