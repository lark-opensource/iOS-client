//
//  Reusable.swift
//  SpaceKit
//
//  Created by Duan Ao on 2018/12/21.
//

import UIKit

// MARK: - Reusable define

public protocol Reusable: AnyObject {
    static var reuseIdentifier: String { get }
}

extension Reusable where Self: UITableViewCell {
    public static var reuseIdentifier: String {
        return "\(self)"
    }
}

extension Reusable where Self: UITableViewHeaderFooterView {
    public static var reuseIdentifier: String {
        return "\(self)"
    }
}

extension Reusable where Self: UICollectionReusableView {
    public static var reuseIdentifier: String {
        return "\(self)"
    }
}

// MARK: - Assign Reusable

extension UITableViewCell: Reusable {}
extension UITableViewHeaderFooterView: Reusable {}
extension UICollectionReusableView: Reusable {}

// MARK: - Register & Dequeue

extension UITableView {

    public func registerClass<T: UITableViewCell>(_: T.Type) {
        register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
    }

    public func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            spaceAssertionFailure("Failed to dequeue Cell, identifier: \(T.reuseIdentifier)")
            return T()
        }
        return cell
    }
}
