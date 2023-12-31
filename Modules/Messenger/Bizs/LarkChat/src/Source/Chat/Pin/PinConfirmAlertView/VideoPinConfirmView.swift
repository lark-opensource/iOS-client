//
//  VideoPinConfirmView.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/9/14.
//

import Foundation
import UIKit
import LarkModel
import LarkMessageCore
import ByteWebImage
import LarkMessengerInterface

// MARK: - VideoPinConfirmView
final class VideoPinConfirmView: PinConfirmContainerView {
    private var videoView: VideoImageViewWrapper!
    var cornerRadius: CGFloat = 0 {
        didSet {
            self.videoView.layer.cornerRadius = cornerRadius
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)

        let videoView = VideoImageViewWrapper(isSmallPreview: true)
        videoView.status = .normal
        videoView.previewView.contentMode = .scaleAspectFill
        videoView.previewView.clipsToBounds = true
        videoView.hideTimeView()
        videoView.layer.masksToBounds = true
        self.addSubview(videoView)
        videoView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 83, height: 83))
            make.left.top.equalTo(BubbleLayout.commonInset.left)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
        }
        self.videoView = videoView
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)

        guard let contentVM = contentVM as? VideoPinConfirmViewModel, let imageInfo = contentVM.previewImageInfo else {
            return
        }
        if !self.videoView.handleAuthority(dynamicAuthorityEnum: contentVM.dynamicAuthorityEnum, hasPermissionPreview: contentVM.permissionPreview.0) {
            return
        }
        self.videoView.previewView.backgroundColor = .clear
        let setImageCompletion: ImageRequestCompletion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                break
            case .failure:
                self.videoView.previewView.backgroundColor = UIColor.ud.N200
            }
        }
        if !imageInfo.1.origin.key.isEmpty {
            let imageSet = ImageItemSet.transform(imageSet: imageInfo.1)
            let key = imageSet.generateVideoMessageKey(forceOrigin: false)
            let placeholder = imageSet.inlinePreview
            self.videoView.previewView.bt.setLarkImage(with: .default(key: key),
                                                       placeholder: placeholder,
                                                       trackStart: {
                                                           return TrackInfo(scene: .Chat, fromType: .media)
                                                       },
                                                       completion: setImageCompletion)
        } else {
            var imageItemSet = ImageItemSet()
            imageItemSet.origin = ImageItem(key: imageInfo.0)
            let set = ImageItemSet.transform(imageSet: imageInfo.1)
            let key = set.generateVideoMessageKey(forceOrigin: true)
            let placeholder = set.inlinePreview
            self.videoView.previewView.bt.setLarkImage(with: .default(key: key),
                                                       placeholder: placeholder,
                                                       trackStart: {
                                                           return TrackInfo(scene: .Chat, fromType: .media)
                                                       },
                                                       completion: setImageCompletion)
        }
    }
}

// MARK: - VideoPinConfirmViewModel
final class VideoPinConfirmViewModel: PinAlertViewModel {
    var previewImageInfo: (String, ImageSet)?
    var permissionPreview: (Bool, ValidateResult?)
    var dynamicAuthorityEnum: DynamicAuthorityEnum

    init?(mediaMessage: Message,
          permissionPreview: (Bool, ValidateResult?),
          dynamicAuthorityEnum: DynamicAuthorityEnum,
          getSenderName: @escaping (Chatter) -> String) {
        self.permissionPreview = permissionPreview
        self.dynamicAuthorityEnum = dynamicAuthorityEnum
        super.init(message: mediaMessage, getSenderName: getSenderName)
        guard let content = mediaMessage.content as? MediaContent else {
            return nil
        }
        self.previewImageInfo = (message.id, content.image)
    }
}
