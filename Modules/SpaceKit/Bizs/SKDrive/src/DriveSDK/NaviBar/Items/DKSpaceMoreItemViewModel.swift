//
//  DKSpaceMoreItemViewModel.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/23.
//

import Foundation
import EENavigator
import RxSwift
import RxRelay
import SpaceInterface
import SKUIKit
import SKCommon
import UniverseDesignBadge
import UniverseDesignIcon

class DKSpaceMoreItemViewModel: DKNaviBarItem {
    private let enableRelay = BehaviorRelay<Bool>(value: false)
    private let visableRelay: BehaviorRelay<Bool>
    private var bag = DisposeBag()
    var badgeStyle: UDBadgeConfig?

    init(enable: Observable<Bool>, visable: Observable<Bool>, isReachable: Observable<Bool>) {
        self.visableRelay = BehaviorRelay<Bool>(value: true)
        visable.bind(to: visableRelay).disposed(by: bag)
        Observable<Bool>.combineLatest(enable, isReachable) { $0 && $1 }
            .bind(to: enableRelay)
            .disposed(by: bag)
    }
    var naviBarButtonID: SKNavigationBar.ButtonIdentifier {
        .more
    }

    var itemIcon: UIImage {
        UDIcon.moreOutlined
    }

    var itemVisable: BehaviorRelay<Bool> {
        visableRelay
    }
    
    var isHighLighted: Bool {
        false
    }

    var itemEnabled: BehaviorRelay<Bool> {
        enableRelay
    }

    func itemDidClicked() -> Action {
        return .presentSpaceMoreVC
    }
}
