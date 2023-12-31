//
//  WorkPlaceDataManager.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/6/11.
//

// 文件过长，注意精简
// swiftlint:disable file_length

import Foundation
import LKCommonsLogging
import SwiftyJSON
import RxSwift
import LarkOPInterface
import Swinject
import OPSDK
import ECOProbeMeta
import LarkWorkplaceModel
import LarkOpenWorkplace

// MARK: 业务接口
extension AppCenterDataManager {

    /// 批量拉取 badge 开关状态列表
    func getAppBadgeSettings(
        pageSize: Int = 50,
        pageToken: String?,
        success: @escaping (_ model: AppBadgeSettingModel) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        Self.logger.info("start to fetch app badge setting page info")
        // 闭包过长，注意精简
        // swiftlint:disable closure_body_length
        DispatchQueue.global().async {
            let monitorEvent = OPMonitor(AppCenterMonitorEvent.op_app_badge_setting_list).timing()
            self.requestAppBadgeSettingsInfo(
                pageSize: pageSize,
                pageToken: pageToken,
                success: { [weak self] json in
                    // 此处使用json["data"].self是希望把错误收敛到buildDataModel内部
                    guard let model = self?.buildDataModel(
                            with: json["data"].self,
                            type: AppBadgeSettingModel.self
                          ) else {
                        DispatchQueue.main.async {
                            Self.logger.error(
                                "fetch app badge setting info successed but parse model failed"
                            )
                            let errorMessage = "build model failed with code"
                            let error = NSError(
                                domain: "getAppBadgeSettings",
                                code: AppCenterDataManager.defaultErrCode,
                                userInfo: [NSLocalizedDescriptionKey: errorMessage]
                            )
                            monitorEvent
                                .setResultTypeFail()
                                .setError(error)
                                .flush()
                            failure(error)
                        }
                        return
                    }
                    /// 获取数据成功，执行结束
                    DispatchQueue.main.async {
                        Self.logger.info("fetch app badge setting page info success")
                        var badgeSettingBrief = [[String: Any]]()
                        if let items = model.items {
                            for item in items {
                                badgeSettingBrief.append([
                                    "appId": item.clientID,
                                    "status": item.needShow
                                ])
                            }
                        }
                        monitorEvent
                            .setResultTypeSuccess()
                            .addCategoryValue("badge_setting_brief", badgeSettingBrief)
                            .flush()
                        success(model)
                    }
                },
                failure: { error in
                    DispatchQueue.main.async {
                        Self.logger.error("fetch app badge setting info failed")
                        monitorEvent
                            .setResultTypeFail()
                            .setError(error)
                            .flush()
                        failure(error)
                    }
                }
            )
        }
        // swiftlint:enable closure_body_length
    }

    /// 更改 badge 开关状态
    func updateAppBadgeStatus(
        appID: String,
        shouldShow: Bool,
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        Self.logger.info("start to update app badge status")
        DispatchQueue.global().async { [weak self] in
            self?.requestToUpdateAppBadgeStatus(
                appID: appID,
                shouldShow: shouldShow,
                success: { _ in
                    /// 获取数据成功，执行结束
                    DispatchQueue.main.async {
                        Self.logger.info("update app badge status success")
                        success()
                    }
                    self?.dependency.badge.update(appID: appID, badgeEnable: shouldShow)
                    self?.dependency.badge.pull(appID: appID)
                },
                failure: { error in
                    DispatchQueue.main.async {
                        Self.logger.error("update app badge status failed with error(\(error)")
                        failure(error)
                    }
                }
            )
        }
    }

    /// 获取工作台排序页数据
    /// - Parameters:
    ///   - needCache: 是否需要缓存数据（true：读取缓存，若请求失败时返回缓存数据，不执行failure回调）
    ///   - success: 成功回调（业务方通过「isFromCache」判断数据是否来缓存
    ///   - failure: 失败回调
    func fetchRankPageInfoWith(
        needCache: Bool = true,
        success: @escaping (_ model: WorkPlaceRankPageViewModel, _ isFromCache: Bool) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        Self.logger.info("start to fetch rank page info")
        // 闭包过长，注意精简
        // swiftlint:disable closure_body_length
        DispatchQueue.global().async {
            // 1. 如果需要cache从本地拉取数据，若成功则进行success回调，继续执行2.
            var readCacheFail: Bool = true
            if needCache {
                if let model = self.getInfoFromCache(
                    cacheKey: WPCacheKey.favoriteApps,
                    type: WorkPlaceRankPageViewModel.self
                ) {
                    Self.logger.info("rank page hit cache")
                    DispatchQueue.main.async {
                        success(model, true)
                        readCacheFail = false
                    }
                } else {
                    Self.logger.info("rank page miss cache")
                }
            }
            /// 2. 异步从远程拉取数据，成功则进行model构造，继续执行3.
            let rankPageReqMonitor = WPMonitor().timing()
            self.requestWorkPlaceRankPageInfo(
                success: { [weak self] (json) in
                    rankPageReqMonitor.setCode(WPMCode.workplace_rank_page_request_success)
                        .postSuccessMonitor(endTiming: true)
                    // 此处使用json["data"].self是希望把错误收敛到buildDataModel内部
                    let rankModelBuild = OPMonitor(WPMWorkplaceCode.workplace_rank_page_model_build_error).timing()
                    guard let model = self?.buildDataModel(
                        with: json["data"].self,
                        type: WorkPlaceRankPageViewModel.self
                    ) else {
                        Self.logger.error("build rank page model failed, fetch exit")
                        let error = NSError(
                            domain: WPMWorkplaceCode.workplace_rank_page_model_build_error.domain,
                            code: WPMWorkplaceCode.workplace_rank_page_model_build_error.code,
                            userInfo: [NSLocalizedDescriptionKey: "build model failed with code"]
                        )
                        if readCacheFail {
                            Self.logger.info(
                                "requst rankPage info successed but parse model failed, no cache data"
                            )
                            failure(error)
                        } else {    // 使用可用缓存，不回调failed
                            Self.logger.info(
                                "requst rankPage info successed but parse model failed, use cache data"
                            )
                        }
                        rankModelBuild.timing().setError(error).flush()
                        return
                    }
                    rankModelBuild.timing().setResultTypeSuccess().flush()
                    /// 3. 远程拉取成功则进行数据持久化
                    self?.setInfoToCache(cacheKey: WPCacheKey.favoriteApps, model: model)
                    /// 4. 获取数据成功，执行结束
                    DispatchQueue.main.async {
                        Self.logger.info("fetch rank page info success")
                        success(model, false)
                    }
                },
                failure: { (error) in
                    Self.logger.error("fetch rank page info failed")
                    DispatchQueue.main.async {
                        if readCacheFail {
                            Self.logger.info("requst rankPage info failed, no cache data")
                            failure(error)
                        } else {    // 使用可用缓存，不回调failed
                            Self.logger.info("requst rankPage info failed, use cache data")
                        }
                    }
                    rankPageReqMonitor.setCode(WPMCode.workplace_rank_page_request_error)
                        .setError(errMsg: error.localizedDescription, error: error)
                        .postFailMonitor()
                }
            )
        }
        // swiftlint:enable closure_body_length
    }

