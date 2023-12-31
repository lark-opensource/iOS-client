//
//  CommentAsideDataPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/7/26.
//
// swiftlint:disable file_length
// 专职负责评论数据CRUD/diff，其他模块不要修改模型的数据！

import UIKit
import SKFoundation
import SKResource
import RxDataSources
import Differentiator
import RxSwift
import RxCocoa
import SpaceInterface
import SKCommon

final class CommentAsideDataPlugin: CommentDiffDataPlugin, CommentPluginType {
    
    static let identifier = "AsideDataPlugin"

    /// 前端有时会不正常返回数据，比如bot同时返回上百条updateData数据,
    /// 需要等待当前数据处理完后，再处理后面的数据。因为diff后刷新是异步的
    /// 必须要等异步数据刷新完 并且对齐后再处理后面的数据
    var updateDataQueue = CommentUpdateDataQueue<CommentAction>()
    
    var isHideComment = false
    
    var asideAtInfoCache: [String: Set<String>] = [:]

    override init() {
        super.init()
        updateDataQueue.actionClosure = { [weak self] node in
            guard let self = self else { return }
            DocsLogger.info("[data queue] perform queue node \(node.action)", component: LogComponents.comment)
            switch node.action {
            case .updateData:
                let oldValue = self.isHideComment
                self.isHideComment = false
                self.resolveData(node: node)
                if oldValue {
                    DispatchQueue.main.async {
                        self.checkAtPermissions()
                    }
                }
            case .scrollComment:
                self.handleScrollComment(node: node)
            case let .updateCopyTemplateURL(templateUrlString):
                let canCopyCommentLink = self.context?.businessDependency?.businessConfig.canCopyCommentLink ?? false
                if templateUrlString != self.templateUrlString,
                   canCopyCommentLink {
                    self.templateUrlString = templateUrlString
                    self.scheduler?.reduce(state: .setCopyAnchorLinkEnable(!templateUrlString.isEmpty))
                    self.scheduler?.reduce(state: .reload)
                }
                node.markFulfill()
            default:
                spaceAssertionFailure("node: \(node.action) is not suport perform at queue now")
            }
        }
    }

    /// 接收action，对数据进行处理
    func mutate(action: CommentAction) {
        switch action {
        // 需要刷新或者滚动UI的操作都放到队列中处理
        case .updateData, .scrollComment, .updateCopyTemplateURL:
            updateDataQueue.appendAction(action)
        case let .scrollComment:
            updateDataQueue.appendAction(action)
        case let .vcFollowOnRoleChange(role):
            self.role = role

        case let .ipc(action, callback):
              handleIPC(action, callback)
        case let .interaction(action):
              handleUIAction(action)
        case .resetActive:
            handleResetActive()
        case .reloadData:
            scheduler?.reduce(state: .reload)
        default:
            break
        }
    }
}

