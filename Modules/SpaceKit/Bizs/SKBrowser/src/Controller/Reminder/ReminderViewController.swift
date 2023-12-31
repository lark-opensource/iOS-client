//
//  ReminderViewController.swift
//  SpaceKit
//
//  Created by nine on 2019/3/18.
//  swiftlint:disable file_length

import Foundation
import SnapKit
import JTAppleCalendar
import RxSwift
import LarkTraitCollection
import RxCocoa
import EENavigator
import SKCommon
import SKResource
import SKUIKit
import SKFoundation
import UniverseDesignColor

public typealias SaveReminderCallback = ((ReminderModel) -> Void)
public final class ReminderViewController: UIViewController {

    private let calendarViewDelegateAgent: CalendarViewDelegateAgent
    weak var delegate: ReminderViewControllerDelegate?
    lazy var keyboardObserver = Keyboard(listenTo: [textItemView.textView], trigger: DocsKeyboardTrigger.reminderTextView.rawValue)

    var isEn: Bool { DocsSDK.currentLanguage == .en_US }

    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = isEn ? "h:mm a" : "HH: mm"
        formatter.resetDateFormatterLocale(isEn: isEn)
        return formatter
    }()

    var context: ReminderContext

    let isCreatingNewReminder: Bool // 如果创建新reminder -> 什么都没做就退出 reminder -> 就会弹出 alert；如果不是 -> 什么都没做就退出 -> 不弹 alert

    var contentOffsetBeforeShowingKeyboard: CGPoint = .zero // 用于键盘降下的时候恢复 content offset

    // MARK: Data

    var oldReminder: ReminderModel
    var reminder: ReminderModel
    var contentSize: CGSize

    public var cancelCallBack: (() -> Void)?
    public var saveReminderCallback: SaveReminderCallback
    public var statisticsCallBack: ((String) -> Void)?
    public var sheetStatisticsCallback: ((String, String?) -> Void)?
    
    public var recordScrollViewContentOffSet: Bool = true

    // 用于判断是否回调事件，用于点击空白消失回调
    public var callBackActionOrNot: Bool = false

    /// 在 text view 里面插入文本换行的时候，屏蔽掉 scroll view 自己的 layoutSubviews 事件导致的 setContentOffset(.zero)
    var shouldResetContentSize: Bool = true

    let animateDuration: Double = 0.3

    // MARK: Views

    lazy var topBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = UDColor.bgBody

        let statusBar = UIView()
        bar.addSubview(statusBar)
        statusBar.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.bottom.equalTo(bar.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
        }
        bar.addSubview(exitButton)
        exitButton.snp.makeConstraints { (make) in
            make.top.equalTo(statusBar.snp.bottom).offset(16)
            make.left.equalToSuperview().inset(16)
            make.width.height.equalTo(24)
        }
        bar.addSubview(saveButton)
        saveButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(exitButton)
            make.right.equalToSuperview().inset(16)
            make.height.equalTo(22)
        }

        bar.layer.ud.setShadowColor(UDColor.N900)
        bar.layer.shadowOffset = CGSize(width: 0, height: 2)
        bar.layer.shadowRadius = 4
        bar.layer.shadowOpacity = 0
        return bar
    }()

    lazy var exitButton: UIButton = {
        let btn = UIButton()
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        btn.setImage(BundleResources.SKResource.Common.Reminder.reminder_close.ud.withTintColor(UDColor.iconN1), for: .normal)
        btn.rx.tap.subscribe { [weak self] (_) in
            self?.statisticsCallBack?("click_quit")
            self?.textItemView.textView.endEditing(true)
            self?.tryCancel()
        }.disposed(by: disposeBag)
        return btn
    }()

    lazy var saveButton: UIButton = {
        let btn = UIButton()
        btn.setTitle(BundleI18n.SKResource.Doc_Reminder_Save, for: .normal)
        btn.setTitleColor(UDColor.colorfulBlue, for: .normal)
        btn.setTitleColor(UDColor.textDisabled, for: .disabled)
        btn.titleLabel?.textAlignment = .right
        btn.rx.tap.subscribe { [weak self] (_) in
            guard let self = self else { return }
            self.textItemView.textView.endEditing(true)
            self.trySave()
        }.disposed(by: disposeBag)
        return btn
    }()

    var scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        return view
    }()

    // MARK: 下面这些子控件全都是浮在 scrollview 上面的，content size 是手动设置的。只有这么做，才能获得良好的文本输入体验

    var dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "DINAlternate-Bold", size: 26)
        label.textColor = UDColor.textTitle
        label.sizeToFit()
        return label
    }()

    lazy var previousButton: UIButton = {
        let btn = UIButton()
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        btn.setImage(BundleResources.SKResource.Common.Reminder.reminder_previous.ud.withTintColor(UDColor.iconN2), for: .normal)
        btn.rx.tap.subscribe { [weak self] (_) in
            guard let self = self else { return }
            self.textItemView.textView.endEditing(true)
            if let date = self.calendarView.visibleDates().monthDates.first?.date, let newDate = self.subtract(date: date, components: 1.sk.month) {
                self.calendarView.scrollToDate(newDate)
            }
            self.statisticsCallBack?("select_month")
        }.disposed(by: disposeBag)
        return btn
    }()

    lazy var nextButton: UIButton = {
        let btn = UIButton()
        btn.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        btn.setImage(BundleResources.SKResource.Common.Reminder.reminder_next.ud.withTintColor(UDColor.iconN2), for: .normal)
        btn.rx.tap.subscribe { [weak self] (_) in
            guard let self = self else { return }
            self.textItemView.textView.endEditing(true)
            if let date = self.calendarView.visibleDates().monthDates.first?.date, let newDate = self.addComponents(date: date, components: 1.sk.month) {
                self.calendarView.scrollToDate(newDate)
            }
            self.statisticsCallBack?("select_month")
        }.disposed(by: disposeBag)
        return btn
    }()

    lazy var mentionDetailLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.N600
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    private let weekHeaderView: WeekHeaderView

    let calendarView = JTAppleCalendarView()
    private lazy var calendarViewLine = DocsItemLine()

    var dayItemView = ReminderSwitchItemView(title: BundleI18n.SKResource.Doc_Reminder_AllDay) // 设置时间的 switch

    var timeItemView = ReminderPickerItemView(title: BundleI18n.SKResource.Doc_Reminder_Time) // switch 打开后出现的 到期时间
    lazy var timePicker: ReminderDatePicker = ReminderDatePicker(mode: context.config.datePickerConfig.datePickerMode,
                                                                 minuteInterval: context.config.datePickerConfig.minuteInterval)

    var noticeItemView = ReminderPickerItemView(title: BundleI18n.SKResource.Doc_Reminder_Alert) // 提醒
    lazy var noticePicker: ReminderPickerView = ReminderPickerView()

    var createTaskItemView = ReminderSwitchItemView(title: BundleI18n.SKResource.CreationMobile_Tasks_CreateTask_CheckOption)
    
    lazy var userItemView = ReminderUserItemView(title: BundleI18n.SKResource.Doc_Reminder_Notify_Person, userModels: reminder.notifyUsers)
    var userPicker: BTChatterPanel?

    lazy var textItemView = ReminderTextView(title: BundleI18n.SKResource.Doc_Reminder_Notify_Notes, text: reminder.notifyText, delegate: self)
    
    lazy var invalidTimeTipsItemView = ReminderTipsItemView(text: BundleI18n.SKResource.LarkCCM_Docx_Poll_SelectTime_Banner)
    
    var textItemHeightInequalityConstraint: Constraint!
    var textItemHeightIsZeroConstraint: Constraint!

    var bottomSafeArea = UIView()

    let disposeBag = DisposeBag()

    // MARK: Observables

    var noticeSelectArray: BehaviorRelay<[(key: ReminderNoticeStrategy, value: String)]>
    var noticeSelectedRow = BehaviorRelay(value: 1)
    var selectedDay = BehaviorRelay(value: Date())
    var selectedTime: BehaviorRelay<Date?> = BehaviorRelay(value: nil)

    public init(with reminder: ReminderModel, contentSize: CGSize,
         showWholeDaySwitch: Bool? = false,
         isCreatingNewReminder: Bool = false,
         config: ReminderVCConfig = ReminderVCConfig.default,
         docsInfo: DocsInfo?,
         callback: @escaping SaveReminderCallback) {
        self.oldReminder = reminder
        self.reminder = reminder
        self.contentSize = contentSize
        self.saveReminderCallback = callback
        self.weekHeaderView = WeekHeaderView()
        self.context = ReminderContext(dateLabel: dateLabel,
                                       config: config,
                                       expireTime: reminder.expireTime ?? Date().timeIntervalSince1970,
                                       docsInfo: docsInfo)
        self.context.config.showWholeDaySwitch = showWholeDaySwitch ?? false
        self.calendarViewDelegateAgent = CalendarViewDelegateAgent(calendarView, context: context)
        self.delegate = self.calendarViewDelegateAgent
        self.noticeSelectArray = BehaviorRelay(value: config.noticePickerConfig.noticeOnADay)
        self.isCreatingNewReminder = isCreatingNewReminder
        super.init(nibName: nil, bundle: nil)
        self.calendarViewDelegateAgent.statisticsCallBack = { [weak self] str in
            self?.statisticsCallBack?(str)
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        layoutUI()
        setupCalendarView()
        setupUI(with: reminder)
        bindUI()
        oldReminder = reminder // bindUI 时会修改
        // 监听sizeClass
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] change in
                guard let self = self else { return }
                if change.old != change.new {
                    DispatchQueue.main.async {
                        self.dismiss(animated: true) {
                            self.directCancel()
                        }
                    }
                }
            }).disposed(by: disposeBag)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIApplication.didChangeStatusBarOrientationNotification,
                                               object: nil)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 去除 picker 的两条分割线，神奇的 UI 需求
        noticePicker.subviews
            .filter { $0.subviews.isEmpty }
            .filter { !($0 is DocsItemLine) }
            .forEach { $0.isHidden = true }
        updateDisplayAreaContentSize()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupKeyboardObservation()
        onWidthChange(width: self.view.frame.width)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        destroyKeyboardObservation()
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard !self.isBeingDismissed else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.isBeingDismissed else {
                return
            }
            self.onWidthChange(width: size.width)
            //参考calendarView.viewWillTransition实现
            let visibleDates = self.calendarView.visibleDates()
            self.calendarView.reloadData(withanchor: visibleDates.monthDates.first?.date)
        }
    }

    func updateDisplayAreaContentSize() {
        if shouldResetContentSize {
            scrollView.contentSize = CGSize(width: view.frame.width, height: bottomSafeArea.frame.maxY)
        }
    }

    deinit {
        directCancel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func orientationDidChange() {
        guard self.modalPresentationStyle == .formSheet else {
            // iPad非formsheet情况横竖屏切换暂时有问题，调用reloadData()会有问题后续需要继续跟进如何解决
            self.dismiss(animated: true, completion: nil)
            return
        }
        onWidthChange(width: self.view.frame.width)
    }

    private func onWidthChange(width: CGFloat) {
        let oldCellSize = calendarView.cellSize
        let newCellSize = (width - 12) / 7 // 12为左右边距
        guard oldCellSize != newCellSize else {
            return
        }
        calendarView.cellSize = newCellSize
        updateTipsViewLayout()
    }
}

