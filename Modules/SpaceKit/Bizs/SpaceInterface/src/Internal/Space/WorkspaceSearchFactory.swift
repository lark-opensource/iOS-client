//
//  WorkspaceSearchFactory.swift
//  SpaceInterface
//
//  Created by Weston Wu on 2023/5/17.
//

import Foundation
/// 从哪个界面进入的搜索
///
/// - all: 主界面，默认
/// - folder: 我的文件夹界面
/// - quickAccess: 快速访问界面
public enum DocsSearchFromType: Equatable {
    case normal
    case folder(token: String, name: String, isShareFolder: Bool)
    case quickAccess
}

public enum SearchFromStatisticName: String {
    case personal
    case shared
    case favourites
    case offline
    case bitableHome
}

public enum WikiSearchResultItem {
    case wikiNode(node: WikiNodeMeta)
    case wikiSpace(id: String, name: String)
}

public protocol WikiTreeSearchDelegate: AnyObject {
    func searchControllerDidClickCancel(_ controller: UIViewController)
    func searchController(_ controller: UIViewController, didClick: WikiSearchResultItem)
}

public protocol WorkspaceSearchFactory {
    func createSpaceSearchController(docsSearchType: DocsSearchType,
                                     searchFrom: DocsSearchFromType,
                                     statisticFrom: SearchFromStatisticName) -> UIViewController

    func createWikiSearchController() -> UIViewController

    func createWikiTreeSearchController(spaceID: String, delegate: WikiTreeSearchDelegate) -> UIViewController

    func createWikiAndFolderSearchController(config: WorkspacePickerConfig) -> UIViewController

    func createFolderSearchController(config: WorkspacePickerConfig) -> UIViewController

    func createWikiSpaceSearchController(delegate: WikiTreeSearchDelegate) -> UIViewController
}
