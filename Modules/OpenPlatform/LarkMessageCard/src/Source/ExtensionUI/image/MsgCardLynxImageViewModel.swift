//
//  MsgCardLynxImageViewModel.swift
//  LarkMessageCard
//
//  Created by bytedance on 2022/11/13.
//

import Foundation
import LarkSDKInterface
import LKCommonsLogging
import RxSwift
import LarkModel
import LarkContainer
import ByteWebImage
import RustPB
import LarkCore
import LarkUIKit
import LarkOPInterface
import LarkMessengerInterface
import LarkAccountInterface
import UniversalCardBase

public enum ImageShowMode: Int {
    case cropCenter = 0
    case stretch = 1
}

public final class MsgCardLynxImageViewModel {
    static let logger = Logger.oplog(MsgCardLynxImageViewModel.self, category: "MsgCardLynxImageViewModel")
    public var cardContext: MessageCardContainer.Context?
    public var imageId: String?
    public var images: [String : Basic_V1_RichTextElement.ImageProperty]?
    public var forcePreview: Bool = false
    public var preview: Bool = false
    public var imageToken: String?
    public var imageUrl: String?
    public var disableLongImageTag: Bool = false
    public var isLongImage: Bool = false
    public var imageShowMode: ImageShowMode = .cropCenter
    public var isTranslateElement: Bool = false
    public var previewImageKeys: [String]?
    @InjectedLazy private var messageAPI: MessageAPI
    //FIXME: 引入 LarkOpenplatform 较为复杂，先用 Optional
    @InjectedOptional private var openPlatformService: OpenPlatformService?
    private let stretchImageAspectRatioLimit = CGFloat(16) / 9
    private let disposeBag = DisposeBag()
    
    public init() {}
    
    public func calculateData(successBlock:(() -> Void)) {
        guard let imageId = self.imageId, let cardContext = cardContext else {
            Self.logger.info("MsgCardLynxImageViewModel: fetchMessage but imageId is nil")
            return
        }
        
        guard let images = MsgCardImageUtils.getAttachmentImages(cardContext: cardContext, openPlatformService: openPlatformService, isTranslateElement: isTranslateElement),
              let imageProperty = images[imageId] else {
            Self.logger.info("MsgCardLynxImageViewModel: attachment images not found")
            return
        }
        self.images = images
        if let url = imageProperty.urls.first {
            self.imageUrl = url + imageProperty.originKey
            Self.logger.info("MsgCardLynxImageViewModel: set image url")
        }
        
        self.imageToken = ImageItemSet.transform(imageProperty:imageProperty).generatePostMessageKey(forceOrigin: false)
        self.isLongImage = UniversalCardImageUtils.isLongImage(imageProperty: imageProperty, disableLongImageTag: disableLongImageTag, heightWidthRatioLimit: stretchImageAspectRatioLimit)
        successBlock()
    }

    public func cleanImageData() {
        self.imageId = nil
        self.cardContext = nil
        self.isLongImage = false
        self.images = nil
        self.imageToken = nil
        self.imageShowMode = .cropCenter
    }
}
