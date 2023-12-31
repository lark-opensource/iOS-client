//
//  FeedSymbol.swift
//  Moment
//
//  Created by zhuheng on 2021/1/7.
//
import UIKit
import Foundation
import LarkMessageCore
import RxSwift
import LarkContainer

enum FeedList { }

extension FeedList {
    /// 这里将每页的获取的最大数量设置较小 优化首屏加载速度
    static let pageCount: Int32 = 8
    static let skeletonCellCount = 5
    enum SourceType {
        case recommand //推荐
        case follow //关注
    }

    enum ErrorType {
        case fetchFirstScreenPostsFail(Error, localDataSuccess: Bool)
        case loadMoreFail(Error)
        case refreshListFail(Error)
    }

    enum TableRefreshType: OuputTaskTypeInfo {
        case localFirstScreenDataRefresh
        case remoteFirstScreenDataRefresh(hasFooter: Bool, style: PostTipStyle?)
        case refresh
        case refreshTable(needResetHeader: Bool = false, hasFooter: Bool, style: PostTipStyle?, trackSence: FeedTrackSence)
        case publishPost
        case refreshCell(indexs: [IndexPath], animation: UITableView.RowAnimation)
        case refreshBoardcast([RawData.Broadcast])

        func canMerge(type: FeedList.TableRefreshType) -> Bool {
            return false
        }
        func duration() -> Double {
            return 0
        }
        func isBarrier() -> Bool {
            return false
        }
    }
}
