//
//  UICollectionView+Cell.swift
//  CTFoundation
//
//  Created by wangwanxin on 2021/7/16.
//

import UIKit
import Foundation

extension CTFoundationExtension where BaseType: UICollectionView {

    // MARK: Reuse Cell

    public func register<T: UICollectionViewCell>(cellType: T.Type) {
        base.register(T.self, forCellWithReuseIdentifier: String(describing: T.self))
    }

    public func dequeueReusableCell<T: UICollectionViewCell>(_ cellType: T.Type, for indexPath: IndexPath) -> T? {
        return base.dequeueReusableCell(withReuseIdentifier: String(describing: T.self), for: indexPath) as? T
    }

    // MARK: Reuse Header View

    public func register<H: UICollectionReusableView>(headerViewType: H.Type) {
        base.register(
            H.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "Header_" + String(describing: H.self)
        )
    }

    public func dequeueReusableHeaderView<H: UICollectionReusableView>(_ headerViewType: H.Type, for indexPath: IndexPath) -> H? {
        return base.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "Header_" + String(describing: H.self),
            for: indexPath
        ) as? H
    }

    // MARK: Reuse Footer View

    public func register<F: UICollectionReusableView>(footerViewType: F.Type) {
        base.register(
            F.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: "Footer_" + String(describing: F.self)
        )
    }

    public func dequeueReusableFooterView<F: UIView>(_ headerViewType: F.Type, for indexPath: IndexPath) -> F? {
        return base.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: "Footer_" + String(describing: F.self),
            for: indexPath
        ) as? F
    }

}

extension UICollectionView: CTFoundationExtensionCompatible {}
