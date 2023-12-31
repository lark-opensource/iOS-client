//
//  NameCardListViewModel.swift
//  LarkContact
//
//  Created by Aslan on 2021/4/18.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkUIKit
import LarkContainer
import LKCommonsLogging
import LarkSDKInterface
import ThreadSafeDataStructure
import LarkFeatureGating
import LarkAccountInterface
import LarkMessengerInterface
import RustPB
import LarkTag

protocol NameCardListCellViewModel {
    var avatarKey: String { get }
    var displayTitle: String { get }
    var displaySubTitle: String { get }
    var entityId: String { get }
    var itemTags: [Tag]? { get }
    var avatarImage: UIImage? { get }

    // handleSelect
    func didSelect(fromVC: UIViewController, accountID: String, resolver: UserResolver)
}

enum NameCardListResult {
    case empty
    case success(datasource: [NameCardListCellViewModel])
    case failure(error: Error)
}

protocol NameCardListViewModel {
    var datasourceDriver: Driver<NameCardListResult> { get }

    var itemRemoveDriver: Driver<Int>? { get }

    var canLeftDelete: Bool { get }

    var hasMore: Bool { get }

    var headerTitle: String? { get }

    // Mail account id which this name card or mail group belong to.
    var accountID: String { get }

    // Mail address which this name card or mail group belong to.
    var mailAddress: String { get }

    var mailAccountType: String { get }

    // actions
    func fetchNameCardList(isRefresh: Bool)

    func removeData(deleteNameCardInfo: NameCardListCellViewModel, atIndex: Int)

    func enableRemveAction(item: NameCardListCellViewModel) -> Bool

    // statitics
    func pageDidView()
}
