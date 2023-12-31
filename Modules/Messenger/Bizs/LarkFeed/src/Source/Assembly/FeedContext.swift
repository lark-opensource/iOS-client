//
//  FeedContext.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/3/26.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import RustPB
import LKCommonsLogging
import LarkOpenFeed
import LarkContainer

final class FeedContext: FeedContextService {
    static let log = Logger.log(FeedContext.self, category: "LarkFeed")
    let userResolver: UserResolver
    /// 页面接口
    var pageAPI: FeedPageContext {
        return pageImpl
    }
    let pageImpl = FeedPageContextImpl()
    /// 数据源接口
    weak var dataSourceAPI: FeedDataSourceContext?
    /// feedlist监听
    var listeners: [FeedListenerItem] = []
    weak var page: UIViewController?

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
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
