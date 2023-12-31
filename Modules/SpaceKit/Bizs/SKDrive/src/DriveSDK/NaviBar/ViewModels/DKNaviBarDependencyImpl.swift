//
//  DKNaviBarDependencyImpl.swift
//  SpaceKit
//
//  Created by Weston Wu on 2020/6/30.
//

import Foundation
import RxSwift
import RxRelay
import SpaceInterface

struct DKMoreDependencyImpl: DKMoreViewModel.Dependency {
    let moreVisable: Observable<Bool>
    let moreEnable: Observable<Bool>
    let isReachable: Observable<Bool>
    let saveToSpaceState: Observable<DKSaveToSpaceState>
}

struct DKNaviBarDependencyImpl: DKNaviBarViewModel.Dependency {
    let titleRelay: BehaviorRelay<String>
    let fileDeleted: BehaviorRelay<Bool>
    let leftBarItems: Observable<[DKNaviBarItem]>
    let rightBarItems: Observable<[DKNaviBarItem]>
}
