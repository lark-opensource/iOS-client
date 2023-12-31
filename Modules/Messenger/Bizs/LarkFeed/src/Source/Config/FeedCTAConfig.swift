//
//  FeedCTAConfig.swift
//  LarkFeed
//
//  Created by Ender on 2023/10/18.
//

import Foundation
import RxSwift
import RustPB
import LarkOpenFeed
import LarkContainer
import LarkSDKInterface
import UniverseDesignToast

final class FeedCTAConfig: FeedCTAConfigService {
    let userResolver: UserResolver
    var loadingMap: Set<FeedCTAInfo> = []
    var disableMap: Set<FeedCTAInfo> = []
    var buttonChangeObservable: Observable<String> {
        return buttonChangeSubject.asObservable()
    }
    let buttonChangeSubject: PublishSubject<String> = PublishSubject()

    let disposeBag = DisposeBag()

    required init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    // 点击按钮时传入按钮信息及另一个按钮需要置灰按钮信息
    func clickWebhookButton(ctaInfo: FeedCTAInfo, anotherCTAInfo: FeedCTAInfo?, from: UIViewController) {
        guard let feedAPI = try? self.userResolver.resolve(assert: FeedAPI.self) else {
            return
        }
        self.changeButton(loadingInfo: ctaInfo, disableInfo: anotherCTAInfo, recover: false)
        feedAPI.appFeedCardButtonCallback(buttonId: ctaInfo.buttonId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                if response.status == .success {
                    var toast = response.toast
                    if toast.isEmpty {
                        toast = BundleI18n.LarkFeed.Lark_Feed_ActionComplete_Fallback_Toast
                    }
                    if let window = from.view.window ?? self.userResolver.navigator.mainSceneWindow {
                        UDToast.showSuccess(with: toast, on: window)
                    }
                } else if response.status == .fail {
                    var toast = response.toast
                    if toast.isEmpty {
                        toast = BundleI18n.LarkFeed.Lark_Feed_ActionFailed_Fallback_Toast
                    }
                    if let window = from.view.window ?? self.userResolver.navigator.mainSceneWindow {
                        UDToast.showFailure(with: toast, on: window)
                    }
                }
                self.changeButton(loadingInfo: ctaInfo, disableInfo: anotherCTAInfo, recover: true)
            }, onError: { [weak self] _ in
                guard let self = self else { return }
                if let window = from.view.window ?? self.userResolver.navigator.mainSceneWindow {
                    UDToast.showFailure(with: BundleI18n.LarkFeed.Lark_Feed_ActionFailed_Fallback_Toast, on: window)
                }
                self.changeButton(loadingInfo: ctaInfo, disableInfo: anotherCTAInfo, recover: true)
            })
            .disposed(by: disposeBag)
    }

    // recover: Bool
    // true 复原按钮（移除 Loading/Disable 态）
    // false 设置按钮（进入 Loading/Disable 态）
    private func changeButton(loadingInfo: FeedCTAInfo, disableInfo: FeedCTAInfo?, recover: Bool) {
        assert(Thread.isMainThread, "UI数据仅支持主线程访问")
        if recover {
            self.loadingMap.remove(loadingInfo)
            if let disableInfo = disableInfo {
                self.disableMap.remove(disableInfo)
            }
        } else {
            self.loadingMap.insert(loadingInfo)
            if let disableInfo = disableInfo {
                self.disableMap.insert(disableInfo)
            }
        }
        self.buttonChangeSubject.onNext((loadingInfo.feedId))
    }

    func isLoading(_ ctaInfo: FeedCTAInfo) -> Bool {
        assert(Thread.isMainThread, "UI数据仅支持主线程访问")
        return loadingMap.contains(ctaInfo)
    }

    func isDisable(_ ctaInfo: FeedCTAInfo) -> Bool {
        assert(Thread.isMainThread, "UI数据仅支持主线程访问")
        return disableMap.contains(ctaInfo)
    }
}
