//
//  ListViewState.swift
//  Todo
//
//  Created by 张威 on 2020/12/1.
//

// MARK: List View State

enum ViewStateFailure {
    case noAuth     // 没有权限
    case deleted    // 已被删除
    case needsRetry // 需要重试
    case none       // 默认
}

enum ListViewState: Equatable {
    /// idle
    case idle
    /// 加载中
    case loading
    /// 加载完成，没数据
    case empty
    /// 加载完成，有数据
    case data
    /// 加载失败
    case failed(ViewStateFailure = .none)
}

/// 列表下拉刷新的状态
enum ListRefreshState {
    /// 不支持下拉刷新
    case none
    /// idle（可触发下拉刷新）
    case idle
    /// 加载中
    case loading
}

/// 列表上拉加载更多的状态
enum ListLoadMoreState: Int {
    /// 未知状态
    case none
    /// 还有更多（未触发）
    case hasMore
    /// 触发加载（已触发）
    case loading
    /// 没有更多（没有更多了）
    case noMore
}

enum ListViewTransition {
    /// animated transition
    case animated
    /// refresh view without animations
    case reload
}

enum ListAfterTransition {
    /// 默认状态
    case none
    /// 滑动到某处
    case scrollToItem(indexPath: IndexPath?)
    /// 选中某处
    case selectItem(indexPath: IndexPath?)
}

enum ListActionResult {

    case succeed(toast: String?)

    case failed(toast: String?)

}
