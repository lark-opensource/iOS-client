//
//  PassportUserService.swift
//  LarkAccountInterface
//
//  Created by Nix Wang on 2022/6/27.
//

import Foundation
import RxSwift

public struct PassportUserState {
    public let user: User
    public let loginState: PassportLoginState
    public let action: PassportUserAction       // 表示状态变化的原因

    public init(user: User, loginState: PassportLoginState, action: PassportUserAction) {
        self.user = user
        self.loginState = loginState
        self.action = action
    }

    public var description: String {
        return "state: [\(loginState.rawValue)] uid: \(user.userID) action: [\(action.rawValue)]"
    }
}

/// 与当前用户相关的接口，在用户容器中提供
public protocol PassportUserService: AnyObject {

    // MARK: - 用户信息

    var state: Observable<PassportUserState> { get }

    /// 当前用户
    var user: User { get }

    /// 当前用户的租户，等同于 user.tenant
    var userTenant: Tenant { get }

    /// 当前前台租户品牌名，无论是 SaaS 版本（走正常 App Store 发布）还是 KA（私有化部署），值总会是 feishu/lark 中的任一一个
    /// 当没有前台租户时，根据 app 包版本决定
    var userTenantBrand: TenantBrand { get }

    /// 当前前台租户geo，当拿不到时默认值为空字符串
    var userTenantGeo: String? { get }

    /// 当前前台租户是否为飞书品牌，语义上等同于国内租户；反之为 lark，国外租户
    /// 当没有前台租户时，根据 app 包版本决定，即 feishu app 为 true
    var isFeishuBrand: Bool { get }

    /// 当前前台用户 unit 归属，当没有前台用户时，根据 app 包版本决定
    var userUnit: String { get }

    /// 当前前台用户 geo 归属，当没有前台用户时，根据 app 包版本决定
    var userGeo: String { get }

    /// 当前前台用户 geo (地理归属地) 是否为中国大陆地区，语义上等于国内用户
    var isChinaMainlandGeo: Bool { get }

    /// Domain 和 SessionKey 的映射, 用于 Cookie 组装
    var sessionKeyWithDomains: [String: [String : String]]? { get }

    // MARK: - 注销

    func checkUnRegisterStatus(scope: UnregisterScope?) -> Observable<CheckUnRegisterStatusModel>

    /// 通过二维码链接加入团队
    /// - Parameters:
    ///   - url: join team QR code url
    ///   - fromVC: vc to show alert
    ///   - result: true if hasError
    func joinTeam(withQRUrl url: String, fromVC: UIViewController, result: @escaping (Bool) -> Void) -> Bool


    // MARK: - 安全密码

    /// 获取当前安全验证码设置状态
    /// - completion: (是否设置密码，是否调用成功)
    func getCurrentSecurityPwdStatus() -> Observable<(Bool, Bool)>

    func pushSecurityPwdSettingViewController(from: UIViewController)

    func getSecurityStatus(appId: String, result: @escaping SecurityResult)


    // MARK: - 财经

    /// get phone number list of current account
    /// 财经（红包）使用
    func getAccountPhoneNumbers() -> Observable<[LarkAccountInterface.PhoneNumber]>

    // MARK: - 其他
    
    /// scope: 需要和 passport 服务端共同定义
    /// contact: 当前用户的登录凭证 e.g: +8613683748343
    /// contactType: 1:手机 2:邮箱
    /// viewControllerHandler: 使用这里的 viewController 做页面呈现
    func verifyContactPoint(
        scope: VerifyScope,
        contact: String,
        contactType: ContactType,
        viewControllerHandler: @escaping (Result<UIViewController, Error>) -> Void,
        completionHandler: @escaping (Result<VerifyToken, Error>) -> Void
    )

    /// 获取免密Token接口
    /// - Parameters:
    ///   - identifier: 需要免密登录的应用标识，比如doc页面链接
    func generateDisposableLoginToken(
        identifier: String,
        completion: @escaping (Result<DisposableLoginInfo, DisposableLoginError>) -> Void
    )

    /// 扫描二维码触发 实名认证流程
    func startRealNameVerificationFromQRCode(params: [String: Any], completion: ((String?) -> Void)?) -> Void

    /// 开放平台增量授权接口
    func requestOpenAPIAuth(params: OpenAPIAuthParams, completion: @escaping ((OpenAPIAuthResult) -> Void))
}

