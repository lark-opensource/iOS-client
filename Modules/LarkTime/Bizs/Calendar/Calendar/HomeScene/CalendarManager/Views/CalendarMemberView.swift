//
//  CalendarMemberView.swift
//  Calendar
//
//  Created by harry zou on 2019/3/26.
//

import UIKit
import SnapKit
import CalendarFoundation
final class CalendarMemberView: UIView {
    var didSelect: ((_ index: Int) -> Void)?

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        self.isUserInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with models: [CalendarMemberCellModel]) {
        var topItem: ConstraintItem = self.snp.top
        for subview in subviews {
            subview.removeFromSuperview()
        }
        for i in 0..<models.count {
            guard let model = models[safeIndex: i] else {
                assertionFailureLog()
                continue
            }
            let isBottom = i == models.count - 1
            if model.shouldHidden {
                if isBottom {
                    self.snp.makeConstraints { (make) in
                        make.bottom.equalTo(topItem)
                    }
                }
                continue
            }
            let cell = CalendarMemberCell(frame: CGRect.zero)
            cell.tag = i
            cell.addTarget(self, action: #selector(cellTaped(sender:)), for: .touchUpInside)
            layout(cell: cell, upItem: topItem, isBottom: isBottom)
            topItem = cell.snp.bottom
            if !isBottom {
                cell.addBottomLine(76)
            }
            cell.updateUI(with: model)
        }
    }

    @objc
    private func cellTaped(sender: CalendarMemberCell) {
        didSelect?(sender.tag)
    }

    private func layout(cell: UIView, upItem: ConstraintItem, isBottom: Bool) {
        addSubview(cell)
        cell.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(upItem)
            if isBottom {
                make.bottom.equalToSuperview()
                cell.addBottomBorder()
            }
        }
    }
}
