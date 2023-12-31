//
//  PagePreservable.swift
//  LarkKeepAlive
//
//  Created by Yaoguoguo on 2023/9/26.
//

import Foundation

public enum PageKeeperType: String {
    case webapp
    case h5
    case littleapp
    case ccm
}

public enum PageKeeperScene: String {
    case main
    case quick
    case suspend
    case temporary
    case workbench
    case normal
}

public enum PageKeepError: Error {
    case normal
    case backgroundAudio
    case whiteList
    case customConfig
}

public protocol PagePreservable: UIViewController {
    /// id用于和pageType生成唯一uniqueID
    var pageID: String { get }

    /// 不同业务优先级保活时间也不一样
    var pageType: PageKeeperType { get }

    var pageScene: PageKeeperScene { get set }

    /// 能否被保活，默认为True，如果需要特殊不保活可以override
    /// 
    /// - Returns: PageKeepError， 不为空则无法添加到队列
    func shouldAddToPageKeeper() -> PageKeepError?

    /// 特殊场景下，业务不希望被移除，如后台播放等，交由业务方自行判断
    ///
    /// - Returns: PageKeepError， 不为空则无法从队列移除
    func shouldRemoveFromPageKeeper() -> PageKeepError?

    func getPageSceneBySelf() -> PageKeeperScene?

    func willAddToPageKeeper()

    func didAddToPageKeeper()

    func willRemoveFromPageKeeper()

    func didRemoveFromPageKeeper()
}

public extension PagePreservable {

    func shouldAddToPageKeeper() -> PageKeepError? { return nil }

    func shouldRemoveFromPageKeeper() -> PageKeepError? { return nil }

    func getPageSceneBySelf() -> PageKeeperScene? { return nil }

    func willAddToPageKeeper() {}

    func didAddToPageKeeper() {}

    func willRemoveFromPageKeeper() {}

    func didRemoveFromPageKeeper() {}
}
