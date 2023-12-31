//
//  AddContactViewController.swift
//  LarkAddressBookSelector
//
//  Created by zhenning on 2020/4/26.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RoundedHUD
import LarkUIKit
import LarkAlertController
import LarkKeyCommandKit
import UniverseDesignToast
import UniverseDesignTabs

// swiftlint:disable type_body_length
open class SelectContactListController: BaseUIViewController,
    UITableViewDataSource,
    UITableViewDelegate,
    UITextFieldDelegate,
    TableViewKeyboardHandlerDelegate {
    public weak var delegate: SelectContactListControllerDelegate?

    private let viewModel: SelectContactListViewModel
    private let disposeBag = DisposeBag()
    private var naviBarTitle: String = ""
    private let alertWhenDismissOrPop: Bool
    /// right item title
    public var rightItemTitle: String? {
        didSet {
            self.rightItem.title = rightItemTitle
            self.navigationItem.rightBarButtonItem = (rightItemTitle == nil) ? nil : self.rightItem
        }
    }
    private var selectType: ContactTableSelectType {
        return self.viewModel.contactTableSelectType
    }
    /// subviews
    private lazy var rightItem: UIBarButtonItem = {
        let item = UIBarButtonItem(title: self.rightItemTitle,
                                   style: .plain, target: self, action: nil)
        item.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.fillDisable,
                                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)],
                                    for: .normal)
        return item
    }()
    private lazy var selectedView: ContactSelectedContainerView = {
        let view = ContactSelectedContainerView(viewModel: self.viewModel)
        return view
    }()
    private var searchWrapper = SearchUITextFieldWrapperView()
    private lazy var searchTextField: SearchUITextField = { [unowned self] in
        let field = self.searchWrapper.searchUITextField
        field.canEdit = true
        let attributedPlaceholder = NSMutableAttributedString(
            string: BundleI18n.LarkAddressBookSelector.Lark_UserGrowth_InviteMemberImportContactsSearch,
            attributes: [
                .font: field.font,
                .foregroundColor: UIColor.ud.textPlaceholder,
                .paragraphStyle: {
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineBreakMode = .byTruncatingTail
                    return paragraphStyle
                }()
            ])
        field.attributedPlaceholder = attributedPlaceholder
        field.delegate = self
        field.backgroundColor = UIColor.ud.bgFloatOverlay
        return field
        }()
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 50, bottom: 0, right: 0)
        tableView.register(ContactTableCell.self, forCellReuseIdentifier: NSStringFromClass(ContactTableCell.self))
        tableView.register(ContactIndexSectionHeader.self,
                           forHeaderFooterViewReuseIdentifier: NSStringFromClass(ContactIndexSectionHeader.self))
        return tableView
    }()
    private lazy var sectionIndexView: UDSectionIndexView = {
        let indexView = UDSectionIndexView(frame: .zero)
        indexView.delegate = self
        indexView.dataSource = self
        indexView.itemPreviewMargin = Layout.sectionIndexitemPreviewMargin
        return indexView
    }()
    private let impactFeedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private lazy var emptyResultView: EmptyDataView = {
        let content = viewModel.contactType == .email
        ? BundleI18n.LarkAddressBookSelector.Lark_B2B_Others_NoContactWithMatchedEmail
        : BundleI18n.LarkAddressBookSelector.Lark_B2B_Others_NoContactWithMatchedNumber

        let emptyDataView = EmptyDataView(content: content,
                                          placeholderImage: Resources.invite_member_no_search_result)
        emptyDataView.isHidden = true
        emptyDataView.isUserInteractionEnabled = false
        emptyDataView.useCenterConstraints = true
        return emptyDataView
    }()
    private lazy var loadErrorView: EmptyDataView = {
        let loadErrorView = EmptyDataView(content: BundleI18n
            .LarkAddressBookSelector
            .Lark_UserGrowth_InviteMemberLoadingFailed,
                                          placeholderImage: Resources.address_book_load_fail)
        loadErrorView.isHidden = true
        loadErrorView.isUserInteractionEnabled = true
        return loadErrorView
    }()

    // keyboard
    var keyboardHandler: TableViewKeyboardHandler?
    public override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + (keyboardHandler?.baseSelectiveKeyBindings ?? []) + confirmKeyBinding
    }
    private var confirmKeyBinding: [KeyBindingWraper] {
        return (self.navigationItem.rightBarButtonItem?.isEnabled ?? false) ? [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputReturn,
                modifierFlags: .command,
                discoverabilityTitle: rightItemTitle
            )
            .binding { [weak self] in
                self?.rightItemDidClick()
            }
            .wraper
        ] : []
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(contactContentType: ContactContentType,
                contactTableSelectType: ContactTableSelectType,
                naviBarTitle: String,
                contactNumberLimit: Int? = nil,
                alertWhenDismissOrPop: Bool = true) {
        self.viewModel = SelectContactListViewModel(contactTableSelectType: contactTableSelectType,
                                                    contactContentType: contactContentType,
                                                    overLimitHandle: {},
                                                    contactNumberLimit: contactNumberLimit,
                                                    validCountryCodeProvider: nil,
                                                    invalidCountryCodeErrorMessage: nil)
        self.naviBarTitle = naviBarTitle
        self.alertWhenDismissOrPop = alertWhenDismissOrPop
        super.init(nibName: nil, bundle: nil)
        setup(contactNumberLimit: contactNumberLimit)
    }

    public init(contactContentType: ContactContentType,
                contactTableSelectType: ContactTableSelectType,
                naviBarTitle: String,
                contactNumberLimit: Int? = nil,
                alertWhenDismissOrPop: Bool = true,
                validCountryCodeProvider: MobileCodeProvider? = nil,
                invalidCountryCodeErrorMessage: String? = nil) {
        self.viewModel = SelectContactListViewModel(contactTableSelectType: contactTableSelectType,
                                                    contactContentType: contactContentType,
                                                    overLimitHandle: {},
                                                    contactNumberLimit: contactNumberLimit,
                                                    validCountryCodeProvider: validCountryCodeProvider,
                                                    invalidCountryCodeErrorMessage: invalidCountryCodeErrorMessage)
        self.naviBarTitle = naviBarTitle
        self.alertWhenDismissOrPop = alertWhenDismissOrPop
        super.init(nibName: nil, bundle: nil)
        setup(contactNumberLimit: contactNumberLimit)
    }

    private func setup(contactNumberLimit: Int? = nil) {
        self.delegate?.onPageInitFinished()
        self.viewModel.overLimitHandle = { [weak self] in
            guard let window = self?.view.window else { return }
            UDToast.showTips(with: BundleI18n.LarkAddressBookSelector.Lark_Invitation_MembersBatchLimit(contactNumberLimit ?? 0),
                             on: window)
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.delegate?.onLifeCycleEvent(type: .viewWillAppear)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.delegate?.onLifeCycleEvent(type: .viewDidAppear)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.delegate?.onLifeCycleEvent(type: .viewWillDisappear)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.delegate?.onLifeCycleEvent(type: .viewDidDisappear)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        bindViewModel()
        registObservables()
        setupKeyCommands()
        fetchLocalContacts()
        self.delegate?.onLifeCycleEvent(type: .viewDidLoad)
    }

    private func fetchLocalContacts() {
        self.loadingPlaceholderView.isHidden = false
        self.viewModel.getLocalContactsAsync()
    }

    private func setupKeyCommands() {
        keyboardHandler = TableViewKeyboardHandler()
        keyboardHandler?.delegate = self
    }

    private func bindViewModel() {
        self.viewModel.listModeDriver
            .drive(onNext: { [weak self] (listMode) in
                guard let `self` = self else { return }
                var selectedViewHeight: CGFloat
                switch listMode {
                case .defaultMode:
                    selectedViewHeight = self.selectedView.suitableHeight
                    self.sectionIndexView.isHidden = false
                    self.emptyResultView.isHidden = !self.viewModel.orderedContacts.isEmpty
                    if self.searchTextField.isFirstResponder {
                        self.searchTextField.resignFirstResponder()
                    }
                case .searchMode:
                    selectedViewHeight = 0
                    self.sectionIndexView.isHidden = true
                    self.viewModel.clearSearchCache()
                }
                self.tableView.reloadData()
                /// 多选模式下，切换搜索时更新选中view的布局
                if self.selectType == .multiple {
                    self.selectedView.snp.updateConstraints({
                        $0.height.equalTo(selectedViewHeight)
                    })
                }
                self.delegate?.onContactListModeDidChange(listMode: listMode)
                SelectContactListController.baseLogger.debug("listModeDriver",
                                                             additionalData: ["self.selectType": "\(self.selectType)",
                                                                "listMode": "\(listMode)",
                                                                "selectedViewHeight": "\(selectedViewHeight)"])
            })
            .disposed(by: self.viewModel.disposeBag)

        self.viewModel.orderedContactsDriver.drive(onNext: { [weak self] (contacts) in
            guard let `self` = self else { return }
            self.loadingPlaceholderView.isHidden = true
            self.emptyResultView.isHidden = !contacts.isEmpty
            self.tableView.reloadData()
            self.sectionIndexView.snp.updateConstraints({ (make) in
                make.height.equalTo(Layout.sectionIndexItemHeight * CGFloat(self.viewModel.sortedContactKeys.count))
            })
            self.sectionIndexView.superview?.layoutIfNeeded()
            self.sectionIndexView.reloadData()
            self.sectionIndexView.selectItem(at: 0)
        }).disposed(by: self.viewModel.disposeBag)

        self.viewModel.contactsLoadedObservable.subscribe(onNext: { [weak self] (loaded) in
            guard let `self` = self else { return }
            if let extraInfosOb = self.delegate?
                .onContactsDataLoadedByExtrasIfNeeded(loaded: loaded, allContacts: self.viewModel.allContacts) {
                // update extra of contact list
                extraInfosOb.subscribe(onNext: { [weak self] extraInfos in
                    guard let `self` = self else { return }
                    self.viewModel.updateContactExtraInfos(extraInfos: extraInfos)
                }).disposed(by: self.viewModel.disposeBag)
            }
        }).disposed(by: self.viewModel.disposeBag)

        /// mutile selected
        self.viewModel.filterContactsDriver
            .drive(onNext: { [weak self] (filteredContacts) in
                guard let `self` = self else { return }

                /// 因为搜索是异步任务，此时有可能已经处于非搜索态，所以需要额外判断
                switch self.viewModel.listMode {
                case .defaultMode:
                    self.emptyResultView.isHidden = true
                case .searchMode:
                    self.emptyResultView.isHidden = !filteredContacts.isEmpty
                    self.tableView.reloadData()
                }
                self.delegate?.onContactSearchChanged(filteredContacts: filteredContacts,
                                                      contentType: self.viewModel.contactType,
                                                      from: self)
            })
            .disposed(by: self.viewModel.disposeBag)

        self.viewModel.selectedContactsDriver
            .drive(onNext: { [weak self] (selectedContacts) in
                guard let `self` = self, self.selectType == .multiple else { return }
                self.delegate?.selectedContactsChanged(selectedContacts: selectedContacts,
                                                       contentType: self.viewModel.contactType,
                                                       from: self)

                let searchWrapperHeight: CGFloat = selectedContacts.isEmpty
                    ? Layout.searchWrapperMaxHeight
                    : Layout.searchWrapperMinHeight
                let selectedViewHeight: CGFloat = selectedContacts.isEmpty ? 0 : self.selectedView.suitableHeight
                let textColor: UIColor = selectedContacts.isEmpty
                    ? UIColor.ud.fillDisable
                    : UIColor.ud.primaryContentDefault
                self.rightItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: textColor,
                                                       NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)],
                                                      for: .normal)
                if self.viewModel.listMode == .defaultMode {
                    self.searchWrapper.snp.updateConstraints { (make) in
                        make.height.equalTo(searchWrapperHeight)
                    }
                    self.selectedView.selectedCollectionView.collectionViewLayout.invalidateLayout()
                    self.selectedView.snp.updateConstraints({ (make) in
                        make.height.equalTo(selectedViewHeight)
                    })
                    self.selectedView.superview?.layoutIfNeeded()
                }
                /// 更新列表选中状态
                self.tableView.reloadData()
                SelectContactListController.baseLogger.debug("selectedContactsDriver",
                                                             additionalData: ["self.selectType": "\(self.selectType)",
                                                                "selectedViewHeight": "\(selectedViewHeight)"])
            })
            .disposed(by: self.viewModel.disposeBag)

        self.viewModel.reloadDataDriver
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            })
            .disposed(by: self.viewModel.disposeBag)

        self.viewModel.errorDriver
            .drive(onNext: { [weak self] error in
                guard let `self` = self else { return }
                self.loadErrorView.isHidden = false
                self.delegate?.showErrorForRequestContacts(error: error,
                                                           contentType: self.viewModel.contactType,
                                                           from: self)
            })
            .disposed(by: self.viewModel.disposeBag)
    }

    private func registObservables() {

        /// right item tap action
        self.rightItem.rx.tap.asDriver()
            .drive(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.rightItemDidClick()
            })
            .disposed(by: self.disposeBag)

        self.searchTextField.rx.text.asDriver().skip(1)
            .filter({ $0 == nil || !$0!.isEmpty })
            .drive(onNext: { [weak self] (text) in
                self?.viewModel.updateSearchResults(for: text ?? "")
            })
            .disposed(by: self.disposeBag)

        self.searchTextField.rx.text.asDriver()
            .distinctUntilChanged()
            .drive(onNext: { [weak self] (searchText) in
                guard let `self` = self else { return }
                let listMode: ContactListMode = (searchText?.count ?? 0 > 0) ? .searchMode : .defaultMode
                self.viewModel.setListMode(listMode: listMode)
                /// fix RxSwift 对拼音连词模式文本变化的判断 bug
                if searchText == "" {
                    self.searchTextField.text = ""
                }
                self.keyboardHandler?.resetFocus()
            })
            .disposed(by: self.disposeBag)
    }

    private func rightItemDidClick() {
        self.delegate?.didTapNaviBarRightItem(selectedContacts: self.viewModel.selectedContacts,
                                              contentType: self.viewModel.contactType,
                                              from: self)
    }

    private func setupSubviews() {
        self.title = self.naviBarTitle
        self.navigationItem.rightBarButtonItem = self.rightItem
        if self.selectType == .multiple {
            self.backCallback = { [weak self] in
                if !(self?.viewModel.selectedContacts.isEmpty ?? true) && self?.alertWhenDismissOrPop ?? true {
                    let alert = LarkAlertController()
                    alert.setContent(text: BundleI18n.LarkAddressBookSelector.Lark_Invitation_QuitBatch)
                    alert.addSecondaryButton(text: BundleI18n.LarkAddressBookSelector.Lark_Invitation_AddMembersRefreshDialogCancel)
                    alert.addPrimaryButton(text: BundleI18n.LarkAddressBookSelector.Lark_Invitation_AddMembersRefreshDialogConfirm,
                                    dismissCompletion: { [weak self] in
                                        self?.navigationController?.popViewController(animated: true)
                                    })
                    self?.present(alert, animated: true)
                }
            }
            self.closeCallback = { [weak self] in
                if !(self?.viewModel.selectedContacts.isEmpty ?? true) && self?.alertWhenDismissOrPop ?? true {
                    let alert = LarkAlertController()
                    alert.setContent(text: BundleI18n.LarkAddressBookSelector.Lark_Invitation_QuitBatch)
                    alert.addSecondaryButton(text: BundleI18n.LarkAddressBookSelector.Lark_Invitation_AddMembersRefreshDialogCancel)
                    alert.addPrimaryButton(text: BundleI18n.LarkAddressBookSelector.Lark_Invitation_AddMembersRefreshDialogConfirm,
                                    dismissCompletion: { [weak self] in
                                        self?.navigationController?.popViewController(animated: true)
                                    })
                    self?.present(alert, animated: true)
                }
            }
        }

        self.view.addSubview(searchWrapper)
        /// searchWrapper高度之前有设定
        searchWrapper.snp.remakeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(Layout.searchWrapperMaxHeight)
        }

        self.view.addSubview(selectedView)
        selectedView.snp.makeConstraints { make in
            make.top.equalTo(searchWrapper.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }

        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(selectedView.snp.bottom)
            make.bottom.left.right.equalToSuperview()
        }

        self.view.addSubview(sectionIndexView)
        sectionIndexView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(Layout.sectionIndexViewRight)
            make.width.equalTo(Layout.sectionIndexViewWidth)
            make.height.equalTo(0)
        }

        self.view.addSubview(emptyResultView)
        emptyResultView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.view.addSubview(loadErrorView)
        loadErrorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.loadingPlaceholderView.superview?.layoutIfNeeded()
    }

    /// 处理选择联系人
    func handleSelectContact(selectContact: AddressBookContact) {
        if self.viewModel.isSelectedContact(selectContact) {
            /// delete item
            if let index = self.viewModel.getIndexOfSelectedContact(selectContact) {
                SelectContactListController.baseLogger.debug("selectedView scrollToItem delete item",
                                                             additionalData: ["index": "\(index)",
                                                                "selectContact": "\(selectContact)"])
                self.selectedView.scrollToItem(at: IndexPath(row: index, section: 0), animated: true)
            }
            self.viewModel.didSelectedContact(contact: selectContact)
        } else {
            /// add item
            self.viewModel.didSelectedContact(contact: selectContact)
            if let index = self.viewModel.getIndexOfSelectedContact(selectContact) {
                self.selectedView.scrollToItem(at: IndexPath(row: index, section: 0), animated: true)
                SelectContactListController.baseLogger.debug("selectedView scrollToItem add item",
                                                             additionalData: ["index": "\(index)",
                                                                "selectContact": "\(selectContact)"])
            }
        }
    }

    /// 重置状态
    public func reset() {
        self.viewModel.setListMode(listMode: .defaultMode)
        self.searchTextField.text = nil
        self.viewModel.updateSearchResults(for: "")
        SelectContactListController.baseLogger.debug("reset")
    }

