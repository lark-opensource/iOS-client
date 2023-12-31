//
//  SpaceVerticalGridViewModel.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/21.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

public protocol SpaceVerticalGridViewModel: AnyObject {
    typealias Action = SpaceSection.Action

    var itemsUpdated: Observable<[SpaceVerticalGridItem]> { get }
    var actionSignal: Signal<Action> { get }

    func prepare()
    func handleMoreAction()
    func didSelect(item: SpaceVerticalGridItem)

    func notifyPullToRefresh()
}
