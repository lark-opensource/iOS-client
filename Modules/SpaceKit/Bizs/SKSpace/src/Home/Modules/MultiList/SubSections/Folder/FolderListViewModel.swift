//
//  FolderListViewModel.swift
//  SKSpace
//
//  Created by Weston Wu on 2021/11/4.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import UniverseDesignEmpty
import SpaceInterface

// 配合文件夹样式列表的 ViewModel，目前有子文件夹列表、我的文件夹列表和共享文件夹列表（后两个待废弃）
protocol FolderListViewModel: SpaceListViewModel {
    // 列表是否空白，埋点用
    var isBlank: Bool { get }
    // 是否是共享文件夹，埋点用
    var isShareFolder: Bool { get }
    // 本地数据是否加载完成，影响空状态展示逻辑
    var localDataReady: Bool { get }
    // 服务器同步状态
    var serverDataState: ServerDataState { get }
    // 网络状态
    var isReachable: Bool { get }
    // 网络状态变化
    var reachabilityChanged: Observable<Bool> { get }
    // 列表空状态文案
    var emptyDescription: String { get }

    var emptyImageType: UDEmptyType { get }
    // 创建按钮 enable 状态
    var createEnabledUpdated: Observable<Bool> { get }
    // 创建上下文
    var createContext: SpaceCreateContext { get }
    // 搜索上下文
    var searchContext: SpaceSearchContext { get }
    // 导航栏 More 按钮
    func folderMoreAction() -> ((UIView) -> Void)?
    // 排序名字
    var sortNameRelay: BehaviorRelay<String> { get }
    // 排序状态
    var sortStateRelay: BehaviorRelay<SpaceListFilterState> { get }
    
    var selectSortOptionRelay: BehaviorRelay<SpaceSortHelper.SortOption?> { get }
    // 排序面板选项, Bool 表示是否发生过修改（即与默认配置不一致）
    func generateSortItems() -> ([SortItem], Bool)?
    // 排序面板 delegate
    var sortPanelDelegate: SpaceSortPanelDelegate { get }
    // 只有共享文件夹2.0列表 使用， 其他列表设为false, 用于在新共享空间空文件夹列表下隐藏兜底页
    var hiddenFolderListSection: Bool { get }
    // 标识不同的文件夹列表
    var folderListScene: FolderListScene { get }
}

// 受权限控制的文件夹列表 ViewModel，只有子文件夹列表实现
protocol PermissionRestrictedFolderListViewModel: FolderListViewModel {

    var folderToken: FileListDefine.ObjToken { get }

    var folderType: FolderType { get }

    var listStatusChanged: Signal<Result<Void, FolderListError>> { get }

    func checkFolderPermission()

    func requestPermission(message: String, roleToRequest: Int) -> Completable

    var folderEntry: FolderEntry? { get }
}

protocol FolderPickerDataModel {
    typealias SortOption = SpaceSortHelper.SortOption
    var pickerItems: [SpaceEntry] { get }
    var pickerItemChanged: Observable<[SpaceEntry]> { get }
    var addToCurrentFolderEnabled: Observable<Bool> { get }
    var interactionHelper: SpaceInteractionHelper { get }
    func setup()
    func refresh() -> Completable
    func loadMore() -> Completable
    func resetSortFilterForPicker()
}

enum FolderListScene: Equatable {
    case shareFolderList
    case myFolderList
    case subFolderList
}
