//
//  SheetBrowserViewController+FeelGood.swift
//  SKSheet
//
//  Created by huayufan on 2021/2/3.
//  


import SKCommon

extension SheetBrowserViewController: BusinessInterceptor {
    
    public var hasOtherInterceptEvent: Bool {
       return hasFabPanel
    }
    
    var hasFabPanel: Bool {
        return view.subviews.contains { $0.isKind(of: SheetToolkitHostView.self) }
    }
}
