//
//  AdditionalTimeZoneViewController.swift
//  Calendar
//
//  Created by chaishenghua on 2023/10/24.
//

import Foundation
import LarkUIKit
import CTFoundation
import LarkContainer
import UniverseDesignColor
import RxSwift
import UniverseDesignToast

/// 视图页支持设置辅助时区
/// https://bytedance.larkoffice.com/docx/UwRadetnIo798fx67SncrVcHnEb
class AdditionalTimeZoneViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    typealias Config = AdditionalTimeZone
    var userResolver: LarkContainer.UserResolver
    private let viewModel: AdditionalTimeZoneViewModel
    private let disposebag = DisposeBag()

    @ScopedInjectedLazy private var timeZoneService: TimeZoneService?

    private lazy var tableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = UDColor.bgBody
        let zeroRect = CGRect(x: 0.0, y: 0.0, width: 0.0, height: Double.leastNormalMagnitude)
        tableView.tableHeaderView = UIView(frame: zeroRect)
        tableView.register(AdditionalTimeZoneCell.self, forCellReuseIdentifier: AdditionalTimeZoneCell.identifier)
        tableView.register(AddAdditionanalTimeZoneCell.self, forCellReuseIdentifier: AddAdditionanalTimeZoneCell.identifier)
        tableView.register(AdditionalTimeZoneHeaderCell.self, forHeaderFooterViewReuseIdentifier: AdditionalTimeZoneHeaderCell.identifier)
        tableView.contentInsetAdjustmentBehavior = .never
        return tableView
    }()

    private lazy var contentView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        return stackView
    }()

    private lazy var localTimeZoneView = LocalTimeZoneView()
    private lazy var additionaltimeZoneSwitchView = AdditionaltimeZoneSwitchView()
    private lazy var divideView = EventBasicDivideView(containerInsets: UIEdgeInsets(top: 14, left: 16, bottom: 0, right: 0))

    init(userResolver: LarkContainer.UserResolver, viewModel: AdditionalTimeZoneViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        viewModel.vc = self
        listenDataPush()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UDColor.bgBody
        self.view.addSubview(contentView)

        contentView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentView.addArrangedSubview(localTimeZoneView)
        localTimeZoneView.snp.makeConstraints { $0.height.equalTo(AdditionalTimeZoneUIStyle.DayScene.localTimeZoneHeight) }
        contentView.addArrangedSubview(EventBasicDivideView())
        contentView.addArrangedSubview(additionaltimeZoneSwitchView)
        additionaltimeZoneSwitchView.snp.makeConstraints { $0.height.equalTo(AdditionalTimeZoneUIStyle.DayScene.additionalTimeZoneSwitchHeight) }
        contentView.addArrangedSubview(divideView)
        contentView.addArrangedSubview(tableView)

        tableView.dataSource = self
        tableView.delegate = self
        // 处理手势冲突
        if let gesture = popupViewController?.interactivePopupGestureRecognizer {
            tableView.panGestureRecognizer.require(toFail: gesture)
        }
        setViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SettingService.shared().stateManager.activate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        SettingService.shared().stateManager.inActivate()
    }

    private func setViewModel() {
        self.divideView.isHidden = !viewModel.isShowAdditionalTimeZone
        self.localTimeZoneView.setViewData(viewData: viewModel.deviceTimeZone)
        self.additionaltimeZoneSwitchView.setModel(isOn: viewModel.isShowAdditionalTimeZone) { [weak self] isOn in
            guard let self = self else { return }
            self.viewModel.isShowAdditionalTimeZone = isOn
            divideView.isHidden = !isOn
            CalendarTracerV2.AdditionalTimeZoneClick.traceClick {
                $0.click("additional_timezone")
                $0.option = String(isOn)
            }
        }
    }

    private func listenDataPush() {
        viewModel.additionalTimeZoneObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] action in
                guard let self = self else { return }
                switch action {
                case .delete(let row):
                    if self.viewModel.isShowAdditionalTimeZone, let section = self.viewModel.getSectionIndex(.additonalTimeZoneList) {
                        UIView.animate(withDuration: 0) {
                            self.tableView.deleteRows(at: [IndexPath(row: row, section: section)], with: .none)
                        }
                    }
                case .insert(let row):
                    if self.viewModel.isShowAdditionalTimeZone, let section = self.viewModel.getSectionIndex(.additonalTimeZoneList) {
                        UIView.animate(withDuration: 0) {
                            self.tableView.insertRows(at: [IndexPath(row: row, section: section)], with: .none)
                        }
                    }
                case .reload:
                    self.tableView.reloadData()
                }
            }).disposed(by: disposebag)

        viewModel.rxSelectAdditionalTimeZone
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            if viewModel.isShowAdditionalTimeZone, let section = viewModel.getSectionIndex(.additonalTimeZoneList) {
                self.tableView.selectRow(at: IndexPath(row: 0, section: section), animated: false, scrollPosition: .none)
            }
        }).disposed(by: disposebag)
        
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = viewModel.getSection(at: section) else { return 0 }
        switch section {
        case .additonalTimeZoneList:
            return viewModel.numberOfRows(section: .additonalTimeZoneList)
        case .addAdditionalTimeZone:
            return viewModel.numberOfRows(section: .addAdditionalTimeZone)
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = viewModel.getSection(at: indexPath.section) else { return 44 }
        switch section {
        case .additonalTimeZoneList:
            return AdditionalTimeZoneUIStyle.DayScene.additonalTimeZoneCellHeight
        case .addAdditionalTimeZone:
            return AdditionalTimeZoneUIStyle.DayScene.addAdditionalTimeZoneHeight
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = viewModel.getSection(at: indexPath.section) else { return UITableViewCell() }
        switch section {
        case .additonalTimeZoneList:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: AdditionalTimeZoneCell.identifier, for: indexPath) as? AdditionalTimeZoneCell,
                  let viewData = viewModel.cellData(at: indexPath.row) else { return UITableViewCell() }
            cell.setViewData(viewData: viewData)
            if viewData.identifier == viewModel.selectedAdditionalTimeZone {
                tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
            return cell
        case .addAdditionalTimeZone:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: AddAdditionanalTimeZoneCell.identifier, for: indexPath) as? AddAdditionanalTimeZoneCell else { return UITableViewCell() }
            cell.setViewData(viewData: self.viewModel.getAddAdditionalTimeZoneViewData())
            return cell
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: AdditionalTimeZoneHeaderCell.identifier)
                as? AdditionalTimeZoneHeaderCell,
              section != 0 else {
            return UIView()
        }
        return headerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return AdditionalTimeZoneUIStyle.DayScene.addAdditionalTimeZoneListTopMargin
        } else {
            return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = viewModel.getSection(at: indexPath.section) else { return }
        switch section {
        case .additonalTimeZoneList:
            if let timeZone = viewModel.cellData(at: indexPath.row),
               viewModel.selectedAdditionalTimeZone != timeZone.identifier {
                viewModel.selectedAdditionalTimeZone = timeZone.identifier
                self.dismiss(animated: true)
            }
        default:
            return
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let section = viewModel.getSection(at: indexPath.section)
        return section == .additonalTimeZoneList ? indexPath : tableView.indexPathForSelectedRow
    }

    func getCellIndexPath(for cell: UITableViewCell) -> IndexPath? {
        return self.tableView.indexPath(for: cell)
    }
}

