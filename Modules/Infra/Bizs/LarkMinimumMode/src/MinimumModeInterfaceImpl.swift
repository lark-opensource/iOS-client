//
//  MinimumModeInterfaceImpl.swift
//  LarkMinimumMode
//
//  Created by zc09v on 2021/5/7.
//

import Foundation
import RxSwift
import LarkContainer
import LarkGuide
import LarkStorage

final class MinimumModeInterfaceImpl: MinimumModeInterface, UserResolverWrapper {
    @ScopedInjectedLazy private var minimumApi: MinimumModeAPI?
    @ScopedInjectedLazy var newGuideService: NewGuideService?

    let userResolver: UserResolver
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    private let disposeBag: DisposeBag = DisposeBag()

    func putDeviceMinimumMode(_ inMinimumMode: Bool, fail: ((Error) -> Void)?) {
        minimumApi?.putDeviceMinimumMode(inMinimumMode)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {
                KVPublic.Core.minimumMode.setValue(inMinimumMode)
                DispatchQueue.main.async {
                    exit(0)
                }
            }, onError: { error in
                fail?(error)
        }).disposed(by: self.disposeBag)
    }

    func showMinimumModeChangeTip(show: () -> Void) {
        let guideKey = "mobile_basic_mode"
        let inMinimum: Bool = KVPublic.Core.minimumMode.value()
        let shouldShowGuide = newGuideService?.checkShouldShowGuide(key: guideKey) ?? false
        // 需要展示guide,同时当前不在基本模式下
        guard shouldShowGuide, !inMinimum else {
            return
        }
        newGuideService?.didShowedGuide(guideKey: guideKey)
        show()
    }

    func forceChangModeIfNeeded(showTip: @escaping (_ finish: @escaping () -> Void) -> Void) {
        minimumApi?.pullDeviceMinimumMode()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { inMinimumModel in
                // 如果远端与本地状态不一致，以远端为准
                if inMinimumModel != KVPublic.Core.minimumMode.value() {
                    KVPublic.Core.minimumMode.setValue(inMinimumModel)
                    showTip({
                        DispatchQueue.main.async {
                            exit(0)
                        }
                    })
                }
        }, onError: { (_) in
        }).disposed(by: self.disposeBag)
    }
}
