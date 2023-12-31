//
//  NavigationAPI.swift
//  LarkSDKInterface
//
//  Created by Meng on 2019/10/20.
//

import Foundation
import RxSwift
import AnimatedTabBar
import RustPB
import LarkTab

public protocol NavigationAPI {
    /// 通知Rust切换Tab
    func noticeRustSwitchTab(tabKey: String) -> Observable<Void>
    func getNavigationInfo(firstPage: Int?, fullData: Bool) -> Observable<AllNavigationInfoResponse>
    func modifyNavigationOrder(tabbarStyle: TabbarStyle, mainTabItems: [AbstractTabBarItem], quickTabItems: [AbstractTabBarItem]) -> Observable<NavigationInfoResponse>
    func modifyNavigationOrder(tabbarStyle: TabbarStyle, mainItems: [AbstractRankItem], quickItems: [AbstractRankItem]) -> Observable<NavigationInfoResponse>

    /// 创建最近访问记录
    func createRecentVisitRecord(appInfo: RustPB.Basic_V1_NavigationAppInfo) -> Observable<Void>
    /// 拉取最近访问列表
    func getRecentVisitRecords() -> Observable<Settings_V1_GetRecentVisitListResponse>
    /// 新增最近使用记录
    func createRecentUsedRecord(appInfo: RustPB.Basic_V1_NavigationAppInfo) -> Observable<Void>
    /// 删除最近使用记录
    func deleteRecentUsedRecord(uniqueId: String) -> Observable<Void>
    /// 拉取最近使用记录
    func getRecentUsedRecord(cursor: Int, count: Int) -> Observable<Settings_V1_GetRecentUsedRecordResponse>
    /// Pin应用到主导航
    func pinAppToNavigation(appInfo: RustPB.Basic_V1_NavigationAppInfo, style: TabbarStyle) -> Observable<Settings_V1_PinNavigationAppResponse>
    /// 删除导航应用
    func unpinNavigationApp(appId: String, bizType: NavigationAppBizType, style: TabbarStyle) -> Observable<Settings_V1_UnPinNavigationAppResponse>
    /// 查询应用是否存在于导航
    func findAppExistInNavigation(appId: String, bizType: NavigationAppBizType, style: TabbarStyle) -> Observable<Bool>
    /// 获取全量导航
    func getNavigationApps() -> Observable<Settings_V1_GetNavigationAppsResponse>
    /// 新增临时区域记录
    func createTemporaryRecord(appInfo: RustPB.Basic_V1_NavigationAppInfo) -> Observable<String>
    /// 删除临时区域记录
    func deleteTemporaryRecord(uniqueIds: [String]) -> Observable<Void>
    /// 拉取临时区域记录
    func getTemporaryRecord(cursor: Int, count: Int) -> Observable<Settings_V1_GetTemporaryRecordResponse>
    /// 更新临时区域记录
    func modifyTemporaryRecord(appInfos: [RustPB.Basic_V1_NavigationAppInfo]) -> Observable<[String]>
    /// 更新应用的信息
    func updateNavigationInfos(appInfos: [RustPB.Basic_V1_NavigationAppInfo]) -> Observable<Void>
}
