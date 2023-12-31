//
//  MagicShareRuntimeImpl+Active.swift
//  ByteView
//
//  Created by liurundong.henry on 2021/7/29.
//

import Foundation
import RxSwift

extension MagicShareRuntimeImpl {

    /// 判断App前后台状态
    func bindActive() {
        Util.runInMainThread { [weak self] in
            // 一些系统提示框显示时，是inactive状态，此时底部文档依然显示，需要正常同步数据
            self?.isApplicationActiveSubject.onNext(UIApplication.shared.applicationState != .background)
        }

        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .map { _ in true }
            .bind(to: isApplicationActiveSubject.asObserver())
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .map { _ in false }
            .bind(to: isApplicationActiveSubject.asObserver())
            .disposed(by: disposeBag)
    }

}
