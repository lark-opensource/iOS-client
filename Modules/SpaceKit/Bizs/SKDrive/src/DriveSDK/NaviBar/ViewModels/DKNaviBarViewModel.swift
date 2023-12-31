//
//  DKNaviBarViewModel.swift
//  SpaceKit
//
//  Created by Weston Wu on 2020/6/16.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

protocol DKNaviBarViewModelDependency {
    var titleRelay: BehaviorRelay<String> { get }
    var fileDeleted: BehaviorRelay<Bool> { get }
    var rightBarItems: Observable<[DKNaviBarItem]> { get }
    var leftBarItems: Observable<[DKNaviBarItem]> { get }
}

class DKNaviBarViewModel {
    typealias Dependency = DKNaviBarViewModelDependency
    private let titleRelay: BehaviorRelay<String>
    private let fileDeletedRelay: BehaviorRelay<Bool>
    var titleUpdated: Driver<String> {
        return titleRelay.asDriver()
    }
    var fileDeleted: Driver<Bool> {
        return fileDeletedRelay.asDriver()
    }
    var title: String {
        return titleRelay.value
    }
    

    var shouldShowTexts: Bool = true
    var shouldShowSensitivity: Bool = false //是否展示密级标签
    var sensitivityName: String?

    private let rightBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
    private let leftBarItemsRelay = BehaviorRelay<[DKNaviBarItem]>(value: [])
    var sensitivityRelay = BehaviorRelay<String>(value: "")
    
    var rightBarItemsUpdated: Driver<[DKNaviBarItem]> {
        return rightBarItemsRelay.asDriver()
    }
    var rightBarItems: [DKNaviBarItem] {
        return rightBarItemsRelay.value
    }
    
    var leftBarItemsUpdated: Driver<[DKNaviBarItem]> {
        return leftBarItemsRelay.asDriver()
    }
    var leftBarItems: [DKNaviBarItem] {
        return leftBarItemsRelay.value
    }
    var titleVisableRelay = BehaviorRelay<Bool>(value: true)
    
    private let disposeBag = DisposeBag()

    init(dependency: Dependency) {
        titleRelay = dependency.titleRelay
        fileDeletedRelay = dependency.fileDeleted
        dependency.leftBarItems.bind(to: leftBarItemsRelay).disposed(by: disposeBag)
        dependency.rightBarItems.bind(to: rightBarItemsRelay).disposed(by: disposeBag)
    }
    
    static let emptyBarViewModel: DKNaviBarViewModel = {
        let titleRelay = BehaviorRelay<String>(value: "")
        let rightBarItems = Observable<[DKNaviBarItem]>.just([])
        let leftBarItems = Observable<[DKNaviBarItem]>.just([])
        let dependency = DKNaviBarDependencyImpl(titleRelay: titleRelay,
                                                 fileDeleted: BehaviorRelay<Bool>(value: false),
                                                 leftBarItems: leftBarItems,
                                                 rightBarItems: rightBarItems)
        return DKNaviBarViewModel(dependency: dependency)
    }()
}
