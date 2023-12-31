//
//  TimeZoneSearchSelectViewController.swift
//  iOS
//
//  Created by 张威 on 2020/1/8.
//

import UIKit
import LarkExtensions
import LarkUIKit
import LarkRustClient
import RxSwift
import RxCocoa

/// 选择时区：搜索->选择
final class TimeZoneSearchSelectViewController: UIViewController {

    var onTimeZoneSelect: ((TimeZoneModel) -> Void)?

    private lazy var disposeBag = DisposeBag()
    private let viewModel: SearchSelectTimeZoneViewModel
    private let cellReuseIdentifier = "Cell"
    private lazy var queryText: Driver<String?> = {
        queryView.textField.rx.text
            .map { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: nil)
    }()
    private typealias Action = Void
    private let queryAction = PublishSubject<Action>()
    private let focusAction = PublishSubject<Action>()
    private var validQueryText: String? { suggestionView.query }

    // MARK: Subviews

    // for input
    private lazy var queryView = TimeZoneSearchQueryView()

    // for suggestion
    private lazy var suggestionView = TimeZoneSearchSuggestionView()

    // for loading
    private lazy var loadingView = TimeZoneSearchLoadingView()

    // for loading failed (service unavailable)
    private lazy var searchFailedView = TimeZoneSearchFailedView()

    // for empty result
    private lazy var resultEmptyView = TimeZoneSearchResultEmptyView()

    // for valid data
    private lazy var resultTableView: UITableView = {
        let theView = UITableView(frame: .zero, style: .plain)
        theView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        theView.separatorColor = UIColor.ud.lineDividerDefault
        theView.dataSource = self
        theView.delegate = self
        theView.register(TimeZoneSearchResultCell.self, forCellReuseIdentifier: cellReuseIdentifier)
        theView.tableFooterView = UIView()
        return theView
    }()

    init(service: TimeZoneSelectService) {
        viewModel = SearchSelectTimeZoneViewModel(service: service)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        queryView.textField.becomeFirstResponder()
    }

    // MARK: Setup Views

    private func setupViews() {

        /// |---self.view
        ///     |---queryView
        ///     |---suggestionView
        ///     |---loadingView
        ///     |---resultTableView
        ///     |---resultEmptyView

        view.backgroundColor = UIColor.ud.bgBody

        // queryView
        queryView.textField.delegate = self
        queryView.cancelButton.rx.controlEvent(.touchUpInside)
            .subscribe(onNext: {[weak self] in
                self?.queryView.textField.resignFirstResponder()
                self?.popupViewController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        view.addSubview(queryView)
        queryView.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(50)
        }

        let seperatorLine = UIView()
        seperatorLine.backgroundColor = UIColor.ud.lineDividerDefault
        view.addSubview(seperatorLine)
        seperatorLine.snp.makeConstraints {
            $0.height.equalTo(0.5)
            $0.top.equalTo(queryView.snp.bottom)
            $0.left.right.equalToSuperview()
                .inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0))
        }

        // suggestionView
        queryText.drive(onNext: { [weak self] in
            self?.suggestionView.query = $0
        }).disposed(by: disposeBag)
        suggestionView.onQueryClick = { [weak self] in
            self?.queryAction.onNext(())
        }
        view.addSubview(suggestionView)
        suggestionView.snp.makeConstraints {
            $0.top.equalTo(seperatorLine.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
        }

        // loadingView
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints {
            $0.edges.equalTo(suggestionView)
        }

        view.addSubview(searchFailedView)
        searchFailedView.snp.makeConstraints {
            $0.edges.equalTo(suggestionView)
        }

        // resultTableView
        view.addSubview(resultTableView)
        resultTableView.snp.makeConstraints {
            $0.edges.equalTo(suggestionView)
        }

        // resultEmptyView
        view.addSubview(resultEmptyView)
        resultEmptyView.snp.makeConstraints {
            $0.edges.equalTo(suggestionView)
        }

        // 处理与 PopupViewController 的交互手势冲突
        if let gesture = popupViewController?.interactivePopupGestureRecognizer {
            resultTableView.panGestureRecognizer.require(toFail: gesture)
        }
    }

