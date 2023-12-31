//
//  CommentDiffDataPlugin.swift
//  SKCommon
//
//  Created by huayufan on 2022/8/26.
//  


import UIKit
import SKFoundation
import RxDataSources
import Differentiator
import RxSwift
import RxCocoa
import SpaceInterface
import SKCommon


typealias CommentSection = AnimatableCommentModel

protocol CommentSnapshootType {
    var commentId: String { get }
    var replyId: String { get }
    var indexPath: IndexPath { get }
    var isNewInput: Bool { get }
    var isAcivte: Bool { get }
    var viewStatus: CommentItem.ViewStatus { get }
}

class CommentDiffDataPlugin {
    
    /// 和UI保持一致的数据源
    var commentSections: [CommentSection] = []
    
    var statsExtra: CommentStatsExtra? = nil

    weak var context: CommentServiceContext?
    
    var docsInfo: DocsInfo?
    
    var templateUrlString: String = ""

    var commentPermission: CommentPermission = []
    
    var role: FollowRole = .none
    
    var payload: [String: Any] = [:]

    func apply(context: CommentServiceContext) {
        self.context = context
    }

    init() {}
    
    var scheduler: CommentSchedulerType? { context?.scheduler }
}

extension CommentDiffDataPlugin {
    
    func constructArraySection(_ comments: [Comment]) -> [CommentSection] {
        return comments.map {
            CommentSection(model: $0, items: $0.commentList)
        }
    }
    
    func prepareCurrentPage(_ oldComments: [CommentSection], _ newData: inout CommentData) {
        // 新数据中有指定的index，直接使用
        guard newData.currentPage == nil else { return }
        // 保证有数据
        guard !newData.comments.isEmpty else { return }
        
        // 找出当前激活的评论信息
        guard var (oldComment, currentPage) = oldComments.activeComment else {
            return
        }
        
        let currentCommentId = oldComment.commentID // 旧的commentId
        
        // 新数据是否存在上个激活的评论Id
        let newIndex = newData.comments.firstIndex(where: {
            currentCommentId.isEmpty == false && $0.commentID == currentCommentId
        })

        if let index = newIndex {
            // 找到了之前所在的commentId, 保持在当前页面
            currentPage = index
        } else { // 数据被删除了，下一页
            if currentPage >= newData.comments.count {
                // 数组越界时，显示最后一页
                currentPage = newData.comments.count - 1
            }
        }

        let comment = newData.comments[currentPage]
        newData.currentCommentID = comment.commentID
        newData.currentPage = currentPage
        
        activate(comment: comment)
    }

    func activate(comment: Comment) {
        comment.isActive = true
        comment.commentList.forEach {
            $0.viewStatus = .normal
        }
    }

    func checkMunuAndDismissIfNeed() {
        scheduler?.dispatch(action: .ipc(.fetchMenuKeys, { [weak self] value, _ in
            guard let self = self else { return }
            var dismissKeys: [String] = []
            if let keys = value as? [String],
               !keys.isEmpty {
                for key in keys {
                    let menuKey = key.split(separator: "_").map(String.init)
                    guard menuKey.count == 2 else {
                        continue
                    }
                    let none = CommentMenuKey.none.rawValue
                    let commentId = menuKey[0]
                    let replyId = menuKey[1]
                    if commentId != none,
                       replyId != none {
                        if self.commentSections[commentId, replyId] == nil {
                            dismissKeys.append(key)
                        }
                    } else if commentId != none, replyId == none {
                        if self.commentSections[commentId, nil] == nil {
                            dismissKeys.append(key)
                        }
                    }
                }
            }
            if !dismissKeys.isEmpty {
                self.scheduler?.dispatch(action: .ipc(.dismisMunu(keys: dismissKeys), nil))
            }
        }))
    }
    
    func scrollToBottomWhenSending(_ oldComments: [CommentSection], _ newComments: [CommentSection]) {
        guard let (comment, index) = newComments.activeComment else {
            return
        }
        guard let (oldComment, _) = oldComments.activeComment else {
            return
        }
        guard oldComment.commentID == comment.commentID else { return }
        let oldCount = oldComment.commentList.count
        let count = comment.commentList.count
        guard let commentItem = comment.commentList.last,
              oldCount > 0,
              oldCount < count else {
            return
        }
        if commentItem.userID.isEmpty || commentItem.userID == User.current.info?.userID {
            scheduler?.reduce(state: .foucus(indexPath: IndexPath.init(row: count - 1, section: index), position: .bottom, highlight: false))
        }
    }
    
    func handleFetchCommentDataDesction( _ callback: CommentAction.IPC.Callback?) {
        let count = commentSections.count
        var itemsCount = 0
        for section in commentSections {
            itemsCount += section.items.realCount
        }
        let desction = CommentDiffDataPlugin.CommentDescription(commentCount: count,
                                              replyCount: itemsCount,
                                              statsExtra: statsExtra,
                                              paylod: payload)
        callback?(desction, nil)
    }
}

