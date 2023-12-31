//
//  TimeZoneQuickSelectViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/1/8.
//  Copyright © 2020 SadJason. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import LarkExtensions
import EENavigator
import CTFoundation
import UniverseDesignFont
import LarkUIKit

/// 选择时区：快速选择
final class TimeZoneQuickSelectViewController: UIViewController {

    typealias ViewModel = TimeZoneQuickSelectViewModel

    typealias TimeZoneSelectHandler = (TimeZoneModel, ViewModel.TimeZoneSelectHandler.Reason) -> Void

    /// 搜索框被点击，push 搜索页
    public typealias SearchViewController = PopupViewControllerItem
    public typealias SearchViewControllerMaker = () -> SearchViewController
    public var onTimeZoneSelect: TimeZoneSelectHandler?

    private static let cellReuseIdentifier = "Cell"

    private lazy var searchBar: UIButton = {
        let theView = UIButton()

        let textField = SearchTextField()
        textField.placeholder = BundleI18n.Calendar.Calendar_Timezone_Search
        textField.isUserInteractionEnabled = false
        theView.addSubview(textField)
        textField.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        theView.backgroundColor = UIColor.ud.bgBody
        theView.layer.cornerRadius = 8
        return theView
    }()

    private lazy var tableView: UITableView = {
        let theView = UITableView(frame: .zero, style: .plain)
        theView.separatorStyle = .none
        theView.dataSource = self
        theView.delegate = self
        theView.register(TimeZoneQuickSelectCell.self, forCellReuseIdentifier: Self.cellReuseIdentifier)
        theView.tableFooterView = UIView()
        theView.backgroundColor = UIColor.ud.bgBody
        return theView
    }()

    private lazy var recentTimeZoneTitleView: UIView = {
        let theView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 32))

        let clearButton = UIButton()
        clearButton.setTitle(BundleI18n.Calendar.Calendar_Timezone_ClearAll, for: .normal)
        clearButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        clearButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        clearButton.sizeToFit()
        clearButton.addTarget(self, action: #selector(deleteAllCellData), for: .touchUpInside)
        theView.addSubview(clearButton)
        clearButton.snp.makeConstraints {
            $0.right.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(8)
        }

        let titleLabel = UILabel()
        titleLabel.text = BundleI18n.Calendar.Calendar_Timezone_Recent
        titleLabel.font = UDFont.body2
        titleLabel.textColor = UIColor.ud.textPlaceholder
        theView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.left.equalToSuperview().inset(16)
            $0.right.equalTo(clearButton)
            $0.height.equalToSuperview()
            $0.top.equalToSuperview().inset(8)
        }

        theView.backgroundColor = UIColor.ud.bgBody
        return theView
    }()

    private var selectedIndexPath: IndexPath?
    private let disposeBag = DisposeBag()

    private let searchViewControllerMaker: SearchViewControllerMaker
    private let viewModel: TimeZoneQuickSelectViewModel

    init(
        service: TimeZoneSelectService,
        selectedTimeZone: BehaviorRelay<TimeZoneModel>,
        anchorDate: Date,
        searchViewControllerMaker: @escaping SearchViewControllerMaker
    ) {
        self.searchViewControllerMaker = searchViewControllerMaker
        viewModel = TimeZoneQuickSelectViewModel(service: service, selectedTimeZone: selectedTimeZone, anchorDate: anchorDate)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()

        bindData()
    }

    private func setupViews() {
        view.backgroundColor = UIColor.ud.bgBody
        self.popupViewController?.foregroundColor = UIColor.ud.bgBody

        searchBar.rx.controlEvent(.touchUpInside).subscribe(onNext: { [weak self] in
            self?.showSearchViewController()
        }).disposed(by: disposeBag)
        view.addSubview(searchBar)
        searchBar.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(16)
            $0.top.equalToSuperview().inset(8)
            $0.height.equalTo(34)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(10)
            $0.left.right.bottom.equalToSuperview()
        }

        if let gesture = popupViewController?.interactivePopupGestureRecognizer {
            tableView.panGestureRecognizer.require(toFail: gesture)
        }
    }

    private func bindData() {
        viewModel.onTimeZoneSelect = ViewModel.TimeZoneSelectHandler { [weak self] (timeZone, reason) in
            self?.onTimeZoneSelect?(timeZone, reason)
        }
        viewModel.onTableViewDataUpdate = tableView.reloadData
    }
}

// MARK: UITableViewDataSource & UITableViewDelegate

extension TimeZoneQuickSelectViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.numberOfSections()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows(in: section)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellReuseIdentifier, for: indexPath)
        guard let timeZoneCell = cell as? TimeZoneQuickSelectCell else { return cell }
        timeZoneCell.viewData = viewModel.cellData(forRowAt: indexPath)
        return timeZoneCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 72 }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 1 else { return nil }
        return recentTimeZoneTitleView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 1 else { return CGFloat.leastNormalMagnitude }
        return 34
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectCellData(forRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == 1 else { return false }
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard indexPath.section == 1 else { return .none }
        return .delete
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        BundleI18n.Calendar.Calendar_Common_Delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, indexPath.section == 1 else { return }
        deleteCellData(forRowAt: indexPath)
    }

}

// MARK: Event Response

extension TimeZoneQuickSelectViewController {

    @objc
    private func deleteAllCellData() {
        viewModel.deleteAllCellData()
    }

    private func deleteCellData(forRowAt indexPath: IndexPath) {
        viewModel.deleteCellData(forRowAt: indexPath)
    }

    private func selectCellData(forRowAt indexPath: IndexPath) {
        viewModel.selectCellData(forRowAt: indexPath)
    }

    private func showSearchViewController() {
        let searchVC = self.searchViewControllerMaker()
        self.popupViewController?.pushViewController(searchVC, animated: true)
    }
}

// MARK: Support Popup

extension TimeZoneQuickSelectViewController: PopupViewControllerItem {

    var naviBarTitle: String {
        return BundleI18n.Calendar.Calendar_Timezone_SelectTimeZone
    }

    var naviBarBackgroundColor: UIColor { UIColor.ud.bgBody }

    var preferredPopupOffset: PopupOffset {
        if Display.pad {
            return PopupOffset(rawValue: 0.6)
        } else {
            let preferredHeight = Popup.Const.defaultPresentHeight
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

        // 左滑 or 右滑
        if abs(velocity.x) > abs(velocity.y) {
            return false
        }

        guard abs(popupViewController.currentPopupOffset.rawValue - hoverPopupOffsets.last!.rawValue) < 0.01 else {
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
