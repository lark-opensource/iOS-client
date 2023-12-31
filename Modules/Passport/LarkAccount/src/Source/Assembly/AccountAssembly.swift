//
//  AccountAssembly.swift
//  LarkAccount
//
//  Created by liuwanlin on 2018/11/25.
//

import EENavigator
import LarkContainer
import LarkFoundation
import LarkLocalizations
import LarkUIKit
import Swinject
import LarkAccountInterface
import LKCommonsLogging
import LKCommonsTracker
import RxSwift
import LarkSettingsBundle
import AppContainer
import LarkAssembler
import LarkOpenSetting
#if LarkAccount_APPSFLYERFRAMEWORK
import AppsFlyerLib
#endif
import LarkEnv

#if canImport(LKPassportExternalAssembly)
import LKPassportExternal
#endif

public typealias AccountDependency = PassportDependency

public enum PassportUserScope {

    private static let logger = Logger.log(PassportUserScope.self, category: "Passport.PassportUserScope")

    /// 这个应该是app内的常量，初始化后不应该再变动，避免新旧实现冲突..
    internal static let enableUserScope: Bool = {
        let enableUserScope = PassportStore.shared.enableUserScope
        print("[Info] Get Passport.enableUserScope: \(enableUserScope)")
        return enableUserScope ?? V3NormalConfig.defaultEnableUserScope
    }()

    public static var userScopeCompatibleMode: Bool { !enableUserScope }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }

    // 作为用户态未启用时的兼容
    static func getCurrentUserResolver() -> UserResolver {
        return Container.shared.getCurrentUserResolver(compatibleMode: userScopeCompatibleMode) // user:current
    }
}

extension PassportUserScope {
    // MARK: - 用户态迁移二期 Rust 部分

    /// 单次启动后不改变
    internal static let enableUserScopeTransitionRust: Bool = {
        let value = PassportGray.shared.getGrayValue(key: .enableUserScopeTransitionRust)
        Self.logger.info("n_action_passport_user_scope RUST: \(value)")
        return value
    }()

    /// 用户态迁移期间所使用的 Scope，用于控制全局态迁移至用户态的服务
    /// 不同的灰度开关会对应不同示例，实现上是一致的
    internal static let containerOrUserScopeRust: ObjectScope = enableUserScopeTransitionRust ? PassportUserScope.userScope : .container

    // MARK: - 用户态迁移二期 Account 部分
    /// 单次启动后不改变
    internal static let enableUserScopeTransitionAccount: Bool = {
        let value = PassportGray.shared.getGrayValue(key: .enableUserScopeTransitionAccount)
        Self.logger.info("n_action_passport_user_scope ACCOUNT: \(value)")
        return value
    }()

    /// 用户态迁移期间所使用的 Scope，用于控制全局态迁移至用户态的服务
    /// 不同的灰度开关会对应不同示例，实现上是一致的
    internal static let containerOrUserScopeAccount: ObjectScope = enableUserScopeTransitionAccount ? PassportUserScope.userScope : .container
}

public final class AccountAssembly: LarkAssemblyInterface {
    public init() {}

