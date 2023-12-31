//
//  AccountServiceCore.swift
//  LarkAccountInterface
//
//  Created by au on 2021/5/23.
//

import UIKit
import RxSwift
import SnapKit
#if LarkAccountInterface_CHATTER
import LarkModel
#endif

/// Core Account Service
public protocol AccountServiceCore: AnyObject { // user:checked

    // MARK: - 5.2 新帐号模型新增接口

    /// 当前前台用户
    @available(*, deprecated, message: "Use `PassportUserService.user` instead.")
    var foregroundUser: User? { get }

    @available(*, deprecated, message: "Use `PassportUserService.user` instead.")
    var foregroundUserObservable: Observable<User?> { get }

    @available(*, deprecated, message: "Use `PassportService.userList` instead.")
    var userList: [User] { get }

    @available(*, deprecated, message: "Use `PassportService.activeUserList` instead.")
    var activeUserList: [User] { get }

    /// 用于侧边栏展示和订阅更新的 userList
    /// 依照`前台 User`、`session 有效 User`、`session 失效 User`排序
    @available(*, deprecated, message: "Use `PassportService.menuUserListObservable` instead.")
    var menuUserListObservable: Observable<[User]> { get }

    /// 等同于 foregroundUser.tenant
    @available(*, deprecated, message: "Use `PassportUserService.userTenant` instead.")
    var foregroundTenant: Tenant? { get }
    
    /// Domain 和 SessionKey 的映射, 用于 Cookie 组装
    @available(*, deprecated, message: "Use `PassportService.sessionKeyWithDomains` instead.")
    var sessionKeyWithDomains: [String: [String : String]]? { get }

    /// 等同于 userList map tenant
    @available(*, deprecated, message: "Use `PassportService.tenantList` instead.")
    var tenantList: [Tenant] { get }

    // MARK: - 5.7 MultiGeo 新增接口

    /// 当前前台租户品牌名，无论是 SaaS 版本（走正常 App Store 发布）还是 KA（私有化部署），值总会是 feishu/lark 中的任一一个
    /// 当没有前台租户时，根据 app 包版本决定
    @available(*, deprecated, message: "Use `PassportService.tenantBrand` instead.")///
    var foregroundTenantBrand: TenantBrand { get }

    /// 当前前台租户是否为飞书品牌，语义上等同于国内租户；反之为 lark，国外租户
    /// 当没有前台租户时，根据 app 包版本决定，即 feishu app 为 true
    @available(*, deprecated, message: "Use `PassportService.isFeishuBrand` instead.")
    var isFeishuBrand: Bool { get }

    /// 当前前台用户 unit 归属，当没有前台用户时，根据 app 包版本决定
    @available(*, deprecated, message: "Use `PassportUserService.userUnit` instead.")
    var foregroundUserUnit: String { get }

    /// 当前前台用户 geo 归属，当没有前台用户时，根据 app 包版本决定
    @available(*, deprecated, message: "Use `PassportUserService.userGeo` instead.")
    var foregroundUserGeo: String { get }

    /// 当前前台用户 geo (地理归属地) 是否为中国大陆地区，语义上等于国内用户
    @available(*, deprecated, message: "Use `PassportUserService.isChinaMainlandGeo` instead.")
    var isChinaMainlandGeo: Bool { get }

    // MARK: - 无 BootManager 集成
    /// 初始化模块 不使用 BootManager 集成时需要调用该方法初始化模块
    @available(*, deprecated, message: "Use `PassportService.setup` instead.")
    func setup()

    /// 登录后主视图显示时收尾工作  不使用 BootManager 集成时进入主界面需要调用该方法做收尾工作
    @available(*, deprecated, message: "Use `PassportService.mainViewLoaded` instead.")
    func mainViewLoaded()

    // MARK: 登录

    @available(*, deprecated, message: "Use `PassportService.logout` instead.")
    func relogin(
        conf: LogoutConf,
        onError: @escaping (_ message: String) -> Void,
        onSuccess: @escaping () -> Void,
        onInterrupt: @escaping () -> Void
    )

    /// 注册中断登出的操作
    ///
    /// - Parameter observable: 中断操作
    @available(*, deprecated, message: "Use `PassportService.register` instead.")
    func register(interruptOperation observable: InterruptOperation)

    // MARK: 登录注册流程定制

    /// 注入 pattern 和 regParams 定制登录注册流程
    /// inject pattern or regParams to login, custom login register procedure
    /// docs: https://bytedance.feishu.cn/wiki/wikcnD3MKkDKnz9SA5UbiKwKWnh
    /// - Parameters:
    ///   - pattern: pattern 决定登录注册流程
    ///              pattern which whill change login procedure, `Set It Carefully`
    ///   - regParams: 透传参数用于数据统计
    ///              addtional params for register -> https://bytedance.feishu.cn/docs/doccnoeng7HRFt2Ue6MU8Jo7Erh#5iFNyg
    @available(*, deprecated, message: "Use `PassportService.injectLogin` instead.")
    func injectLogin(pattern: String?, regParams: [String: Any]?)