    /// 回传工作台排序页的排序结果
    /// - Parameters:
    ///   - updateData: 要更新的rank数据
    ///   - cacheModel: 需要缓存的model数据，nil则不缓存
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func updateCommonList(
        updateData: UpdateRankResult,
        cacheModel: WorkPlaceRankPageViewModel?,
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        Self.logger.info("start to update rank page result")
        let updateSuccess = OPMonitor(WPMCode.workplace_update_common_item_success).timing()
        let updateFail = OPMonitor(WPMCode.workplace_update_common_item_fail).timing()
        DispatchQueue.global().async {
            // 异步发送网络请求，成功则回调success
            self.postUpdateRankInfo(
                data: updateData,
                success: { [weak self] () in
                    DispatchQueue.main.async {
                        Self.logger.info("update rank page data success")
                        if let model = cacheModel {
                            self?.setInfoToCache(cacheKey: WPCacheKey.favoriteApps, model: model)
                        }
                        success()
                        updateSuccess.timing().flush()
                    }
                },
                failure: { (error) in
                    Self.logger.error("update rank page data failed", error: error)
                    DispatchQueue.main.async {
                        failure(error)
                        updateFail.timing().setError(error).flush()
                    }
                }
            )
        }
    }

    /// 获取工作台分类页面数据
    /// - Parameters:
    ///   - needCache: 是否需要缓存数据（true：读取缓存，若请求失败时返回缓存数据，不执行failure回调）
    ///   - success: 成功回调（业务方通过「isFromCache」判断数据是否来缓存
    ///   - failure: 失败回调
    func fetchCategoryInfo(
        needCache: Bool = true,
        success: @escaping (_ model: WPSearchCategoryApp, _ isFromCache: Bool) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        // 闭包过长，注意精简
        // swiftlint:disable closure_body_length
        DispatchQueue.global().async {
            // 1. 如果需要cache从本地拉取数据，若成功则进行success回调，继续执行2.
            let categoryReq = WPMonitor().timing()
            var readCacheFail: Bool = true
            if needCache {
                if let model = self.getInfoFromCache(
                    cacheKey: WPCacheKey.categoryPage,
                    type: WPSearchCategoryApp.self
                ) {
                    Self.logger.info("category page hit cache")
                    DispatchQueue.main.async {
                        success(model, true)
                        readCacheFail = false
                    }
                } else {
                    Self.logger.info("cotegory page miss cache")
                }
            }
            // 2. 异步从远程拉取数据，成功则进行model构造，继续执行3.
            self.requestWPCategoryInfoWith(
                // 闭包过长，注意精简
                // swiftlint:disable closure_body_length
                success: { [weak self] (json) in
                    categoryReq.setCode(WPMCode.workplace_category_search_request_success)
                        .postSuccessMonitor(endTiming: true)   // 请求成功，上报埋点
                    // 此处使用json["data"].self是希望把错误收敛到buildDataModel内部
                    let modelType = WPSearchCategoryApp.self
                    let pageModelBuildError = OPMonitor(WPMWorkplaceCode.workplace_category_page_model_build_error)
                        .timing()
                    guard let model = self?.buildDataModel(with: json["data"].self, type: modelType) else {
                        Self.logger.error("build \(modelType) model failed, fetch data exit")
                        let error = NSError(
                            domain: WPMWorkplaceCode.workplace_category_page_model_build_error.domain,
                            code: WPMWorkplaceCode.workplace_category_page_model_build_error.code,
                            userInfo: [NSLocalizedDescriptionKey: "build \(modelType) model failed with code"]
                        )
                        if readCacheFail {
                            Self.logger.info(
                                "requst Category info successed but parse model failed, no cache data"
                            )
                            failure(error)
                        } else {    // 使用可用缓存，不回调failed
                            Self.logger.info(
                                "requst Category info successed but parse model failed, use cache data"
                            )
                        }
                        pageModelBuildError.timing().setError(error).flush()
                        return
                    }
                    /// 3. 远程拉取成功则进行数据持久化
                    self?.setInfoToCache(cacheKey: WPCacheKey.categoryPage, model: model)
                    /// 4. 获取数据成功，执行结束
                    DispatchQueue.main.async {
                        Self.logger.info("fetch cotegory page info success")
                        success(model, false)
                    }
                },
                // swiftlint:enable closure_body_length
                failure: { (error) in
                    Self.logger.error("fetch cotegory page info failed")
                    categoryReq.setCode(WPMCode.workplace_category_search_request_error)
                        .setError(errMsg: error.localizedDescription, error: error)
                        .postFailMonitor()
                    DispatchQueue.main.async {
                        if readCacheFail {
                            Self.logger.info("requst Category info failed, no cache data")
                            failure(error)
                        } else {    // 使用可用缓存，不回调failed
                            Self.logger.info("requst Category info failed, use cache data")
                        }
                    }
                }
            )
        }
        // swiftlint:enable closure_body_length
    }

