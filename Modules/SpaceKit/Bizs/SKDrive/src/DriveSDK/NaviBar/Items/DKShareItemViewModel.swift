//
//  DKShareItemViewModel.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/22.
//

import Foundation
import SKResource
import EENavigator
import RxSwift
import RxRelay
import SpaceInterface
import SKUIKit
import SKCommon
import UniverseDesignBadge
import UniverseDesignIcon

class DKShareItemViewModel: DKNaviBarItem {
    private let enableRelay = BehaviorRelay<Bool>(value: false)
    private let visableRelay: BehaviorRelay<Bool>
    private var bag = DisposeBag()
    var itemDidClickAction: (() -> Void)?
    var badgeStyle: UDBadgeConfig?

    init(enable: Observable<Bool>, visable: Observable<Bool>, isReachable: Observable<Bool>) {
        self.visableRelay = BehaviorRelay<Bool>(value: true)
        visable.bind(to: visableRelay).disposed(by: bag)
        Observable<Bool>.combineLatest(enable, isReachable) { $0 && $1 }
            .bind(to: enableRelay)
            .disposed(by: bag)
    }
    var naviBarButtonID: SKNavigationBar.ButtonIdentifier {
        .share
    }

    var itemIcon: UIImage {
        UDIcon.shareOutlined
    }

    var itemVisable: BehaviorRelay<Bool> {
        visableRelay
    }

    var itemEnabled: BehaviorRelay<Bool> {
        enableRelay
    }
    
    var isHighLighted: Bool {
        false
    }

    func itemDidClicked() -> Action {
        itemDidClickAction?()
        return .presentShareVC
    }
}