// MARK: Support Popup

extension AdditionalTimeZoneViewController: PopupViewControllerItem {

    var naviBarTitle: String {
        return BundleI18n.Calendar.Calendar_Timezone_SelectTimeZone
    }

    var preferredPopupOffset: PopupOffset {
        if Display.pad {
            return PopupOffset(rawValue: 0.6)
        } else {
            let preferredHeight = AdditionalTimeZoneUIStyle.DayScene.preferredHeight - Popup.Const.indicatorHeight
            let containerHeight = (popupViewController?.contentHeight ?? UIScreen.main.bounds.height)
            return PopupOffset(rawValue: preferredHeight / containerHeight)
        }
    }

    var hoverPopupOffsets: [PopupOffset] {
        [preferredPopupOffset, .full]
    }

    func shouldBeginPopupInteractingInCompact(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let popupViewController = popupViewController,
            interactivePopupGestureRecognizer == popupViewController.interactivePopupGestureRecognizer,
            let panGesture = interactivePopupGestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let velocity = panGesture.velocity(in: panGesture.view)
        let point = panGesture.location(in: self.view)

        // 手势开始时不在tableview中
        if !tableView.frame.contains(point) {
            return true
        }

        // 左滑 or 右滑
        if abs(velocity.x) > abs(velocity.y) {
            return false
        }

        guard let hoverPopupOffset = hoverPopupOffsets.last,
              abs(popupViewController.currentPopupOffset.rawValue - hoverPopupOffset.rawValue) < 0.01 else {
            return true
        }
        // 上滑
        if velocity.y < 0 {
            return false
        }
        // 下滑
        if velocity.y > 0 && tableView.contentOffset.y > 0.1 {
            return false
        }
        return true
    }

    func shouldBeginPopupInteractingInRegular(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let popupViewController = popupViewController,
            interactivePopupGestureRecognizer == popupViewController.interactivePopupGestureRecognizer,
            let panGesture = interactivePopupGestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let velocity = panGesture.velocity(in: panGesture.view)
        let point = panGesture.location(in: self.view)

        // 手势开始时不在tableview中
        if !tableView.frame.contains(point) {
            return true
        }

        // 左滑 or 右滑
        if abs(velocity.x) > abs(velocity.y) {
            return false
        }

        // 上滑
        if velocity.y < 0 {
            return false
        }
        // 下滑
        if velocity.y > 0 && tableView.contentOffset.y > 0.1 {
            return false
        }
        return true
    }
}
