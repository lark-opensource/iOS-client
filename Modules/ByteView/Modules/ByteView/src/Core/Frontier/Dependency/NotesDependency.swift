//
//  NotesDependency.swift
//  ByteViewDependency
//
//  Created by liurundong.henry on 2023/5/19.
//

import Foundation

public struct NotesAPIConfig {
    public let module: String
    public let sceneID: String

    public init(module: String, sceneID: String) {
        self.module = module
        self.sceneID = sceneID
    }
}

public protocol NotesDocumentFactory: AnyObject {

    func create(url: URL, config: NotesAPIConfig) -> NotesDocument?
}

public typealias NotesInvokeCallBack = (([String: Any], Error?) -> Void)

public protocol NotesDocument: AnyObject {

    var docVC: UIViewController { get }

    var status: NotesDocumentStatus { get }

    func setDelegate(_ delegate: NotesDocumentDelegate)

    func invoke(command: String,
                payload: [String: Any]?,
                callback: NotesInvokeCallBack?)

    func updateSettingConfig(_ settingConfig: [String: Any])

}

public protocol NotesDocumentDelegate: AnyObject {

    func docComponent(_ doc: NotesDocument,
                      onInvoke data: [String: Any]?,
                      callback: NotesInvokeCallBack?)

    func docComponent(_ doc: NotesDocument, onEvent event: NotesDocumentEvent)

    func docComponent(_ doc: NotesDocument, onOperation operation: NotesDocumentOperation) -> Bool

}

public enum NotesDocumentStatus {
    case start
    case loading
    case success
    case fail(error: Error?)
}

public enum NotesDocumentEvent: CustomStringConvertible {

    /// 状态变化
    case statusChange(status: NotesDocumentStatus)
    /// 文档标题被改变
    case onTitleChange(title: String)
    /// 即将关闭
    case willClose
    /// 点击导航栏按钮
    case onNavigationItemClick(item: String)

    public var description: String {
        switch self {
        case .statusChange: return "statusChange"
        case .onTitleChange: return "onTitleChange"
        case .willClose: return "willClose"
        case .onNavigationItemClick: return "onNavigationItemClick"
        }
    }
}

public enum NotesDocumentOperation: CustomStringConvertible {

    /// 点击文档中的url链接
    case openUrl(url: String)
    /// 点击文档中的url链接，且打开url前需要执行额外的handler
    case openUrlWithHandlerBeforeOpen(url: String, handler: () -> Void)
    /// 点击文档中的图片链接
    case openPic(url: String)
    /// 点击UserProfile
    case showUserProfile(userId: String)

    public var description: String {
        switch self {
        case .openUrl: return "openUrl"
        case .openUrlWithHandlerBeforeOpen: return "openUrlWithHandlerBeforeOpen"
        case .openPic: return "openPic"
        case .showUserProfile: return "showUserProfile"
        }
    }
}
