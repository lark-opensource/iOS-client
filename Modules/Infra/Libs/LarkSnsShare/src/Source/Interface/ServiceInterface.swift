//
//  ServiceInterface.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/3/19.
//

import UIKit
import Foundation
import LarkContainer
import EENavigator

// MARK: 最基础的分享能力接口

public protocol SnsShareDelegate: AnyObject {
    func wechatWrapperCallback(wrapper: LarkShareBaseService, error: Error?, customCallbackUserInfo: [AnyHashable: Any]?)
    func qqWrapperCallback(wrapper: LarkShareBaseService, error: Error?, customCallbackUserInfo: [AnyHashable: Any]?)
    func weiboWrapperCallback(wrapper: LarkShareBaseService, error: Error?, customCallbackUserInfo: [AnyHashable: Any]?)
}

public protocol SnsConfiguration {
    var snsAppIDMapping: [SnsType: String] { get }
    var universalLink: String { get }
}

public protocol LarkShareBaseService {
    var snsConfiguration: SnsConfiguration { get set }
    var delegate: SnsShareDelegate? { get set }
    func isAvaliable(snsType: SnsType) -> Bool
    func wakeup(snsType: SnsType) -> SnsWakeUpResult
    // 校验分享SDK后台权限
    func checkShareSDKAuthority(snsType: SnsType) -> Bool
    // 获取分享SDK拦截弹窗文案
    func getShareSdkDenyTipText(snsType: SnsType) -> String
    // 纯文本分享
    func sendText(navigatable: Navigatable,
                  snsType: SnsType,
                  snsScenes: SnsScenes?,
                  text: String,
                  customCallbackUserInfo: [AnyHashable: Any])
    // 图片分享
    func sendImage(navigatable: Navigatable,
                   snsType: SnsType,
                   snsScenes: SnsScenes?,
                   image: UIImage,
                   title: String?,
                   description: String?,
                   customCallbackUserInfo: [AnyHashable: Any])
    // web链接分享
    func sendWebPageURL(navigatable: Navigatable,
                        snsType: SnsType,
                        snsScenes: SnsScenes?,
                        webpageURL: String,
                        thumbnailImage: UIImage,
                        imageURL: String?,
                        title: String,
                        description: String,
                        customCallbackUserInfo: [AnyHashable: Any])
    // 系统面板分享
    func presentSystemShareController(
        navigatable: Navigatable,
        activityItems: [Any],
        presentFrom: UIViewController?,
        popoverMaterial: PopoverMaterial?,
        completionHandler: UIActivityViewController.CompletionWithItemsHandler?
    )
    // 懒注册分享sdk
    func registerSnsSDKIfNeeded(snsType: SnsType)
    // 执行OpenURL Application生命周期相关处理
    @discardableResult
    func handleOpenURL(_ url: URL) -> Bool
    // 执行ContinueUserActivity生命周期相关处理
    @discardableResult
    func handleOpenUniversalLink(_ userActivity: NSUserActivity) -> Bool
}

// MARK: 分享能力上层分装协议
public typealias LarkShareCallback = (ShareResult, LarkShareItemType) -> Void
public protocol LarkShareService {
    /// 根据动态配置分享(推荐，须引入 `ExpansionAbility` Subspec)，支持注入兜底分享项
    /// https://bytedance.feishu.cn/docs/doccngbnlPSCV7NQ7CuXLy19RJn#
    /// - Parameters:
    ///     - traceId: 场景分享行为的 id，目前配置在 appSettings 上
    ///     - contentContext: 分享内容
    ///     - baseViewController: 基于哪个vc弹出
    ///     - downgradeTipPanelMaterial: 封禁降级的操作提示弹窗物料
    ///     - customShareContextMapping: 自定义面板 item 的物料映射
    ///     - defaultItemTypes: 默认面板 item
    ///     - popoverMaterial: 在 ipad 上指定为 popover 视图的物料，不传则表现为 fullScreen
    ///     - shareCallback: 分享回调，包含分享结果和用户真正选择的 item 类型
    func present(
        by traceId: String,
        contentContext: ShareContentContext,
        baseViewController: UIViewController,
        downgradeTipPanelMaterial: DowngradeTipPanelMaterial?,
        customShareContextMapping: [String: CustomShareContext]?,
        defaultItemTypes: [LarkShareItemType],
        popoverMaterial: PopoverMaterial?,
        shareCallback: LarkShareCallback?
    )

    /// 根据静态配置分享
    /// - Parameters:
    ///     - staticItemTypes: 静态的面板 item
    ///     - contentContext: 分享内容
    ///     - baseViewController: 基于哪个vc弹出
    ///     - popoverMaterial: 在 ipad 上指定为 popover 视图的物料，不传则表现为 fullScreen
    ///     - needDowngrade: check 某个 item 是否需要进行降级处理
    ///     - downgradeInterceptor: 针对某个 item 的具体降级处理
    ///     - shareCallback: 分享回调，包含分享结果和用户真正选择的 item 类型
    func present(
        with staticItemTypes: [LarkShareItemType],
        contentContext: ShareContentContext,
        baseViewController: UIViewController,
        popoverMaterial: PopoverMaterial?,
        needDowngrade: ((_ itemType: LarkShareItemType) -> Bool)?,
        downgradeInterceptor: ((_ itemType: LarkShareItemType) -> Void)?,
        shareCallback: LarkShareCallback?
    )
    
    //新增安全剪贴板支持豁免方法
    func present(
        by traceId: String,
        contentContext: ShareContentContext,
        baseViewController: UIViewController,
        downgradeTipPanelMaterial: DowngradeTipPanelMaterial?,
        customShareContextMapping: [String: CustomShareContext]?,
        defaultItemTypes: [LarkShareItemType],
        popoverMaterial: PopoverMaterial?,
        pasteConfig: SnsPasteConfig?,
        shareCallback: LarkShareCallback?
    )

    func present(
        with staticItemTypes: [LarkShareItemType],
        contentContext: ShareContentContext,
        baseViewController: UIViewController,
        popoverMaterial: PopoverMaterial?,
        needDowngrade: ((_ itemType: LarkShareItemType) -> Bool)?,
        downgradeInterceptor: ((_ itemType: LarkShareItemType) -> Void)?,
        pasteConfig: SnsPasteConfig?,
        shareCallback: LarkShareCallback?
    )

    /// 注入动态分享配置的提供者
    /// 默认使用内置的 `ShareDynamicConfigurationParser` 来获取和解析
    /// 调用后会通过外部注入的 provider 来完成获取和解析工作
    func registerProvider(_ provider: ShareConfigurationProvider)
}

// 分享组件剪贴板配置
public enum SnsPasteConfig: String {
    //使用飞书剪贴板，不豁免外部粘贴
    case scPaste
    //使用飞书剪贴板，豁免外部粘贴
    case scPasteImmunity
}
