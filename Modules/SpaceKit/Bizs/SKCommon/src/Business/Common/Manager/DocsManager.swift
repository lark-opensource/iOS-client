//
//  DocsManager.swift
//  Docs
//
//  Created by weidong fu on 4/2/2018.
//

import Foundation
import Kingfisher
import SQLite
import LarkRustClient
import LarkRustHTTP
import RxSwift
import os
import SKFoundation
import SpaceInterface
import SKInfra

public enum LarkOpenEvent {
    /// 插入历史记录
    case record(_ id: String, url: URL, title: String, iconImageSource: UIImage, vc: UIViewController, needAutoScreenShot: Bool, info: [String: Any]?)
    /// 路由跳转
    case openURL(_ url: URL, _ controller: UIViewController)
    /// 分享图片至会话
    case shareImage(_ image: UIImage, controller: UIViewController)
    /// 分享debug文件到会话
    case sendDebugFile(path: String, fileName: String, vc: UIViewController)
    /// 识别二维码
    case scanQR(_ code: String, _ controller: UIViewController)
    case routeChat(chatID: String)
    /// 加上vc是为了在VC Follow下点击doc中的客服能显示在正确的层级，不然客服界面会被VC盖住
    case customerService(controller: UIViewController?)
    case none
}

/// 由Lark提供的能力
/// 目前传递路径Lark<-DocsManager<-EditorManager<-BrowserView<-[Service]
public protocol LarkOpenAgent: AnyObject {
    func sendLarkOpenEvent(_ event: LarkOpenEvent)
}

/// Feed 置顶
public protocol DocsManagerFeedDelegate: AnyObject {
    func markFeedCardShortcut(for feedId: String,
                              isAdd: Bool,
                              success: SKMarkFeedSuccess?,
                              failure: SKMarkFeedFailure?)
    func isFeedCardShortcut(feedId: String) -> Bool
}

extension DocsManagerFeedDelegate {
    func markFeedCardShortcut(for feedId: String,
                              isAdd: Bool,
                              success: SKMarkFeedSuccess?,
                              failure: SKMarkFeedFailure?) { }
    func isFeedCardShortcut(feedId: String) -> Bool { return false }
}

public protocol DocsManagerDelegate: AnnouncementDelegate, NetworkAuthDelegate, LarkOpenAgent, DocsManagerFeedDelegate {
    var basicUserInfo: BasicUserInfo? { get }
    var userDomain: String { get }
    var docsDomains: DocsConfig.Domains { get }
    var envInfo: DomainConfig.EnvInfo { get }
    var rustService: RustService { get }
    var globalWatermarkIsOn: Bool { get }
    var animationLoading: DocsLoadingViewProtocol? { get }
    var serviceTermURL: String { get }
    var privacyURL: String { get }
    func requiredNewBearSession(completion: @escaping(_ session: String?, _ error: Error?) -> Void)
    func docRequiredToHandleOpen(_ url: String, in browser: BaseViewController)

    func requestShareAccessory(in browser: BaseViewController) -> UIView?
    func requestShareAccessory(with feedId: String) -> UIView?

    func docRequiredToShowUserProfile(_ userId: String, fileName: String?, from controller: UIViewController, params: [String: Any])

    func sendReadMessageIDs(_ params: [String: Any], in browser: BaseViewController?, callback: @escaping ((Error?) -> Void))

    func docRequiredToShowEnterpriseTopic(query: String,
                                          addrId: String,
                                          triggerView: UIView,
                                          triggerPoint: CGPoint,
                                          clientArgs: String,
                                          clickHandle: EnterpriseTopicClickHandle?,
                                          tapApplinkHandle: EnterpriseTopicTapApplinkHandle?,
                                          targetVC: UIViewController)

    func docPequiredToDismissEnterpriseTopic()

    func fetchLarkFeatureGating(with key: String, isStatic: Bool, defaultValue: Bool) -> Bool?
    func getABTestValue(with key: String, shouldExposure: Bool) -> Any?

    func checkVCIsRunning() -> Bool

    func openLKWebController(url: URL, from: UIViewController?)
    func launchCustomerService()
    func generatePasswordFreeLink(urlString: String, completion: @escaping (String) -> Void)
    func getOPContextInfo(with params: [AnyHashable: Any]) -> DocsOPAPIContextProtocol?
    func checkIsSearchMainContainerViewController(responder: UIResponder) -> Bool
    func createGroupGuideBottomView(docToken: String, docType: String, templateId: String, chatId: String, fromVC: UIViewController?) -> UIView
}
