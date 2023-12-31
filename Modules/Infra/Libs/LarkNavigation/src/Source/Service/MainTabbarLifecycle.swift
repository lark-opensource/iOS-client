//
//  MainTabbarLifecycle.swift
//  LarkNavigation
//
//  Created by 袁平 on 2020/3/27.
//

import Foundation
import RxSwift

final class MainTabbarLifecycleImp: TabbarLifecycle {
    private let tabDidAppearPublish = PublishSubject<Void>()
    var onTabDidAppear: Observable<Void> {
        return tabDidAppearPublish.asObservable()
    }

    func fireTabDidAppear() {
        tabDidAppearPublish.onNext(())
    }
}
