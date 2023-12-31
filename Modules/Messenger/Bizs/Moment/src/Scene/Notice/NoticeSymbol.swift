//
//  NoticeSymbol.swift
//  Moment
//
//  Created by liluobin on 2021/2/24.
//

import Foundation
import LarkMessageCore
import RxSwift
import LarkContainer
import LarkUIKit

enum NoticeList { }

extension NoticeList {
    static let pageCount: Int32 = 20
    static let skeletonCellCount = Display.pad ? 15 : 10

    enum SourceType {
        case reaction
        case message
    }

    public enum ErrorType {
        case fetchFirstScreenDataFail(Error)
        case loadMoreFail(Error)
        case refreshListFail(Error)
    }

    enum TableRefreshType: OuputTaskTypeInfo {
        case remoteFirstScreenDataRefresh(hasFooter: Bool)
        case refreshTable(needResetHeader: Bool = false, hasFooter: Bool)
        case onlyRefresh
        func canMerge(type: NoticeList.TableRefreshType) -> Bool {
            false
        }

        func duration() -> Double {
            return 0
        }
        func isBarrier() -> Bool {
            return false
        }
    }
}
