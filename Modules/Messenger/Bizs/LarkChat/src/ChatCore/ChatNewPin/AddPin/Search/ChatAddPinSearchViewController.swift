//
//  ChatAddPinSearchViewController.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/6.
//

import Foundation
import LarkUIKit
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignEmpty
import RxSwift
import RxCocoa
import EENavigator
import FigmaKit
import LarkCore
import LarkEMM
import LarkSensitivityControl

final class ChatAddPinSearchTextField: SearchUITextField {
    override func paste(_ sender: Any?) {
        let config = PasteboardConfig(token: Token("LARK-PSDA-messenger-chat-chatTabs-add-paste-permission"))
        if let string = SCPasteboard.general(config).string, string.count > ChatAddPinSearchViewController.textMaxLength {
            if let window = self.window {
                UDToast.showTips(with: BundleI18n.LarkChat.Lark_IM_Pinned_CharactersMax_Toast(ChatAddPinSearchViewController.textMaxLength), on: window)
            }
        }
        super.paste(sender)
    }
    var pasteHandler: ((String) -> Void)?
}

final class ChatAddPinSearchViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {

    // swiftlint:disable number_separator
    static let textMaxLength: Int = 10000
    // swiftlint:enable number_separator

    private lazy var addItem: LKBarButtonItem = {
        let rightItem = LKBarButtonItem(title: BundleI18n.LarkChat.Lark_IM_NewPin_AddPinnedLink_Add_Button)
        rightItem.button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        rightItem.button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        rightItem.isEnabled = false
        return rightItem
    }()

    private let viewModel: ChatAddPinSearchViewModel
    private let disposeBag = DisposeBag()
    private lazy var tableView: InsetTableView = {
        let tableView = InsetTableView()
        tableView.estimatedRowHeight = 68
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.lu.register(cellSelf: ChatAddPinDocSearchCell.self)
        tableView.lu.register(cellSelf: ChatAddPinDocStatusSearchCell.self)
        tableView.lu.register(cellSelf: ChatAddPinURLSearchCell.self)
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()
    private lazy var emptyView: ChatAddPinDocEmptyView = ChatAddPinDocEmptyView()
    /// 搜索框
    private lazy var searchTextField: ChatAddPinSearchTextField = {
        return ChatAddPinSearchTextField()
    }()
    private let addCompletion: (() -> Void)?

    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkChat.Lark_IM_NewPin_AddPinnedItem_Desc
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        return label
    }()

    override var navigationBarStyle: LarkUIKit.NavigationBarStyle {
        return .custom(UIColor.ud.bgBase)
    }