    // MARK: 用户信息

    /// 当前用户信息
    @available(*, deprecated, message: "Use `PassportUserService.user` instead.")
    var currentAccountInfo: Account { get }

    /// 当前用户是否为空
    @available(*, deprecated, message: "Use `PassportUserService.user` instead.")
    var currentAccountIsEmpty: Bool { get }

    /// 当前用户变更的信号，例如：头像变化时会触发
    @available(*, deprecated, message: "Use `PassportUserService.user` instead.")
    var currentAccountObservable: Observable<Account> { get }

    /// user type 变化的信号
    @available(*, deprecated, message: "Use `PassportUserService.user` instead.")
    var currentUserTypeObservable: Observable<AccountUserType> { get }

    /// 用户切换账户的信号，例如：A->B，退出登录的时候会触发
    @available(*, deprecated, message: "Use `PassportUserService.user` instead.")
    var accountChangedObservable: Observable<Account?> { get }

    /// 全部的账户信息
    @available(*, deprecated, message: "Use `userList` instead.")
    var accounts: [Account] { get }

    /// 多租户信息变化的信号
    @available(*, deprecated, message: "Use `userListObservable` instead.")
    var accountsObservable: Observable<[Account]> { get }

    /// 待审批用户
//    @available(*, deprecated, message: "No longer available.")
//    var pendingUsers: [PendingUser] { get }
    /// 待审批用户变化信号
//    @available(*, deprecated, message: "No longer available.")
//    var pendingUsersObservable: Observable<[PendingUser]> { get }

    /// 用户列表变化信号
    @available(*, deprecated, message: "Use `PassportService.userListObservable` instead.")
    var userListObservable: Observable<AccountUserList> { get }

    #if LarkAccountInterface_CHATTER
    // Passport即将剥离chatter，请不要使用此API
    @available(*, deprecated, message: "Please use ChatterManager.currentChatter")
    var currentChatter: Chatter { get }
    #endif

    // MARK: 账号管理

    /// 账号与安全
//    @available(*, deprecated, message: "Use `PassportService.accountSafety` instead.")
//    func accountSafety() -> UIViewController
    /// 新版账号安全中心
    @available(*, deprecated, message: "Use `PassportService.openAccountSecurityCenter` instead.")
    func openAccountSecurityCenter(from: UIViewController)
    /// 账号安全中心入口文案
    @available(*, deprecated, message: "Use `PassportService.accountSecurityCenterEntryTitle` instead.")
    func accountSecurityCenterEntryTitle() -> String

    // MARK: - 切换租户
    /// 切换账户
    ///
    /// - Parameter userId: 切换至用户id
    @available(*, deprecated, message: "Use `PassportService.switchTo` instead.")
    func switchTo(userID: String)

    @available(*, deprecated, message: "Use `PassportService.switchTo` instead.")
    func switchTo(userID: String, complete: ((Bool) -> Void)?)

    /// 自动寻找下一个租户进行切换，如果失败需要返回登录页
    @available(*, deprecated, message: "Will be removed soon")
    func autoSwitch(complete: ((Bool) -> Void)?)

    /// 注销用户, 默认是前台用户
    @available(*, deprecated, message: "Use `PassportUserService.unregisterUser` instead.")
    func unRegisterUser(complete: ((Bool) -> Void)?)

    // MARK: 加入团队
    /// go to team conversion process
    /// - Parameters:
    ///   - nav: navigation used for state machine
    ///   - trackPath: track different start path
    @available(*, deprecated, message: "Use `PassportService.pushToTeamConversion` instead.")
    func pushToTeamConversion(fromNavigation nav: UINavigationController,
                              trackPath: String?)

    /// join team through qrcode link, return true if create task success
    /// - Parameters:
    ///   - url: join team qrcode url
    ///   - fromVC: vc to show alert
    ///   - result: true if hasError
    @available(*, deprecated, message: "Use `PassportUserService.joinTeam` instead.")
    func joinTeam(withQRUrl url: String, fromVC: UIViewController, result: @escaping (Bool) -> Void) -> Bool

    @available(*, deprecated, message: "Will be removed soon.")
    func upgradeTeamViewController(nav: UINavigationController,
                                   trackInfo: (path: String?, from: String?),
                                   handler: @escaping (Bool) -> Void,
                                   result: @escaping (UIViewController?) -> Void)

    @available(*, deprecated, message: "Will be removed soon.")
    func upgradeTeam(
        tenantName: String,
        staffSize: String?,
        industryType: String?
    ) -> Observable<Bool>

