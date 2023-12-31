//
//  VoIPDependentServices.swift
//  LarkByteView
//
//  Created by chentao on 2019/12/29.
//
import Foundation
import LarkVoIP
import RxSwift
import ByteViewInterface
import LarkEnv
#if LarkMod
import LarkWaterMark
#endif
#if LarkLiveMod
import LarkLiveInterface
#endif

#if LarkMod
final class VoIPWaterMarkServiceImpl: VoIPWaterMarkService {

    let waterMarkProxy: WaterMarkService

    init(waterMarkProxy: WaterMarkService) {
        self.waterMarkProxy = waterMarkProxy
    }

    var darkModeWaterMarkView: Observable<UIView> {
        return waterMarkProxy.darkModeWaterMarkView
    }

    var globalWaterMarkIsShow: Observable<Bool> {
        return waterMarkProxy.globalWaterMarkIsShow
    }
}
#endif

final class DefaultVoIPWaterMarkService: VoIPWaterMarkService {
    var darkModeWaterMarkView: Observable<UIView> {
        let v = UIView()
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        return .just(v)
    }

    var globalWaterMarkIsShow: Observable<Bool> {
        .just(false)
    }
}

#if LarkLiveMod
final class VoIPLiveServiceImpl: VoIPLiveService {
    let liveServiceProxy: LarkLiveService

    init(liveServiceProxy: LarkLiveService) {
        self.liveServiceProxy = liveServiceProxy
    }

    func isLiving() -> Bool {
        return liveServiceProxy.isLiving()
    }

    func startVoip() {
        liveServiceProxy.startVoip()
    }
}
#endif
class DefaultVoIPLiveService: VoIPLiveService {
    func isLiving() -> Bool {
        false
    }

    func startVoip() { }
}

#if MessengerMod
import LarkSDKInterface
import LarkFeatureSwitch
import LarkAppConfig

final class MessengerVoIPConfigService: VoIPConfigService {
    private let setting: UserGeneralSettings?
    init(setting: UserGeneralSettings?) {
        self.setting = setting
    }

    var showMessageDetail: Bool {
        setting?.showMessageDetail ?? false
    }

    var isVoIPEnabled: Bool {
        var isVoIPEnabled = true
        Feature.on(.voip).apply(on: {
            isVoIPEnabled = true
        }, off: {
            isVoIPEnabled = false
        })
        return isVoIPEnabled
    }

    var env: VoIPEnv {
        let envType: VoIPEnv.EnvType
        switch EnvManager.env.type {
        case .release:
            envType = .release
        case .staging:
            envType = .staging
        case .preRelease:
            envType = .preRelease
        }
        return VoIPEnv(envType: envType, isChinaMainlandGeo: EnvManager.env.isChinaMainlandGeo)
    }
}

final class MessengerVoIPChatService: VoIPChatService {
    private let chat: ChatAPI?
    private let chatter: ChatterAPI?
    init(chat: ChatAPI?, chatter: ChatterAPI?) {
        self.chat = chat
        self.chatter = chatter
    }

    func getLocalP2PChatId(userId: String) -> String? {
        chat?.getLocalP2PChat(by: userId)?.id
    }

    func getChatterFromLocal(id: String) -> VoIPChatter? {
        chatter?.getChatterFromLocal(id: id).map { VoIPChatter(id: id, displayName: $0.displayName, avatarKey: $0.avatarKey) }
    }

    func getChatterFromRemote(id: String) -> Observable<VoIPChatter?> {
        chatter?.getChatter(id: id).map { chatter in
            chatter.map { VoIPChatter(id: id, displayName: $0.displayName, avatarKey: $0.avatarKey) }
        } ?? .just(nil)
    }
}

#endif
final class DefaultVoIPConfigService: VoIPConfigService {
    var showMessageDetail: Bool {
        false
    }

    var isVoIPEnabled: Bool {
        true
    }

    var env: VoIPEnv {
        let envType: VoIPEnv.EnvType
        switch EnvManager.env.type {
        case .release:
            envType = .release
        case .staging:
            envType = .staging
        case .preRelease:
            envType = .preRelease
        }
        return VoIPEnv(envType: envType, isChinaMainlandGeo: EnvManager.env.isChinaMainlandGeo)
    }
}

final class DefaultVoIPChatService: VoIPChatService {
    func getLocalP2PChatId(userId: String) -> String? {
        nil
    }

    func getChatterFromLocal(id: String) -> VoIPChatter? {
        nil
    }

    func getChatterFromRemote(id: String) -> Observable<VoIPChatter?> {
        .empty()
    }
}
