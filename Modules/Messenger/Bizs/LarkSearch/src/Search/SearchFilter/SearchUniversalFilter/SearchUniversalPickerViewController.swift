//
//  SearchUniversalPickerViewController.swift
//  LarkSearch
//
//  Created by sunyihe on 2022/8/26.
//

import UIKit
import Logger
import RxSwift
import LarkUIKit
import Foundation
import EENavigator
import LarkSearchCore
import LarkSDKInterface
import LarkSearchFilter
import UniverseDesignColor
import LarkAccountInterface
import LarkMessengerInterface
import ServerPB
import LarkContainer

public final class SearchUniversalPickerViewController: BaseUIViewController, PickerDelegate, UITextViewDelegate {
    var resolver: UserResolver

    var didFinishChooseItem: ((SearchUniversalPickerViewController, [ForwardItem]) -> Void)?

    private let currentAccount: User
    private let feedService: FeedSyncDispatchService
    private static let logger = Logger.log(SearchUniversalPickerViewController.self,
                                           category: "SearchUniversalPickerViewController")
    private let pickType: UniversalPickerType
    private var selectedItems: [Option] {
        get { picker.selected }
        set { picker.selected = newValue }
    }
    private(set) var isMultiSelectMode: Bool {
        get { picker.isMultiple }
        set { picker.isMultiple = newValue }
    }
    private let selectMode: SearchUniversalPickerBody.SelectMode

    private var isFirstEnter: Bool = true

    public var picker: ChatPicker
    public var containerViewWidth: CGFloat = 300

    private let disposeBag = DisposeBag()

    init(resolver: UserResolver,
         selectedItems: [ForwardItem],
         currentAccount: User,
         pickType: UniversalPickerType,
         picker: ChatPicker,
         selectMode: SearchUniversalPickerBody.SelectMode,
         feedService: FeedSyncDispatchService) {
        self.resolver = resolver
        self.currentAccount = currentAccount
        self.pickType = pickType
        self.feedService = feedService
        self.picker = picker
        self.selectMode = selectMode

        super.init(nibName: nil, bundle: nil)
        picker.delegate = self
        if !selectedItems.isEmpty {
            isFirstEnter = false
            if self.selectMode == .Multi {
                isMultiSelectMode = true
            }
            picker.selectedView.refreshCountTextView(count: selectedItems.count)
        }
        switch pickType {
        case .folder, .workspace:
            picker.defaultView = NoSelectView(pickType: pickType)
        case .filter:
            picker.defaultView = NoSelectView(pickType: pickType)
            picker.filterPickerResultViewWidth = {
                return self.containerViewWidth
            }
        case .chat(let types):
            picker.defaultView = SearchDefaultChatView(resolver: self.resolver,
                                                       feedService: feedService,
                                                       pickTypes: types,
                                                       selection: picker)
        case .userAndGroupChat:
            picker.defaultView = SearchDefaultChatView(resolver: self.resolver,
                                                       feedService: feedService,
                                                       pickTypes: .unlimited,
                                                       selection: picker)
        case .defaultType:
            break
        default: break
        }
        self.selectedItems = selectedItems
    }

    public convenience init(resolver: UserResolver,
                            selectedItems: [ForwardItem],
                            currentAccount: User,
                            pickType: UniversalPickerType,
                            selectMode: SearchUniversalPickerBody.SelectMode,
                            feedService: FeedSyncDispatchService,
                            enableMyAi: Bool = false,
                            supportFrozenChat: Bool? = false) {
        let pickerParam = ChatPicker.InitParam()
        pickerParam.includeOuterTenant = true
        pickerParam.supportFrozenChat = supportFrozenChat
        pickerParam.pickType = pickType
        pickerParam.includeMyAi = enableMyAi
        let picker = ChatPicker(resolver: resolver, frame: .zero, params: pickerParam)
        self.init(resolver: resolver,
                  selectedItems: selectedItems,
                  currentAccount: currentAccount,
                  pickType: pickType,
                  picker: picker,
                  selectMode: selectMode,
                  feedService: feedService)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        containerViewWidth = view.frame.width
        title = BundleI18n.LarkSearch.Lark_Legacy_SelectLark

        self.view.addSubview(picker)

        picker.frame = view.bounds
        picker.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        bindViewModel()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        containerViewWidth = view.frame.width
        switch pickType {
        case .filter(let customFilterInfo):
            if !self.selectedItems.isEmpty {
                self.picker.selectedView.isHidden = false
            }
            self.picker.triggerSearch()
        case .folder, .workspace, .chat, .userAndGroupChat, .defaultType:
            break
        default: break
        }
    }

    private func bindViewModel() {
        picker.selectedChangeObservable.bind(onNext: { [weak self] _ in self?.updateSelectedInfo() }).disposed(by: disposeBag)
        picker.isMultipleChangeObservable.bind(onNext: { [weak self] _ in self?.isMultipleChanged() }).disposed(by: disposeBag)

        self.isMultipleChanged()
    }