    // swiftlint:disable function_body_length
    // swiftlint:disable identifier_name
    public func registContainer(container: Swinject.Container) {
        //pubic
        container.register(Launcher.self) { (_) -> Launcher in
            return Launcher()
        }.inObjectScope(.container) // user:global

        container.register(AccountService.self) { (r) -> AccountService in // user:checked
            return r.resolve(Launcher.self)!
        }

        container.register(DeviceService.self) { (r) -> DeviceService in
            return r.resolve(InternalDeviceServiceProtocol.self)!
        }

        container.register(InternalDeviceServiceProtocol.self) { (_) -> InternalDeviceServiceProtocol in
            return PassportDeviceServiceWrapper.shared
        }
        
        container.register(PassportGlobalDeviceService.self) { _ in
            return PassportDeviceServiceWrapper.shared
        }.inObjectScope(.container).userSafe()

        container.register(GlobalEnvironmentService.self) { _ in
            return GlobalEnvironmentServiceImpl()
        }.inObjectScope(.container).userSafe()

        container.inObjectScope(.user(type: .both)).register(UserEnvironmentService.self) { userResolver in
            return UserEnvironmentServiceImpl(userResolver: userResolver)
        }
        
        container.register(GlobalUserService.self) { _ in
            return GlobalUserServiceImpl.shared
        }.inObjectScope(.container)

        //internal
        container.register(UploadLog.self) { _ in UploadLogManager.shared }.inObjectScope(.container) // user:global

        container.register(PassportStore.self) { _ in PassportStore.shared }.inObjectScope(.container) // user:global

        container.register(UserManager.self) { _ in UserManager.shared }.inObjectScope(.container) // user:global

        container.register(SwitchEnvironmentManager.self) { _ in SwitchEnvironmentManager.shared }.inObjectScope(.container) // user:global

        container.inObjectScope(PassportUserScope.userScope).register(DisposableLoginManager.self) { r in
            return try DisposableLoginManager(resolver: r as? UserResolver)
        }

        container.register(PassportConf.self) { _ -> PassportConf in
            return PassportConf.shared
        }.inObjectScope(.container) // user:global

        container.register(V3LoginService.self) { (r) -> V3LoginService in
            let conf = try r.resolve(assert: PassportConf.self)
            let dependency = try r.resolve(assert: PassportDependency.self)
            return V3LoginService(
                configuration: conf,
                dependency: dependency
            )
        }.inObjectScope(.container) // user:global

        container.register(KaLoginManager.self) { (r) -> KaLoginManager in
            let loginService = r.resolve(V3LoginService.self)!
            return KaLoginFactory.createKaLoginManager(
                loginStateSub: loginService.loginStateSub,
                httpClient: loginService.httpClient,
                context: UniContextCreator.create(.login)
            )
        }.inObjectScope(.container) // user:global

        container.register(IDPServiceProtocol.self) { _ -> IDPServiceProtocol in
            #if IDP
            return IDPService.shared
            #else
            return IDPServicePlaceHolder()
            #endif
        }.inObjectScope(.container) // user:global

        container.register(IDPWebViewServiceProtocol.self) { _ -> IDPWebViewServiceProtocol in
            #if IDP
                #if SUITELOGIN_KA
                //5.22版本民生idp登录需要使用特化逻辑，后续改造成通用代码
                if KAFeatureConfigManager.enableNativeIdP {
                    return IDPNativeService()
                }
                #endif
            return IDPWebViewService()
            #else
            return IDPWebViewServicePlaceholder()
            #endif
        }.inObjectScope(.container) // user:global

        container.register(PassportWebViewDependency.self) { _ -> PassportWebViewDependency in
            return PassportWebViewDependencyImpl()
        }.inObjectScope(.container) // user:global

        container.register(KaLoginService.self) { (r) -> KaLoginService in
            return r.resolve(KaLoginManager.self)!
        }.inObjectScope(.container) // user:global

        container.register(LaunchGuidePassportDependency.self) { _ -> LaunchGuidePassportDependency in
            return LaunchGuidePassportDependencyImpl()
        }.inObjectScope(.container) // user:global

        container.register(NewSwitchUserService.self) { _ -> NewSwitchUserService in
            return NewSwitchUserService()
        }.inObjectScope(.container) // user:global

        container.register(SwitchUserAPI.self) { _ -> SwitchUserAPI in
            return SwitchUserAPI()
        }.inObjectScope(.container) // user:global

        container.register(V3APIHelper.self) { (r) -> V3APIHelper in
            return r.resolve(V3LoginService.self)!.apiHelper
        }.inObjectScope(.container) // user:global

        container.register(PassportTokenManager.self) { _ -> PassportTokenManager in
            return PassportTokenManager()
        }.inObjectScope(.container) // user:global

        container.register(HTTPClient.self) { (_) -> HTTPClient in
            return HTTPClient()
        }.inObjectScope(.container) // user:global

        container.register(PassportEventRegistry.self) { (_) -> PassportEventRegistry in
            return PassportEventRegistry()
        }.inObjectScope(.container) // user:global

        container.register(LogoutService.self) { _ -> LogoutService in
            return LogoutService()
        }.inObjectScope(.container) // user:global

        container.register(UnloginProcessHandler.self) { _ in
            UnloginProcessHandler(resolver: container)
        }.inObjectScope(.container) // user:global

        container.register(EnvironmentInterface.self) { (_) in
            return SwitchEnvironmentManager.shared
        }.inObjectScope(.container) // user:global

        container.inObjectScope(PassportUserScope.containerOrUserScopeAccount).register(UnregisterAPI.self) { _ -> UnregisterAPI in
            return UnregisterAPI()
        }

        container.inObjectScope(PassportUserScope.containerOrUserScopeAccount).register(UnregisterService.self) { r -> UnregisterService in
            return try UnregisterService(resolver: (r as? UserResolver))
        }

        container.register(RecoverAccountAPI.self) { (_) -> RecoverAccountAPI in
            return RecoverAccountAPI()
        }.inObjectScope(.container) // user:global

        container.register(LoginAPI.self) { (_) -> LoginAPI in
            return LoginAPI()
        }.inObjectScope(.container) // user:global

        container.register(VerifyAPI.self) { (_) -> VerifyAPI in
            return VerifyAPI()
        }.inObjectScope(.container) // user:global

        container.inObjectScope(PassportUserScope.userScope).register(MFAAPI.self) { r in
            return try MFAAPI(userResolver: r)
        }
        
        container.register(UserCenterAPI.self) { (_) -> UserCenterAPI in
            return UserCenterAPI()
        }.inObjectScope(.container) // user:global
        
        container.register(JoinTeamAPIV3.self) { (_) -> JoinTeamAPIV3 in
            return JoinTeamAPIV3()
        }.inObjectScope(.container) // user:global

        container.register(BioAuthAPI.self) { (_) -> BioAuthAPI in
            return BioAuthAPI()
        }.inObjectScope(.container) // user:global

        container.register(BioAuthService.self) { (_) -> BioAuthService in
            return BioAuthService()
        }.inObjectScope(.container) // user:global

        container.register(UserSessionService.self) { (_) -> UserSessionService in
            return UserSessionService()
        }.inObjectScope(.user)

        container.inObjectScope(PassportUserScope.userScope).register(OpenAPIAuthAPI.self) { _ -> OpenAPIAuthAPI in
            return OpenAPIAuthAPI()
        }

        container.inObjectScope(PassportUserScope.userScope).register(OpenAPIAuthService.self) { r -> OpenAPIAuthService in
            return try OpenAPIAuthService(resolver: r)
        }
        
        container.register(GlobalKvStorageService.self) { _ in
            return GlobalKvStorageServiceImpl.shared
        }.inObjectScope(.container)

        //plugin
        container.register(SetDeviceInfoAPI.self) { _ -> SetDeviceInfoAPI in
            #if LarkAccount_RUST
            return RustSetDeviceInfoAPI()
            #else
            return NativeSetDeviceInfoAPI()
            #endif
        }.inObjectScope(.container) // user:global

        container.register(MigrateAPI.self) { _ -> MigrateAPI in
            #if LarkAccount_RUST
            return RustMigrateAPI()
            #else
            return NativeMigrateAPI()
            #endif
        }.inObjectScope(.container) // user:global

        container.register(LogoutAPI.self) { _ -> LogoutAPI in
            #if LarkAccount_RUST
            return RustLogoutAPI()
            #else
            return NativeLogoutAPI()
            #endif
        }.inObjectScope(.container) // user:global

        container.register(DynamicDomainService.self) { _ -> DynamicDomainService in
            #if LarkAccount_RUST
            return RustDynamicDomainService()
            #else
            return NativeDynamicDomainService()
            #endif
        }.inObjectScope(.container) // user:global

        container.register(CaptchaAPI.self) { (_) -> CaptchaAPI in
            #if LarkAccount_RUST
            return RustCaptchaAPI()
            #else
            return NativeCaptchaAPI()
            #endif
        }.inObjectScope(.container) // user:global

        container.inObjectScope(PassportUserScope.userScope).register(DisposableLoginConfigAPI.self) { r -> DisposableLoginConfigAPI in
            #if LarkAccount_RUST
            return try RustDisposableLoginConfigAPI(resolver: (r as? UserResolver))
            #else
            // 空实现，无须用户态迁移
            return NativeDisposableLoginConfigAPI()
            #endif
        }

        container.inObjectScope(PassportUserScope.userScope).register(QRCodeAPI.self) { r -> QRCodeAPI in
            return NativeQRCodeAPI(resolver: r)
        }

        container.inObjectScope(PassportUserScope.containerOrUserScopeRust).register(DeviceManageServiceProtocol.self) { r -> DeviceManageServiceProtocol in
            return try NativeDeviceManageService(resolver: (r as? UserResolver))
        }

        container.register(RealnameVerifyAPI.self) { (_) -> RealnameVerifyAPI in
            return RealnameVerifyAPIIMP()
        }.inObjectScope(.container) // user:global

        container.register(AccountServiceUG.self) {(_) -> AccountServiceUG in // user:checked
            return UGService()
        }.inObjectScope(.container) // user:global

        container.inObjectScope(PassportUserScope.containerOrUserScopeAccount).register(MFALegacyAPI.self) { _ -> MFALegacyAPI in
            return MFALegacyAPI()
        }

        container.inObjectScope(PassportUserScope.containerOrUserScopeAccount).register(AccountServiceMFA.self) { r -> AccountServiceMFA in // user:checked
            return try MFAService(resolver: ((r as? UserResolver)))
        }

        #if DEBUG || BETA || ALPHA
        container.register(AutoLoginService.self) { (_) -> AutoLoginService in
            return AutoLoginServiceImpl()
        }.inObjectScope(.container) // user:global
        #endif
        
       
        container.register(PassportDebugService.self) { (_) -> PassportDebugService in
        #if DEBUG || BETA || ALPHA
            return PassportDebugServiceDebugImpl()
        #else
            return PassportDebugServiceDefaultImpl()
        #endif
        }.inObjectScope(.container) // user:global


        container.register(AccountServiceAgreement.self) { (_) -> AccountServiceAgreement in // user:checked
            return AgreementService()
        }.inObjectScope(.container) // user:global

        container.register(PassportService.self) { (_) -> PassportService in
            return PassportServiceImpl()
        }.inObjectScope(.container) // user:global

        container.inObjectScope(PassportUserScope.userScope).register(PassportUserService.self) { r in
            return try PassportUserServiceImpl(resolver: r)
        }

        container.inObjectScope(PassportUserScope.userScope).register(InternalMFANewService.self) { r in
            return try MFANewServiceImpl(userResolver: r)
        }

        container.inObjectScope(PassportUserScope.userScope).register(AccountServiceNewMFA.self) { r in // user:current
            return try r.resolve(assert: InternalMFANewService.self)
        }

        container.register(PassportStateService.self) { (_) -> PassportStateService in
            return PassportStateServiceImpl()
        }.inObjectScope(.container) // user:global

        container.inObjectScope(.container).register(MultiUserActivityCoordinatable.self) { (_) in
            return MultiUserActivityCoordinator.shared
        }

#if canImport(LKPassportExternalAssembly)
        container.register(KAPassportProtocol.self) { (_) -> KAPassportProtocol in
            return KaPassportImpl()
        }.inObjectScope(.user)  // user:checked
#endif

        container.register(PassportContainerAfterRustOnlineWorkflow.self) { (_) -> PassportContainerAfterRustOnlineWorkflow in
            return PassportContainerWorkflowImpl()
        }.inObjectScope(.container)
    }

