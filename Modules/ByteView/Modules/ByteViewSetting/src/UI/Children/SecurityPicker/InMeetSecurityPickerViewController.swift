//
//  InMeetSecurityUserPickerViewController.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/9.
//

import Foundation
import ByteViewCommon
import ByteViewUI
import UniverseDesignToast
import ByteViewNetwork
import ByteViewTracker

final class InMeetSecurityPickerViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate {
    let viewModel: InMeetSecurityPickerViewModel
    private var selectedCount: Int = -1
    private var rows: [InMeetSecurityPickerRow] = []
    private var searchRows: [InMeetSecurityPickerRow] = []

    private weak var loadingView: UDToast?
    lazy var searchView = SearchBarView()
    lazy var maskSearchViewTap = UITapGestureRecognizer(target: self, action: #selector(didCancelSearch(_:)))
    lazy var resultBackgroundView: UIView = {
        let resultBackgroundView = UIView(frame: .zero)
        resultBackgroundView.addGestureRecognizer(maskSearchViewTap)
        resultBackgroundView.backgroundColor = UIColor.ud.bgBody
        resultBackgroundView.isHidden = true
        return resultBackgroundView
    }()

    lazy var tableView: BaseTableView = {
        let tableView = BaseTableView(frame: CGRect.zero, style: .plain)
        tableView.backgroundColor = UIColor.clear
        tableView.rowHeight = 72
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .ud.lineDividerDefault
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        return tableView
    }()

    private lazy var bottomView = InMeetSecuritySelectBottomView()

    private lazy var searchResultView: InMeetSecuritySearchContainerView = {
        let searchResult = InMeetSecuritySearchContainerView()
        searchResult.tableView.backgroundColor = UIColor.clear
        searchResult.tableView.rowHeight = 72
        searchResult.tableView.separatorStyle = .singleLine
        searchResult.tableView.separatorColor = .ud.lineDividerDefault
        searchResult.tableView.tableFooterView = UIView(frame: CGRect.zero)
        return searchResult
    }()

    init(setting: MeetingSettingManager) {
        self.viewModel = InMeetSecurityPickerViewModel(setting: setting)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = I18n.View_G_SelectContactGroupRoom

        view.backgroundColor = .ud.bgBody
        view.addSubview(searchView)
        view.addSubview(tableView)
        view.addSubview(resultBackgroundView)
        view.addSubview(bottomView)

        searchView.textField.attributedPlaceholder = NSAttributedString(string: I18n.View_G_SearchContactGroupRoom, config: .bodyAssist)
        searchView.snp.makeConstraints { (maker) in
            maker.height.equalTo(54)
            maker.top.left.right.equalTo(view.safeAreaLayoutGuide)
        }

        tableView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(searchView.snp.bottom)
            maker.bottom.equalTo(bottomView.snp.top)
        }

        resultBackgroundView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(searchView.snp.bottom)
            maker.bottom.equalTo(bottomView.snp.top)
        }

