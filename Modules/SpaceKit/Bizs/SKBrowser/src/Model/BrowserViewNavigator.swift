//
//  BrowserViewNavigator.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/7/14.
//  


import Foundation
import SKCommon

/// 初始化Browserview 时需要传入的变量
struct BrowserViewConfig {
    weak var shareDelegate: DocsBrowserShareDelegate?
    weak var statisticsDelegate: BrowserViewStatisticsDelegate?
    weak var offlineDelegate: BrowserViewOfflineDelegate?
    weak var navigator: BrowserViewNavigator?
    var clientInfos = [String: String]()
}

public protocol BrowserViewNavigator: AnyObject {
    func currentBrowserVC(_ browserView: BrowserView) -> UIViewController?
    func browserView(_ browserView: BrowserView, requiresOpen url: URL) -> Bool
    func pageIsExistInStack(_ browserView: BrowserView, url: URL) -> Bool
}
