//
//  MailOOOSettingViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/2/23.
//

import Foundation
import LarkUIKit
import EENavigator
import RxSwift
import RxCocoa
import RxDataSources
import RustPB
import Homeric
import FigmaKit
import UniverseDesignIcon

class MailOOOSettingViewController: MailBaseViewController, UITableViewDelegate, UITableViewDataSource {

    enum MailOOOSource {
        case setting
        case banner
    }

    let disposeBag = DisposeBag()

    let maxHtmlCount = 3000

    private var viewModel: MailSettingViewModel?
    var accountId: String
    var accountSetting: MailAccountSetting?
    var source: MailOOOSource = .setting
    let accountContext: MailAccountContext

    init(accountContext: MailAccountContext, viewModel: MailSettingViewModel?, source: MailOOOSource, accountId: String) {
        self.viewModel = viewModel
        self.accountId = accountId
        self.source = source
        self.accountContext = accountContext
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    // var dataListArr = BehaviorSubject(value: [MailOOOSectionItem]())
    var dataListArr = [MailOOOSection]() // BehaviorSubject(value: [MailOOOSection]())
    lazy var tableView: InsetTableView = self.createTableView()
    var switchEnable = true {
        didSet {
            reloadData()
        }
    }

    var onlySendToTenant = false
    var viewDidLoadFlag = false
    var viewDidTrans = false
    


    override var navigationBarTintColor: UIColor {
        return UIColor.ud.bgFloatBase
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        accountContext.editorLoader.preloadEditor()
        setupAndBindView()
        setupViewModel()
        switch self.source {
        case .setting:
            MailTracker.log(event: Homeric.EMAIL_OOO_SETTINGS_SHOW, params: ["source": "Settings"])
        case .banner:
            MailTracker.log(event: Homeric.EMAIL_OOO_SETTINGS_SHOW, params: ["source": "Banner"])
        }

        guard let vacationResponder = self.viewModel?.getAccountSetting(of: accountId)?.setting.vacationResponder else {
            return
        }

        if !vacationResponder.enable || vacationResponder.autoReplyBody.count < maxHtmlCount {
            reloadData()
            viewDidLoadFlag = true
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !viewDidLoadFlag {
            reloadData()
            viewDidLoadFlag = true
        }
    }

    func setupViewModel() {
        if viewModel == nil {
            viewModel = MailSettingViewModel(accountContext: accountContext)
        } else {
            reloadData()
        }
        self.viewModel?.refreshDriver.drive(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.reloadData()
        }).disposed(by: disposeBag)
    }

    func reloadData() {
        self.accountSetting = viewModel?.getAccountSetting(of: accountId)
        guard let vacationResponder = self.accountSetting?.setting.vacationResponder else {
            return
        }
        var datas = [
            MailOOOSection(header: "", items: [ .TitleSwitchSectionItem(title: BundleI18n.MailSDK.Mail_Setting_EmailAutoReply,
                                                                        enabled: vacationResponder.enable)])
        ]
        onlySendToTenant = vacationResponder.onlySendToTenant
        let tenantName = accountContext.user.info?.tenantName ?? vacationResponder.tenantName
        if vacationResponder.enable {
            datas.append(contentsOf: [
                MailOOOSection(header: "", items: [ .DatePickerSectionItem(
                    startTime: Date(timeIntervalSince1970: TimeInterval(vacationResponder.startTimestamp / 1000))/*.utcToLocalDate()*/,
                    endTime: Date(timeIntervalSince1970: TimeInterval(vacationResponder.endTimestamp / 1000))/*.utcToLocalDate()*/)]),
                MailOOOSection(header: "", items: [
                    .ImageTitleSectionItem(title: BundleI18n.MailSDK.Mail_OOO_Content_Title, image: UDIcon.editOutlined.withRenderingMode(.alwaysTemplate)),
                    .ImageLongTextSectionItem(title: vacationResponder.autoReplyBody, image: Resources.mail_setting_icon_edit)
                ]),
                MailOOOSection(header: "", items: [
                    // IG修改这个逻辑，只显示发送给bd
//                    .CheckboxTitleSectionItem(title: BundleI18n.MailSDK.Mail_OOO_SendToAll, isSelected: !onlySendToTenant),
                    .CheckboxTitleSectionItem(title: BundleI18n.MailSDK.Mail_OOO_InternalOnly(tenantName),
                        isSelected: onlySendToTenant)
                ])
            ])
        }
       // dataListArr.onNext(datas)
        dataListArr = datas
        if vacationResponder.enable && vacationResponder.autoReplyBody.count > maxHtmlCount {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        } else {
            tableView.reloadData()
        }
    }

    func setupAndBindView() {
        title = BundleI18n.MailSDK.Mail_Setting_EmailAutoReply
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    // to prevent swipe to delete behavior
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 11
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataListArr.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataListArr[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch dataListArr[indexPath.section].items[indexPath.row] {
        case let .TitleSwitchSectionItem(title, status):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailOOOSettingSwitchCell.lu.reuseIdentifier,
                                                           for: indexPath) as? MailOOOSettingSwitchCell
                else { return UITableViewCell() }
            cell.setCellInfo(title: title, status: status)
            cell.switchBtnObserver
                .debounce(.seconds(Int(0.8)), scheduler: MainScheduler.instance)
                .distinctUntilChanged().asObservable()
                .subscribe(onNext: { [weak self] value in
                    guard let `self` = self else { return }
                    /// ooo 开关
                    if var setting = self.accountSetting?.setting {
                        var newSettings: [MailSettingAction] = [.vacationResponder(.enable(value))]
                        var endTimestamp = setting.vacationResponder.endTimestamp
                        let endDate = Date(timeIntervalSince1970: TimeInterval(endTimestamp / 1000))
                        if endDate.compare(Date()) == .orderedAscending {
                            endTimestamp = self.getEndTimeStamp(Date())
                            newSettings.append(.vacationResponder(.endTimestamp(endTimestamp)))
                        }
                        self.accountSetting?.updateSettings(newSettings)
                    }
                    self.switchEnable = value
                    self.viewModel?.updateOOOSwitch(value, self.accountId)
                    MailTracker.log(event: Homeric.EMAIL_OOO_SETTINGS_SAVED, params: ["switch_type": value ? "on" : "off"])
                }).disposed(by: cell.disposeBag)
            return cell
        case let .DatePickerSectionItem(startTime, endTime):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailOOOSettingDateCell.lu.reuseIdentifier) as? MailOOOSettingDateCell
                    else { return UITableViewCell() }
            cell.delegate = self
            cell.setCellInfo(startTime: startTime, endTime: endTime)
            return cell
        case let .ImageTitleSectionItem(title, image):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailOOOSettingIconCell.lu.reuseIdentifier,
                                                       for: indexPath) as? MailOOOSettingIconCell
                else { return UITableViewCell() }
            cell.setCellInfo(title: title, image: image)
            return cell
        case let .ImageLongTextSectionItem(title, image):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailOOOSettingLongTextCell.lu.reuseIdentifier,
                                                       for: indexPath) as? MailOOOSettingLongTextCell
                else { return UITableViewCell() }
            cell.setCellInfo(title: title, image: image)
            return cell

