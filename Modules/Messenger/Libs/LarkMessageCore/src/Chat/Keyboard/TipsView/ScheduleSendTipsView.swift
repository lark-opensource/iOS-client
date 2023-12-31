//
//  ScheduleSendTipsView.swift
//  LarkMessageCore
//
//  Created by JackZhao on 2022/9/1.
//

import UIKit
import RustPB
import LarkModel
import Foundation
import LarkContainer
import LarkMessageBase
import LarkSDKInterface
import UniverseDesignIcon
import UniverseDesignColor
import LarkChatOpenKeyboard

public struct SendMessageModel {
    public var parentMessage: Message?
    public var threadId: String?
    public var messageId: String
    public var cid: String
    public var itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType

    public init(parentMessage: Message? = nil,
                messageId: String = "",
                cid: String = "",
                itemType: RustPB.Basic_V1_ScheduleMessageItem.ItemType = .scheduleMessage,
                threadId: String? = nil) {
        self.cid = cid
        self.messageId = messageId
        self.itemType = itemType
        self.parentMessage = parentMessage
        self.threadId = threadId
    }
}

class ScheduleSendTipsView: UIView, KeyboardTipsView {
    weak var delegate: KeyboardSchuduleSendButtonDelegate?

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.udtokenReactionBgGrey
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 8
        return view
    }()

    private lazy var sendTimeTitle: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkMessageCore.Lark_IM_ScheduleMessage_SendAtTime_Text
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.textColor = .ud.textCaption
        return label
    }()

    private lazy var sendTime: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.textColor = .ud.colorfulBlue
        return label
    }()

    private lazy var exitIcon: ExpandImageView = {
        let icon = ExpandImageView()
        icon.image = UDIcon.closeSmallOutlined.ud.withTintColor(UIColor.ud.iconN3)
        return icon
    }()

    private let time: Date
    private let showExit: Bool
    private let timeDesc: String
    private let sendMessageModel: SendMessageModel
    private let is12HourStyle: Bool

    init(time: Date,
         timeDesc: String,
         is12HourStyle: Bool,
         sendMessageModel: SendMessageModel,
         showExit: Bool,
         delegate: KeyboardSchuduleSendButtonDelegate?) {
        self.time = time
        self.showExit = showExit
        self.timeDesc = timeDesc
        self.is12HourStyle = is12HourStyle
        self.delegate = delegate
        self.sendMessageModel = sendMessageModel
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBodyOverlay

        self.delegate?.scheduleTipDidShow(date: time)
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 8, bottom: 0, right: 8))
        }

        containerView.addSubview(sendTimeTitle)
        sendTimeTitle.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(Cons.titleHeight)
            make.left.equalTo(Cons.horizontalPadding)
            make.top.equalTo(Cons.verticalPadding)
        }

        containerView.addSubview(sendTime)
        sendTime.text = timeDesc
        sendTime.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(sendTimeTitle.snp.right).offset(4)
            make.top.equalTo(Cons.verticalPadding)
        }
        sendTime.isUserInteractionEnabled = true
        sendTime.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(timeTapped)))

        if showExit {
            containerView.addSubview(exitIcon)
            exitIcon.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.width.height.equalTo(24)
                make.right.equalTo(-9)
            }
            exitIcon.isUserInteractionEnabled = true
            exitIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(exitTapped)))
        }
    }

    @objc
    private func timeTapped() {
        let model = self.sendMessageModel
        delegate?.onMessengerKeyboardPanelSchuduleSendTimeTap(currentSelectDate: time, sendMessageModel: model) { [weak self] date in
            self?.sendTime.text = ScheduleSendManager.formatScheduleTimeWithDate(date,
                                                                                 is12HourStyle: self?.is12HourStyle == true,
                                                                                 isShowYear: Date().year != date.year)
            // 更新输入框的数据
            let sendModel = ScheduleSendModel(parentMessage: model.parentMessage,
                                              messageId: model.messageId,
                                              cid: model.cid,
                                              itemType: model.itemType,
                                              threadId: model.threadId)
            self?.delegate?.updateTip(.scheduleSend(date, self?.showExit ?? false, self?.is12HourStyle == true, sendModel))
        }
    }

    @objc
    private func exitTapped() {
        delegate?.onMessengerKeyboardPanelSchuduleExitButtonTap()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    struct Cons {
        static let containerVerticalPadding: CGFloat = 8
        static let titleHeight: CGFloat = 20
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 8
    }

    func suggestHeight(maxWidth: CGFloat) -> CGFloat {
        Cons.titleHeight + Cons.verticalPadding * 2 + Cons.containerVerticalPadding * 2
    }
}

class ExpandImageView: UIImageView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 四周热区扩大4
        let insets = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        if bounds.inset(by: insets).contains(point) {
            return self
        }
        return super.hitTest(point, with: event)
    }
}
