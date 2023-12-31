//
//  UserNickNameCell.swift
//  Moment
//
//  Created by liluobin on 2021/5/23.
//

import Foundation
import UIKit
import LarkInteraction

final class UserNickNameCell: UICollectionViewCell {
    static let reuseId: String = "UserNickNameCell"
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    var item: UserNickNameItem? {
        didSet {
            updateUI()
        }
    }
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textDisable
        label.font = UIFont.systemFont(ofSize: 14)
        label.backgroundColor = .clear
        return label
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupView() {
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        contentView.backgroundColor = UIColor.ud.bgFiller
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        self.addPointer(.lift.targetView { $0.superview?.superview })
    }

    private func updateUI() {
        guard let item = item else {
            return
        }
        titleLabel.text = item.data.nickname
        if item.selected {
            titleLabel.textColor = UIColor.ud.primaryContentPressed
            contentView.backgroundColor = UIColor.ud.functionInfoFillSolid02
        } else {
            titleLabel.textColor = UIColor.ud.textTitle
            contentView.backgroundColor = UIColor.ud.bgFiller
        }
    }
}
