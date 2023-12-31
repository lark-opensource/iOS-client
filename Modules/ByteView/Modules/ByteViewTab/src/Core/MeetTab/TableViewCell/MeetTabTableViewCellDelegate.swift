//
//  MeetTabTableViewCellDelegate.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//

import UIKit

protocol MeetTabCellConfigurable: UITableViewCell {
    func bindTo(viewModel: MeetTabCellViewModel)
}

protocol MeetTabSectionConfigurable: UITableViewHeaderFooterView {
    func bindTo(viewModel: MeetTabSectionViewModel)
}
