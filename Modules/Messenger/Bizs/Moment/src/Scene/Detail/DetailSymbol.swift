//
//  DetailSymbol.swift
//  Moment
//
//  Created by zhuheng on 2021/1/7.
//

import UIKit
import Foundation
import LarkMessageCore
import RxSwift
import LarkContainer

enum Detail { }

extension Detail {
    static let commentPageCount: Int32 = 20

    enum Sections: Int {
        case post //动态
        case hotComments //热评
        case comments //评论
        static func == (lhs: Int, rhs: Detail.Sections) -> Bool {
            return lhs == rhs.rawValue
        }
    }

    enum SubIndexInComments: Int {
        case hot //热评
        case normal //评论
    }

    enum Inputs {
        case entity(_ entity: RawData.PostEntity)
        case postID(_ ID: String)
    }

    enum ViewType {
        case all
        case empty
        case postAndHotComment
        case onlyComment
    }

    public enum ErrorType {
        case fetchPostFail(Error)
        case loadMoreFail(Error)
        case sendCommentFail(Error)
    }

    struct ScrollInfo {
        public let indexPath: IndexPath
        public let tableScrollPosition: UITableView.ScrollPosition
        public let highlightCommentId: String?
        public let animation: Bool
        public init(indexPath: IndexPath,
                    tableScrollPosition: UITableView.ScrollPosition = .top,
                    highlightCommentId: String? = nil,
                    animation: Bool = false) {
            self.indexPath = indexPath
            self.tableScrollPosition = tableScrollPosition
            self.highlightCommentId = highlightCommentId
            self.animation = animation
        }
    }

    enum TableRefreshType: OuputTaskTypeInfo {
        case postInitRefresh
        case firstScreenCommentRefresh(hasHeader: Bool, hasFooter: Bool, scrollTo: Detail.ScrollInfo?, sdkCost: TimeInterval)
        case refresh
        case refreshTable(hasHeader: Bool, hasFooter: Bool, scrollTo: Detail.ScrollInfo?)
        case publishComment
        case scroll(ScrollInfo)
        case postDelete
        case postDeletedBySelf
        case refreshCell(indexs: [IndexPath], animation: UITableView.RowAnimation)
        case unsupportType

        func canMerge(type: Detail.TableRefreshType) -> Bool {
            return false
        }

        func duration() -> Double {
            var duration: Double = 0
            switch self {
            case .firstScreenCommentRefresh(_, _, let scrollTo, _):
                duration = scrollTo?.highlightCommentId != nil ? MomentCommonCell.highlightDuration : 0.1
            case .refreshTable(_, _, let scrollTo):
                duration = scrollTo?.highlightCommentId != nil ? MomentCommonCell.highlightDuration : 0.1
            case .publishComment:
                duration = 0.1
            case .scroll(let scrollInfo):
                duration = scrollInfo.highlightCommentId != nil ? MomentCommonCell.highlightDuration : 0.1
            case .postDeletedBySelf, .refreshCell, .postInitRefresh, .postDelete, .refresh, .unsupportType:
                break
            }
            return duration
        }

        func isBarrier() -> Bool {
            return false
        }
    }
}