        bottomView.snp.makeConstraints { maker in
            maker.left.right.equalTo(view)
            maker.height.equalTo(52)
            maker.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
            maker.bottom.lessThanOrEqualTo(view.vc.keyboardLayoutGuide.snp.top)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).priority(.high)
            maker.bottom.equalTo(view.vc.keyboardLayoutGuide.snp.top).priority(.high)
        }

        resultBackgroundView.addSubview(searchResultView)
        searchResultView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        let cellTypes: [InMeetSecurityPickerCellIdentifier] = [.user, .room, .group, .calendar, .calendarHeader]
        cellTypes.forEach {
            self.tableView.register($0.cellType, forCellReuseIdentifier: $0.identifier)
            self.searchResultView.tableView.register($0.cellType, forCellReuseIdentifier: $0.identifier)
        }

        self.tableView.tag = .tableView
        self.searchResultView.tableView.tag = .searchTableView
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.searchResultView.tableView.dataSource = self
        self.searchResultView.tableView.delegate = self
        self.viewModel.delegate = self
        self.viewModel.search.delegate = self

        self.searchView.textDidChange = { [weak self] in
            self?.updateSearchKey($0)
        }

        self.searchResultView.tableView.loadMoreDelegate?.addBottomLoading { [weak self] in
            self?.viewModel.search.loadMore()
        }

        self.searchView.cancelButton.addTarget(self, action: #selector(didCancelSearch(_:)), for: .touchUpInside)
        self.searchView.textField.addTarget(self, action: #selector(didBeginEditing(_:)), for: .editingDidBegin)
        self.bottomView.sureButton.addTarget(self, action: #selector(didClickSave), for: .touchUpInside)
        self.bottomView.selectedButton.addTarget(self, action: #selector(didClickSelectedCount), for: .touchUpInside)
        VCTracker.post(name: .vc_entry_auth_choose_view)
    }

    override func viewDidFirstAppear(_ animated: Bool) {
        super.viewDidFirstAppear(animated)
        if self.viewModel.isLoading {
            self.loadingView = UDToast.showLoading(with: I18n.View_VM_Loading, on: self.view)
        } else {
            self.reloadData(isSearch: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        VCTracker.post(name: .vc_entry_auth_choose_view)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        VCTracker.post(name: .vc_entry_auth_choose_click, params: [.click: "close"])
    }

    override func doBack() {
        super.doBack()
        VCTracker.post(name: .vc_entry_auth_choose_click, params: [.click: "close"])
    }

    func reloadData(isSearch: Bool, shouldReload: Bool = true) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            if isSearch {
                if shouldReload {
                    self.searchRows = self.viewModel.buildSearchRows()
                    self.searchResultView.tableView.reloadData()
                }
                if self.searchRows.isEmpty {
                    self.searchResultView.update(.noResult)
                } else {
                    self.searchResultView.update(.result(self.viewModel.search.hasMore))
                }
            } else {
                if shouldReload {
                    self.rows = self.viewModel.buildRows()
                    self.tableView.reloadData()
                }
            }
            let selectedCount = self.viewModel.selectedCount
            if self.selectedCount != selectedCount {
                self.selectedCount = selectedCount
                UIView.performWithoutAnimation {
                    self.bottomView.selectedButton.setTitle("\(I18n.View_M_Selected)\(selectedCount)", for: .normal)
                    self.bottomView.selectedButton.isEnabled = selectedCount > 0
                    self.bottomView.sureButton.isEnabled = selectedCount > 0
                    self.bottomView.selectedButton.layoutIfNeeded()
                }
            }
        }
    }

    @objc private func didClickSave() {
        VCTracker.post(name: .vc_entry_auth_choose_click, params: [.click: "confirm", .shareNum: self.viewModel.selectedCount])
        self.viewModel.saveSetting()
        self.popOrDismiss(true)
    }

    @objc private func didClickSelectedCount() {
        let vc = InMeetSecuritySelectedViewController(setting: self.viewModel.setting, selectedData: self.viewModel.selectedData, delegate: self)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func didCancelSearch(_ sender: Any) {
        self.isSearchJobScheduled = false
        self.searchingKey = ""
        searchView.reset()
        searchResultView.isHidden = true
        resultBackgroundView.isHidden = true
        tableView.isHidden = false
        viewModel.search.cancel()
    }

    @objc private func didBeginEditing(_ tf: UITextField) {
        self.isFirstSearchJob = true
        resultBackgroundView.isHidden = false
        updateSearchKey(tf.text ?? "")
    }

    private var isFirstSearchJob = true
    private var isSearchJobScheduled = false
    private var searchingKey: String = ""
    private func updateSearchKey(_ key: String) {
        isSearchJobScheduled = true
        if isFirstSearchJob {
            self.isFirstSearchJob = false
            runSearchJobIfNeeded()
        } else {
            self.searchingKey = key
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) { [weak self] in
                self?.runSearchJobIfNeeded()
            }
        }
    }

    private func runSearchJobIfNeeded() {
        guard isSearchJobScheduled else { return }
        isSearchJobScheduled = false
        let key = self.searchingKey
        if key.isEmpty {
            searchResultView.isHidden = true
            maskSearchViewTap.isEnabled = true
            tableView.isHidden = false
            resultBackgroundView.alpha = 0.5
        } else {
            searchResultView.isHidden = false
            maskSearchViewTap.isEnabled = false
            tableView.isHidden = true
            resultBackgroundView.alpha = 1.0
        }
        viewModel.search.search(key: key)
        if viewModel.search.isRequesting {
            searchResultView.update(.loading)
        } else {
            securityPickerDidUpdateSearchResult(isChanged: true)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.tag == .searchTableView ? self.searchRows.count : self.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = tableView.tag == .searchTableView ? self.searchRows[indexPath.row] : self.rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.identifier.identifier, for: indexPath)
        cell.separatorInset = .init(top: 0, left: row.showsSeparator ? 108 : tableView.frame.width, bottom: 0, right: 0)
        if let cell = cell as? InMeetSecurityPickerCell {
            cell.config(row, setting: self.viewModel.setting)
            cell.didConfigCell()
        }
        if let cell = cell as? InMeetSecurityPickerCalendarCell {
            cell.expandAction = { [weak self] in
                self?.expandCalendar($0)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let isSearch = tableView.tag == .searchTableView
        let row = isSearch ? self.searchRows[indexPath.row] : self.rows[indexPath.row]
        self.viewModel.toggleRowSelection(row)
        if isSearch {
            self.reloadData(isSearch: true)
        }
        self.reloadData(isSearch: false)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.bounces = scrollView.contentInset.top < scrollView.contentOffset.y
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }
}

extension InMeetSecurityPickerViewController {
    private func expandCalendar(_ info: InMeetSecurityPickerItem.CalendarHeaderInfo) {
        switch info.status {
        case .noPermission:
            UDToast.showTips(with: I18n.View_G_GuestListHidden, on: self.view)
        case .notInCalendar:
            UDToast.showTips(with: I18n.View_G_CanNotSeeGuestList, on: self.view)
        case .success:
            self.viewModel.toggleCalendarExpand()
            self.reloadData(isSearch: false)
        default:
            break
        }
    }
}

extension InMeetSecurityPickerViewController: InMeetSecurityPickerViewModelDelegate {
    func securityPickerDidFinishLoading() {
        Logger.setting.info("securityPickerDidFinishLoading")
        self.loadingView?.remove()
        self.loadingView = nil
        self.reloadData(isSearch: false)
    }

    func securityPickerDidChangeSecuritySetting(_ setting: VideoChatSettings.SecuritySetting) {
        Logger.setting.info("securityPickerDidChangeSecuritySetting")
        self.reloadData(isSearch: false)
    }
}

extension InMeetSecurityPickerViewController: InMeetSecurityPickerSearchDelegate {
    func securityPickerDidUpdateSearchResult(isChanged: Bool) {
        Logger.setting.info("securityPickerDidUpdateSearchResult, isChanged: \(isChanged)")
        self.reloadData(isSearch: true, shouldReload: isChanged)
    }
}

extension InMeetSecurityPickerViewController: InMeetSecuritySelectedViewControllerDelegate {
    func securitySelectedViewControllerDidSave(_ vc: InMeetSecuritySelectedViewController) {
        if vc.deletedItems.isEmpty { return }
        self.viewModel.unselectItems(vc.deletedItems)
        if !self.searchResultView.isHidden {
            self.reloadData(isSearch: true)
        }
        self.reloadData(isSearch: false)
    }
}

private extension Int {
    static let tableView = 1
    static let searchTableView = 2
}

private final class InMeetSecuritySelectBottomView: UIView {
    lazy var selectedButton: UIButton = {
        let button = UIButton(type: .roundedRect)
        button.setTitleColor(UIColor.ud.primaryPri500, for: .normal)
        button.setTitleColor(UIColor.ud.primaryPri300, for: .disabled)
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        button.isEnabled = false
        button.contentHorizontalAlignment = .left
        return button
    }()

    lazy var sureButton: UIButton = {
        let button = UIButton()
        button.setTitle(I18n.View_M_Save, for: .normal)
        button.setTitleColor(UIColor.ud.staticWhite, for: .normal)
        button.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .disabled)
        button.vc.setBackgroundColor(UIColor.ud.primaryPri500, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.fillDisabled, for: .disabled)
        button.vc.setBackgroundColor(UIColor.ud.primaryPri600, for: .highlighted)
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.tintColor = .clear
        button.isEnabled = false
        button.layer.cornerRadius = 4.0
        button.clipsToBounds = true
        return button
    }()

    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBody

        addSubview(selectedButton)
        addSubview(sureButton)
        addSubview(lineView)

        selectedButton.snp.makeConstraints { (maker) in
            maker.left.equalTo(safeAreaLayoutGuide).offset(16)
            maker.centerY.equalToSuperview()
            maker.top.equalToSuperview().offset(17)
            maker.bottom.equalToSuperview().offset(-17)
            maker.height.equalTo(18)
        }

        sureButton.snp.makeConstraints { (maker) in
            maker.width.greaterThanOrEqualTo(60)
            maker.height.greaterThanOrEqualTo(28)
            maker.right.equalTo(safeAreaLayoutGuide).offset(-16)
            maker.left.greaterThanOrEqualTo(selectedButton.snp.right).offset(16)
            maker.centerY.equalToSuperview()
        }

        lineView.snp.makeConstraints { (maker) in
            maker.left.right.top.equalToSuperview()
            maker.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
