//
//  CCMAILaunchBarService.swift
//  CCMMod
//
//  Created by ByteDance on 2023/6/16.
//

import Foundation
import UIKit
import SpaceInterface
import LarkContainer
import RxSwift
import RxCocoa
#if MessengerMod
import LarkMessengerInterface
#endif

class CCMAILaunchBarServiceImpl: CCMAILaunchBarService {
    
    private let resolver: UserResolver
    
    private let disposeBag = DisposeBag()
    
    init(resolver: UserResolver) {
        self.resolver = resolver
    }
    
    func getQuickLaunchBarAIItemInfo() -> BehaviorRelay<UIImage> {
        #if MessengerMod
        if let service = try? resolver.resolve(assert: MyAIQuickLaunchBarService.self) {
            let oldRelay = service.getQuickLaunchBarItemInfo(type: .ai(nil))
            let newRelay = BehaviorRelay<UIImage>(value: oldRelay.value.image)
            oldRelay.subscribe(onNext: { [weak newRelay] in
                newRelay?.accept($0.image)
            }).disposed(by: disposeBag)
            return newRelay
        } else {
            return BehaviorRelay<UIImage>(value: .init())
        }
        #endif
        return BehaviorRelay<UIImage>(value: .init())
    }
}
