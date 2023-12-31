//
//  EventEditViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/2/13.
//

import LarkUIKit
import RxCocoa
import RxSwift
import SnapKit
import CalendarFoundation
import LarkAlertController
import LarkKeyCommandKit
import AppReciableSDK
import UniverseDesignToast
import LarkContainer
import EENavigator
import LarkGuide
import LarkGuideUI
import UIKit
import LarkTimeFormatUtils
import UniverseDesignActionPanel
import UniverseDesignColor
import UniverseDesignFont

/// 日程编辑页

final class EventEditViewController: BaseUIViewController, UIAdaptivePresentationControllerDelegate, UIScrollViewDelegate, UserResolverWrapper {
    enum EditType: String { // 用于埋点
        case new
        case edit
    }
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(EventEditUIStyle.Color.viewControllerBackground)
    }

    let userResolver: UserResolver

    @ScopedInjectedLazy var pushService: RustPushService?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?
    @ScopedInjectedLazy var docsDispatherSerivce: DocsDispatherSerivce?
    @ScopedInjectedLazy var newGuideManager: NewGuideService?

    weak var delegate: EventEditViewControllerDelegate?
    var viewModel: EventEditViewModel
    var editType: EventEditViewController.EditType = .new
    let disposeBag = DisposeBag()

    private var lastSaveDisposable: Disposable?

    // 标记本次编辑页是否发起过大人数日程审批
    var hasApprovedAttendeeCount: Bool = false
    // 是否展示过切换三方日历引导
    var isShowSwitchingCalendarGuide: Bool = false

    init(viewModel: EventEditViewModel, userResolver: UserResolver) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()

        setupViewModel()
        setupNaviItem()
        bindView()

        ReciableTracer.shared.recEndEditEvent()
        CalendarTracerV2.EventFullCreate.traceView {
            $0.event_type = self.viewModel.input.isWebinarScene ? "webinar" : "normal"
            $0.is_editor = (self.editType == .new) || self.event.isEditable ? "true" : "false"
            $0.from_source = self.viewModel.input.isFromAI ? "ai_create" : ""
            if case .chat(let scheduleConflictNum, let attendeeNum) = self.viewModel.actionSource {
                $0.from_source = "chat"
                $0.schedule_conflict_num = scheduleConflictNum
                $0.attendee_num = attendeeNum
            }
            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.viewModel.originalEvent?.getPBModel(),
                                                                   startTime: Int64(self.viewModel.originalEvent?.startDate.timeIntervalSince1970 ?? 0)))
        }

        NotificationCenter.default.rx
            .notification(UIApplication.userDidTakeScreenshotNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.onScreenShot()
            }).disposed(by: disposeBag)
        navigationController?.presentationController?.delegate = self
    }

    private func onScreenShot() {
        guard let event = viewModel.eventModel?.rxModel?.value.getPBModel() else { return }
        let infos = event.getScreenShotInfo(scenario: "edit_event",
                                        instanceStartTime: event.startTime,
                                        eventInstanceEndTime: event.endTime)
        let logString = "user screenshot accompanying infos: \(infos)"

        EventEdit.logger.info(logString)
    }

    // 记录 view 是否第一次 appear
    private var isViewAppeared = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        inlineAIPanelShowUpIfNeed()

        guard !isViewAppeared else { return }
        isViewAppeared = true

        let b1 = showGuideForAddingAttendeeByEmail()
        let b2 = showGuideForSetVC()
        let b3 = showGuideForZoom()
        let b4 = showGuideForGuestPermission()
        if !b1 && !b2 && !b3 && !b4 {
            switch viewModel.input {
            case .createWithContext, .createWebinar:
                summaryView.textView.becomeFirstResponder()
            default: break
            }
        }

        viewModel.rxMeetingNotesViewData.accept(viewModel.rxMeetingNotesViewData.value)
    }

    private func showGuideForGuestPermission() -> Bool {
        guard let newGuideManager = newGuideManager, GuideService.shouldShowGuideForGuestPermission(newGuideManager: newGuideManager),
              shouldShow(id: .guestPermission) else { return false }
        hideKeyboard()
        GuideService.showGuideForGuestPermission(from: self, newGuideManager: newGuideManager, refreView: guestPermissionView)
        return true
    }

    private func showGuideForZoom() -> Bool {
        if !FG.shouldEnableZoom { return false }
        guard let newGuideManager = newGuideManager, GuideService.shouldShowGuideForZoom(newGuideManager: newGuideManager) && isNormalLego else {
            return false
        }
        var refFrame = view.convert(videoMeetingView.videoMeetingItem.tailLabel.frame, from: videoMeetingView.videoMeetingItem.tailLabel.superview)
        refFrame.top += 10
        let passthroughView = UIView(frame: refFrame)
        passthroughView.isHidden = true
        view.addSubview(passthroughView)
        GuideService.showGuideForZoom(
            from: self,
            newGuideManager: newGuideManager,
            referView: passthroughView,
            completion: { [weak passthroughView] in
                passthroughView?.removeFromSuperview()
            }
        )
        return true
    }

    private var isNormalLego: Bool {
        viewModel.legoInfo == .normal()
    }

    private func showGuideForSetVC() -> Bool {
        guard let newGuideManager = newGuideManager, GuideService.shouldShowGuideForSetVC(newGuideManager: newGuideManager) && isNormalLego else {
            return false
        }
        var refFrame = view.convert(videoMeetingView.frame, from: videoMeetingView.superview)
        refFrame.top += 10
        let passthroughView = UIView(frame: refFrame)
        passthroughView.isHidden = true
        view.addSubview(passthroughView)
        GuideService.showGuideForSetVC(
            from: self,
            newGuideManager: newGuideManager,
            referView: passthroughView,
            completion: { [weak passthroughView] in
                passthroughView?.removeFromSuperview()
            }
        )
        return true
    }

    private func showGuideForSwitchingCalendar() -> Bool {
        guard let newGuideManager = newGuideManager, GuideService.shouldShowGuideForSwitchingCalendar(newGuideManager: newGuideManager) && isNormalLego else {
            return false
        }
        var refFrame = view.convert(calendarView.frame, from: calendarView.superview)
        refFrame.top += 10
        let passthroughView = UIView(frame: refFrame)
        passthroughView.isHidden = true
        view.addSubview(passthroughView)
        GuideService.showGuideForSwitchingCalendar(
            from: self,
            newGuideManager: newGuideManager,
            referView: passthroughView,
            completion: { [weak passthroughView] in
                passthroughView?.removeFromSuperview()
            }
        )
        return true
    }

    private func showGuideForAddingAttendeeByEmail() -> Bool {
        guard case .createWithContext = viewModel.input else { return false }
        // 如果获取日历失败，仅显示 Error 弹窗
        guard Display.phone, !viewModel.rxHasGetCalendar.value else { return false }
        guard let newGuideManager = newGuideManager, GuideService.shouldShowGuideForAddingAttendeeByEmail(newGuideManager: newGuideManager) && isNormalLego else {
            return false
        }

        var refFrame = view.convert(attendeeView.frame, from: attendeeView.superview)
        refFrame.origin.x = 48
        refFrame.size.width = 60
        let passthroughView = UIView(frame: refFrame)
        passthroughView.isHidden = true
        view.addSubview(passthroughView)

        GuideService.showGuideForAddingAttendeeByEmail(
            from: self,
            newGuideManager: newGuideManager,
            referView: passthroughView,
            completion: { [weak passthroughView] in
                passthroughView?.removeFromSuperview()
            }
        )
        return true
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SettingService.shared().stateManager.activate()
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingService.shared().stateManager.inActivate()
        self.hideKeyboard()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        if viewModel.input.isWebinarScene {
            webinarFooterLabel.snp.updateConstraints {
                $0.bottom.equalToSuperview().offset(-view.safeAreaInsets.bottom)
            }
        } else {
            moduleContainerView.snp.updateConstraints {
                $0.bottom.equalToSuperview().offset(-view.safeAreaInsets.bottom)
            }
        }
    }

    override func handleModalDismissKeyCommand() {
        hideKeyboard()
        handleClosingClick()
        clearNoUseZoomMeetingIfNeeded(true)
    }

    lazy var rootView = EventEditRootScrollView()
    private lazy var moduleContainerView = EventEditModuleContainerView(groups: makeModuleGroups())
    private lazy var footerBar = EventEditFooterBarView()

    // 普通创建日程标题
    private lazy var summaryView = EventEditSummaryView()
    // 参与人
    private lazy var attendeeView = EventEditAttendeeView()
    private lazy var webinarSpeakerView = EventEditWebinarAttendeeView()
    private lazy var webinarAudienceView = EventEditWebinarAttendeeView()
    // 参与者权限
    private lazy var guestPermissionView = EventEditGuestPermissionView()
    private lazy var arrangeDateView = EventEditArrangeDateView()
    private lazy var pickDateView = EventEditPickDateView()
    private lazy var timeZoneView = EventEditTimeZoneView()

    private lazy var videoMeetingView = EventEditVideoMeetingView()

    private lazy var calendarView = EventEditCalendarView()
    private lazy var colorView = EventEditColorView()
    private lazy var visibilityView = EventEditVisibilityView()
    private lazy var freeBusyView = EventEditFreeBusyView()

    private lazy var meetingRoomView = EventEditMeetingRoomView()
    private lazy var locationView = EventEditLocationView()
    private lazy var reminderView = EventEditReminderView()
    private lazy var rruleView = EventEditRruleView()
    private lazy var attachmentView = EventEditAttachmentView()

    private lazy var checkInView = EventEditCheckInView()
    private lazy var meetingNotesView: EventEditMeetingNotesView = {
        let view = EventEditMeetingNotesView(
            userResolver: self.userResolver,
            bgColor: UDColor.bgFloat,
            createViewType: FG.myAI ? .ai : .list
        )
        view.iconSize = EventEditUIStyle.Layout.cellLeftIconSize
        return view
    }()

    private lazy var notesView: EventEditNotesView? = {
        guard let docsViewHolder = docsDispatherSerivce?.sell() else { return nil }
        return EventEditNotesView(frame: .zero, bgColor: UIColor.ud.bgFloat, docsViewHolder: docsViewHolder)
    }()
    private lazy var deleteView = EventEditDeleteView()

    private let webinarAttendeeMaxNum = 600
    var isEndDateEditable: Bool { rruleView.viewData?.isEndDateEditable ?? false }
    private(set) lazy var webinarFooterLabel = {
        let label = UILabel()
        label.font = UDFont.caption1
        label.textColor = UDColor.textCaption
        label.textAlignment = .center
        label.text = BundleI18n.Calendar.Calendar_Settings_MaxNumColon + String(webinarAttendeeMaxNum)
        return label
    }()
    
    private lazy var inlineAIViewController: InlineAIViewController = {
        let viewModel = InlineAIViewModel(userResolver: userResolver,
                                                 editType: self.editType)
        let inlineAIViewController = InlineAIViewController(viewModel: viewModel)
        inlineAIViewController.delegate = self
        return inlineAIViewController
    }()

    private func setupView() {
        view.backgroundColor = EventEditUIStyle.Color.viewControllerBackground

        /// View Hierarchy:
        /// |---containerView (self.view)
        ///     |---rootView
        ///         |---moduleContainerView
        ///             |---summaryView
        ///             |---attendeeView
        ///             |---....
        ///         |---footerBar

        rootView.showsVerticalScrollIndicator = false
        rootView.contentInsetAdjustmentBehavior = .never
        rootView.alwaysBounceVertical = true
        rootView.keyboardDismissMode = .onDrag
        view.addSubview(rootView)
        rootView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        rootView.delegate = self

        rootView.addSubview(moduleContainerView)
        moduleContainerView.snp.makeConstraints {
            $0.leading.top.width.equalToSuperview()
            if !viewModel.input.isWebinarScene {
                $0.bottom.equalToSuperview().offset(-view.safeAreaInsets.bottom)
            }
        }

        setupWebinarFooterView()

        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        // 主题view添加手势拦截掉父类（上面）的手势
        addTapGestureToSummaryView()
        #if !LARK_NO_DEBUG
        addDebugGesture()
        #endif
        
        setupInlineAIModule()
    }
    
    private func setupInlineAIModule() {
        view.addSubview(inlineAIViewController.view)
        inlineAIViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        inlineAIViewController.inlineUIStatusCallBack = { [weak self] data in
            guard let self = self , let data = data else { return }
            switch data.status {
            case .unknown:
                self.updateNavigationItemStatus(leftEnable: data.leftNavEnable, rightEnable: data.rightNavEnable)
            default:
                self.updateNavigationItemStatus(leftEnable: false, rightEnable: false)
                break
            }
        }

        rootView.aiTaskStatusGetter = { [weak self] (needConfirm) -> AiTaskStatus in
            return self?.inlineAIViewController.getAITaskStatusByNeedConfirm(needConfirm: needConfirm) ?? .unknown
        }

        rootView.tapBlockFrameGetter = { [weak self] (type) -> CGRect? in
            switch type {
            case .attendee:
                if self?.viewModel.eventModel?.rxModel?.value.aiStyleInfo.attendee.isEmpty ?? true {
                    return nil
                }
            default: break
            }
            return self?.getCurrentRectOfView(type: type)
        }
    }

    private func setupWebinarFooterView() {
        if viewModel.input.isWebinarScene {
            rootView.addSubview(webinarFooterLabel)
            webinarFooterLabel.isHidden = true
            webinarFooterLabel.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalTo(moduleContainerView.snp.bottom).offset(14)
                if Display.pad {
                    make.bottom.equalToSuperview().offset(-20)
                } else {
                    make.bottom.equalToSuperview().offset(-view.safeAreaInsets.bottom)
                }
            }
            viewModel.rxWebinarFooterLabelData.subscribeForUI { [weak self] text in
                self?.webinarFooterLabel.isHidden = text.isNil
                self?.webinarFooterLabel.text = text
            }.disposed(by: disposeBag)
        }
    }

    @objc
    func hideKeyboard() {
        view.endEditing(true)
    }
        
    // 停止拖拽
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            tryToShowSwitchingCalendarGuide(scrollView: scrollView)
        }
    }
    
    // 开始减速
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        tryToShowSwitchingCalendarGuide(scrollView: scrollView)
    }

    // 尝试去展示切换日历引导
    private func tryToShowSwitchingCalendarGuide(scrollView: UIScrollView) {
        if !isShowSwitchingCalendarGuide, scrollView.frame.height + scrollView.contentOffset.y > calendarView.frame.maxY {
            self.isShowSwitchingCalendarGuide = !showGuideForSwitchingCalendar()
        }
    }

    private func setupNaviItem() {
        self.navigationController?.isNavigationBarHidden = false
        let cancelItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Cancel)
        cancelItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                self?.hideKeyboard()
                self?.handleClosingClick()
                self?.clearNoUseZoomMeetingIfNeeded(true)
            }.disposed(by: disposeBag)
        navigationItem.leftBarButtonItem = cancelItem

        let doneItem = LKBarButtonItem(title: BundleI18n.Calendar.Calendar_Common_Save, fontStyle: .medium)
        doneItem.button.tintColor = UIColor.ud.primaryContentDefault
        doneItem.button.rx.controlEvent(.touchUpInside)
            .bind { [weak self] in
                guard let enable = self?.navigationItem.rightBarButtonItem?.isEnabled,
                      enable else {
                    return
                }
                self?.hideKeyboard()
                self?.handleSavingClick()
                self?.clearNoUseZoomMeetingIfNeeded(false)
            }
            .disposed(by: disposeBag)
        navigationItem.rightBarButtonItem = doneItem
        if let title = viewModel.title {
            self.title = title
        }
    }

    private func setupViewModel() {
        viewModel.docsDataGetter = { [weak notesView] in
            return Observable<(data: String, plainText: String)>.create { [weak notesView] s in
                notesView?.docsViewHolder.getDocData { [weak notesView] (data, error) in
                    if let error = error {
                        s.onError(error)
                        return
                    }
                    notesView?.docsViewHolder.getPainText { (plainText, error) in
                        if let error = error {
                            s.onError(error)
                            return
                        }
                        var (onData, onPlainText) = ("", "")
                        if let plainText = plainText, !plainText.isEmpty {
                            onData = data ?? ""
                            onPlainText = plainText
                        }
                        s.onNext((onData, onPlainText))
                        s.onCompleted()
                    }
                }
                return Disposables.create()
            }
        }
        viewModel.htmlDataGetter = { [weak self] in
            return Observable<String>.create { [weak self] s in
                self?.notesView?.docsViewHolder.getDocHtml { (htmlText, error) in
                    if let error = error {
                        s.onError(error)
                        return
                    }
                    s.onNext(htmlText ?? "")
                    s.onCompleted()
                }
                return Disposables.create()
            }
        }

        viewModel.rxHasGetCalendar.subscribeForUI(onNext: { [weak self] result in
            guard result else { return }
            guard let self = self else { return }
            let confirmVC = LarkAlertController()
            confirmVC.setContent(text: I18n.Calendar_Toast_CalError)
            confirmVC.addPrimaryButton(text: I18n.Calendar_Common_Confirm, dismissCompletion: {
                self.delegate?.didCancelEdit(from: self)
            })
            self.present(confirmVC, animated: true)
        }).disposed(by: disposeBag)

        if case .copyWithEvent = viewModel.input {
            viewModel.attendeeModel?.rxAlertMessage
                .subscribeForUI(onNext: { [weak self] alert in
                    guard let self = self,
                          let alert = alert else { return }
                    let confirmVC = LarkAlertController()
                    confirmVC.setTitle(text: alert.title)
                    confirmVC.setContent(text: alert.message)
                    confirmVC.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Copy_SomeGuestsNotInDuplicateEvent_OkButton)
                    self.present(confirmVC, animated: true)
                }).disposed(by: disposeBag)
            viewModel.attendeeModel?.rxPullAllAttendeeStatus
                .subscribeForUI { [weak self] status in
                    guard let self = self else { return }
                    if case .failed = status {
                        self.handleErrorToast(I18n.Calendar_Edit_FindTimeFailed)
                    }
                }.disposed(by: disposeBag)
        }

        viewModel.attendeeModel?.rxAddAttendeeMessage
            .subscribeForUI(onNext: { [weak self] message in
                guard let self = self, let message = message else { return }
                switch message {
                case .warningToast(let warning):
                    self.handleWarningToast(warning)
                case .errorToast(let error):
                    self.handleErrorToast(error)
                case .tipsToast(let msg):
                    self.handleTipsToast(msg)
                default:
                    return
                }
            }).disposed(by: disposeBag)
    }

    private func bindView() {
        // bind view data && action
        EventEditLegoInfo.LegoID.allCases.filter(shouldShow(id:)).forEach(bindView(with:))

        // Saving Button (Navi Right BarItem)
        viewModel.savingModel?.rxModel?.subscribeForUI { [weak self] savingStatus in
            guard let savingItem = self?.navigationItem.rightBarButtonItem as? LKBarButtonItem else {
                return
            }
            let (tintColor, isEnabled): (UIColor, Bool)
            switch savingStatus {
            case .disabled: (tintColor, isEnabled) = (UIColor.ud.textDisabled, false)
            case .enabled: (tintColor, isEnabled) = (UIColor.ud.primaryContentDefault, true)
            case .alert: (tintColor, isEnabled) = (UIColor.ud.primaryFillSolid03, true)
            }
            savingItem.button.tintColor = tintColor

            // 记录本应的ItemStatus
            self?.inlineAIViewController.updateSaveItemEnableStatus(isRightEnable: isEnabled)

            if self?.inlineAIViewController.getAITaskStatusByNeedConfirm(needConfirm: false) != .unknown {
                savingItem.isEnabled = false
            } else {
                savingItem.isEnabled = isEnabled
            }
        }.disposed(by: disposeBag)

    }

    // MARK: View Data && Action for Modules View

    private func bindView(with legoID: EventEditLegoInfo.LegoID) {
        switch legoID {
        case .summary: bindSummaryView()
        case .webinarAttendee: bindWebinarAttendeeView()
        case .attendee: bindAttendeeView()
        case .guestPermission: bindGuestPermissionView()
        case .arrangeDate: bindArrangeDateView()
        case .datePicker: bindPickDateView()
        case .timeZone: bindTimeZoneView()
        case .videoMeeting: bindVideoMeetingView()
        case .calendar: bindCalendarView()
        case .color: bindColorView()
        case .visibility: bindVisibilityView()
        case .freebusy: bindFreeBusyView()
        case .reminder: bindReminderView()
        case .meetingRoom: bindMeetingRoomView()
        case .location: bindLoactionView()
        case .checkIn: bindCheckInView()
        case .rrule: bindRruleView()
        case .description: bindNotesView()
        case .attachment: bindAttachmentView()
        case .meetingNotes: bindMeetingNotesView()
        case .delete: bindDeleteView()
        case .larkVideoMeetingSetting: return
        case .unknown: return
        }
    }

    private func bindSummaryView() {
        guard shouldShow(id: .summary) else { return }
        viewModel.rxSummaryViewData.bind(to: summaryView).disposed(by: disposeBag)
        summaryView.textView.rx.text.orEmpty.changed
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .bind { [weak self] text in
                self?.viewModel.updateSummary(text)
            }
            .disposed(by: disposeBag)
        
        summaryView.inlineClickHandler = {[weak self] in
            guard let self = self else { return }
            self.inlineAIViewController.inlineAIClickHandler()
            self.inlineAIViewController.updateSaveItemEnableStatus(inlineNavItemStatus: InlineNavItemStatus(status: .initial,
                                                                                                           leftNavEnable: self.navigationItem.leftBarButtonItem?.isEnabled,
                                                                                                           rightNavEnable: self.navigationItem.rightBarButtonItem?.isEnabled))
            updateNavigationItemStatus(leftEnable: false, rightEnable: false)
            self.viewModel.calendarMyAIService?.activeBleScanForEdit(fromVC: self.inlineAIViewController,
                                                                     canPopDialogCallBack: { [weak self] in
                return self?.inlineAIViewController.getAITaskStatusByNeedConfirm(needConfirm: false) == .initial
            })
        }
    }

    private func bindWebinarAttendeeView() {
        guard shouldShow(id: .webinarAttendee) else { return }
        viewModel.rxSpeakerViewData.bind(to: webinarSpeakerView).disposed(by: disposeBag)
        viewModel.rxAudienceViewData.bind(to: webinarAudienceView).disposed(by: disposeBag)
        let actionWhenMustHaveAllAttendee = { [unowned self] (type: WebinarAttendeeType, action: @escaping () -> Void) in
            self.hideKeyboard()
            guard let attendeeContext = self.viewModel.webinarAttendeeModel?.getAttendeeContext(with: type) else {
                return
            }
            if attendeeContext.haveAllAttendee {
                // 已经有全量参与人，直接进
                action()
            } else {
                // 加载成功与否都允许用户进入
                UDToast.showLoading(with: BundleI18n.Calendar.Calendar_Common_LoadAndWait,
                                    on: self.view,
                                    disableUserInteraction: true)
                attendeeContext.waitAllAttendees(onSuccess: { [weak self] in
                    guard let self = self else { return }
                    action()
                    UDToast.removeToast(on: self.view)
                }, onFailure: { [weak self] in
                    guard let self = self else { return }
                    action()
                    UDToast.removeToast(on: self.view)
                })
            }

        }
        webinarSpeakerView.clickHandler = { [unowned self] in
            actionWhenMustHaveAllAttendee(.speaker, { [weak self] in
                guard let self = self else { return }
                self.delegate?.listWebinarAttendee(from: self, type: .speaker)
            })
        }
        webinarSpeakerView.addHandler = { [unowned self] in
            actionWhenMustHaveAllAttendee(.speaker, { [weak self] in
                guard let self = self else { return }
                self.delegate?.addWebinarAttendee(from: self, type: .speaker)
            })
        }
        webinarAudienceView.clickHandler = { [unowned self] in
            actionWhenMustHaveAllAttendee(.speaker, { [weak self] in
                guard let self = self else { return }
                self.delegate?.listWebinarAttendee(from: self, type: .audience)
            })
        }
        webinarAudienceView.addHandler = { [unowned self] in
            actionWhenMustHaveAllAttendee(.speaker, { [weak self] in
                guard let self = self else { return }
                self.delegate?.addWebinarAttendee(from: self, type: .audience)
            })
        }
    }

    private func bindAttendeeView() {
        guard shouldShow(id: .attendee) else { return }
        viewModel.rxAttendeeViewData.bind(to: attendeeView).disposed(by: disposeBag)
        attendeeView.clickHandler = { [unowned self] in
            self.hideKeyboard()
            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click("view_attendee").target("cal_event_attendee_list_view")
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.viewModel.eventModel?.rxModel?.value.getPBModel(),
                                                                       startTime: Int64(self.viewModel.eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
            }
            let actionWhenMustHaveAllAttendee = {
                self.delegate?.listAttendee(from: self)
                self.inlineAIViewController.hideInlineAIPanel()
                Tracer.shared.calShowAttendeeList(actionSource: .edit)
            }
            if viewModel.hasAllAttendee {
                // 已经有全量参与人，直接进
                actionWhenMustHaveAllAttendee()
            } else {
                // 加载成功与否都允许用户进入
                UDToast.showLoading(with: BundleI18n.Calendar.Calendar_Common_LoadAndWait,
                                    on: self.view,
                                    disableUserInteraction: true)
                viewModel.waitAttendeesLoading(onSuccess: { [weak self] in
                    guard let self = self else { return }
                    actionWhenMustHaveAllAttendee()
                    UDToast.removeToast(on: self.view)
                }, onFailure: { [weak self] in
                    guard let self = self else { return }
                    actionWhenMustHaveAllAttendee()
                    UDToast.removeToast(on: self.view)
                })
            }
        }

        attendeeView.addHandler = { [unowned self] in
            self.hideKeyboard()
            let actionWhenMustHaveAllAttendee = {
                self.delegate?.addAttendee(from: self)
            }
            if viewModel.hasAllAttendee {
                // 已经有全量参与人，直接进
                actionWhenMustHaveAllAttendee()
            } else {
                // 加载成功与否都允许用户进入
                UDToast.showLoading(with: BundleI18n.Calendar.Calendar_Common_LoadAndWait,
                                    on: self.view,
                                    disableUserInteraction: true)
                viewModel.waitAttendeesLoading(onSuccess: { [weak self] in
                    guard let self = self else { return }
                    actionWhenMustHaveAllAttendee()
                    UDToast.removeToast(on: self.view)
                }, onFailure: { [weak self] in
                    guard let self = self else { return }
                    actionWhenMustHaveAllAttendee()
                    UDToast.removeToast(on: self.view)
                })
            }
        }
    }

    private func bindGuestPermissionView() {
        guard shouldShow(id: .guestPermission) else { return }
        viewModel.rxGuestPermissionViewData.bind(to: guestPermissionView).disposed(by: disposeBag)

        guestPermissionView.onClick = { [unowned self] in
            self.hideKeyboard()
            self.delegate?.selectGuestPermission(from: self)
        }
    }

    private func bindArrangeDateView() {
        guard shouldShow(id: .arrangeDate) else { return }
        viewModel.rxArrangeDateViewData.bind(to: arrangeDateView).disposed(by: disposeBag)
        arrangeDateView.clickHandler = { [unowned self] in
            self.hideKeyboard()
            self.delegate?.arrangeDate(from: self)

            guard let eventModel = self.viewModel.eventModel?.rxModel?.value else { return }
            let meetingRoomCount = eventModel.meetingRooms.count
            let groupCount = eventModel.attendees.filter {
                guard case .group = $0 else { return false }
                return true
            }.count
            let userCount = eventModel.attendees.filter {
                guard case .user = $0 else { return false }
                return true
            }.count
            Tracer.shared.enterFreeBusy(
                meetingRoomCount: meetingRoomCount,
                actionSource: .fullEventEditor,
                groupCount: groupCount,
                userCount: userCount
            )
            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click("manage_time")
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.viewModel.eventModel?.rxModel?.value.getPBModel(),
                                                                       startTime: Int64(self.viewModel.eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
            }
        }
    }

    private func bindPickDateView() {
        guard shouldShow(id: .datePicker) else { return }
        viewModel.rxPickDateViewData.bind(to: pickDateView).disposed(by: disposeBag)
        let pickDateViewClickInDisable = { [unowned self] in
            guard let event = self.viewModel.eventModel?.rxModel?.value,
                  let meetingRooms = self.viewModel.meetingRoomModel?.rxMeetingRooms.value else { return }
            let isEditable = event.getPBModel().isEditable
            let duration = Int64(event.endDate.timeIntervalSince(event.startDate))
            let haveApprovalMeetingRoom = meetingRooms.hasFullApprovalMeetingRoom() || meetingRooms.hasConditionApprovalMeetingRoom(duration: duration)
            // 有完全编辑权限 && 有需要审批的会议室 && 有rrule，则不可编辑 date
            if isEditable && haveApprovalMeetingRoom && event.rrule != nil {
                self.showConfirmAlertController(
                    title: I18n.Calendar_Rooms_EventTimeNoChangeSwitchRoom,
                    message: nil,
                    confirmText: I18n.Calendar_Common_GotIt,
                    cancelText: nil,
                    confirmHandler: nil,
                    cancelHandler: nil
                )
            }
        }
        pickDateView.startClickHandler = { [unowned self] in
            self.hideKeyboard()
            let isClickable = self.pickDateView.viewData?.isClickable ?? false
            if isClickable {
                self.delegate?.pickDate(from: self, selectStart: true)
                Tracer.shared.calClickDatePickerOnEditPage()
            } else {
                pickDateViewClickInDisable()
            }
        }
        pickDateView.endClickHandler = { [unowned self] in
            self.hideKeyboard()
            let isClickable = self.pickDateView.viewData?.isClickable ?? false
            if isClickable {
                self.delegate?.pickDate(from: self, selectStart: false)
                Tracer.shared.calClickDatePickerOnEditPage()
            } else {
                pickDateViewClickInDisable()
            }
        }
    }

    private func bindTimeZoneView() {
        guard shouldShow(id: .timeZone) else { return }
        viewModel.rxTimeZoneViewData.bind(to: timeZoneView).disposed(by: disposeBag)

        timeZoneView.clickHandler = { [unowned self] in
            self.hideKeyboard()
            self.delegate?.pickDate(from: self, selectStart: true)
            Tracer.shared.calClickDatePickerOnEditPage()
        }
        let originEvent = self.viewModel.originalEvent
        timeZoneView.invalidWarningDisplayCallback = {
            CalendarTracerV2.EventCreateDifferentTimezone.traceView() {
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: originEvent?.getPBModel(),
                                                                       startTime: Int64(originEvent?.startDate.timeIntervalSince1970 ?? 0)))
            }
        }
    }

    private func bindCalendarView() {
        guard shouldShow(id: .calendar) else { return }
        viewModel.rxCalendarViewData.bind(to: calendarView).disposed(by: disposeBag)
        calendarView.clickHandler = { [unowned self] in
            self.hideKeyboard()
            if case .editWebinar = self.viewModel.input {
                UDToast.showTips(with: I18n.Calendar_G_AttibuteNoChange, on: self.view)
                return
            }
            self.delegate?.selectCalendar(from: self)
        }
    }

    private func bindColorView() {
        guard shouldShow(id: .color) else { return }
        viewModel.rxColorViewData.bind(to: colorView).disposed(by: disposeBag)
        colorView.clickHandler = { [unowned self] in
            let canEdit = viewModel.permissionModel?.rxPermissions.value.color.isEditable ?? false
            if !canEdit {
                let isTentative = viewModel.eventModel?.rxModel?.value.getPBModel().selfAttendeeStatus == .needsAction
                let isLark = viewModel.eventModel?.rxModel?.value.calendar?.source == .lark
                if isLark && isTentative {
                    UDToast.showTips(with: I18n.Calendar_G_WhetherAttendFirst, on: self.view)
                }
                return
            }
            self.hideKeyboard()
            self.delegate?.selectColor(from: self)
        }
    }

    // MARK: View Action For Closing
    private func handleClosingClick() {
        Tracer.shared.calEditClose(
            editType: self.viewModel.input.isFromCreating ? .new : .edit
        )
        let traceViewParam = CalendarTracerV2.EventCreateCancelConfirm.ViewParams()
        guard let (alertTitle, alertTip) = viewModel.alertTipForClosing(trace: traceViewParam) else {
            self.delegate?.didCancelEdit(from: self)
            return
        }

        let alertTexts = EventEditConfirmAlertTexts(title: alertTitle,
                                                    message: alertTip,
                                                    confirmText: I18n.Calendar_CreateEvent_DiscardChangesAndLeave_LeaveButton,
                                                    cancelText: I18n.Calendar_Detail_BackToEdit)
        let alertContext = EventEditConfirmAlert(
            texts: alertTexts,
            confirmHandler: { [weak self] in
                guard let self = self else { return }
                self.viewModel.meetingNotesModel?.deleteMeetingNotes(.cancelEdit)
                self.delegate?.didCancelEdit(from: self)
                CalendarTracerV2.EventCreateCancelConfirm.traceClick(commonParam: self.commonParamData) {
                    $0.click("discard")
                    $0.will_delete_notes = traceViewParam.will_delete_notes
                }
            },
            cancelHandler: { [weak self] in
                guard let self = self else { return }
                EventEdit.logger.info("cancel close EventEditViewController")
                CalendarTracerV2.EventCreateCancelConfirm.traceClick(commonParam: self.commonParamData) {
                    $0.click("back_to_edit")
                    $0.will_delete_notes = traceViewParam.will_delete_notes
                }
            }
        )
        showConfirmAlertController(alertContext)
        CalendarTracerV2.EventCreateCancelConfirm.traceView(commonParam: commonParamData) {
            $0.will_delete_notes = traceViewParam.will_delete_notes
        }
    }

    private func bindVideoMeetingView() {
        guard shouldShow(id: .videoMeeting) else { return }
        viewModel.rxVideoMeetingViewData.bind(to: videoMeetingView).disposed(by: disposeBag)
        videoMeetingView.videoMeetingClickHandler = { [weak self] (editable) in
            guard let self = self else { return }
            if editable {
                self.hideKeyboard()
                self.delegate?.selectVideoMeeting(from: self)
                CalendarTracerV2.EventFullCreate.traceClick {
                    $0.click("lark_meeting").target("cal_vc_setting_view")
                    $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.viewModel.eventModel?.rxModel?.value.getPBModel(),
                                                                           startTime: Int64(self.viewModel.eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
                }

            } else if self.viewModel.eventModel?.rxModel?.value.videoMeeting.videoMeetingType == .googleVideoConference {
                UDToast.showTips(with: BundleI18n.Calendar.Calendar_Google_UnableToEditMeetings, on: self.view)
            } else if self.viewModel.eventModel?.rxModel?.value.videoMeeting.videoMeetingType == .unknownVideoMeetingType {
                UDToast.showTips(with: BundleI18n.Calendar.Calendar_Edit_CantEditUpgradeToast, on: self.view)
            }
        }

        videoMeetingView.settingClickHandler = { [weak self] isEditable in
            guard let self = self,
                  let event = self.viewModel.eventModel?.rxModel?.value.getPBModel() else { return }

            let videoMeeting = self.viewModel.getVideoMeeting()

            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click("edit_vc_setting").target("vc_meeting_pre_setting_view")
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.viewModel.eventModel?.rxModel?.value.getPBModel(),
                                                                       startTime: Int64(self.viewModel.eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
            }

            // zoom会议 编辑权限 单独判断
            if videoMeeting?.videoMeetingType == .zoomVideoMeeting {
                self.viewModel.localZoomConfigs = videoMeeting?.zoomConfigs
                if let isEditable = videoMeeting?.zoomConfigs.isEditable, isEditable == true && FG.shouldEnableZoom {} else {
                    UDToast.showTips(with: I18n.Calendar_Zoom_NoEditPermit, on: self.view)
                    return
                }
            }

            let isVideoMeetingLiving = self.viewModel.permissionModel?.rxModel?.value.isVideoMeetingLiving ?? false // 会议是否正在进行
            let isOriginalEditable = self.viewModel.permissionModel?.rxModel?.value.event.isEditable ?? false // 是否有完全编辑权限
            if !isEditable {
                if isVideoMeetingLiving && isOriginalEditable {
                    UDToast.showTips(with: I18n.Calendar_Edit_MeetingCantChange, on: self.view)
                }
                return
            }

            if videoMeeting?.videoMeetingType == .zoomVideoMeeting {
                let viewModel = ZoomDefaultSettingViewModel(meetingID: videoMeeting?.zoomConfigs.meetingID ?? 0, userResolver: self.userResolver)
                let vc = ZoomDefaultSettingController(viewModel: viewModel, userResolver: self.userResolver)

                viewModel.onSaveCallBack = {[weak self]  (meetingNo, password, meetingUrl) in
                    guard let self = self else { return }
                    if var videoMeeting = videoMeeting {
                        videoMeeting.zoomConfigs.meetingNo = meetingNo
                        videoMeeting.zoomConfigs.password = password
                        videoMeeting.zoomConfigs.meetingURL = meetingUrl
                        videoMeeting.meetingURL = meetingUrl
                        self.viewModel.updateVideoMeeting(videoMeeting)
                    }
                    UDToast.showTips(with: I18n.Calendar_Zoom_MeetInfoUpdated, on: self.view)
                }

                let nav = LkNavigationController(rootViewController: vc)
                if Display.pad {
                    nav.modalPresentationStyle = .formSheet
                }
                self.userResolver.navigator.present(nav, from: self)
            } else {
                let uniqueId = videoMeeting?.uniqueID
                var vcSettingId: String? = videoMeeting?.larkVcBindingData.vcSettingID
                vcSettingId = vcSettingId.isEmpty ? nil : vcSettingId

                CalendarTracerV2.EventFullCreate.traceClick {
                    $0.click("edit_vc_setting").target("vc_meeting_pre_setting_view")
                }

                if let uniqueId = uniqueId, !uniqueId.isEmpty {
                    let instanceDetails = CalendarInstanceDetails(uniqueID: uniqueId,
                                                                  key: event.key,
                                                                  originalTime: event.originalTime,
                                                                  instanceStartTime: event.startTime,
                                                                  instanceEndTime: event.endTime)
                    self.calendarDependency?.showVideoMeetingSetting(instanceDetails: instanceDetails, from: self)
                } else {
                    self.calendarDependency?.jumpToCreateVideoMeeting(
                        vcSettingId: vcSettingId,
                        from: self) { [weak self] response, error in
                            guard let self = self else { return }
                            guard error == nil else {
                                UDToast.showFailure(with: I18n.Calendar_Toast_FailedToLoad, on: self.view)
                                return
                            }

                            if let res = response, var videoMeeting = videoMeeting {
                                videoMeeting.larkVcBindingData.vcSettingID = res.vcSettingId
                                self.viewModel.updateVideoMeeting(videoMeeting)
                            }
                    }
                }
            }
        }
    }

    private func bindVisibilityView() {
        guard shouldShow(id: .visibility) else { return }
        viewModel.rxVisibilityViewData.bind(to: visibilityView).disposed(by: disposeBag)
        visibilityView.clickHandler = { [unowned self] in
            self.hideKeyboard()
            self.delegate?.selectVisibility(from: self)
        }
    }

    private func bindFreeBusyView() {
        guard shouldShow(id: .freebusy) else { return }
        viewModel.rxFreeBusyViewData.bind(to: freeBusyView).disposed(by: disposeBag)
        freeBusyView.clickHandler = { [unowned self] in
            self.hideKeyboard()
            self.delegate?.selectFreeBusy(from: self)
        }
    }

    private func bindMeetingRoomView() {
        guard shouldShow(id: .meetingRoom) else { return }
        viewModel.rxMeetingRoomViewData.bind(to: meetingRoomView).disposed(by: disposeBag)
        meetingRoomView.addRoomClickHandler = { [unowned self] in
            self.hideKeyboard()
            self.delegate?.selectMeetingRoom(from: self)
        }
        let itemDeleteHandler = { [unowned self] (index: Int) in
            self.hideKeyboard()
            if let alertTexts = self.viewModel.confirmAlertTextsForDeletingVisibleMeetingRoom(at: index) {
                self.showConfirmAlertController(
                    texts: alertTexts,
                    confirmHandler: { [weak self] in
                        self?.viewModel.deleteMeetingRoom(at: index)
                    }
                )
            } else {
                self.viewModel.deleteMeetingRoom(at: index)
            }
            CalendarTracerV2.EventFullCreate.traceClick {
                $0.click("delete_resource")
                $0.is_new_create = (editType == .new) ? "true" : "false"
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.viewModel.eventModel?.rxModel?.value.getPBModel(),
                                                                       startTime: Int64(self.viewModel.eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)))
            }
        }
        meetingRoomView.itemDeleteHandler = itemDeleteHandler

        let itemFormClickHandler = { [weak self] (index: Int) in
            guard let self = self else { return }
            guard let originalCustomization = self.viewModel.meetingRoomForm(index: index) else {
                assertionFailure()
                return
            }

            let formViewController = MeetingRoomFormViewController(resourceCustomization: originalCustomization, userResolver: self.userResolver)
            formViewController.cancelSignal
                .subscribe(onNext: { [weak formViewController] in
                    formViewController?.navigationController?.popViewController(animated: true)
                    CalendarTracer.shared.formComplete(action: .cancel, nextPage: .eventDetail)
                })
                .disposed(by: self.disposeBag)
            formViewController.confirmSignal
                .subscribe(onNext: { [weak self] custom in
                    guard let self = self else { return }
                    self.navigationController?.popViewController(animated: true)
                    self.viewModel.meetingRoomUpdateForm(index: index, newForm: custom)
                    CalendarTracer.shared.formComplete(action: .confirm, nextPage: .eventDetail)
                })
                .disposed(by: self.disposeBag)
            self.show(formViewController, sender: self)
            CalendarTracer.shared.enterFormViewController(source: .editMeetingInfo)
        }
        meetingRoomView.itemFormClickHandler = itemFormClickHandler

        let itemClickHandler = { [unowned self] (index: Int) in
            CalendarTracer.shared.calClickMeetingRoomInfo(from: .fullEventEditor, with: .edit)
            self.hideKeyboard()
            let meetingRoom = self.viewModel.meetingRoomModel?.visibleMeetingRoom(at: index)
            // 跳转会议室详情页
            var context = DetailWithStatusContext()
            guard let calendarID = meetingRoom?.uniqueId else {
                assertionFailure("选中会议室没有 uniqueId")
                return
            }
            context.calendarID = calendarID
            context.startTime = self.viewModel.rxPickDateViewData.value.startDate
            context.endTime = self.viewModel.rxPickDateViewData.value.endDate
            context.timeZone = self.viewModel.rxPickDateViewData.value.timeZone.identifier
            let eventModel = self.viewModel.eventModel?.rxModel?.value
            context.rrule = eventModel?.rrule?.iCalendarString() ?? ""
            // 只有当key不为空才去通过日程三元组鉴权
            context.eventUniqueFields = eventModel?.getPBModel().key.isEmpty == false ?  getEventUniqueFields() : nil
            let input: MeetingRoomDetailInput = .detailWithStatus(context)
            let viewModel = MeetingRoomDetailViewModel(input: input, userResolver: self.userResolver)
            let toVC = MeetingRoomDetailViewController(viewModel: viewModel, userResolver: self.userResolver)
            navigationController?.pushViewController(toVC, animated: true)
        }
        meetingRoomView.itemClickHandler = itemClickHandler

        meetingRoomView.showAllRoomsClickHandler = { [weak self] in
            guard let self = self else { return }

            let vm = SelectedMeetingRoomViewModel(contents: .edit(self.viewModel.rxMeetingRoomViewData,
                                                                  SelectedMeetingRoomViewModel.PassThroughAction(itemDeleteHandler: itemDeleteHandler,
                                                                                                                 itemFormHandler: itemFormClickHandler,
                                                                                                                 itemClickHandler: itemClickHandler)))
            let vc = SelectedMeetingRoomViewController(viewModel: vm, userResolver: self.userResolver)
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    // 获取日程三元组信息，用于跨租户鉴权
    private func getEventUniqueFields() -> CalendarEventUniqueField? {
        guard let eventPBModel = self.viewModel.eventModel?.rxModel?.value.getPBModel() else {
            assertionFailure("lose eventPBModel")
            EventEdit.logger.info("lose eventPBModel")
            return nil
        }
        var eventUniqueFields = CalendarEventUniqueField()
        eventUniqueFields.calendarID = eventPBModel.calendarID
        eventUniqueFields.originalTime = eventPBModel.originalTime
        eventUniqueFields.key = eventPBModel.key
        return eventUniqueFields
    }

    private func bindLoactionView() {
        guard shouldShow(id: .location) else { return }
        viewModel.rxLocationViewData.bind(to: locationView).disposed(by: disposeBag)
        locationView.clickHandler = { [unowned self] in
            self.hideKeyboard()
            self.delegate?.selectLocation(from: self)
        }
        locationView.deleteHandler = { [unowned self] in
            self.hideKeyboard()
            self.viewModel.updateLocation(nil)
        }
    }

    private func bindCheckInView() {
        guard shouldShow(id: .checkIn) else { return }
        viewModel.rxCheckInViewData.bind(to: checkInView).disposed(by: disposeBag)
        let clickHandler = { [weak self] in
            guard let self = self else { return }
            self.hideKeyboard()
            self.delegate?.selectCheckIn(from: self)
        }
        checkInView.clickHandler = clickHandler
        checkInView.nextHandler = clickHandler
    }

    private func bindRruleView() {
        guard shouldShow(id: .rrule) else { return }
        viewModel.rxRruleViewData.bind(to: rruleView).disposed(by: disposeBag)
        rruleView.warningViewShowHandler = { [weak self] in
            CalendarTracerV2.UtiltimeAdjustRemind.traceView {
                $0.location = CalendarTracerV2.AdjustRemindLocation.editEventView.rawValue
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: self?.viewModel.eventModel?.rxModel?.value.getPBModel()))
            }
        }
        let rruleViewClickInDisable: (_ notEditReason: EventEditViewModel.NotEditReason) -> Void = { [unowned self] notEditReason in
            guard let event = self.viewModel.eventModel?.rxModel?.value,
                  let meetingRooms = self.viewModel.meetingRoomModel?.rxMeetingRooms.value else { return }
            let isEditable = event.getPBModel().isEditable
            let duration = Int64(event.endDate.timeIntervalSince(event.startDate))
            let haveApprovalMeetingRoom = meetingRooms.hasFullApprovalMeetingRoom() || meetingRooms.hasConditionApprovalMeetingRoom(duration: duration)
            // 有完全编辑权限 && 有需要审批的会议室 && 有rrule，则不可编辑 rrule
            if isEditable && haveApprovalMeetingRoom && event.rrule != nil {
                self.showConfirmAlertController(
                    title: I18n.Calendar_Rooms_RuleNoChangeSwitchRoom,
                    message: nil,
                    confirmText: I18n.Calendar_Common_GotIt,
                    cancelText: nil,
                    confirmHandler: nil,
                    cancelHandler: nil
                )
                return
            }
            switch notEditReason {
            // 有需要审批的会议室，弹不能编辑rrule
            case .meetingRoomApproval:
                UDToast.showTips(with: I18n.Calendar_Approval_RecurToast, on: self.view)
            // 日程参与者超过x人不支持转为重复性日程
            case .fullEventNoConvertRecur(let count):
                UDToast.showTips(with: I18n.Calendar_G_FullEventNoConvertRecur(number: count), on: self.view)
            case .none:
                break
            }
        }
        rruleView.ruleClickHandler = { [unowned self] in
            self.hideKeyboard()
            let isClickable = self.rruleView.viewData?.isRuleEditable ?? false
            let notEditReason = self.rruleView.viewData?.notEditReason ?? .none
            if isClickable {
                self.delegate?.selectRrule(from: self)
            } else {
                rruleViewClickInDisable(notEditReason)
            }
        }
        rruleView.ruleDeleteHandler = { [unowned self] in
            self.hideKeyboard()
            let isClickable = self.rruleView.viewData?.isRuleEditable ?? false
            let notEditReason = self.rruleView.viewData?.notEditReason ?? .none
            if isClickable {
                self.delegate?.selectRrule(from: self)
            } else {
                rruleViewClickInDisable(notEditReason)
            }
        }
        rruleView.endDateClickHandler = { [unowned self] in
            self.hideKeyboard()
            let isClickable = self.rruleView.viewData?.isEndDateEditable ?? false
            let notEditReason = self.rruleView.viewData?.notEditReason ?? .none
            if isClickable {
                self.delegate?.selectRruleEndDate(from: self)
            } else {
                rruleViewClickInDisable(notEditReason)
            }
        }
        rruleView.adjustEndDateClickHandler = { [unowned self] in
            self.hideKeyboard()
            let isClickable = self.rruleView.viewData?.isTipClickable ?? false
            let notEditReason = self.rruleView.viewData?.notEditReason ?? .none
            if isClickable {
                self.viewModel.adjustRruleEndDate()
                if FG.calendarRoomsReservationTime {
                    self.viewModel.needRenewalReminder = true
                    CalendarTracerV2.UtiltimeAdjustRemind.traceClick() {
                        $0.click("adjust")
                        $0.location = CalendarTracerV2.AdjustRemindLocation.editEventView.rawValue
                        $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.viewModel.eventModel?.rxModel?.value.getPBModel()))
                    }
                    // 展示toast
                    let timezone = TimeZone(identifier: self.viewModel.rxPickDateViewData.value.timeZone.identifier) ?? .current
                    let customOptions = Options(
                        timeZone: timezone,
                        timeFormatType: .long,
                        datePrecisionType: .day
                    )
                    let dateDesc = TimeFormatUtils.formatDate(from: viewModel.meetingRoomMaxEndDateInfo()?.furthestDate ?? Date(), with: customOptions)
                    UDToast.showTips(with: I18n.Calendar_G_AvailabilitySuggestion_TimeChanged_Popup(eventEndTime: dateDesc), on: self.view,
                        delay: 5.0)
                }
            } else {
                rruleViewClickInDisable(notEditReason)
            }
        }
    }

    private func bindReminderView() {
        guard shouldShow(id: .reminder) else { return }
        viewModel.rxReminderViewData.bind(to: reminderView).disposed(by: disposeBag)
        let clickHandler = { [weak self] in
            guard let self = self else { return }
            self.hideKeyboard()
            self.delegate?.selectReminder(from: self)
        }
        reminderView.clickHandler = clickHandler
        reminderView.nextHandler = clickHandler
    }

    private func bindAttachmentView() {
        guard shouldShow(id: .attachment) else { return }
        viewModel.rxAttachmentViewData.bind(to: attachmentView).disposed(by: disposeBag)
        attachmentView.itemTappedRelay
            .throttle(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .subscribe(onNext: { [unowned self] clickType in
                self.hideKeyboard()
                switch clickType {
                case .open(let token):
                    self.delegate?.selectAttachment(from: self, withToken: token)
                case .delete(let index):
                    self.delegate?.deleteAttachment(from: self, with: index)
                case .reUpload(let index):
                    self.delegate?.reuploadAttachment(from: self, with: index)
                case .jump(let link):
                    guard let url = URL(string: link) else {
                        EventEdit.logger.error("cannot jump url: \(link)")
                        return
                    }
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                case .url(let link, let token):
                    if !token.isEmpty {
                        self.delegate?.selectAttachment(from: self, withToken: token)
                    } else {
                        guard let url = URL(string: link) else {
                            EventEdit.logger.error("cannot jump url: \(link)")
                            return
                        }
                        self.userResolver.navigator.push(url, from: self)
                    }
                }
            })
            .disposed(by: disposeBag)

        attachmentView.addClickHandler = { [unowned self] in
            self.hideKeyboard()
            guard let attachmentModel = self.viewModel.attachmentModel else { return }
            switch attachmentModel.securityAudit.checkAuth(permType: .fileUpload) {
            case .deny:
                self.showConfirmAlertController(
                    title: I18n.Calendar_Setting_NoAccess,
                    message: I18n.Calendar_Share_AdminSettingCantAddFile,
                    confirmText: I18n.Calendar_Common_GotIt, cancelText: nil,
                    confirmHandler: nil, cancelHandler: nil
                )
            case .error:
                self.showConfirmAlertController(
                    title: I18n.Calendar_Setting_NoAccess,
                    message: I18n.Calendar_G_ChangedPermissionChangedTryLater,
                    confirmText: I18n.Calendar_Common_GotIt, cancelText: nil,
                    confirmHandler: nil, cancelHandler: nil
                )
            default:
                self.delegate?.addAttachment(from: self)
                CalendarTracerV2.EventFullCreate.traceClick {
                    $0.click("upload_attachment")
                    $0.is_new_create = editType == .new ? "true" : "false"
                    $0.mergeEventCommonParams(
                        commonParam: .init(
                            event: self.viewModel.eventModel?.rxModel?.value.getPBModel(),
                            startTime: Int64(self.viewModel.eventModel?.rxModel?.value.startDate.timeIntervalSince1970 ?? 0)
                        )
                    )
                }
            }
        }
    }

    private func bindMeetingNotesView() {
        guard shouldShow(id: .meetingNotes) else { return }
        viewModel.rxMeetingNotesViewData
            .subscribeForUI(onNext: { [weak self] viewData in
                self?.meetingNotesView.viewData = viewData
            }).disposed(by: disposeBag)
        meetingNotesView.delegate = self
        meetingNotesView.deleteHandler = { [unowned self] in
            self.viewModel.deleteMeetingNotes()
            CalendarTracerV2.EventFullCreate.traceClick(commonParam: commonParamData) {
                $0.click("delete_meeting_notes")
            }
        }
    }

    private func bindNotesView() {
        guard shouldShow(id: .description), let notesView = notesView else { return }
        viewModel.rxNotesViewData.bind(to: notesView).disposed(by: disposeBag)
        notesView.clickHandler = { [unowned self] in
            self.hideKeyboard()
            self.delegate?.editNotes(from: self)
        }
        notesView.deleteHandler = { [unowned self] in
            self.hideKeyboard()
            self.viewModel.clearNotes()
        }

    }

    private func bindDeleteView() {
        guard shouldShow(id: .delete) else { return }
        viewModel.rxDeleteViewData.bind(to: deleteView).disposed(by: disposeBag)
        deleteView.clickHandler = { [weak self] in
            self?.handleDelete()
        }
    }
    // MARK: View Action for Saving

    private func handleSavingClick() {
        guard let savingModel = viewModel.savingModel?.rxModel?.value else { return }
        let statusStr: String
        switch savingModel {
        case .enabled:
            ReciableTracer.shared.recStartSaveEvent()
            navigationItem.rightBarButtonItem?.isEnabled = false
            lastSaveDisposable?.dispose()
            lastSaveDisposable = doSave()
            lastSaveDisposable?.disposed(by: disposeBag)
            statusStr = "enabled"
        case .alert(let message):
            let alertTexts = EventEditConfirmAlertTexts(message: message, cancelText: nil)
            showConfirmAlertController(texts: alertTexts)
            statusStr = "alert(\(message))"
        case .disabled:
            statusStr = "disabled"
        }
        EventEdit.logger.info("save button clicked. status: \(statusStr)")
    }

    private func doSave() -> Disposable {
        let view: UIView = userResolver.navigator.mainSceneTopMost?.view ?? self.view
        let source = self.viewModel.input.isFromCreating ? "create" : "edit"
        let isWebinar = self.viewModel.input.isWebinarScene ? 1 : 0
        return viewModel.saveEvent()
            .subscribe(
                onState: { [weak self] saveResult in
                    guard let self = self else { return }
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                    UDToast.removeToast(on: view)
                    switch saveResult {
                    case .pbType(let event, let span):
                        self.delegate?.didFinishSaveEvent(event, span: span, from: self)
                    case .ekType(let event):
                        self.delegate?.didFinishSaveLocalEvent(event, from: self)
                    }
                    ReciableTracer.shared.recEndSaveEvent()
                    SlaMonitor.traceSuccess(.SaveEvent, action: "save", source: source, additionalParam: ["is_webinar": isWebinar])
                },
                onMessage: { [weak self] message in
                    self?.handleSavingMessage(message)
                },
                onTerminate: { [weak self] error in
                    guard let self = self else { return }
                    UDToast.removeToast(on: view)
                    if let saveError = error as? EventEditViewModel.SaveTerminal {
                        switch saveError {
                        case .notChanged:
                            // 没有改变，直接退出
                            self.delegate?.didCancelEdit(from: self)
                        case .backToEdit, .rruleEndDateNotValid, .notSyncAttendee:
                            // 继续编辑
                            break
                        case .switchCalendarFailed:
                            EventEdit.assertionFailure("switch calendar failed", type: .switchCalendarFailed)
                            UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Toast_FailedToTransferEventToCalendar, on: view)
                        case .failedToSave:
                            EventEdit.assertionFailure("save event failed: \(error)", type: .saveFailed)
                            UDToast.showTips(with: BundleI18n.Calendar.Calendar_Edit_SaveFailedTip, on: view)
                            ReciableTracer.shared.recTracerError(errorType: ErrorType.Unknown,
                                                                 scene: Scene.CalEventEdit,
                                                                 event: .saveEvent,
                                                                 userAction: "cal_save_event",
                                                                 page: "cal_event_create",
                                                                 errorCode: Int(error.errorCode() ?? 0),
                                                                 errorMessage: error.getMessage() ?? "")
                        case .incompletedForm(let calendarIDs):
                            self.viewModel.meetingRoomModel?.updateIncompletedForms(IDs: calendarIDs)
                        case .webinarVCSettingNotValid(let reason):
                                UDToast.showTips(with: reason, on: view)
                        case .apiUnavailable:
                            EventEdit.assertionFailure("calendar api is unavailable!")
                        }
                        if let slaError = saveError.tryExtractSlaError() {
                            SlaMonitor.traceFailure(.SaveEvent, error: slaError, action: "save", source: source, additionalParam: ["is_webinar": isWebinar])
                        }
                    } else {
                        let tip = error.getTitle(errorScene: .eventSave)
                            ?? BundleI18n.Calendar.Calendar_Edit_SaveFailedTip
                        UDToast.showTips(with: tip, on: view)
                        ReciableTracer.shared.recTracerError(errorType: ErrorType.Unknown,
                                                             scene: Scene.CalEventEdit,
                                                             event: .saveEvent,
                                                             userAction: "cal_save_event",
                                                             page: "cal_event_create",
                                                             errorCode: Int(error.errorCode() ?? 0),
                                                             errorMessage: error.getMessage() ?? "")
                        SlaMonitor.traceFailure(.SaveEvent, error: error, action: "save", source: source, additionalParam: ["is_webinar": isWebinar])
                    }
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            )
    }

    private func inSecondaryVC() -> Bool {
        return navigationController?.viewControllers.count != 1
    }

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        /// 二级页面不可下滑 dismiss
        if inSecondaryVC() { return false }
        /// 主页面判断是否可以 dismiss
        let eventHasChanged = viewModel.rxEventHasChanged.value
        let meetingNotesHasEdit = viewModel.meetingNotesModel?.notesHasEdit ?? false
        return !(eventHasChanged || meetingNotesHasEdit)
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        /// 二级页面不进行处理
        if inSecondaryVC() { return }

        /// 有 InlineAI 处理态时 不处理
        let inlineTaskStatus = inlineAIViewController.getAITaskStatusByNeedConfirm(needConfirm: false)
        if inlineTaskStatus == .processing || inlineTaskStatus == .initial { return }

        /// 主页面进行取消操作
        self.handleClosingClick()
    }

    // 添加手势拦截掉父类view的手势
    // 避免点击输入框x号收起键盘又打开的体验问题（父类手势事件会收起键盘）
    private func addTapGestureToSummaryView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(summaryViewTapped))
        tap.cancelsTouchesInView = false
        summaryView.addGestureRecognizer(tap)
    }

    @objc
    func summaryViewTapped() {
    }
    
    /// 用于获取当前view的frame 用于滚动函数
    func getCurrentRectOfView(type: AIGenerateEventInfoType) -> CGRect {
        switch type {
        case .summary:
            return summaryView.frame
        case .attendee:
            return attendeeView.frame
        case .rrule:
            return rruleView.frame
        case .time:
            return pickDateView.frame
        case .meetingRoom:
            return meetingRoomView.frame
        case .meetingNotes:
            return meetingNotesView.frame
        }
    }
    
    func getMeetingNotesView() -> MeetingNotesView {
        return self.meetingNotesView.meetingNotesView
    }

    /// navigationItem 可用状态更改
    private func updateNavigationItemStatus(leftEnable: Bool? = nil, rightEnable: Bool? = nil) {
        if let leftEnable = leftEnable {
            navigationItem.leftBarButtonItem?.isEnabled = leftEnable
        }

        if let rightEnable = rightEnable {
            navigationItem.rightBarButtonItem?.isEnabled = rightEnable
        }
    }

    /// AI 状态完成态 ，参与人二级页返回时，需要showPanel
    private func inlineAIPanelShowUpIfNeed() {
        if self.inlineAIViewController.getAITaskStatusByNeedConfirm(needConfirm: false) == .finish {
            self.inlineAIViewController.showPanelFromSecondVCBack()
        }
    }
}

