//
//  FocusTitleCell.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/9.
//

import UIKit

protocol FocusTitleCell: UITableViewCell {

    var iconKey: String? { get set }
    var focusName: String? { get set }
}