// MARK: - TableViewKeyboardHandlerDelegate

    public func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return tableView
    }

// MARK: - UITableViewDataSource

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell: ContactTableCell = tableView.dequeueReusableCell(withIdentifier:
            NSStringFromClass(ContactTableCell.self), for: indexPath) as? ContactTableCell else {
                return UITableViewCell()
        }
        let cellVM = viewModel.contactCellViewModelForIndexPath(indexPath: indexPath)
        if let cellVM = cellVM {
            if self.selectType == .multiple {
                cellVM.selected = self.viewModel.isSelectedContact(cellVM.contact)
            }
            cell.cellViewModel = cellVM
        }
        return cell
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sectionsCount
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.getRowsInSection(section: section)
    }

// MARK: - UITableViewDelegate

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard indexPath.section < viewModel.sortedContactKeys.count else { return }
        let contactKey = viewModel.sortedContactKeys[indexPath.section]
        guard let contacts = self.viewModel.orderedContacts[contactKey],
              indexPath.row < contacts.count else {
            return
        }
        if let contact = self.viewModel.orderedContacts[contactKey]?[indexPath.row] {
            if viewModel.isBlockedContact(contact) {
                if let message = viewModel.invalidCountryCodeErrorMessage {
                    UDToast.showFailure(with: message, on: view)
                }
                return
            }
        }
        // 单选 / 多选
        switch viewModel.contactTableSelectType {
        case .single:
            if viewModel.listMode == .defaultMode {
                guard viewModel.sortedContactKeys.count > indexPath.section,
                    let contact = self.viewModel.orderedContacts[viewModel.sortedContactKeys[indexPath.section]]?[indexPath.row]
                    else { return }
                self.viewModel.didSelectedContact(contact: contact)
                self.delegate?.didChooseContactInSingleType(contact: contact, contentType: self.viewModel.contactType, from: self)

            } else if viewModel.listMode == .searchMode {
                let contact = self.viewModel.filteredContacts[indexPath.row]
                self.viewModel.didSelectedContact(contact: contact)
                self.delegate?.didChooseContactInSingleType(contact: contact, contentType: self.viewModel.contactType, from: self)
            }
        case .multiple:
            switch viewModel.listMode {
            case .defaultMode:
                guard viewModel.sortedContactKeys.count > indexPath.section,
                    let contact = self.viewModel.orderedContacts[viewModel.sortedContactKeys[indexPath.section]]?[indexPath.row]
                    else { return }
                self.handleSelectContact(selectContact: contact)
                self.delegate?.didSelectContactInMultipleType(contact: contact,
                                                              contentType: self.viewModel.contactType,
                                                              toSelected: viewModel.isSelectedContact(contact),
                                                              from: self)
                self.tableView.beginUpdates()
                self.tableView.reloadRows(at: [indexPath], with: .none)
                self.tableView.endUpdates()
            case .searchMode:
                let contact = self.viewModel.filteredContacts[indexPath.row]
                self.handleSelectContact(selectContact: contact)
                self.delegate?.didSelectContactInMultipleType(contact: contact,
                                                              contentType: self.viewModel.contactType,
                                                              toSelected: viewModel.isSelectedContact(contact),
                                                              from: self)
            }
        }
        // swiftlint:enable line_length
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Layout.selectableContactCellHeight
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard viewModel.listMode == .defaultMode,
            let sectionHeader = tableView.dequeueReusableHeaderFooterView(withIdentifier:
                NSStringFromClass(ContactIndexSectionHeader.self)) as? ContactIndexSectionHeader else {
                    return nil
        }
        sectionHeader.setTitle(title: self.viewModel.sortedContactKeys[section])
        return sectionHeader
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch viewModel.listMode {
        case .defaultMode:
            return Layout.selectableContactSectionHeaderHeight
        case .searchMode:
            return CGFloat.leastNormalMagnitude
        }
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let section = self.tableView.indexPathsForVisibleRows?.first?.section,
            self.sectionIndexView.currentItem != self.sectionIndexView.item(at: section) {
            self.sectionIndexView.selectItem(at: section)
        }
    }

    // MARK: - UITextFieldDelegate

    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = ""
        textField.resignFirstResponder()
        self.viewModel.setListMode(listMode: .defaultMode)
        return false
    }
}
// swiftlint:enable type_body_length

