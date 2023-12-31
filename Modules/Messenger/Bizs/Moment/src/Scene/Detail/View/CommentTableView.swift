//
//  CommentTableView.swift
//  Moment
//
//  Created by zhuheng on 2021/1/7.
//

import UIKit
import Foundation
import LarkMessageCore
import RichLabel
import SnapKit

protocol CommentTableViewDelegate: AnyObject {
    func loadTopComments(finish: @escaping (ScrollViewLoadMoreResult) -> Void)
    func loadMoreCommens(finish: @escaping (ScrollViewLoadMoreResult) -> Void)
    func commentCellViewModel(indexPath: IndexPath) -> MomentsCommentCellViewModel?
    func postCellViewModel(indexPath: IndexPath) -> MomentPostCellViewModel?
}

final class CommentTableView: CommonTable, PostCellCanHandleLongPress {
    weak var commentTableViewDelegate: CommentTableViewDelegate?
    private(set) var longPressGesture: UILongPressGestureRecognizer!

    init() {
        super.init(frame: .zero, style: .grouped)
        self.contentInsetAdjustmentBehavior = .never
        self.longPressGesture = self.lu.addLongPressGestureRecognizer(action: #selector(bubbleLongPressed(_:)), duration: 0.2, target: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    public func bubbleLongPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            // locationInSelf
            let location = gesture.location(in: self)
            self.showMenu(location: location, gesture: gesture)
        default:
            break
        }
    }

    func showMenu(location: CGPoint, gesture: UIGestureRecognizer) {
        guard let indexPath = self.indexPathForRow(at: location),
            let cell = self.cellForRow(at: indexPath) as? MomentCommonCell,
            cell.bounds.contains(self.convert(location, to: cell)) else {
            return
        }
        //长按评论
        if let cellVM = self.commentTableViewDelegate?.commentCellViewModel(indexPath: indexPath) {
            cellVM.showMenu(cell, location: self.convert(location, to: cell), triggerGesture: gesture)
            return
        }
        //长按动态
        if let cellVM = self.commentTableViewDelegate?.postCellViewModel(indexPath: indexPath) {
            let location = self.convert(location, to: cell)
            let result = self.canHandle(cell: cell, location: location)
            if result.canHandle {
                cellVM.showMenu(cell, location: self.convert(location, to: cell), triggerGesture: gesture)
                if result.key == MomentsActionBarComponentConstant.thumbsUpKey.rawValue {
                    cellVM.trackFeedPageViewClick(.reaction_press)
                    cellVM.trackDetailPageClick(.reaction_press)
                } else {
                    cellVM.trackDetailPageClick(.post_press)
                }
            }
            return
        }
    }

    override func loadMoreBottomContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        commentTableViewDelegate?.loadMoreCommens(finish: finish)
    }

    override func loadMoreTopContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        commentTableViewDelegate?.loadTopComments(finish: finish)
    }
}
