//
//  CaledarFilterCells.swift
//  AsyncComponent
//
//  Created by sunxiaolei on 2019/8/15.
//

import UIKit
import Foundation
import CalendarFoundation
import SnapKit

final class CalendarFilterHeaderCell: UIView {
    let label = UILabel.cd.titleLabel(fontSize: 14)

    override init(frame: CGRect) {
        super.init(frame: frame)

        label.textColor = UIColor.ud.textTitle
        self.backgroundColor = UIColor.ud.bgBody
        layoutLabel(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutLabel(_ label: UILabel) {
        addSubview(label)
        label.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-12)
            make.left.right.equalToSuperview().offset(16)
        }
    }
}

final class CalendarFilterFooterCell: UIView {
    let bgView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        bgView.backgroundColor = UIColor.ud.bgBase
        self.backgroundColor = UIColor.ud.bgBody
        layoutLabel(bgView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutLabel(_ bgView: UIView) {
        addSubview(bgView)
        bgView.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-8)
            make.left.right.equalToSuperview()
            make.height.equalTo(8)
        }
    }
}
