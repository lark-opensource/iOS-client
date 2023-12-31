//
//  SettingViewDependency.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/11.
//

import Foundation
import ByteViewNetwork

public protocol SettingViewDependency {
    func push(url: URL, from: UIViewController)

    func createChatterPicker(selectedIds: [String], disabledIds: [String], isMultiple: Bool, includeOuterTenant: Bool,
                             selectHandler: ((String) -> Void)?, deselectHandler: ((String) -> Void)?) -> UIView
}