// MARK: SetupView - Module

extension EventEditViewController {

    private struct ModuleGroup: EventEditModuleGroupType {
        var itemViews: [UIView]
        var showTopLine = false
        var topSeparatorInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 0)
        var showBottomLine = false
        var bottomSeparatorInset = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 0)
        var showSeparatorLine = false
        var separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        var topMargin = CGFloat.leastNormalMagnitude
        var bottomMargin = CGFloat.leastNormalMagnitude
    }

    // 具体UI见：https://bytedance.feishu.cn/docx/QFLMdXC84owcgLxVtXRc6WD6n5g
    private func makeModuleGroups() -> ([ModuleGroup]) {
        var moduleGroups: [ModuleGroup] = []
        let group_1 = [
            shouldShow(id: .summary) ? summaryView : nil
        ].compactMap { $0 }

        let group_2 = [
            shouldShow(id: .datePicker) ? pickDateView : nil,
            shouldShow(id: .timeZone) ? timeZoneView : nil,
            shouldShow(id: .rrule) ? rruleView : nil
        ].compactMap { $0 }

        let group_3 = [
            shouldShow(id: .webinarAttendee) ? webinarSpeakerView : nil,
            shouldShow(id: .webinarAttendee) ? webinarAudienceView : nil,
            shouldShow(id: .attendee) ? attendeeView : nil,
            shouldShow(id: .arrangeDate) ? arrangeDateView : nil,
            shouldShow(id: .guestPermission) ? guestPermissionView : nil
        ].compactMap { $0 }
        let group_4 = [
            shouldShow(id: .videoMeeting) && FS.suiteVc(userID: self.userResolver.userID) ? videoMeetingView : nil,
            shouldShow(id: .meetingRoom) ? meetingRoomView : nil,
            shouldShow(id: .location) ? locationView : nil
        ].compactMap { $0 }

        // 文档 + 描述 + 附件
        let group_5 = [
            shouldShow(id: .meetingNotes) ? meetingNotesView : nil,
            shouldShow(id: .description) ? notesView : nil,
            shouldShow(id: .attachment) ? attachmentView : nil
        ].compactMap { $0 }

        let group_6 = [
            shouldShow(id: .checkIn) ? checkInView : nil,
            shouldShow(id: .reminder) ? reminderView : nil,
            shouldShow(id: .calendar) ? calendarView : nil,
            shouldShow(id: .color) ? colorView : nil,
            shouldShow(id: .visibility) ? visibilityView : nil,
            shouldShow(id: .freebusy) ? freeBusyView : nil
        ].compactMap { $0 }

        let group_7 = [
            shouldShow(id: .delete) ? deleteView : nil
        ].compactMap { $0 }

        moduleGroups.append(ModuleGroup(itemViews: group_1,
                                        showBottomLine: true))
        moduleGroups.append(
            ModuleGroup(
                itemViews: self.viewModel.input.isWebinarScene ? group_2 : group_3,
                showBottomLine: true)
        )
        moduleGroups.append(
            ModuleGroup(
                itemViews: self.viewModel.input.isWebinarScene ? group_3 : group_2,
                showBottomLine: true)
        )
        moduleGroups.append(
            ModuleGroup(
                itemViews: group_4,
                showBottomLine: true)
        )
        moduleGroups.append(
            ModuleGroup(
                itemViews: group_5,
                showBottomLine: true)
        )
        moduleGroups.append(
            ModuleGroup(
                itemViews: group_6,
                showBottomLine: self.viewModel.input.isWebinarScene)
        )
        moduleGroups.append(
            ModuleGroup(
                itemViews: group_7,
                showTopLine: true)
        )
        return moduleGroups
    }

    private func shouldShow(id: EventEditLegoInfo.LegoID) -> Bool {
        viewModel.legoInfo.shouldShow(id)
    }
}

extension EventEditViewController: EventEditConfirmAlertSupport { }

#if !LARK_NO_DEBUG
// MARK: 编辑页便捷调试
extension EventEditViewController: ConvenientDebug {
    func addDebugGesture() {
        guard FG.canDebug else { return }
        self.view.rx.gesture(Factory<UILongPressGestureRecognizer> { _, _ in })
            .when([.began])
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.showActionSheet(debugInfo: self.viewModel, in: self)
            })
            .disposed(by: disposeBag)
    }
}
#endif
