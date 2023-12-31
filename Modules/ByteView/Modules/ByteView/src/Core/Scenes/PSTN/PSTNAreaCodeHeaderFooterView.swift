//
//  PSTNAreaCodeHeaderFooterView.swift
//  ByteView
//
//  Created by yangyao on 2020/4/14.
//

import UIKit

class PSTNAreaCodeHeaderFooterView: UITableViewHeaderFooterView {
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubview(titleLabel)

        let view = UIView()
        view.backgroundColor = UIColor.ud.N100
        backgroundView = view

        titleLabel.snp.makeConstraints { (maker) in
            maker.height.equalTo(20)
            maker.centerY.equalToSuperview()
            maker.left.equalTo(safeAreaLayoutGuide).offset(16)
            maker.right.lessThanOrEqualToSuperview().inset(16).priority(.low)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
