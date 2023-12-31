//
//  ReusableCell.swift
//  ReusableCell
//
//  Created by 陈乐辉 on 2019/4/9.
//  Copyright © 2019年 CLH. All rights reserved.
//

import Foundation
import UIKit

public protocol MinutesReusableCell {
    static var minsIdentifier: String { get }
}

extension MinutesReusableCell {
    public static var minsIdentifier: String {
        return "\(self)"
    }
}

extension UITableViewCell: MinutesReusableCell {}
extension UITableViewHeaderFooterView: MinutesReusableCell {}
extension UICollectionReusableView: MinutesReusableCell {}

private var tableViewIdentifierKey: Void?

extension UITableView {
    fileprivate var minsIdedtifiers: Set<String> {
        get {
            if let ids = objc_getAssociatedObject(self, &tableViewIdentifierKey) as? Set<String> {
                return ids
            } else {
                let ids = Set<String>()
                objc_setAssociatedObject(self, &tableViewIdentifierKey, ids, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return ids
            }
        }
        set {
            objc_setAssociatedObject(self, &tableViewIdentifierKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension MinsWrapper where Base: UITableView {

    public func dequeueReusableCell<T: UITableViewCell>(with type: T.Type, configure: (T) -> Void) -> UITableViewCell {
        if !base.minsIdedtifiers.contains(T.minsIdentifier) {
            base.register(type, forCellReuseIdentifier: T.minsIdentifier)
            base.minsIdedtifiers.insert(T.minsIdentifier)
        }
        if let cell = base.dequeueReusableCell(withIdentifier: T.minsIdentifier) as? T {
            configure(cell)
            return cell
        }
        return UITableViewCell()
    }

    public func dequeueReusableCell<T: UITableViewCell>(with type: T.Type, for indexPath: IndexPath, configure: (T) -> Void) -> UITableViewCell {
        if !base.minsIdedtifiers.contains(T.minsIdentifier) {
            base.register(type, forCellReuseIdentifier: T.minsIdentifier)
            base.minsIdedtifiers.insert(T.minsIdentifier)
        }
        let reusableCell = base.dequeueReusableCell(withIdentifier: T.minsIdentifier, for: indexPath)
        guard let cell = reusableCell as? T else { return reusableCell }
        configure(cell)
        return cell
    }

    public func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>(with type: T.Type, configure: (T) -> Void) -> UITableViewHeaderFooterView {
        if !base.minsIdedtifiers.contains(T.minsIdentifier) {
            base.register(type, forHeaderFooterViewReuseIdentifier: T.minsIdentifier)
            base.minsIdedtifiers.insert(T.minsIdentifier)
        }
        if let rv = base.dequeueReusableHeaderFooterView(withIdentifier: T.minsIdentifier) as? T {
            configure(rv)
            return rv
        }
        return UITableViewHeaderFooterView()
    }
}

private var collectionViewIdentifierKey: Void?

extension UICollectionView {
    fileprivate var minsIdedtifiers: Set<String> {
        get {
            if let ids = objc_getAssociatedObject(self, &collectionViewIdentifierKey) as? Set<String> {
                return ids
            } else {
                let ids = Set<String>()
                objc_setAssociatedObject(self, &collectionViewIdentifierKey, ids, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return ids
            }
        }
        set {
            objc_setAssociatedObject(self, &collectionViewIdentifierKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension MinsWrapper where Base: UICollectionView {

    public enum ElementKind {
        case header
        case footer

        public var value: String {
            switch self {
            case .header:
                return UICollectionView.elementKindSectionHeader
            case .footer:
                return UICollectionView.elementKindSectionFooter
            }
        }
    }

    public func dequeueReusableCell<T: UICollectionViewCell>(with type: T.Type, for indexPath: IndexPath, configure: (T) -> Void) -> UICollectionViewCell {
        if !base.minsIdedtifiers.contains(T.minsIdentifier) {
            base.register(type, forCellWithReuseIdentifier: T.minsIdentifier)
            base.minsIdedtifiers.insert(T.minsIdentifier)
        }
        let cell = base.dequeueReusableCell(withReuseIdentifier: T.minsIdentifier, for: indexPath)
        if let cell = cell as? T {
            configure(cell)
        }
        return cell
    }

    public func dequeueReusableSupplementaryView<T: UICollectionReusableView>(of elementKind: ElementKind, with type: T.Type, for indexPath: IndexPath, configure: (T) -> Void) -> UICollectionReusableView {
        if !base.minsIdedtifiers.contains(T.minsIdentifier) {
            base.register(type, forSupplementaryViewOfKind: elementKind.value, withReuseIdentifier: T.minsIdentifier)
            base.minsIdedtifiers.insert(T.minsIdentifier)
        }
        let view = base.dequeueReusableSupplementaryView(ofKind: elementKind.value, withReuseIdentifier: T.minsIdentifier, for: indexPath)
        if let view = view as? T {
            configure(view)
        }
        return view
    }
}
