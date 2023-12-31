//
//  ChatterPickerViewController.swift
//  LarkChat
//
//  Created by qihongye on 2019/7/25.
//

import UIKit
import EENavigator
import Foundation
import LarkCore
import LarkModel
import LarkUIKit
import RxSwift
import UniverseDesignToast
import LKCommonsLogging
import LarkSDKInterface
import LarkContainer

final class ChatterPickerViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {
    private let logger = Logger.log(ChatterPickerViewController.self, category: "Module.Search.ChatterPickerViewController")

    private let disposeBag = DisposeBag()

    private let viewModel: GroupChatterPickWithSearchViewModel
    private var datas: [ChatChatterSection] = []
    private let isMulti: Bool
    private let isPopup: Bool

    private var singleSelectIndex: IndexPath?
    private var tapOutsideGesture: UITapGestureRecognizer?

    private lazy var searchWrapper: SearchUITextFieldWrapperView = {
        return SearchUITextFieldWrapperView()
    }()

    private var searchTextField: SearchUITextField {
        return searchWrapper.searchUITextField
    }

    private lazy var tableView: ChatChatterBaseTable = {
        return ChatChatterBaseTable(frame: .zero, style: .plain)
    }()

    private lazy var bottomCoverView: ChatterListBottomTipView = {
        let view = ChatterListBottomTipView(frame: ChatterListBottomTipView.defaultFrame(self.view.bounds.width))
        view.title = BundleI18n.LarkSearch.Lark_Group_HugeGroup_MemberList_Bottom
        return view
    }()

    private lazy var navBar: UIView = {
        let container = UIView()
        container.backgroundColor = UIColor.ud.bgBody
        container.clipsToBounds = true
        container.layer.cornerRadius = 8
        container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return container
    }()

    var confirmSelect: (([Chatter]) -> Void)?

    init(viewModel: GroupChatterPickWithSearchViewModel, isMulti: Bool = false, isPopup: Bool = false) {
        self.viewModel = viewModel
        self.isMulti = isMulti
        self.isPopup = isPopup
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = isPopup ? .clear : UIColor.ud.bgBody

        tableView.estimatedRowHeight = 68
        tableView.rowHeight = 68
        tableView.sectionIndexBackgroundColor = UIColor.clear
        tableView.sectionIndexColor = UIColor.ud.textTitle
        tableView.lu.register(cellSelf: ChatChatterCell.self)
        tableView.lu.register(cellSelf: UITableViewCell.self)
        tableView.register(ContactTableHeader.self,
                           forHeaderFooterViewReuseIdentifier: String(describing: ContactTableHeader.self))
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        var searchTopConstraintItem = view.snp.top
        if isMulti {
            setupNavBar()
            searchTopConstraintItem = navBar.snp.bottom
        }
        searchTextField.canEdit = true
        searchTextField.placeholder = BundleI18n.LarkSearch.Lark_Legacy_Search
        view.addSubview(searchWrapper)
        searchWrapper.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(searchTopConstraintItem)
        }
        tableView.snp.makeConstraints { (make) in
            make.bottom.leading.trailing.equalToSuperview()
            make.top.equalTo(searchWrapper.snp.bottom)
        }

        addObserver()
        self.viewModel.loadFirstScreen()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateContentSizeForPopup()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isMulti && tapOutsideGesture == nil {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
            tapGesture.cancelsTouchesInView = false
            view.window?.addGestureRecognizer(tapGesture)
            tapOutsideGesture = tapGesture
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let tapOutsideGesture = tapOutsideGesture {
            view.window?.removeGestureRecognizer(tapOutsideGesture)
            self.tapOutsideGesture = nil
        }
    }

