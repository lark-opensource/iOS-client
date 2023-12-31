//
//  DKConfidentItemViewModel.swift
//  SKDrive
//
//  Created by majie.7 on 2021/11/30.
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
import UniverseDesignColor


class DKSensitivtyItemViewModel: DKNaviBarItem {
    
    private let visableRelay: BehaviorRelay<Bool>
    private let settedRelay: BehaviorRelay<Bool>
    private let disposeBag = DisposeBag()
    
    var badgeStyle: UDBadgeConfig?
    
    init(visable: Observable<Bool>) {
        self.visableRelay = BehaviorRelay<Bool>(value: true)
        self.settedRelay = BehaviorRelay<Bool>(value: false)
        self._itemIcon = UDIcon.safeSettingsOutlined.ud.withTintColor(UDColor.iconN3)
        visable.bind(to: visableRelay).disposed(by: disposeBag)
    }
    
    var naviBarButtonID: SKNavigationBar.ButtonIdentifier {
        .sensitivity
    }
    
    var itemIcon: UIImage {
        return _itemIcon
    }
    
    var isHighLighted: Bool {
        false
    }
    
    var itemVisable: BehaviorRelay<Bool> {
        visableRelay
    }
    
    func itemDidClicked() -> Action {
        .presentSercetSetting
    }
    
    var _itemIcon: UIImage
}
