//
//  MemberInviteViewModel+UIDelegate.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/11.
//

import Foundation
import UIKit

// swiftlint:disable force_cast
// MARK: - UITableViewDataSource & Delegate
extension MemberInviteViewModel {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = (tableView as! FieldListTypeable).fieldListType
        let viewModel: FieldViewModelAbstractable!
        if type == .email && indexPath.row == 0 {
            viewModel = emailFieldViewModel
        } else if type == .phone && indexPath.row == 0 {
            viewModel = phoneFieldViewModel
        } else if type == .email && indexPath.row == 1 {
            viewModel = nameFieldViewModelForEmail
        } else {
            viewModel = nameFieldViewModelForPhone
        }
        let cellClass: FieldCellAbstractable.Type = NSClassFromString(viewModel.cellMapping) as! FieldCellAbstractable.Type
        let cell: FieldCellAbstractable? = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(cellClass.self)) as? FieldCellAbstractable
        if let dCell = cell {
            dCell.bindWithViewModel(viewModel: viewModel)
            return dCell
        } else {
            let newCell: FieldCellAbstractable = cellClass.init(style: .default, reuseIdentifier: NSStringFromClass(cellClass.self))
            newCell.bindWithViewModel(viewModel: viewModel)
            return newCell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let type = (tableView as! FieldListTypeable).fieldListType
        let viewModel: FieldViewModelAbstractable!
        if type == .email && indexPath.row == 0 {
            viewModel = emailFieldViewModel
        } else if type == .phone && indexPath.row == 0 {
            viewModel = phoneFieldViewModel
        } else if type == .email && indexPath.row == 1 {
            viewModel = nameFieldViewModelForEmail
        } else {
            viewModel = nameFieldViewModelForPhone
        }
        return viewModel.FieldCellHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}
// swiftlint:enable force_cast
