//
//  QuickLaunchService.swift
//  LarkQuickLaunchInterface
//
//  Created by Hayden Wang on 2023/5/30.
//

import LarkTab
import RxSwift
import RustPB

/// 通过 QuickLaunchService 可以访问 Launcher 的功能
public protocol QuickLaunchService {

    var isQuickLauncherEnabled: Bool { get }
    func showQuickLaunchWindow(from: MyAIQuickLaunchBarInterface?)
    func dismissQuickLaunchWindow(animated: Bool, completion: (() -> Void)?)
    func getRecentRecords() -> Observable<([RustPB.Basic_V1_NavigationAppInfo])>
    func addRecentRecords(vc: TabContainable)
    func removeRecentRecords(by id: String)
    func pinToQuickLaunchWindow(id: String,
                                tabBizID: String,
                                tabBizType: CustomBizType,
                                tabIcon: CustomTabIcon,
                                tabTitle: String,
                                tabURL: String,
                                tabMultiLanguageTitle: [String: String]) -> Observable<Settings_V1_PinNavigationAppResponse>
    func pinToQuickLaunchWindow(vc: TabContainable) -> Observable<Settings_V1_PinNavigationAppResponse>
    func pinToQuickLaunchWindow(tab: TabCandidate) -> Observable<Settings_V1_PinNavigationAppResponse>
    func unPinFromQuickLaunchWindow(vc: TabContainable) -> Observable<Settings_V1_UnPinNavigationAppResponse>
    func unPinFromQuickLaunchWindow(appId: String, tabBizType: CustomBizType) -> Observable<Settings_V1_UnPinNavigationAppResponse>
    func findInQuickLaunchWindow(vc: TabContainable) -> Observable<Bool>
    func findInQuickLaunchWindow(appId: String, tabBizType: CustomBizType) -> Observable<Bool>
    func getNavigationApps() -> Observable<Settings_V1_GetNavigationAppsResponse>
    func getNavigationErrorMessage(error: Error) -> (Int32, String)
    func updateNavigationInfos(appInfos: [RustPB.Basic_V1_NavigationAppInfo]) -> Observable<Void>
    func getNavigationAppIcon(appType: AppType, key: String) -> UIImage?
    func generateAppUniqueId(bizType: CustomBizType, appId: String) -> String
}
