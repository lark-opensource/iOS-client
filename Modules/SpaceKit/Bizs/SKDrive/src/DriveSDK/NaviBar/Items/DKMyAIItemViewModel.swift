//
//  DKMyAIItemViewModel.swift
//  SKDrive
//
//  Created by zenghao on 2023/8/31.
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
import LarkContainer

class DKMyAIItemViewModel: DKNaviBarItem {
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
        .aiChatMode
    }

    var itemIcon: UIImage {
        let service = try? Container.shared.resolve(assert: CCMAILaunchBarService.self)
        let udSize = CGSize(width: 24, height: 24) // UDIcon的默认尺寸
        if let image = service?.getQuickLaunchBarAIItemInfo().value,
           let resizedImage = image.getResizeImageBySize(udSize) {
            return resizedImage
        }
        
        return UDIcon.myaiColorful
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
        return .presentMyAIVC
    }
    
    // My AI 需要显示彩色icon
    var useOriginRenderedImage: Bool {
        return true
    }
}
