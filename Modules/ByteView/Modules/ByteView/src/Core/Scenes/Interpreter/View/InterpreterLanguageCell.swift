//
//  InterpreterLanguageCell.swift
//  ByteView
//
//  Created by fakegourmet on 2020/10/22.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

class InterpreterLanguageCell: UITableViewCell {

    lazy var langIconView: UIImageView = UIImageView()
    lazy var langLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()
    lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.ud.fillHover
        self.selectedBackgroundView = selectedBackgroundView
        setupLayouts()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayouts() {
        contentView.addSubview(langIconView)
        contentView.addSubview(langLabel)
        addSubview(separatorView)

        langIconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        langLabel.snp.makeConstraints { (make) in
            make.left.equalTo(langIconView.snp.right).offset(16)
            make.centerY.equalToSuperview()
        }
        separatorView.snp.makeConstraints { (make) in
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
            make.left.equalTo(langIconView.snp.left)
        }
    }

    func config(with model: InterpreterLanguageInfo) {
        isUserInteractionEnabled = !model.isSelected

        langLabel.text = model.i18nText
        langLabel.textColor = model.isSelected ? UIColor.ud.textDisabled : UIColor.ud.textTitle

        let selectedIcon = LanguageIconManager.get(by: model.languageType,
                                                   foregroundColor: UIColor.ud.udtokenBtnPriTextDisabled,
                                                   backgroundColor: UIColor.ud.N400)
        let icon = LanguageIconManager.get(by: model.languageType)
        langIconView.image = model.isSelected ? selectedIcon : icon
    }
}
