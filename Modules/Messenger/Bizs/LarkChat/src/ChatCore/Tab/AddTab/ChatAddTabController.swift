//
//  ChatAddTabController.swift
//  LarkChat
//
//  Created by zhaojiachen on 2022/3/27.
//

import Foundation
import RustPB
import SnapKit
import LarkUIKit
import LarkModel
import LarkCore
import LarkSDKInterface
import LarkTag
import LarkFeatureGating
import LarkAvatar
import UniverseDesignColor
import LKCommonsLogging
import LarkKeyboardKit
import LKCommonsTracker
import Swinject
import RxSwift
import RxCocoa
import EENavigator
import LarkOpenChat
import UIKit
import Homeric
import LarkBizAvatar
import LarkContainer
import EditTextView
import LarkEMM
import LarkSensitivityControl

final class ChatAddTabSearchTextField: SearchUITextField {
    override func paste(_ sender: Any?) {
        let config = PasteboardConfig(token: Token("LARK-PSDA-messenger-chat-chatTabs-add-paste-permission"))
        if let string = SCPasteboard.general(config).string, !string.isEmpty {
            self.pasteHandler?(string)
        }
        super.paste(sender)
    }
    var pasteHandler: ((String) -> Void)?
}

final class ChatAddTabController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {

    private let viewModel: ChatAddTabViewModel
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = 0
        tableView.backgroundColor = UIColor.ud.bgBody
        tableView.lu.register(cellSelf: ChatTabDocSearchCell.self)
        tableView.lu.register(cellSelf: ChatTabDocStatusSearchCell.self)
        tableView.lu.register(cellSelf: ChatTabAddURLSearchCell.self)
        tableView.lu.register(cellSelf: ChatTabAddURLPreviewCell.self)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()
    let emptyView: ChatTabDocEmptyView = ChatTabDocEmptyView()
    /// 搜索框
    private lazy var searchTextField: ChatAddTabSearchTextField = {
        return ChatAddTabSearchTextField()
    }()

    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkChat.Lark_IM_AddTabs_AddDocOrWebpageLink_Desc
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private let disposeBag = DisposeBag()

    static let logger = Logger.log(ChatAddTabController.self, category: "Module.ChatAddTabController")

    init(viewModel: ChatAddTabViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        titleString = BundleI18n.LarkChat.Lark_Groups_AddTabsTitle
        addCancelItem()

        self.view.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview().inset(20)
        }

        searchTextField.rx.text
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (text: String?) in
                if let text = text, text.count > 10_000 {
                    self?.searchTextField.text = text.substring(to: 10_000)
                }
            })
            .disposed(by: self.disposeBag)
        searchTextField.placeholder = BundleI18n.LarkChat.Lark_IM_AddTabs_LinkPlaceholder
        searchTextField.canEdit = true
        searchTextField.tapBlock = { (textField) in
            textField.becomeFirstResponder()
        }
        searchTextField.becomeFirstResponder()
        searchTextField.layer.cornerRadius = 6
        searchTextField.addTarget(self, action: #selector(searchTextDidChanged), for: .editingChanged)

        let searchTextWrapperView = UIView()
        self.view.addSubview(searchTextWrapperView)
        searchTextWrapperView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(52)
            make.top.equalTo(tipLabel.snp.bottom)
        }
        searchTextWrapperView.addSubview(searchTextField)
        searchTextField.snp.makeConstraints({ make in
            make.top.equalTo(6)
            make.height.equalTo(36)
            make.left.equalTo(16)
            make.right.equalTo(-16)
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
        self.viewModel.updateTextField = { [weak self] text in
            self?.searchTextField.text = text
        }
        self.viewModel.getCurrentInputText = { [weak self] in
            return self?.searchTextField.text ?? ""
        }
        searchTextField.pasteHandler = { [weak self] pasteString in
            self?.viewModel.handlePaste(pasteString)
        }
        IMTracker.Chat.DocPageAdd.View(self.viewModel.chat)
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
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        switch self.viewModel.searchScene {
        case .url(let urlPreviewInfo):
            let setURLModel = ChatAddTabSetURLModel(chatId: self.viewModel.chat.id,
                                                    chat: self.viewModel.chat,
                                                    url: self.viewModel.searchKey,
                                                    urlPreviewInfo: urlPreviewInfo)
            let setLabelNameControllerVC = ChatTabSetURLNameController(userResolver: viewModel.userResolver, setURLNameModel: setURLModel, addCompletion: viewModel.addCompletion)
            viewModel.navigator.push(setLabelNameControllerVC, from: self)
            IMTracker.Chat.DocPageAdd.Click.LinkAdd(
                self.viewModel.chat,
                params: ["tab_type": "web_tab",
                         "link_recognized": "true",
                         "add_type": "link"]
            )
        case .doc:
            if indexPath.row == viewModel.showDocs.count {
                return
            }
            let docModel = self.viewModel.showDocs[indexPath.row]
            let setDocNameModel = ChatAddTabSetDocModel(chatId: self.viewModel.chat.id,
                                                        chat: self.viewModel.chat,
                                                        id: docModel.id,
                                                        url: docModel.url,
                                                        docType: docModel.docType,
                                                        title: docModel.title,
                                                        titleHitTerms: docModel.titleHitTerms,
                                                        ownerID: docModel.ownerID,
                                                        ownerName: docModel.ownerName)
            guard let setLabelNameControllerVC = try? ChatTabSetDocNameController(userResolver: viewModel.userResolver, setDocNameModel: setDocNameModel, addCompletion: viewModel.addCompletion)
            else { return }
            viewModel.navigator.push(setLabelNameControllerVC, from: self)
            IMTracker.Chat.DocPageAdd.Click.LinkAdd(
                self.viewModel.chat,
                params: ["tab_type": "single_doc_tab",
                         "link_recognized": "false",
                         "add_type": self.viewModel.searchKey.isEmpty ? "access_list" : "search"]
            )
        }
    }

    public func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ChatTabDocSearchCell else {
            return
        }
        cell.update(isHighlight: true)
    }

    public func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ChatTabDocSearchCell else {
            return
        }
        cell.update(isHighlight: false)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.viewModel.searchScene {
        case .url(let urlPreviewInfo):
            if let urlPreviewInfo = urlPreviewInfo {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ChatTabAddURLPreviewCell.self), for: indexPath) as? ChatTabAddURLPreviewCell else {
                    return UITableViewCell()
                }
                cell.set(urlPreviewInfo, link: self.viewModel.searchKey)
                return cell
            }
            guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ChatTabAddURLSearchCell.self), for: indexPath) as? ChatTabAddURLSearchCell else {
                return UITableViewCell()
            }
            cell.set(self.viewModel.searchKey)
            return cell
        case .doc:
            if indexPath.row < self.viewModel.showDocs.count {
                let identifier = String(describing: ChatTabDocSearchCell.self)
                if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ChatTabDocSearchCell {
                    let doc = self.viewModel.showDocs[indexPath.row]
                    cell.setDoc(doc)
                    return cell
                }
            } else {
                let identifier = String(describing: ChatTabDocStatusSearchCell.self)
                if let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as? ChatTabDocStatusSearchCell {
                    cell.searchResult = self.viewModel.searchResult
                    return cell
                }
            }
            return UITableViewCell()
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch self.viewModel.searchScene {
        case .url(let urlPreviewInfo):
            return urlPreviewInfo == nil ? 48 : 66
        case .doc:
            return 68
        }
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.height

        if offset + height * 2 > contentHeight {
            self.viewModel.loadMoreIfNeeded()
        }
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.view.endEditing(true)
    }
}

