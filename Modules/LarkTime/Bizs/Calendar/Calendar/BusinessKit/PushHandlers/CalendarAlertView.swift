//
//  CalendarAlertView.swift
//  Alamofire
//
//  Created by zhuchao on 2018/2/26.
//

import UIKit
import SnapKit
import Foundation
import CalendarFoundation
import LarkTimeFormatUtils
import FigmaKit
import LarkPushCard

final class CalendarAlertView: UIView {
    init(title: String, time: Date, meetingRooms: [String], location: String, isAllday: Bool, is12HourStyle: Bool) {
        super.init(frame: .zero)
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.distribution = .fillEqually
        stackView.addArrangedSubview(self.label(withTitle: BundleI18n.Calendar.Calendar_Alert_Title, content: title.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : title))

        let timeString: String
        // 使用设备时区
        let isInSameYear = Calendar(identifier: .gregorian).isDate(time, equalTo: Date(), toGranularity: .year)
        var customOptions = Options(
            shouldShowGMT: !isAllday,
            timeFormatType: isInSameYear ? .short : .long,
            datePrecisionType: .day,
            dateStatusType: .absolute
        )
        if isAllday {
            timeString = CalendarTimeFormatter.formatRelativeFullDate(from: time, with: customOptions)
        } else {
            customOptions.is12HourStyle = is12HourStyle
            customOptions.timePrecisionType = .minute
            timeString = CalendarTimeFormatter.formatRelativeFullDateTime(from: time, with: customOptions)
        }

        stackView.addArrangedSubview(self.label(withTitle: BundleI18n.Calendar.Calendar_Alert_Time, content: timeString))

        if !meetingRooms.isEmpty {
            stackView.addArrangedSubview(self.label(withTitle: BundleI18n.Calendar.Calendar_Alert_Room, content: meetingRooms.joined(separator: ",")))
        }

        if !location.isEmpty {
            stackView.addArrangedSubview(self.label(withTitle: BundleI18n.Calendar.Calendar_Alert_Location, content: location))
        }
        self.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    func disPlayHeight() -> CGFloat {
        return self.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    }

    private func label(withTitle title: String, content: String) -> UILabel {
        let label = UILabel.cd.textLabel(fontSize: 16)
        label.text = title + "    " + content
        label.numberOfLines = 1
        label.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
        label.snp.makeConstraints { make in
            make.height.equalTo(label.font.figmaHeight)
        }
        return label
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct CalendarPushCard: Cardable {
    var id: String

    var priority: LarkPushCard.CardPriority = .normal

    var title: String?

    var buttonConfigs: [LarkPushCard.CardButtonConfig]?

    var icon: UIImage?

    var customView: UIView?

    var duration: TimeInterval?

    var bodyTapHandler: ((LarkPushCard.Cardable) -> Void)?

    var timedDisappearHandler: ((LarkPushCard.Cardable) -> Void)?

    var removeHandler: ((LarkPushCard.Cardable) -> Void)?

    var extraParams: Any?
}