    private func bindData() {
        viewModel.onTimeZoneSelect = onTimeZoneSelect

        // 编辑事件
        focusAction.subscribe(onNext: { [weak self] _ in
            self?.handleFocusing()
        }).disposed(by: disposeBag)

        // 查询事件
        queryAction.subscribe(onNext: { [weak self] _ in
            self?.handleQuering()
        }).disposed(by: disposeBag)

        // loading 处理
        viewModel.isLoading.distinctUntilChanged().subscribe(onNext: { [weak self] _ in
            self?.handleLoading()
        }).disposed(by: disposeBag)

        // query result 处理
        viewModel.lastQueryResult.subscribe(onNext: { [weak self] _ in
            self?.handleResult()
        }).disposed(by: disposeBag)
    }

}

// MARK: Event Response

extension TimeZoneSearchSelectViewController {

    private func handleFocusing() {
        self.viewModel.cancelLoadingIfNeeded()
        self.viewModel.clearResultIfNeeded()
        self.suggestionView.isHidden = false
        self.view.bringSubviewToFront(self.suggestionView)
    }

    private func handleQuering() {
        guard let query = self.validQueryText,
            !query.isEmpty else {
                return
        }

        self.queryView.textField.resignFirstResponder()
        self.suggestionView.isHidden = true
        self.viewModel.clearResultIfNeeded()
        self.viewModel.reloadCellItems(by: query)
    }

    private func handleLoading() {
        if viewModel.isLoading.value {
            self.loadingView.isHidden = false
            self.loadingView.indicatorView.startAnimating()
            self.view.bringSubviewToFront(self.loadingView)
        } else {
            self.loadingView.isHidden = true
            self.loadingView.indicatorView.stopAnimating()
        }
    }

    private func handleResult() {
        self.resultTableView.reloadData()

        guard let result = viewModel.lastQueryResult.value else {
            self.resultEmptyView.isHidden = true
            self.resultTableView.isHidden = true
            self.searchFailedView.isHidden = true
            return
        }

        switch result.result {
        case .empty:
            self.resultEmptyView.isHidden = false
            self.resultTableView.isHidden = true
            self.searchFailedView.isHidden = true
            self.view.bringSubviewToFront(self.resultEmptyView)
        case .items:
            self.resultEmptyView.isHidden = true
            self.resultTableView.isHidden = false
            self.searchFailedView.isHidden = true
            self.view.bringSubviewToFront(self.resultTableView)
        case .error:
            self.resultEmptyView.isHidden = true
            self.resultTableView.isHidden = true
            self.searchFailedView.isHidden = false
            self.view.bringSubviewToFront(self.searchFailedView)
        }
    }

}

extension TimeZoneSearchSelectViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        focusAction.onNext(())
        guard let text = textField.text, !text.isEmpty else { return }
        let endDocument = textField.endOfDocument
        guard let endPosition = textField.position(from: endDocument, offset: 0),
            let startPosition = textField.position(from: endPosition, offset: -text.count) else {
                return
        }
        textField.selectedTextRange = textField.textRange(from: startPosition, to: endPosition)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        queryAction.onNext(())
        return true
    }

}

// MARK: UITableViewDataSource & UITableViewDelegate

extension TimeZoneSearchSelectViewController: UITableViewDataSource & UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfRows()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        guard let timeZoneCell = cell as? TimeZoneSearchResultCell else {
            return cell
        }
        timeZoneCell.viewData = viewModel.cellData(forRowAt: indexPath)
        return timeZoneCell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 88 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: false)
        viewModel.selectCellData(forRowAt: indexPath)
    }

}

// MARK: Support Popup

extension TimeZoneSearchSelectViewController: PopupViewControllerItem {

    var preferredPopupOffset: PopupOffset { .full }
    var hoverPopupOffsets: [PopupOffset] { [preferredPopupOffset] }

    func shouldBeginPopupInteracting(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let popupViewController = popupViewController,
            interactivePopupGestureRecognizer == popupViewController.interactivePopupGestureRecognizer,
            let panGesture = interactivePopupGestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        if queryView.textField.isFirstResponder {
            queryView.textField.resignFirstResponder()
        }
        guard abs(popupViewController.currentPopupOffset.rawValue - hoverPopupOffsets.last!.rawValue) < 0.01 else {
            return true
        }
        // 上滑
        let velocity = panGesture.velocity(in: panGesture.view)
        if velocity.y < 0 {
            return false
        }
        // 下滑
        if velocity.y > 0 && resultTableView.contentOffset.y > 0.1 {
            return false
        }
        return true
    }

}
