//
//  LarkMailInterface.swift
//  LarkMailInterface
//
//  Created by tefeng liu on 2020/2/6.
//

import Foundation
import EENavigator
import RxSwift
import LarkUIKit

public struct ShareEmlEntry {
    public let data: Data
    public let from: NavigatorFrom

    public init(data: Data, from: NavigatorFrom) {
        self.data = data
        self.from = from
    }
}

/// shareExtesion 进入飞书事件.
public enum ShareEmlAction {
    case open(ShareEmlEntry)
}

public enum LarkMailEMLDownloadState {
    case downloading(progress: Double)
    case success(fileURL: URL)
    case interrupted(reason: String)
}

public protocol LarkMailEMLProvider {
    /// 如果已下载完成，提供LocalFileURL，直接从本地打开
    var localFileURL: URL? { get }
    func download() -> Observable<LarkMailEMLDownloadState>
    func cancelDownload()
}

public protocol LarkMailInterface {
    func checkLarkMailTabEnable() -> Bool
    func isConversationModeEnable() -> Bool
    func notifyMailNaviUpdated(isEnabled: Bool)
    func onShareEml(action: ShareEmlAction) -> Observable<()>
    func canOpenIMFile(fileName: String) -> Bool
    func openEMLFromIM(fileProvider: LarkMailEMLProvider, from: NavigatorFrom)
    func openEMLFromPath(_ path: URL, from: NavigatorFrom)
    func getEMLPreviewController(_ emlPath: URL) -> UIViewController?
    func getSearchController(query: String?, searchNavBar: SearchNaviBar?) -> UIViewController
    func hasLarkSearchService() -> Bool
}

