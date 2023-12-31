//
//  DriveBizViewControllerDelegate.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/7/17.
//

import Foundation
import SKCommon
import SKFoundation
import UIKit
import UniverseDesignColor

protocol DriveBizeControllerProtocol {
    var panGesture: UIPanGestureRecognizer? { get }
    var shouldHandleDismissGesture: Bool { get }
    // 同层渲染使用，返回的视图有native手势处理逻辑，需要在视图区域内禁不处理前端手势
    var customGestureView: UIView? { get }
    var openType: DriveOpenType { get }
    // 用于根据ChildVC情况配置MainVC的颜色（目前是视频文件在用）
    var mainBackgroundColor: UIColor { get }
    func willUpdateDisplayMode(_ mode: DrivePreviewMode)
    func changingDisplayMode(_ mode: DrivePreviewMode)
    func updateDisplayMode(_ mode: DrivePreviewMode)
}
extension DriveBizeControllerProtocol {
    var shouldHandleDismissGesture: Bool { true }
    var customGestureView: UIView? { nil }
    var mainBackgroundColor: UIColor { UDColor.bgBase }
}

protocol DrivePreviewScreenModeDelegate: NSObjectProtocol {
    @discardableResult
    func changeScreenMode() -> Bool
    
    func changePreview(situation: DrivePreviewSituation)

    @discardableResult
    func isInFullScreenMode() -> Bool

    func hideCommentBar(animated: Bool)

    func showCommentBar(animated: Bool)
    
    func setCommentBar(enable: Bool)
}

enum DriveBizViewControllerOpenResult {
    case cancel
    case cancelOnCellularNetwork
    case success
    case unsupport
    case failed
}

enum DriveBizViewControllerAction {
    // 子VC主动关闭评论面板
    case dismissCommentVC
    // 子VC从card mode进入normal mode
    case enterNormalMode
    // 子VC根据自身状态控制在卡片模式下标题栏的显示和隐藏
    case showCardModeNavibar(isShow: Bool)
}

/// 为了保证文件打开阶段耗时统计的准确性，子VC必须要调用 unsupport/previewFailed/openSuccess/exitPreview 的其中一种方法，否则会进 assert
protocol DriveBizViewControllerDelegate: NSObjectProtocol {
    var context: [String: Any]? { get set }
    
    /// AI 分会话支持从问答卡片中跳转到特定页面
    var pageNumber: Int? { get }
    /// 不支持预览
    func unSupport(_ bizViewController: UIViewController, reason: DriveUnsupportPreviewType, type: DriveOpenType)
    /// 预览失败
    func previewFailed(_ bizViewController: UIViewController, needRetry: Bool, type: DriveOpenType, extraInfo: [String: Any]?)
    /// 预览失败，并自动重试（有默认空实现）
    func previewFailedWithAutoRetry(_ bizViewController: UIViewController, type: DriveOpenType, extraInfo: [String: Any])
    /// 数据上报
    func statistic(action: DriveStatisticAction, source: DriveStatisticActionSource)
    /// 业务埋点数据上报(2021.6月新增)
    func statistic(event: DocsTrackerEventType, params: [String: Any])
    /// 业务埋点上报 点击事件
    func clickEvent(_ event: DocsTrackerEventType, clickEventType: ClickEventType, params: [String: Any])
    /// 预览成功
    func openSuccess(type: DriveOpenType)
    /// 退出预览
    func exitPreview(result: DriveBizViewControllerOpenResult, type: DriveOpenType)
    /// 导航栏添加预览按钮
    func append(leftBarButtonItems: [DriveNavBarItemData], rightBarButtonItems: [DriveNavBarItemData])
    /// 加载阶段耗时性能上报
    func stageBegin(stage: DrivePerformanceRecorder.Stage)
    func stageEnd(stage: DrivePerformanceRecorder.Stage)
    func reportStage(stage: DrivePerformanceRecorder.Stage, costTime: Double)
    
    // 子 VC 触发的操作
    func invokeDriveBizAction(_ action: DriveBizViewControllerAction)
    // fileID
    var fileID: String? { get }
}

extension DriveBizViewControllerDelegate {
    func previewFailedWithAutoRetry(_ bizViewController: UIViewController, type: DriveOpenType, extraInfo: [String: Any]) {}
    
    var pageNumber: Int? { return nil }
}
