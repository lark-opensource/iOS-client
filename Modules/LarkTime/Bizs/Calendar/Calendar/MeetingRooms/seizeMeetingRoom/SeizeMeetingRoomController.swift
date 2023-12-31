//
//  SeizeMeetingRoomController.swift
//  Calendar
//
//  Created by harry zou on 2019/4/15.
//

import UIKit
import RxSwift
import RxCocoa
import RoundedHUD
import CalendarFoundation
import LarkTimeFormatUtils
import LarkContainer

protocol SeizeMeetingRoomDependency {
    func getMeetingroom(with token: String, startTime: Int, endTime: Int, currentTenantId: String) -> Observable<SeizeMeetingRoomModel>
    func seizeMeetingroom(calendarId: String, startTime: Int, endTime: Int) -> Observable<CalendarEventEntity>
    func setShouldShowPopup(shouldShowPopUp: Bool) -> Observable<Void>

    var currentTenantID: String { get }
    var defaultEventLength: Int { get }
    var is12HourStyle: BehaviorRelay<Bool> { get }
}

final class SeizeMeetingRoomDependencyImpl: SeizeMeetingRoomDependency, UserResolverWrapper {
    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    @ScopedInjectedLazy var rustAPI: CalendarRustAPI?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    var currentTenantID: String { calendarDependency?.currentUser.tenantId ?? "" }

    var defaultEventLength: Int {
        return Int(SettingService.shared().getSetting().defaultEventDuration)
    }

    var is12HourStyle: BehaviorRelay<Bool> { calendarDependency?.is12HourStyle ?? .init(value: false) }

    func getMeetingroom(with token: String, startTime: Int, endTime: Int, currentTenantId: String) -> Observable<SeizeMeetingRoomModel> {
        return rustAPI?.getMeetingroom(with: token, startTime: startTime, endTime: endTime, currentTenantId: currentTenantId) ?? .empty()
    }

    func seizeMeetingroom(calendarId: String, startTime: Int, endTime: Int) -> Observable<CalendarEventEntity> {
        return rustAPI?.seizeMeetingroom(calendarId: calendarId, startTime: startTime, endTime: endTime) ?? .empty()
    }

    func setShouldShowPopup(shouldShowPopUp: Bool) -> Observable<Void> {
        return rustAPI?.setShouldShowPopup(shouldShowPopUp: shouldShowPopUp) ?? .empty()
    }

}

final class SeizeMeetingRoomController: CalendarController, UserResolverWrapper {

    let userResolver: UserResolver
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    private var dependency: SeizeMeetingRoomDependency
    private static let defaultDuration: Int = 600
    private let disposeBag = DisposeBag()
    private var isFirstTime = true

    private let token: String
    private let jumpToEventDetail: (CalendarEventEntity) -> UIViewController

    private var seizeMeetingroomModel: SeizeMeetingRoomModel?
    private var secondsLeft: Double
    private var availableTimeStart: Int = -1
    private var hasCurrentInstance: Bool = false
    private var availableTimeEnd: Int = -1

