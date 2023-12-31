//
//  BTCatalogueTitleView.swift
//  SKSheet
//
//  Created by huayufan on 2021/3/23.
//  


import UIKit
import SKCommon
import RxSwift
import RxCocoa

final class BTCatalogueTitleView: DraggableTitleView {}

extension Reactive where Base: BTCatalogueTitleView {
    
    var title: Binder<String> {
        return Binder(base) { (target, text) in
            target.setTitle(text)
        }
    }
    
}
