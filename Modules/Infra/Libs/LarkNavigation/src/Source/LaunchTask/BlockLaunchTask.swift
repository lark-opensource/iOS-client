//
//  BlockLaunchTask.swift
//  LarkNavigation
//
//  Created by KT on 2020/7/1.
//

import Foundation
import BootManager
import LarkContainer
import RxSwift
import LKCommonsLogging

/**
 登录、切租户，同步请求的接口，会阻塞后面的启动流程
 fastLogin不会走这个任务
 整体3s超时
 */
final class BlockLaunchTask: UserAsyncBootTask, Identifiable {
    static var identify = "BlockLaunchTask"

    static let logger = Logger.log(BlockLaunchTask.self)

    let disposeBag = DisposeBag()

    @ScopedProvider private var navigationConfigService: NavigationConfigService?

    override func execute(_ context: BootContext) {
        BlockLaunchTask.logger.info("start pre launche home check")
        checkNavigationConfig()
            .timeout(.seconds(3), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .catchErrorJustReturn(())
            .subscribe { [weak self] _ in
                self?.end()
        }
        .disposed(by: disposeBag)
    }

    private func checkNavigationConfig() -> Observable<Void> {
        guard let navigationConfigService = self.navigationConfigService,
              navigationConfigService.originalAllTabsinfo == nil else {
            BlockLaunchTask.logger.info("check navigation skip.", additionalData: [
                "hasNavigationInfo": "\(navigationConfigService?.originalAllTabsinfo != nil)"
            ])
            return .just(())
        }

        BlockLaunchTask.logger.debug("pre launchome begin navigation task.")
        return navigationConfigService
            .fetchNavigationInfo()
            .timeout(.seconds(3), scheduler: MainScheduler.instance)
    }
}
