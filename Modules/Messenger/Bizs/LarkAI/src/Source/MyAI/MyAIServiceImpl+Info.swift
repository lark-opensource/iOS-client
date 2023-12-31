//
//  MyAIServiceImpl+Info.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/13.
//

import Foundation
import LarkAIInfra
import ServerPB
import EENavigator
import LarkMessengerInterface
import LarkUIKit
import RustPB
import ByteWebImage
import UniverseDesignIcon
import LarkSDKInterface

/// 把MyAIInfoService相关逻辑放这里
public extension MyAIServiceImpl {
    /// 1.判断是否开启MyAI功能：后台 + FG，不用监听Push，开关变化很低频
    func fetchMyAIEnable() {
        if larkMyAIMainSwitch {
            MyAIServiceImpl.logger.info("my ai begin fetch myai enable")
            let request = ServerPB_Office_ai_CheckMyAIUsableRequest()
            self.rustClient?.sendPassThroughAsyncRequest(request, serCommand: .larkOfficeAiImCheckMyAiUsable).subscribe(onNext: { [weak self] (response: ServerPB_Office_ai_CheckMyAIUsableResponse) in
                guard let `self` = self else { return }
                MyAIServiceImpl.logger.info("my ai finish fetch myai enable, enable: \(response.usableStatus)")
                let isEnable = response.usableStatus
                if isEnable {
                    self.getMyAIInfo(); self.fetchMyAIInfo()
                }
                self.enable.accept(isEnable)
            }, onError: { error in
                MyAIServiceImpl.logger.info("my ai error fetch myai enable, error: \(error)")
            }).disposed(by: self.disposeBag)
        } else {
            MyAIServiceImpl.logger.info("my ai enable accept false because of fg")
            self.enable.accept(false)
        }
    }

    /// 用于联系人tab MyAI、大搜出Mock MyAI人，跳转到MyAI的Profile；内部会根据是否Onboarding先进入Onboarding流程
    func openMyAIProfile(from: NavigatorFrom) {
        self.checkOnboardingAndThen(from: from) {
            DispatchQueue.main.async {
                self.userResolver.navigator.presentOrPush(
                    body: MyAIProfileBody(),
                    wrap: LkNavigationController.self,
                    from: from,
                    prepareForPresent: { viewController in
                        viewController.modalPresentationStyle = .formSheet
                    }
                )
            }
        }
    }

    /// 3.获取头像信息，Onboarding前、后通过GetAIProfile得到的chatterId是一致的
    func fetchMyAIInfo(exec: (() -> Void)? = nil) {
        MyAIServiceImpl.logger.info("my ai begin fetch myai info")
        var request = RustPB.Contact_V2_GetMyAIChatterRequest()
        request.syncDataStrategy = .forceServer // SDK不支持tryLocal
        self.rustClient?.sendAsyncRequest(request).subscribe(onNext: { [weak self] (response: RustPB.Contact_V2_GetMyAIChatterResponse) in
            guard let `self` = self else { return }
            let aiInfo = response.myAi
            MyAIServiceImpl.logger.info("my ai fetch myai info succeeded: id: \(aiInfo.id), name: \(aiInfo.name.encodeMD5()), avatar: \(aiInfo.avatarKey)")
            self.myAIChatterId = aiInfo.id
            exec?()
            updateAIInfoIfNeeded(id: aiInfo.id, name: aiInfo.name, avatarKey: aiInfo.avatarKey)
        }, onError: { error in
            MyAIServiceImpl.logger.error("my ai fetch myai info error, error: \(error)")
            exec?()
        }).disposed(by: self.disposeBag)
    }