// MARK: - Setup
private extension ReminderViewController {

    func setupUI(with reminder: ReminderModel) {
        // 是否设置时间
        dayItemView.rightView.isOn = reminder.shouldSetTime ?? true
        // 过期时间
        if let expireTime = reminder.expireTime {
            let time = Date(timeIntervalSince1970: TimeInterval(expireTime))
            selectedDay.accept(time)
            timePicker.date = time
            if let shouldSetTime = reminder.shouldSetTime, shouldSetTime {
                selectedTime.accept(time)
            }
        } else {
            resetTimePicker()
        }
        // 提醒
        if reminder.notifyStrategy != nil {
            updateNoticePicker()
        } else {
            if context.config.showWholeDaySwitch { noticeSelectedRow.accept(1) } // 如果开启全天，默认值为第一项
            noticeItemView.rightView.text = BundleI18n.SKResource.Doc_Reminder_NoAlert
        }
        
        if let deadlineText = context.config.deadlineText {
            timeItemView.updateTitle(deadlineText)
        }
        
        if !context.config.showNoticeItem {
            noticeItemView.isHidden = true
        }
        
        if !context.config.showPickTimeSwitch {
            dayItemView.isHidden = true
        }
        
        // 创建飞书任务
        createTaskItemView.rightView.isOn = reminder.isCreateTaskSwitchOn
        
    }

