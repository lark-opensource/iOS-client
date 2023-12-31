//
//  UITableView+Identifier.swift
//  ByteView
//
//  Created by wulv on 2022/2/15.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import ByteViewNetwork

extension UITableView {

    func register<T: UITableViewCell>(cellType: T.Type) {
        register(cellType, forCellReuseIdentifier: String(describing: cellType))
    }

    // swiftlint:disable force_cast
    func dequeueReusableCell<T: UITableViewCell>(withType cellType: T.Type, for indexPath: IndexPath) -> T {
        dequeueReusableCell(withIdentifier: String(describing: cellType), for: indexPath) as! T
    }
    // swiftlint:enable force_cast

    func register<T: UITableViewHeaderFooterView>(viewType: T.Type) {
        register(viewType, forHeaderFooterViewReuseIdentifier: String(describing: viewType))
    }

    func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>(withType viewType: T.Type) -> T? {
        dequeueReusableHeaderFooterView(withIdentifier: String(describing: viewType)) as? T
    }
}
