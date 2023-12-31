//
//  CalendarSearchViewModel.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/9/5.
//

import Foundation
import LarkFoundation
import LKCommonsLogging
import UIKit
import LarkModel
import LarkUIKit
import LarkTag
import RxSwift
import LarkCore
import UniverseDesignToast
import EENavigator
import LarkSDKInterface
import LarkMessengerInterface
import LarkSceneManager
import LarkAppLinkSDK
import LarkSearchCore
import LarkContainer

struct CalendarSearchRenderDataModel: Codable {
    // 时间相关的单位都是ms
    var id: String?
    var eventServerId: String?
    var startTime: Int64?
    var endTime: Int64?
    var crossDayNo: Int64?
    var crossDaySum: Int64?
    var crossDayStartTime: Int64?
    var crossDayEndTime: Int64?
    var owner: String?
    var selfAttendeeStatus: Int64?
    var eventColorIndex: Int64?
    var calendarColorIndex: Int64?
    var isAllDay: Bool?
    var calendarType: Int64?
    var startTimezone: String?
    var isCrossTenant: Bool?
    var creator: String?
    var calendarId: String?
    var key: String?
    var originalTime: Int64?
    var summary: String?
    var attendee: String?
    var chatName: String?
    var organizer: String?
    var appLink: String?
    var resource: String?
    var location: String?
    var description: String?

    var crossDayStartDate: Date? {
        guard let _crossDayStartTime = crossDayStartTime else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(Double(_crossDayStartTime) / 1000.0))
    }

    var crossDayEndDate: Date? {
        guard let _crossDayEndTime = crossDayEndTime else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(Double(_crossDayEndTime) / 1000.0))
    }

    var crossDayStartIsToday: Bool? {
        return crossDayStartDate?.isToday
    }

    var crossDayStartIsInFuture: Bool? {
        return crossDayStartDate?.isInFuture
    }
}

final class CalendarSearchDayTitleViewModel: SearchCellViewModel {
    // 本身不是一个日程数据，只是包含了这一天的第一个日程的结果
    let searchResult: SearchResultType
    let renderDataModel: CalendarSearchRenderDataModel

    var searchClickInfo: String { return "" }

    var resultTypeInfo: String { return "SearchCalendarTitle" }
    let userResolver: UserResolver

    init(userResolver: UserResolver, searchResult: SearchResultType, renderDataModel: CalendarSearchRenderDataModel) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.renderDataModel = renderDataModel
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        return nil
    }

    /// 返回支持 iPad 多 scene 场景的拖拽能力
    func supportDragScene() -> Scene? {
        return nil
    }

    func supprtPadStyle() -> Bool {
        return UIDevice.btd_isPadDevice() && isPadFullScreenStatus(resolver: userResolver)
    }
}

// 分割线cellViewModel 无实际含义,searchResult 与下一个cell一致
final class CalendarSearchDividingLineViewModel: SearchCellViewModel {
    let searchResult: SearchResultType

    var searchClickInfo: String { return "" }

    var resultTypeInfo: String { return "SearchCalendarDividingLine" }

    let userResolver: UserResolver

    init(userResolver: UserResolver, searchResult: SearchResultType) {
        self.userResolver = userResolver
        self.searchResult = searchResult
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        return nil
    }

    /// 返回支持 iPad 多 scene 场景的拖拽能力
    func supportDragScene() -> Scene? {
        return nil
    }

    func supprtPadStyle() -> Bool {
        return UIDevice.btd_isPadDevice() && isPadFullScreenStatus(resolver: userResolver)
    }
}

final class CalendarSearchViewModel: SearchCellViewModel, UserResolverWrapper {
    static let logger = Logger.log(CalendarSearchViewModel.self, category: "Module.IM.Search")
    @ScopedInjectedLazy var service: SearchMainTabService?
    let router: SearchRouter
    let searchResult: SearchResultType
    let renderDataModel: CalendarSearchRenderDataModel
    var tab: SearchTab?
    var pointColor: UIColor {
        var color: UIColor = UIColor.ud.B500
        if let _service = service, !_service.allCalendarItems.isEmpty, let calendarId = renderDataModel.calendarId {
            color = _service.allCalendarItems.first { calendarItem in
                calendarItem.id.elementsEqual(calendarId)
            }?.color ?? color
        }
        return color
    }
    var searchClickInfo: String { return "open_search" }
    var resultTypeInfo: String { return "slash_command" }

    let userResolver: UserResolver
    init(userResolver: UserResolver, searchResult: SearchResultType, router: SearchRouter, renderDataModel: CalendarSearchRenderDataModel) {
        self.userResolver = userResolver
        self.searchResult = searchResult
        self.renderDataModel = renderDataModel
        self.router = router
    }

    func didSelectCell(from vc: UIViewController) -> SearchHistoryModel? {
        guard let appLinkStr = renderDataModel.appLink, !appLinkStr.isEmpty else {
            Self.logger.error("[LarkSearch] main search calendar applink is empty")
            return nil
        }
        if let url = URL(string: appLinkStr)?.lf.toHttpUrl() {
            navigator.pushOrShowDetail(url, context: [FromSceneKey.key: FromScene.global_search.rawValue], from: vc)
        } else {
            Self.logger.error("[LarkSearch] main search calendar applink url is error \(appLinkStr)")
        }
        return nil
    }

    func supportDragScene() -> Scene? {
        // TODO:
        return nil
    }

    func supprtPadStyle() -> Bool {
        return UIDevice.btd_isPadDevice() && isPadFullScreenStatus(resolver: userResolver)
    }
}
