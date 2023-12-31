//
//  TimeZoneQuickSelectViewController.swift
//  LarkMail
//
//  Created by majx on 2020/12/13 from Calendar/TimeZone.
//

import UIKit
import RxSwift
import RxCocoa
import LarkExtensions

/// 选择时区：快速选择
final class TimeZoneQuickSelectViewController: UIViewController {

    typealias ViewModel = TimeZoneQuickSelectViewModel

    typealias TimeZoneSelectHandler = (TimeZoneModel, ViewModel.TimeZoneSelectHandler.Reason) -> Void

    /// 搜索框被点击，push 搜索页
    typealias SearchViewController = PopupViewControllerItem
    typealias SearchViewControllerMaker = () -> SearchViewController
    var onTimeZoneSelect: TimeZoneSelectHandler?

    private static let cellReuseIdentifier = "TimeZoneCell"
    private var selectedIndexPath: IndexPath?
    private let disposeBag = DisposeBag()

    private let searchViewControllerMaker: SearchViewControllerMaker
    private let viewModel: TimeZoneQuickSelectViewModel

    // Views
    private lazy var searchBar: UIButton = {
        let theView = UIButton()
        let textField = SearchTextField()
         textField.placeholder = BundleI18n.MailSDK.Mail_Timezone_Search
        textField.isUserInteractionEnabled = false
        theView.addSubview(textField)
        textField.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        return theView
    }()

    private lazy var seperatorLineView: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineBorderCard
        return line
    }()

    private lazy var tableView: UITableView = {
        let theView = UITableView(frame: .zero, style: .plain)
        theView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        theView.separatorColor = UIColor.ud.lineBorderCard
        theView.dataSource = self
        theView.delegate = self
        theView.register(TimeZoneQuickSelectCell.self, forCellReuseIdentifier: Self.cellReuseIdentifier)
        theView.tableFooterView = UIView()
        return theView
    }()

    init(service: TimeZoneSelectService,
         selectedTimeZone: BehaviorRelay<TimeZoneModel>,
         searchViewControllerMaker: @escaping SearchViewControllerMaker) {
        self.searchViewControllerMaker = searchViewControllerMaker
        viewModel = TimeZoneQuickSelectViewModel(service: service, selectedTimeZone: selectedTimeZone)
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

    private func bindData() {
        viewModel.onTimeZoneSelect = ViewModel.TimeZoneSelectHandler { [weak self] (timeZone, reason) in
            self?.onTimeZoneSelect?(timeZone, reason)
        }
        viewModel.onTableViewDataUpdate = tableView.reloadData
    }

    private func setupViews() {
        view.backgroundColor = UIColor.ud.bgBody

        searchBar.rx.controlEvent(.touchUpInside)
        .subscribe(onNext: { [weak self] in
            self?.showSearchViewController()
        }).disposed(by: disposeBag)

        view.addSubview(searchBar)
        searchBar.snp.makeConstraints {
            $0.top.equalToSuperview().offset(4)
            $0.left.right.equalToSuperview().inset(16)
            $0.height.equalTo(34)
        }

        view.addSubview(seperatorLineView)
        seperatorLineView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(12)
            $0.left.right.equalToSuperview()
            $0.height.equalTo(0.5)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            $0.top.equalTo(seperatorLineView.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
        }

        if let gesture = popupViewController?.interactivePopupGestureRecognizer {
            tableView.panGestureRecognizer.require(toFail: gesture)
        }
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

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 68 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        selectCellData(forRowAt: indexPath)
    }
}

// MARK: Event Response

extension TimeZoneQuickSelectViewController {
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

    var preferredPopupOffset: PopupOffset {
        let preferredHeight = 327 + Display.bottomSafeAreaHeight
        let containerHeight = (popupViewController?.contentHeight ?? UIScreen.main.bounds.height)
        return PopupOffset(rawValue: preferredHeight / containerHeight)
    }

    var hoverPopupOffsets: [PopupOffset] {
        [preferredPopupOffset, .full]
    }

    func shouldBeginPopupInteracting(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool {
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

}
