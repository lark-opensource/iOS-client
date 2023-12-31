//
//  DocComponentEvent.swift
//  SpaceInterface
//
//  Created by lijuyou on 2023/5/18.
//  


import Foundation


/// 文档组件状态
public enum DocComponentStatus {
    case start
    case loading
    case success
    case fail(error: Error?)
}

/// 文档内产生的事件
public enum DocComponentEvent: CustomStringConvertible {
    /// 状态变化
    case statusChange(status: DocComponentStatus)
    /// 文档标题被改变
    case onTitleChange(title: String)
    /// 即将关闭
    case willClose
    ///  导航按钮点击
    case onNavigationItemClick(item: String)

    public var description: String {
        //数据含有token，打印时只打印operation
        switch self {
        case .statusChange(status: let status):
            return "statusChange:\(status)"
        case .onTitleChange:
            return "onTitleChange"
        case .willClose:
            return "willClose"
        case .onNavigationItemClick(item: let item):
            return "onNavigationItemClick:\(item)"
        }
    }
}


/// 文档内产生的操作 (参考MagicShare)
public enum DocComponentOperation: CustomStringConvertible {
    /// 点击文档中的url链接
    case openUrl(url: String)
    /// 点击文档中的url链接，且打开url前需要执行额外的handler
    case openUrlWithHandlerBeforeOpen(url: String, handler: () -> Void)
    /// 点击文档中的图片链接
    case openPic(url: String)
    /// 点击UserProfile
    case showUserProfile(userId: String)
    
    public var description: String {
        //数据含有token，打印时只打印operation
        switch self {
        case .openUrl:
            return "openUrl"
        case .openPic:
            return "openPic"
        case .showUserProfile:
            return "openUserProfile"
        case .openUrlWithHandlerBeforeOpen:
            return "openUrlWithHandlerBeforeOpen"
        }
    }
}


public enum DocComponentNavigationItem: String {
    case close = "close"
    case back = "back"
    case more = "MORE_OPERATE"
    case done = "done"
    case catalog = "catalog"
    case message = "MESSAGE"
    case share = "SHARE"
}