    func getMyAIInfo() {
        MyAIServiceImpl.logger.info("my ai begin get myai info")
        var request = RustPB.Contact_V2_GetMyAIChatterRequest()
        request.syncDataStrategy = .local // SDK不支持tryLocal
        self.rustClient?.sendAsyncRequest(request).subscribe(onNext: { [weak self] (response: RustPB.Contact_V2_GetMyAIChatterResponse) in
            guard let `self` = self else { return }
            // 如果本地没有，则SDK会返回空数据
            let aiInfo = response.myAi
            MyAIServiceImpl.logger.info("my ai fetch myai info succeeded: id: \(aiInfo.id), name: \(aiInfo.name), avatar: \(aiInfo.avatarKey)")
            guard !aiInfo.id.isEmpty else {
                MyAIServiceImpl.logger.error("my ai finish get myai info, id is empty")
                return
            }
            self.myAIChatterId = aiInfo.id
            updateAIInfoIfNeeded(id: aiInfo.id, name: aiInfo.name, avatarKey: aiInfo.avatarKey)
        }, onError: { error in
            MyAIServiceImpl.logger.error("my ai get myai info error, error: \(error)")
        }).disposed(by: self.disposeBag)
    }

    /// 监听头像信息变化
    func observableMyAIInfo() {
        (try? self.userResolver.userPushCenter)?.observable(for: PushChatters.self).subscribe(onNext: { [weak self] (pushChatters) in
            guard let `self` = self, !self.myAIChatterId.isEmpty, let chatter = pushChatters.chatters.first(where: { $0.id == self.myAIChatterId }) else { return }
            MyAIServiceImpl.logger.info("my ai observable info change, avatarKey: \(chatter.avatarKey), entityID: \(chatter.id), name: \(chatter.name)")
            updateAIInfoIfNeeded(id: chatter.id, name: chatter.name, avatarKey: chatter.avatarKey)
        }).disposed(by: self.disposeBag)
    }

    /// 判断获取到的 AI 信息是否变化，更新 `AIInfo`
    private func updateAIInfoIfNeeded(id: String, name: String, avatarKey: String) {
        let oldAIInfo = self.info.value
        var newAIInfo: MyAIInfo
        if self.needOnboarding.value {
            // 如果没有完成 Onboarding，使用默认信息
            let defaultResource = self.defaultResource
            newAIInfo = MyAIInfo(id: id,
                                 name: defaultResource.name,
                                 avatarKey: avatarKey,
                                 avatarImage: defaultResource.iconSmall)
            if newAIInfo != oldAIInfo {
                self.info.accept(newAIInfo)
                MyAIServiceImpl.logger.info("update my ai info with default value")
            } else {
                MyAIServiceImpl.logger.info("skip updating my ai info with default value")
            }
        } else {
            newAIInfo = MyAIInfo(id: id,
                                 name: name,
                                 avatarKey: avatarKey,
                                 avatarImage: nil)
            // 以下情况需要拉取头像：
            //   1. AIInfo 不同
            //   2. AIInfo 相同但是之前没拉到头像，
            if newAIInfo != oldAIInfo || oldAIInfo.avatarImage == nil {
                let resource: LarkImageResource = .avatar(key: newAIInfo.avatarKey, entityID: newAIInfo.id)
                LarkImageService.shared.setImage(with: resource, completion: { [weak self] imageResult in
                    guard let self = self else { return }
                    switch imageResult {
                    case .success(let result):
                        MyAIServiceImpl.logger.info("my ai finish loading avatar image")
                        newAIInfo.avatarImage = result.image
                        self.info.accept(newAIInfo)
                    case .failure(let error):
                        MyAIServiceImpl.logger.info("my ai failed loading avatar image, error: \(error)")
                        self.info.accept(newAIInfo)
                    }
                })
                MyAIServiceImpl.logger.info("update my ai info")
            } else {
                MyAIServiceImpl.logger.info("skip updating my ai info")
            }
        }
    }
}

extension MyAIInfo: Equatable {
    public static func == (lhs: MyAIInfo, rhs: MyAIInfo) -> Bool {
        guard lhs.id == rhs.id else { return false }
        guard lhs.name == rhs.name else { return false }
        guard lhs.avatarKey == rhs.avatarKey else { return false }
        return true
    }
}
