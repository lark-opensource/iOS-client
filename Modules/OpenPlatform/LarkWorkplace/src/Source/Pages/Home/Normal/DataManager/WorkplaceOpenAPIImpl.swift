//
//  WorkplaceOpenAPIImpl.swift
//  LarkWorkplace
//
//  Created by yinyuan on 2021/2/2.
//

import Foundation
import OPSDK
import LarkOPInterface
import Swinject
import RxRelay
import RxSwift
import LKCommonsLogging
import OPFoundation
import LarkContainer
import AppContainer
import LarkOpenWorkplace

/// 工作台数据服务的实现
final class WorkplaceOpenAPIImpl: WorkplaceOpenAPI {
    static let logger = Logger.log(WorkplaceOpenAPI.self)

    private let pushCenter: PushNotificationCenter
    private let dataManager: AppCenterDataManager

    private var disposeBag = DisposeBag()

    init(pushCenter: PushNotificationCenter, dataManager: AppCenterDataManager) {
        self.pushCenter = pushCenter
        self.dataManager = dataManager

        // 初始化
        setup()
    }

    func queryAppSubTypeInfo(
        appId: String,
        fromCache: Bool,
        success: @escaping (WPAppSubTypeInfo) -> Void,
        failure: @escaping (Error) -> Void
    ) {
        Self.logger.info("queryCommonApp \(appId) fromCache:\(fromCache)")
        DispatchQueue.main.async { [weak self] in
            self?.dataManager.queryAppSubTypeInfo(
                appID: appId,
                fromCache: fromCache,
                success: success,
                failure: failure
            )
        }
    }

    func addCommonApp(
        appIds: [String],
        success: @escaping () -> Void,
        failure: @escaping (Error) -> Void
    ) {
        Self.logger.info("addCommonApp \(appIds)")
        dataManager.addCommonApp(
            appIDs: appIds,
            success: {
                success()
            },
            failure: failure
        )
    }
    func removeCommonApp(
        appId: String,
        success: @escaping () -> Void,
        failure: @escaping (Error) -> Void
    ) {
        Self.logger.info("removeCommonApp \(appId)")
        dataManager.removeCommonApp(
            appID: appId,
            success: {
                success()
            },
            failure: failure
        )
    }

    func reportRecentlyMiniApp(appId: String, path: String) {
        dataManager.reportRecentlyUsedApp(appId: appId, ability: .miniApp, path: path)
    }

    func reportRecentlyWebApp(appId: String) {
        dataManager.reportRecentlyUsedApp(appId: appId, ability: .web)
    }
}

extension WorkplaceOpenAPIImpl {
    /// 初始化
    private func setup() {
        Self.logger.info("WorkPlaceDataServiceImpl setup")

        // 建立数据数据变化监听
        observeDataPushRefresh()

        // 尝试主动拉取最新数据
        fetchWorkplaceData()
    }

    /// 从远端请求最新的数据
    private func fetchWorkplaceData() {
        Self.logger.info("start fecth main page info.")
        dataManager.fetchItemInfoWith(needCache: false) { (_, _) in
            Self.logger.info("fetchItemInfoWith succeed.")
        } failure: { (error) in
            Self.logger.error("fetchItemInfoWith failed.")
        }
    }

    /// 后台支持刷新应用中心
    private func observeDataPushRefresh() {
        // 监听工作台数据远端变化的通知(尚未开始刷新)
        pushCenter.observable(for: WorkplacePushMessage.self)
            /// 让工作台这边的请求先执行，如果已经刷新了数据，考虑下不要再次刷新
            .delay(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                guard let self = self else { return }
                // push 的数据更新时间
                guard let timestamp = Double(message.timestamp) else {
                    Self.logger.error("timestamp invalid.")
                    return
                }
                if self.dataManager.isWorkplaceDataRefreshing {
                    // 工作台正在刷新数据，这里就不需要在重复刷新了
                    Self.logger.info("workplace data is refreshing.")
                    return
                }

                // 最近一次数据刷新时间
                let workplaceDataLastRefreshTime = self.dataManager.workplaceDataLastRefreshTime

                if workplaceDataLastRefreshTime >= timestamp {
                    // 如果已经刷新过数据，这里就不要重复请求了
                    Self.logger.info("workplace data has refreshed.")
                    return
                }

                // 触发一次数据更新
                Self.logger.info("workplace data start fetch")
                self.fetchWorkplaceData()
            }).disposed(by: disposeBag)
    }
}
