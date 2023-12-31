//
//  UniversalCardLynxImageViewModel.swift
//  LarkMessageCard
//
//  Created by bytedance on 2022/11/13.
//

import Foundation
import LKCommonsLogging
import RxSwift
import LarkModel
import LarkContainer
import ByteWebImage
import RustPB
import LarkUIKit
import LarkAccountInterface
import UniversalCardInterface

public enum ImageShowMode: Int {
    case cropCenter = 0
    case stretch = 1
}

public final class UniversalCardLynxImageViewModel {
    static let logger = Logger.log(UniversalCardLynxImageViewModel.self, category: "UniversalCardLynxImageViewModel")
    public var cardContext: UniversalCardContext?
    public var imageId: String?
    public var imageProperty: RustPB.Basic_V1_RichTextElement.ImageProperty?
    public var forcePreview: Bool = false
    public var preview: Bool = false
    public var imageToken: String?
    public var imageUrl: String?
    public var disableLongImageTag: Bool = false
    public var isLongImage: Bool = false
    public var imageShowMode: ImageShowMode = .cropCenter
    public var isTranslateElement: Bool = false
    public var previewImageKeys: [String]?
    private let stretchImageAspectRatioLimit = CGFloat(16) / 9
    private let disposeBag = DisposeBag()
    
    public init() {}
    
    public func calculateData() {
        guard let images = isTranslateElement ?
                cardContext?.sourceData?.translateContent?.attachment.images :
                cardContext?.sourceData?.cardContent.attachment.images,
              let imageID = self.imageId, let imageProperty = images[imageID] else {
            Self.logger.error("UniversalCardLynxImageViewModel: require params is nil")
            return
        }
        self.imageProperty = imageProperty
        self.isLongImage = UniversalCardImageUtils.isLongImage(imageProperty: imageProperty, disableLongImageTag: disableLongImageTag, heightWidthRatioLimit: stretchImageAspectRatioLimit)
        if let url = imageProperty.urls.first { self.imageUrl = url + imageProperty.originKey}
        self.imageToken = ImageItemSet.transform(imageProperty:imageProperty).generatePostMessageKey(forceOrigin: false)
    }

    public func cleanImageData() {
        self.imageId = nil
        self.cardContext = nil
        self.isLongImage = false
        self.imageProperty = nil
        self.imageToken = nil
        self.imageShowMode = .cropCenter
    }
}