    public func registRouter(container: Swinject.Container) {
        Navigator.shared.registerMiddleware_(cacheHandler: true) { () -> MiddlewareHandler in
            return container.resolve(UnloginProcessHandler.self)!
        }

        Navigator.shared.registerRoute_(type: SimplifyLoginBody.self) {
            return SimplifyLoginHandler()
        }

        Navigator.shared.registerRoute_(type: GuestLoginBody.self) {
            return GuestLoginHandler()
        }

        Navigator.shared.registerRoute_(pattern: AccountManagementBody.pattern) { (_, res) in
            res.end(resource: container.resolve(Launcher.self)!.credentialList(context: UniContextCreator.create(.unknown)))
        }

        Navigator.shared.registerRoute_(type: MineAccountBody.self) { (_, _, res) in
            res.end(resource: DeviceManagerViewController())
        }

        Navigator.shared.registerRoute_(type: SwitchAccountBody.self) {
            return SwitchAccountHandler(resolver: container)
        }

        let pattern = PassportStore.shared.tnsAuthURLRegex ?? V3NormalConfig.defaultTNSAuthURLRegex
        Navigator.shared.registerRoute_(regExpPattern: pattern) { (req, res) in
            do {
                let dependency = try container.resolve(type: PassportDependency.self)
                let webViewController = dependency.createWebViewController(req.url, customUserAgent: nil)
                res.end(resource: webViewController)
            } catch {
                res.end(error: RouterError.notHandled)
            }
        }
    }

