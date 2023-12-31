//
//  MockNaviagitonAPI.swift
//  Minutes_Example
//
//  Created by lvdaqian on 2021/5/13.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import RustPB
import LarkNavigation
import LarkTab
import LKCommonsLogging
import RxSwift
import AnimatedTabBar
import LarkAccountInterface
import LarkRustClient

//class NavigationAPIImpl: NavigationAPI {
//
//    static private let logger = Logger.log(NavigationAPIImpl.self, category: "Navigation")
//
//    var mainTabs: [Tab] = [.feed, .minutes]
//    var quickTabs: [Tab] = []
//
//    private let client: RustService
//
//    init(client: RustService) {
//        self.client = client
//    }
//
//    func noticeRustSwitchTab(tabKey: String) -> Observable<Void> {
//        var request = RustPB.Behavior_V1_TabActivatedRequest()
//        request.tabKey = tabKey
//        return client.sendAsyncRequest(request).subscribeOn(scheduler)
//    }
//
//    func getNavigationInfo(firstPage: Int? = nil, fullData: Bool = true) -> Observable<AllNavigationInfoResponse> {
//        var response = NavigationAppInfoResponse()
//        let mapFunction = { (tab: Tab) -> Basic_V1_NavigationAppInfo in
//            var appinfo = Basic_V1_NavigationAppInfo()
//            appinfo.key = tab.key
//            if let appId = tab.appid, let infoID = Int64(appId) {
//                appinfo.id = infoID
//            }
//            return appinfo
//        }
//
//        response.platform = .navMobile
//        response.primaryCount = Int32(mainTabs.count)
//        response.totalCount = Int32(mainTabs.count + quickTabs.count)
//
//        response.appInfo = mainTabs.map(mapFunction) + quickTabs.map(mapFunction)
//
//        var batch = NavigationAppInfoBatchResponse()
//        batch.responses = [response]
//
//        let info = AllNavigationInfoResponse(response: batch)
//        return .just(info)
//    }
//
//    func modifyNavigationOrder(tabbarStyle: TabbarStyle, mainItems: [AbstractRankItem], quickItems: [AbstractRankItem]) -> Observable<NavigationInfoResponse> {
//        mainTabs = mainItems.map { $0.tab }
//        quickTabs = quickItems.map { $0.tab }
//        return getNavigationInfo().map { $0.bottom }
//    }
//}

