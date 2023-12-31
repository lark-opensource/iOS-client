//
//  CalendarFilterViewController.swift
//  CalendarInChat
//
//  Created by sunxiaolei on 2019/8/11.
//

import UniverseDesignIcon
import Foundation
import LarkUIKit
import RxSwift
import RoundedHUD
import LarkContainer
import UniverseDesignToast
import UIKit
import EENavigator

final class CalendarFilterViewController: UIViewController, UIAdaptivePresentationControllerDelegate, UserResolverWrapper {
    private let tableView = UITableView(frame: CGRect.zero, style: .grouped)
    @ScopedInjectedLazy var calendarManager: CalendarManager?
    private let cellReuseIdentifier = "CalendarFilterCell"
    private let disposeBag = DisposeBag()
    var finishChooseCalendars: (([String]) -> Void)?

    let barItem = LKBarButtonItem(image: UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24)), title: nil)
    let confirmBarItem = LKBarButtonItem(image: nil, title: BundleI18n.Calendar.Calendar_Common_Done)

    private let getAllCalendars: (() -> Observable<[[SidebarCellContent]]>)
    private var sidebarItems: [[SidebarCellContent]] = []
    private var lastChoosenCalendars: [String]?
    private let subscribeViewController: UIViewController
    private var needReloadData = true

    let userResolver: UserResolver

    init(calenderLoader: @escaping () -> Observable<[[SidebarCellContent]]>,
         subscribeViewController: UIViewController,
         userResolver: UserResolver) {
        self.getAllCalendars = calenderLoader
        self.subscribeViewController = subscribeViewController
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutNaviBar()
        layoutTableView(tableView: tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
        reloadData()
    }

    private func layoutNaviBar() {
        addCloseItem()
        title = BundleI18n.Calendar.Calendar_EventSearch_ChooseCal
    }

    private func layoutTopViews(view: UIView) -> UIView {
        let bar = UIView()
        bar.backgroundColor = UIColor.ud.bgBase
        view.addSubview(bar)
        bar.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(8)
        }

        let subscribeView = UIView()
        subscribeView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(subscribeView)
        subscribeView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(bar.snp.bottom)
            make.height.equalTo(52)
        }

        let subscribeButton = UIButton()
        subscribeButton.setImage(UDIcon.getIconByKey(.addnewOutlined,
                                                     renderingMode: .alwaysOriginal,
                                                     iconColor: UIColor.ud.primaryContentDefault,
                                                     size: CGSize(width: 24, height: 24)), for: .normal)
        subscribeButton.addTarget(self, action: #selector(subscribeClick), for: .touchUpInside)
        subscribeView.addSubview(subscribeButton)
        subscribeButton.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.width.equalTo(24)
            make.height.equalTo(24)
            make.top.bottom.equalToSuperview()
        }

        let subscribeLable = UILabel()
        subscribeLable.text = BundleI18n.Calendar.Calendar_SubscribeCalendar_SubscribeCalendars
        subscribeLable.font = UIFont.systemFont(ofSize: 16)
        subscribeLable.textColor = UIColor.ud.primaryContentDefault
        subscribeView.addSubview(subscribeLable)
        subscribeLable.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(48)
            make.top.bottom.equalToSuperview()
        }
        subscribeLable.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(subscribeClick))
        tapGesture.numberOfTapsRequired = 1
        subscribeLable.addGestureRecognizer(tapGesture)

        let lableWrapper = UIView()
        lableWrapper.backgroundColor = UIColor.ud.bgBase
        view.addSubview(lableWrapper)
        lableWrapper.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(subscribeView.snp.bottom)
            make.height.equalTo(40)
        }
        let subscribedView = UILabel()
        subscribedView.text = BundleI18n.Calendar.Calendar_EventSearch_Subscribed
        subscribedView.font = UIFont.systemFont(ofSize: 16)
        subscribedView.textColor = UIColor.ud.textPlaceholder
        lableWrapper.addSubview(subscribedView)
        subscribedView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview()
        }
        return lableWrapper
    }

    private func layoutTableView(tableView: UITableView) {
        self.view.addSubview(tableView)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.rowHeight = 44
        tableView.register(CalendarSidebarCell.self,
                           forCellReuseIdentifier: cellReuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.leastNonzeroMagnitude, height: CGFloat.leastNonzeroMagnitude))
    }

    private func addCloseItem() {
        barItem.button.addTarget(self, action: #selector(saveItemTapped), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = barItem
    }

    override func didMove(toParent parent: UIViewController?) {
        // 监听左滑返回事件只需要判断parent是否为空即可，空说明是左滑返回，不为空说明是刚进入
        if parent == nil {
            finishChosenCallback()
        }
        super.didMove(toParent: parent)
    }

    @objc
    private func subscribeClick() {
        needReloadData = true
        subscribeViewController.presentationController?.delegate = self
        self.present(subscribeViewController, animated: true, completion: nil)
    }

    @objc
    private func saveItemTapped() {
        finishChosenCallback()
        self.navigationController?.popViewController(animated: true)
    }

    private func finishChosenCallback() {
        let calendars = sidebarItems.flatMap { $0 }.filter { $0.isChecked }
        let calendarIds = calendars.map { sidebarCellContent -> String in
            return sidebarCellContent.id
        }

        if calendarIds != self.lastChoosenCalendars {
            // 对齐PC、Android：在搜索页面的筛选日历页面勾选日历等同于在日历管理页勾选日历，即返回视图页会显示刚才勾选的日历
            // 首次进入页面 self.lastChoosenCalendars 为空，不会走以下逻辑而是直接赋值
            if let lastChoosenCalendars = self.lastChoosenCalendars {
                for calendar in calendars where !lastChoosenCalendars.contains(calendar.id) {
                    calendarManager?.updateCalendarVisibility(serverId: calendar.id,
                                                             visibility: calendar.isChecked,
                                                             isLocal: calendar.type == .local)
                        .observeOn(MainScheduler.instance)
                        .subscribe(onNext: { (success) in
                            if !success, let window = self.userResolver.navigator.mainSceneWindow {
                                UDToast().showFailure(with: BundleI18n.Calendar.Calendar_Toast_FailedToLoad, on: window)
                            }
                        }, onError: { (error) in
                            if let window = self.userResolver.navigator.mainSceneWindow {
                                switch error.errorType() {
                                case .exceedMaxVisibleCalNum:
                                    UDToast.showFailure(with: I18n.Calendar_Detail_TooMuchViewReduce, on: window)
                                default:
                                    UDToast().showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Toast_FailedToLoad, on: window)
                                }
                            }
                        }).disposed(by: disposeBag)
                }
            }
            self.lastChoosenCalendars = calendarIds
            self.finishChooseCalendars?(calendarIds)
        }
    }

    func reloadData(needCallBack: Bool = false) {
        if !needReloadData {
            self.sidebarItems = self.sidebarItems.map { $0.sorted { $0.isChecked && !$1.isChecked } }
            self.tableView.reloadData()
            return
        }
        self.getAllCalendars()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (calendars) in
                guard let `self` = self else {
                    return
                }

                let preCheckedCalendarIds = self.sidebarItems.flatMap { $0 }.filter { $0.isChecked }.map { $0.id }

                let oldItems = self.sidebarItems.flatMap { $0.map { $0.id } }
                let newSubscribed = calendars.flatMap { $0 }.filter { !oldItems.contains($0.id) && $0.isChecked }.map { $0.id }

                self.sidebarItems = calendars.filter { $0.first != nil && $0.first?.type != .local }.map { sidebarCellContents -> [SidebarCellContent] in
                    return sidebarCellContents.map { sidebarCellContent -> SidebarCellContent in

                        if needCallBack {

                            var content = sidebarCellContent
                            if let chosenCalendars = self.lastChoosenCalendars {
                                if chosenCalendars.contains(content.id) {
                                    content.isChecked = true
                                } else if newSubscribed.contains(content.id) {
                                    content.isChecked = true
                                } else {
                                    content.isChecked = false
                                }
                            }
                            return content
                        } else {
                            // 这里是修复刷新时候不应该根据lastChoosenCalendars判断是否check，但是逻辑耦合太深，先else一下
                            var content = sidebarCellContent
                            if preCheckedCalendarIds.contains(content.id) {
                                content.isChecked = true
                            } else if newSubscribed.contains(content.id) {
                                content.isChecked = true
                            } else {
                                content.isChecked = false
                            }
                            return content
                        }

                    }.sorted { $0.isChecked && !$1.isChecked }
                }

                if needCallBack {
                    self.finishChosenCallback()
                }

                self.tableView.reloadData()
                }, onError: { [weak self] (error) in
                    guard let self = self else { return }
                    RoundedHUD.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_View_SyncListFailed, on: self.view)
            }).disposed(by: disposeBag)
        needReloadData = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.reloadData()
    }
}