// MARK: - diff
extension CommentDiffDataPlugin {

    
    /// 对评论数据进行diff 并更新tableView
    /// - Parameters:
    ///   - source: 老数据
    ///   - target: 新数据
    ///   - done: diff update完成， 返回值表示是否有数据变更
   func differences(_ source: [CommentSection], _ target: [CommentSection], tableView: UITableView, done: @escaping ((Bool) -> Void)) {
        do {
            if source.isEmpty || target.isEmpty {
                // 根bitable那边的使用经验，这里可能会crash，直接reload即可
                DocsLogger.info("[diff] reload directly", component: LogComponents.comment)
                self.commentSections = target
                self.scheduler?.reduce(state: .syncData(self.commentSections))
                self.scheduler?.reduce(state: .reload)
                done(true)
            } else {
                DocsLogger.info("[diff] comment begin", component: LogComponents.comment)
                let stagedChangeset = try Diff.differencesForSectionedView(initialSections: source, finalSections: target)
                if stagedChangeset.isEmpty {
                    DocsLogger.info("[diff] comment done -- empty", component: LogComponents.comment)
                    done(false)
                }
                for (idx, changeset) in stagedChangeset.enumerated() {
                    let updateBlock = { [weak self] in
                        guard let self = self else { return }
                        var updateIdxs: [IndexPath]?
                        if !changeset.updatedItems.isEmpty {
                            updateIdxs = changeset.updatedItems.map { IndexPath(row: $0.itemIndex, section: $0.sectionIndex) }
                         }
                        let finalSections = changeset.finalSections
                        finalSections.forEach {
                            $0.model.commentList = $0.items
                        }
                        self.commentSections = finalSections
                        changeset.printDiff(with: finalSections)
                        self.scheduler?.reduce(state: .diffResult(finalSections, updateIdxs))
                        let animationConfiguration = AnimationConfiguration(insertAnimation: .none,
                                                        reloadAnimation: .none,
                                                        deleteAnimation: .none)
                        tableView.batchUpdates(changeset,
                                               animationConfiguration: animationConfiguration)
                    }
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    tableView.performBatchUpdates(updateBlock) {  [weak self] _ in
                        if idx == stagedChangeset.count - 1 {
                            done(true)
                        }
                        CATransaction.commit()
                        self?.scheduler?.reduce(state: .batchUpdatesCompletion)
                    }
                }
                DocsLogger.info("[diff] comment done", component: LogComponents.comment)
            }
        } catch {
            DocsLogger.error("[diff] failed with error", error: error, component: LogComponents.comment)
            done(true)
            self.scheduler?.reduce(state: .reload)
        }
    }
}


struct CommentIndex {
    private(set) var value: Int
    
    static let notFound = CommentIndex(-1)
    
    init(_ value: Int) { self.value = value }
}

extension Array where Element == CommentSection {

    /// replyId为空时返回comment位置，都有值时返回commentItem位置
    subscript(commentId: String, replyId: String?) -> IndexPath? {
        if let replyId = replyId, !replyId.isEmpty {
            for i in 0..<self.count {
                if self[i].model.commentID != commentId {
                    continue
                }
                if let index = self[i].items.firstIndex(where: { $0.replyID == replyId }) {
                    return IndexPath(row: index, section: i)
                }
            }
        } else if !commentId.isEmpty {
            if let index = self.firstIndex(where: { $0.model.commentID == commentId }) {
                return IndexPath(row: 0, section: index)
            }
        }
        return nil
    }

    subscript(indexPath: IndexPath) -> CommentItem? {
        if indexPath.section <= self.count - 1,
           indexPath.row >= 0,
           indexPath.row <= self[indexPath.section].items.count - 1 {
           return self[indexPath.section].items[indexPath.row]
        }
        return nil
    }
    
    subscript(index: CommentIndex) -> Comment? {
        if index.value <= self.count - 1, index.value >= 0 {
            return self[index.value].model
        }
        return nil
    }
    
    var activeComment: (comment: Comment, index: Int)? {
        guard let index = self.firstIndex(where: { $0.model.isActive }) else {
            return nil
        }
        return (self[index].model, index)
    }
    
    /// 清空键盘状态
    func setResign() -> IndexPath? {
        guard let tuple = modifiableItem else {
            return nil
        }
        tuple.item.viewStatus.resign()
        return tuple.index
    }
    
    /// 设置键盘激活状态
    func setFoucus() -> IndexPath? {
        guard let tuple = modifiableItem else {
            return nil
        }
        tuple.item.viewStatus.focus()
        return tuple.index
    }
    
    var modifiableItem: (item: CommentItem, index: IndexPath)? {
        if let (comment, section) = activeComment {
            for (idx, item) in comment.commentList.enumerated() where item.viewStatus != .normal {
                return (item, IndexPath(row: idx, section: section))
            }
            DocsLogger.error("viewStatus error", component: LogComponents.comment)
        }
        return nil
    }
}

// MARK: internal data
extension CommentDiffDataPlugin {
    
    enum DataIPCError: Error {
        case indexPathNotFound
        case commentIndexNotFound
        case snapshootNotFound
        case indexOverflow
        case unknow
    }
    
    struct CommentSnapshootImpl: CommentSnapshootType {
        var commentId: String
        var replyId: String
        var indexPath: IndexPath
        var isNewInput: Bool
        var isAcivte: Bool
        var viewStatus: CommentItem.ViewStatus
    }
    
    struct CommentDescription {
        let commentCount: Int
        let replyCount: Int
        var statsExtra: CommentStatsExtra?
        var paylod: [String: Any]
    }
}
