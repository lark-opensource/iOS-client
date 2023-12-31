//
//  SelectCountryNumberCell.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/9/12.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit

final class SelectCountryNumberCell: UITableViewCell {
    lazy var countryLabel: UILabel = {
        let countryLabel = UILabel()
        countryLabel.textAlignment = .left
        countryLabel.font = UIFont.systemFont(ofSize: 14)
        countryLabel.textColor = UIColor.ud.N900
        return countryLabel
    }()

    lazy var numberLabel: UILabel = {
        let numberLabel = UILabel()
        numberLabel.textAlignment = .right
        numberLabel.font = UIFont.systemFont(ofSize: 14)
        numberLabel.textColor = UIColor.ud.N900
        return numberLabel
    }()

    lazy var bottomSeperator: UIView = {
        let bottomSeperator = UIView()
        bottomSeperator.backgroundColor = UIColor.ud.commonTableSeparatorColor
        return bottomSeperator
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.addSubview(countryLabel)
        self.addSubview(numberLabel)
        self.addSubview(bottomSeperator)

        countryLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(18)
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-16)
        }

        numberLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-19)
            make.left.greaterThanOrEqualTo(countryLabel.snp.right).offset(15)
            make.top.equalTo(countryLabel.snp.top)
            make.bottom.equalTo(countryLabel.snp.bottom)
        }

        bottomSeperator.snp.makeConstraints { (make) in
            make.left.equalTo(countryLabel.snp.left)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    func set(country: String, number: String) {
        countryLabel.text = country
        numberLabel.text = number
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