extension CalendarFilterViewController: UITableViewDelegate, UITableViewDataSource {

    private func getCalendarBy(indexPath: IndexPath) -> SidebarCellContent? {
        guard indexPath.section < sidebarItems.count,
            indexPath.row < sidebarItems[indexPath.section].count else {
                return nil
        }
        return sidebarItems[indexPath.section][indexPath.row]
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let sidebarCell = tableView.cellForRow(at: indexPath) as? CalendarSidebarCell,
            indexPath.section < sidebarItems.count,
            indexPath.row < sidebarItems[indexPath.section].count else {
                return
        }
        var calendar = sidebarItems[indexPath.section][indexPath.row]
        calendar.isChecked = !calendar.isChecked
        sidebarItems[indexPath.section][indexPath.row] = calendar
        updateCell(cell: sidebarCell, data: calendar)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < sidebarItems.count, let firstItem = sidebarItems[section].first else {
            return 0
        }
        switch firstItem.type {
        case .google:
            return 64
        case .larkMine:
            return 144
        default:
            return 44
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 32
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < sidebarItems.count, let firstItem = sidebarItems[section].first else {
            return nil
        }

        switch firstItem.type {
        case .larkMine:
            let view = UIView()
            let bottomView = layoutTopViews(view: view)

            let sectionView = CalendarFilterHeaderCell(frame: CGRect.zero)
            sectionView.label.text = firstItem.sourceTitle
            view.addSubview(sectionView)
            sectionView.snp.makeConstraints { make in
                make.bottom.left.right.equalToSuperview()
                make.top.equalTo(bottomView.snp.bottom)
            }
            return view
        case .larkSubscribe:
            let sectionView = CalendarFilterHeaderCell(frame: CGRect.zero)
            sectionView.label.text = firstItem.sourceTitle
            return sectionView
        case .local:
            return CalendarSection(text: firstItem.sourceTitle, type: firstItem.type)
        case .google:
            return CalendarSection(text: firstItem.sourceTitle, type: firstItem.type)
        case .exchange:
            return CalendarSection(text: firstItem.sourceTitle, type: firstItem.type)
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < sidebarItems.count, sidebarItems[section].first != nil else {
            return nil
        }
        if section == tableView.numberOfSections - 1 { return nil }
        return CalendarFilterFooterCell(frame: CGRect.zero)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sidebarItems.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sidebarItems[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier,
                                                 for: indexPath)
        guard let model = getCalendarBy(indexPath: indexPath),
            let sidebarCell = cell as? CalendarSidebarCell else {
                return UITableViewCell()
        }
        updateCell(cell: sidebarCell, data: model)
        return sidebarCell
    }

    private func updateCell(cell: CalendarSidebarCell, data: SidebarCellContent) {
        cell.setupContent(model: data)
    }
}
