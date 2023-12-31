//
//  NewCalendarManagerMainController.swift
//  Calendar
//
//  Created by huoyunjie on 2021/8/5.
//

import UIKit
import UniverseDesignIcon
import Foundation
import EENavigator
import LarkUIKit
import LarkContainer
import CalendarFoundation
import RxSwift
import RxCocoa
import LarkActionSheet
import RustPB
import LKCommonsLogging
import UniverseDesignActionPanel
import UniverseDesignDialog
import UniverseDesignToast
import LarkGuide

struct CalendarList {
    static let logger = Logger.log(CalendarList.self, category: "calendar.calendar_list")

    static func logInfo(_ message: String) {
        logger.info(message)
    }

    static func logError(_ message: String) {
        logger.error(message)
    }

    static func logWarn(_ message: String) {
        logger.warn(message)
    }

    static func logDebug(_ message: String) {
        logger.debug(message)
    }
}

final class CalendarListController: UIViewController, UIPopoverPresentationControllerDelegate, UserResolverWrapper {

    @ScopedInjectedLazy var newGuideManager: NewGuideService?
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    
    private lazy var taskInCalendarFG: Bool = {
        return FeatureGating.taskInCalendar(userID: self.userResolver.userID)
    }()

    private let bag: DisposeBag = DisposeBag()
    let tableView = UITableView(frame: .zero, style: .grouped)
    let viewModel: CalendarListViewModel
    private var isFirstEnter = true
    private var isFirstDrag = true
    private lazy var occupyView: UIView = UIView()
    
    /// Guide
    private var shouldShowGuideKeys: [GuideService.GuideKey] = [.calendarShareGuideKey, .taskInCalendarOnboardingInSidebar]

    let userResolver: UserResolver

    init(viewModel: CalendarListViewModel, userResolver: UserResolver, source: String) {
        self.viewModel = viewModel
        self.userResolver = userResolver
        switch source {
        case GuideService.GuideKey.taskInCalendarOnboardingInHomeView.rawValue:
            shouldShowGuideKeys = [.taskInCalendarOnboardingInSidebar]
        case GuideService.GuideKey.calendarSettingGuideKey.rawValue:
            shouldShowGuideKeys = [.calendarShareGuideKey]
        default:
            shouldShowGuideKeys = [.calendarShareGuideKey, .taskInCalendarOnboardingInSidebar]
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        bindViewData()
        CalendarTracerV2.CalendarList.traceView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isFirstEnter {
            viewModel.autoSelectHighlightedCalendar(self)
            showHighlightOrGuide()
            isFirstEnter = false
        }
        self.tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    private func setupView() {
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 48
        tableView.register(NewCalendarSidebarCell.self,
                           forCellReuseIdentifier: "NewCalendarSiderbarCell")

        tableView.separatorStyle = .none
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bindViewData() {
        Observable.combineLatest(viewModel.rxViewContent, viewModel.rxIsCellHighlighting)
            .subscribeForUI(onNext: { [weak self] _, isCellHighlighting in
                guard let self = self, !isCellHighlighting else { return }
                self.tableView.reloadData()
            }).disposed(by: bag)
    }

    private func showHighlightOrGuide() {
        if let highlightIndexPath = self.viewModel.getHighlightModelIndexPath() {
            let sectioin = highlightIndexPath.section
            let rows = tableView.numberOfRows(inSection: sectioin)
            guard sectioin < tableView.numberOfSections, highlightIndexPath.row < rows else { return }
            // 展示高亮cell
            self.tableView.scrollToRow(at: highlightIndexPath, at: .middle, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600), execute: {
                if let cell = self.tableView.cellForRow(at: highlightIndexPath) as? NewCalendarSidebarCell {
                    self.viewModel.rxIsCellHighlighting.accept(true)
                    cell.doblinking()
                }
            })
        } else if self.shouldShowGuideKeys.contains(.taskInCalendarOnboardingInSidebar),
                  FeatureGating.taskInCalendar(userID: self.userResolver.userID),
                  let newGuideManager = newGuideManager,
                  GuideService.isGuideNeedShow(newGuideManager: newGuideManager, key: .taskInCalendarOnboardingInSidebar) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: {
                self.showTimeContainerObboarding()
            })
        } else if self.shouldShowGuideKeys.contains(.calendarShareGuideKey),
                  FG.optimizeCalendar,
                  let guideIndexPath = self.viewModel.getGuideCalendarIndexPath(),
                  let newGuideManager = self.newGuideManager,
                  GuideService.isGuideNeedShow(newGuideManager: newGuideManager, key: .calendarShareGuideKey) {
            // 展示Guide
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300), execute: {
                if let cell = self.tableView.cellForRow(at: guideIndexPath) as? NewCalendarSidebarCell {
                    self.tableView.isScrollEnabled = false
                    GuideService.showGuideForCalendarOptimize(from: self, newGuideManager: newGuideManager, referView: cell.settingButton, completion: {
                        self.tableView.isScrollEnabled = true
                    })
                }
            })
        }
    }
    
    private func showTimeContainerObboarding() {
        guard let guideIndexPath = self.viewModel.getTimeContainerGuideIndexPath(),
              let newGuideManager = self.newGuideManager,
              let cell = self.tableView.cellForRow(at: guideIndexPath) as? NewCalendarSidebarCell else { return }
        self.tableView.isScrollEnabled = false
        GuideService.showGuideForTimeContainerSidebar(newGuideManager: newGuideManager, refreView: cell, completion: { [weak self] in
            self?.tableView.isScrollEnabled = true
        })
    }

    private func highlightStateReset() {
        guard isFirstDrag, viewModel.rxIsCellHighlighting.value else { return }
        viewModel.rxIsCellHighlighting.accept(false)
        isFirstDrag = false
    }
}

