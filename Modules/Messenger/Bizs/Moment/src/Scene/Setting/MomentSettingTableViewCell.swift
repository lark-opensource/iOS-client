//
//  MomentSettingTableViewCell.swift
//  Moment
//
//  Created by zc09v on 2021/6/15.
//

import Foundation
import UIKit

protocol MomentSettingTableViewCell: UITableViewCell {
    var settingItem: MomentSettingItem? { get }
    func setItem(_ item: MomentSettingItem?)
}
