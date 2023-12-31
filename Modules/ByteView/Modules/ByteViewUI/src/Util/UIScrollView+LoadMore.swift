//
//  UIScrollView+LoadMore.swift
//  ByteViewUI
//
//  Created by kiri on 2023/2/24.
//

import Foundation

extension UIScrollView {
    private static var loadingDelegateKey = 0 as UInt8

    public var loadMoreDelegate: UIScrollViewLoadingDelegate? {
        let delegate = objc_getAssociatedObject(self, &Self.loadingDelegateKey) as? UIScrollViewLoadingDelegate
        if delegate == nil, let obj = UIDependencyManager.dependency?.createScrollViewLoadingDelegate(for: self) {
            objc_setAssociatedObject(self, &Self.loadingDelegateKey, obj, .OBJC_ASSOCIATION_RETAIN)
            return obj
        }
        return delegate
    }
}
