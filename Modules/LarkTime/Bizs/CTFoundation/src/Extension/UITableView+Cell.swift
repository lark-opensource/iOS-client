//
//  UITableView+Cell.swift
//  CTFoundation
//
//  Created by 张威 on 2020/11/19.
//

import UIKit
import Foundation

extension CTFoundationExtension where BaseType: UITableView {

    // MARK: Reuse Cell

    public func register<T: UITableViewCell>(cellType: T.Type) {
        base.register(T.self, forCellReuseIdentifier: String(describing: T.self))
    }

    public func dequeueReusableCell<T: UITableViewCell>(_ cellType: T.Type, for indexPath: IndexPath) -> T? {
        return base.dequeueReusableCell(withIdentifier: String(describing: T.self), for: indexPath) as? T
    }

    // MARK: Reuse Header View

    public func register<H: UITableViewHeaderFooterView>(headerViewType: H.Type) {
        base.register(H.self, forHeaderFooterViewReuseIdentifier: "Header_" + String(describing: H.self))
    }

    public func dequeueReusableHeaderView<H: UIView>(_ headerViewType: H.Type) -> H? {
        return base.dequeueReusableHeaderFooterView(withIdentifier: "Header_" + String(describing: H.self)) as? H
    }

    // MARK: Reuse Footer View

    public func register<F: UITableViewHeaderFooterView>(footerViewType: F.Type) {
        base.register(F.self, forHeaderFooterViewReuseIdentifier: "Footer_" + String(describing: F.self))
    }

    public func dequeueReusableFooterView<F: UIView>(_ headerViewType: F.Type) -> F? {
        return base.dequeueReusableHeaderFooterView(withIdentifier: "Footer_" + String(describing: F.self)) as? F
    }

}

extension UITableView: CTFoundationExtensionCompatible {}
