//
//  MyAIProfileSettingViewModel.swift
//  LarkAI
//
//  Created by Hayden on 2023/5/29.
//

import Foundation
import RxSwift
import RxCocoa
import LarkContainer
import LKCommonsLogging
import LKCommonsTracker
import LarkMessengerInterface

final class MyAISettingViewModel: MyAIOnboardingViewModel {

    private static let logger = Logger.log(MyAISettingViewModel.self, category: "LarkAI.MyAI")

    var myAIService: MyAIService? {
        try? userResolver.resolve(type: MyAIService.self)
    }

    let myAiId: String
    var myAiAvatarKey: String
    // 修改之前的 avatarKey
    let previousAvatarKey: String
    var myAiName: String

    init(resolver: UserResolver,
         myAiId: String,
         myAiAvatarKey: String,
         myAiName: String) {
        self.myAiId = myAiId
        self.myAiName = myAiName
        self.myAiAvatarKey = myAiAvatarKey
        self.previousAvatarKey = myAiAvatarKey
        super.init(userResolver: resolver)
        self.currentName = myAiName
    }

    override var currentName: String {
        didSet {
            myAiName = currentName
        }
    }

    override var currentAvatar: AvatarInfo {
        didSet {
            myAiAvatarKey = currentAvatar.staticImageKey
        }
    }

    func updateAIName(with name: String, onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil) {
        Self.logger.info("[MyAI.Profile][Setting][\(#function)] will update ai name with: \(name)")
        myAiAPI?.updateAIProfile(name: name, avatarKey: nil)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] resp in
                Self.logger.info("[MyAI.Profile][Setting][\(#function)] update name succeed: \(resp)")
                self?.myAiName = name
                self?.currentName = name
                onSuccess?()
            }, onError: { error in
                Self.logger.error("[MyAI.Profile][Setting][\(#function)] update name failed: \(error)")
                onFailure?(error)
            }).disposed(by: disposeBag)
    }

    func updateAIAvatar(onSuccess: (() -> Void)? = nil, onFailure: ((Error) -> Void)? = nil) {
        let avatarKey = currentAvatar == .default ? defaultAvatarKey : currentAvatar.staticImageKey
        Self.logger.info("[MyAI.Profile][Setting][\(#function)] will update ai avatar with: \(avatarKey)")
        myAiAPI?.updateAIProfile(name: nil, avatarKey: avatarKey)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] resp in
                Self.logger.info("[MyAI.Profile][Setting][\(#function)] update avatar succeed: \(resp)")
                self?.myAiAvatarKey = avatarKey
                onSuccess?()
            }, onError: { error in
                Self.logger.error("[MyAI.Profile][Setting][\(#function)] update avatar failed: \(error)")
                onFailure?(error)
            }).disposed(by: disposeBag)
    }

    // MARK: - 埋点

    func reportSettingShown() {
        Tracker.post(TeaEvent("profile_ai_setting_information_view", params: [
            "shadow_id": myAiId
        ]))
    }

    func reportNameClicked() {
        Tracker.post(TeaEvent("profile_ai_setting_information_click", params: [
            "shadow_id": myAiId,
            "click": "name_edit"
        ]))
    }

    func reportAvatarClicked() {
        Tracker.post(TeaEvent("profile_ai_setting_information_click", params: [
            "shadow_id": myAiId,
            "click": "avatar"
        ]))
    }

    func reportAvatarSettingShown() {
        Tracker.post(TeaEvent("profile_ai_avatar_setting_information_view", params: [
            "shadow_id": myAiId
        ]))
    }

    func reportAvatarSettingCancelClicked() {
        Tracker.post(TeaEvent("profile_ai_avatar_setting_information_click", params: [
            "shadow_id": myAiId,
            "click": "back"
        ]))
    }

    func reportAvatarSettingSaveClicked() {
        Tracker.post(TeaEvent("profile_ai_avatar_setting_information_click", params: [
            "shadow_id": myAiId,
            "click": "save",
            "from_avatar_id": previousAvatarKey,
            "to_avatar_id": myAiAvatarKey
        ]))
    }

    func reportNameSettingShown() {
        Tracker.post(TeaEvent("profile_ai_name_setting_information_view", params: [
            "shadow_id": myAiId
        ]))
    }

    func reportNameSettingCancelClicked() {
        Tracker.post(TeaEvent("profile_ai_name_setting_information_click", params: [
            "shadow_id": myAiId,
            "click": "back"
        ]))
    }

    func reportNameSettingSaveClicked() {
        Tracker.post(TeaEvent("profile_ai_name_setting_information_click", params: [
            "shadow_id": myAiId,
            "click": "save"
        ]))
    }
}