    /// 查询工作台指定分类/搜索的应用信息
    /// - Parameters:
    ///   - query: 查询关键字，不为空则是搜索
    ///   - tagId: 搜索/查询的tagId, 为空就搜全部tag
    ///   - success: 成功回调
    ///   - failure: 失败回调
    ///
    /// 说明: query和tagId非正交，可组合查询
    func fetchCategorySearchWith(
        query: String = "",
        tagId: String = "",
        success: @escaping (_ model: WPSearchCategoryApp) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        // 闭包过长，注意精简
        // swiftlint:disable closure_body_length
        DispatchQueue.global().async {
            // 请求获取搜索/分类结果
            let searchReq = WPMonitor().timing()
            self.requestWPCategorySearch(
                query: query,
                tagId: tagId,
                success: { [weak self] (json) in
                    // 请求成功，上报埋点
                    searchReq.setCode(WPMCode.workplace_category_page_request_success)
                        .postSuccessMonitor(endTiming: true)
                    // 请求成功，构造model
                    let modelType = WPSearchCategoryApp.self
                    guard let model = self?.buildDataModel(with: json["data"].self, type: modelType) else {
                        Self.logger.error("build \(modelType) model failed, fetch exit")
                        let error = NSError(
                            domain: WPMWorkplaceCode.workplace_category_search_model_build_error.domain,
                            code: WPMWorkplaceCode.workplace_category_search_model_build_error.code,
                            userInfo: [NSLocalizedDescriptionKey: "build model failed with code"]
                        )
                        failure(error)
                        return
                    }
                    //  构造model成功，执行结束
                    DispatchQueue.main.async {
                        Self.logger.info("fetch category search info success")
                        success(model)
                    }
                },
                failure: { (error) in
                    Self.logger.error("fetch category search info failed")
                    searchReq.setCode(WPMCode.workplace_category_page_request_error)
                        .setError(errMsg: error.localizedDescription, error: error)
                        .postFailMonitor()
                    DispatchQueue.main.async {
                        failure(error)
                        searchReq.timing()
                            .setError(errMsg: error.localizedDescription, error: error)
                            .postFailMonitor()
                    }
                }
            )
        }
        // swiftlint:enable closure_body_length
    }
    /// 工作台-添加常用应用
    /// - Parameters:
    ///   - itemIds: 要添加的常用应用Id列表(与 appIDs 二选一)
    ///   - appIDs: 要添加的常用应用appID列表(与 itemIds 二选一)
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func addCommonApp(
        itemIds: [String]? = nil,
        appIDs: [String]? = nil,
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        assert((itemIds != nil || appIDs != nil), "you should provide itemIds or appIDs")
        DispatchQueue.global().async {
            // 异步发送网络请求，成功则回调success
            let addCommonReqMonitor = WPMonitor().timing()
            self.postAddCommonAppInfo(
                itemIds: itemIds,
                appIDs: appIDs,
                success: {
                    DispatchQueue.main.async {
                        Self.logger.info("add common app success")
                        success()
                        addCommonReqMonitor.setCode(WPMCode.workplace_add_common_app_request_success)
                            .postSuccessMonitor(endTiming: true)
                    }
                },
                failure: { (error) in
                    Self.logger.error("add common app failed", error: error)
                    DispatchQueue.main.async {
                        failure(error)
                        addCommonReqMonitor.setCode(WPMCode.workplace_add_common_app_request_error)
                            .setError(errMsg: "add common app request failed", error: error)
                            .postFailMonitor()
                    }
                }
            )
        }
    }
    /// 工作台-删除常用应用
    /// - Parameters:
    ///   - itemId: 要删除的常用应用的ID(与 appID 二选一)
    ///   - appID: 要删除的常用应用的appID(与 itemId 二选一)
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func removeCommonApp(
        itemId: String? = nil,
        appID: String? = nil,
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        DispatchQueue.global().async {
            // 异步发送网络请求，成功则回调success
            let removeCommonReqMonitor = WPMonitor().timing()
            self.postRemoveCommonAppInfo(
                itemId: itemId,
                appID: appID,
                success: {
                    DispatchQueue.main.async {
                        Self.logger.info("remove common app success")
                        success()
                        removeCommonReqMonitor.setCode(WPMCode.workplace_remove_common_app_request_success)
                            .postSuccessMonitor(endTiming: true)
                    }
                },
                failure: { (error) in
                    Self.logger.error("remove common app failed", error: error)
                    DispatchQueue.main.async {
                        failure(error)
                        removeCommonReqMonitor.setCode(WPMCode.workplace_remove_common_app_request_error)
                            .setError(errMsg: "remove common app request failed", error: error)
                            .postFailMonitor()
                    }
                }
            )
        }
    }

    /// 工作台-查询常用应用
    /// - Parameters:
    ///   - appID: 要查询的常用应用的appID
    ///   - fromCache: 是否直接缓存中读取
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func queryAppSubTypeInfo(
        appID: String,
        fromCache: Bool,
        success: @escaping (_ info: WPAppSubTypeInfo) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        // 闭包过长，注意精简
        // swiftlint:disable closure_body_length
        DispatchQueue.global().async {
            // 从缓存中直接读取
            if fromCache {
                var isUserCommon = false
                var isUserDistributedRecommend = false
                var isUserRecommend = false
                if let model = self.getWidgetHomeModelFromCache() {
                    // 找到对应的 item
                    if let itemInfo = model.allItemInfos.values.first { (itemInfo) -> Bool in
                        itemInfo.appId == appID
                    } {
                        // 找到对应的常用应用
                        if model.rspModel?.data.tagList.contains(where: { (tag) -> Bool in
                            tag.children?.contains(where: { (children) -> Bool in
                                children.itemId == itemInfo.itemId && children.subType == .common
                            }) == true
                        }) == true {
                            Self.logger.info("AppCenter: AppCenter commonApp hit cache")
                            isUserCommon = true
                        }
                        if model.rspModel?.data.tagList.contains(where: { (tag) -> Bool in
                            tag.children?.contains(where: { (children) -> Bool in
                                children.itemId == itemInfo.itemId && children.subType == .deletableRecommend
                            }) == true
                        }) == true {
                            isUserDistributedRecommend = true
                        }
                        if model.rspModel?.data.tagList.contains(where: { (tag) -> Bool in
                            tag.children?.contains(where: { (children) -> Bool in
                                children.itemId == itemInfo.itemId && children.subType == .recommend
                            }) == true
                        }) == true {
                            isUserRecommend = true
                        }
                    }
                }
                let info = WPAppSubTypeInfo(
                    isUserCommon: isUserCommon,
                    isUserDistributedRecommend: isUserDistributedRecommend,
                    isUserRecommend: isUserRecommend
                )
                DispatchQueue.main.async {
                    success(info)
                }
                return
            }

            // 异步发送网络请求，成功则回调success
            let queryCommonReq = WPMonitor().timing()
            self.postQueryCommonAppInfo(
                appID: appID,
                success: { (isUserCommon) in
                    DispatchQueue.main.async {
                        Self.logger.info("query common app success")
                        success(isUserCommon)
                        queryCommonReq.setCode(WPMCode.workplace_update_common_item_success)
                            .postSuccessMonitor(endTiming: true)
                    }
                },
                failure: { (error) in
                    Self.logger.error("query common app failed", error: error)
                    DispatchQueue.main.async {
                        failure(error)
                        queryCommonReq.setCode(WPMCode.workplace_update_common_item_fail)
                            .setError(errMsg: "query common app request failed", error: error)
                            .postFailMonitor()
                    }
                }
            )
        }
        // swiftlint:enable closure_body_length
    }

