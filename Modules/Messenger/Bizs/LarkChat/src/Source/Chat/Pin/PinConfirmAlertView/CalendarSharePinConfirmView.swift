//
//  CalendarSharePinConfirmView.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/29.
//

import Foundation
import UIKit
import LarkModel

// MARK: - CalendarSharePinConfirmView
final class CalendarSharePinConfirmView: PinConfirmContainerView {
    var icon: UIImageView
    var title: UILabel
    var eventTimeDescription: UILabel

    override init(frame: CGRect) {
        self.icon = UIImageView(image: Resources.pinCalenderConfirmTip)
        self.title = UILabel(frame: .zero)
        title.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        title.textColor = UIColor.ud.N900
        title.numberOfLines = 1
        self.eventTimeDescription = UILabel(frame: .zero)
        eventTimeDescription.font = UIFont.systemFont(ofSize: 12)
        eventTimeDescription.textColor = UIColor.ud.N500
        eventTimeDescription.numberOfLines = 1
        super.init(frame: frame)
        self.addSubview(icon)
        self.addSubview(title)
        self.addSubview(eventTimeDescription)
        icon.snp.makeConstraints { (make) in
            make.left.top.equalTo(BubbleLayout.commonInset.left)
            make.width.height.equalTo(48)
            make.bottom.equalTo(self.nameLabel.snp.top).offset(-BubbleLayout.commonInset.bottom)
        }

        title.snp.makeConstraints { (make) in
            make.top.equalTo(icon)
            make.left.equalTo(icon.snp.right).offset(8)
            make.right.lessThanOrEqualToSuperview().offset(-BubbleLayout.commonInset.right)
        }

        eventTimeDescription.snp.makeConstraints { (make) in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.left.equalTo(title)
            make.right.lessThanOrEqualToSuperview().offset(-BubbleLayout.commonInset.right)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setPinConfirmContentView(_ contentVM: PinAlertViewModel) {
        super.setPinConfirmContentView(contentVM)

        guard let calendarShareVM = contentVM as? CalendarSharePinConfirmViewModel else {
            return
        }
        title.text = calendarShareVM.title
        eventTimeDescription.text = calendarShareVM.eventTimeDescription?() ?? ""
    }
}

// MARK: - CalendarSharePinConfirmViewModel
final class CalendarSharePinConfirmViewModel: PinAlertViewModel {
    var title: String = ""
    var eventTimeDescription: (() -> String)?
    init?(shareEventMessage: Message,
          getSenderName: @escaping (Chatter) -> String,
          eventTimeDescription: @escaping (_ start: Int64, _ end: Int64, _ isAllDay: Bool) -> String) {
        super.init(message: shareEventMessage, getSenderName: getSenderName)

        guard let content = shareEventMessage.content as? EventShareContent else {
            return nil
        }

        self.title = content.title.isEmpty ? BundleI18n.LarkChat.Lark_View_ServerNoTitle : content.title
        self.eventTimeDescription = {
            return eventTimeDescription(content.startTime, content.endTime, content.isAllDay ?? false)
        }
    }
}
