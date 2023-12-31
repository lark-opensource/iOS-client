//
//  LarkDependency.swift
//  ByteView
//
//  Created by kiri on 2023/6/27.
//

import Foundation
import RxSwift

/// 飞书平台，未细分业务线, 一般用于标记平台通用组件
public protocol LarkDependency {

    var window: WindowDependency { get }

    var emotion: EmotionDependency { get }

    var emojiData: EmojiDataDependency { get }

    var security: SecurityStateDependency { get }

    /// guide key 需要由 PM 申请
    func shouldShowGuide(key: String) -> Bool

    /// guide key 需要由 PM 申请
    func didShowGuide(key: String)

    /// 获取当前的水印视图
    func getWatermarkView(completion: @escaping ((UIView) -> Void))

    /// 获取 VC 共享屏幕及 magic share 区域的水印 view
    func getVCShareZoneWatermarkView() -> Observable<UIView?>
}

/// 外部依赖： 获取外部Window服务，需要通过swinject 注入依赖
public protocol WindowDependency {

    // 是否使用外部window，如果否，则下面都可以空实现
    var isExternalWindowEnabled: Bool { get }

    // 获取外部window的展示位置
    func getTargetOrigin(with size: CGSize) -> CGPoint

    // 获取外部window的展示区域
    func getTargetFrame() -> CGRect

    // 把VC移交给外部window
    func addViewController(with vc: UIViewController, size: CGSize)

    // 从外部window移除并获取移交的VC
    func removeViewController() -> UIViewController?

    // 替换外部window的VC
    func replaceViewController(with vc: UIViewController)

    /// attemptRotationToDeviceOrientation的替代，小窗的时候要调用一下，不然会出现小窗后手机横屏小窗抖动的行为
    func updateSupportedInterfaceOrientations()
}

public enum EmotionLayoutType {
    case leftAlignedFlowLayout
    case recentReactionsFloatLayout
}

/// 聊天表情
public protocol EmotionDependency {
    var reactions: [String] { get }
    func imageByKey(_ key: String) -> UIImage?
    func imageKey(by reactionKey: String) -> String?
    func emotionKeyBy(i18n: String) -> String?
    func skinKeysBy(_ key: String) -> [String]
    func sizeBy(_ key: String) -> CGSize?
    func isDeletedBy(key: String) -> Bool
    func getIllegaDisplayText() -> String
    func createLayout(_ layoutType: EmotionLayoutType) -> UICollectionViewFlowLayout
}

/// 对外依赖，获取主端安全页面状态
public protocol SecurityStateDependency {
    func didSecurityViewAppear() -> Bool
    // 截屏录屏保护（共享屏幕场景豁免保护）
    func vcScreenCastChange(_ vcCast: Bool)
    /// 复制管控
    func setPasteboardText(_ message: String, token: String, shouldImmunity: Bool) -> Bool
    /// 粘贴管控
    func getPasteboardText(token: String) -> String?
}
