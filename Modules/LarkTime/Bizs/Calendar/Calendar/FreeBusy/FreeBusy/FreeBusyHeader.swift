//
//  FreeBusyHeader.swift
//  Calendar
//
//  Created by zhouyuan on 2019/4/8.
//

import UIKit
import Foundation
import CalendarFoundation

protocol Shadowable {
}

extension Shadowable where Self: UIView {
    func setupBottomShadows() {
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.ud.setShadowColor(UIColor.black)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 5
        let rect = CGRect(x: 0, y: bounds.height - 2, width: bounds.width, height: 2)
        layer.shadowPath = UIBezierPath(rect: rect).cgPath
    }

    func setupTopShadows() {
        layer.masksToBounds = false
        layer.shadowRadius = 3
        layer.ud.setShadowColor(UIColor.black)
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: -3)
        let rect = CGRect(x: 0, y: 0, width: bounds.width, height: 3)
        layer.shadowPath = UIBezierPath(rect: rect).cgPath
    }
}

final class FreeBusyHeader: UIView, Shadowable {
    static let height: CGFloat = PersonalCardHeaderviewCell.height
    private let headerView: ArrangementHeaderView
    init(leftMargin: CGFloat) {
        self.headerView = ArrangementHeaderView(leftMargin: leftMargin, mode: .personalCard)
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody
        addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.right.left.top.bottom.equalToSuperview()
        }
    }

    func relayoutForiPad(newWidth: CGFloat) {
        headerView.relayoutForiPad(newWidth: newWidth)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupBottomShadows()
    }

    func updateModel(model: ArrangementHeaderViewModel) {
         headerView.updateModel(model: model)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
