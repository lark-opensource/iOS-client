//
//  CategorySymbol.swift
//  Moment
//
//  Created by liluobin on 2021/4/28.
//
import UIKit
import Foundation
import LarkMessageCore
import RxSwift
import LarkContainer

enum CategoryDetailInputs {
    case categoryEntity(_ entity: RawData.PostCategory)
    case categoryID(_ ID: String)
    var id: String {
        var categoryID = ""
        switch self {
        case .categoryEntity(let category):
            categoryID = category.category.categoryID
        case .categoryID(let cId):
            categoryID = cId
        }
        return categoryID
    }
}

enum PostList { }

extension PostList {
    static let pageCount: Int32 = 8
    static let skeletonCellCount = 5
    enum ErrorType {
        case fetchFirstScreenPostsFail(Error, localDataSuccess: Bool)
        case loadMoreFail(Error)
        case refreshListFail(Error)
    }

    enum TableRefreshType: OuputTaskTypeInfo {
        case remoteFirstScreenDataRefresh(hasFooter: Bool, style: PostTipStyle?)
        case refresh
        case refreshTable(needResetHeader: Bool = false, hasFooter: Bool, style: PostTipStyle?)
        case refreshCell(indexs: [IndexPath], animation: UITableView.RowAnimation)
        func canMerge(type: PostList.TableRefreshType) -> Bool {
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
