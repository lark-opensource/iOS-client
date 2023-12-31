//
//  MyAIServiceImpl+Onboarding.swift
//  LarkAI
//
//  Created by 李勇 on 2023/10/13.
//

import Foundation
import LarkGuide
import EENavigator
import LarkMessengerInterface
import UniverseDesignToast
import RxSwift
import LarkSDKInterface

/// 把MyAIOnboardingService相关逻辑放这里
public extension MyAIServiceImpl {
    /// 2.判断是否进行过Onboarding
    func getMyAIOnboarding() {
        MyAIServiceImpl.logger.info("my ai begin get myai onboarding")
        self.needOnboarding.accept(self.newGuideManager?.checkShouldShowGuide(key: MyAIServiceImpl.myAIOnboardingGuideKey) ?? false)
        MyAIServiceImpl.logger.info("my ai finish get myai onboarding, onboarding: \(self.needOnboarding.value)")
    }

    /// 判断是否进行过Onboarding，MyAIServiceImpl时机比较早，newGuideManager可能都没有从服务端拉取完成，所以需要fetchMyAIOnboarding进行补拉
    func fetchMyAIOnboarding() {
        MyAIServiceImpl.logger.info("my ai begin fetch myai onboarding")
        self.newGuideManager?.fetchUserGuideInfos { [weak self] in
            guard let `self` = self else { return }
            let needOnboarding = self.newGuideManager?.checkShouldShowGuide(key: MyAIServiceImpl.myAIOnboardingGuideKey) ?? false
            self.needOnboarding.accept(needOnboarding)
            MyAIServiceImpl.logger.info("my ai finish fetch myai onboarding, onboarding: \(needOnboarding)")
            // 如果需要进行Onboarding，则监听Onboarding消费的情况
            if needOnboarding { self.observableMyAIOnboarding() }
        }
    }

    /// 监听Onboarding变化，只关心 true -> false
    func observableMyAIOnboarding() {
        MyAIServiceImpl.logger.info("my ai begin observable myai onboarding")
        (try? self.userResolver.userPushCenter)?.observable(for: PushUserGuideUpdatedMessage.self).subscribe(onNext: { [weak self] (pushGuideData)  in
            guard let `self` = self else { return }
            // 如果当前Onboarding依然是true，则不进行后续操作
            if pushGuideData.pairs.first(where: { $0.orderedInfos.contains(where: { $0.key == MyAIServiceImpl.myAIOnboardingGuideKey }) }) != nil { return }

            MyAIServiceImpl.logger.info("my ai finish observable myai onboarding, change to false")
            // 设置不需要Onboarding，移除监听
            self.needOnboarding.accept(false); self.onboardingDisposeBag = DisposeBag()
        }).disposed(by: self.onboardingDisposeBag)
    }

    func openOnboarding(from: NavigatorFrom,
                               onSuccess: ((_ chatID: Int64) -> Void)?,
                               onError: ((_ error: Error?) -> Void)?,
                               onCancel: (() -> Void)?) {
        MyAIServiceImpl.logger.info("my ai onboarding begin")
        let onboardingBody = MyAIOnboardingBody { [weak self] chatId in
            guard let self = self else { return }
            MyAIServiceImpl.logger.info("my ai onboarding finish, chatId: \(chatId)")
            // Onboarding完后，记录得到的chatId
            self.myAIChatId = chatId
            // Onboarding完后，手动设置已经Onboarding过，让Feed Mock消失
            self.newGuideManager?.didShowedGuide(guideKey: MyAIServiceImpl.myAIOnboardingGuideKey); self.needOnboarding.accept(false)
            // 补拉一次MyAI信息，得到Onboarding设置的头像、名字（Onboarding完服务端应该不会立即给Push）
            if self.myAIChatterId.isEmpty { self.fetchMyAIInfo() }
            onSuccess?(chatId)
        } onError: { [weak self] error in
            MyAIServiceImpl.logger.info("my ai onboarding error: \(error)")
            guard let self = self else { return }
            if let apiError = error?.underlyingError as? APIError, case .myAiAlreadyInitSuccess = apiError.type {
                // 重复 Onboarding，重新拉取信息，并刷新 AI 数据
                self.newGuideManager?.didShowedGuide(guideKey: MyAIServiceImpl.myAIOnboardingGuideKey)
                self.needOnboarding.accept(false)
                self.fetchMyAIInfo()
            }
            onError?(error)

            /* 把重复 Onboarding 当成成功处理（以防 PM 改主意，先注释掉，不删代码）
            if let apiError = error?.underlyingError as? APIError, case .myAiAlreadyInitSuccess = apiError.type {
                MyAIServiceImpl.logger.info("my ai onboarding, already init success, begin fetch chatId")
                self.checkChatterIdAndThen { [weak self] in
                    guard let `self` = self else { return }
                    self.checkChatIdAndThen { [weak self] in
                        guard let `self` = self else { return }
                        // Onboarding完后，手动设置已经Onboarding过，让Feed Mock消失
                        self.newGuideManager.didShowedGuide(guideKey: MyAIServiceImpl.myAIOnboardingGuideKey); self.needOnboarding.accept(false)
                        onSuccess?(self.myAIChatId)
                        MyAIServiceImpl.logger.info("my ai onboarding, already init success, finish fetch chatId: \(self.myAIChatId)")
                    }
                }
                return
            }
            onError?(error)
             */
        } onCancel: {
            MyAIServiceImpl.logger.info("my ai onboarding cancel")
            onCancel?()
        }

        // 提前拉取资源，再打开 Onboarding 页面
        var toast: UDToast?
        if let window = self.userResolver.navigator.mainSceneWindow {
            toast = UDToast.showLoading(on: window)
        }
        MyAIResourceManager.loadResourcesFromSetting(userResolver: self.userResolver, onSuccess: { [weak self] in
            toast?.remove()
            self?.userResolver.navigator.present(body: onboardingBody, from: from, completion: { [weak self] _, _ in
                MyAIServiceImpl.logger.info("my ai onboarding present complete")
                self?.requestingChatModeSet.removeAll()
            })
        }, onFailure: { [weak self] in
            toast?.remove()
            MyAIServiceImpl.logger.info("my ai onboarding loadResources fail")
            self?.requestingChatModeSet.removeAll()
        })
    }

    /// 检测是否进行过Onboarding，然后再执行后续动作
    func checkOnboardingAndThen(from: NavigatorFrom, exec: @escaping () -> Void) {
        // 从GuideService中重新获取一次，内部会实时更新；这里只是为了兜底：其他端Onboarding完成，observableMyAIOnboarding没有收到Push
        self.needOnboarding.accept(self.newGuideManager?.checkShouldShowGuide(key: MyAIServiceImpl.myAIOnboardingGuideKey) ?? false)

        MyAIServiceImpl.logger.info("my ai begin check onboarding")
        // 如果已经Onboarding过，直接执行后续动作
        if !self.needOnboarding.value {
            MyAIServiceImpl.logger.info("my ai finish check onboarding, already onboarding")
            exec()
            return
        }

        // 如果确认没有进行过Onboarding，则进行Onboarding
        MyAIServiceImpl.logger.info("my ai finish check onboarding, need onboarding, begin onboarding")
        // error、cancel不用处理，不会走后续逻辑
        self.openOnboarding(from: from, onSuccess: { _ in
            exec()
        }, onError: nil, onCancel: nil)
    }
}