        case let .CheckboxTitleSectionItem(title, isSelected):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MailOOOSettingCheckboxCell.lu.reuseIdentifier,
                                                       for: indexPath) as? MailOOOSettingCheckboxCell
                else { return UITableViewCell() }
            cell.selectionStyle = .none
            cell.setCellInfo(title: title, isSelected: isSelected)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        switch dataListArr[indexPath.section].items[indexPath.row] {
        case .DatePickerSectionItem(startTime: _, endTime: _):
            jumpToDatePicker(isSelectAtStarTime: true)
        case .ImageLongTextSectionItem(title: _, image: _),
            .ImageTitleSectionItem(title: _, image: _):
            guard let vacationResponder = accountSetting?.setting.vacationResponder else {
                return
            }
            let draftItem = MailContent(subject: "",
                                        bodySummary: vacationResponder.autoReplySummary,
                                        bodyHtml: vacationResponder.autoReplyBody, subjectCover: nil,
                                        images: vacationResponder.images.map({ MailImageInfo.convertFromPBModel($0) }), docsConfigs: [])
            let draft = MailDraft(fromAddress: "", fromName: "", content: draftItem, docID: "")
            let editVC = MailSendController.makeSendNavController(accountContext: accountContext,
                                                                  action: .outOfOffice,
                                                                  draft: draft,
                                                                  statInfo: MailSendStatInfo(from: .outOfOffice, newCoreEventLabelItem: "none"),
                                                                  trackerSourceType: .outOfOffice,
                                                                  oooDelegate: self)
            // 先不该model v
            navigator?.present(editVC, from: self)
        case let .TitleSwitchSectionItem(title: _, enabled: enable):
            self.switchEnable = enable
            self.accountSetting?.updateSettings(.vacationResponder(.enable(enable)))
        case let .CheckboxTitleSectionItem(title: _, isSelected: isSelected):
            self.onlySendToTenant = !isSelected
            self.refreshCheckbox(indexPath.section)
            self.accountSetting?.updateSettings(.vacationResponder(.onlySendToTenant(!isSelected)))
        }
    }

    func refreshCheckbox(_ section: Int) {
        if dataListArr.count > section {
            guard let vacationResponder = accountSetting?.setting.vacationResponder else {
                return
            }
            let tenantName = accountContext.user.info?.tenantName ?? vacationResponder.tenantName
            dataListArr[section] = MailOOOSection(header: "", items: [
//                .CheckboxTitleSectionItem(title: BundleI18n.MailSDK.Mail_OOO_SendToAll, isSelected: !onlySendToTenant),
                .CheckboxTitleSectionItem(title: BundleI18n.MailSDK.Mail_OOO_InternalOnly(tenantName),
                    isSelected: onlySendToTenant)
            ])
            tableView.reloadSections([section], animationStyle: .none)
        }

    }

    private func createTableView() -> InsetTableView {
        let tableView = InsetTableView(frame: .zero)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = UIColor.ud.bgFloatBase
        tableView.separatorColor = UIColor.ud.lineDividerDefault
        tableView.sectionHeaderHeight = 11
        tableView.sectionFooterHeight = 0
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: Display.width, height: 0.01))

        /// registerCell
        tableView.lu.register(cellSelf: MailOOOSettingSwitchCell.self)
        tableView.lu.register(cellSelf: MailOOOSettingIconCell.self)
        tableView.lu.register(cellSelf: MailOOOSettingLongTextCell.self)
        tableView.lu.register(cellSelf: MailOOOSettingCheckboxCell.self)
        tableView.lu.register(cellSelf: MailOOOSettingDateCell.self)

        tableView.rx.setDelegate(self).disposed(by: disposeBag)
        tableView.rx.setDataSource(self).disposed(by: disposeBag)

        tableView.contentInsetAdjustmentBehavior = .never

        return tableView
    }
}

