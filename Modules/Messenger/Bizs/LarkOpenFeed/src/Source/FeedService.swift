//
//  FeedService.swift
//  LarkMessengerInterface
//
//  Created by 夏汝震 on 2021/1/5.
//

import UIKit
import Foundation
import RxSwift
import RustPB
import EENavigator
import Swinject
import LarkContainer

public enum FeedPageState: Int {
    case unknown

    case viewInit

    case viewDidLoad

    case viewWillAppear

    case viewDidAppear

    case viewWillDisappear

    case viewDidDisappear

    case viewDeinit
}

/// 页面能力
public protocol FeedPageContext {
    var pageStateObservable: Observable<FeedPageState> { get }
}

/// 数据源能力
public protocol FeedDataSourceContext: AnyObject {
    var currentFilterType: Feed_V1_FeedFilter.TypeEnum { get }
}

/// 上下文
public protocol FeedContextService {
    /// 页面接口
    var pageAPI: FeedPageContext { get }
    /// 数据源接口
    var dataSourceAPI: FeedDataSourceContext? { get }
    var page: UIViewController? { get }
    var listeners: [FeedListenerItem] { get }
    var userResolver: UserResolver { get }
}

public protocol FeedLayoutService {
    var containerSizeChangeObservable: Observable<CGSize> { get }
    var containerSize: CGSize { get }
}

public struct FeedPageBody: PlainBody {
    public static let pattern = "//client/feed/main"
    public init() {}
}
