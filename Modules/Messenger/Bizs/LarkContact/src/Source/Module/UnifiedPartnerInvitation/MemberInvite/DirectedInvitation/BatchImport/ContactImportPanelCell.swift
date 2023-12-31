//
//  ContactImportPanelCell.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/4/30.
//

import Foundation
import UIKit
import SnapKit

final class ContactImportPanelCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(_ content: String) {
        contentLabel.setText(text: content, lineSpacing: 6.0)
    }

    private lazy var circleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.colorfulBlue
        view.layer.cornerRadius = 3.0
        view.layer.masksToBounds = true
        return view
    }()

    private lazy var contentLabel: InsetsLabel = {
        let label = InsetsLabel(frame: .zero, insets: UIEdgeInsets(top: 9, left: 22, bottom: 9, right: 10))
        label.backgroundColor = UIColor.ud.N100
        label.textColor = UIColor.ud.N600
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.layer.cornerRadius = 4.0
        label.layer.masksToBounds = true
        return label
    }()
}

private extension ContactImportPanelCell {
    func layoutPageSubviews() {
        contentView.addSubview(contentLabel)
        contentLabel.addSubview(circleView)
        circleView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(17)
            make.left.equalToSuperview().offset(10)
            make.width.height.equalTo(6.0)
        }
        contentLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(2)
        }
    }
}
