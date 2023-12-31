//
//  ProfileSymbol.swift
//  Moment
//
//  Created by liluobin on 2021/3/9.
//

import UIKit
import Foundation
import LarkMessageCore
import RxSwift
import LarkContainer

enum UserPostList { }

extension UserPostList {
    static let pageCount: Int32 = 8
    static let skeletonCellCount = 5

    public enum ErrorType {
        case fetchFirstScreenPostsFail(Error, localDataSuccess: Bool)
        case loadMoreFail(Error)
        case refreshListFail(Error)
    }

    enum TableRefreshType: OuputTaskTypeInfo {
        case remoteFirstScreenDataRefresh(hasFooter: Bool)
        case refresh
        case delePost
        case refreshTable(needResetHeader: Bool = false, hasFooter: Bool)
        case refreshCell(indexs: [IndexPath], animation: UITableView.RowAnimation)

        func canMerge(type: UserPostList.TableRefreshType) -> Bool {
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

enum UserFollowList { }

extension UserFollowList {
    static let pageCount: Int32 = 20
    static let skeletonCellCount = 20

    public enum ErrorType {
        case fetchFirstScreenDataFail(Error)
        case loadMoreFail(Error)
        case refreshListFail(Error)
    }

    enum TableRefreshType: OuputTaskTypeInfo {

        case remoteFirstScreenDataRefresh(hasFooter: Bool)
        case refreshTable(needResetHeader: Bool = false, hasFooter: Bool)

        func canMerge(type: UserFollowList.TableRefreshType) -> Bool {
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
