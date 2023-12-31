//
//  MeetTabCellViewModelDelagate.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import Foundation
import Action
import RxCocoa
import UniverseDesignIcon

class MeetTabCellViewModel: DiffDataProtocol {

    struct TraitStyle: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        static let regular = TraitStyle(rawValue: 1)
        static let compact = TraitStyle(rawValue: 1 << 1)
    }

    typealias Match = String

    typealias Sort = Int64

    var sortKey: Int64 { return 0 }

    var matchKey: String { return "" }

    var loadTime: Int64 { return 0 }

    var cellIdentifier: String { return "" }

    var startTimeInterval: Int64 { return 0 }

    /// 控制是否隐藏
    var visibleInTraitStyle: TraitStyle { return [.compact, .regular] }

    var meetingID: String { return "" }

    static let timer: Driver<Int> = Driver.interval(.seconds(1)).startWith(1)
}

struct MeetTabSectionViewModel {
    var title: String
//    var icon: UDIconType?
    var textColor: UIColor?
    var iconColor: UIColor?
    var animationPath: String?
    var isLoadMore: Bool = false
    var showSeparator: Bool = true
    var moreAction: CocoaAction?
    var loadStatus: MeetTabResultStatus = .result
    var loadAction: CocoaAction?

    var sectionHeaderIdentifier: String = MeetTabHistoryDataSource.sectionHeaderIdentifier
    var padSectionHeaderIdentifier: String = MeetTabHistoryDataSource.padSectionHeaderIdentifier
    var sectionFooterIdentifier: String = MeetTabHistoryDataSource.sectionFooterIdentifier
    var padSectionFooterIdentifier: String = MeetTabHistoryDataSource.padSectionFooterIdentifier
    var loadMoreSectionFooterIdentifier: String = MeetTabHistoryDataSource.loadMoreSectionFooterIdentifier
    var padLoadMoreSectionFooterIdentifier: String = MeetTabHistoryDataSource.padLoadMoreSectionFooterIdentifier
    // disable-lint: magic number
    var headerHeightGetter: (Bool) -> CGFloat = { isRegular in
        isRegular ? 60.0 : 46.0
    }

    var footerHeightGetter: (MeetTabResultStatus, Bool) -> CGFloat = { loadStatus, isRegular in
        if loadStatus != .result {
            return isRegular ? 50.0 : 42.0
        } else {
            return isRegular ? 16.0 : 7.0
        }
    }
    // enable-lint: magic number
}
