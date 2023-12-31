//
//  LarkInterface+Emotion.swift
//  LarkMessageCore
//
//  Created by huangjianming on 2019/8/11.
//

import Foundation
import EENavigator
import LarkModel
import RustPB

public struct EmotionShopListBody: CodablePlainBody {
    public static let pattern = "//client/shop_list"

    public init() {
    }
}

public struct EmotionShopDetailWithSetIDBody: CodablePlainBody {
    public static let pattern = "//client/stickerSet"
    public let stickerSetID: String

    enum CodingKeys: String, CodingKey {
        case stickerSetID = "id"
    }

    public init(stickerSetID: String) {
        self.stickerSetID = stickerSetID
    }
}

public struct EmotionShopDetailBody: PlainBody {
    public static let pattern = "//client/stickerSetDetail"
    public var stickerSet: RustPB.Im_V1_StickerSet

    public init(stickerSet: RustPB.Im_V1_StickerSet) {
        self.stickerSet = stickerSet
    }
}

public struct EmotionSettingBody: PlainBody {
    public static let pattern = "//client/emotion/setting"
    public var showType: ShowType
    public init(showType: ShowType) {
        self.showType = showType
    }

}

public struct EmotionSingleDetailBody: PlainBody {
    public static let pattern = "//client/emotion/stikerDetail"
    public var sticker: RustPB.Im_V1_Sticker
    public let stickerSet: RustPB.Im_V1_StickerSet?
    public var stickerSetID: String
    public var message: Message

    public init(sticker: RustPB.Im_V1_Sticker, stickerSet: RustPB.Im_V1_StickerSet?, stickerSetID: String, message: Message) {
        self.sticker = sticker
        self.stickerSet = stickerSet
        self.stickerSetID = stickerSetID
        self.message = message
    }
}

public enum ShowType {
    case present
    case push
}
public struct StickerManagerBody: PlainBody {
    public var showType: ShowType

    public static let pattern = "//client/stiker"
    public init(showType: ShowType) {
        self.showType = showType
    }
}
