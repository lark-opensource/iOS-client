//
//  FocusMentionViewController.swift
//  LarkFocus
//
//  Created by 白镜吾 on 2023/1/9.
//

import UIKit
import Foundation
import LarkMention
import SnapKit
import RxSwift
import RxCocoa
import UniverseDesignColor
import LarkUIKit
import LarkSDKInterface
import LarkContainer
import LarkRichTextCore
import UniverseDesignIcon

final class FocusMentionViewController: BaseUIViewController, UserResolverWrapper {

    @ScopedInjectedLazy private var searchAPI: SearchAPI?
    
    var dismissObserver: NSObjectProtocol?

    weak var delegate: MentionPanelDelegate?

    private lazy var isSearched: Bool = false

    private lazy var disposeBag = DisposeBag()

    private lazy var vm = MentionViewModel()

    private lazy var provider: MentionDataProviderType = {
        var param = MentionSearchParameters()
        param.chat = nil
        let provider = MentionDataProvider(resolver: self.userResolver, parameters: param)
        return provider
    }()

    private lazy var headerView: FocusMentioHeaderView = {
        let header = FocusMentioHeaderView()
        header.delegate = self
        return header
    }()

    private lazy var searchTextView: SearchUITextFieldWrapperView = {
        let searchTextView = SearchUITextFieldWrapperView()
        searchTextView.searchUITextField.clearButtonMode = .always
        searchTextView.searchUITextField.isUserInteractionEnabled = true
        searchTextView.searchUITextField.addTarget(self, action: #selector(searchTextFieldEditingChanged(_:)), for: .editingChanged)
        searchTextView.searchUITextField.placeholder = BundleI18n.LarkFocus.Lark_Profile_StatusNoteSelectMentions_Placeholder
        return searchTextView
    }()
    
    private lazy var mentionView: MentionResultView = {
        let mentionView = MentionResultView(parameters: MentionUIParameters(),
                                            mentionTracker: MentionTraker(productLevel: "", scene: ""))
        mentionView.hideHeaderView()
        mentionView.tableView.backgroundColor = UIColor.ud.bgBase
        mentionView.layer.masksToBounds = true
        mentionView.layer.cornerRadius = 0
        return mentionView
    }()

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBase
        self.setup()
        self.bindUIAction()
        self.bindVMAction()
        self.provider.didEventHandler = { [weak self] in
            guard let self = self else { return }
            self.vm.update(event: $0)
        }

        dismissObserver = NotificationCenter.default.addObserver(forName: UIApplication.willChangeStatusBarOrientationNotification,
                                                                 object: nil,
                                                                 queue: .main) { [weak self] _ in
            guard let self = self else { return }
            self.onDismiss(false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.generateRecommandItems()
    }

    func setup() {
        self.setupComponents()
        self.setupConstraints()
    }

    func setupComponents() {
        self.view.addSubview(headerView)
        self.view.addSubview(searchTextView)
        self.view.addSubview(mentionView)
    }

    func setupConstraints() {
        headerView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(48 - 7)
            make.top.equalToSuperview()
        }
        searchTextView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(54)
            make.top.equalTo(headerView.snp.bottom)
        }
        mentionView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalTo(searchTextView.snp.bottom).offset(8)
            make.bottom.equalToSuperview()
        }
    }

    @objc
    private func searchTextFieldEditingChanged(_ textField: UITextField) {
        if let text = textField.text, !text.isEmpty {
            self.isSearched = true
            provider.search(text: text)
        }
    }

    func generateRecommandItems() {
        searchAPI?.getClosestChatters(begin: 0, end: 7)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chatters) in
                guard let self = self else { return }
                guard !self.isSearched else { return }
                let data = chatters.prefix(5).map { $0.transformToPickerOption() }
                if var recommendItems = self.vm.recommendItems {
                    recommendItems += data
                    self.vm.recommendItems = recommendItems
                    self.vm.update(event: .empty)
                } else {
                    self.vm.recommendItems = data
                }
            })
            .disposed(by: disposeBag)

        searchAPI?.universalSearch(query: "",
                                  scene: .rustScene(.searchDoc),
                                  begin: 0,
                                  end: 5,
                                  moreToken: nil,
                                  filter: nil,
                                  needSearchOuterTenant: true,
                                  authPermissions: [])
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (searchResult) in
            guard let self = self else { return }
            guard !self.isSearched else { return }
            var data = searchResult.results.compactMap { searchResultType -> PickerOptionType? in
                switch searchResultType.meta {
                case .doc(let docMeta):
                    return searchResultType.transformToDocPickerOption(docMeta: docMeta)
                case .wiki(let wikiMeta):
                    return searchResultType.transformToWikiPickerOption(wikiMeta: wikiMeta)
                default:
                    return nil
                }
            }
            if var recommendItems = self.vm.recommendItems {
                recommendItems += Array(data.prefix(5))
                self.vm.recommendItems = recommendItems
                self.vm.update(event: .empty)
            } else {
                self.vm.recommendItems = Array(data.prefix(5))
            }
        })
        .disposed(by: disposeBag)
    }

    private func addTableViewLoadMore() {
        guard isSearched else { return }
        mentionView.tableView.addBottomLoadMoreView { [weak self] in
            guard let self = self else { return }
            self.provider.loadMore()
        }
    }

    private func bindUIAction() {
        mentionView.didSelectRowHandler = { [weak self] in
            guard let self = self else { return }
            self.vm.selectItem(at: $0)
        }
    }

    private func bindVMAction() {
        vm.didStartLoadHandler = { [weak self] (items, state) in
            guard let self = self else { return }
            self.mentionView.reloadTable(items: items, isSkeleton: state.isShowSkeleton)
            self.mentionView.updateTableScroll()
            self.addTableViewLoadMore()
        }
        vm.didEndLoadHandler = { [weak self] (items, state) in
            guard let self = self else { return }
            self.mentionView.reloadTable(items: items, isSkeleton: state.isShowSkeleton)
            self.mentionView.tableView.endBottomLoadMore(hasMore: state.hasMore)
        }
        vm.didSwitchMultiSelectHandler = { [weak self] (items, state) in
            guard let self = self else { return }
            self.mentionView.reloadTable(items: items, isSkeleton: state.isShowSkeleton)
        }
        vm.didReloadItemAtRowHandler = { [weak self] (items, rows) in
            guard let self = self else { return }
            self.mentionView.reloadTableAtRows(items: items, rows: rows)
        }
        vm.didCompleteHandler = { [weak self] in
            self?.onDismiss(true)
        }
        // 绑定加载状态
        vm.state.map { $0.isLoading }.distinctUntilChanged()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.mentionView.isLoading = $0
            }).disposed(by: disposeBag)
        // 绑定骨架屏状态
        vm.state.map { $0.isShowSkeleton }
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.mentionView.isUserInteractionEnabled = !$0
            }).disposed(by: disposeBag)
        // 绑定错误状态

        vm.state.map { $0.error }
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                guard let error = $0 as? MentionViewModel.VMError else {
                    self.mentionView.error = nil
                    return
                }
                vmErrorHandler(error: error)
            }).disposed(by: disposeBag)

        func vmErrorHandler(error: MentionViewModel.VMError) {
            switch error {
            case .noResult:
                if let noResultText = self.mentionView.param.noResultText, !noResultText.isEmpty {
                    self.mentionView.error = noResultText
                } else {
                    self.mentionView.error = BundleI18n.LarkFocus.Lark_Mention_NoResultsFound_Mobile
                }
            case .network(_):
                self.mentionView.error = BundleI18n.LarkFocus.Lark_Mention_ErrorUnableToLoad_Mobile
            }
        }
    }

    func onDismiss(_ animated: Bool = true) {
        self.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.handleDismiss()
        }
    }

    private func handleDismiss() {
        let isSelected = self.vm.currentState.isGlobalCheckBoxSelected ?? false
        let items = vm.currentItems.filter { $0.isMultipleSelected }
        delegate?.panel(didFinishWith: items)
        if let isGlobalSelected = vm.currentState.isGlobalCheckBoxSelected {
            delegate?.panel(didDismissWithGlobalCheckBox: isGlobalSelected)
        }
    }
}

