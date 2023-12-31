//
//  DocDefines.swift
//  SKCommon
//
//  Created by lijuyou on 2020/6/30.
//  


import Foundation
import RxRelay


// From UtilDocsInfoUpdateService
/// 获取 DocsInfo 信息的两个阶段
///
/// - getWikiInfo: 获取wiki对应的objToken 和type
/// - getWholeInfo: 获取真正objToken 对应的信息
public enum DocsInfoUpdateStage {
    case getWikiInfo
    case getWholeInfo
}

public protocol DocsInfoDidUpdateReporter: AnyObject {
    func loaderDidUpdateDocsInfo(stage: DocsInfoUpdateStage, error: Error?)
    ///获取到真实token 和type, 处理fakeToken、无权限这种边缘case
    func loaderDidUpdateRealTokenAndType(info: DocsInfo)
}


// From MultiTaskService
/// 存储当前文档的滑动位置
/// 目前只有Docs支持滑动位置记录
public struct DocsScrollPos {
    public let x: Float
    public let y: Float

    public init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }
}


//From WebCommentProcessor.swift
public typealias WebCommentSendCallBack = (Int?, String?) -> Void


// From  ShareLinkEditViewController+Cell.swfit
enum PasswordSettingNetworkError: Error {
    case setupFailed
    case refreshFailed
    case deleteFailed
    case submitFailed
}

//From ReminderItemView.swift
public protocol DocsListItemView {
    associatedtype RightView: UIView
    var leftTitle: UILabel { get set }
    var rightView: RightView { get set }
    var tapCallback: ((RightView) -> Void)? { get set }
}


public protocol DocsOPAPIContextProtocol {
    
    var controller: UIViewController? { get }
    
    var appId: String? { get }
}