// MARK: - resolve data
extension CommentAsideDataPlugin {
    private func resolveData(node: CommentDataQueueNode<CommentAction>) {
        guard case let .updateData(data) = node.action else {
            return
        }
        data.addFooter()
        guard let context = context,
              let tableView = context.tableView,
              let scheduler = context.scheduler else {
                  DocsLogger.error("context lost key info", component: LogComponents.comment)
            node.markFulfill()
            return
        }

        if self.statsExtra == nil,
           let statsExtra = data.statsExtra {
            self.statsExtra = statsExtra
        }
        
        payload = data.paylod

        // loading状态处理
        scheduler.reduce(state: .loading(!data.isLoaded))
        
        scheduler.reduce(state: .updateTitle(BundleI18n.SKResource.Doc_Facade_Comments + " (\(data.comments.count))"))
        
        commentPermission = data.commentPermission
        docsInfo = data.docsInfo

        if let docsInfo = data.docsInfo {
            scheduler.reduce(state: .updateDocsInfo(docsInfo))
        }
        
        scheduler.reduce(state: .setTranslateConfig(context.businessDependency?.businessConfig.translateConfig))

        scheduler.reduce(state: .updatePermission(data.commentPermission))
        
        let newSections = constructArraySection(data.comments)

        let nextId = data.currentCommentID ?? ""
        let pos = data.currentCommentPos
        let replyId = data.currentReplyID
        
        let activeComment = commentSections.activeComment?.0
        
        let cancelHightLight = data.cancelHightLight == true
        let preId = activeComment?.commentID ?? ""
        let nextIsActive = !nextId.isEmpty
//        let currentIsActive = !preId.isEmpty
        
        // 记住当前UI位置
        scheduler.reduce(state: .locateReference)
        
        // 新数据有激活评论命令，且和当前激活评论不相同（当前可以是激活或者未激活）
        let activeNow = (nextIsActive && nextId != preId)
        if activeNow {
            DocsLogger.info("active now, reload directly", component: LogComponents.comment)
            // activeNow 需要reload，不走diff reload，否则对齐可能会不准确
            // 但是需要匹配数据进行状态转移，如评论图片的loading状态，这时需要通过diff便利一次
            _ = try? Diff.differencesForSectionedView(initialSections: commentSections, finalSections: newSections)
            commentSections = newSections
            scheduler.reduce(state: .syncData(commentSections))
            scheduler.reduce(state: .reload)
            afterUpdateUI(preId: preId, nextId: nextId, replyId: replyId, position: pos, changed: false)
            node.markFulfill()
            checkMunuAndDismissIfNeed()
            return
        }
        // 剩下还有以下情况， 需要走diff
        // 1. 新数据有取消激活评论命令：-- 直接走diff
        // 2. 新数据是有激活命令，当前数据有激活，是同个激活评论：-- viewState需要同步，再走diff
        // 3. 新数据是无激活命令，当前数据有激活：-- 需要设置新数据为激活状态，viewState也需要同步，再走diff
        // 4. 新数据是无激活命令，当前数据无激活：-- 直接走diff
        syncCurrentStatus(cancel: cancelHightLight,
                             nextId: nextId,
                             activeComment: activeComment,
                             newSections: newSections)
        

        // diff
        differences(commentSections, newSections, tableView: tableView) { [weak self] changed in
            // RxDatasource diff时不支持section纬度的update，走diff会有bug，
            // changeSet.finalSections中的section最终拿到的是source数据源中的section
            // 需要最后同步下数据
            if !changed {
                self?.statsExtra = nil
            }
            self?.commentSections = newSections
            self?.scheduler?.reduce(state: .syncData(newSections))
            self?.afterUpdateUI(preId: preId,
                                nextId: nextId,
                                replyId: replyId,
                                position: pos,
                                changed: changed)
            node.markFulfill()
            self?.checkMunuAndDismissIfNeed()
        }
    }
    
    
    /// 刷新UI之后需要做对齐
    /// - Parameters:
    ///   - preId: 旧的激活的评论id， 空表示不存在
    ///   - nextId: 新的的激活的评论id， 空表示不存在
    ///   - replyId: 可选值，有值时在浮窗评论下还需要做滚动的操作
    ///   - position: 可选值，有值时表示需要和正文对齐
    ///   - changed: 数据是否有变更
    private func afterUpdateUI(preId: String, nextId: String, replyId: String?, position: CGFloat?, changed: Bool) {
        func keepCurrentPosition() {
            if let tuple = commentSections.modifiableItem,
               tuple.item.viewStatus.isFirstResponser {
                // 如果当前正在输入，优先保证输入框在键盘之上
                DocsLogger.info("afterUpdate keeping input visiable", component: LogComponents.comment)
                scheduler?.reduce(state: .keepInputVisiable(indexPath: tuple.index, force: false))
            } else {
                DocsLogger.info("afterUpdate keepStill", component: LogComponents.comment)
                scheduler?.reduce(state: .keepStill)
            }
        }
        // 无对齐操作需要保持静止
        guard !nextId.isEmpty else {
            if changed {
                keepCurrentPosition()
            } else {
                DocsLogger.info("afterUpdate nothing changed", component: LogComponents.comment)
            }
            return
        }
        let replyIdIsEmpty = (replyId ?? "").isEmpty
        let needFoucus = (preId != nextId) || (position != nil) || !replyIdIsEmpty
        if needFoucus,
           let index = self.commentSections[nextId, replyId] { // 有对齐且不是同一条评论
            DocsLogger.info("afterUpdate align now position:\(position) replyId:\(replyId)", component: LogComponents.comment)
            // 对齐
            scheduler?.reduce(state: .align(indexPath: index, position: position))
            
            let notPresenter = (role == nil || role != .presenter)
            let inVC = docsInfo?.isInVideoConference ?? false
            if !inVC || inVC && notPresenter {
                // bitable需要延后再作为第一响应者
                if docsInfo?.inherentType == .bitable {
                    DocsLogger.info("delay bitable listenKeyboard", component: LogComponents.comment)
                    DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) { [weak self] in
                        guard let self = self else { return }
                        if let item = self.commentSections.modifiableItem?.item, item.viewStatus.isFirstResponser {
                            // 正在输入中不需要再抢焦点
                            return
                        }
                        self.scheduler?.reduce(state: .listenKeyboard)
                    }
                } else {
                    DocsLogger.info("listenKeyboard now", component: LogComponents.comment)
                    scheduler?.reduce(state: .listenKeyboard)
                }
            }
            // 高亮（aside评论目前尚不支持）
            scheduler?.reduce(state: .foucus(indexPath: index, position: .top, highlight: true))
        } else { // 有对齐信息，但是是同一条评论，认为只是不同的协同更新
            // 只是普通更新，需要保持当前UI静止
            if changed {
                keepCurrentPosition()
            } else {
                DocsLogger.info("afterUpdate nothing changed", component: LogComponents.comment)
            }
        }
    }
    
    
    /// 将当前状态转移到newSections中，防止diff之后数据丢失
    /// - Parameters:
    ///   - cancel: 新数据中是否包含取消评论命令
    ///   - nextId: 新数据中激活评论Id，
    ///   - activeComment: 当前激活的评论
    ///   - newSections: 新数据
    private func syncCurrentStatus(cancel: Bool, nextId: String, activeComment: Comment?, newSections: [CommentSection] ) {
        if !cancel, let comment = activeComment {
            var sameComment: Comment?
            if let indexPath = newSections[comment.commentID, nil],
               let newComment = newSections[CommentIndex(indexPath.section)] {
                sameComment = newComment
            }
            let focusItem = comment.commentList.first { $0.viewStatus != .normal }
            if let item = focusItem {
                let newItem = sameComment?.commentList.first(where: {
                    $0.replyID == item.replyID
                })
                if let same = sameComment {
                    // 同步高亮状态
                    same.isActive = true
                    let viewStatus = item.viewStatus
                    newItem?.viewStatus = viewStatus
                    if case .edit = viewStatus {
                        let lastItem = sameComment?.commentList.last
                        if lastItem?.uiType == .footer {
                            lastItem?.viewStatus = .normal
                        }
                    }
                    if comment.commentID == nextId {
                        DocsLogger.info("sync status current is active", component: LogComponents.comment)
                    } else {
                        DocsLogger.info("sync status \(nextId) is active", component: LogComponents.comment)
                    }
                    
                } else { // 评论被解决了，不需要处理，走后面diff
                    DocsLogger.info("sync status commentId:\(comment.commentID) was deleted", component: LogComponents.comment)
                }
            } else {
                // item在无评论权限时可能为空
                DocsLogger.warning("sync status commentId:\(comment.commentID) has no input model", component: LogComponents.comment)
            }
        } // else则为1和4场景，直接走diff
    }
    
    private func handleScrollComment(node: CommentDataQueueNode<CommentAction>) {
        guard case let .scrollComment(commentId, replyId, percent) = node.action else {
            return
        }
        var indexPath = IndexPath(row: 0, section: 0)
        if replyId == "IN_HEADER", let index = commentSections[commentId, nil] {
            indexPath = index
        } else if let index = commentSections[commentId, replyId] {
            indexPath = index
        } else {
            DocsLogger.error("\(Self.identifier) found nil comment when handling scroll comment", component: LogComponents.comment)
            node.markFulfill()
            return
        }
        scheduler?.reduce(state: .scrollToItem(indexPath: indexPath, percent: percent))
        node.markFulfill()
    }
}