    func setupCalendarView() {
        calendarView.backgroundColor = UDColor.bgBody
        calendarView.clipsToBounds = false
        calendarView.minimumLineSpacing = 0
        calendarView.minimumInteritemSpacing = 0
        calendarView.calendarDataSource = calendarViewDelegateAgent
        calendarView.calendarDelegate = calendarViewDelegateAgent
        calendarView.register(MonthViewCell.self, forCellWithReuseIdentifier: "MonthViewCell")
        calendarView.scrollingMode = .stopAtEachCalendarFrame
        calendarView.cellSize = (contentSize.width - 12) / 7 //12为左右边距
        calendarView.sectionInset = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        calendarView.isPagingEnabled = true
        calendarView.scrollDirection = .horizontal
        calendarView.showsHorizontalScrollIndicator = false
        calendarView.showsVerticalScrollIndicator = false
        calendarView.clipsToBounds = false
    }
}

// MARK: - Layout
extension ReminderViewController {

    // swiftlint:disable function_body_length
    func layoutUI() {
        view.backgroundColor = UDColor.bgBody
        view.addSubview(scrollView)
        view.addSubview(topBar)
        topBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top).offset(57)
        }
        scrollView.snp.makeConstraints { (make) in
            make.top.equalTo(topBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }

        scrollView.addSubview(dateLabel)
        scrollView.addSubview(previousButton)
        scrollView.addSubview(nextButton)
        scrollView.addSubview(weekHeaderView)
        scrollView.addSubview(calendarView)
        scrollView.addSubview(calendarViewLine)
        dateLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(22)
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(30)
        }
        nextButton.snp.makeConstraints { (make) in
            make.right.equalTo(view).inset(21)
            make.centerY.equalTo(dateLabel)
            make.width.height.equalTo(20)
        }
        previousButton.snp.makeConstraints { (make) in
            make.right.equalTo(nextButton.snp.left).inset(-44)
            make.centerY.equalTo(dateLabel)
            make.width.height.equalTo(20)
        }
        weekHeaderView.snp.makeConstraints { (make) in
            make.left.right.equalTo(view).inset(6)
            make.top.equalTo(dateLabel.snp.bottom).offset(16)
            make.height.equalTo(20)
        }
        calendarView.snp.makeConstraints { (make) in
            make.top.equalTo(weekHeaderView.snp.bottom).offset(8)
            make.left.right.equalTo(view)
            make.height.equalTo(240)
        }
        calendarViewLine.snp.makeConstraints { (make) in
            make.left.right.equalTo(calendarView)
            make.bottom.equalTo(calendarView.snp.bottom).offset(8)
            make.height.equalTo(0.5)
        }

        exitButton.docs.addStandardHighlight()
        saveButton.docs.addStandardHighlight()
        previousButton.docs.addStandardHighlight()
        nextButton.docs.addStandardHighlight()

        scrollView.addSubview(dayItemView)
        scrollView.addSubview(timeItemView)
        scrollView.addSubview(timePicker)
        scrollView.addSubview(noticeItemView)
        scrollView.addSubview(noticePicker)
        scrollView.addSubview(createTaskItemView)
        scrollView.addSubview(userItemView)
        scrollView.addSubview(textItemView)
        scrollView.addSubview(bottomSafeArea)
        scrollView.addSubview(mentionDetailLabel)

        if !context.config.showWholeDaySwitch {
            dayItemView.isHidden = true
            timeItemView.isHidden = true
        }
        dayItemView.snp.makeConstraints { (make) in
            make.top.equalTo(calendarViewLine.snp.bottom)
            make.left.right.equalTo(view)
            make.height.equalTo(context.config.showWholeDaySwitch ? 60 : 0)
        }
        dayItemView.rightView.onTintColor = UDColor.colorfulBlue
        timeItemView.snp.makeConstraints { (make) in
            make.top.equalTo(dayItemView.snp.bottom)
            make.left.right.equalTo(view)
            make.height.equalTo(context.config.showWholeDaySwitch ? 60 : 0)
        }
        timePicker.snp.makeConstraints { (make) in
            make.top.equalTo(timeItemView.snp.bottom)
            make.height.equalTo(0)
            make.left.right.equalTo(view)
        }
        timePicker.isHidden = true
        noticeItemView.snp.makeConstraints { (make) in
            make.top.equalTo(timePicker.snp.bottom)
            make.left.right.equalTo(view)
            if context.config.showNoticeItem {
                make.height.equalTo(60)
            } else {
                make.height.equalTo(0)
            }
        }
        noticePicker.snp.makeConstraints { (make) in
            make.top.equalTo(noticeItemView.snp.bottom)
            make.left.right.equalTo(view)
            make.height.equalTo(0)
        }
        noticePicker.isHidden = true
        
        userItemView.snp.makeConstraints { make in
            make.top.equalTo(noticePicker.snp.bottom)
            make.left.right.equalTo(view)
            make.height.equalTo(0)
        }
        setUserItem(isHidden: reminder.notifyUsers == nil)
        textItemView.snp.makeConstraints { (make) in
            make.top.equalTo(userItemView.snp.bottom)
            make.left.right.equalTo(view)
            textItemHeightIsZeroConstraint = make.height.equalTo(0).constraint
            textItemHeightInequalityConstraint = make.height.greaterThanOrEqualTo(90).constraint
        }
        setTextItem(isHidden: reminder.notifyText == nil)
        
        let isMentionHidden = reminder.mentions?.isEmpty ?? true
        mentionDetailLabel.snp.makeConstraints { (make) in
            make.top.equalTo(textItemView.snp.bottom).offset(isMentionHidden ? 0 : 16)
            make.left.equalTo(view).offset(16)
            make.right.equalTo(view).offset(-16)
        }
        setMentionDetail(text: reminder.mentions)
        mentionDetailLabel.isHidden = (reminder.mentions?.isEmpty ?? true) || reminder.notifyStrategy == .noAlert
        createTaskItemView.isHidden = !self.context.config.isShowCreateTaskSwitch
        createTaskItemView.rightView.onTintColor = UDColor.colorfulBlue
        createTaskItemView.snp.makeConstraints { make in
            make.top.equalTo(mentionDetailLabel.snp.bottom)
            make.left.right.equalTo(view)
            make.height.equalTo(self.context.config.isShowCreateTaskSwitch ? 60 : 0)
        }
        
        bottomSafeArea.snp.makeConstraints { make in
            make.top.equalTo(createTaskItemView.snp.bottom)
            make.left.right.equalTo(view)
            make.height.equalTo(max(view.safeAreaInsets.bottom, 10))
        }
        setTextItem(isHidden: reminder.notifyText == nil)
    }
    
   
}

