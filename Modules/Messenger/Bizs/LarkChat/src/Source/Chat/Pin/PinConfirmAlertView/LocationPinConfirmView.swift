//
//  LocationPinConfirmView.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/29.
//

import UIKit
import Foundation
import LarkMessageCore
import LarkModel
import ByteWebImage
import LarkSDKInterface

final class LocationPinConfirmView: PinConfirmContainerView {
    let locationView: ChatLocationViewWrapper

    override init(frame: CGRect) {
        self.locationView = ChatLocationViewWrapper(
            setting: ChatLocationViewStyleSetting(
                nameFont: UIFont.ud.body1,
                descriptionFont: UIFont.ud.caption1,
                imageSize: FavoriteUtil.locationScreenShotSize
            )
        )
        super.init(frame: frame)
        self.addSubview(locationView)
        locationView.snp.makeConstraints { (make) in
            make.right.equalTo(-BubbleLayout.commonInset.right)
            make.left.top.equalTo(BubbleLayout.commonInset.left)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)

        guard let contentVM = contentVM as? LocationPinConfirmViewModel else {
            return
        }
        locationView.set(
            name: contentVM.name,
            description: contentVM.description,
            originSize: contentVM.originSize,
            setting: ChatLocationConsts.setting,
            locationTappedCallback: { },
            setLocationViewAction: { (imageView, completion) in
                let imageSet = ImageItemSet.transform(imageSet: contentVM.content.image)
                let key = imageSet.generateImageMessageKey(forceOrigin: false)
                let placeholder = imageSet.inlinePreview
                let resource = LarkImageResource.default(key: key)
                imageView.bt.setLarkImage(with: resource,
                                          placeholder: placeholder,
                                          completion: { result in
                                              switch result {
                                              case let .success(imageResult):
                                                  completion(imageResult.image, nil)
                                              case let .failure(error):
                                                  completion(nil, error)
                                              }
                                          })
            }, settingGifLoadConfig: contentVM.settingGifLoadConfig
        )
    }
}

// MARK: - ImagePinConfirmViewModel
final class LocationPinConfirmViewModel: PinAlertViewModel {
    var content: LocationContent!
    var settingGifLoadConfig: GIFLoadConfig?
    init?(locationMessage: Message, getSenderName: @escaping (Chatter) -> String, settingGifLoadConfig: GIFLoadConfig?) {
        self.settingGifLoadConfig = settingGifLoadConfig
        super.init(message: locationMessage, getSenderName: getSenderName)

        guard let content = locationMessage.content as? LocationContent else {
            return nil
        }
        self.content = content
    }

    /// 地理位置名称
    public var name: String {
        return self.content.location.name.isEmpty ? BundleI18n.LarkChat.Lark_Chat_MessageReplyStatusLocation("") : self.content.location.name
    }

    /// 地理位置描述
    public var description: String {
        return self.content.location.description_p
    }

    /// 预览图片的原始大小
    public var originSize: CGSize {
        return content.image.intactSize
    }
}
