//
//  DemoAppNavigationMockDependency.swift
//  LarkTourDev
//
//  Created by Meng on 2020/5/22.
//

import Foundation
import LarkTourInterface
import LarkNavigation
import RxSwift
import LarkContainer

class DemoAppNavigationMockDependency: NavigationMockDependency {
    @Provider var tourSerivce: TourService

    override func checkOnboardingIfNeeded() -> Observable<Void> {
        return tourSerivce.checkOnboardingIfNeeded()
    }
}
