//
//  ChatTabSearchDocViewController.swift
//  LarkChat
//
//  Created by Zigeng on 2022/5/6.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignEmpty
import RxSwift
import LarkCore
import LarkKeyboardKit
import LKCommonsTracker
import Homeric
import LarkContainer

final class ChatTabSearchDocViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {

    final class NoResultView: UIView {
        let textLabel = UILabel()
        let icon = UIImageView(image: UDEmptyType.noSearchResult.defaultImage())

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(icon)
            icon.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview()
                make.width.height.equalTo(100)
            }

            addSubview(textLabel)
            textLabel.textAlignment = .center
            textLabel.font = UIFont.systemFont(ofSize: 14)
            textLabel.textColor = .ud.textCaption
            textLabel.lineBreakMode = .byTruncatingMiddle
            textLabel.snp.makeConstraints { make in
                make.top.equalTo(icon.snp.bottom).offset(12)
                make.centerX.equalToSuperview()
                make.left.right.equalToSuperview().inset(16)
                make.bottom.equalToSuperview()
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func updateText(_ text: String) {
            let attributedString: NSMutableAttributedString
            let wholeText = BundleI18n.LarkChat.Lark_Legacy_SearchNoResult(text)
            let template = BundleI18n.LarkChat.__Lark_Legacy_SearchNoResult as NSString

            attributedString = NSMutableAttributedString(string: wholeText)
            attributedString.addAttribute(.foregroundColor,
                                          value: UIColor.ud.textCaption,
                                          range: NSRange(location: 0, length: attributedString.length))

            let start = template.range(of: "{{").location
            if start != NSNotFound {
                attributedString.addAttribute(.foregroundColor,
                                              value: UIColor.ud.textLinkNormal,
                                              range: NSRange(location: start, length: (text as NSString).length))
            }
            self.textLabel.attributedText = attributedString
        }
    }

    private let viewModel: ChatTabSearchDocViewModel
    private let disposeBag = DisposeBag()
    private let contentContainer = UIView()
    private lazy var searchWrapper = SearchUITextFieldWrapperView()
    private var searchTextField: SearchUITextField {
        return searchWrapper.searchUITextField
    }
    private let noResultView = NoResultView()
    private let resultView = SearchResultView(tableStyle: .plain)
    private var dataTableView: UITableView { return resultView.tableview }
    private lazy var placeHolderView: UDEmptyView = {
        return UDEmptyView(
            config: UDEmptyConfig(
                description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkChat.Lark_Legacy_PullEmptyResult),
                imageSize: 100,
                spaceBelowImage: 12,
                type: UniverseDesignEmpty.UDEmptyType.noFile
            )
        )
    }()
    private var currentInChatData = ChatTabSearchDocData(searchQuery: "",
                                                          cellViewModels: [],
                                                          hasMore: false) {
        didSet {
            for model in currentInChatData.cellViewModels {
                model.fromVC = self
            }
        }
    }

    init(userResolver: UserResolver, chatId: String, router: ChatTabSearchDocRouter) throws {
        viewModel = try ChatTabSearchDocViewModel(userResolver: userResolver, chatId: chatId, router: router)
        super.init(nibName: nil, bundle: nil)
        if KeyboardKit.shared.keyboardType == .hardware {
            self.searchTextField.autoFocus = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 加载缓存的场景，不进行空query加载
        if currentInChatData.cellViewModels.isEmpty {
            searchTextChanged()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        searchTextField.resignFirstResponder()
        super.viewWillDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkChat.Lark_IM_Tabs_Docs_Title
        view.backgroundColor = UIColor.ud.bgBody
        searchTextField.autocorrectionType = .no
        searchTextField.canEdit = true
        searchTextField.placeholder = BundleI18n.LarkChat.Lark_Legacy_SearchHint
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        view.addSubview(searchWrapper)
        searchWrapper.snp.makeConstraints({ make in
            make.top.equalToSuperview().offset(8)
            make.left.right.equalToSuperview()
        })
        view.addSubview(contentContainer)
        contentContainer.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.top.equalTo(searchWrapper.snp.bottom)
        }
        let topConstraint = contentContainer.snp.top

        dataTableView.delegate = self
        dataTableView.dataSource = self
        dataTableView.estimatedRowHeight = 68
        dataTableView.rowHeight = UITableView.automaticDimension
        dataTableView.register(ChatTabSearchDocTableViewCell.self, forCellReuseIdentifier: ChatTabSearchDocTableViewCell.reuseId)
        contentContainer.addSubview(resultView)
        resultView.snp.makeConstraints { make in
            make.top.equalTo(topConstraint)
            make.left.right.bottom.equalToSuperview()
        }
        contentContainer.addSubview(noResultView)
        noResultView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview().offset(-45)
            make.width.equalToSuperview()
        }
        contentContainer.addSubview(placeHolderView)
        placeHolderView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        viewModel.stateObservable
            .subscribe(onNext: { [weak self] (state) in
                guard let self = self else { return }
                self.configViewHidden(state: state)
                switch state {
                case .placeHolder:
                    break
                case .searching:
                    self.resultView.status = .loading
                case .result(let data, let text):
                    self.resultView.status = .result
                    if text == (self.searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") {
                        self.currentInChatData = data
                        self.dataTableView.reloadData()
                        // NOTE: load from cache will set state
                        self.searchTextField.text = data.searchQuery
                        self.dataTableView.endBottomLoadMore(hasMore: data.hasMore)
                    }
                case .noResult(let text):
                    self.noResultView.updateText(text)
                case .searchFail(let text, let isLoadMore):
                    if isLoadMore {
                        self.resultView.status = .result
                    } else {
                        self.noResultView.updateText(text)
                    }
                    self.dataTableView.endBottomLoadMore(hasMore: isLoadMore)
                }
            })
            .disposed(by: disposeBag)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_DOC_LIST_VIEW))
    }

    private func configViewHidden(state: ChatTabSearchDocState) {
        switch state {
        case .searching, .result:
            resultView.isHidden = false
            noResultView.isHidden = true
            placeHolderView.isHidden = true
        case .searchFail(_, let isLoadMore):
            if isLoadMore {
                resultView.isHidden = false
                noResultView.isHidden = true
            } else {
                resultView.isHidden = true
                noResultView.isHidden = false
            }
            placeHolderView.isHidden = true
        case .placeHolder:
            resultView.isHidden = true
            noResultView.isHidden = true
            placeHolderView.isHidden = false
        case .noResult:
            resultView.isHidden = true
            noResultView.isHidden = false
            placeHolderView.isHidden = true
        }
    }

    @objc
    private func searchTextChanged() {
        if searchTextField.markedTextRange == nil {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(search), object: nil)
            self.perform(#selector(search), with: nil, afterDelay: 0.3)
        }
    }

    @objc
    private func search() {
        let query = searchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if viewModel.lastSearchQuery == query { return } // 防重过滤

        resultView.tableview.addBottomLoadMoreView { [weak self] in
            guard let self = self else { return }
            self.viewModel.loadMore(query: query)
        }
        viewModel.search(query: query)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentInChatData.cellViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellVM = currentInChatData.cellViewModels[indexPath.row]
        cellVM.indexPath = indexPath
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatTabSearchDocTableViewCell.reuseId, for: indexPath)
        if let cell = cell as? ChatTabSearchDocTableViewCell {
            cell.update(viewModel: cellVM)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        let cellVM = currentInChatData.cellViewModels[indexPath.row]
        cellVM.goNextPage()
    }
}
