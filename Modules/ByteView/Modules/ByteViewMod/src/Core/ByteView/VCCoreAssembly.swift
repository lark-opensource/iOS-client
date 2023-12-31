//
//  VCCoreAssembly.swift
//  ByteViewMod
//
//  Created by kiri on 2021/10/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import EENavigator
import LarkSceneManager
import BootManager
import ByteViewInterface
import ByteViewCommon
import LarkAccountInterface
import AppContainer
import LarkAssembler
import LarkRustClient
import ByteViewUDColor
import UniverseDesignColor
import LarkAppLinkSDK
import ByteView
import ByteViewLiveCert
import ByteViewNetwork
import ByteViewSetting
import LarkMedia

final class VCCoreAssembly: LarkAssemblyInterface {

    func getSubAssemblies() -> [LarkAssemblyInterface]? {
        PushAssembly()
    }

    func registContainer(container: Container) {
        let user = container.inObjectScope(.vcUser)
        user.register(CertService.self) { r in
            let httpClient = try r.resolve(assert: HttpClient.self)
            #if LarkMod
            return CertService(httpClient: httpClient, dependency: LarkLiveCertDependency(userResolver: r))
            #else
            return CertService(httpClient: httpClient, dependency: DefaultLiveCertDependency())
            #endif
        }

        user.register(AccountInfo.self) {
            LarkAccountInfo(userResolver: $0)
        }

        user.register(LarkDependency.self) { r in
            #if LarkMod
            return LarkDependencyImpl(userResolver: r)
            #else
            return DefaultLarkDependency(userResolver: r)
            #endif
        }

        user.register(MediaMutexDependency.self) {
            try MediaMutexDependencyImpl(userResolver: $0)
        }

        user.register(MeetingService.self) {
            MeetingServiceImpl(userResolver: $0)
        }

        user.register(CurrentMeetingService.self) {
            CurrentMeetingService(userResolver: $0)
        }

        user.register(MeetingNotifyService.self) { r in
            MeetingNotifyService(factory: { try MeetingDependencyImpl(userResolver: r) })
        }

        user.register(TerminationMonitor.self) {
            TerminationMonitor(storage: LocalStorageImpl(space: .user(id: $0.userID)))
        }

        user.register(HttpClient.self) { r in
            HttpClient(userId: r.userID)
        }

        user.register(UserSettingManager.self) { r in
            do {
                let setting = UserSettingManager(dependency: try UserSettingDependencyImpl(userResolver: r))
                setting.setViewDependency(SettingUIDependencyImpl(userResolver: r))
                return setting
            } catch {
                throw error
            }
        }
    }

