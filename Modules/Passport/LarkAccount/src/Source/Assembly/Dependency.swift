//
//  Dependency.swift
//  LarkAccount
//
//  Created by quyiming on 2020/9/23.
//

import Foundation
import RxSwift
import RxCocoa
import LarkEnv
import LarkUIKit
import LarkAccountInterface

// swiftlint:disable missing_docs
public protocol NotificationStatusDependency {
    var notifyDisableDriver: Driver<Bool> { get }
    func updateNotificaitonStatus(notifyDisable: Bool, retry: Int)
}

public protocol PassportDependency: NotificationStatusDependency {
    func openURL(_ url: URL, from: UIViewController)
    func createWebViewController(_ url: URL, customUserAgent: String?) -> UIViewController
    func createFailView() -> UIView
    func getOpenPlatformDeviceId() -> String
    func value(forKey key: String, defaultValue: String) -> String
    func setValue(value: String, forKey key: String)
    func removeValue(key: String)
    func openDynamicURL(_ url: URL, from: UIViewController)
    func openDynamicURL(_ url: URL, from: UIViewController,isPresent: Bool, prepare: ((UIViewController) -> Void)?)
    // 调用财经 web 容器打开 财经相关 url
    func openCJURL(_ url: String, from: UIViewController)
    func successUpgradeTeam<T: UIViewController>(
        path: String?,
        lastVCType: T.Type?,
        from: UIViewController?
    )

    /// 无源人脸认证
    func doFaceLiveness(
        appId: String,
        ticket: String,
        scene: String,
        mode: String,
        callback: @escaping (_ data: [AnyHashable: Any]?, _ error: Error?) -> Void
    )

    /// 有源人脸认证
    func doFaceLiveness(
        appId: String,
        ticket: String,
        scene: String,
        identityName: String,
        identityCode: String,
        presentToShow: Bool,    // 默认传 false，为了防止出现两个返回按钮，可以传 true
        callback: @escaping (_ data: [AnyHashable: Any]?, _ error: Error?) -> Void
    )
    func toJoinMeetingController(from: UIViewController)

    func updateAppLanguage(model: LanguageModel, from: UIViewController)

    /// 当前精简模式状态 后续需要剥离
    var leanModeStatus: Observable<Bool> { get }

    var deviceInLeanMode: Bool { get }

    func clearCookie()

    func setupCookie(user: User) -> Bool

    func openProfile(_ userID: String, hostViewController: UIViewController)

    // MARK: - 跨租户消息通知
    func userListChange(userList: [User], foregroundUser: User?, action: PassportUserAction, delegate: LarkContainerManagerFlowProgressDelegate)
}
// swiftlint:enable missing_docs
