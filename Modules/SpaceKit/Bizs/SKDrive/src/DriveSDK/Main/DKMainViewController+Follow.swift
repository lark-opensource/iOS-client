//
//  DKMainViewController+Follow.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/6/27.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON
import SpaceInterface
import SKCommon
import SKFoundation

// 桥接 SpaceFollowAPIDelegate
protocol DriveFollowAPIDelegate: AnyObject {
    /// VCFollow 的角色
    var followRole: FollowRole { get }
    /// 主 MagicShare 的内容是否原生文件
    var isHostNativeContent: Bool { get }
    /// follow 相关埋点数据
    var followStatisticParameters: [String: String]? { get }
    /// 同层 Follow 元素在文档的位置
    var fileBlockMountToken: String? { get set }
    /// 注册Follow模块
    func register(followContent: FollowableContent)
    /// 反注册Follow模块
    func unregister(followContent: FollowableContent)
    /// 需要回调给VC的各种操作
    /// - Parameters:
    ///   - operation: 动作信息，key为操作类型，value为动作参数
    func handle(operation: SpaceFollowOperation)
    /// drive 内容加载完成
    func followDidReady()
    /// drive 内容渲染完成
    func followDidRenderFinish()
}

protocol DriveFollowContentManager: DriveFollowAPIDelegate {
    // 当前文件名
    var followTitle: String { get set }
    // 评论follow状态变化
    var commentFollowStateUpdated: Driver<DriveCommentManager.State> { get }
    // 初始化 follow delegate
    func setup(followController: FollowableViewController, followAPIDelegate: SpaceFollowAPIDelegate)
    // 刷新 follow 内容
    func refreshInFollowContext()
    // 配置文件内容的 follow
    func setupFollowConfig(for contentProvider: DriveFollowContentProvider)
    // follow 内容提供者
    var followContentProvider: DriveFollowContentProvider? { get }
    var shouldHideBackButton: Bool { get }
    var shouldSkipCellularCheck: Bool { get }
    /// 预览页面是否自动进入沉浸态
    var shouldEnterFullScreenMode: Bool { get }
}

// 支持 Follow 的预览 VC 需要实现这个协议，同时只存在一个 contentProvider
protocol DriveFollowContentProvider: AnyObject {
    // 目前是否支持 VC Follow，可用于 FG 判断
    var vcFollowAvailable: Bool { get }
    var followScrollView: UIScrollView? { get }
    func setup(followDelegate: DriveFollowAPIDelegate, mountToken: String?)
    func onRoleChange(_ newRole: FollowRole)
    func registerFollowableContent()
    func unregisterFollowableContent()
}

extension DriveFollowContentProvider {
    func onRoleChange(_ newRole: FollowRole) {}
    func registerFollowableContent() {}
    func unregisterFollowableContent() {}
}

// 支持 Follow 的容器 VC 需要实现这个协议
protocol DriveFollowContainer: AnyObject {
    // 表示当前是否处于 VC Follow 环境
    var isInVCFollow: Bool { get }
    func setupFollowConfig(contentProvider: DriveFollowContentProvider)
    func handleContentUnavailableForFollow()
}

extension DKMainViewController: FollowableViewController {

    var isEditingStatus: Bool {
        return false
    }

    var isInVCFollow: Bool {
        return followManager != nil
    }

    var shouldHideBackButtonInFollow: Bool {
        return followManager?.shouldHideBackButton ?? false
    }

    var shouldSkipCellularCheckInFollow: Bool {
        return followManager?.shouldSkipCellularCheck ?? false
    }

    var forbbidenDismissInFollow: Bool {
        return isInVCFollow
    }

    var followManager: DriveFollowContentManager? {
        return viewModel as? DriveFollowContentManager
    }

    /// 当前FollowAPI 所对应的 docs 文档标题
    var followTitle: String {
        return followManager?.followTitle ?? ""
    }

    /// 返回当前UIScrollView
    var followScrollView: UIScrollView? {
        return followManager?.followContentProvider?.followScrollView
    }

