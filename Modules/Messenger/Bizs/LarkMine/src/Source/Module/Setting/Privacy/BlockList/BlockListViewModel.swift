//
//  BlockListViewModel.swift
//  LarkMine
//
//  Created by 姚启灏 on 2020/7/26.
//

import Foundation
import LarkModel
import LarkContainer
import LarkSDKInterface
import LarkMessengerInterface
import LKCommonsLogging
import RxSwift
import RxCocoa
import RustPB
import EENavigator

// 定义第一页的光标
private let firstPageCursor: String = "0"

final class BlockListViewModel {
    private let logger = Logger.log(BlockListViewModel.self)

    public let userNavigator: Navigatable
    private let configAPI: ConfigurationAPI
    public let monitor: SetContactInfomationMonitorService

    // 默认传入第一页
    private var cursor: String = firstPageCursor

    // 是否可以下拉加载更多
    var hasMore: Bool = false

    var dataSource: [RustPB.Contact_V2_BlockUser] = []

    var isFirstPage: Bool {
        return self.cursor == firstPageCursor
    }

    private var dispostBag: DisposeBag = DisposeBag()

    init(userNavigator: Navigatable, configAPI: ConfigurationAPI, monitor: SetContactInfomationMonitorService) {
        self.userNavigator = userNavigator
        self.configAPI = configAPI
        self.monitor = monitor
    }

    private let refreshPublish: PublishSubject<Void> = PublishSubject<Void>()
    var refreshDriver: Driver<()> {
        return refreshPublish.asDriver(onErrorJustReturn: ())
    }

    private let errorPublish: PublishSubject<Void> = PublishSubject<Void>()
    var errorDriver: Driver<()> {
        return errorPublish.asDriver(onErrorJustReturn: ())
    }

    func deleteUserByID(_ id: String) -> Observable<Void> {
        return configAPI
            .deleteBlockUserByID(id)
            .observeOn(MainScheduler.instance)
            .do(onDispose: { [weak self] () in
                guard let `self` = self else { return }
                self.dataSource = self.dataSource.filter({
                    return $0.userID != id
                })
                self.delPrivacySettingBlockUser()
            })
    }

    func fetchFristPageData() {
        self.cursor = firstPageCursor
        self.fetchData()
    }

    func fetchData() {
        self.logger.info("[LarkMine]{block user list}-get block user list \(self.cursor)")
        configAPI.getBlockUserListRequest(cursor: self.cursor)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
            // 如果当前请求的是第一页的数据 移除之前的数据
            if let currentCursor = self?.cursor, currentCursor == firstPageCursor {
                self?.dataSource.removeAll()
            }
            self?.cursor = response.cursor
            self?.hasMore = response.hasMore_p
            if !response.userInfos.isEmpty {
                self?.dataSource += response.userInfos
            }
                self?.logger.info("[LarkMine]{block user list}-get block user list success: \(response.userInfos.map { $0.userID }), hasMore: \(response.hasMore_p), cursor: \(response.cursor)")
            self?.refreshPublish.onNext(())
        }, onError: { [weak self] in
            self?.logger.error("[LarkMine]{block user list}-get block user list error: \($0.localizedDescription)")
            self?.errorPublish.onNext(())
        }).disposed(by: self.dispostBag)
    }

    private func delPrivacySettingBlockUser() {
        MineTracker.trackSettingPrivacyBlockDelete()
    }
}
