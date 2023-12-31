//
//  HashTagCell.swift
//  Moment
//
//  Created by liluobin on 2021/7/19.
//

import Foundation
import UIKit

final class HashTagCell: UITableViewCell {
    static let cellId: String = "HashTagCell"
    let titleLabel = UILabel()
    let desLabel = UILabel()
    var item: HashTagItem? {
        didSet {
            updateUI()
        }
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = UIColor.ud.bgBody
        titleLabel.numberOfLines = 1
        titleLabel.font = UIFont.systemFont(ofSize: 17)
        titleLabel.textColor = UIColor.ud.textLinkNormal
        titleLabel.text = ""
        titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }

        desLabel.font = UIFont.systemFont(ofSize: 12)
        desLabel.textColor = UIColor.ud.textCaption
        desLabel.numberOfLines = 1
        desLabel.text = ""
        desLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(desLabel)
        desLabel.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.right).offset(8)
            make.centerY.equalTo(titleLabel)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
        let lineView = UIView()
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        contentView.addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.right.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
    }

    func updateUI() {
        guard let item = self.item else {
            return
        }
        self.titleLabel.text = item.content
        self.desLabel.text = item.desText
    }
}