enum MailOOOSectionItem {
    case TitleSwitchSectionItem(title: String, enabled: Bool) // BehaviorRelay<Bool>)
    case DatePickerSectionItem(startTime: Date, endTime: Date)
    case ImageTitleSectionItem(title: String, image: UIImage)
    case ImageLongTextSectionItem(title: String, image: UIImage)
    case CheckboxTitleSectionItem(title: String, isSelected: Bool)
}

struct MailOOOSection {
    var header: String
    var items: [MailOOOSectionItem]
}

extension MailOOOSection: SectionModelType {
    typealias Item = MailOOOSectionItem

    init(original: MailOOOSection, items: [Item]) {
        self = original
        self.items = items
    }
}

extension MailOOOSettingViewController: MailSendOOODelegate {
    func saveAutoReplyLetter(content: MailContent?) {
        let images = content?.images.map { $0.toPBModel() } ?? []
        let autoReplyBody = content?.bodyHtml ?? ""
        let autoReplySummary = content?.bodySummary ?? ""

        accountSetting?.updateSettings(.vacationResponder(.images(images)),
                                       .vacationResponder(.autoReplyBody(autoReplyBody)),
                                       .vacationResponder(.autoReplySummary(autoReplySummary)))
        reloadData()
        viewDidTrans = true
    }
}

