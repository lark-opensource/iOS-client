//
//  FakeContactDependency.swift
//  MailDemo
//
//  Created by tefeng liu on 2022/4/16.
//

import Foundation
import RxSwift
import RxCocoa
import RustPB
import LKCommonsLogging
#if LARKCONTACT
import LarkFeedInterface

final class FeedContext: FeedContextService {
    static let log = Logger.log(FeedContext.self, category: "LarkFeed")
    /// 页面接口
    var pageAPI: FeedPageContext {
        return pageImpl
    }
    let pageImpl = FeedPageContextImpl()
    /// 数据源接口
    weak var dataSourceAPI: FeedDataSourceContext?
    weak var page: UIViewController?
    init() {}
}

final class FeedPageContextImpl: FeedPageContext {
    var pageStateObservable: Observable<FeedPageState> {
        return pageStateRelay.asObservable()
    }
    let pageStateRelay = BehaviorRelay<FeedPageState>(value: .unknown)
}

enum FeedLogBizType: String {
    case pageState
    case launch
    case uiAction
    case dataStream
    case shortcut
    case header
    case topbar
    case screenShot
    case error
}
#endif
