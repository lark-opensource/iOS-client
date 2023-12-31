//
//  EventReplyViewController.swift
//  Calendar
//
//  Created by heng zhu on 2019/7/24.
//

import UniverseDesignIcon
import Foundation
import RxSwift
import RustPB
import LarkUIKit
import UIKit
import RoundedHUD
import CalendarFoundation
import UniverseDesignToast
import LarkContainer

final class EventReplyViewController: UIViewController, UserResolverWrapper {

    let userResolver: UserResolver
    @ScopedInjectedLazy var calendarApi: CalendarRustAPI?

    private let replyView: ReplyView
    private let textView: KMPlaceholderTextView = {
        let view = KMPlaceholderTextView()
        view.font = UIFont.cd.regularFont(ofSize: 16)
        return view
    }()

    private let replySendButton: UIButton = {
        let button = UIButton.cd.button()
        button.setImage(UDIcon.getIconByKeyNoLimitSize(.sendColorful).scaleNaviSize().withRenderingMode(.alwaysOriginal), for: .normal)
        button.setImage(UDIcon.getIconByKeyNoLimitSize(.sendFilled).scaleNaviSize().renderColor(with: .n4), for: .disabled)
        return button
    }()
    private let sendView: UIView = UIView()

    private var replyMessage: String?
    private var bottomPadding: CGFloat = 0
    private let calendarId: String
    private let key: String
    private let originalTime: Int64
    private var messageId: String?
    private var status: CalendarEventAttendeeEntity.Status
    private var inviterCalendarId: String
    private let disposeBag: DisposeBag = DisposeBag()
    private let commpentSucess: (_ chatId: String) -> Void
    private var inviterlocalizedName: String?
    private let traceContext: TraceContext?

    var dismiss: ((_ message: String) -> Void)?
    var rsvpChange: ((_ status: CalendarEventAttendee.Status) -> Void)?
    var changeEvent: ((CalendarEvent) -> Void)?
    var isFromBot = false

    private var isWebinar: Bool = false

