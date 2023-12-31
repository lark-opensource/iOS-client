//
//  NavigationDependencyImpl.swift
//  LarkApp
//
//  Created by CharlieSu on 11/29/19.
//

import Foundation
import RxSwift
import Swinject
//import ByteViewDemo
import LarkContainer
import RxCocoa
import ByteViewTab

class LarkNavigationAssembly: Assembly {

    public init() { }

    public func assemble(container: Container) {
        container.register(NavigationDependency.self) { _ -> NavigationDependency in
            return NavigationDependencyImpl()
        }
    }
}

private class NavigationDependencyImpl: NavigationDependency {

    func checkOnboardingIfNeeded() -> Observable<Void> {
        .just(Void())
    }

    var shouldNoticeNewVerison: Observable<Bool> {
        .just(false)
    }

    var doNotDisturbType: Observable<NaviBarDoNotDisturbType> {
        .just(.normal)
    }

    var mailEnable: Bool {
        return false
    }

    func notifyMailNaviEnabled() {
    }

    func notifyVideoConferenceTabEnabled() {
    }

    func updateBadge(to count: Int) {
    }

    func getSearchVC(fromTabURL: URL?, sourceOfSearchStr: String?, entryAction: String) -> UIViewController? {
        return nil
    }
    func getSearchOnPadEntranceView() -> UIView {
        return .init()
    }
    func changeSelectedState(isSelect: Bool) {
    }

    func enableUseNewSearchEntranceOnPad() -> Bool {
        return false
    }
}
