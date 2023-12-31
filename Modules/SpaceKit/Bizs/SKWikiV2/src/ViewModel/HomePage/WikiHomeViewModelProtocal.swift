//
//  WikiHomeViewModelProtocal.swift
//  SKWikiV2
//
//  Created by majie.7 on 2022/12/12.
//

import Foundation
import SKCommon
import RxSwift
import RxCocoa
import SKWorkspace

enum WikiHomeListItem {
    case wikiSpace(item: WikiSpace)
    case upload(item: DriveStatusItem)
}

enum WikiHomeAction {
    case updateNetworkState(isReachable: Bool)
    case jumpToWikiTree(space: WikiSpace)
    case jumpToCreateWikiPicker(sourceView: UIView)
    case updatePlaceHolderView(shouldShow: Bool)
    case jumpToUploadList(mountToken: String)

    // 新版本首页新增action
    case getListError(Error)
    case updateHeaderList(count: Int, isLoading: Bool)
    case updateList
    case stopPullToRefresh
    case stopLoadMoreList(hasMore: Bool?)
    case present(UIViewController)
    case scrollHeaderView(index: IndexPath)
}

enum WikiHomePageCellIdentifier: String {
    case spaceCellReuseIdentifier               = "wiki.home.space.collection.cell"
    case spacePlaceHolderCellReuseIdentifier    = "wiki.home.space.placeholder.cell"
    case recentCellReuseIdentifier              = "wiki.home.recent.table.cell"
    case wikiSpaceListIdentifier                = "wiki.home.wiki.space.list.table.cell"
    case uploadCellReuseIdentifier              = "wiki.home.upload.cell"
}

protocol WikiHomePageViewModelProtocol: NSObject, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    var items: [WikiHomeListItem] { get }
    var actionOutput: Driver<WikiHomeAction> { get }
    var tableViewShouldScrollToTop: Observable<Bool> { get }
    var isReachable: Bool { get }
    var headerSpacesCount: Int { get }
    var heightOfHeaderSection: CGFloat { get }
    var isV2: Bool { get }
    var emptyListDescription: String { get }
    var ui: WikiHomePageUIDelegate? { set get }
    
    func didAppear(isFirstTime: Bool)
    func didClickCreate(sourceView: UIView)
    func didClickAllSpaces()
    func refreshHeaderList()
    func refreshList()
    func loadMoreList()
    // 上下列表以及筛选项全部刷新
    func refresh()
}

protocol WikiHomePageUIDelegate: AnyObject {
    var isiPadRegularSize: Bool { get }
}