    func registRouter(container: Container) {
        Navigator.shared.registerMiddleware.factory(cache: true, FloatWindowHandler.init(resolver:))
        Navigator.shared.registerLocateOrPopObserver.factory(cache: true, FloatWindowHandler.init(resolver:))
        Navigator.shared.registerRoute.type(StartMeetingBody.self).factory(StartMeetingHandler.init(resolver:))
        Navigator.shared.registerRoute.type(JoinMeetingBody.self).factory(JoinMeetingHandler.init(resolver:))
        Navigator.shared.registerRoute.type(JoinMeetingByCalendarBody.self).factory(JoinMeetingByCalendarHandler.init(resolver:))
        Navigator.shared.registerRoute.type(JoinInterviewBody.self).factory(JoinInterviewHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ShareContentBody.self).factory(ShareContentHandler.init(resolver:))
        Navigator.shared.registerRoute.type(PhoneCallBody.self).factory(PhoneCallHandler.init(resolver:))
        Navigator.shared.registerRoute.type(PhoneCallPickerBody.self).factory(PhoneCallPickerHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ByteViewSettingsBody.self).factory(ByteViewSettingsHandler.init(resolver:))
        Navigator.shared.registerRoute.type(VCCalendarSettingsBody.self).factory(VCCalendarSettingsHandler.init(resolver:))
        Navigator.shared.registerRoute.type(JoinMeetingByLinkBody.self).factory(JoinMeetingByLinkHandler.init(resolver:))
        Navigator.shared.registerRoute.type(JoinMeetingByMeetingNoBody.self).factory(JoinMeetingByMeetingNoHandler.init(resolver:))
        Navigator.shared.registerRoute.type(VideoChatPromptBody.self).factory(VideoChatPromptHandler.init(resolver:))
        Navigator.shared.registerRoute.type(JoinMeetingByMyAIBody.self).factory(JoinMeetingByMyAIHandler.init(resolver:))
        Navigator.shared.registerRoute.type(MeetingLiveCertBody.self).factory(MeetingLiveCertHandler.init(resolver:))
        Navigator.shared.registerRoute.type(PreviewParticipantsBody.self).factory(PreviewParticipantsHandler.init(resolver:))
        Navigator.shared.registerRoute.type(PstnPhonesBody.self).factory(PstnPhonesHandler.init(resolver:))

        Navigator.shared.registerRoute.match({ (url) -> Bool in
            return ByteViewAppSchemaHandler.isMatch(url: url)
        }).factory(ByteViewAppSchemaHandler.init(resolver:))

        /// IM中点开says链接 - 设置埋点
        Navigator.shared.registerRoute.match({ (url) -> Bool in
            return ByteViewUrlTrackHandler.verifyURL(url: url, hosts: ["getsays.cn"], pathRule: ["share\\/[a-zA-Z0-9]+$"])
        }).tester({ (req: EENavigator.Request) -> Bool in
            return ByteViewUrlTrackHandler.test(req: req, linkSource: "says")
        }).factory(ByteViewUrlTrackHandler.init(resolver:))

        /// IM中点开LarkMinutes链接 - 设置埋点
        Navigator.shared.registerRoute.match({ (url) -> Bool in
            return ByteViewUrlTrackHandler.verifyURL(url: url, hosts: nil, pathRule: ["\\/minutes\\/(ob|mm)(\\w{22})$", "\\/minutes_feishu\\/[a-zA-Z0-9]+$"])
        }).tester({ req in
            return ByteViewUrlTrackHandler.test(req: req, linkSource: "minutes")
        }).factory(ByteViewUrlTrackHandler.init(resolver:))
    }

    func registURLInterceptor(container: Container) {
        (JoinInterviewBody.pattern, { (url, from) in
            Navigator.currentUserNavigator.open(url, from: from)
        })

        (VideoChatPromptBody.pattern, { (url, from) in
            Navigator.currentUserNavigator.open(url, from: from)
        })

        (JoinMeetingByLinkBody.pattern, { (url, from) in
            Navigator.currentUserNavigator.open(url, from: from)
        })

        (JoinMeetingByMeetingNoBody.pattern, { (url, from) in
            Navigator.currentUserNavigator.open(url, from: from)
        })
    }

    func registLarkAppLink(container: Container) {
        //目前没有机制、时机支持UDColor，沟通后确认可放到registLarkAppLink
        UDColor.registerUDBizColor(ByteViewThemeColor())
        // 注册视频会议 AppLink 协议
        LarkAppLinkSDK.registerHandler(path: JoinMeetingByLinkBody.path, handler: { (applink: AppLink) in
            OpenMeetingLinkHandler().handle(appLink: applink)
        })

        LarkAppLinkSDK.registerHandler(path: MeetingLiveCertBody.path, handler: { (applink: AppLink) in
            LiveCertLinkHandler().handle(appLink: applink)
        })

        LarkAppLinkSDK.registerHandler(path: ByteViewSettingsBody.path, handler: { (applink: AppLink) in
            OpenByteViewSettingsLinkHandler().handle(appLink: applink)
        })

        LarkAppLinkSDK.registerHandler(path: "/client/vc/myai/action") { applink in
            MyAIActionLinkHandler().handle(appLink: applink)
        }
    }

    func registPassportDelegate(container: Container) {
        (PassportDelegateFactory { ByteViewPassportDelegate.shared }, PassportDelegatePriority.middle)
    }

    func registBootLoader(container: Container) {
        // 优先级设为 high，及时响应 willTerminate 事件，退出灵动岛
        (ByteViewApplicationDelegate.self, DelegateLevel.high)
    }

    func registLaunch(container: Container) {
        NewBootManager.register(VCSetupTask.self)
        NewBootManager.register(AccountInterruptTask.self)
    }

    @available(iOS 13.0, *)
    func registLarkScene(container: Container) {
        SceneManager.shared.register(config: VcSceneConfig.self)
        SceneManager.shared.register(config: VcSideBarSceneConfig.self)
    }
}

extension Logger {
    static let account = Logger.getLogger("Account")
}