// MARK: - UDSectionIndexViewDataSource

extension SelectContactListController: UDSectionIndexViewDataSource, UDSectionIndexViewDelegate {

    public func numberOfItemViews(in sectionIndexView: UDSectionIndexView) -> Int {
        return self.viewModel.sortedContactKeys.count
    }

    public func sectionIndexView(_ sectionIndexView: UDSectionIndexView, itemViewAt section: Int) -> UDSectionIndexViewItem {
        let itemView = UDSectionIndexViewItem()
        itemView.titleFont = UIFont.boldSystemFont(ofSize: 11)
        itemView.selectedColor = UIColor.clear
        itemView.titleSelectedColor = UIColor.ud.primaryContentDefault
        itemView.titleColor = UIColor.ud.textCaption
        itemView.title = self.viewModel.sortedContactKeys[section]
        return itemView
    }

    public func sectionIndexView(_ sectionIndexView: UDSectionIndexView,
                          itemPreviewFor section: Int) -> UDSectionIndexViewItemPreview {
        let preview = UDSectionIndexViewItemPreview(title: self.viewModel.sortedContactKeys[section], type: .drip)
        return preview
    }

    public func sectionIndexView(_ sectionIndexView: UDSectionIndexView, didSelect section: Int) {
        self.impactFeedbackGenerator.prepare()
        self.impactFeedbackGenerator.impactOccurred()
        sectionIndexView.selectItem(at: section)
        sectionIndexView.showItemPreview(at: section, hideAfter: 0.2)
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: false)
        self.delegate?.didSelectSectionIndexView(section: section, contentType: self.viewModel.contactType, from: self)
    }

    public func sectionIndexView(_ sectionIndexView: UDSectionIndexView, toucheMoved section: Int) {
        self.impactFeedbackGenerator.prepare()
        self.impactFeedbackGenerator.impactOccurred()
        sectionIndexView.selectItem(at: section)
        sectionIndexView.showItemPreview(at: section)
        self.tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: false)
    }

    public func sectionIndexView(_ sectionIndexView: UDSectionIndexView, toucheCancelled section: Int) {}
}

// MARK: - Const

extension SelectContactListController {
    enum Layout {
        static let searchWrapperMinHeight: CGFloat = 48
        static let searchWrapperMaxHeight: CGFloat = 54
        static let selectableContactSectionHeaderHeight: CGFloat = 32
        static let selectableContactCellHeight: CGFloat = 68
        static let sectionIndexViewWidth: CGFloat = 20
        static let sectionIndexViewRight: CGFloat = -6
        static let sectionIndexItemHeight: CGFloat = 16
        static let sectionIndexitemPreviewMargin: CGFloat = 20
    }
}
