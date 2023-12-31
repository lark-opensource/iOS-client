//
//  ImagePinConfirmView.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/29.
//

import Foundation
import LarkModel
import ByteWebImage
import AppReciableSDK
import UIKit
import LarkMessengerInterface
import RustPB

// MARK: - ImagePinConfirmView
final class ImagePinConfirmView: PinConfirmContainerView {

    var imageView: UIImageView = .init(image: nil)

    override init(frame: CGRect) {
        super.init(frame: frame)

        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        imageView.layer.ud.setBorderColor(UIColor.ud.N300)
        imageView.layer.borderWidth = 1
        imageView.layer.cornerRadius = 4
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(80)
            make.left.top.equalTo(BubbleLayout.commonInset.left)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
        }
        self.imageView = imageView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)

        guard let contentVM = contentVM as? ImagePinConfirmViewModel else {
            return
        }
        if !(contentVM.permissionPreview.0 && contentVM.dynamicAuthorityEnum.authorityAllowed) {
            self.imageView.backgroundColor = UIColor.ud.bgFloatOverlay
            self.imageView.image = Resources.no_preview_permission
            self.imageView.contentMode = .center
            return
        }
        imageView.backgroundColor = UIColor.clear
        imageView.contentMode = .scaleAspectFill
        self.imageView.setImageWithAction { (imageView, completion) in
            let imageSet = ImageItemSet.transform(imageSet: contentVM.content.image)
            let key = imageSet.generateImageMessageKey(forceOrigin: false)
            let placeholder = imageSet.inlinePreview
            let resource = LarkImageResource.default(key: key)
            imageView.bt.setLarkImage(
                with: resource,
                placeholder: placeholder,
                trackStart: {
                    TrackInfo(scene: .Chat, fromType: .image)
                },
                completion: { result in
                    switch result {
                    case .success(let imageResult):
                        completion(imageResult.image, nil)
                    case .failure(let error):
                        completion(placeholder, error)
                    }
                }
            )
        }
    }
}

// MARK: - ImagePinConfirmViewModel
final class ImagePinConfirmViewModel: PinAlertViewModel {
    var content: ImageContent = .transform(pb: RustPB.Basic_V1_Message())
    var permissionPreview: (Bool, ValidateResult?)
    var dynamicAuthorityEnum: DynamicAuthorityEnum
    init?(imageMessage: Message,
          permissionPreview: (Bool, ValidateResult?),
          dynamicAuthorityEnum: DynamicAuthorityEnum,
          getSenderName: @escaping (Chatter) -> String) {
        self.permissionPreview = permissionPreview
        self.dynamicAuthorityEnum = dynamicAuthorityEnum
        super.init(message: imageMessage, getSenderName: getSenderName)
        guard let content = imageMessage.content as? ImageContent else {
            return nil
        }
        self.content = content
    }
}

final class StickerPinConfirmView: PinConfirmContainerView {

    var imageView: UIImageView = .init(image: nil)

    override init(frame: CGRect) {
        super.init(frame: frame)

        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.clear
        imageView.layer.borderColor = UIColor.ud.N300.cgColor
        imageView.layer.borderWidth = 1
        imageView.layer.cornerRadius = 4
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        self.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(80)
            make.left.top.equalTo(BubbleLayout.commonInset.left)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
        }
        self.imageView = imageView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)

        guard let contentVM = contentVM as? StickerPinConfirmViewModel else {
            return
        }
        self.imageView.setImageWithAction { (imageView, completion) in
            imageView.bt.setLarkImage(with: .sticker(key: contentVM.key, stickerSetID: ""),
                                      trackStart: {
                                        return TrackInfo(scene: .Chat, fromType: .sticker)
                                      },
                                      completion: { result in
                                        switch result {
                                        case .success(let imageResult):
                                            completion(imageResult.image, nil)
                                        case .failure(let error):
                                            completion(nil, error)
                                        }
                                      })
        }
    }
}

// MARK: - ImagePinConfirmViewModel
final class StickerPinConfirmViewModel: PinAlertViewModel {
    var content: StickerContent!

    var key: String {
        return self.content.key
    }

    init?(stickerMessage: Message, getSenderName: @escaping (Chatter) -> String) {
        super.init(message: stickerMessage, getSenderName: getSenderName)

        guard let content = stickerMessage.content as? StickerContent else {
            return nil
        }
        self.content = content
    }
}