    func addObserver() {
        searchTextField.rx.text.asDriver().skip(1)
            .distinctUntilChanged({ (str1, str2) -> Bool in
                return str1 == str2
            })
            .debounce(.milliseconds(300))
            .drive(onNext: { [weak self] (text) in
                self?.viewModel.loadFilterData(matchText: text ?? "")
            }).disposed(by: disposeBag)

        viewModel.statusVar.drive(onNext: { [weak self] (status) in
            self?.changeViewStatus(status)
        }).disposed(by: disposeBag)

        viewModel.canSearch
            .distinctUntilChanged({ $0 == $1 })
            .drive(onNext: { [weak self] (canSearch) in
                guard let self = self else {
                    return
                }
                self.searchWrapper.isHidden = !canSearch
                self.updateTableViewConstraint()
            })
            .disposed(by: disposeBag)
    }

    private func refreshFotterView() {
        tableView.tableFooterView = viewModel.shouldShowTipView && !viewModel.isInSearch ? bottomCoverView : UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 1))
    }

    private func changeViewStatus(_ status: ChatChatterViewStatus) {
        switch status {
        case .loading:
            loadingPlaceholderView.isHidden = false
        case .error(let error):
            loadingPlaceholderView.isHidden = true
            tableView.status = viewModel.chatterSectionsData.isEmpty ? .empty : .display

            if let error = error.underlyingError as? APIError {
                switch error.type {
                case .noSecretChatPermission(let message):
                    UDToast.showFailure(with: message, on: self.view, error: error)
                default:
                    UDToast.showFailure(with: BundleI18n.LarkSearch.Lark_Legacy_ErrorMessageTip, on: self.view, error: error)
                }
            }

            logger.error("load data error", error: error)
        case .viewStatus(let status):
            datas = viewModel.chatterSectionsData
            loadingPlaceholderView.isHidden = true
            tableView.status = status

            // 取出上拉加载更多
            tableView.removeBottomLoadMore()
            tableView.reloadData()

            // 非搜索态，且有更多数据则添加上拉加载更多
            if !viewModel.isInSearch, let cursor = viewModel.cursor, !cursor.isEmpty {
                tableView.addBottomLoadMoreView(infiniteScrollActionImmediatly: false) { [weak self] in
                    self?.viewModel.loadMoreData()
                }
            }
            self.refreshFotterView()
            updateContentSizeForPopup()
        }
    }

    private func updateContentSizeForPopup() {
        if !isPopup {
            return
        }
        var height = 0.0, originY = 0.0
        let navBarHeight = isMulti ? 56.0 : 0
        for section in datas {
            if let title = section.title, !title.isEmpty {
                height += 30
            }
            height += (68 * Double(section.items.count))
        }
        if let window = view.window {
            let maxHeight = window.bounds.height - navBarHeight - window.safeAreaInsets.top
            height = min(height + window.safeAreaInsets.bottom, maxHeight) + navBarHeight
            originY = window.bounds.height - height
        }

        if let popoverVC = popoverPresentationController,
           UIDevice.current.userInterfaceIdiom == .pad {
            preferredContentSize = CGSize(width: tableView.bounds.width, height: height)
            switch popoverVC.arrowDirection {
            case .up:
                if isMulti {
                    navBar.snp.remakeConstraints { make in
                        make.top.equalToSuperview().offset(12)
                        make.leading.trailing.equalToSuperview()
                        make.height.equalTo(56)
                    }
                } else {
                    searchWrapper.snp.remakeConstraints { make in
                        make.top.equalToSuperview().offset(12)
                        make.leading.trailing.equalToSuperview()
                    }
                }
            default:
                break
            }
            updateTableViewConstraint()
        } else {
            view.frame = CGRect(x: 0, y: originY, width: view.bounds.width, height: height)
        }
    }

    private func updateTableViewConstraint() {
        var bottomOffset = 0.0
        if isPopup, UIDevice.current.userInterfaceIdiom == .pad,
           let popArrowDir = popoverPresentationController?.arrowDirection, popArrowDir == .down {
            bottomOffset = 12
        }
        tableView.snp.remakeConstraints({ make in
            make.top.equalTo(searchWrapper.isHidden ? searchWrapper.snp.top : searchWrapper.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-bottomOffset)
        })
    }

    private func setupNavBar() {
        view.addSubview(navBar)
        navBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(56)
        }
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.text = viewModel.navibarTitle
        navBar.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        let closeBtn = UIButton()
        closeBtn.setImage(BundleResources.LarkSearch.navigation_close_outlined, for: .normal)
        closeBtn.addTarget(self, action: #selector(dismissController), for: .touchUpInside)
        navBar.addSubview(closeBtn)
        closeBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        let confirmBtn = UIButton()
        confirmBtn.setTitle(BundleI18n.LarkSearch.Lark_Legacy_Sure, for: .normal)
        confirmBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        confirmBtn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        confirmBtn.addTarget(self, action: #selector(confirmBtnTapped), for: .touchUpInside)
        navBar.addSubview(confirmBtn)
        confirmBtn.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    @objc
    private func tapped(_ sender: UITapGestureRecognizer) {
        if !tableView.frame.contains(sender.location(in: view)) {
            dismiss(animated: true)
        }
    }

    @objc
    private func dismissController() {
        dismiss(animated: true)
    }

    @objc
    private func confirmBtnTapped() {
        confirmSelect?(viewModel.selectedChatters)
        dismiss(animated: true)
    }

    // MARK: - UITableViewDelegate
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if self.searchTextField.canResignFirstResponder == true {
            self.searchTextField.resignFirstResponder()
        }
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // 抹掉背景
        tableView.deselectRow(at: indexPath, animated: true)

        // 取出对应的Cell & Item
        guard let cell = tableView.cellForRow(at: indexPath) as? ChatChatterCellProtocol,
              let item = cell.item,
              let chatter = item.itemUserInfo as? Chatter else {
            return
        }

        if isMulti {
            cell.setCellSelect(canSelect: true, isSelected: !cell.isCheckboxSelected, isCheckboxHidden: false)
            viewModel.selectChatter(chatter: chatter, select: cell.isCheckboxSelected)
        } else {
            if let singleSelectIndex = singleSelectIndex,
               singleSelectIndex != indexPath,
               let lastSelectCell = tableView.cellForRow(at: singleSelectIndex) as? ChatChatterCellProtocol {
                lastSelectCell.setCellSelect(canSelect: false, isSelected: false, isCheckboxHidden: true)
            }
            confirmSelect?([chatter])
            dismiss(animated: true)
        }
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section >= datas.count || datas[section].title?.isEmpty ?? true || datas[section].title == nil {
            return 0
        }

        return 30
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section < datas.count {
            let sectionItem = datas[section]
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: String(describing: sectionItem.sectionHeaderClass))
            (header as? ChatChatterSectionHeaderProtocol)?.set(sectionItem)
            return header
        }
        return nil
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return viewModel.shouldShowTipView ? nil : datas.map { $0.indexKey }
    }
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return datas.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < datas.count else { return 0 }
        return datas[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section >= datas.count || indexPath.row >= datas[indexPath.section].items.count {
            return tableView.dequeueReusableCell(withIdentifier: UITableViewCell.lu.reuseIdentifier, for: indexPath)
        }

        let item = datas[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: item.itemCellClass),
            for: indexPath
        )

        if var itemCell = cell as? ChatChatterCellProtocol {
            itemCell.set(item, filterKey: viewModel.filterKey, userResolver: Container.shared.getCurrentUserResolver())
            let isSelected = viewModel.selectedChatters.contains { $0.id == item.itemId }

            if isMulti {
                itemCell.setCellSelect(canSelect: true, isSelected: isSelected, isCheckboxHidden: false)
            } else {
                itemCell.isCheckboxHidden = true
            }

            if isSelected && !isMulti {
                singleSelectIndex = indexPath
            }
        }

        return cell
    }
}
