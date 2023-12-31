//
//  ParticipantSearchViewController.swift
//  ByteView
//
//  Created by Tobb Huang on 2022/11/21.
//

import Foundation
import Action
import RxSwift
import RxCocoa
import SnapKit
import ByteViewUI
import RxDataSources
import ByteViewCommon
import UIKit

final class ParticipantSearchViewController: VMViewController<ParticipantSearchViewModel>, UIGestureRecognizerDelegate {

    var isIPadLayout: BehaviorRelay<Bool> = BehaviorRelay(value: false)

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewModel.trackShowPanel()
    }

    override func bindViewModel() {
        super.bindViewModel()
        bindTableView()
        bindSearchView()
        bindMaskViewHidden()
    }

    // MARK: - Setup SubViews

    lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.View_G_CancelButton, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .regular)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.addTarget(self, action: #selector(doBack), for: .touchUpInside)
        return button
    }()

    fileprivate lazy var maskSearchViewTap = UITapGestureRecognizer()

    private lazy var searchResultMaskView: UIView = {
        let stackView = UIStackView(arrangedSubviews: [participantSearchHeaderView, resultBackgroundView])
        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.isHidden = true

        let backView = UIView(frame: stackView.bounds)
        backView.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.5)
        backView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        stackView.insertSubview(backView, at: 0)
        return stackView
    }()

    private lazy var searchView: SearchBarView = {
        let searchView = SearchBarView(frame: CGRect.zero, isNeedCancel: true)
        searchView.iconImageDimension = 16
        searchView.clipsToBounds = true
        searchView.setPlaceholder(I18n.View_M_Search)
        searchView.textField.accessibilityIdentifier =
            "ParticipantSearchViewController.searchView.accessibilityIdentifier"
        searchView.textField.accessibilityLabel =
            "ParticipantSearchViewController.searchView.accessibilityLabel"
        searchView.textField.isAccessibilityElement = true
        searchView.cancelButton.accessibilityIdentifier =
            "ParticipantSearchViewController.cancelButton.accessibilityIdentifier"
        searchView.cancelButton.isAccessibilityElement = true
        return searchView
    }()

    private lazy var participantSearchHeaderView: ParticipantSearchHeaderView = {
        let view = ParticipantSearchHeaderView(frame: .zero)
        view.isHidden = true
        return view
    }()

    private lazy var resultBackgroundView: UIView = {
        let view = UIView(frame: .zero)
        view.addGestureRecognizer(maskSearchViewTap)
        return view
    }()

    private lazy var searchResultView: SearchContainerView = {
        let searchContainerView = SearchContainerView(frame: .zero)
        searchContainerView.tableView.rowHeight = tableViewRowH
        searchContainerView.backgroundColor = UIColor.ud.bgBody
        searchContainerView.tableView.keyboardDismissMode = .none
        searchContainerView.tableView.backgroundColor = UIColor.ud.bgBody
        searchContainerView.tableView.separatorStyle = .none
        searchContainerView.tableView.keyboardDismissMode = .onDrag
        searchContainerView.tableView.delaysContentTouches = false
        searchContainerView.tableView.register(cellType: SearchParticipantCell.self)
        searchContainerView.isHidden = true
        // 屏蔽父视图tap响应
        let tapGesture = UITapGestureRecognizer()
        tapGesture.cancelsTouchesInView = false
        searchContainerView.addGestureRecognizer(tapGesture)
        return searchContainerView
    }()

    private lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: CGRect.zero, style: .plain)
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = tableViewRowH
        tableView.register(cellType: InMeetParticipantCell.self)
        tableView.register(cellType: InterpreterParticipantCell.self)
        return tableView
    }()

    override func setupViews() {
        title = viewModel.title

        if viewModel.leftNavItem == .button {
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: cancelButton)
        }

        view.addSubview(searchView)
        searchView.setContentCompressionResistancePriority(
            UILayoutPriority.required,
            for: NSLayoutConstraint.Axis.vertical
        )

        searchView.snp.makeConstraints { (make) in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(searchViewMarginTop)
            make.height.equalTo(searchViewHeight)
            make.left.equalTo(self.view.safeAreaLayoutGuide).offset(Layout.marginLeft)
            make.right.equalTo(self.view.safeAreaLayoutGuide).offset(-Layout.marginRight)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.bottom.equalToSuperview()
            make.top.equalTo(self.searchView.snp.bottom).offset(tableViewMarginSearchView)
            make.width.equalToSuperview()
        }
        tableView.sectionFooterHeight = tableViewMarginSearchView

        view.addSubview(searchResultMaskView)
        searchResultMaskView.snp.makeConstraints { (make) in
            make.left.bottom.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalTo(self.searchView.snp.bottom)
        }

        resultBackgroundView.addSubview(searchResultView)
        searchResultView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        searchResultView.tableView.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(tableViewMarginSearchView)
            make.left.right.bottom.equalToSuperview()
        }

        participantSearchHeaderView.snp.makeConstraints { (make) in
            make.height.equalTo(40)
        }

        self.tableView.rx.contentOffset.map({ [weak self] (offset) -> Bool in
            return offset.y <= self?.tableView.contentInset.top ?? 0
        })
        .distinctUntilChanged()
        .subscribe(onNext: { [weak self] forbidden in
            self?.tableView.bounces = !forbidden
        })
        .disposed(by: rx.disposeBag)
    }

    // MARK: - Layout

    private let topGap: CGFloat = 12.0
    private let regularTopGap: CGFloat = 25.0
    private let regularW: CGFloat = 375
    private let regularMaxH: CGFloat = 435

    private var titleLabelMarginTop: CGFloat {
        if Display.pad {
            return (20 - topGap)
        } else {
            return (12 - topGap)
        }
    }

    private let searchViewHeight: CGFloat = 36.0
    private let searchViewMarginTop: CGFloat = 8.0
    private let tableViewMarginSearchView: CGFloat = 8.0

    private let tableViewRowH: CGFloat = 64.0

    // MARK: - Action
    private func setupCellActions() {
        Observable.zip(
            tableView.rx.modelSelected(BaseParticipantCellModel.self),
            tableView.rx.itemSelected
        )
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] item, indexPath in
            guard let self = self else { return }
            self.tapParticipantCell(cellModel: item)
            self.tableView.deselectRow(at: indexPath, animated: true)
        })
        .disposed(by: rx.disposeBag)

        Observable.zip(
            searchResultView.tableView.rx.modelSelected(BaseParticipantCellModel.self),
            searchResultView.tableView.rx.itemSelected
        )
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] item, indexPath in
            guard let self = self, let cellModel = item as? SearchParticipantCellModel else { return }
            self.searchView.textField.resignFirstResponder()
            self.tapParticipantSearchCell(cellModel: cellModel)
            self.searchResultView.tableView.deselectRow(at: indexPath, animated: true)
        })
        .disposed(by: rx.disposeBag)
    }

    fileprivate func tapParticipantCell(cellModel: BaseParticipantCellModel) {
        if let cellModel = cellModel as? InMeetParticipantCellModel {
            viewModel.selectedClosure?(.init(type: .inMeet(cellModel.participant),
                                             name: cellModel.displayName,
                                             avatarInfo: cellModel.avatarInfo,
                                             searchVC: self))
        } else if let cellModel = cellModel as? InterpreterIdleParticipantCellModel,
                  let avatarInfo = cellModel.avatarInfo,
                  let displayName = cellModel.displayName {
            viewModel.selectedClosure?(.init(type: .idle(cellModel.idleInterpreter.user),
                                             name: displayName,
                                             avatarInfo: avatarInfo,
                                             searchVC: self))
        }
    }

    fileprivate func tapParticipantSearchCell(cellModel: SearchParticipantCellModel) {
        if let participant = cellModel.searchBox.participant {
            viewModel.selectedClosure?(.init(type: .inMeet(participant),
                                             name: cellModel.displayName,
                                             avatarInfo: cellModel.avatarInfo,
                                             searchVC: self))
        } else if let preInterpreter = viewModel.preInterpreters.first(where: { $0.user.id == cellModel.searchBox.id }) {
            viewModel.selectedClosure?(.init(type: .idle(preInterpreter.user),
                                             name: cellModel.displayName,
                                             avatarInfo: cellModel.avatarInfo,
                                             searchVC: self))
        }
    }

    fileprivate func bindMaskViewHidden() {
        self.searchView.editingDidBegin = { [weak self] _ in
            self?.searchResultMaskView.isHidden = false
        }
        self.searchView.editingDidEnd = { [weak self] isEmpty in
            self?.searchResultMaskView.isHidden = isEmpty
        }
        self.searchView.tapCancelButton = { [weak self] in
            self?.searchResultMaskView.isHidden = true
        }
        self.searchView.tapClearButton = { [weak self] isEditing in
            self?.searchResultMaskView.isHidden = !isEditing
        }
    }

    private func bindSearchView() {
        searchView.resultTextObservable
            .map { $0.isEmpty }
            .asDriver(onErrorJustReturn: true)
            .drive(searchResultView.rx.isHidden)
            .disposed(by: rx.disposeBag)

        searchView.clearButton.rx.tap
            .map { true }
            .asDriver(onErrorJustReturn: true)
            .drive(searchResultView.rx.isHidden)
            .disposed(by: rx.disposeBag)

        searchView.resultTextObservable
            .filter { !$0.isEmpty }
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .bind(onNext: viewModel.paginatedList.text.onNext)
            .disposed(by: rx.disposeBag)

        searchResultView.loadMoreObservable
            .bind(onNext: viewModel.paginatedList.loadNext.onNext)
            .disposed(by: rx.disposeBag)

        viewModel.paginatedList.result
            .map { $0.convert() }
            .observeOn(MainScheduler.instance)
            .bind(to: searchResultView.statusObserver)
            .disposed(by: rx.disposeBag)

        maskSearchViewTap.rx.event
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.searchView.resetSearchBar()
                self?.searchView.cancelButton.isHidden = true
                self?.searchResultMaskView.isHidden = true
            })
            .disposed(by: rx.disposeBag)
    }

    // MARK: - Handle Data
    private func bindTableView() {
        setupDataSource()
        setupCellActions()
    }

    private func setupDataSource() {
        viewModel.sectionModels
            .bind(to: tableView.rx.items(dataSource: generateDataSource()))
            .disposed(by: rx.disposeBag)

        let data = viewModel.paginatedList.result.startWith(.loading)
            .map({ [weak self] result -> [SearchParticipantCellModel] in
                guard let self = self else { return [] }
                switch result {
                case .loading, .noMatch: return []
                case let .results(items, _):
                    let hasCohostAuthority = self.viewModel.meeting.setting.hasCohostAuthority
                    let hostEnabled = self.viewModel.meeting.setting.isHostEnabled
                    let meetingSubType = self.viewModel.meeting.subType
                    return items.map { self.viewModel.createSearchCellModel($0, hasCohostAuthority: hasCohostAuthority, hostEnabled: hostEnabled, meetingSubType: meetingSubType) }
                }
            })

        data.map { [ParticipantSearchSectionModel(items: $0)] }
            .bind(to: searchResultView.tableView.rx.items(dataSource: generateSearchDataSource()))
            .disposed(by: rx.disposeBag)
    }

    private func generateDataSource() -> RxTableViewSectionedReloadDataSource<ParticipantSearchSectionModel> {
        let dataSource = RxTableViewSectionedReloadDataSource<ParticipantSearchSectionModel>(
            configureCell: { (_, tableView, indexPath, item) -> UITableViewCell in
                if item is InMeetParticipantCellModel {
                    let cell = tableView.dequeueReusableCell(withType: InMeetParticipantCell.self, for: indexPath)
                    cell.configure(with: item)
                    return cell
                } else if item is InterpreterIdleParticipantCellModel {
                    let cell = tableView.dequeueReusableCell(withType: InterpreterParticipantCell.self, for: indexPath)
                    cell.configure(with: item)
                    return cell
                }
                return UITableViewCell()
            })
        return dataSource
    }

    private func generateSearchDataSource() -> RxTableViewSectionedReloadDataSource<ParticipantSearchSectionModel> {
        let dataSource = RxTableViewSectionedReloadDataSource<ParticipantSearchSectionModel>(
            configureCell: { (_, tableView, indexPath, item) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withType: SearchParticipantCell.self, for: indexPath)
                cell.configure(with: item)
                return cell
            })
        return dataSource
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if searchResultMaskView.isHidden &&
            self.tableView.bounds.contains(gestureRecognizer.location(in: self.tableView)) {
            return self.tableView.contentOffset.y <= 1.0 + self.tableView.contentInset.top
        } else if !searchResultView.tableView.isHidden &&
                    searchResultView.tableView.bounds.contains(gestureRecognizer.location(in: searchResultView.tableView)) {
            return searchResultView.tableView.contentOffset.y <= 1.0 + searchResultView.tableView.contentInset.top
        } else {
            return true
        }
    }
}

extension ParticipantSearchViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        isIPadLayout.accept(isRegular)
    }
}

extension ParticipantSearchViewController {
    enum Layout {
        static var marginRight: CGFloat = 16
        static var marginLeft: CGFloat = 16
    }
}
