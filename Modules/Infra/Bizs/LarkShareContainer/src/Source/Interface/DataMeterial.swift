//
//  DataMeterial.swift
//  LarkShareContainer
//
//  Created by shizhengyu on 2020/12/17.
//

import UIKit
import Foundation
import LarkSnsShare

// 二维码 或 链接 展示页各种状态下所需的物料
public enum TabContentMeterial {
    // 可能会预加载的信息（比如头像、名字和描述）
    case preload(CommonInfo)
    // 成功态的物料，展示二维码或链接
    case success(SuccessStatusMaterial)
    // 错误态的物料，展示加载失败 + 点击重试
    case error(ErrorStatusMaterial)
    // 不可用态的物料，展示不可用描述
    case disable(DisableStatusMaterial)
    // 不需要通过异步方式加载物料的占位类型，内部不做任何处理(viaChat目前是这种)
    case none
}

// 加载头像需要的资源
public enum IconResource {
    case key(String)
    case url(URL)
}

// 二维码 或 链接 展示页需要的通用信息(头像、名称、描述等)
public struct CommonInfo {
    public let name: String
    public let description: String?
    public let iconResource: IconResource
    public init(name: String, description: String? = nil, iconResource: IconResource) {
        self.name = name
        self.description = description
        self.iconResource = iconResource
    }
}

// 二维码 或 链接 展示页成功态下所需的物料
public enum SuccessStatusMaterial {
    public struct ViaLink {
        public let thirdShareBizId: String
        public let thirdShareTitle: String
        public let link: String
        public let content: String
        public let expiredTip: String?
        public let tip: String?
        public let copyCompletion: (() -> Void)?
        public let shareCompletion: ((_ result: ShareResult, _ itemType: LarkShareItemType) -> Void)?

        public init(
            thirdShareBizId: String,
            thirdShareTitle: String,
            link: String,
            content: String,
            expiredTip: String? = nil,
            tip: String? = nil,
            copyCompletion: (() -> Void)? = nil,
            shareCompletion: ((_ result: ShareResult, _ itemType: LarkShareItemType) -> Void)? = nil
        ) {
            self.thirdShareBizId = thirdShareBizId
            self.thirdShareTitle = thirdShareTitle
            self.link = link
            self.content = content
            self.expiredTip = expiredTip
            self.tip = tip
            self.copyCompletion = copyCompletion
            self.shareCompletion = shareCompletion
        }
    }

    public struct ViaQRCode {
        public let thirdShareBizId: String
        public let thirdShareTitle: String
        public let link: String
        public let expiredTip: String?
        public let tip: String?
        public let saveCompletion: ((_ isSuccess: Bool) -> Void)?
        public let shareCompletion: ((_ result: ShareResult, _ itemType: LarkShareItemType) -> Void)?

        public init(
            thirdShareBizId: String,
            thirdShareTitle: String,
            link: String,
            expiredTip: String? = nil,
            tip: String? = nil,
            saveCompletion: ((_ isSuccess: Bool) -> Void)? = nil,
            shareCompletion: ((_ result: ShareResult, _ itemType: LarkShareItemType) -> Void)? = nil
        ) {
            self.thirdShareBizId = thirdShareBizId
            self.thirdShareTitle = thirdShareTitle
            self.link = link
            self.expiredTip = expiredTip
            self.tip = tip
            self.saveCompletion = saveCompletion
            self.shareCompletion = shareCompletion
        }
    }

    case viaLink(ViaLink)
    case viaQRCode(ViaQRCode)
}

// 二维码 或 链接 展示页错误态下所需的物料
public struct ErrorStatusMaterial {
    // 为空使用默认提示文案
    // 链接tab下显示 `链接加载失败`
    // 二维码tab下显示 `二维码加载失败`
    public let errorTipMsg: String?
    // 为空使用默认错误态提示图
    public let errorTipImage: UIImage?

    public init(
        errorTipMsg: String? = nil,
        errorTipImage: UIImage? = nil
    ) {
        self.errorTipMsg = errorTipMsg
        self.errorTipImage = errorTipImage
    }

    public static func `default`() -> ErrorStatusMaterial {
        return ErrorStatusMaterial()
    }
}

// 二维码 或 链接 展示页不可用态下所需的物料
public struct DisableStatusMaterial {
    public let disableTipMsg: String
    // 为空使用默认不可用态提示图
    public let disableTipImage: UIImage?

    public init(
        disableTipMsg: String,
        disableTipImage: UIImage? = nil
    ) {
        self.disableTipMsg = disableTipMsg
        self.disableTipImage = disableTipImage
    }
}
