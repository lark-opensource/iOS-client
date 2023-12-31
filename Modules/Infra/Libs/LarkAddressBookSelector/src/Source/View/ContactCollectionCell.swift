//
//  ContactSelectedCell.swift
//  LarkAddressBookSelector
//
//  Created by zhenning on 2020/4/26.
//

import Foundation
import UIKit
import SnapKit

public final class ContactCollectionCell: UICollectionViewCell {

    public static let nameFont: UIFont = UIFont.systemFont(ofSize: 12)

    private lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.clipsToBounds = true
        nameLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        nameLabel.font = ContactCollectionCell.nameFont
        nameLabel.textAlignment = .center
        return nameLabel
    }()

    required override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
        self.backgroundColor = UIColor.ud.primaryContentDefault
        self.layer.cornerRadius = 4
    }

    func setupView() {
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(28)
        }
    }

    func setContent(_ name: String) {
        nameLabel.text = name
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
