//
//  FieldCellAbstractable.swift
//  LarkContact
//
//  Created by SlientCat on 2019/6/9.
//

import Foundation
import UIKit

protocol FieldCellAbstractable: UITableViewCell {
    func bindWithViewModel(viewModel: FieldViewModelAbstractable)
    func beActive()
}
