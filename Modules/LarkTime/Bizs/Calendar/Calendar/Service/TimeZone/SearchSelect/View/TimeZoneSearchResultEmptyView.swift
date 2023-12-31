//
//  TimeZoneSearchResultEmptyView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/17.
//

import UIKit
import SnapKit
import UniverseDesignTheme
import UniverseDesignEmpty

/// 搜索结果为空
final class TimeZoneSearchResultEmptyView: UIView {

    private lazy var iconImageView: UIImageView = {
        let theView = UIImageView()
        theView.image = UDEmptyType.searchFailed.defaultImage()
        return theView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.text = BundleI18n.Calendar.Calendar_Common_NoResult
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.Calendar.Calendar_Timezone_TipsNoResults
        return label
    }()

    var title: String? {
        didSet { titleLabel.text = title }
    }

    var subtitle: String? {
        didSet { subtitleLabel.text = subtitle }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)

        iconImageView.snp.makeConstraints {
            $0.size.equalTo(100)
            $0.top.equalToSuperview().offset(50)
            $0.centerX.equalToSuperview()
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(6)
            $0.centerX.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
