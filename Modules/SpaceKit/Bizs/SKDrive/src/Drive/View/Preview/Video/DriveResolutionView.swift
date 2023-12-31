//
//  DriveResolutionView.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/8/9.
//

import UIKit
import SKCommon
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

class DriveResolutionView: UIView {
    private let selectedIcon = UIImageView()
    private let title = UILabel()
    var resolutionName: String = "" {
        didSet {
            title.text = resolutionName
        }
    }

    var isSelected: Bool = false {
        didSet {
            selectedIcon.isHidden = !isSelected
            if isSelected {
                title.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
                title.textColor = UDColor.primaryContentDefault
            } else {
                title.font = UIFont.systemFont(ofSize: 16.0)
                title.textColor = UDColor.textTitle
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupLayout()
    }

    func setupUI() {
        title.textAlignment = .center
        addSubview(title)

        selectedIcon.image = UDIcon.listCheckOutlined.ud.withTintColor(UDColor.primaryContentDefault)
        addSubview(selectedIcon)
    }

    func setupLayout() {
        title.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.center.equalToSuperview()
        }

        selectedIcon.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.right.equalTo(title.snp.left).offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
