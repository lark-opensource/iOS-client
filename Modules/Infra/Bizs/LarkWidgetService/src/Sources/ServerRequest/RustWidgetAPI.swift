//
//  RustWidgetAPI.swift
//  LarkWidget
//
//  Created by ZhangHongyun on 2020/12/3.
//

import Foundation
import RxSwift
import LarkRustClient
import LarkContainer
import ServerPB

final class RustWidgetAPI: WidgetAPI {

    @Provider private var rustService: RustService

    func fetchCalendarWidgetTimeline() -> Observable<GetSmartWidgetResponse> {
        let request = GetSmartWidgetResquest()
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .getSmartWidget)
    }

    func fetchUtilityWidgetData() -> Observable<GetUtilityWidgetListReponse> {
        let request = GetUtilityWidgetListRequest()
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .getWidgetAppList)
    }

    func fetchTodoWidgetTimeline() -> Observable<GetTodoWidgetResponse> {
        var filter = ServerPB_Todo_entities_TodoFilter()
        filter.relation.category = .assignToMe
        filter.state.category = .ongoing
        var params = ServerPB_Todos_PagingWidgetParams()
        params.count = 10
        params.filter = filter
        var request = GetTodoWidgetRequest()
        request.params = params
        return rustService.sendPassThroughAsyncRequest(request, serCommand: .mgetTodoWidgetData)
    }
}
