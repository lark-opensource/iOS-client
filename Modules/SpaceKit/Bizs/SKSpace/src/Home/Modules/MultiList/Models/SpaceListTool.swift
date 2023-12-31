//
//  SpaceListTool.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/4.
//

import Foundation
import RxSwift
import RxRelay
import SKCommon

public enum SpaceListTool {
    // 列表过滤器
    case filter(stateRelay: BehaviorRelay<SpaceListFilterState>,
                isEnabled: Observable<Bool>,
                clickHandler: (UIView) -> Void)

    //排序
    case sort(stateRelay: BehaviorRelay<SpaceListFilterState>,
              titleRelay: BehaviorRelay<String>,
              isEnabled: Observable<Bool>,
              clickHandler: (UIView) -> Void)

    // 列表模式切换
    case modeSwitch(modeRelay: BehaviorRelay<SpaceListDisplayMode>, clickHandler: (UIView) -> Void)

    // 文件夹more按钮，仅在导航栏出现
    case more(isEnabled: Observable<Bool>, clickHandler: (UIView) -> Void)
    
    // 将排序，筛选，视图切换组合起来的面板
    case controlPanel(filterStateRelay: BehaviorRelay<SpaceListFilterState>,
                      sortStateRelay: BehaviorRelay<SpaceListFilterState>,
                      clickHandler: (UIView) -> Void)
}