// MARK: - IPC
extension CommentAsideDataPlugin {
    
    fileprivate func handleIPC(_ action: CommentAction.IPC, _ callback: CommentAction.IPC.Callback?) {
        switch action {
        case let .refresh(commentId, replyId):
            if let idx = self.commentSections[commentId, replyId] {
                if idx.row == 0 { // 0是虚拟header数据源，表示更新整个section
                    scheduler?.reduce(state: .updateSections([idx.section]))
                } else {
                    scheduler?.reduce(state: .updateItems([idx]))
                }
            }
        case let .resignKeyboard(commentId, replyId):
            handleResignKeyboard(commentId, replyId, callback)

        case .becomeResponser:
            let indexPath = commentSections.setFoucus()
            callback?(indexPath, nil)

        case let .setReplyMode(commentId, becomeResponser):
            handleSetReplyMode(commentId, becomeResponser, callback)

        case let .setEditMode(replyId, becomeResponser):
            handleSetEditMode(replyId, becomeResponser, callback)
            
        case let .fetchIndexPath(commentId, replyId):
            if let indexPath = self.commentSections[commentId, replyId] {
                callback?(indexPath, nil)
            } else {
                callback?(nil, DataIPCError.indexPathNotFound)
            }
        case .setNormalMode:
            if let activeComment = commentSections.activeComment {
                handleNormalMode(activeComment.0)
                callback?(CommentIndex(activeComment.1), nil)
            } else {
                callback?(nil, DataIPCError.commentIndexNotFound)
            }
        
        case .fetchSnapshoot:
            handleFetchSnapshoot(callback)
            
        case .activeNext:
            handleActiveNext(callback)

        case .activePre:
            handleActivePre(callback)
        case .inviteUserDone:
            markInputPermission()
        case .fetchCommentDataDesction:
            handleFetchCommentDataDesction(callback)
        case let .resetDataCache(statsExtra, action):
            switch action {
            case .render:
                let recordedEdit = self.statsExtra?.recordedEdit == true
                if statsExtra == nil, !recordedEdit {
                    return
                }
                self.statsExtra = statsExtra
            case .edit:
                self.statsExtra = statsExtra
            }
        default:
            break
        }
    }
    