    /// 获取子tag info
    func requestItemsWithSubTag(
        subtagID: Int,
        success: @escaping (_ model: SubTagItemInfo) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        // 闭包过长，注意精简
        // swiftlint:disable closure_body_length
        DispatchQueue.global().async {
            let buildSubTagFail = OPMonitor(WPMWorkplaceCode.workplace_get_sub_tag_model_build_fail).timing()
            let requestSubTagReq = WPMonitor().timing()
            self.requestSubTagItems(
                subtagID: subtagID,
                success: { [weak self] (json) in
                    guard let self = self else {
                        Self.logger.error("build subtaginfo model self released")
                        return
                    }
                    /// 解析返回数据，构造Model失败
                    guard let model = self.buildDataModel(
                          with: json["data"].self,
                          type: SubTagItemInfo.self
                        ) else {
                        Self.logger.error("build subtaginfo model failed, fetch exit")
                        let error = NSError(
                            domain: WPMWorkplaceCode.workplace_rank_page_model_build_error.domain,
                            code: WPMWorkplaceCode.workplace_rank_page_model_build_error.code,
                            userInfo: [NSLocalizedDescriptionKey: "build model failed with code"]
                        )
                        failure(error)
                        buildSubTagFail.timing()
                            .setError(error)
                            .flush()
                        return
                    }
                    /// 成功回调
                    DispatchQueue.main.async {
                        success(model)
                        requestSubTagReq.setCode(WPMCode.workplace_get_sub_tag_request_success)
                            .postSuccessMonitor(endTiming: true)
                    }
                },
                failure: { (error) in
                    DispatchQueue.main.async {
                        failure(error)
                    }
                    requestSubTagReq.setCode(WPMCode.workplace_get_sub_tag_request_fail)
                        .setError(error: error)
                        .postFailMonitor()
                }
            )
        }
        // swiftlint:enable closure_body_length
    }

    /// 拉取运营配置
    /// - Parameters:
    ///   - isOnboarding: 是否为 onboarding 用户，默认为老用户
    func fetchOperationConfig(
        isOnboarding: Bool = false,
        success: @escaping (_ model: WorkPlaceOperationModel) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        // 闭包过长，注意精简
        // swiftlint:disable closure_body_length
        DispatchQueue.global().async {
            let operationConfigReq = WPMonitor().timing()
            self.getOperationActivity(
                isOnboarding: isOnboarding,
                success: { [weak self] (json) in
                    // 请求成功，构造model
                    let modelType = WorkPlaceOperationModel.self
                    guard let model = self?.buildDataModel(with: json["data"].self, type: modelType) else {
                        Self.logger.error("build \(modelType) model failed, fetch exit")
                        let error = OPError.error(
                            monitorCode: WPMCode.workplace_get_operational_config_fail.wp_mCode,
                            userInfo: ["reason": "build model failed with \(json)"]
                        )
                        failure(error)
                        return
                    }
                    //  构造model成功，执行结束
                    DispatchQueue.main.async {
                        Self.logger.info("fetch operation config success")
                        success(model)
                        operationConfigReq.setCode(WPMCode.workplace_get_operational_config_success)
                            .postSuccessMonitor(endTiming: true)
                    }
                },
                failure: { (error) in
                    Self.logger.error("fetch operation config failed")
                    DispatchQueue.main.async {
                        failure(error)
                        operationConfigReq.setCode(WPMCode.workplace_get_operational_config_fail)
                            .setError(error: error)
                            .postFailMonitor()
                    }
                }
            )
        }
        // swiftlint:enable closure_body_length
    }
}

// MARK: 网络请求
extension AppCenterDataManager {
    /// 批量拉取 badge 开关状态列表
    private func requestAppBadgeSettingsInfo(
        pageSize: Int,
        pageToken: String?,
        success: @escaping (_ json: JSON) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        /// 发起请求
        Self.logger.info(
            "start to request requestAppBadgeSettingsInfo data from remote via network"
        )
        let context = WPNetworkContext(injectInfo: .cookie, trace: self.traceService.currentTrace)
        var params: [String: String] = [:]
        params["page_size"] = "\(pageSize)"
        if let lastPageToken = pageToken {
            params["page_token"] = lastPageToken
        }
        networkService.request(
            WPGetAppBadgeSettingConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { (json) in
            if json["code"].int == 0 {  // 请求成功
                Self.logger.info(
                    "requestAppBadgeSettingsInfo request data via network successed"
                )
                success(json)
            } else {
                Self.logger.error(
                    "requestAppBadgeSettingsInfo request data via network failed",
                    additionalData: [
                        "code": "\(String(describing: json["code"].int))"
                    ]
                )
                failure(
                    NSError(
                        domain: "getAppBadgeSettings",
                        code: AppCenterDataManager.defaultErrCode,
                        userInfo: [
                            NSLocalizedDescriptionKey: "network request failed with code: \(json["code"].intValue)"
                        ]
                    )
                )
            }
        }, onError: { (err) in          // 请求出错
            Self.logger.error(
                "requestAppBadgeSettingsInfo request data via network failed",
                error: err
            )
            failure(err)
        })
        .disposed(by: disposeBag)
    }

