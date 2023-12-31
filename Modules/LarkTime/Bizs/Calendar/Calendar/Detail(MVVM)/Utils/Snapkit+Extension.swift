//
//  Snapkit+Extension.swift
//  Calendar
//
//  Created by Rico on 2021/3/19.
//

import Foundation
import SnapKit

extension ConstraintViewDSL {
    func edgesEqualToSuperView() {
        makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
}
