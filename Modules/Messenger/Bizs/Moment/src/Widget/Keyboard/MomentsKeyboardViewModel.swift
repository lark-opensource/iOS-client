//
//  MomentsKeyboardViewModel.swift
//  Moment
//
//  Created by bytedance on 2021/1/7.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import LarkKeyboardView
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import LarkAttachmentUploader
import LarkAlertController
import ByteWebImage
import LarkMessengerInterface
import RustPB
import RxSwift
import LarkFeatureGating
import LarkSetting

/// 发送相关的代理
protocol MomentsKeyboardViewModelDelegate: AnyObject {
    func willStartUploadUserSelectedImage()
    func uploadUserSelectedImageFinished(error: Error?)
    func defaultInputSendTextMessage(_ content: RustPB.Basic_V1_RichText?, imageInfo: RawData.ImageInfo?, replyComment: RawData.CommentEntity?, isAnonymous: Bool)
}

final class MomentsKeyboardSeletedImage {
    // image的token
    var token = ""
    // 附件ID
    var attachmentKey = ""

    // 本地存储图片的key
    var originKey = ""

    // 附件ID
    var size: CGSize = .zero

    weak var view: UIView?
}

final class MomentsKeyboardViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(MomentsKeyboardViewModel.self, category: "Module.Moments.MomentsKeyboardViewModel")

    weak var delegate: MomentsKeyboardViewModelDelegate?

    @ScopedInjectedLazy var resourceAPI: ResourceAPI?

    @ScopedInjectedLazy var sendImageProcessor: SendImageProcessor?

    @ScopedInjectedLazy var chatterApi: ChatterAPI?

    @ScopedInjectedLazy var anonymousConfigService: UserAnonymousConfigService?

    @ScopedInjectedLazy var circleConfigService: MomentsConfigAndSettingService?

    @ScopedInjectedLazy var fgService: FeatureGatingService?
    @ScopedInjectedLazy var settingService: SettingService?

    let attachmentUploader: AttachmentUploader

    var isAnonymous: Bool = false {
        didSet {
            onAnonymousStatusChangeBlock?(isAnonymous)
        }
    }
    /// 是否还有匿名的余额
    var hasQuota: Bool?
    var onAnonymousStatusChangeBlock: ((Bool) -> Void)?

    var refreshUIBlock: (() -> Void)?
    var refreshKeyBoardIdentitySwitcher: (() -> Void)?
    var selectedImage: MomentsKeyboardSeletedImage?

    private let disposeBag = DisposeBag()
    lazy var IsCompressCameraPhotoFG: Bool = {
        self.fgService?.staticFeatureGatingValue(with: "feature_key_camera_photo_compress") ?? false
    }()

    static func momentskeyboardDraftKey() -> String {
        return "moments_keyboard_draft"
    }

    var postEntity: RawData.PostEntity? {
        didSet {
            refreshKeyBoardIdentitySwitcher?()
        }
    }

    /// 图片压缩设置
    lazy var imageCompressConfig: MomentsImageCompressConfig = {
        return MomentsImageCompressConfig(settingService: settingService, defaultLength: 2000, defaultQuality: 0.8)
    }()

    init(userResolver: UserResolver,
         postEntity: RawData.PostEntity?,
         delegate: MomentsKeyboardViewModelDelegate,
         attachmentUploader: AttachmentUploader) {
        self.userResolver = userResolver
        self.delegate = delegate
        self.attachmentUploader = attachmentUploader
        self.setUploadFinish()
    }

    func keyboardItems(keyboard: MomentsKeyboard) -> [InputKeyboardItem] {
        return [
            MomentsKeyboardFactory.buildAt(keyboard),
            MomentsKeyboardFactory.buildEmotion(keyboard),
            MomentsKeyboardFactory.buildPicture(keyboard)
        ]
    }

    func photoPickerAssetType() -> PhotoPickerAssetType {
        return .imageOnly(maxCount: self.selectedImage != nil ? 0 : 1)
    }

    func upload(image: UIImage, imageData: Data?, useOriginal: Bool, extraInfo: [String: AnyHashable]? = nil) -> String? {
        var imageInfo: [String: String] = [
            "width": "\(Int32(image.size.width))",
            "height": "\(Int32(image.size.height))",
            "type": "post",
            "useOriginal": useOriginal ? "1" : "0"
        ]
        // 额外信息，为了不破坏原有结构，所以转jsonString放进去
        if let extra = extraInfo,
           let jsonData = try? JSONSerialization.data(withJSONObject: extra, options: .fragmentsAllowed) {
            let string = String(data: jsonData, encoding: .utf8)
            imageInfo["extraInfo"] = string
        }
        guard let data = imageData else {
            MomentsKeyboardViewModel.logger.info("image 无法转化为对应 data")
            return nil
        }

        let imageAttachment = self.attachmentUploader.attachemnt(data: data, type: .secureImage, info: imageInfo)
        MomentsKeyboardViewModel.logger.info("use custom upload imageAttachmentKey: \(imageAttachment.key)")
        self.attachmentUploader.customUpload(attachment: imageAttachment)
        self.delegate?.willStartUploadUserSelectedImage()
        return imageAttachment.key
    }

    private func setUploadFinish() {
        self.attachmentUploader.defaultCallback = { [weak self] (_, attachmentKey, token, data, error) in

            guard let `self` = self, let seletedAttachmentKey = self.selectedImage?.attachmentKey,
                  seletedAttachmentKey == attachmentKey else { return }

            if let imageData = data,
               let token = token,
               let image = try? ByteImage(imageData) {
                let originKey = self.resourceAPI?.computeResourceKey(key: token, isOrigin: true) ?? ""
                self.selectedImage?.token = token
                self.selectedImage?.originKey = originKey
                self.storeImageToCacheFromDraft(image: image, imageData: imageData, originKey: originKey)
                self.refreshUIBlock?()
                self.refreshUIBlock = nil
            }
            self.delegate?.uploadUserSelectedImageFinished(error: error)
        }
    }

    private func storeImageToCacheFromDraft(image: UIImage, imageData: Data, originKey: String) {
        if !LarkImageService.shared.isCached(resource: .default(key: originKey)) {
            LarkImageService.shared.cacheImage(image: image, data: imageData, resource: .default(key: originKey))
        }
    }

    func queryAnonymousQuotaFinish(_ finish: ((Bool) -> Void)?) {
        guard let postEntity = postEntity else {
            finish?(false)
            return
        }
        anonymousConfigService?.getAnonymousQuotaWithPostID(postID: postEntity.id) { [weak self] (hasQuota) in
            self?.hasQuota = hasQuota
            finish?(hasQuota)
        }
    }
}