extension FocusMentionViewController: FocusMentioHeaderViewDelegate {
    func closePanel() {
        self.dismiss(animated: true)
    }
}

extension ChatterMeta {
    func transformToPickerOption() -> PickerOptionType {

        let chatterOption = FocusPickerOption(id: self.id,
                                              type: .chatter,
                                              meta: nil,
                                              isEnableMultipleSelect: false,
                                              isMultipleSelected: false,
                                              avatarID: self.id,
                                              avatarKey: self.avatarKey,
                                              name: NSAttributedString(string: self.name),
                                              subTitle: nil,
                                              desc: nil,
                                              tags: nil)
        return chatterOption
    }
}

extension SearchResultType {
    func transformToDocPickerOption(docMeta: SearchMetaDocType) -> PickerOptionType {
        let image = LarkRichTextCoreUtils.docIcon(docType: docMeta.type, fileName: self.title.string)
        let tags: [PickerOptionTagType] = docMeta.isCrossTenant ? [.external] : []
        let mentionDocMeta = MentionMetaDocType(image: image, docType: .doc, url: docMeta.url)
        let desc = NSAttributedString(string: BundleI18n.LarkFocus.Lark_Mention_Owner_Mobile(docMeta.ownerName))

        let docOption = FocusPickerOption(id: docMeta.id,
                                          type: .document,
                                          meta: .doc(mentionDocMeta),
                                          isEnableMultipleSelect: false,
                                          isMultipleSelected: false,
                                          avatarID: self.avatarID,
                                          avatarKey: self.avatarKey,
                                          name: self.title,
                                          subTitle: nil,
                                          desc: desc,
                                          tags: tags)
        return docOption
    }

    func transformToWikiPickerOption(wikiMeta: SearchMetaWikiType) -> PickerOptionType {
        let image = LarkRichTextCoreUtils.docIcon(docType: wikiMeta.type, fileName: self.title.string)
        let tags: [PickerOptionTagType] = wikiMeta.isCrossTenant ? [.external] : []
        let mentionWikiMeta = MentionMetaDocType(image: image, docType: .wiki, url: wikiMeta.url)
        let desc = NSAttributedString(string: BundleI18n.LarkFocus.Lark_Mention_Owner_Mobile(wikiMeta.ownerName))

        let wikiOption = FocusPickerOption(id: wikiMeta.id,
                                           type: .wiki,
                                           meta: .wiki(mentionWikiMeta),
                                           isEnableMultipleSelect: false,
                                           isMultipleSelected: false,
                                           avatarID: self.avatarID,
                                           avatarKey: self.avatarKey,
                                           name: self.title,
                                           subTitle: NSAttributedString(string: wikiMeta.ownerName),
                                           desc: desc,
                                           tags: tags)
        return wikiOption
    }

}