// MARK: - 点击事件和数据绑定
extension ReminderViewController {

    func bindUI() {
        scrollView.rx.contentOffset
            .flatMap { (offset) -> Observable<Bool> in Observable.just(offset.y > 0) }
            .subscribe { [weak self] shouldShowShadow in
                self?.setTopBarShadow(show: shouldShowShadow)
            }
            .disposed(by: disposeBag)
        calendarViewDelegateAgent.callBack = { [weak self] selectedDate, isManual in
            guard let self = self else { return }
            self.textItemView.textView.endEditing(true)
            self.selectedDay.accept(selectedDate)
            
            let hasoCorrectExpireTime = self.tryAutoCorrectExpireTime(isManual)
            if !hasoCorrectExpireTime {
                self.updateReminderTime()
            }
            self.setTimePicker(isHidden: true, scrollsToBottom: false)
            self.setNoticePicker(isHidden: true, scrollsToBottom: false)
            self.statisticsCallBack?("select_date")
        }
        dayItemView.rightView.rx.isOn.subscribe { [weak self] _ in
            guard let self = self else { return }
            // 各个控件隐藏状态
            self.textItemView.textView.endEditing(true)
            self.updateReminder(shouldSetTime: self.dayItemView.rightView.isOn)
            self.setTimeItemView(isHidden: !self.dayItemView.rightView.isOn)
            self.setNoticeItem(shouldSetTime: self.dayItemView.rightView.isOn)
            self.setTimePicker(isHidden: true, scrollsToBottom: false)
            self.setNoticePicker(isHidden: true, scrollsToBottom: false)
            // 各个控件数据状态
            self.updateNoticePicker()
            self.updateTimePicker()
            self.updateReminderTime()
            self.statisticsCallBack?(self.dayItemView.rightView.isOn ? "client_all_day" : "client_cancel_all_day")
        }.disposed(by: disposeBag)
        timeItemView.tapCallback = { [weak self] _ in
            guard let self = self else { return }
            self.textItemView.textView.endEditing(true)
            self.setNoticePicker(isHidden: true, scrollsToBottom: false)
            self.setTimePicker(isHidden: !self.timePicker.isHidden, scrollsToBottom: true)
        }
        timePicker.dateObserver.skip(1)
            .subscribe(onNext: { [weak self] newDate in
            guard let self = self else { return }
            self.textItemView.textView.endEditing(true)
            self.selectedTime.accept(newDate)
        }).disposed(by: disposeBag)
        noticeItemView.tapCallback = { [weak self] _ in
            guard let self = self else { return }
            self.textItemView.textView.endEditing(true)
            self.setTimePicker(isHidden: true, scrollsToBottom: false)
            self.setNoticePicker(isHidden: !self.noticePicker.isHidden, scrollsToBottom: true)
        }
        noticeSelectArray.asObservable()
            .bind(to: noticePicker.rx.items(adapter: PickerViewViewAdapter()))
            .disposed(by: disposeBag)
        // 提醒选择器选择 -> noticeSelectRow
        noticePicker.rx.itemSelected.subscribe(onNext: { [weak self] (_, _) in
            guard let self = self else { return }
            self.textItemView.textView.endEditing(true)
            self.noticeSelectedRow.accept(self.noticePicker.selectedRow(inComponent: 0))
            if self.reminder.notifyUsers != nil && self.reminder.notifyText != nil { // 只有 sheet 命中这里
                let isNoAlert = self.noticePicker.selectedRow(inComponent: 0) == 0
                self.setUserItem(isHidden: isNoAlert)
                self.setTextItem(isHidden: isNoAlert)
                if isNoAlert {
                    self.statisticsCallBack?("click_no_reminder")
                }
                self.view.layoutIfNeeded()
                self.updateDisplayAreaContentSize()
            }
        }).disposed(by: disposeBag)
        // noticeSelectRow<Int> -> 提醒label显示+提醒选择器更新+数据更新
        noticeSelectedRow.bind(to: noticePicker.rx.row).disposed(by: disposeBag)
        noticeSelectedRow.subscribe { [weak self] (rowEvent) in
            guard let row = rowEvent.element else { return }
            self?.updateNoticeStrategy(with: row)
        }.disposed(by: disposeBag)
        // selectedDay<Date> -> 日历选择的天数
        selectedDay.bind(to: calendarView.rx.selectedDate).disposed(by: disposeBag)
        // selectedTime<Date> -> 时间label显示+数据更新
        selectedTime.asObservable().subscribe { [weak self] (selectedTimeEvent) in
            guard let self = self, let element = selectedTimeEvent.element else { return }
            self.updateReminderTime()
            if let selectedTime = element {
                self.delegate?.reminderViewControllerDidSelectedTime(time: selectedTime)
                self.timeItemView.rightView.text = self.formatDate(selectedTime)
            }
        }.disposed(by: disposeBag)
        
        createTaskItemView.rightView.rx.isOn.subscribe { [weak self] _ in
            guard let self = self else { return }
            self.updateCreateTaskStatus(isOn: self.createTaskItemView.rightView.isOn)
        }
        
        userItemView.tapCallback = { [weak self] _ in
            guard let self = self else { return }
            self.textItemView.textView.endEditing(true)
            self.setNoticePicker(isHidden: true, scrollsToBottom: false)
            self.setTimePicker(isHidden: true, scrollsToBottom: false)
            self.showUserPicker()
        }
    }