    public func registURLInterceptor(container: Swinject.Container) {
        (SwitchAccountBody.pattern, { (url, from) in
            Navigator.shared.open(url, context: ["from": "app"], from: from) // user:checked (navigator)
        })
    }

    private static func containerPassportDelegate(container: Swinject.Container) -> PassportDelegate {
        // 提前初始化，保证对应的Container初始化设置正常完成
        if PassportUserScope.enableUserScope {
            return ContainerPassportDelegate(container: container)
        } else {
            return DummyPassportDelegate()
        }
    }

    public func registPassportDelegate(container: Swinject.Container) {
        let containerDelegate = Self.containerPassportDelegate(container: container)
        (PassportDelegateFactory { containerDelegate }, PassportDelegatePriority.high)

        (PassportDelegateFactory {
            if PassportUserScope.enableUserScope {
                return LogAppenderPassportDelegate(resolver: container)
            } else {
                return DummyPassportDelegate()
            }
        }, PassportDelegatePriority.middle)

        (PassportDelegateFactory {
            if PassportUserScope.enableUserScope {
                return AccountMultiScenePassportDelegate()
            } else {
                return DummyPassportDelegate()
            }
        }, PassportDelegatePriority.middle)

#if !LarkAccount_BootManager
        (PassportDelegateFactory {
            if PassportUserScope.enableUserScope {
                return AccountIntegratorDelegate()
            } else {
                return DummyPassportDelegate()
            }
        }, PassportDelegatePriority.high)
#endif
    }