    /// 配置实现Follow的ViewContoller
    func onSetup(followAPIDelegate: SpaceFollowAPIDelegate) {
        guard let followManager = followManager else {
            DocsLogger.error("drive.main.follow --- failed to get followManager when set delegate, not in follow mode")
            return
        }
        followManager.setup(followController: self, followAPIDelegate: followAPIDelegate)

        // 单独 MagicShare Drive 文件才需要绑定评论状态
        if followAPIDelegate.isHostNativeContent {
            DocsLogger.driveInfo("drive.main.follow --- onSetup bindCommentFollowState")
            bindCommentFollowState(followManager: followManager)
        }

        self.viewModel.hostModule?.commonContext.followAPIDelegate = followAPIDelegate
    }

    /// 刷新当前页面
    func refreshFollow() {
        guard let followManager = followManager else {
            DocsLogger.error("drive.main.follow --- failed to get followManager when refresh, not in follow mode")
            return
        }
        followManager.refreshInFollowContext()
    }

    func onRoleChange(_ newRole: FollowRole) {
        // 进入follow状态时默认进入沉浸态
        if followManager?.shouldEnterFullScreenMode == true {
            if newRole == .follower {
                enterFullScreen()
            }
        }
        followManager?.followContentProvider?.onRoleChange(newRole)
    }

    func onOperate(_ operation: SpaceFollowOperation) {
        switch operation {
        case .willSetFloatingWindow:
            // 在 VC Follow 切换小窗口前，需要 dismiss 弹出的 DriveContainerViewController
            dismissFileBlockIfNeed()
        case .onDocumentVCDidMove:
            //vcFollow情况下，切换到小窗模式或重新共享新文档，附件和卡片都会移除，需要通知前端
            dismissFileBlockIfNeed()
            self.removeFromParent()
            followManager?.handle(operation: .onExitAttachFile(isNewAttach: true))
        case .exitAttachFile:
            dismissFileBlockIfNeed()
        case .finishFullScreenWindow:
            // 通知 VM 恢复小窗，可能需要重新触发重定向
            let index = currentIndex
            let cellVM = viewModel.cellViewModel(at: index)
            cellVM.didResumeVCFullWindow()
        default:
            break
        }
    }

    /// 把 Present 出来的 FileBlock 收起来
    private func dismissFileBlockIfNeed() {
        guard let parent = self.parent as? DriveContainerViewController else { return }
        DocsLogger.driveInfo("dismissFileBlock", category: "VCFollow")
        // 这里主动调用 resetChildVC 把弹出的 VC 放回 FileBlock，所以 dismiss animated 需为 false
        willChangeMode(.card)
        parent.resetChildVC?()
        if let presenting = parent.presentingViewController {
            // 关闭当前 parent(DriveContainerVC) present 出来的 vc(评论的vc) 后再把 parent dismiss
            // https://meego.feishu.cn/larksuite/issue/detail/6273468
            DocsLogger.driveInfo("dismissFileBlock - dismiss presentingVC \(presenting)", category: "VCFollow")
            presenting.dismiss(animated: false) {
                parent.dismiss(animated: false)
            }
        } else {
            parent.dismiss(animated: false)
        }
    }
}

// MARK: - VC Follow Comment State
extension DKMainViewController {

    private func bindCommentFollowState(followManager: DriveFollowContentManager) {
        followManager.commentFollowStateUpdated
            .drive(onNext: { [weak self] (commentState) in
                self?.set(commentState: commentState)
            })
            .disposed(by: bag)
    }

    private func set(commentState: DriveCommentFollowState) {
        switch commentState {
        case .collapse:
            collapseCommentViewIfNeed()
        case let .expanded(focusedID):
            showCommentView(commentID: focusedID)
        }
    }

    private func collapseCommentViewIfNeed() {
        DocsLogger.driveInfo("collapseCommentViewIfNeed")
        viewModel.hostModule?.commentManager?.commentModule?.hide()
    }

    private func showCommentView(commentID: String?) {
        viewModel.hostModule?.subModuleActionsCenter.accept(.viewComments(commentID: commentID, isFromFeed: false))
    }
}

// MARK: - DriveFollowContainer
extension DKMainViewController: DriveFollowContainer {

    func setupFollowConfig(contentProvider: DriveFollowContentProvider) {
        guard let followManager = followManager else {
            DocsLogger.driveInfo("drive.main.follow --- not in follow mode, skip setup follow config for contentProvider")
            return
        }
        followManager.setupFollowConfig(for: contentProvider)
    }

    func handleContentUnavailableForFollow() {
        // TODO: 上报给 VC，提示不支持follow
        DocsLogger.error("drive.main.follow --- follow content provider not available for following")
    }
}
