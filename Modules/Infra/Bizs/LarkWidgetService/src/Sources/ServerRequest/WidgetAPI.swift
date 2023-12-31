//
//  WidgetAPI.swift
//  LarkWidget
//
//  Created by ZhangHongyun on 2020/12/2.
//

import Foundation
import UIKit
import RxSwift
import ServerPB

protocol WidgetAPI {

    func fetchCalendarWidgetTimeline() -> Observable<GetSmartWidgetResponse>
    func fetchUtilityWidgetData() -> Observable<GetUtilityWidgetListReponse>
    func fetchTodoWidgetTimeline() -> Observable<GetTodoWidgetResponse>
}