extension MailOOOSettingViewController: MailDatePickerViewControllerDelegate {
    var calendarProvider: CalendarProxy? {
        accountContext.provider.calendarProvider
    }

    func didSaveDate(startTime: Date, endTime: Date) {
        let startTime = getStartTimeStamp(startTime)
        let endTimestamp = getEndTimeStamp(endTime)
        accountSetting?.updateSettings(.vacationResponder(.startTimestamp(startTime)),
                                       .vacationResponder(.endTimestamp(endTimestamp)))
        reloadData()
    }

    private func getStartTimeStamp(_ startTime: Date) -> Int64 {
//        let timezone = TimeZone(abbreviation: viewModel?.currentSetting?.setting.vacationResponder.timeZone ?? "") ?? TimeZone.current
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.era, .year, .month, .day, .hour, .minute, .second], from: startTime/*.utcToLocalDate(TimeZone.current)*/)
        comps.hour = 0
        comps.minute = 0
        comps.second = 1
        let beginDate = calendar.date(from: comps)
        return Int64((beginDate ?? startTime).milliTimestamp) ?? 0
    }

    private func getEndTimeStamp(_ endTime: Date) -> Int64 {
//        let timezone = TimeZone(abbreviation: viewModel?.currentSetting?.setting.vacationResponder.timeZone ?? "") ?? TimeZone.current
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.era, .year, .month, .day, .hour, .minute, .second], from: endTime/*.utcToLocalDate(TimeZone.current)*/)
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        let beginDate = calendar.date(from: comps)
        let endDate = beginDate?.addingTimeInterval(3600 * 24 - 1)
        return Int64((endDate ?? endTime).milliTimestamp) ?? 0
    }
}

extension MailOOOSettingViewController: MailOOOSettingDateCellDelegate {
    func didClickedStartTime() {
        jumpToDatePicker(isSelectAtStarTime: true)
    }

    func didClickedEndTime() {
        jumpToDatePicker(isSelectAtStarTime: false)
    }

    func jumpToDatePicker(isSelectAtStarTime: Bool) {
        let vc = MailDatePickerViewController(accountContext: accountContext)
        vc.isSelectAtStarTime = isSelectAtStarTime
        vc.delegate = self
        if let vacationResponder = accountSetting?.setting.vacationResponder {
            // let timezone = TimeZone.current // TimeZone(abbreviation: vacationResponder.timeZone ?? "") ?? TimeZone.current
            var vacationStart = Date(timeIntervalSince1970: TimeInterval(vacationResponder.startTimestamp / 1000))
            var vacationEnd = Date(timeIntervalSince1970: TimeInterval(vacationResponder.endTimestamp / 1000))
            let currentStart = Calendar.current.startOfDay(for: Date())
            if let currentEnd = Calendar.current.startOfDay(for: Date()).changed(hour: 23) {
                if currentStart <= vacationStart {
                    // 还没开始，保持不变
                } else if currentEnd <= vacationEnd {
                    // 开始生效了，更新开始日期为当前日期
                    vacationStart = currentStart
                } else {
                    // 已经结束了，都更新为当天
                    vacationStart = currentStart
                    vacationEnd = currentEnd
                }
            }
            vc.updateStartTimeRangeAndPicker(vacationStart)
            vc.updateEndTimeRangeAndPicker(vacationEnd)
        }
        let pickerVC = LkNavigationController(rootViewController: vc)
        pickerVC.navigationBar.isTranslucent = false
        pickerVC.navigationBar.shadowImage = UIImage()
        pickerVC.modalPresentationStyle = Display.pad ? .formSheet :.fullScreen
        navigator?.present(pickerVC, from: self)
    }
}
