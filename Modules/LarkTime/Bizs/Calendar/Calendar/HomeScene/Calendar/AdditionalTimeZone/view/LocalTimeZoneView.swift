//
//  LocalTimeZoneView.swift
//  Calendar
//
//  Created by chaishenghua on 2023/10/24.
//

import Foundation
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon
import LarkTimeFormatUtils

class LocalTimeZoneView: UIView {
    private lazy var localMarkView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKeyNoLimitSize(.localFilled).renderColor(with: .n3)
        return imageView
    }()

    private lazy var titleView = {
        let label = UILabel()
        label.font = UDFont.body0(.fixed)
        label.textColor = UDColor.textTitle
        return label
    }()

    private lazy var subTitleView = {
        let label = UILabel()
        label.font = UDFont.body2(.fixed)
        label.textColor = UDColor.textPlaceholder
        return label
    }()

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.backgroundColor = UDColor.bgBody
        self.addSubview(titleView)
        self.addSubview(subTitleView)
        self.addSubview(localMarkView)

        titleView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(24)
            make.top.equalToSuperview().inset(12)
            make.trailing.equalTo(localMarkView.snp.leading).offset(-8)
        }
        subTitleView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(22)
            make.bottom.equalToSuperview().inset(12)
            make.trailing.equalToSuperview().inset(16)
        }
        localMarkView.snp.makeConstraints {
            $0.size.equalTo(14)
            $0.centerY.equalTo(titleView)
            $0.trailing.lessThanOrEqualToSuperview().inset(16)
        }
    }

    func setViewData(viewData: LocalTimeZoneViewData) {
        titleView.text = viewData.title
        subTitleView.text = viewData.subTitle
    }
}
