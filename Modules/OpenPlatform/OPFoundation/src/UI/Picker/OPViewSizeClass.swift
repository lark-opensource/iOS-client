//
//  OPViewSizeClass.swift
//  EEMicroAppSDK
//
//  Created by yi on 2021/3/24.
//

import Foundation
import LarkTraitCollection
import RxSwift
import LKCommonsLogging

@objcMembers public final class OPViewSizeClass: NSObject {
    let disposeBag = DisposeBag()
    static let logger = Logger.log(OPViewSizeClass.self, category: "OPViewSizeClass")
    var changging = false

    public class func sizeClass(window: UIWindow?) -> UIUserInterfaceSizeClass {
        return window?.lkTraitCollection.horizontalSizeClass ?? .unspecified
    }

    public func traitCollectionChange(view: UIView, didChange: @escaping (UITraitCollection) -> Void) -> Void {
        if view == nil {
            OPViewSizeClass.logger.info("OPViewSizeClass traitCollectionChange view is nil")
            return
        }
        changging = false
        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] change in
                guard change.new != change.old, let self = self else { return }
                guard UIApplication.shared.applicationState != .background else {
                    OPViewSizeClass.logger.info("OPViewSizeClass observeRootTraitCollectionWillChange app is background")
                    return
                }
                guard !self.changging else {
                    OPViewSizeClass.logger.info("OPViewSizeClass observeRootTraitCollectionWillChange changging")
                    return
                }
                self.changging = true
                didChange(change.new)
                self.changging = false
            }).disposed(by: self.disposeBag)

    }
}
