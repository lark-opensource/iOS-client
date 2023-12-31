//
//  MinutesSearchBar.swift
//  Minutes
//
//  Created by ByteDance on 2023/9/14.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignColor

class MinutesSearchBar: UIView {
    lazy var searchBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UDIcon.getIconByKey(.searchOutlined, iconColor: UIColor.ud.iconN2), for: .normal)
        return btn
    }()

    lazy var searchTitle: UILabel = {
        let lbl = UILabel()
        lbl.text = BundleI18n.Minutes.MMWeb_G_Search
        lbl.textColor = UIColor.ud.textPlaceholder
        lbl.font = .systemFont(ofSize: 16)
        return lbl
    }()

    var searchHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        let bg = UIButton()
        bg.backgroundColor = UIColor.ud.bgBodyOverlay
        bg.layer.cornerRadius = 6
        bg.addTarget(self, action: #selector(tapToSearch), for: .touchUpInside)
        addSubview(bg)

        bg.addSubview(searchBtn)
        bg.addSubview(searchTitle)

        bg.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-12)
        }

        searchBtn.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 18, height: 18))
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        searchTitle.snp.makeConstraints { make in
            make.left.equalTo(searchBtn.snp.right).offset(8)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func tapToSearch() {
        searchHandler?()
    }

}
