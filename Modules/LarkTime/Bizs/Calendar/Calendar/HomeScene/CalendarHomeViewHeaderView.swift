//
//  CalendarHomeViewHeaderView.swift
//  Calendar
//
//  Created by jiayi zou on 2018/1/12.
//

import UniverseDesignIcon
import UIKit
import SnapKit
import RxSwift
import LarkButton
import LarkUIKit
import LarkTimeFormatUtils

protocol CalendarHomeViewHeaderViewDelegate: AnyObject {
    func calendarHomeViewHeaderView(_ view: CalendarHomeViewHeaderView, didTapFilter: UIButton)
    func calendarHomeViewHeaderView(_ view: CalendarHomeViewHeaderView, didTapSetting: UIButton)
}

final class CalendarHomeViewHeaderView: UIView {

    weak var delegate: CalendarHomeViewHeaderViewDelegate?

    private let filterButton = IconButton()
    private let monthButton = IconButton(type: .custom)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(filterButton)
        filterButton.addTarget(self, action: #selector(filterButtonPressed), for: .touchUpInside)
        filterButton.snp.makeConstraints { (make) -> Void in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(24)
            make.width.equalTo(24)
        }
        filterButton.setImage(UDIcon.getIconByKeyNoLimitSize(.calendarSlideOutlined).scaleNaviSize().renderColor(with: .n2), for: .normal)

        monthButton.addTarget(self, action: #selector(filterButtonPressed), for: .touchUpInside)
        self.addSubview(monthButton)
        monthButton.snp.makeConstraints { (make) -> Void in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
            make.left.equalTo(filterButton.snp.right).offset(8)
            make.height.equalTo(24)
        }
        
        // 低端机延迟
        ViewPageDowngradeTaskManager.addTask(scene: .changeMonthButton,
                                             way: .delay1s) { [weak self] _ in
            self?.changeMonthButton(date: Date())
        }
        // 冷启动1s后初始化首页红点，避免影响冷启动性能
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            LarkBadgeManager.configRedDot(badgeID: .cal_menu, view: self.filterButton, relatedBadges: [.cal_dark_mode], topRightPoint: CGPoint(x: 5, y: -6))
        }
    }

    @objc
    func filterButtonPressed(_ sender: UIButton) {
        self.delegate?.calendarHomeViewHeaderView(self, didTapFilter: sender)
    }

    func changeMonthButton(date: Date?) {
        if let date = date {
            let monthTitle = CalendarHomeViewHeaderView.getMonthTitle(date: date)
            monthButton.setTitle(monthTitle, for: .normal)
            monthButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 24)
            monthButton.setTitleColor(UIColor.black, for: .normal)
        }
    }

    static func getMonthTitle(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: TimeFormatUtils.languageIdentifier)
        formatter.dateFormat = BundleI18n.Calendar.Calendar_StandardTime_YearMonthCombineFormat
        let monthTitle = formatter.string(from: date)
        return monthTitle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return self.frame.size
    }
}