extension CalendarListController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let listSection = self.viewModel.getSectionIn(section: section) else { return 0 }
        return listSection.content.data.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        highlightStateReset()
        tableView.deselectRow(at: indexPath, animated: false)
        changeVisibility(with: indexPath)
    }

    private func changeVisibility(with indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? NewCalendarSidebarCell,
              let modelData = self.viewModel.getModelDataBy(indexPath: indexPath) else { return }
        
        let showLoading: Bool = {
            if modelData.source == .calendar {
                return !((modelData as? CalendarSidebarModelData)?.calendar.isLocalCalendar() ?? true)
            }
            return true
        }()
        cell.setupIsChecked(!modelData.isVisible, showLoading)
        self.viewModel.changeVisibility(indexPath: indexPath, from: self)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewCalendarSiderbarCell", for: indexPath)

        guard let sidebarCell = cell as? NewCalendarSidebarCell,
              let cellModel = self.viewModel.getModelDataBy(indexPath: indexPath) else {
            assertionFailureLog()
            return UITableViewCell()
        }
        sidebarCell.hiddenBlink()
        sidebarCell.viewData = cellModel
        sidebarCell.settingTaped = { [weak self, weak sidebarCell] in
            guard let self = self, let anchor = sidebarCell?.settingButton else { return }
            self.highlightStateReset()
            self.viewModel.tap(.setting(indexPath: indexPath, from: self, popAnchor: anchor))
        }
        sidebarCell.checkboxTaped = {[unowned self] _ in
            self.highlightStateReset()
            self.changeVisibility(with: indexPath)
        }
        return sidebarCell
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let section = self.viewModel.getSectionIn(section: section),
              !section.content.data.isEmpty else {
            return 0.01
        }
        return 36
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if FG.enableImportExchange && viewModel.isThirdPartyGroup(section) {
            return tableView.rowHeight
        }
        if section == self.viewModel.numberOfSections() - 1 {
            return 10
        }
        return 0
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        func getHeaderView(type: CalendarListSection) -> UIView {
            let labelWrapper = UIView()
            labelWrapper.backgroundColor = UIColor.ud.bgBody
            let label = UILabel()
            label.text = type.content.sourceTitle
            label.font = UIFont.systemFont(ofSize: 16)
            label.textColor = UIColor.ud.textPlaceholder
            labelWrapper.addSubview(label)
            label.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(16)
                make.top.equalToSuperview().offset(12)
            }
            var image: UIImage?
            switch type {
            case .google:
                image = UDIcon.getIconByKeyNoLimitSize(.googleColorful).withRenderingMode(.alwaysOriginal)
            case .exchange:
                image = UDIcon.getIconByKeyNoLimitSize(.exchangeColorful).withRenderingMode(.alwaysOriginal)
            case .local:
                image = UDIcon.getIconByKeyNoLimitSize(.phoneColorful).withRenderingMode(.alwaysOriginal)
            default:
                break
            }

            if let image = image {
                let logo = UIImageView(image: image)
                labelWrapper.addSubview(logo)
                logo.snp.makeConstraints { (make) in
                    make.size.equalTo(14)
                    make.top.equalToSuperview().offset(15)
                    make.left.equalTo(label.snp.right).offset(4)
                    make.right.equalToSuperview().offset(-16).priority(.low)
                }
                label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            }

            return labelWrapper
        }

        guard let section = self.viewModel.getSectionIn(section: section),
              !section.content.data.isEmpty else {
            return nil
        }
        return getHeaderView(type: section)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if FG.enableImportExchange && viewModel.isThirdPartyGroup(section) {
            guard let listSection = viewModel.getSectionIn(section: section),
                  let cellModel = listSection.content.data.first else { return nil }
            let cell = ThirdPartyFooterCell(frame: .zero)
            cell.accountValid = cellModel.accountValid
            cell.accountExpiring = cellModel.accountExpiring
            cell.tapCallback = { [weak self] in
                guard let self = self else { return }
                self.highlightStateReset()
                self.viewModel.tap(.footer(section: section, from: self))
            }
            return cell
        }
        return nil
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        highlightStateReset()
    }
}