    init(viewModel: ChatAddPinSearchViewModel, addCompletion: (() -> Void)?) {
        self.viewModel = viewModel
        self.addCompletion = addCompletion
        super.init(nibName: nil, bundle: nil)

        self.closeCallback = { [weak self] in
            guard let chat = self?.viewModel.chat else {
                return
            }
            IMTracker.Chat.AddTop.Click.cancel(chat)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBase
        titleString = BundleI18n.LarkChat.Lark_IM_NewPin_AddPinnedItem_Button
        self.navigationItem.rightBarButtonItem = self.addItem
        addCancelItem()

        self.view.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview().inset(18)
        }

        searchTextField.rx.text
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (text: String?) in
                if let text = text, text.count > Self.textMaxLength {
                    self?.searchTextField.text = text.substring(to: Self.textMaxLength)
                }
            })
            .disposed(by: self.disposeBag)
        searchTextField.placeholder = BundleI18n.LarkChat.Lark_IM_NewPin_EnterCopyLink_Placeholder
        searchTextField.canEdit = false
        searchTextField.backgroundColor = UIColor.ud.bgBody
        searchTextField.tapBlock = { [weak self] (textField) in
            textField.becomeFirstResponder()
            guard let chat = self?.viewModel.chat else {
                return
            }
            IMTracker.Chat.AddTop.Click.search(chat)
        }
        searchTextField.becomeFirstResponder()
        searchTextField.layer.cornerRadius = 6
        searchTextField.addTarget(self, action: #selector(searchTextDidChanged), for: .editingChanged)

        let searchTextWrapperView = UIView()
        self.view.addSubview(searchTextWrapperView)
        searchTextWrapperView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(54)
            make.top.equalTo(tipLabel.snp.bottom)
        }
        searchTextWrapperView.addSubview(searchTextField)
        searchTextField.snp.makeConstraints({ make in
            make.centerY.equalToSuperview()
            make.height.equalTo(38)
            make.left.right.equalToSuperview().inset(16)
        })

        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(searchTextWrapperView.snp.bottom)
        }
        self.view.addSubview(self.emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.edges.equalTo(tableView)
        }
        emptyView.isHidden = true

        self.viewModel.reloadDriver.drive(onNext: { [weak self] (_) in
            self?.tableView.reloadData()
        }).disposed(by: self.disposeBag)

        IMTracker.Chat.AddTop.View(self.viewModel.chat)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.reloadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchTextField.resignFirstResponder()
    }

    @objc
    private func searchTextDidChanged() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(searchTextChangedHandler), object: nil)
        self.perform(#selector(searchTextChangedHandler), with: nil, afterDelay: 0.3)
    }

    @objc
    private func searchTextChangedHandler() {
        guard searchTextField.markedTextRange == nil else { return }
        self.viewModel.search(self.searchTextField.text ?? "")
    }

    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        switch self.viewModel.searchScene {
        case .url:
            let titleType: ChatAddPinURLPreviewTitleType = .url(ChatAddPinURLPreviewTitleType.URLModel(url: self.viewModel.searchKey, inlineEntity: nil))
            let addVM = ChatAddPinURLPreviewViewModel(userResolver: self.viewModel.userResolver,
                                                      chatBehaviorRelay: self.viewModel.chatWrapper.chat,
                                                      titleType: titleType,
                                                      fromSearch: true,
                                                      addCompletion: addCompletion)
            let addVC = ChatAddPinURLPreviewController(viewModel: addVM)
            self.viewModel.userResolver.navigator.push(addVC, from: self)
        case .doc:
            if indexPath.row == viewModel.showDocs.count {
                return
            }
            let docModel = self.viewModel.showDocs[indexPath.row]
            let titleType: ChatAddPinURLPreviewTitleType = .doc(ChatAddPinURLPreviewTitleType.DocModel(url: docModel.url,
                                                                                                       docType: docModel.docType,
                                                                                                       wikiSubType: docModel.wikiSubType,
                                                                                                       title: docModel.title,
                                                                                                       ownerName: docModel.ownerName,
                                                                                                       iconInfo: docModel.iconInfo))
            let addVM = ChatAddPinURLPreviewViewModel(userResolver: self.viewModel.userResolver,
                                                      chatBehaviorRelay: self.viewModel.chatWrapper.chat,
                                                      titleType: titleType,
                                                      fromSearch: !self.viewModel.searchKey.isEmpty,
                                                      addCompletion: addCompletion)
            let addVC = ChatAddPinURLPreviewController(viewModel: addVM)
            self.viewModel.userResolver.navigator.push(addVC, from: self)
            IMTracker.Chat.AddTop.Click.select(self.viewModel.chat, fromSearch: !self.viewModel.searchKey.isEmpty)
        }
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ChatAddPinDocSearchCell else {
            return
        }
        cell.update(isHighlight: true)
    }

    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ChatAddPinDocSearchCell else {
            return
        }
        cell.update(isHighlight: false)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.viewModel.searchScene {
        case .url:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ChatAddPinURLSearchCell.self), for: indexPath) as? ChatAddPinURLSearchCell else {
                return UITableViewCell()
            }
            cell.set(self.viewModel.searchKey)
            return cell
        case .doc:
            if indexPath.row < self.viewModel.showDocs.count {
                let identifier = String(describing: ChatAddPinDocSearchCell.self)
                if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ChatAddPinDocSearchCell {
                    let doc = self.viewModel.showDocs[indexPath.row]
                    cell.setDoc(doc)
                    return cell
                }
            } else {
                let identifier = String(describing: ChatAddPinDocStatusSearchCell.self)
                if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ChatAddPinDocStatusSearchCell {
                    cell.set(searchResult: self.viewModel.searchResult, showLoading: self.viewModel.showDocs.isEmpty)
                    return cell
                }
            }
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.viewModel.searchScene {
        case .url:
            self.emptyView.isHidden = true
            return 1
        case .doc:
            var itemCount = self.viewModel.showDocs.count
            if !self.viewModel.searchKey.isEmpty, (itemCount > 0 || self.viewModel.searchResult != .normal) {
                itemCount += 1
            }
            self.emptyView.isHidden = (itemCount != 0 || self.viewModel.searchKey.isEmpty)
            return itemCount
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch self.viewModel.searchScene {
        case .url:
            return 84
        case .doc:
            if indexPath.row >= self.viewModel.showDocs.count {
                return 76
            }
            return 68
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.height

        if offset + height * 2 > contentHeight {
            self.viewModel.loadMoreIfNeeded()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
}

final class ChatAddPinDocEmptyView: UIView {

    private let icon: UIImageView = UIImageView()
    private let titleLabel: UILabel = UILabel()

    init() {
        super.init(frame: CGRect.zero)
        self.addSubview(icon)
        self.addSubview(titleLabel)
        icon.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(70.5)
        }
        icon.image = UDEmptyType.noSearchResult.defaultImage()

        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(icon.snp.bottom).offset(20)
        }
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textCaption
        titleLabel.text = BundleI18n.CCM.Lark_Legacy_SearchEmpty
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
