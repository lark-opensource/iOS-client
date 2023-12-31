//
//  UniversalRecommendPresentable.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/24.
//

import UIKit
import Foundation
import RxSwift
import RustPB
import LarkSDKInterface
import LarkSearchCore
import RxCocoa
import LarkSearchFilter

protocol UniversalRecommendPresentable: AnyObject {
    // Output
    var shouldReloadData: Observable<Void> { get }
    var shouldInsertRows: Observable<(Int, [IndexPath])> { get }
    var shouldDeleteRows: Observable<(Int, [IndexPath])> { get }
    var status: Driver<UniversalRecommendViewModel.Status> { get }

    func requestIfNeeded()

    // Track
    func trackShow()

    func changeFilterStyle(_ style: FilterBarStyle)
    // Forward
    var delegate: UniversalRecommendDelegate? { get set }
    var trackingDelegate: UniversalRecommendTrackingDelegate? { get set }

    var currentWidth: (() -> CGFloat?)? { get set }
    var currentVC: (() -> UIViewController?)? { get set }

    // TableView
    var numberOfSections: Int { get }
    func numberOfRows(forSection section: Int) -> Int
    func heightForCell(forIndexPath indexPath: IndexPath) -> CGFloat
    var registeredCellTypes: Set<String> { get set }
    var headerTypes: [UniversalRecommendHeaderProtocol.Type] { get }
    var footerTypes: [UniversalRecommendFooterProtocol.Type] { get }
    func headerType(forSection section: Int) -> UniversalRecommendHeaderProtocol.Type?
    func headerHeight(forSection section: Int) -> CGFloat
    func footerType(forSection section: Int) -> UniversalRecommendFooterProtocol.Type?
    func footerHeight(forSection section: Int) -> CGFloat
    func cellType(forIndexPath indexPath: IndexPath) -> SearchCellProtocol.Type?
    func headerViewModel(forSection section: Int) -> UniversalRecommendHeaderPresentable?
    func cellViewModel(forIndexPath indexPath: IndexPath) -> SearchCellPresentable?
    func selectItem(atIndexPath indexPath: IndexPath, from vc: UIViewController)
    func willDisplay(atIndexPath indexPath: IndexPath)
    func reloadData()

    // KeyBinding
    func firstFocusPosition() -> UniversalRecommendViewController.FocusInfo?
    func canFocus(info: IndexPath) -> Bool
}

extension UniversalRecommendPresentable {
    func trackShow() {}
}