    private(set) lazy var sureButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 30))
        button.addTarget(self, action: #selector(didFinishPick), for: .touchUpInside)
        button.setTitleColor(UIColor.ud.textDisable, for: .disabled)
        button.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.6), for: .highlighted)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitle(BundleI18n.LarkSearch.Lark_Legacy_Sure, for: .normal)
        button.contentHorizontalAlignment = .right
        return button
    }()

    private(set) lazy var multiSelectItem: UIBarButtonItem = {
        let btnItem = LKBarButtonItem(title: BundleI18n.LarkSearch.Lark_Legacy_Select)
        btnItem.setProperty(font: UIFont.systemFont(ofSize: 16), alignment: .right)
        btnItem.setBtnColor(color: UIColor.ud.textTitle)
        btnItem.button.addTarget(self, action: #selector(didTapMultiSelect), for: .touchUpInside)
        return btnItem
    }()

    @objc
    func didFinishPick(isCreateGroup: Bool = false) {
        if let selectedItems = selectedItems as? [ForwardItem] {
            didFinishChooseItem?(self, selectedItems)
        }
    }

    @objc
    public func didTapMultiSelect() {
        self.isMultiSelectMode = true
    }

    public func unfold(_ picker: Picker) {
        switch pickType {
        case .folder, .workspace, .filter:
            showFolderWikiSelectedPicker()
        case .chat, .defaultType, .userAndGroupChat:
            showChatSelectedPicker()
        default: break
        }
    }

    private func showFolderWikiSelectedPicker() {
        let vc = UniversalPickerSelectedViewController(delegate: self.picker,
                                                      confirmTitle: sureButton.titleLabel?.text ?? BundleI18n.LarkSearch.Lark_Legacy_Sure,
                                                       pickType: pickType,
                                                       isFirstEnter: self.isFirstEnter,
                                                      completion: { [weak self] _ in
                                                        self?.didFinishPick()
                                                      })
        (try? Container.shared.getUserResolver(userID: currentAccount.userID))?.navigator.push(vc, from: self)
    }

    private func showChatSelectedPicker() {
        let body = PickerSelectedBody(
            picker: self.picker,
            confirmTitle: sureButton.titleLabel?.text ?? BundleI18n.LarkSearch.Lark_Legacy_Send,
            allowSelectNone: false,
            shouldDisplayCountTitle: false,
            completion: { [weak self] _ in
                self?.didFinishPick()
            })
        (try? Container.shared.getUserResolver(userID: currentAccount.userID))?.navigator.push(body: body, from: self)
    }

    private func updateSelectedInfo() {
        assert(Thread.isMainThread, "should occur on main thread!")
        if !picker.isMultiple, self.selectedItems.count == 1 {
            didFinishPick()
        }
        switch pickType {
        case .folder, .workspace, .filter:
            picker.defaultView = NoSelectView(pickType: pickType)
        case .chat(let types):
            picker.defaultView = SearchDefaultChatView(resolver: self.resolver,
                                                       feedService: feedService,
                                                       pickTypes: types,
                                                       selection: picker)
        case .userAndGroupChat:
            picker.defaultView = SearchDefaultChatView(resolver: self.resolver,
                                                       feedService: feedService,
                                                       pickTypes: .unlimited,
                                                       selection: picker)
        case .defaultType:
            break
        default: break
        }
        updateSureStatus()
        let idSet = Set(self.selectedItems.map { $0.optionIdentifier.id })
    }

    private func updateSureStatus() {
        self.updateSureButton(count: self.selectedItems.count)
        if self.selectedItems.isEmpty, isFirstEnter {
            self.sureButton.setTitleColor(UIColor.ud.primaryContentDefault.withAlphaComponent(0.6), for: .normal)
            self.sureButton.isEnabled = false
        } else {
            self.sureButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            self.sureButton.isEnabled = true
        }
    }

    func updateSureButton(count: Int) {
        var title = BundleI18n.LarkSearch.Lark_Legacy_Sure
        if count >= 1 {
            title = BundleI18n.LarkSearch.Lark_Legacy_Sure + "(\(count))"
        }
        self.sureButton.setTitle(title, for: .normal)
    }

    func isMultipleChanged() {
        self.navigationItem.leftBarButtonItem = self.leftBarButtonItem
        if isMultiSelectMode || self.selectMode == .Single {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: sureButton)
        } else {
            self.navigationItem.rightBarButtonItem = self.rightBarButtonItem
        }
        self.updateSureStatus()
    }

    private(set) lazy var leftBarButtonItem: UIBarButtonItem = {
        return addCancelItem()
    }()

    private(set) lazy var rightBarButtonItem: UIBarButtonItem? = {
        return self.multiSelectItem
    }()
}
