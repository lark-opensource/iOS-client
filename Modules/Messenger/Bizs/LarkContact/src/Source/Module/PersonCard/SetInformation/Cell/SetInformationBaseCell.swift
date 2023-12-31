//
//  SetInformationBaseCell.swift
//  LarkContact
//
//  Created by 强淑婷 on 2020/7/15.
//

import Foundation
import LarkUIKit

/// cell点击事件
typealias SetInforamtionTapHandler = () -> Void
/// switch点击事件
typealias SetInforamtionSwitchHandler = (_ status: Bool) -> Void
/// checkBox点击事件
typealias SetInforamtionCheckHandler = (_ isSelected: Bool) -> Void

/// 所有赋值给cell的model必须遵守这个协议
protocol SetInformationItemProtocol {
    /// 重用标识符
    var cellIdentifier: String { get }
}
class SetInformationBaseCell: BaseSettingCell {

    var item: SetInformationItemProtocol? {
        didSet {
            setCellInfo()
        }
    }

    func setCellInfo() {
        assert(false, "没有实现对应的填充方法")
    }

}
