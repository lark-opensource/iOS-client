//
//  UDSkeleton.swift
//  UniverseDesignLoading
//
//  Created by Miaoqi Wang on 2020/11/9.
//

import UIKit
import Foundation
import UniverseDesignTheme
import SkeletonView

/// Conform to UITableViewDataSource, and do additional work
public typealias UDSkeletonTableViewDataSource = SkeletonTableViewDataSource
/// Conform to UITableViewDelegate, and do additional work
public typealias UDSkeletonTableViewDelegate = SkeletonTableViewDelegate
/// Conform to UICollectionViewDataSource, and do additional work
public typealias UDSkeletonCollectionViewDataSource = SkeletonCollectionViewDataSource
/// Conform to UICollectionViewDelegate, and do additional work
public typealias UDSkeletonCollectionViewDelegate = SkeletonCollectionViewDelegate
/// Alias for String
public typealias ReusableCellIdentifier = SkeletonView.ReusableCellIdentifier

extension UIView {
    private struct AssociatedKeys {
        static var isShowKey = "isShowKey"
    }
    private var isShow: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.isShowKey) as! Bool
        }
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.isShowKey,
                                     newValue,
                                     objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    /// Show universe design style skeleton
    public func showUDSkeleton() {
        self.traitObserver = TraitObserver()
        self.traitObserver?.onTraitChange = { [weak self] _ in
            guard let self = self, self.superview != nil, self.isShow else { return }
            self.hideUDSkeleton()
            self.showUDSkeletonView()
        }
        if #available(iOS 13.0, *) {
            UDThemeManager.refreshCurrentUserInterfaceStyleIfNeeded()
        }
        showUDSkeletonView()
    }

    /// Hide universe design style skeleton
    public func hideUDSkeleton() {
        isShow = false
        stopSkeletonAnimation()
        hideSkeleton()
    }
    /// 函数内部调用展示 UDSkeleton 的方法
    private func showUDSkeletonView() {
        isShow = true
        showAnimatedGradientSkeleton(usingGradient: SkeletonGradient(baseColor: UDLoadingColorTheme.skeletonColor))
    }
}

extension UILabel {
    /// Universe design style skeleton label corner
    public func udSkeletonCorner() {
        linesCornerRadius = 4
    }
}

extension UITextView {
    /// Universe design style skeleton label corner
    public func udSkeletonCorner() {
        linesCornerRadius = 4
    }
}

extension UITableView {
    /// Wait layout before show skeleton, in case skeleton not show when call showSkeleton in viewDidLoad
    public func udPrepareSkeleton(completion: @escaping (Bool) -> Void) {
        performBatchUpdates(nil, completion: completion)
    }
}

extension UICollectionView {
    /// Wait layout before show skeleton, in case skeleton not show when call showSkeleton in viewDidLoad
    public func udPrepareSkeleton(completion: @escaping (Bool) -> Void) {
        if self.dataSource as? SkeletonCollectionViewDataSource != nil {
            // use SkeletonView implement
            self.prepareSkeleton(completion: completion)
        } else {
            // use default implement same with UITableView.udPrepareSkeleton
            performBatchUpdates(nil, completion: completion)
        }
    }
}
