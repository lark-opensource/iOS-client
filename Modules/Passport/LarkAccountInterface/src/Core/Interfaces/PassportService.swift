//
//  PassportService.swift
//  LarkAccountInterface
//
//  Created by Nix Wang on 2022/6/28.
//

import Foundation
import RxSwift

public enum PassportUserAction: String {
    case initialized    // 初始化
    case fastLogin      // 自动登录
    case login          // 登录
    case logout         // 登出
    case `switch`       // 切换用户
    case settingsMultiUserUpdating
}

public enum PassportLoginState: String {
    case online
    case offline
}

public struct PassportState: CustomStringConvertible {
    public let user: User?                  // 当前用户，初始化时、未登录时为 nil
    public let loginState: PassportLoginState
    public let action: PassportUserAction   // 表示状态变化的原因

    public init(user: User?, loginState: PassportLoginState, action: PassportUserAction) {
        self.user = user
        self.loginState = loginState
        self.action = action
    }

    public var description: String {
        return "state: [\(loginState.rawValue)] uid: \(user?.userID ?? "nil") action: [\(action.rawValue)]"
    }
}

public struct MultiUserActivityState: CustomStringConvertible {

    public let action: LarkAccountInterface.PassportUserAction
    public let toForegroundUserID: String?
    /// 计算时需要被移除的用户，目前在登出场景会使用
    public let droppedUserIDs: [String]?

    public init(action: PassportUserAction, toForegroundUserID: String?, droppedUserIDs: [String]? = nil) {
        self.action = action
        self.toForegroundUserID = toForegroundUserID
        self.droppedUserIDs = droppedUserIDs
    }

    public var description: String {
        return "State - action: \(action.rawValue), foreground uid: \(toForegroundUserID ?? "nil"), dropped uid: \(droppedUserIDs ?? [])"
    }
}

/// 与用户无关/多用户相关的接口，在全局容器中提供
public protocol PassportService: AnyObject {

    // MARK: - 用户相关
    /*
     状态变化时序：

     login:
     (nil, offline) -> (A, online)

     fastLogin:
     (nil, offline) -> (A, online)

     switch:
     正常切换：(A, online) -> (A, offline) -> (B, online)
     前台 session 失效并验证：(A, online) -> (A, offline) -> (A, online)
     切换所有用户失败：(A, online) -> (A, offline) -> (nil, offline)

     logout:
     (A, online) -> (A, offline) -> (nil, offline)
     */
    var state: Observable<PassportState> { get }

    /// **业务方不应当直接调用此接口，请从 PassportUserService.user 获取当前用户信息**
    var foregroundUser: User? { get }
    
    var userList: [User] { get }

    var activeUserList: [User] { get }

    /// 用于侧边栏展示和订阅更新的 userList
    /// 依照`前台 User`、`session 有效 User`、`session 失效 User`排序
    var menuUserListObservable: Observable<[User]> { get }

    /// 等同于 userList map tenant
    var tenantList: [Tenant] { get }

    func getUser(_ userID: String) -> User?

    /// 仅用于Chatter Manager 同步数据
    func updateUserInfo(
        userId: String,
        name: String,
        avatarKey: String,
        enUsName: String,
        avatarUrl: String
    )

    /// 当前前台租户品牌名，无论是 SaaS 版本（走正常 App Store 发布）还是 KA（私有化部署），值总会是 feishu/lark 中的一个
    /// 当没有前台租户时，根据 app 包版本决定
    var tenantBrand: TenantBrand { get }

    /// 当前前台租户是否为飞书品牌，语义上等同于国内租户；反之为 lark，国外租户
    /// 当没有前台租户时，根据 app 包版本决定，即 feishu app 为 true
    var isFeishuBrand: Bool { get }

    /// 新状态灰度开关
    var enableUserScope: Bool { get }
    
    // MARK: - 登录 & 登出

    /// 注册中断登出的操作
    ///
    /// - Parameter observable: 中断操作
    func register(interruptOperation observable: InterruptOperation)

    /// 注入 pattern 和 regParams 定制登录注册流程
    /// inject pattern or regParams to login, custom login register procedure
    /// docs: https://bytedance.feishu.cn/wiki/wikcnD3MKkDKnz9SA5UbiKwKWnh
    /// - Parameters:
    ///   - pattern: pattern 决定登录注册流程
    ///              pattern which will change login procedure, `Set It Carefully`
    ///   - regParams: 透传参数用于数据统计
    ///              additional params for register -> https://bytedance.feishu.cn/docs/doccnoeng7HRFt2Ue6MU8Jo7Erh#5iFNyg
    func injectLogin(pattern: String?, regParams: [String: Any]?)

    /// 登出
    ///
    /// 当登出前台用户 && 还有其他用户时，会自动切换到下一个租户，切换完成时会调用 onSwitch
    ///
    /// - Parameters:
    ///   - conf: 登出配置
    ///   - onError: 登出失败
    ///   - onSuccess: 登出成功，当 willSwitchUser 为 true 时，表示将会自动切换租户并在切换结束后调用 onSwitch，否则不会调用 onSwitch
    ///   - onInterrupt: 登出被阻断
    ///   - onSwitch：自动切换用户结束
    func logout(
        conf: LogoutConf,
        onInterrupt: @escaping () -> Void,
        onError: @escaping (_ message: String) -> Void,
        onSuccess: @escaping (_ willSwitchUser: Bool, _ message: String?) -> Void,
        onSwitch: ((_ success: Bool) -> Void)?
    )

