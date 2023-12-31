//
//  TodayPlanCell.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/2.
//

import Foundation
import SnapKit
import UniverseDesignFont
import UniverseDesignColor

class TodayPlanTableCell: UITableViewCell {
    private lazy var startTimeView: UILabel = {
        let label = UILabel()
        label.font = UDFont.caption1
        label.textColor = UDColor.textTitle
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 2
        return label
    }()
    private lazy var todayItemView = TodayPlanItemView()

    static let identifier = String(describing: TodayPlanTableCell.self)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.contentView.backgroundColor = UDColor.bgBody
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.addSubview(startTimeView)
        contentView.addSubview(todayItemView)
        startTimeView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.width.equalTo(41)
            make.top.equalToSuperview().inset(8)
        }
        todayItemView.snp.makeConstraints { make in
            make.leading.equalTo(startTimeView.snp.trailing).offset(4)
            make.top.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(16)
        }
    }

    func setModel(model: TodayPlanModel) {
        if model.baseModel.rangeTime.isEmpty {
            startTimeView.snp.remakeConstraints { make in
                make.leading.equalToSuperview()
                make.width.equalTo(41)
                make.centerY.equalTo(todayItemView)
            }
        } else {
            startTimeView.snp.remakeConstraints { make in
                make.leading.equalToSuperview()
                make.width.equalTo(41)
                make.top.equalToSuperview().inset(8)
            }
        }
        if model.needShowTime {
            self.startTimeView.isHidden = false
            self.startTimeView.attributedText = model.startTime
        } else {
            self.startTimeView.isHidden = true
        }
        self.todayItemView.setModel(model: model)
    }
}