    /// 更改 badge 开关状态
    private func requestToUpdateAppBadgeStatus(
        appID: String,
        shouldShow: Bool,
        success: @escaping (_ json: JSON) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        /// 请求配置信息
        var localAuthorizations: [String: Any] = [:]
        var scopeInfo: [String: Any] = [:]
        scopeInfo["auth"] = shouldShow
        // 时间戳单位取毫秒
        let timeInterval = Int64(Date().timeIntervalSince1970 * 1000)
        scopeInfo["modifyTime"] = timeInterval
        localAuthorizations["appBadge"] = scopeInfo
        /// 发起请求
        Self.logger.info("start to request updateAppBadgeStatus data from remote via network")
        let context = WPNetworkContext(injectInfo: .cookie, trace: traceService.currentTrace)
        var params: [String: Any] = [
            "appVersion": WPUtils.appVersion,
            "appID": appID,
            "userAuthScope": localAuthorizations
        ]
        if let session = userService.user.sessionKey {
            params["sessionID"] = session
        } else {
            Self.logger.error("updateAppBadgeStatus get user sessionKey failed")
        }
        networkService.request(
            WPUpdateBadgeStatusConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { json in
            if json["error"].int == 0 {  // 请求成功
                Self.logger.info("updateAppBadgeStatus request data via network successed")
                success(json)
            } else {
                Self.logger.error(
                    "updateAppBadgeStatus request data via network failed",
                    additionalData: [
                        "json": "\(json)",
                        "code": "\(json["error"].int)"
                    ]
                )
                failure(
                    NSError(
                        domain: "updateAppBadgeStatus",
                        code: AppCenterDataManager.defaultErrCode,
                        userInfo: [
                            NSLocalizedDescriptionKey: "network request failed with code: \(json["code"].intValue)"
                        ]
                    )
                )
            }
        }, onError: { (err) in          // 请求出错
            Self.logger.error(
                "updateAppBadgeStatus request data via network failed",
                error: err
            )
            failure(err)
        })
        .disposed(by: disposeBag)
    }

