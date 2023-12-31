//
//  CalendarAccessView.swift
//  Calendar
//
//  Created by heng zhu on 2019/3/25.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import SnapKit

protocol CalendarAccessViewProtocol {
    var title: String { get }
    var subTitle: String { get }
}

struct CalendarAccessData: CalendarAccessViewProtocol {
    let title: String
    let subTitle: String
    let accessRole: CalendarAccess
}

struct CalendarMemberAccessData: CalendarAccessViewProtocol {
    let title: String
    let subTitle: String
    let accessRole: AccessRole
}

protocol CalendarAccessViewDelegate: AnyObject {
    func didSelect(index: Int)
}

final class CalendarAccessView: UIView {
    weak var delegate: CalendarAccessViewDelegate?
    var cells: [CalendarAccessRoleCell] = [CalendarAccessRoleCell]()

    init(dataSource: [CalendarAccessViewProtocol], selectIndex: Int, withBottomBorder: Bool) {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        var upItem: ConstraintItem = self.snp.top
        for i in 0..<dataSource.count {
            let data = dataSource[i]
            var bottomBorder = true
            if i == dataSource.count - 1, withBottomBorder == false {
                bottomBorder = false
            }
            let cell = CalendarAccessRoleCell(title: data.title, subTitle: data.subTitle, withBottomBorder: bottomBorder)
            cell.tag = i
            cell.addTarget(self, action: #selector(cellTaped(sender:)), for: .touchUpInside)
            cell.update(isSelected: selectIndex == i)
            cells.append(cell)
            layout(cell: cell, upItem: upItem, isBottom: i == dataSource.count - 1)
            upItem = cell.snp.bottom
        }
    }

    @objc
    private func cellTaped(sender: CalendarAccessRoleCell) {
        self.delegate?.didSelect(index: sender.tag)
    }

    func select(atIndex index: Int) {
        cells.forEach { (cell) in
            cell.update(isSelected: cell.tag == index)
        }
    }

    private func layout(cell: UIView, upItem: ConstraintItem, isBottom: Bool) {
        addSubview(cell)
        cell.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(upItem)
            if isBottom {
                make.bottom.equalToSuperview()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
