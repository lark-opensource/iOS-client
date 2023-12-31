//
//  ReadRecordHiddenInfoView.swift
//  SKCommon
//
//  Created by CJ on 2021/9/26.
//

import Foundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon
import UIKit

class ReadRecordHiddenInfoView: UIView {

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.groupOutlined.ud.withTintColor(UDColor.iconN1)
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.textColor = UDColor.textTitle
        label.text = BundleI18n.SKResource.CreationMobile_Stats_Visits_title(0, 0)
        label.numberOfLines = 0
        return label
    }()

    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .left
        label.textColor = UDColor.textCaption
        label.numberOfLines = 0
        label.text = BundleI18n.SKResource.CreationMobile_Stats_Visits_desc
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
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(tipLabel)
    }

    private func setupConstraints() {
        iconImageView.snp.makeConstraints { make in
            make.leading.equalTo(safeAreaLayoutGuide.snp.leading).offset(17)
            make.width.height.equalTo(18)
            make.top.equalToSuperview().offset(12)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-17)
            make.top.equalToSuperview().offset(12)
        }

        tipLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-10)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupShadow()
    }

    private func setupShadow() {
        self.ud.setLayerShadowColor(UIColor.ud.shadowDefaultLg)
        self.layer.shadowOpacity = 0.8
        self.layer.shadowRadius = 1
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -1))
        path.addLine(to: CGPoint(x: self.frame.size.width, y: -1))
        path.addLine(to: CGPoint(x: self.frame.size.width, y: 0))
        self.layer.shadowPath = path.cgPath
    }

    public func setReadRecordUserCount(_ totalCount: Int, _ hiddenCount: Int) {
        if totalCount < ReadRecordViewModel.visitsMaxCount {
            titleLabel.text = BundleI18n.SKResource.CreationMobile_Stats_Visits_title(totalCount, hiddenCount)
        } else {
            titleLabel.text = BundleI18n.SKResource.CreationMobile_Stats_Visits_TooMany(totalCount)
        }
    }
}
