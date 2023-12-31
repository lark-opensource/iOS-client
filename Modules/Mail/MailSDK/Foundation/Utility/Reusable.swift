//
//  Reusable.swift
//  DocsSDK
//
//  Created by Duan Ao on 2018/12/21.
//

import UIKit

// MARK: - Reusable define
protocol Reusable: AnyObject {
    static var reuseIdentifier: String { get }
}

extension Reusable where Self: UICollectionReusableView {
    static var reuseIdentifier: String { return "\(self)" }
}

extension Reusable where Self: UITableViewHeaderFooterView {
    static var reuseIdentifier: String { return "\(self)" }
}

extension Reusable where Self: UITableViewCell {
    static var reuseIdentifier: String { return "\(self)" }
}

// MARK: - Assign Reusable
extension UITableViewCell: Reusable {}
extension UITableViewHeaderFooterView: Reusable {}
extension UICollectionReusableView: Reusable {}

// MARK: - Register & Dequeue
// MARK: - UICollectionView
extension UICollectionView {
    func registerClass<T: UICollectionViewCell>(_: T.Type) {
        register(T.self, forCellWithReuseIdentifier: T.reuseIdentifier)
    }
}

// MARK: - UITableView
extension UITableView {
    func registerClass<T: UITableViewCell>(_: T.Type) {
        register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
    }

    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            return T()
        }
        return cell
    }
}