extension CalendarListController: CalendarShareForwardVCDelegate {
    func finishShare(from: CalendarShareForwardViewController, params: CalendarShareParams) {
        from.change(toastStatus: .loading(info: I18n.Calendar_Share_Sharing, disableUserInteraction: false, fromWindow: true))
        viewModel.calendarApi?.shareCalendar(
            calendarID: params.calID, comment: params.comment,
            shareMembers: params.memberCommits,
            forbiddenList: params.forbiddenList
        ).subscribeForUI { [weak self] _ in
            from.change(toastStatus: .remove)
            guard let slideVC = self?.parent else { return }
            slideVC.change(toastStatus: .success(I18n.Calendar_Share_SharedToast, fromWindow: true))
        } onError: { [weak self] error in
            from.change(toastStatus: .remove)
            guard let slideVC = self?.parent else { return }

            if error.errorType() == .calendarIsPrivateErr {
                slideVC.change(toastStatus: .failure(I18n.Calendar_G_CantSharePrivateCalendar, fromWindow: true))
            } else if error.errorType() == .calendarIsDeletedErr {
                slideVC.change(toastStatus: .failure(I18n.Calendar_Common_CalendarDeleted, fromWindow: true))
            } else if error.errorType() == .calendarServerCustomizeErr || error.errorType() == .calendarWriterReachLimitErr {
                slideVC.change(toastStatus: .failure(error.getServerDisplayMessage() ?? I18n.Calendar_Bot_SomethingWrongToast, fromWindow: true))
            } else {
                slideVC.change(toastStatus: .failure(I18n.Calendar_Bot_SomethingWrongToast, fromWindow: true))
            }

            CalendarBiz.shareLogger.info(error.localizedDescription)
        }.disposed(by: bag)
    }
}
