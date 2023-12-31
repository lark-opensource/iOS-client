//
//  SpaceRecentListAutoRefresher.swift
//  SKSpace
//
//  Created by Weston Wu on 2022/5/19.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SKCommon

class SpaceRecentListAutoRefresher: SpaceListAutoRefresher {
    private weak var listProvider: SpaceRefresherListProvider?
    private var bag = DisposeBag()
    var actionHandler: NotifyRefreshHandler?
    // 拉取间隔，单位 s
    let refreshInterval: Double
    private var lastRefreshTime: Date?

    init(listProvider: SpaceRefresherListProvider, refreshInterval: Int) {
        self.listProvider = listProvider
        self.refreshInterval = Double(refreshInterval)
    }

    func setup() {
        if UserScopeNoChangeFG.MJ.newRecentListRefreshStrategy {
            //新的云文档tab刷新策略，仅在切换tab时刷新列表
            NotificationCenter.default.rx
                .notification(.SpaceTabItemTapped)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] notification in
                    guard let userInfo = notification.userInfo,
                          let isSameTab = userInfo[SpaceTabItemTappedNotificationKey.isSameTab] as? Bool,
                          !isSameTab else {
                        return
                    }
                    self?.fetchList()
                })
                .disposed(by: bag)
        } else {
            // 监听 tabAppear 和 进前台事件
            NotificationCenter.default.rx.notification(.SpaceTabDidAppear)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    DocsLogger.info("space.recent.refresher --- fetch list when switch to space tab")
                    self.fetchList()
                })
                .disposed(by: bag)

            NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    DocsLogger.info("space.recent.refresher --- fetch list when enter foreground")
                    self.fetchList()
                })
                .disposed(by: bag)
        }
    }

    func start() {}

    func stop() {}

    func notifySyncEvent() {}

    func notifyFileDeleted(token: FileListDefine.ObjToken) {}

    private func fetchList() {
        guard let listProvider = listProvider else {
            return
        }
        
        if UserScopeNoChangeFG.MJ.newRecentListRefreshStrategy {
            listProvider.fetchCurrentList(size: RecentListDataModel.recentListPageCount) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(dataDiff):
                    self.handle(dataDiff: dataDiff)
                case let .failure(error):
                    DocsLogger.error("space.recent.refresher --- fetch list failed", error: error)
                }
            }
        } else {
            if let lastRefreshTime = lastRefreshTime {
                let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshTime)
                guard timeSinceLastRefresh > refreshInterval else {
                    // 刷新间隔不满足 config 配置，忽略
                    return
                }
            }
            // 触发时更新下时间戳
            lastRefreshTime = Date()

            listProvider.fetchCurrentList(size: RecentListDataModel.recentListPageCount) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(dataDiff):
                    self.handle(dataDiff: dataDiff)
                case let .failure(error):
                    DocsLogger.error("space.recent.refresher --- fetch list failed", error: error)
                }
            }
        }
    }

    private func handle(dataDiff: FileDataDiff) {
        guard let listProvider = listProvider else {
            return
        }
        let serverTokenList = dataDiff.recentObjs.map(\.token)
        let currentTokenList = listProvider.listEntries.map(\.objToken)
        // 新版刷新策略FG开，切换tab过来后无条件刷新最近列表
        let showTips = UserScopeNoChangeFG.MJ.newRecentListRefreshStrategy ? false : serverTokenList != currentTokenList
        let clickHandler: RefreshActionHandler = { callback in
            callback(.success(dataDiff))
        }
        actionHandler?(clickHandler, showTips)
    }
}
