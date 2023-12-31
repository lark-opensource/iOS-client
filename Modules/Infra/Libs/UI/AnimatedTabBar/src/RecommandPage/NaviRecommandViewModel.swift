//
//  NaviRecommandViewModel.swift
//  AnimatedTabBar
//
//  Created by ByteDance on 2023/11/24.
//

import UIKit
import Foundation
import RxSwift
import RxRelay
import LarkContainer
import RustPB
import LarkQuickLaunchInterface

typealias NavigationAppInfo = RustPB.Basic_V1_NavigationAppInfo
final class NaviRecommandViewModel {
    var status = PublishSubject<NaviRecommandLoadStatus>()

    let userResolver: UserResolver
    private var quickLaunchService: QuickLaunchService?
    private let disposeBag = DisposeBag()
    /// tools数据回调
    lazy var recommandObservable: Observable<[NavigationAppInfo]> = self.recommandVariable.asObservable()
    private let recommandVariable = BehaviorRelay<[NavigationAppInfo]>(value: [])

    init(userResolver: UserResolver,
         quickLaunchService: QuickLaunchService?) {
        self.userResolver = userResolver
        self.quickLaunchService = quickLaunchService
    }

    func loadRecommandData() {

        self.status.onNext(.loading)
        /// 从服务端加载推荐应用数据
        self.quickLaunchService?.getRecentRecords()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (appInfos) in
                guard let self = self else { return }
                if appInfos.isEmpty {
                    self.status.onNext(.empty)
                } else {
                    self.recommandVariable.accept(appInfos)
                    let status: NaviRecommandLoadStatus = .loadComplete
                    self.status.onNext(status)
                }
                NaviRecommandViewController.logger.info("load recent visit records success count = \(appInfos.count)")
            }, onError: { [weak self] (error) in
                guard let self = self else { return }
                self.status.onNext(.fail(.requestError(error)))
                NaviRecommandViewController.logger.error("load recent visit records error", error: error)
            }).disposed(by: self.disposeBag)
    }
}

public enum NaviRecommandLoadStatus {
    case fail(NaviRecommandRequestError)
    case retry
    case loading
    case loadComplete
    case reload
    case empty
}

public enum NaviRecommandRequestError: Error {
    case searchError(Error)
    case requestError(Error)
}
