//
//  RootTraitCollectionObserver.swift
//  LarkUIKit
//
//  Created by Meng on 2019/8/30.
//

import Foundation
import RxSwift

public protocol RootTraitCollectionObserver: AnyObject {

    func observeRootTraitCollectionWillChange(
        for node: RootTraitCollectionNodeType
    ) -> Observable<TraitCollectionChange>

    func observeRootTraitCollectionDidChange(
        for node: RootTraitCollectionNodeType
    ) -> Observable<TraitCollectionChange>
}