    private func handleResignKeyboard(_ commentId: String, _ replyId: String, _ callback: CommentAction.IPC.Callback?) {
        if let indexPath = commentSections[commentId, replyId] {
            commentSections[indexPath]?.viewStatus.resign()
            callback?(indexPath, nil)
        } else {
            callback?(nil, DataIPCError.unknow)
        }
    }
    
    private func handleFetchSnapshoot( _ callback: CommentAction.IPC.Callback?) {
        guard let tuple = commentSections.modifiableItem else {
            callback?(nil, DataIPCError.snapshootNotFound)
            return
        }
        let item = tuple.item
        let index = tuple.index
        let res = CommentSnapshootImpl(commentId: item.commentId ?? "",
                                   replyId: item.replyID,
                                   indexPath: index,
                                   isNewInput: item.isNewInput,
                                   isAcivte: item.isActive,
                                   viewStatus: item.viewStatus)
        callback?(res, nil)
    }
    
    fileprivate func handleNormalMode(_ comment: Comment?) {
        guard let comment = comment else {
            return
        }
        DocsLogger.info("\(comment) set to normal mode", component: LogComponents.comment)
        comment.isActive = false
        comment.commentList.forEach {
            $0.viewStatus = .normal
        }
        scheduler?.reduce(state: .syncData(commentSections))
    }
    
    fileprivate func handleResetActive() {
        commentSections.forEach { section in
            section.model.isActive = false
            section.model.commentList.forEach {
                $0.viewStatus = .normal
            }
        }
        // 失焦的时候去掉没提交的评论
        commentSections = commentSections.filter({ $0.model.interactionType != nil })
        scheduler?.reduce(state: .syncData(commentSections))
        scheduler?.reduce(state: .reload)
    }

    fileprivate func handleSetReplyMode(_ commentId: String?, _ becomeResponser: Bool, _ callback: CommentAction.IPC.Callback?) {
        let activeComment: (Comment, Int)? = commentSections.activeComment
        var nextComment: Comment?
        var nextSection: Int?
        if let commentId = commentId,
           let section = commentSections[commentId, nil]?.section,
           let next = commentSections[CommentIndex(section)] {
            nextComment = next
            nextSection = section
        }
        var response = (CommentIndex.notFound, CommentIndex.notFound)
        if let next = nextComment { // 指定激活某条评论为reply mode
            if let cur = activeComment?.0,
               next.commentID != cur.commentID {
                handleNormalMode(cur)
            }
            replyMode(nextComment, becomeResponser)
            response = (CommentIndex(activeComment?.1 ?? -1), CommentIndex(nextSection ?? -1))
        } else { // 设置当前激活的评论为reply mode
            replyMode(activeComment?.0, becomeResponser)
            response = (CommentIndex.notFound, CommentIndex(activeComment?.1 ?? -1))
        }
        scheduler?.reduce(state: .syncData(commentSections))
        callback?(response, nil)
    }
    
