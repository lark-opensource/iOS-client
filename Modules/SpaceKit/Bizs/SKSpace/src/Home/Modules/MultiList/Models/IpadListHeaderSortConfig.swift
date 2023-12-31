//
//  IpadListHeaderSortConfig.swift
//  SKSpace
//
//  Created by majie.7 on 2023/9/28.
//

import Foundation
import RxSwift
import RxCocoa

// ipad Space列表表头展示信息的一些配置
public class IpadListHeaderSortConfig {
    typealias Index = IpadSpaceSubListHeaderView.Index
    typealias Option = SpaceSortHelper.SortOption
    
    var sortOptions: [Option]
    var selectSortOptionDriver: Driver<(Index, Option)>?
    var displayModeRelay: BehaviorRelay<SpaceListDisplayMode>
    
    init(sortOption: [SpaceSortHelper.SortOption],
         displayModeRelay: BehaviorRelay<SpaceListDisplayMode>,
         selectSortOptionDriver: Driver<(Index, Option)>? = nil) {
        self.sortOptions = sortOption
        self.displayModeRelay = displayModeRelay
        self.selectSortOptionDriver = selectSortOptionDriver
    }
    
}
