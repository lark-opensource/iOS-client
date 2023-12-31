//
//  DriveSDK+Action.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2020/6/17.
//

import UIKit
import RxSwift

public struct DriveSDKStopReason {
    public var image: UIImage?
    public var reason: String

    public init(reason: String, image: UIImage?) {
        self.reason = reason
        self.image = image
    }
}

/// DriveSDK暴露给业务方的UI动作，业务方可以通过向DriveSDK发送Action自定义自己的UI动作
/// 比如 showBanner， 可以展示业务方自定义的banner逻辑，业务可以自己处理banner相关交互
public enum DriveSDKUIAction {
    /// 在预览界面展示一个banner
    ///  参数
    ///  banner: UIView  业务自定义的banner样式，业务自己响应banner交互逻辑，DriveSDK负责把banner视图展示在预览界面
    ///  bannerID:  用于唯一表示banner，如果存在多个banner，通过bannerID 处理对应的banner， 只需要在一次预览过程中唯一即可
    case showBanner(banner: UIView, bannerID: String)
    ///  关闭banner
    ///  参数
    ///  bannerID: 如果业务展示了多个banner，可以通过bannerID唯一表示关闭哪一个banner
    case hideBanner(bannerID: String)
}

public protocol DriveSDKActionDependency {
    typealias Reason = DriveSDKStopReason
    typealias Action = DriveSDKUIAction
    /// 退出预览界面
    var closePreviewSignal: Observable<Void> { get }
    /// 停止预览， 并展示提示界面
    /// 参数
    /// Reason: 描述停止预览后展示的兜底界面信息，包括图片和文案字段
    var stopPreviewSignal: Observable<Reason> { get }
    /// 业务UI动作，比如展示或隐藏banner
    /// 参数
    /// DriveSDKUIAction: 具体的UI Action，比如展示banner
    var uiActionSignal: Observable<DriveSDKUIAction> { get }
}

public extension DriveSDKActionDependency {
    var uiActionSignal: Observable<DriveSDKUIAction> {
        return .never()
    }
}