    private let countDown: CountdownView
    private var actionSheet: SeizeMeetingroomActionSheet?
    private let meetingRoomCell = SeizeMeetingRoomCell()
    private let creatorCell = MeetingCreatorCell(frame: .zero)
    private let timeCell = SeizeTimeCell()
    private let seizeableWrapper = UIView()
    private let seizeButton: UIButton = SeizeButton()
    private var timer = Timer()
    private var confirmView: SeizeConfirmView?
    private let hintLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.Calendar.Calendar_Takeover_TipsBottom
        label.textAlignment = .center
        return label
    }()
    private lazy var loadingView: LoadingView? = LoadingView(displayedView: self.view)

    init(userResolver: UserResolver,
         dependency: SeizeMeetingRoomDependency,
         token: String,
         jumpToEventDetail: @escaping ((CalendarEventEntity) -> UIViewController)) {
        self.userResolver = userResolver
        self.dependency = dependency
        self.token = token
        self.jumpToEventDetail = jumpToEventDetail
        self.secondsLeft = Double(SeizeMeetingRoomController.defaultDuration)
        self.countDown = CountdownView(redius: 120,
                                       lineWidth: 10,
                                       secondsLeft: Double(SeizeMeetingRoomController.defaultDuration),
                                       totalSeconds: SeizeMeetingRoomController.defaultDuration,
                                        scale: 1)
        super.init(nibName: nil, bundle: nil)
        self.title = BundleI18n.Calendar.Calendar_Takeover_Takeover
        self.addBackItem()
    }

    deinit {
        timer.invalidate()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        reloadData(is12HourStyle: dependency.is12HourStyle.value)
        setup(seizeButton: seizeButton)
        timer = Timer(timeInterval: 1, repeats: true) { [weak self] (_) in
            guard let `self` = self else { return }
            self.secondsLeft -= 1
            if self.secondsLeft >= 0 {
                self.countDown.update(secondsLeft: self.secondsLeft, totalSeconds: self.seizeMeetingroomModel?.seizeTime ?? SeizeMeetingRoomController.defaultDuration)
            }
            // 每10s Call一次SDK更新
            if Int(self.secondsLeft) % 10 == 0 {
                self.reloadData(is12HourStyle: self.dependency.is12HourStyle.value)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.loadingView?.showLoading()
        }
    }

    private func reloadData(is12HourStyle: Bool) {
        dependency.getMeetingroom(with: token,
                           startTime: Int(Date().dayStart().timeIntervalSince1970),
                           endTime: Int(Date().dayEnd().timeIntervalSince1970),
                           currentTenantId: dependency.currentTenantID).subscribeForUI(onNext: { [weak self] (model) in
                            guard let `self` = self else {
                                return
                            }
                            self.stopLoading()
                            if self.seizeMeetingroomModel == nil {
                                self.layout(seizeableView: self.seizeableWrapper)
                            }
                            self.seizeMeetingroomModel = model
                            self.updateView(model: model, is12HourStyle: is12HourStyle)
                            }, onError: { [weak self] (error) in
                                if self?.isFirstTime ?? false {
                                    CalendarTracer.shareInstance.enterSeizeMeetingRoom(isNormal: false)
                                    self?.isFirstTime = false
                                }
                                self?.stopLoading()
                                switch Int(error.errorCode() ?? 0) {
                                case SeizeMeetingRoomModel.Errors.resourceIsDisabledErr.rawValue:
                                    self?.showNormalError(type: .bannedMeetingRoom)
                                case SeizeMeetingRoomModel.Errors.businessUnpaidErr.rawValue:
                                    self?.showNormalError(type: .notSubscribe)
                                case SeizeMeetingRoomModel.Errors.resourceSeizeClosedErr.rawValue:
                                    self?.showNormalError(type: .seizeFeatureClosed)
                                case SeizeMeetingRoomModel.Errors.resourceNotFoundErr.rawValue:
                                    self?.showNormalError(type: .scanQRCodeFailed)
                                case SeizeMeetingRoomModel.Errors.externalUser.rawValue:
                                    self?.showNormalError(type: .illegalUser)
                                default:
                                    self?.updateErrorView(error: nil)
                                }
                                operationLog(message: error.localizedDescription, optType: nil)
                            }).disposed(by: disposeBag)
    }

    func layout(seizeableView: UIView) {
        self.view.addSubview(seizeableWrapper)
        seizeableWrapper.backgroundColor = UIColor.ud.bgBody
        seizeableWrapper.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        layout(meetingRoomCell: meetingRoomCell, in: seizeableWrapper)
        layout(timeCell: timeCell, in: seizeableWrapper, topView: meetingRoomCell)
        layout(countDown: countDown, in: seizeableWrapper, topView: timeCell)
        layout(seizeButton: seizeButton, in: seizeableWrapper, topView: countDown)
        layout(hintLabel: hintLabel, in: seizeableWrapper)
    }

    func showNormalError(type: SeizeFailedView.ErrorType) {
        let failedWrapper = UIView()
        failedWrapper.layout(equalTo: self.view)
        seizeableWrapper.removeFromSuperview()
        let failedView = SeizeFailedView(type: type)
        failedWrapper.addSubview(failedView)
        failedView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(158)
        }
    }

    private func updateErrorView(error: SeizeMeetingRoomModel.Errors?) {
        if self.seizeMeetingroomModel == nil {
            // 数据未能加载，显示空界面
            showNormalError(type: .scanQRCodeFailed)
            timer.invalidate()
            return
        }
        if let error = error {
            // 有具体错误，终止轮询
            actionSheet?.disappear()
            timer.invalidate()
            switch error {
            case .allDayEvent:
                showAlldayView()
            case .availableDurationTooShoot:
                RoundedHUD.showTips(with: BundleI18n.Calendar.Calendar_Takeover_TimeChange, on: view)
                showNormalError(type: .noAvailableTime)
            case .resourceIsDisabledErr:
                showNormalError(type: .bannedMeetingRoom)
            case .businessUnpaidErr:
                showNormalError(type: .notSubscribe)
            case .resourceSeizeClosedErr:
                showNormalError(type: .seizeFeatureClosed)
            case .resourceNotFoundErr:
                showNormalError(type: .scanQRCodeFailed)
            case .externalUser:
                showNormalError(type: .illegalUser)
            }
        }
    }

    func showAlldayView() {
        meetingRoomCell.removeFromSuperview()
        timeCell.removeFromSuperview()
        let failedWrapper = UIView()
        failedWrapper.backgroundColor = UIColor.ud.bgBody
        guard let instance = self.seizeMeetingroomModel?.getCurrentAlldayInstance() as? CalendarEventInstanceEntityFromPB else {
            showNormalError(type: .scanQRCodeFailed)
            return
        }
        let creatorEntity = CreatorEntity(avatarKey: instance.getCreator().avatarKey,
                                          userName: instance.getCreator().name,
                                          chatId: instance.getCreator().chatterID)
        failedWrapper.layout(equalTo: self.view)
        seizeableWrapper.removeFromSuperview()
        let failedView = SeizeFailedView(type: .allDayEvent)
        meetingRoomCell.update(title: self.seizeMeetingroomModel?.meetingRoom.fullName ?? "")
        // 时区默认为设备时区 - 显示 M 月 d 日
        let customOptions = Options(
            timeFormatType: .short,
            datePrecisionType: .day
        )
        let dayText = TimeFormatUtils.formatDate(from: Date(), with: customOptions)
        let title = BundleI18n.Calendar.Calendar_Takeover_AlldayTIme(Date: dayText)
        timeCell.update(title: title)
        timeCell.setTag(isHidden: true)
        timeCell.showAlldayBorder()
        layout(meetingRoomCell: meetingRoomCell, in: failedWrapper)
        layout(timeCell: timeCell, in: failedWrapper, topView: meetingRoomCell)
        failedWrapper.addSubview(creatorCell)
        creatorCell.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(timeCell.snp.bottom)
        }
        creatorCell.update(creatorEntity: creatorEntity)
        creatorCell.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] () in
            self?.jumpToChatter(title: title)
        }).disposed(by: disposeBag)
        failedWrapper.addSubview(failedView)
        failedView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(creatorCell.snp.bottom).offset(100)
        }
    }

    private func updateView(model: SeizeMeetingRoomModel, is12HourStyle: Bool) {
        var tipShowed: Bool = false

        func showTip(tip: String, obviousChange: Bool) {
            if tipShowed {
                return
            }
            if actionSheet?.isShowing ?? false {
                tipShowed = true
                RoundedHUD.showTips(with: tip, on: view)
                return
            }
            if obviousChange {
                tipShowed = true
                let height = seizeableWrapper.bounds.height
                // 总高度 - 两个cell - 倒计时圈上边缘距cell底部 - 倒计时圈高度 - 倒计时圈距抢占按钮顶部 + toast距抢占按钮顶部
                let offset = height - 53 * 2 - countDown.distanceToUpItem(width: view.bounds.width) - countDown.intrinsicContentSize.height - countDown.distanceToButton(width: view.bounds.width) + 20
                RoundedHUD.showTips(with: tip, on: seizeableWrapper).setCustomBottomMargin(offset)
            }
        }
        do {
        let (secondsLeftInt, availableTimeStart, availableTimeEnd, hasCurrentInstance) = try model.getCountdownInfo()
        if self.isFirstTime {
            CalendarTracer.shareInstance.enterSeizeMeetingRoom(isNormal: true)
            self.isFirstTime = false
        }
        let secondsLeft = Double(secondsLeftInt)
        if self.availableTimeEnd != availableTimeEnd {
            if self.availableTimeEnd != -1 {
                showTip(tip: BundleI18n.Calendar.Calendar_Takeover_TimeChange, obviousChange: false)
            }
            self.availableTimeEnd = availableTimeEnd
        }
        if self.hasCurrentInstance != hasCurrentInstance
            && self.hasCurrentInstance
            && !hasCurrentInstance
            && self.secondsLeft != 0 {
                showTip(tip: BundleI18n.Calendar.Calendar_Takeover_TimeChange, obviousChange: true)
        }
        if self.availableTimeStart != availableTimeStart {
            if secondsLeft != 0, self.availableTimeStart != -1 {
                showTip(tip: BundleI18n.Calendar.Calendar_Takeover_TimeChange, obviousChange: true)
            }
            self.availableTimeStart = availableTimeStart
        }
        if self.secondsLeft != secondsLeft {
            self.secondsLeft = secondsLeft
        }
        if secondsLeft == 0 {
            seizeButton.isEnabled = true
        } else {
            seizeButton.isEnabled = false
        }
        countDown.update(secondsLeft: secondsLeft, totalSeconds: model.seizeTime)
        meetingRoomCell.update(title: model.meetingRoom.fullName)
        timeCell.update(title: model.getTimeCellString(currentTime: model.currentTimeStamp,
                                                       availableTimeStart: availableTimeStart,
                                                       availTimeEnd: availableTimeEnd,
                                                       is12HourStyle: is12HourStyle))
        if secondsLeft != 0 {
            actionSheet?.disappear()
        }
        actionSheet?.update(model: DurationSelectionModel(startTime: availableTimeStart,
                                                           nextUnavailableTime: availableTimeEnd))
        } catch let error as SeizeMeetingRoomModel.Errors {
            updateErrorView(error: error)
            if self.isFirstTime {
                CalendarTracer.shareInstance.enterSeizeMeetingRoom(isNormal: false)
                self.isFirstTime = false
            }
            return
        } catch {
            assertionFailure()
            return
        }
    }

    private func layout(countDown: CountdownView, in superview: UIView, topView: UIView) {
        superview.addSubview(countDown)
        let offset = countDown.distanceToUpItem(width: superview.bounds.width)
        countDown.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(topView.snp.bottom).offset(offset)
        }
    }

    private func layout(meetingRoomCell: UIView, in superview: UIView) {
        superview.addSubview(meetingRoomCell)
        meetingRoomCell.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
    }

    private func layout(timeCell: UIView, in superview: UIView, topView: UIView) {
        superview.addSubview(timeCell)
        timeCell.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(topView.snp.bottom)
        }
    }

    private func layout(seizeButton: UIView, in superview: UIView, topView: UIView) {
        superview.addSubview(seizeButton)
        let offset = countDown.distanceToUpItem(width: superview.bounds.width)
        seizeButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().inset(97.5)
            make.top.equalTo(topView.snp.bottom).offset(offset)
        }
    }

    private func layout(hintLabel: UIView, in superview: UIView) {
        superview.addSubview(hintLabel)
        hintLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(superview.safeAreaLayoutGuide.snp.bottom).offset(-16)
            make.left.right.equalToSuperview().inset(16)
            make.centerX.equalToSuperview()
        }
    }

    @objc
    private func jumpToChatter(title: String) {
        if let chatterId = (self.seizeMeetingroomModel?.getCurrentAlldayInstance()as? CalendarEventInstanceEntityFromPB)?.getCreator().chatterID {
            CalendarTracer.shareInstance.calShowUserCard(actionSource: .seizeMeetingroom)
            calendarDependency?.jumpToProfile(chatterId: chatterId, eventTitle: title, from: self)
        }
    }

    private func setup(seizeButton: UIButton) {
        seizeButton.addTarget(self, action: #selector(seizeButtonPressed), for: .touchUpInside)
    }

    @objc
    private func seizeButtonPressed() {
        guard let seizeMeetingroomModel = seizeMeetingroomModel else {
            assertionFailureLog()
            return
        }
        CalendarTracer.shareInstance.tapSeize()
        if seizeMeetingroomModel.shouldShowConfirm {
            confirmView = SeizeConfirmView()
            confirmView!.confirmPressed = { [unowned self] (nextTime) in
                self.dependency.setShouldShowPopup(shouldShowPopUp: !nextTime).subscribeForUI(onNext: { [weak self] (_) in
                    self?.showActionSheet()
                }, onError: { [weak self] error in
                    guard let self = self else { return }
                    RoundedHUD.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_SubscribeCalendar_OperationFailed, on: self.view)
                }).disposed(by: self.disposeBag)
            }
            confirmView!.show(in: self)
            return
        }
        showActionSheet()
    }

    private func showActionSheet() {
        if let actionSheet = self.actionSheet {
            actionSheet.show(in: self)
        } else {
            let durationSelectionModel = DurationSelectionModel(startTime: availableTimeStart,
                                                                nextUnavailableTime: availableTimeEnd)
            let actionSheet = SeizeMeetingroomActionSheet(model: durationSelectionModel, defaultDuration: dependency.defaultEventLength, is12HourStyle: dependency.is12HourStyle)
            actionSheet.timeConfirmed = { [unowned self] (startTime, endTime) in
                guard let calendarId = self.seizeMeetingroomModel?.meetingRoom.uniqueId else {
                    return
                }
                CalendarTracer.shareInstance.tapSeizeNow()
                self.dependency.seizeMeetingroom(calendarId: calendarId,
                                          startTime: startTime,
                                          endTime: endTime).subscribeForUI(onNext: { [weak self] (entity) in
                                            self?.actionSheet?.disappear()
                                            if let vc = self?.jumpToEventDetail(entity) {
                                                if let rootVC = self?.navigationController?.viewControllers.first {
                                                    self?.navigationController?.setViewControllers([rootVC, vc], animated: true)
                                                }
                                            }
                                          }, onError: { [weak self] (error) in
                                            guard let self = self else { return }
                                            self.actionSheet?.disappear()
                                            RoundedHUD.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Takeover_FailTakeover, on: self.view)
                                          }).disposed(by: self.disposeBag)
            }
            self.actionSheet = actionSheet
            actionSheet.show(in: self)
        }
    }

    func stopLoading() {
        if let loadingView = self.loadingView {
            loadingView.hideSelf()
            loadingView.removeFromSuperview()
            self.loadingView = nil
        }
    }
}