    private static func containerLauncherDelegate(container: Swinject.Container) -> LauncherDelegate { // user:checked
        // 提前初始化，保证对应的Container初始化设置正常完成
        if PassportUserScope.enableUserScope {
            return DummyLauncherDelegate()
        } else {
            return ContainerDelegate(container: container)
        }
    }

    public func registLauncherDelegate(container: Swinject.Container) {
        let containerDelegate = Self.containerLauncherDelegate(container: container)
        (LauncherDelegateFactory { containerDelegate }, LauncherDelegateRegisteryPriority.high)

        (LauncherDelegateFactory {
            if PassportUserScope.enableUserScope {
                return DummyLauncherDelegate()
            } else {
                return SuiteLoginLaunchDelegate(resolver: container)
            }
        }, LauncherDelegateRegisteryPriority.middle)

        (LauncherDelegateFactory {
            if PassportUserScope.enableUserScope {
                return DummyLauncherDelegate()
            } else {
                return AccountMultiSceneDelegate()
            }
        }, LauncherDelegateRegisteryPriority.middle)

        (LauncherDelegateFactory {
            return UserDataEraserHelper.shared
        }, LauncherDelegateRegisteryPriority.high)

#if !LarkAccount_BootManager
        (LauncherDelegateFactory {
            if PassportUserScope.enableUserScope {
                return DummyLauncherDelegate()
            } else {
                return AccountIntegratorLauncherDelegate()
            }
        }, LauncherDelegateRegisteryPriority.high)
#endif
    }
    // swiftlint:enable ForceUnwrapping

    public func registUnloginWhitelist(container: Swinject.Container) {
        SimplifyLoginBody.pattern
        GuestLoginBody.pattern
    }

    public func getSubAssemblies() -> [LarkAssembler.LarkAssemblyInterface]? {
        var assemblies: [LarkAssembler.LarkAssemblyInterface] = []

        #if LarkAccount_RUST
        assemblies.append(RustPluginAssembly())
        #endif

        #if LarkAccount_Authorization
        assemblies.append(AuthorizationAssembly())
        #else
        assemblies.append(MockAuthorizationAssembly())
        #endif

        #if LarkAccount_BootManager
        assemblies.append(AccountBootManageAssembly())
        #endif

        return assemblies
    }

    @_silgen_name("Lark.LarkEnv_EnvDelegateRegistry_regist.accountAssembly")
    static public func assembleEnvDelegate() {
        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
            return AppLogEnvDelegate()
        }))
        
        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
            return TuringServiceEnvDelegate()
        }))
        
        #if LarkAccount_RUST
        EnvDelegateRegistry.register(factory: EnvDelegateFactory(delegateProvider: { () -> EnvDelegate in
            return LarkRustEnvDelegate()
        }))
        #endif
    }

    @_silgen_name("Lark.OpenSetting.PassportSettingAssembly")
    public static func pageFactoryRegister() {
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.accountEntry.moduleKey, provider: { userResolver in
            guard let depency = try? userResolver.resolve(assert: AccountDependency.self) else {
                return nil
            }
            // 精简模式状态不显示账号于安全
            if depency.deviceInLeanMode {
                return nil
            }
            return GeneralBlockModule(
                userResolver: userResolver,
                title: AccountServiceAdapter.shared.accountSecurityCenterEntryTitle(), // user:checked
                                                onClickBlock: { (userResolver, vc) in
                AccountServiceAdapter.shared.openAccountSecurityCenter(from: vc) // user:checked
            })
        })
        PageFactory.shared.register(page: .main, moduleKey: ModulePair.Main.mainLogout.moduleKey, provider: { userResolver in
            return MainSettingLogoutModule(userResolver: userResolver)
        })
    }
}