    /// 请求工作台排序页面的数据
    /// - Parameters:
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func requestWorkPlaceRankPageInfo(
        success: @escaping (_ json: JSON) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        /// 发起请求
        Self.logger.info("start to request data from remote via network")
        
        let context = WPNetworkContext(injectInfo: .session, trace: traceService.currentTrace)
        let params: [String: Any] = [
            "needWidget": true,
            "needBlock": true
        ].merging(WPGeneralRequestConfig.legacyParameters) { $1 }
        networkService.request(
            WPRankPageConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { (json) in
            if json["code"].int == 0 {  // 请求成功
                Self.logger.info("request data via network successed")
                success(json)
            } else {
                Self.logger.error(
                    "request data via network failed",
                    additionalData: [
                        "code": "\(json["code"].int)"
                    ]
                )
                failure(
                    NSError(
                        domain: WPMWorkplaceCode.workplace_rank_page_request_error.domain,
                        code: WPMWorkplaceCode.workplace_rank_page_request_error.code,
                        userInfo: [
                            NSLocalizedDescriptionKey: "network request failed with code: \(json["code"].intValue)"
                        ]
                    )
                )
            }
        }, onError: { (err) in          // 请求出错
            Self.logger.error("request data via network failed", error: err)
            failure(err)
        })
        .disposed(by: disposeBag)
    }
    /// 网络请求更新rank的数据
    /// - Parameters:
    ///   - updateData: rank数据
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func postUpdateRankInfo(
        data: UpdateRankResult,
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        /// 发起请求
        Self.logger.info("start to update rank data to remote via network")
        let context = WPNetworkContext(injectInfo: .session, trace: traceService.currentTrace)
        let params: [String: Any] = [
            "newCommonWidgetItemList": data.newCommonWidgetItemList,
            "originCommonWidgetItemList": data.originCommonWidgetItemList,
            "newCommonIconItemList": data.newCommonIconItemList,
            "originCommonIconItemList": data.originCommonIconItemList,
            "newDistributedRecommendItemList": data.newDistributedRecommendItemList,
            "originDistributedRecommendItemList": data.originDistributedRecommendItemList
        ]
        networkService.request(
            WPUpdateCommonItemConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { (json) in
            if json["code"].int == 0 {  // 请求成功
                Self.logger.info("request data via network successed")
                success()
            } else {
                Self.logger.error(
                    "request data via network failed",
                    additionalData: [
                        "code": "\(String(describing: json["code"].int))"
                    ]
                )
                failure(
                    NSError(
                        domain: WPMWorkplaceCode.workplace_rank_page_request_error.domain,
                        code: WPMWorkplaceCode.workplace_rank_page_request_error.code,
                        userInfo: [
                            NSLocalizedDescriptionKey: "network request failed with code: \(json["code"].intValue)"
                        ]
                    )
                )
            }
        }, onError: { (err) in          // 请求出错
            Self.logger.error("request data via network failed", error: err)
            failure(err)
        })
        .disposed(by: disposeBag)
    }
    /// 请求工作台分类页面的数据
    /// - Parameters:
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func requestWPCategoryInfoWith(
        success: @escaping (_ json: JSON) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        /// 发起请求
        Self.logger.info("start to request data from remote via network")
        let context = WPNetworkContext(injectInfo: .session, trace: self.traceService.currentTrace)
        let params: [String: Any] = [
            "needWidget": true,
            "needBlock": true
        ].merging(WPGeneralRequestConfig.legacyParameters) { $1 }
        networkService.request(
            WPGetTagsAndRecentAppsConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { (json) in
            if json["code"].int == 0 {  // 请求成功
                Self.logger.info("request data via network successed")
                success(json)
            } else {
                Self.logger.error(
                    "request data via network failed",
                    additionalData: [
                        "code": "\(String(describing: json["code"].int))",
                        "msg": "\(json["msg"].stringValue)"
                    ]
                )
                failure(
                    NSError(
                        domain: WPMCode.workplace_category_page_request_error.domain,
                        code: WPMCode.workplace_category_page_request_error.code,
                        userInfo: [
                            NSLocalizedDescriptionKey: "network request failed with code: \(json["code"].intValue)"
                        ]
                    )
                )
            }
        }, onError: { (err) in
            // 请求出错
            Self.logger.error("request data via network failed", error: err)
            failure(err)
        })
        .disposed(by: disposeBag)
    }
    /// 网络请求-查询工作台指定分类/搜索的应用信息
    /// - Parameters:
    ///   - query: 查询关键字，不为空则是搜索
    ///   - tagId: 搜索/查询的tagId, 为空就搜全部tag
    ///   - success: 成功回调
    ///   - failure: 失败回调
    ///
    /// 说明: query和tagId非正交，可组合查询
    func requestWPCategorySearch(
        query: String = "",
        tagId: String = "",
        success: @escaping (_ json: JSON) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        /// 发起请求
        Self.logger.info("start to request data from remote via network")
        let context = WPNetworkContext(injectInfo: .session, trace: self.traceService.currentTrace)
        let params: [String: Any] = [
            "query": query,
            "tagId": tagId,
            "needWidget": true,
            "needBlock": true
        ].merging(WPGeneralRequestConfig.legacyParameters) { $1 }
        networkService.request(
            WPSearchItemByTagConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { (json) in
            if json["code"].int == 0 {  // 请求成功
                Self.logger.info("request data via network successed")
                success(json)
            } else {
                Self.logger.error(
                    "request data via network failed",
                    additionalData: [
                        "code": "\(String(describing: json["code"].int))"
                    ]
                )
                failure(
                    NSError(
                        domain: WPMCode.workplace_category_search_request_error.domain,
                        code: WPMCode.workplace_category_search_request_error.code,
                        userInfo: [
                            NSLocalizedDescriptionKey: "network request failed with code: \(json["code"].intValue)"
                        ]
                    )
                )
            }
        }, onError: { (err) in
            // 请求出错
            Self.logger.error("request data via network failed", error: err)
            failure(err)
        })
        .disposed(by: disposeBag)
    }
    /// 工作台网路请求-添加常用应用
    /// - Parameters:
    ///   - itemIds: 要添加的常用应用Id列表(与 appIDs 二选一)
    ///   - appIDs: 要添加的常用应用appID列表(与 itemIds 二选一)
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func postAddCommonAppInfo(
        itemIds: [String]?,
        appIDs: [String]?,
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        // 发起请求
        Self.logger.info("start to add common app synchronizing to remote via network")
        let context = WPNetworkContext(injectInfo: .cookie, trace: self.traceService.currentTrace)
        var params: [String: Any] = [:]
        if let itemIds = itemIds {
            params["itemIds"] = itemIds
        }
        if let appIds = appIDs {
            params["appIds"] = appIds
        }
        networkService.request(
            WPAddCommonAppConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { (json) in
            if json["code"].int == 0 {  // 请求成功
                Self.logger.info("synchronize data via network successed")
                success()
            } else {
                Self.logger.error(
                    "synchronize data via network failed",
                    additionalData: [
                        "code": "\(json["code"].int)"
                    ]
                )
                failure(
                    NSError(
                        domain: WPMCode.workplace_add_common_app_request_error.domain,
                        code: WPMCode.workplace_add_common_app_request_error.code,
                        userInfo: [
                            NSLocalizedDescriptionKey: "network request failed with code: \(json["code"].intValue)"
                        ]
                    )
                )
            }
        }, onError: { (err) in          // 请求出错
            Self.logger.error("synchronize data via network failed", error: err)
            failure(err)
        })
        .disposed(by: disposeBag)
    }
    /// 工作台网路请求-删除常用应用
    /// - Parameters:
    ///   - itemId: 要删除的常用应用的ID(与 appID 二选一)
    ///   - appID: 要删除的常用应用的appID(与 itemId 二选一)
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func postRemoveCommonAppInfo(
        itemId: String?,
        appID: String?,
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        // 发起请求
        Self.logger.info(
            "start to remove common item synchronizing to remote via network",
            additionalData: [
                "itemId": "\(String(describing: itemId))",
                "appID": "\(String(describing: appID))"
            ]
        )
        let context = WPNetworkContext(injectInfo: .cookie, trace: traceService.currentTrace)
        let params: [String: Any]
        if let itemId = itemId {
            params = ["itemId": itemId]
        } else if let appId = appID {
            params = ["appId": appId]
        } else {
            params = [:]
        }
        networkService.request(
            WPRemoveCommonItemConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { (json) in
            if json["code"].int == 0 {  // 请求成功
                Self.logger.info("synchronize data via network successed")
                success()
            } else {
                Self.logger.error(
                    "synchronize data via network failed",
                    additionalData: [
                        "code": "\(String(describing: json["code"].int))"
                    ]
                )
                failure(
                    NSError(
                        domain: WPMCode.workplace_add_common_app_request_error.domain,
                        code: WPMCode.workplace_add_common_app_request_error.code,
                        userInfo: [
                            NSLocalizedDescriptionKey: "network request failed with code: \(json["code"].intValue)"
                        ]
                    )
                )
            }
        }, onError: { (err) in
            // 请求出错
            Self.logger.error("synchronize data via network failed", error: err)
            failure(err)
        })
        .disposed(by: disposeBag)
    }
    /// 工作台网路请求-查询常用应用
    /// - Parameters:
    ///   - appID: 要查询的常用应用的appID
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func postQueryCommonAppInfo(
        appID: String,
        success: @escaping (_ info: WPAppSubTypeInfo) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        // 发起请求
        Self.logger.info("start to query common app(\(appID)) synchronizing to remote via network")
        let context = WPNetworkContext(injectInfo: .cookie, trace: self.traceService.currentTrace)
        networkService.request(
            WPQueryCommonAppConfig.self,
            params: ["appId": appID],
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { (json) in
            if json["code"].int == 0 {  // 请求成功
                Self.logger.info("synchronize data via network successed")
                let info = WPAppSubTypeInfo(
                    isUserCommon: json["data"]["isUserCommon"].boolValue,
                    isUserDistributedRecommend: json["data"]["isUserDistributedRecommend"].boolValue,
                    isUserRecommend: json["data"]["isUserRecommend"].boolValue
                )
                success(info)
            } else {
                Self.logger.error(
                    "synchronize data via network failed",
                    additionalData: [
                        "code": "\(String(describing: json["code"].int))"
                    ]
                )
                let codeInfo = WPMWorkplaceCode.workplace_query_common_app_request_error
                let monitorCode = OPMonitorCode(
                    domain: codeInfo.domain,
                    code: codeInfo.code,
                    level: codeInfo.level,
                    message: codeInfo.message
                )
                failure(monitorCode.error(message: "network request failed with code: \(json["code"].intValue)"))
            }
        }, onError: { (err) in          // 请求出错
            Self.logger.error("synchronize data via network failed", error: err)
            failure(err)
        })
        .disposed(by: disposeBag)
    }
    /// 工作台新应用-清除标记
    /// - Parameters:
    ///   - itemId: 要清除的应用的ItemID
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func postCleanNewApp(
        itemId: String,
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        // 发起请求
        Self.logger.info("start to clean new app(\(itemId)) flag")
        let context = WPNetworkContext(injectInfo: .cookie, trace: self.traceService.currentTrace)
        networkService.request(
            WPCleanNewAppFlagConfig.self,
            params: ["itemId": itemId],
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { (json) in
            if json["code"].int == 0 {  // 请求成功
                Self.logger.info("synchronize clean new app via network successed")
                success()
            } else {
                Self.logger.error(
                    "synchronize clean new app via network failed",
                    additionalData: [
                        "code": "\(String(describing: json["code"].int))"
                    ]
                )
            }
        }, onError: { (err) in          // 请求出错
            Self.logger.error("synchronize clean new app via network failed", error: err)
            failure(err)
        })
        .disposed(by: disposeBag)
    }

