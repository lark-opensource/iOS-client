//
//  UITableView+Lark.swift
//  Lark
//
//  Created by 李耀忠 on 2016/12/15.
//  Copyright © 2016年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkCompatible
import SnapKit
import UIKit

private var emptyDataViewKey: Void?

public extension LarkUIKitExtension where BaseType: UITableView {
    func register<T: UITableViewCell>(cellSelf: T.Type) {
        self.base.register(T.self, forCellReuseIdentifier: T.lu.reuseIdentifier)
    }

    var indexesOfVisibleSections: [Int] {
        // Note: We can't just use indexPathsForVisibleRows, since it won't return index paths for empty sections.
        var visibleSectionIndexes: [Int] = []

        for index in 0 ..< self.base.numberOfSections {
            var headerRect: CGRect?
            // In plain style, the section headers are floating on the top,
            // so the section header is visible if any part of the section's rect is still visible.
            // In grouped style, the section headers are not floating,
            // so the section header is only visible if it's actualy rect is visible.
            if self.base.style == .plain {
                headerRect = self.base.rect(forSection: index)
            } else {
                headerRect = self.base.rectForHeader(inSection: index)
            }
            if headerRect != nil {
                // The "visible part" of the tableView is based on the content offset and the tableView's size.
                let visiblePartOfTableView = CGRect(
                    x: self.base.contentOffset.x,
                    y: self.base.contentOffset.y,
                    width: self.base.bounds.size.width,
                    height: self.base.bounds.size.height
                )
                if visiblePartOfTableView.intersects(headerRect!) {
                    visibleSectionIndexes.append(index)
                }
            }
        }
        return visibleSectionIndexes
    }

    var visibleSectionHeaders: [UITableViewHeaderFooterView] {
        var visibleSects: [UITableViewHeaderFooterView] = []
        for sectionIndex in indexesOfVisibleSections {
            if let sectionHeader = self.base.headerView(forSection: sectionIndex) {
                visibleSects.append(sectionHeader)
            }
        }

        return visibleSects
    }

    var allItemsCount: Int {
        var items = 0
        for index in 0 ..< self.base.numberOfSections {
            items += self.base.numberOfRows(inSection: index)
        }
        return items
    }

