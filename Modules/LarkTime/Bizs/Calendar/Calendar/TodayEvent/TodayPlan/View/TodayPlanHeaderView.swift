//
//  TodayPlanHeaderView.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/10.
//

import UniverseDesignColor
import UniverseDesignFont

class TodayPlanHeaderView: UITableViewHeaderFooterView {
    static let identifier = "TodayPlanHeaderView"

    private lazy var label: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Calendar.Lark_Event_ScheduledToday_Title
        label.textColor = UDColor.textTitle
        label.font = UDFont.headline
        return label
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    private func setupView() {
        self.contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.trailing.leading.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