    init(userResolver: UserResolver,
         status: CalendarEventAttendeeEntity.Status,
         inviterCalendarId: String,
         inviterlocalizedName: String?,
         replyMessage: String? = nil,
         calendarId: String,
         key: String,
         originalTime: Int64,
         messageId: String?,
         traceContext: TraceContext? = nil,
         isWebinar: Bool,
         commpentSucess: @escaping (_ chatId: String) -> Void
         ) {
        self.userResolver = userResolver
        let replyViewModel = ReplyViewModel(status: status)
        self.calendarId = calendarId
        self.inviterlocalizedName = inviterlocalizedName
        self.status = status
        self.originalTime = originalTime
        self.key = key
        self.messageId = messageId
        self.inviterCalendarId = inviterCalendarId
        self.replyMessage = replyMessage
        self.replyView = ReplyView(content: replyViewModel, isPackUpStyle: true)
        self.commpentSucess = commpentSucess
        self.traceContext = traceContext
        self.isWebinar = isWebinar
        super.init(nibName: nil, bundle: nil)

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateStatus(status: CalendarEventAttendeeEntity.Status) {
        replyView.setStatus(status)
    }
    private var textViewMaxHeight: CGFloat = 0.0
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        self.replyView.delegate = self

        if let placeholder = inviterlocalizedName, !placeholder.isEmpty {
            self.textView.placeholder = BundleI18n.Calendar.Calendar_Detail_ReplyRSVPSendto(value: placeholder)
        } else {
            self.calendarApi?
                .getChatters(userIds: [inviterCalendarId])
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (chatterMap) in
                    guard let `self` = self else { return }
                    if let chatter = chatterMap.first?.value {
                        self.textView.placeholder = BundleI18n.Calendar.Calendar_Detail_ReplyRSVPSendto(value: FG.useChatterAnotherName ? chatter.nameWithAnotherName : chatter.localizedName)
                }
            }).disposed(by: disposeBag)
        }

        if let message = replyMessage {
            textView.text = message
        }

        replySendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        textView.rx.value.asDriver().drive(onNext: { [weak self] (message) in
            self?.replyMessage = message
            let messageTrimed: String? = message?.trimmingCharacters(in: .whitespacesAndNewlines)
            let messageIsEmpty = messageTrimed?.isEmpty ?? true
            self?.replySendButton.isEnabled = !messageIsEmpty
        }).disposed(by: disposeBag)

    }

    private var isFirstEnter: Bool = true

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textViewMaxHeight = self.view.frame.height - replyBarHeight - sendViewHeight - offsetBetweenReplyViewAndTextView
        layoutReplyBar(replyView)
        layoutTextView(textView, maxHeight: textViewMaxHeight)
        layoutSendView(sendView)

        DispatchQueue.main.async {
            self.registerNotification()
            self.textView.becomeFirstResponder()
        }
        isFirstEnter = false
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if !Display.pad || isFirstEnter || isKeyBoardOpen {
            return
        }
        textViewMaxHeight = self.view.frame.height - replyBarHeight - sendViewHeight - offsetBetweenReplyViewAndTextView
        textView.snp.updateConstraints({ update in
            update.height.equalTo(textViewMaxHeight)
            update.left.equalToSuperview().offset(12)
            update.right.equalToSuperview().offset(-12)
            update.top.equalTo(replyView.snp.bottom).offset(offsetBetweenReplyViewAndTextView)
        })
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func registerNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameChange(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardFrameChange(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc
    private func sendButtonTapped() {
        let messageReply = self.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.reply(status: self.status, comment: messageReply)
        CalendarTracerV2.EventDetail.traceClick {
            $0.click("reply")
            $0.event_type = self.isWebinar ? "webinar" : "normal"
            $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: self.traceContext?.eventID,
                                                                   eventStartTime: self.traceContext?.startTime.description,
                                                                   isRecurrence: self.traceContext?.isRecurrence,
                                                                   originalTime: self.traceContext?.originalTime?.description,
                                                                   uid: self.traceContext?.uid))
        }
    }

    private var isKeyBoardOpen: Bool = false

    @objc
    private func keyboardFrameChange(_ notify: Notification) {
        guard let userinfo = notify.userInfo else {
            return
        }

        let duration: TimeInterval = userinfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0

        guard let curveValue = userinfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
            let curve = UIView.AnimationCurve(rawValue: curveValue) else {
                return
        }

        if notify.name == UIResponder.keyboardWillShowNotification {
            guard let keyboardFrame = userinfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                return
            }
            if Display.pad {
                DispatchQueue.main.async {
                    if let screenView = self.view.window {
                        let rect = self.view.convert(self.view.bounds, to: screenView)
                        self.bottomPadding = keyboardFrame.height - (Display.height - rect.bottom)
                        if self.bottomPadding < 0 {
                            self.bottomPadding = 0
                        }
                    }
                    self.setContentHeight(Float(self.textViewMaxHeight - self.bottomPadding), duration: duration, curve: curve)
                }
                isKeyBoardOpen = true
                return
            }
            self.bottomPadding = keyboardFrame.size.height
        } else if notify.name == UIResponder.keyboardWillHideNotification {
            isKeyBoardOpen = false
            self.bottomPadding = 0
        }

        self.setContentHeight(Float(textViewMaxHeight - bottomPadding), duration: duration, curve: curve)
    }

    private var contentHeight: Float = 0
    private var animationFinish: Bool = true
    private func setContentHeight(
        _ height: Float,
        duration: TimeInterval,
        curve: UIView.AnimationCurve?,
        completion: ((Bool) -> Void)? = nil) {
        if contentHeight == height {
            completion?(true)
            return
        }
        contentHeight = height
        textView.snp.updateConstraints({ update in
            update.height.equalTo(contentHeight)
            update.left.equalToSuperview().offset(12)
            update.right.equalToSuperview().offset(-12)
            update.top.equalTo(replyView.snp.bottom).offset(offsetBetweenReplyViewAndTextView)
        })
        if duration > 0 {
            self.animationFinish = false
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.beginFromCurrentState],
                animations: {
                    if let curve = curve {
                        UIView.setAnimationCurve(curve)
                    }

                }, completion: { (finish) in
                completion?(finish)
                self.animationFinish = true
                })
        } else {
            completion?(true)
        }
    }

    private let replyBarHeight: CGFloat = 44

    private func layoutReplyBar(_ replyBar: UIView) {
        view.addSubview(replyBar)
        replyBar.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(replyBarHeight)
        }
    }

    private let offsetBetweenReplyViewAndTextView: CGFloat = 6.5

    private func layoutTextView(_ textView: UIView, maxHeight: CGFloat) {
        view.addSubview(textView)
        textView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
            make.top.equalTo(replyView.snp.bottom).offset(offsetBetweenReplyViewAndTextView)
            make.height.equalTo(maxHeight)
        }
    }

    private let sendViewHeight: CGFloat = 38

    private func layoutSendView(_ sendView: UIView) {
        view.addSubview(sendView)
        sendView.snp.makeConstraints { (make) in
            make.height.equalTo(sendViewHeight)
            make.left.right.equalToSuperview()
            make.top.equalTo(textView.snp.bottom)
        }

        sendView.addSubview(replySendButton)
        replySendButton.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }

    private func reply(status: CalendarEventAttendeeEntity.Status, comment: String) {
        if isFromBot {
            CalendarMonitorUtil.startTrackRsvpEventBotCardTime(calEventId: traceContext?.eventID, originalTime: originalTime, uid: key)
        } else {
            CalendarMonitorUtil.startTrackRsvpEventDetailTime(calEventId: traceContext?.eventID, originalTime: originalTime, uid: key)
        }
        let hud = RoundedHUD()
        //处理网络回调闭包
        let accessResult = { [weak self] (event: CalendarEventEntity, chatID: String, errorCodes: [Int32]) in
            guard let `self` = self else { return }
            if !event.calendarId.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    hud.showSuccess(with: BundleI18n.Calendar.Calendar_Detail_ResponseSuccessed, on: self.view)
                    self.replyView.setStatus(status)
                    self.status = status
                    self.rsvpChange?(status)
                    self.changeEvent?(event.getPBModel())
                    if !chatID.isEmpty {
                        self.commpentSucess(chatID)
                    }
                })
                if self.isFromBot {
                    CalendarMonitorUtil.endTrackRsvpEventBotCardTime()
                } else {
                    CalendarMonitorUtil.endTrackRsvpEventDetailTime()
                }
            } else {
                hud.showFailure(with: BundleI18n.Calendar.Calendar_Detail_ResponseFailed, on: self.view)
            }
            if errorCodes.contains(where: { ErrorType(rawValue: $0) == .invalidCipherFailedToSendMessage }) {
                UDToast.showFailure(with: I18n.Calendar_KeyNoToast_CannoReply_Pop, on: self.view)
            }
            CalendarTracerV2.EventCard.traceClick {
                $0.click("reply").target("none")
                if let traceContext = self.traceContext {
                    $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: self.traceContext?.eventID,
                                                                           eventStartTime: self.traceContext?.startTime.description,
                                                                           isRecurrence: self.traceContext?.isRecurrence,
                                                                           originalTime: self.traceContext?.originalTime?.description,
                                                                           uid: self.traceContext?.uid))
                }
                $0.chat_id = chatID
                $0.event_type = self.isWebinar ? "webinar" : "normal"
                $0.is_new_card_type = "false"
                $0.is_support_reaction = "false"
                $0.is_bot = "true"
                $0.is_share = "false"
                $0.is_invited = status == .removed ? "false" : "true"
                $0.is_reply_card = status == .removed ? "false" : "true"
            }
        }

        //处理网络error
        let accessError = { (error: Error) -> Void in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
                guard let self = self else { return }
                let errorType = error.errorType()
                if errorType == .unableSendRSVPCommentErr {
                    hud.remove()
                    EventAlert.showCancelReplyRSVPAlert(
                        title: BundleI18n.Calendar.Calendar_Detail_ReplyRSVPNotFriend,
                        controller: self,
                        acknowledgeAction: nil
                    )
                } else if errorType == .userAlreadyDismissedErr {
                    hud.remove()
                    EventAlert.showCancelReplyRSVPAlert(
                        title: BundleI18n.Calendar.Calendar_Detail_ReplyRSVPResigned,
                        controller: self,
                        acknowledgeAction: nil
                    )
                } else {
                    hud.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Detail_ResponseFailed, on: self.view)
                }
            })
        }
        hud.showLoading(with: BundleI18n.Calendar.Calendar_Toast_ReplyingMobile, on: view, disableUserInteraction: true)

        self.calendarApi?.replyCalendarEventInvitation(
            calendarId: calendarId,
            key: key,
            originalTime: originalTime,
            comment: comment,
            inviteOperatorID: inviterCalendarId,
            replyStatus: status,
            messageId: messageId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: accessResult, onError: accessError)
            .disposed(by: disposeBag)
    }

}

extension EventReplyViewController: ReplyViewDelegate {
    func replyView(_ replyView: ReplyView,
                   actionBarDidTap status: CalendarEventAttendeeEntity.Status) {
        self.status = status
        self.updateStatus(status: self.status)
    }

    func sysActionBarDidTap(_ replyView: ReplyView) {
    }

    func replyViewJoinBtnTaped(_ replyView: ReplyView) {
    }

    //点击关闭回复页面
    func replyViewReplyTaped(_ replyView: ReplyView) {
        self.dismiss?(textView.text)
    }
}

extension EventReplyViewController {
    struct TraceContext {
        let eventID: String
        let startTime: Int64
        let isRecurrence: Bool
        let originalTime: Int?
        let uid: String?
    }
}
