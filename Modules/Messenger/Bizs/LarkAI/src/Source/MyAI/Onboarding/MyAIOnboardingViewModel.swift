//
//  MyAIOnboardingViewModel.swift
//  LarkAI
//
//  Created by ByteDance on 2023/5/17.
//

import Foundation
import RxSwift
import RxCocoa
import LarkSDKInterface
import LarkContainer
import LarkSetting
import LKCommonsLogging
import LarkLocalizations
import LKCommonsTracker
import LarkMessengerInterface
import LarkAccountInterface

class MyAIOnboardingViewModel {

    let userResolver: UserResolver
    let myAiAPI: MyAIAPI?
    let myAiService: MyAIService?
    let passportService: PassportService?

    let disposeBag = DisposeBag()

    private static let logger = Logger.log(MyAIOnboardingViewModel.self, category: "LarkAI.MyAI")

    var successCallback: ((Int64) -> Void)?
    var failureCallback: ((Error?) -> Void)?
    var cancelCallback: (() -> Void)?

    var currentAvatar: AvatarInfo = .default
    var currentAvatarPlaceholderImage: UIImage?
    var currentName: String = ""

    private(set) var defaultAvatarKey = MyAIResourceManager.defaultAvatarKey

    var presetNames: [String] = MyAIResourceManager.presetNames {
        didSet {
            presetNamesUpdatePublish.onNext(())
        }
    }

    var presetAvatars: [AvatarInfo] = MyAIResourceManager.presetAvatars {
        didSet {
            presetAvatarsUpdatePublish.onNext(())
        }
    }

    private var presetAvatarsUpdatePublish = PublishSubject<Void>()
    var presetAvatarsUpdateDriver: Driver<Void> {
        presetAvatarsUpdatePublish.asDriver(onErrorJustReturn: (()))
    }

    private var presetNamesUpdatePublish = PublishSubject<Void>()
    var presetNamesUpdateDriver: Driver<Void> {
        presetNamesUpdatePublish.asDriver(onErrorJustReturn: (()))
    }

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        self.myAiAPI = try? userResolver.resolve(assert: MyAIAPI.self)
        self.myAiService = try? userResolver.resolve(assert: MyAIService.self)
        self.passportService = try? userResolver.resolve(assert: PassportService.self)
        if !MyAIResourceManager.checkResourcesIntegrity() {
            MyAIResourceManager.loadResourcesFromSetting(userResolver: userResolver, onSuccess: { [weak self] in
                self?.defaultAvatarKey = MyAIResourceManager.defaultAvatarKey
                self?.presetAvatars = MyAIResourceManager.presetAvatars
                self?.presetNames = MyAIResourceManager.presetNames
            }, onFailure: { })
        }
    }

    func initMyAI(onSuccess: ((Int64) -> Void)? = nil, onFailure: ((Error) -> Void)? = nil) {
        let name = currentName
        let avatarKey = currentAvatar == .default ? defaultAvatarKey : currentAvatar.staticImageKey
        Self.logger.info("[MyAI.Onboarding][Init][\(#function)] will call init API with name: \(currentName), avatarKey: \(avatarKey)")
        myAiAPI?.initMyAI(name: name, avatarKey: avatarKey)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { resp in
                Self.logger.info("[MyAI.Onboarding][Init][\(#function)] call init API succeed: \(resp)")
                onSuccess?(Int64(resp.chat.id) ?? 0)
            }, onError: { error in
                Self.logger.error("[MyAI.Onboarding][Init][\(#function)] call init API failed: \(error)")
                onFailure?(error)
            }).disposed(by: disposeBag)
    }

    // MARK: - 埋点

    var aiShadowID: String {
        myAiService?.info.value.id ?? ""
    }

    func reportOnboardingSetupViewShown() {
        Tracker.post(TeaEvent("public_ai_onboarding_view", params: [
            "shadow_id": aiShadowID
        ]))
    }

    func reportOnboardingSetupCloseClicked() {
        Tracker.post(TeaEvent("public_ai_onboarding_click", params: [
            "shadow_id": aiShadowID,
            "click": "close"
        ]))
    }

    func reportOnboardingSetupContinueClicked() {
        Tracker.post(TeaEvent("public_ai_onboarding_click", params: [
            "shadow_id": aiShadowID,
            "click": "continue",
            "avatar_id": currentAvatar.staticImageKey,
            "is_default_avatar": currentAvatar == .default ? "true" : "false",
            "name": currentName,
            "is_default_name": presetNames.contains(currentName) ? "true" : "false"
        ]))
    }

    func reportOnboardingConfirmViewShown() {
        Tracker.post(TeaEvent("public_ai_onboarding_confirm_view", params: [
            "shadow_id": aiShadowID
        ]))
    }

    func reportOnboardingConfirmBackClicked() {
        Tracker.post(TeaEvent("public_ai_onboarding_confirm_click", params: [
            "shadow_id": aiShadowID,
            "click": "back"
        ]))
    }

    func reportOnboardingConfirmCloseClicked() {
        Tracker.post(TeaEvent("public_ai_onboarding_confirm_click", params: [
            "shadow_id": aiShadowID,
            "click": "close"
        ]))
    }

    func reportOnboardingConfirmFinishClicked() {
        Tracker.post(TeaEvent("public_ai_onboarding_confirm_click", params: [
            "shadow_id": aiShadowID,
            "click": "complete"
        ]))
    }
}