    /// 请求子tag数据（全部应用下的分类应用）
    private func requestSubTagItems(
        subtagID: Int,
        success: @escaping (_ json: JSON) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        /// 这种一次性的数据拉取，RxSwif比URLSession或者TokenNetworking不知道低到哪里去了
        Self.logger.info("subtagreq: start requestSubTagItems \(subtagID)")
        let context = WPNetworkContext(injectInfo: .cookie, trace: self.traceService.currentTrace)
        let params: [String: Any] = [
            "needWidget": true,
            "needBlock": true,
            "subTagId": subtagID
        ].merging(WPGeneralRequestConfig.legacyParameters) { $1 }
        networkService.request(
            WPSubTagItemsConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { (json) in
            if json["code"].int == 0 {
                success(json)
                Self.logger.info("subtagreq: requestSubTagItems successed: \(Date().timeIntervalSince1970)")
            } else {
                let errCodeInfo = WPMCode.workplace_get_sub_tag_request_fail
                let error = NSError(
                    domain: errCodeInfo.domain,
                    code: errCodeInfo.code,
                    userInfo: [NSLocalizedDescriptionKey: json.description]
                )
                failure(error)
                Self.logger.error("subtagreq: from remote failed: \(error.localizedDescription)")
            }
        }, onError: { (error) in
            Self.logger.error("subtagreq: from remote failed: \(error.localizedDescription)")
            failure(error)
        })
        .disposed(by: disposeBag)
    }
    /// 工作台一键安装应用
    /// - Parameters:
    ///   - appIds: 要添加的常用应用Id列表
    ///   - success: 成功回调
    ///   - failure: 失败回调
    func postInstallAppInfo(
        appIds: [String],
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        // 发起请求
        Self.logger.info("start to install app Asynchronizing to remote via network")
        let context = WPNetworkContext(injectInfo: .cookie, trace: self.traceService.currentTrace)
        let params: [String: Any] = [
            "timeOffset": WorkplaceTool.currentTimeZoneOffset(),
            "apps": appIds
        ]
        networkService.request(
            WPAsyncInstallAppConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { (json) in
            if json["code"].int == 0 {  // 请求成功
                Self.logger.info("postInstallAppInfo synchronize data via network successed")
                success()
            } else {
                // 返回异常
                // swiftlint:disable line_length
                Self.logger.error("postInstallAppInfo synchronize data via network failed with code: \(String(describing: json["code"].int))")
                // swiftlint:enable line_length
                failure(
                    NSError(
                        domain: "onBoarding.postInstallAppInfo",
                        code: json["code"].intValue,
                        userInfo: ["msg": json["msg"].stringValue]
                    )
                )
            }
        }, onError: { (err) in
            // 请求出错
            Self.logger.error(
                "postInstallAppInfo synchronize data via network failed",
                error: err
            )
            failure(err)
        })
        .disposed(by: disposeBag)
    }
    /// 运营状态更新值
    enum OperationState: String {
        /// 跳过安装
        case skipInstall = "SkipInstall"
        /// 关闭运营活动
        case closeOperationalActivity = "CloseOperationalActivity"
        /// 关闭一键安装应用
        case closeOperationalApps = "CloseOperationalApps"
    }
    /// 工作台拉取运营配置
    /// - Parameters:
    ///   - isOnboarding: 是否为 onboarding 用户，默认为老用户
    ///   - success: 成功回调
    ///   - failure: 失败回调
    private func getOperationActivity(
        isOnboarding: Bool,
        success: @escaping (_ json: JSON) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        // 发起请求
        Self.logger.info("start to install app Asynchronizing to remote via network")
        let context = WPNetworkContext(injectInfo: .cookie, trace: self.traceService.currentTrace)
        let params: [String: Any] = ["isOnboarding": isOnboarding]
            .merging(WPGeneralRequestConfig.legacyParameters) { $1 }
        networkService.request(
            WPGetOperationSettingsConfig.self,
            params: params,
            context: context
        )
        .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .subscribe(onSuccess: { (json) in
            if json["code"].int == 0 {  // 请求成功
                Self.logger.info("getOperationActivity synchronize data via network successed \(json)")
                success(json)
            } else {
                // swiftlint:disable line_length
                Self.logger.error("getOperationActivity synchronize data via network failed with code: \(String(describing: json["code"].int))")
                // swiftlint:enable line_length
                let error = OPError.error(
                    monitorCode: WPMCode.workplace_get_operational_config_fail.wp_mCode,
                    userInfo: ["reason": "response data failed with \(json)"]
                )
                failure(error)
            }
        }, onError: { (err) in          // 请求出错
            Self.logger.error(
                "getOperationActivity synchronize data via network failed",
                error: err
            )
            failure(err)
        })
        .disposed(by: disposeBag)
    }
}

extension AppCenterDataManager {
    /// Query app list in a certain category
    ///
    /// - Parameters:
    ///   - category: Category name
    ///   - disposeBag: RxSwift disposeBag, release resources when view controller is destoryed.
    ///   - success: Request success callback
    ///   - failure: Request failed callback
    func asyncQueryApps(
        in category: String,
        disposeBag: DisposeBag,
        success: @escaping (_ model: WPSearchCategoryApp) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        asyncQueryApps(with: "", in: category, disposeBag: disposeBag, success: success, failure: failure)
    }

    /// Query app list with keywords
    ///
    /// - Parameters:
    ///   - keyword: Query keyword
    ///   - disposeBag: RxSwift disposeBag, release resources when view controller is destoryed.
    ///   - success: Request success callback
    ///   - failure: Request failed callback
    func asyncQueryApps(
        with keyword: String,
        disposeBag: DisposeBag,
        success: @escaping (_ model: WPSearchCategoryApp) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        asyncQueryApps(with: keyword, in: "", disposeBag: disposeBag, success: success, failure: failure)
    }