    @available(*, deprecated, message: "Will be removed soon.")
    func pushToJoinTeam(from: UIViewController)

    // MARK: passport 原生切换租户页面
    @available(*, deprecated, message: "Use `PassportUserService.pushToSwitchUserViewController` instead.")
    func pushToSwitchUserViewController(from: UIViewController)


    // MARK: 安全密码

    /// 获取当前安全验证码设置状态
    ///
    /// - Returns: true:设置 false:未设置
    @available(*, deprecated, message: "Use `PassportUserService.getCurrentSecurityPwdStatus` instead.")
    func getCurrentSecurityPwdStatus() -> Observable<(Bool, Bool)>

    @available(*, deprecated, message: "Use `PassportUserService.getSecurityPasswordViewControllerToPush` instead.")
    func getSecurityPwdViewControllerToPush(isSetPwd: Bool,
                                            createNewSuccess: @escaping () -> Void,
                                            callback: @escaping (UIViewController?) -> Void)

    @available(*, deprecated, message: "Use `PassportUserService.getSecurityStatus` instead.")
    func getSecurityStatus(appId: String, result: @escaping SecurityResult)

    @available(*, deprecated, message: "Use `PassportUserService.checkUnregisterStatus` instead.")
    func checkUnRegisterStatus(scope: UnregisterScope?) -> Observable<CheckUnRegisterStatusModel>

    // MARK: 财经
    /// get phone number list of current account
    /// 财经（红包）使用
    @available(*, deprecated, message: "Use `PassportUserService.getPhoneNumbers` instead.")///
    func getAccountPhoneNumbers() -> Observable<[PhoneNumber]>

    // MARK: 财经
    // 调用财经 web 容器打开 财经相关 url
    @available(*, deprecated, message: "Use `PassportService.openCJURL` instead.")
    func openCJURL(_ url: String)

    /// mobile code top counry code list
    @available(*, deprecated, message: "Use `PassportService.getTopCountryList` instead.")
    func getTopCountryList() -> [String]

    /// mobile code black counry code list
    @available(*, deprecated, message: "Use `PassportUserService.getBlackCountryList` instead.")
    func getBlackCountryList() -> [String]

    @available(*, deprecated, message: "Use `PassportUserService.launchGuideLogin` instead.")
    func launchGuideLogin(context: LauncherContext) -> Observable<Void>

    @available(*, deprecated, message: "Use `PassportUserService.createLoginNavigation` instead.")
    func createLoginNavigation(rootViewController: UIViewController) -> UINavigationController

    @available(*, deprecated, message: "Use `PassportService.updateOnLaunchGuide` instead.")
    func updateOnLaunchGuide(_ onLaunchGuide: Bool)

    /// 是否在引导页
    @available(*, deprecated, message: "Will be removed soon")
    var onLaunchGuide: Bool { get }

    @available(*, deprecated, message: "Use `PassportUserService.quitTeamH5Url` instead.")
    func quitTeamH5Url() -> URL?

    @available(*, deprecated, message: "Use `PassportUserService.teamConversionEntryTitle` instead.")
    func teamConversionEntryTitle(for account: Account) -> String

    /// scope: 需要和 passport 服务端共同定义
    /// contact: 当前用户的登录凭证 e.g: +8613683748343
    /// contactType: 1:手机 2:邮箱
    /// viewControllerHandler: 使用这里的 viewController 做页面呈现
    @available(*, deprecated, message: "Use `PassportUserService.verifyContactPoint` instead.")
    func verifyContactPoint(
        scope: VerifyScope,
        contact: String,
        contactType: ContactType,
        viewControllerHandler: @escaping (Result<UIViewController, Error>) -> Void,
        completionHandler: @escaping (Result<VerifyToken, Error>) -> Void
    )

    @available(*, deprecated, message: "Use `verifyContactPoint(scope:contact:viewControllerHandler:completionHandler:)` instead.")
    func verifyContactPoint(
        scope: VerifyScope, // 需要和passport服务端共同定义
        contact: String, // 当前用户的登录凭证 e.g:+8613683748343
        complete: @escaping (Result<VerifyToken, Error>) -> Void, // Error类型待定
        title: String?, // 可选 验证码页面title
        subtitle: String? // 可选 验证码页面subtitle
    ) -> UIViewController

    @available(*, deprecated, message: "Will be removed soon")
    var deviceService: DeviceService { get }

    /// 仅用于Chatter Manager 同步数据
    @available(*, deprecated, message: "Use `PassportService.updateUserInfo` instead.")
    func updateUserInfo(
        userId: String,
        name: String,
        avatarKey: String,
        enUsName: String,
        avatarUrl: String
    )

