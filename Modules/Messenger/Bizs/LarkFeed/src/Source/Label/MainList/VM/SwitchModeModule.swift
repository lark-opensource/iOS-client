//
//  SwitchModeModule.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/22.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkSDKInterface
import RustPB
import UniverseDesignToast
import ThreadSafeDataStructure
import RunloopTools
import LKCommonsLogging
import LarkPerf
import LarkModel
import AppReciableSDK

final class SwitchModeModule {

    enum Mode {
        case standardMode,
             threeBarMode(Int)
        static func != (lhs: Mode, rhs: Mode) -> Bool {
            if case .standardMode = lhs,
               case .standardMode = rhs {
                return false
            }
            if case .threeBarMode(let left) = lhs,
               case .threeBarMode(let right) = rhs,
               left == right {
                return false
            }
            return true
        }
    }

    private let disposeBag = DisposeBag()
    var mode: Mode {
        return switchModeRelay.value
    }
    private let switchModeRelay = BehaviorRelay<SwitchModeModule.Mode>(value: SwitchModeModule.Mode.standardMode)
    var switchModeObservable: Observable<SwitchModeModule.Mode> {
        return switchModeRelay.asObservable()
    }
    private let dataModule: LabelMainListDataModule
    private let expandedModule: ExpandedModule

    init(dataModule: LabelMainListDataModule,
         expandedModule: ExpandedModule) {
        self.dataModule = dataModule
        self.expandedModule = expandedModule
    }

    func update(mode: SwitchModeModule.Mode) {
        switch mode {
        case .standardMode:
            break
        case .threeBarMode(let labelId):
            self.expandedModule.updateExpandState(id: labelId, isExpand: true)
        }
        switchModeRelay.accept(mode)
        dataModule.trigger()
    }
}
