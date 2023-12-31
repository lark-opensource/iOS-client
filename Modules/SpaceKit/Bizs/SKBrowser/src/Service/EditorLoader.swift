//
//  DocsLoader.swift
//  SKBrowser
//
//  Created by chenhuaguan on 2021/7/6.
//

import SKFoundation
import SKUIKit
import SKCommon

public protocol DocsLoader: EditorConfigDelegate, BrowserViewLifeCycleEvent, BrowserLoadingReporter, SKTracableProtocol {
    var docsInfo: DocsInfo? { get }
    var currentUrl: URL? { get set }
    var netRequestHeaders: [String: String] { get }
    var openSessionID: String? { get set }
    var loadStatus: LoadStatus { get }
    var docContext: DocContext? { get set }
    func load(url: URL)
    func resetDocsInfo(_ url: URL)
    func updateClientInfo(_ newInfos: [String: String])
    func removeContentIfNeed()
    func setNavibarHeight(naviHeight: CGFloat)
    func delayShowLoading()
    func browserWillClear()
    func reload(with docUrl: URL?)
    func resetShowOverTimeTip()
    func browserDidGetWikiInfo(error: Error?)
    func updateVersionInfo()
}
public extension DocsLoader {
    func reload() {
        self.reload(with: nil)
    }
}