    /// 获取免密Token接口
    /// - Parameters:
    ///   - identifier: 需要免密登录的应用标识，比如doc页面链接
    @available(*, deprecated, message: "Use `PassportUserService.generateDisposableLoginToken` instead.")
    func generateDisposableLoginToken(
        identifier: String,
        completion: @escaping (Result<DisposableLoginInfo, DisposableLoginError>) -> Void
    )

    /// 扫描二维码触发 实名认证流程
    @available(*, deprecated, message: "Use `PassportUserService.startRealNameVerificationFromQRCode` instead.")
    func startRealnameVerificationFromQRCode(params: [String: Any], completion: ((String?) -> Void)?) -> Void
    
    /// 获取通过手机号添加企业成员的黑白名单
    /// 当白名单不为空时以白名单为准
    @available(*, deprecated, message: "Use `PassportService.getPhoneNumberRegionList` instead.")
    func getPhoneNumberRegionList(_ completion: @escaping (_ allowList: [String]?, _ blockList: [String]?, _ error: Error?) -> Void) -> Void
    
    // MARK: - 导出本地日志
    
    /// 订阅状态栏点击 5 下行为
    /// 在获取本地日志路径后弹出 UIActivityViewController，分享日志压缩文件
    @available(*, deprecated, message: "Use `PassportService.subscribeStatusBarInteraction` instead.")
    func subscribeStatusBarInteraction()
    
    ///  取消订阅状态栏点击5下行为
    @available(*, deprecated, message: "Use `PassportService.unsubscribeStatusBarInteraction` instead.")
    func unsubscribeStatusBarInteraction()
    
    func fetchClientLog(completion: @escaping (ClientLogShareViewController?) -> Void)
    /// 是否正在执行v2版本的switch user
    func isExecutingSwitchUserV2() -> Bool
    /// 是否开启rustSDK barrier 异步等待返回的逻辑
    func enableSwitchUserEnterBarrierTask() -> Bool
    /// 是否开启新的登录处理流程
    func isNewEnterAppProcess() -> Bool

    #if DEBUG || BETA || ALPHA
    /// 获取Debug下的网络接口信息
    func getNetworkInfoItem() -> [NetworkInfoItem]
    #endif
}

public final class ClientLogShareViewController: UIViewController {
    
    private let activityViewController: UIActivityViewController
    
    public init(url: URL) {
        //定义回调方法
        let successHandler: UIActivityViewController.CompletionWithItemsHandler = { _,successShared,_,_ in
            let fileManager = FileManager()
            do {
                //删除本地日志打包文件
                try fileManager.removeItem(at: url)
            } catch {
                //删除文件失败
            }
        }
        self.activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityViewController.completionWithItemsHandler = successHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    public init() {
        fatalError("use init(url:) instead")
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        addChild(activityViewController)
        view.addSubview(activityViewController.view)
        activityViewController.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        activityViewController.didMove(toParent: self)
    }
}

#if DEBUG || BETA || ALPHA

public struct NetworkInfoItem {

    // 是否是一次成功的网络请求
    public let isSuccess: Bool

    let host: String?
    let path: String?
    let httpCode: Int?
    let xRequestId: String?
    let xTTEnv: String?

    // 失败的场景才会有
    let errorCode: Int32?
    let errorMessage: String?
    let bizCode: Int32?
    let xTTLogid: String?

    // 网络请求回调的时间
    let time: String

    public init(isSuccess: Bool, host: String?, path: String?, httpCode: Int?, xRequestId: String?, xTTEnv: String?, errorCode: Int32?, errorMessage: String?, bizCode: Int32?, xTTLogid: String?) {
        self.isSuccess = isSuccess
        self.host = host
        self.path = path
        self.httpCode = httpCode
        self.xRequestId = xRequestId
        self.xTTEnv = xTTEnv
        self.errorCode = errorCode
        self.errorMessage = errorMessage
        self.bizCode = bizCode
        self.xTTLogid = xTTLogid

        // 获取当前时区的时间
        let timezone = NSTimeZone.system
        let interval = TimeInterval(timezone.secondsFromGMT())
        self.time = Date().addingTimeInterval(interval).description
    }

    public func getHost() -> String {
        return self.host ?? ""
    }

    public func getPath() -> String {
        return self.path ?? ""
    }

    public func getTime() -> String {
        return self.time
    }

    public var desc: String {
        return """
        host:\(String(describing: host));
        path:\(String(describing: path));
        httpCode:\(String(describing: httpCode));
        xRequestId:\(String(describing: xRequestId));
        xTTEnv:\(String(describing: xTTEnv));
        errorCode:\(String(describing: errorCode));
        errorMessage:\(String(describing: errorMessage));
        bizCode:\(String(describing: bizCode));
        xTTLogid:\(String(describing: xTTLogid))
        """
    }
}

#endif