    // MARK: - 账号管理

    /// 新版账号安全中心
    func openAccountSecurityCenter(from: UIViewController)
    
    /// 账号安全中心入口文案
    func accountSecurityCenterEntryTitle() -> String

    /// 加入团队
    /// - Parameters:
    ///   - nav: navigation used for state machine
    ///   - trackPath: track different start path
    func pushToTeamConversion(fromNavigation nav: UINavigationController,
                              trackPath: String?)


    // MARK: - 切换租户

    /// 切换账户
    ///
    /// - Parameter userId: 切换至用户id
    func switchTo(userID: String)

    func switchTo(userID: String, complete: ((Bool) -> Void)?)

    // passport 原生切换租户页面
    func pushToSwitchUserViewController(from: UIViewController)


    // MARK: - Session Service

    /// 主动调用session invalid检查，并切换到下一个有效租户
    func checkSessionInvalid()

    // MARK: - 财经

    // 调用财经 web 容器打开 财经相关 url
    func openCJURL(_ url: String)

    
    // MARK: - 国家代码

    /// mobile code top country code list
    func getTopCountryList() -> [String]

    /// mobile code black country code list
    func getBlackCountryList() -> [String]

    /// 获取通过手机号添加企业成员的黑白名单
    /// 当白名单不为空时以白名单为准
    func getPhoneNumberRegionList(_ completion: @escaping (_ allowList: [String]?, _ blockList: [String]?, _ error: Error?) -> Void) -> Void


    // MARK: - 导出本地日志

    /// 订阅状态栏点击 5 下行为
    /// 在获取本地日志路径后弹出 UIActivityViewController，分享日志压缩文件
    /// 建议在viewWillAppear中调用
    func subscribeStatusBarInteraction()
    
    /// 取消订阅状态栏点击5下行为
    /// 建议在viewWillDisappear中调用
    func unsubscribeStatusBarInteraction()

    func fetchClientLog(completion: @escaping (ClientLogShareViewController?) -> Void)


    // MARK: - UI 相关
    func launchGuideLogin(context: LauncherContext) -> Observable<Void>

    func createLoginNavigation(rootViewController: UIViewController) -> UINavigationController

    func quitTeamH5Url() -> URL?

    func teamConversionEntryTitle() -> String


    // MARK: - 设备相关
    var deviceID: String { get }
    
    func getLegacyDeviceId() -> String?
    
    func getLegacyDeviceIdBy(unit: String) -> String?
}

public protocol MultiUserActivityCoordinatable: AnyObject {

    /// `预期`的跨租户在线的用户列表
    /// - `预期`是指，它基于产品规则和当前完整用户列表的计算结果，但不一定和容器/ sdk 实际 online 列表一致
    /// - 考虑到用户信息可能会更新（比如头像），这里只提供 ID List
    /// - 需要用户完整数据结构，可以使用 PassportService getUser(userID:)
    /// - 它会在容器处理之前就完成更新，无本地持久化，每次启动根据 fast login 和设置开关值做最新的计算
    var activityUserIDList: [String] { get }

    /// 设置页跨租户消息通知开关
    var settingsEnableMultiUserActivity: Bool { get }

    /// 由设置页功能开关变化影响的跨租户用户列表变更
    /// - enable: 设置页即将使用的新值
    /// - completion: 当 activity user list 完成计算时就会调用，`不会`等待容器处理结果
    func settingsWillUpdate(_ enable: Bool, completion: @escaping (Bool) -> Void)

    /// 由 Passport 相关事件影响的跨租户用户列表变更
    /// - state: 需要关注的参数，例如新前台身份
    /// - completion: 当容器完成前台用户相关操作后调用
    func stateWillUpdate(_ state: MultiUserActivityState, completion: @escaping (Result<Void, Error>) -> Void)

}
public class MultiUserActivitySwitch {
    public static let enableMultipleUserKey = "enableMultipleUserFG"
    /// TODO: 从硬盘中读取启动值
    /// 流程相关的用这个值, 重启生效，app生命周期不会变，保证流程稳定性
    public static let enableMultipleUser = UserDefaults.standard.bool(forKey: enableMultipleUserKey)
    /// UI开关用这个值. 可以被动态改变.
    /// 变化时会发出enableMultipleUserRealtimeChanged通知（如果要保证线程，比如主线程，需要自己async）。
    /// 当由true变为false后，UI不应该再展示，后台用户应该被下线(passport发出userList变化事件)
    /// NOTE: 为了简化变化实现复杂度，该值只会从true变为false，不会从false变为true，可以根据这一假定简化对应的复杂度
    public static var enableMultipleUserRealtime = enableMultipleUser
    /// 开关值变化时，会发出这个通知.
    public static let enableMultipleUserRealtimeChanged = Notification.Name("enableMultipleUserRealtimeChanged")
}