    fileprivate func handleSetEditMode(_ replyId: String, _ becomeResponser: Bool, _ callback: CommentAction.IPC.Callback?) {
        let activeComment = commentSections.activeComment
        if let activeComment = activeComment {
            if let row = editMode(activeComment.comment, replyId, becomeResponser) {
                scheduler?.reduce(state: .syncData(commentSections))
                callback?(IndexPath(row: row, section: activeComment.index), nil)
            } else {
                callback?(nil, DataIPCError.commentIndexNotFound)
            }
        }
    }
    
    fileprivate func replyMode(_ comment: Comment?, _ becomeResponser: Bool) {
        guard let comment = comment else {
            return
        }
        DocsLogger.info("\(comment) set to reply mode becomeResponser:\(becomeResponser)", component: LogComponents.comment)
        comment.isActive = true
        comment.commentList.forEach {
            $0.viewStatus = .normal
        }
        if let item = comment.commentList.last,
           item.uiType == .footer,
           item.canComment {
            switch comment.interactionType {
            case .comment, .none:
                item.viewStatus = .reply(isFirstResponser: becomeResponser)
            case .reaction:
                item.viewStatus = .normal
            }
        }
    }
    
    // 设置replyId为编辑模式并返回其下标
    @discardableResult
    private func editMode(_ comment: Comment, _ replyId: String, _ becomeResponser: Bool) -> Int? {
        // 确保item存在
        let index = comment.commentList.firstIndex { $0.replyID == replyId }
        guard index != nil else {
            return nil
        }
        DocsLogger.info("\(comment) set to edit mode becomeResponser:\(becomeResponser)", component: LogComponents.comment)
        for item in comment.commentList {
            if item.replyID == replyId, item.canComment {
                item.viewStatus = .edit(isFirstResponser: becomeResponser)
            } else {
                item.viewStatus = .normal
            }
        }
        return index
    }
    
    private func handleActiveNext(_ callback: CommentAction.IPC.Callback?) {
        guard let activeComment = commentSections.activeComment else {
            callback?(nil, DataIPCError.unknow)
            return
        }
        let index = activeComment.index
        guard let commentId = commentSections[CommentIndex(index + 1)]?.commentID else {
            callback?(nil, DataIPCError.indexOverflow)
            return
        }
        callback?(commentId, nil)
    }
    
    private func handleActivePre(_ callback: CommentAction.IPC.Callback?) {
        guard let activeComment = commentSections.activeComment else {
            callback?(nil, DataIPCError.unknow)
            return
        }
        let index = activeComment.index
        guard let commentId = commentSections[CommentIndex(index - 1)]?.commentID else {
            callback?(nil, DataIPCError.indexOverflow)
            return
        }
        callback?(commentId, nil)
    }
}

// MARK: - UI Action
extension CommentAsideDataPlugin {
    
    func handleUIAction(_ action: CommentAction.UI) {
        switch action {
        case .inviteUserDone:
            markInputPermission()
        case .hideComment:
            self.isHideComment = true
        case let .didShowAtInfo(item, atInfos):
            let commentId = item.commentId ?? ""
            let cacheKey = "\(commentId)_\(item.replyID)"
            guard !item.replyID.isEmpty else {
                asideAtInfoCache[cacheKey] = nil
                return
            }
            var requestUids: Set<String> = Set()
            for atInfo in atInfos where atInfo.type == .user {
                let uid = atInfo.token
                if !requestUids.contains(uid) {
                    requestUids.insert(uid)
                }
            }
            asideAtInfoCache[cacheKey] = requestUids
        case let .didSelect(comment):
            // 选中非当前未发送的评论的时候，数据过滤掉草稿
            if comment.interactionType != nil {
                commentSections = commentSections.filter({ $0.model.interactionType != nil })
            }
        default:
            break
        }
    }
    
    func markInputPermission() {
        guard let wrapper = commentSections.modifiableItem else { return }
        scheduler?.reduce(state: .refreshAtUserText(at: wrapper.index))
    }
    
    func checkAtPermissions() {
        var requestUids: Set<String> = Set()
        for element in self.asideAtInfoCache {
            let keys = element.key.split(separator: "_")
            guard keys.count == 2 else { continue }
            let commentId = String(keys[0])
            let replyId = String(keys[1])
            guard commentSections[commentId, replyId] != nil else { continue }
            for uid in element.value {
                if !requestUids.contains(uid) {
                    requestUids.insert(uid)
                }
            }
        }
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            self.context?.scheduler?.dispatch(action: .ipc(.prepareForAtUid(uids: requestUids), nil))
        }
    }
}
