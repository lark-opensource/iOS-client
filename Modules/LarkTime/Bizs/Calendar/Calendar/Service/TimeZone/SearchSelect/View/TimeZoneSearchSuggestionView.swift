//
//  TimeZoneSearchSuggestionView.swift
//  Calendar
//
//  Created by 张威 on 2020/2/17.
//

import UIKit
import SnapKit
import UniverseDesignIcon

final class TimeZoneSearchSuggestionView: UIView {

    var onQueryClick: (() -> Void)?

    var query: String? {
        didSet {
            textLabel.text = query
            clickContainer.isHidden = query?.count ?? 0 == 0
        }
    }

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.primaryContentDefault
        return label
    }()

    private lazy var clickContainer = UIButton()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBody

        clickContainer.isHidden = true
        addSubview(clickContainer)
        clickContainer.snp.makeConstraints {
            $0.left.top.width.equalToSuperview()
            $0.height.equalTo(52.5)
        }

        let iconImageView = UIImageView()
        iconImageView.image = UDIcon.getIconByKeyNoLimitSize(.searchOutlined).ud.withTintColor(UIColor.ud.primaryContentDefault)
        clickContainer.addSubview(iconImageView)
        iconImageView.snp.makeConstraints {
            $0.size.equalTo(16)
            $0.top.equalToSuperview().offset(18)
            $0.left.equalToSuperview().offset(24)
        }

        clickContainer.addSubview(textLabel)
        textLabel.snp.makeConstraints {
            $0.centerY.equalTo(iconImageView)
            $0.left.equalTo(iconImageView.snp.right).offset(6.5)
            $0.right.equalToSuperview().offset(-24)
        }

        let bottomLineView = UIView()
        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault
        clickContainer.addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints {
            $0.height.equalTo(0.5)
            $0.left.right.bottom.equalToSuperview()
                .inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0))
        }

        clickContainer.addTarget(self, action: #selector(buttonClicked), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func buttonClicked() {
        onQueryClick?()
    }
}