final class ChatTabDocEmptyView: UIView {

    private let icon: UIImageView = UIImageView()
    private let titleLabel: UILabel = UILabel()
    init() {
        super.init(frame: CGRect.zero)
        self.addSubview(icon)
        self.addSubview(titleLabel)
        backgroundColor = UDColor.bgBody
        icon.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(70.5)
        }
        icon.image = LarkCore.Resources.empty_search

        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(icon.snp.bottom).offset(20)
        }
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UDColor.textPlaceholder
        titleLabel.text = BundleI18n.CCM.Lark_Legacy_SearchEmpty
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ChatTabDocStatusSearchCell: UITableViewCell {
    private var titleLabel: UILabel = UILabel()

    var searchResult: ChatAddTabViewModel.SearchStatus = .noload {
        didSet {
            switch searchResult {
            case .normal:
                self.titleLabel.text = BundleI18n.CCM.Lark_Legacy_AllResultLoaded
            default:
                self.titleLabel.text = BundleI18n.CCM.Lark_Legacy_SendDocLoading
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.font = UIFont.systemFont(ofSize: 14)
        self.titleLabel.textColor = UDColor.textPlaceholder
        self.titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
 final class ChatTabDocSearchModel {
    var id: String
    var title: String
    // Search Broker V2 自带高亮 优先使用这个
    var attributedTitle: NSAttributedString?
    var ownerID: String
    var ownerName: String
    var updateTime: Int64
    var url: String
    var docType: RustPB.Basic_V1_Doc.TypeEnum
    var titleHitTerms: [String]
    var isCrossTenant: Bool
    /// 自定义icon 的key
    var iconKey: String?
    /// 自定义icon的type，目前type == 1是image
    var iconType: IconType?
    // wiki 真正类型
    var wikiSubType: RustPB.Basic_V1_Doc.TypeEnum
    var relationTag: Basic_V1_TagData?

    init(
        id: String,
        title: String,
        attributedTitle: NSAttributedString? = nil,
        ownerID: String,
        ownerName: String,
        url: String,
        docType: RustPB.Basic_V1_Doc.TypeEnum,
        updateTime: Int64,
        titleHitTerms: [String],
        isCrossTenant: Bool,
        iconKey: String?,
        iconType: Int?,
        wikiSubType: RustPB.Basic_V1_Doc.TypeEnum,
        relationTag: Basic_V1_TagData? = nil
    ) {
        self.id = id
        self.title = title
        self.relationTag = relationTag
        self.attributedTitle = attributedTitle
        self.ownerID = ownerID
        self.ownerName = ownerName
        self.url = url
        self.docType = docType
        self.updateTime = updateTime
        self.titleHitTerms = titleHitTerms
        self.isCrossTenant = isCrossTenant
        self.iconKey = iconKey
        if let iconTypeValue = iconType, let type = IconType(rawValue: iconTypeValue) {
            self.iconType = type
        }
        self.wikiSubType = wikiSubType
    }
}

extension ChatTabDocSearchModel {
    enum IconType: Int {
        case unknow = 0
        case image = 1

        static let supportedShowingTypes: [IconType] = [.image]

        /// 判断当前是否是支持显示的类型，一开始支持图片、自定义的图，加这个是为了考虑以后兼容新的类型，在老的客户端上至少能正常显示默认图
        public var isCurSupported: Bool {
            return IconType.supportedShowingTypes.contains(self)
        }
    }
}
