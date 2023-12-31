//
//  ReadRecordListTitleHeaderView.swift
//  SKCommon
//
//  Created by CJ on 2021/9/26.
//

import Foundation
import SKResource
import UniverseDesignColor

class ReadRecordListTitleHeaderView: UIView {
    private lazy var nameTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.textColor = UDColor.textCaption
        label.text = BundleI18n.SKResource.CreationMobile_Stats_Visits_PeopleNum
        return label
    }()

    private lazy var lastViewTimestampTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .right
        label.textColor = UDColor.textCaption
        label.text = BundleI18n.SKResource.CreationMobile_Stats_Visits_VisitedTime
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(nameTitleLabel)
        addSubview(lastViewTimestampTitleLabel)
    }

    private func setupConstraints() {
        nameTitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(safeAreaLayoutGuide.snp.leading).offset(18)
            make.centerY.equalToSuperview()
        }

        lastViewTimestampTitleLabel.snp.makeConstraints { make in
            make.trailing.equalTo(safeAreaLayoutGuide.snp.trailing).offset(-23)
            make.centerY.equalToSuperview()
        }
    }
}