    var emptyDataView: UIView? {
        get {
            return objc_getAssociatedObject(base, &emptyDataViewKey) as? UIView
        }

        set {
            objc_setAssociatedObject(base, &emptyDataViewKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func addEmptyDataViewIfNeeded(_ constraints: ((_ make: ConstraintMaker) -> Void)? = nil) {
        guard let emptyDataView = self.emptyDataView else {
            return
        }

        self.base.isScrollEnabled = true
        emptyDataView.removeFromSuperview()
        if self.allItemsCount <= 0 {
            self.base.isScrollEnabled = false
            self.base.insertSubview(emptyDataView, at: 0)

            if let constraints = constraints {
                emptyDataView.snp.makeConstraints(constraints)
            } else {
                emptyDataView.snp.makeConstraints { make in
                    make.left.width.equalToSuperview()
                    make.top.height.equalToSuperview()
                }
            }
        }
    }

    /// LarkExtensions: IndexPath for last row in section.
    ///
    /// - Parameter section: section to get last row in.
    /// - Returns: optional last indexPath for last row in section (if applicable).
    func indexPathForLastRow(inSection section: Int) -> IndexPath? {
        guard base.numberOfSections > 0, section >= 0 else { return nil }
        guard base.numberOfRows(inSection: section) > 0 else {
            return IndexPath(row: 0, section: section)
        }
        return IndexPath(row: base.numberOfRows(inSection: section) - 1, section: section)
    }

    /// LarkExtensions: Reload data with a completion handler.
    ///
    /// - Parameter completion: completion handler to run after reloadData finishes.
    func reloadData(_ completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0, animations: {
            self.base.reloadData()
        }, completion: { _ in
            completion()
        })
    }

    /// LarkExtensions: Remove TableFooterView.
    func removeTableFooterView() {
        base.tableFooterView = nil
    }

    /// LarkExtensions: Remove TableHeaderView.
    func removeTableHeaderView() {
        base.tableHeaderView = nil
    }

    /// LarkExtensions: Dequeue reusable UITableViewCell using class name.
    ///
    /// - Parameter name: UITableViewCell type.
    /// - Returns: UITableViewCell object with associated class name.
    func dequeueReusableCell<T: UITableViewCell>(withClass name: T.Type) -> T {
        guard let cell = base.dequeueReusableCell(withIdentifier: String(describing: name)) as? T else {
            fatalError(
                "Couldn't find UITableViewCell for \(String(describing: name)), make sure the cell is registered with table view")
        }
        return cell
    }

    /// LarkExtensions: Dequeue reusable UITableViewCell using class name for indexPath.
    ///
    /// - Parameters:
    ///   - name: UITableViewCell type.
    ///   - indexPath: location of cell in tableView.
    /// - Returns: UITableViewCell object with associated class name.
    func dequeueReusableCell<T: UITableViewCell>(withClass name: T.Type, for indexPath: IndexPath) -> T {
        guard let cell = base.dequeueReusableCell(withIdentifier: String(describing: name), for: indexPath) as? T else {
            fatalError(
                "Couldn't find UITableViewCell for \(String(describing: name)), make sure the cell is registered with table view")
        }
        return cell
    }

    /// LarkExtensions: Dequeue reusable UITableViewHeaderFooterView using class name.
    ///
    /// - Parameter name: UITableViewHeaderFooterView type.
    /// - Returns: UITableViewHeaderFooterView object with associated class name.
    func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>(withClass name: T.Type) -> T {
        guard let headerFooterView = base.dequeueReusableHeaderFooterView(withIdentifier: String(describing: name)) as? T else {
            fatalError(
                "Couldn't find UITableViewHeaderFooterView for \(String(describing: name)), make sure the view is registered with table view")
        }
        return headerFooterView
    }

    /// LarkExtensions: Register UITableViewHeaderFooterView using class name.
    ///
    /// - Parameters:
    ///   - nib: Nib file used to create the header or footer view.
    ///   - name: UITableViewHeaderFooterView type.
    func register<T: UITableViewHeaderFooterView>(nib: UINib?, withHeaderFooterViewClass name: T.Type) {
        base.register(nib, forHeaderFooterViewReuseIdentifier: String(describing: name))
    }

    /// LarkExtensions: Register UITableViewHeaderFooterView using class name.
    ///
    /// - Parameter name: UITableViewHeaderFooterView type.
    func register<T: UITableViewHeaderFooterView>(headerFooterViewClassWith name: T.Type) {
        base.register(T.self, forHeaderFooterViewReuseIdentifier: String(describing: name))
    }

    /// LarkExtensions: Register UITableViewCell using class name.
    ///
    /// - Parameter name: UITableViewCell type.
    func register<T: UITableViewCell>(cellWithClass name: T.Type) {
        base.register(T.self, forCellReuseIdentifier: String(describing: name))
    }

    /// LarkExtensions: Register UITableViewCell using class name.
    ///
    /// - Parameters:
    ///   - nib: Nib file used to create the tableView cell.
    ///   - name: UITableViewCell type.
    func register<T: UITableViewCell>(nib: UINib?, withCellClass name: T.Type) {
        base.register(nib, forCellReuseIdentifier: String(describing: name))
    }

    /// LarkExtensions: Register UITableViewCell with .xib file using only its corresponding class.
    ///               Assumes that the .xib filename and cell class has the same name.
    ///
    /// - Parameters:
    ///   - name: UITableViewCell type.
    ///   - bundleClass: Class in which the Bundle instance will be based on.
    func register<T: UITableViewCell>(nibWithCellClass name: T.Type, at bundleClass: AnyClass? = nil) {
        let identifier = String(describing: name)
        var bundle: Bundle?

        if let bundleName = bundleClass {
            bundle = Bundle(for: bundleName)
        }

        base.register(UINib(nibName: identifier, bundle: bundle), forCellReuseIdentifier: identifier)
    }

    /// LarkExtensions: Check whether IndexPath is valid within the tableView.
    ///
    /// - Parameter indexPath: An IndexPath to check.
    /// - Returns: Boolean value for valid or invalid IndexPath.
    func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
        return indexPath.section >= 0 &&
            indexPath.row >= 0 &&
        indexPath.section < base.numberOfSections &&
        indexPath.row < base.numberOfRows(inSection: indexPath.section)
    }

    /// LarkExtensions: Safely scroll to possibly invalid IndexPath.
    ///
    /// - Parameters:
    ///   - indexPath: Target IndexPath to scroll to.
    ///   - scrollPosition: Scroll position.
    ///   - animated: Whether to animate or not.
    func safeScrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition, animated: Bool) {
        guard indexPath.section < base.numberOfSections else { return }
        guard indexPath.row < base.numberOfRows(inSection: indexPath.section) else { return }
        base.scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
    }
}