    /// Send request for app list query
    ///
    /// - Parameters:
    ///   - keyword: Query keyword
    ///   - category: Category name
    ///   - disposeBag: RxSwift disposeBag, release resources when view controller is destoryed.
    ///   - success: Request success callback
    ///   - failure: Request failed callback
    private func asyncQueryApps(
        with keyword: String,
        in category: String,
        disposeBag: DisposeBag,
        success: @escaping (_ model: WPSearchCategoryApp) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        let context = WPNetworkContext(injectInfo: .session, trace: traceService.currentTrace)
        let params = WPSearchCategoryAppRequestParams(
            query: keyword,
            tagId: category,
            larkVersion: WPUtils.appVersion,
            locale: WorkplaceTool.curLanguage(),
            needWidget: true,
            needBlock: true
        )
        networkService.request(
            WPSearchItemByTagCodableConfig.self,
            params: params,
            context: context
        )
        .subscribeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
        .observeOn(MainScheduler.instance)
        .subscribe(
            onSuccess: { [weak self] (dataModel) in
                guard let innerModel = dataModel.data, dataModel.code == 0 else {
                    WPMonitor().setTrace(self?.traceService.currentTrace)
                        .setCode(WPMCode.workplace_category_page_request_error)
                        .setError(errMsg: dataModel.message ?? "")
                        .flush()
                    failure(NSError(
                        domain: WPMCode.workplace_category_page_request_error.domain,
                        code: WPMCode.workplace_category_page_request_error.code))
                    return
                }
                WPMonitor().setTrace(self?.traceService.currentTrace)
                    .setCode(WPMCode.workplace_category_page_request_success)
                    .flush()
                success(innerModel)
            },
            onError: { [weak self] (err) in
                WPMonitor().setTrace(self?.traceService.currentTrace)
                    .setCode(WPMCode.workplace_category_page_request_error)
                    .setError(err)
                    .flush()
                failure(err)
            }
        ).disposed(by: disposeBag)
    }

    /// Report recently used app (not custom link)
    ///
    /// - Parameters:
    ///   - appId: App identifier
    ///   - ability: Application ability, different open strategy
    ///   - path: Sub path of mini-app (eg: "Approval" template - "Purchase" app)
    func reportRecentlyUsedApp(appId: String, ability: WPAppItem.AppAbility, path: String = "") {
        var additionData = ["appId": "\(appId)", "ability": "\(ability)", "path": "\(path)"]
        Self.logger.info("start report recently used app", additionalData: additionData)
        let requestParams = WPAppOpenedRequestParams(appId: appId, abilityType: ability, path: path)
        var disposeBag = DisposeBag()

        let context = WPNetworkContext(injectInfo: .session, trace: traceService.currentTrace)
        networkService
            .request(WPAppOpenedConfig.self, params: requestParams, context: context)
            .asObservable()
            .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
            .subscribe(
                onNext: { dataModel in
                    guard dataModel.code == 0 else {
                        additionData["errMsg"] = dataModel.message
                        Self.logger.error("report failed", additionalData: additionData)
                        return
                    }
                    Self.logger.info("report success", additionalData: additionData)
                },
                onError: { err in
                    additionData["error"] = "\(err)"
                    Self.logger.error("report failed", additionalData: additionData)
                },
                onCompleted: {
                    disposeBag = DisposeBag()
                }
            ).disposed(by: disposeBag)
    }

    /// Report recently used custom link
    ///
    /// - Parameter itemId: Item identifier
    func reportRecentlyUsedCustomLink(itemId: String) {
        var additionData = ["itemId": "\(itemId)"]
        Self.logger.info("start report recently used link", additionalData: additionData)
        let requestParams = WPCustomLinkOpenedRequestParams(itemId: itemId)
        var disposeBag = DisposeBag()
        let context = WPNetworkContext(injectInfo: .session, trace: traceService.currentTrace)
        networkService
            .request(WPLinkItemOpenedConfig.self, params: requestParams, context: context)
            .asObservable()
            .observeOn(ConcurrentDispatchQueueScheduler(queue: .global()))
            .subscribe(
                onNext: { dataModel in
                    guard dataModel.code == 0 else {
                        additionData["errMsg"] = dataModel.message
                        Self.logger.error("report failed", additionalData: additionData)
                        return
                    }
                    Self.logger.info("report success", additionalData: additionData)
                },
                onError: { err in
                    additionData["error"] = "\(err)"
                    Self.logger.error("report failed", additionalData: additionData)
                },
                onCompleted: {
                    disposeBag = DisposeBag()
                }
            ).disposed(by: disposeBag)
    }

    func shareBlockByMessageCard(
        params: WPShareBlockByMessageCardRequestParams,
        success: @escaping () -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        var additionData = ["itemId": "\(params.itemId)", "receivers": "\(params.receivers)"]
        Self.logger.info("send share block request", additionalData: additionData)
        var disposeBag = DisposeBag()
        let context = WPNetworkContext(injectInfo: .session, trace: traceService.currentTrace)
        networkService
            .request(WPShareBlockItemByMessageCardConfig.self, params: params, context: context)
            .asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { dataModel in
                    if dataModel.code == 10025, let failedReceivers = dataModel.data?.failedReceivers,
                       failedReceivers.count < params.receivers.count {
                        // 部分发送失败，按成功处理
                        additionData["errCode"] = "\(dataModel.code)"
                        additionData["errMsg"] = dataModel.message
                        Self.logger.warn("some receiver failed to share", additionalData: additionData)
                        success()
                    } else if dataModel.code == 0 {
                        // 全部发送成功
                        Self.logger.info("share block success", additionalData: additionData)
                        success()
                    } else {
                        // 全部发送失败
                        additionData["errCode"] = "\(dataModel.code)"
                        additionData["errMsg"] = dataModel.message
                        Self.logger.error("share block failed", additionalData: additionData)
                        failure(NSError(domain: "share block failed", code: -1))
                    }
                },
                onError: { err in
                    additionData["error"] = "\(err)"
                    Self.logger.error("share block failed", additionalData: additionData)
                    failure(err)
                },
                onCompleted: {
                    disposeBag = DisposeBag()
                }
            ).disposed(by: disposeBag)
    }
}

// swiftlint:enable file_length