    func setTopBarShadow(show: Bool) {
        if show {
            topBar.layer.shadowOpacity = 0.12
        } else {
            topBar.layer.shadowOpacity = 0
        }
    }

    func scrollsToBottomAnimated(_ animated: Bool) {
        // 当在iPadC模式时，才需要使用该场景
        guard self.modalPresentationStyle == .formSheet else {
            return
        }
        let offset = self.scrollView.contentSize.height - self.scrollView.bounds.size.height
        if offset > 0 {
            self.scrollView.setContentOffset(CGPoint(x: 0, y: offset), animated: animated)
        }
    }
}

// MARK: - 更新reminder数据模型，为避免数据和状态的不同步，请确保以下方法只通过bindUI()中的事件绑定来进行调用修改
extension ReminderViewController {
    /// 更新reminder的是否选择全天
    func updateReminder(shouldSetTime: Bool) {
        self.reminder.shouldSetTime = shouldSetTime
    }
    
    /// 更新reminder的过期时间
    func updateReminderTime() {
        if let shouldSetTime = self.reminder.shouldSetTime, shouldSetTime {
            reminder.expireTime = getCombineDateTime(date: selectedDay.value, time: selectedTime.value).timeIntervalSince1970
        } else {
            let defaultHour = context.docsInfo?.type == .sheet ? 0 : 23
            let defaultMinute = context.docsInfo?.type == .sheet ? 0 : 59
            let defaultSecond = context.docsInfo?.type == .sheet ? 0 : 59
            self.reminder.expireTime = Date(year: self.selectedDay.value.sk.year,
                                            month: self.selectedDay.value.sk.month,
                                            day: self.selectedDay.value.sk.day,
                                            hour: defaultHour,
                                            minute: defaultMinute,
                                            second: defaultSecond).timeIntervalSince1970
        }
        
        if context.config.showDeadlineTips {
            if let expireTime = self.reminder.expireTime, !self.checkExpireTime(expireTime) {
                DocsLogger.info("invalid expireTime: \(expireTime)", component: LogComponents.reminder)
                setupInvalidTimeTipsItemView(isShow: true)
                saveButton.isEnabled = false
                let date = Date(timeIntervalSince1970: expireTime)
                timeItemView.isEnabled = date.isInToday
                
            } else {
                setupInvalidTimeTipsItemView(isShow: false)
                saveButton.isEnabled = true
                timeItemView.isEnabled = true
            }
        }
    }
    /// 更新reminder提醒策略
    func updateNoticeStrategy(with row: Int) {
        if let shouldSetTime = self.reminder.shouldSetTime, !shouldSetTime {
            self.reminder.notifyStrategy = self.context.config.noticePickerConfig.noticeOnADay[row].key
            self.noticeItemView.rightView.text = self.context.config.noticePickerConfig.noticeOnADay[row].value
        } else {
            self.reminder.notifyStrategy = self.context.config.noticePickerConfig.noticeAtAMoment[row].key
            self.noticeItemView.rightView.text = self.context.config.noticePickerConfig.noticeAtAMoment[row].value
        }
        mentionDetailLabel.isHidden = self.reminder.notifyStrategy == .noAlert
    }
    
    func updateCreateTaskStatus(isOn: Bool) {
        self.reminder.isCreateTaskSwitchOn = isOn
    }
}


private extension Reactive where Base: UIPickerView {
    var row: Binder<Int> {
        return Binder(self.base) { picker, row in
            guard row < picker.numberOfRows(inComponent: 0) else {
                DocsLogger.error("越界保护，请检查 picker 数据源", component: LogComponents.reminder)
                return
            }
            picker.selectRow(row, inComponent: 0, animated: false)
        }
    }
}

private extension Reactive where Base: JTAppleCalendarView {
    var selectedDate: Binder<Date> {
        return Binder(self.base) { calendar, date in
            guard calendar.selectedDates.first != date else { return }
            calendar.selectDates([date])
            calendar.scrollToDate(date, animateScroll: false)
        }
    }
}
