//
//  PinSchedulerRoundRobinPinConfirmView.swift
//  LarkChat
//
//  Created by tuwenbo on 2023/4/5.
//

import Foundation
import UIKit
import LarkModel

final class PinSchedulerRoundRobinPinConfirmView: PinConfirmContainerView {
    var icon: UIImageView
    var title: UILabel
    var eventTimeDescription: UILabel

    override init(frame: CGRect) {
        self.icon = UIImageView(image: Resources.pinCalenderTip)
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

        guard let vm = contentVM as? SchedulerRoundRobinPinConfirmViewModel else {
            return
        }
        title.text = vm.title
        eventTimeDescription.text = vm.eventTimeDescription?() ?? ""
    }
}

final class SchedulerRoundRobinPinConfirmViewModel: PinAlertViewModel {
    var title: String = ""
    var eventTimeDescription: (() -> String)?
    init?(message: Message,
          getSenderName: @escaping (Chatter) -> String,
          eventTimeDescription: @escaping (_ start: Int64, _ end: Int64, _ isAllDay: Bool) -> String) {
        super.init(message: message, getSenderName: getSenderName)

        guard let content = message.content as? RoundRobinCardContent else {
            return nil
        }
        if content.status == .statusActive {
            self.title = BundleI18n.Calendar.Calendar_Scheduling_WhoDidEvent_Bot(host: content.hostName, invitee: content.guestName)
        } else {
            self.title = BundleI18n.Calendar.Calendar_Scheduling_EventNoAvailable_Bot
        }
        self.eventTimeDescription = {
            return eventTimeDescription(content.startTime, content.endTime, false)
        }
    }
}
