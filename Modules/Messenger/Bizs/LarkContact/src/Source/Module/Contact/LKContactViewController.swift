//
//  LKContactViewController.swift
//  LarkContact
//
//  Created by Sylar on 2018/4/9.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import LarkContainer
import RxSwift
import EENavigator
import SnapKit
import LarkSDKInterface
import LarkModel
import LarkKeyboardKit
import LarkTraitCollection
import UniverseDesignColor
import LarkSetting

protocol ContactSearchable {
    var isPublic: Bool { get set }
    func search(text: String)
    func reloadData()
}

typealias ContactSearchableViewController = UIViewController & ContactSearchable

class LKContactViewController: BaseUIViewController, ContactSelect, UICollectionViewDelegate, UICollectionViewDataSource {

    let chatAPI: ChatAPI
    let chatterAPI: ChatterAPI

    private var selectedContactItems: [SelectedContactItem] = []

    // Navibar
    let multiSelectItem = LKBarButtonItem(title: BundleI18n.LarkContact.Lark_Legacy_Select)
    let cancelItem = LKBarButtonItem(title: BundleI18n.LarkContact.Lark_Legacy_Cancel)
    var sureButton: UIButton { return (sureItem.customView as? UIButton) ?? UIButton(frame: .zero) }
    let sureItem = UIBarButtonItem(customView: UIButton())

    var searchFieldWrapperView: SearchUITextFieldWrapperView?
    let selectedCollectionLayout = UICollectionViewFlowLayout()
    let selectedCollectionView: UICollectionView
    var collectionBottom: ConstraintItem { return selectedCollectionView.snp.bottom }
    var searchVC: ContactSearchableViewController
    var inputNavigationItem: UINavigationItem?
    var contactUserResolver: LarkContainer.UserResolver
    var enableEnterSearchDetail: Bool

    private lazy var customNavigationItem: UINavigationItem = {
        return inputNavigationItem ?? self.navigationItem
    }()
    private let disposeBag = DisposeBag()

    init(chatAPI: ChatAPI,
         chatterAPI: ChatterAPI,
         searchVC: ContactSearchableViewController,
         showSearch: Bool = true,
         resolver: UserResolver) {
        self.chatAPI = chatAPI
        self.chatterAPI = chatterAPI
        self.selectedCollectionView = UICollectionView(frame: .zero,
                                                       collectionViewLayout: selectedCollectionLayout)
        self.searchVC = searchVC
        self.contactUserResolver = resolver
        self.enableEnterSearchDetail = self.contactUserResolver.fg.staticFeatureGatingValue(with: .enableEnterSearchDetail)
        if showSearch {
            self.searchFieldWrapperView = SearchUITextFieldWrapperView()
            self.searchFieldWrapperView?.searchUITextField.autocorrectionType = .no
            if KeyboardKit.shared.keyboardType == .hardware && self.enableEnterSearchDetail {
                self.searchFieldWrapperView?.searchUITextField.autoFocus = true
            }
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !isToolBarHidden {
            if let toolbar = self.navigationController?.toolbar as? PickerToolBar {
                self.toolbarItems = toolbar.toolbarItems()
            }
        }
        configNaviBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedContactItems = dataSource.selectedContactItems()

        isNavigationBarHidden = false
        configNaviBar()
        if (navigationController?.toolbar as? PickerToolBar) != nil {
            isToolBarHidden = false
        } else {
            isToolBarHidden = true
        }

        multiSelectItem.button.addTarget(self, action: #selector(multiSelectDidClick), for: .touchUpInside)
        multiSelectItem.button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        multiSelectItem.button.setTitleColor(UIColor.ud.N900, for: .normal)

        cancelItem.button.addTarget(self, action: #selector(cancelDidClick), for: .touchUpInside)
        cancelItem.button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancelItem.button.setTitleColor(UIColor.ud.N900, for: .normal)

        sureButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        sureButton.setTitleColor(UIColor.ud.colorfulBlue.ud.withOver(UIColor.ud.N00.withAlphaComponent(0.5)),
                                 for: .disabled)
        sureButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        sureButton.contentHorizontalAlignment = .right
        sureButton.addTarget(self, action: #selector(sureDidClick), for: .touchUpInside)

        selectedCollectionLayout.scrollDirection = .horizontal
        selectedCollectionLayout.itemSize = CGSize(width: 30, height: 30)
        selectedCollectionLayout.minimumInteritemSpacing = 10
        selectedCollectionView.backgroundColor = UIColor.ud.N00
        selectedCollectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        selectedCollectionView.delegate = self
        selectedCollectionView.dataSource = self
        let collectionCellID = String(describing: ContactAvatarCollectionCell.self)
        selectedCollectionView.register(ContactAvatarCollectionCell.self,
                                        forCellWithReuseIdentifier: collectionCellID)
        if let searchField = searchFieldWrapperView {
            view.addSubview(searchField)
            if ((self.searchVC as? CollaborationSearchViewController ) != nil) || self.enableEnterSearchDetail {
                searchField.searchUITextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
            } else {
                searchField.searchUITextField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(searchTextClick)))
            }
            searchField.snp.makeConstraints { (make) in
                make.top.right.left.equalToSuperview()
            }

            view.insertSubview(selectedCollectionView, belowSubview: searchField)
            selectedCollectionView.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.top.equalTo(searchField.snp.bottom)
                make.height.equalTo(44)
            }
        } else {
            view.addSubview(selectedCollectionView)
            selectedCollectionView.snp.makeConstraints { (make) in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(44)
            }
        }

        addChild(searchVC)
        view.addSubview(searchVC.view)
        searchVC.view.isHidden = true
        searchVC.view.snp.makeConstraints { (make) in
            make.top.equalTo(collectionBottom)
            make.left.right.bottom.equalToSuperview()
        }

        dataSource.getSelectedObservable
            .subscribe(onNext: { [weak self] items in
                guard let self = self else { return }
                let originCount = self.selectedContactItems.count
                let totalCount = items.count
                let sureTitle = BundleI18n.LarkContact.Lark_Legacy_ConfirmInfo + "(\(totalCount))"
                self.sureButton.setTitle(sureTitle, for: .normal)

                self.sureButton.sizeToFit()
                if self.dataSource.isSelectEmpty {
                    self.sureButton.isEnabled = self.configuration.allowSelectNone
                } else {
                    self.sureButton.isEnabled = true
                }

                self.selectedContactItems = items
                UIView.performWithoutAnimation {
                    self.selectedCollectionView.reloadData()
                }
                if totalCount > originCount {
                    self.selectedCollectionView.scrollToItem(at: IndexPath(item: totalCount - 1, section: 0), at: .right, animated: true)
                }
                func showCollectionViewIfNeeded(_ show: Bool) {
                    if show {
                        let topConstraints = self.searchFieldWrapperView?.snp.bottom ?? self.view.snp.top
                        self.selectedCollectionView.isHidden = false
                        self.selectedCollectionView.snp.remakeConstraints { (make) in
                            make.left.right.equalToSuperview()
                            make.height.equalTo(44)
                            make.top.equalTo(topConstraints)
                        }
                    } else {
                        let bottomConstraints = self.searchFieldWrapperView?.snp.bottom ?? self.view.snp.top
                        self.selectedCollectionView.isHidden = true
                        self.selectedCollectionView.snp.remakeConstraints { (make) in
                            make.left.right.equalToSuperview()
                            make.height.equalTo(44)
                            make.bottom.equalTo(bottomConstraints)
                        }
                    }
                }

                if case .multi = self.configuration.style {
                    showCollectionViewIfNeeded(totalCount != 0)
                } else if case .singleMultiChangeable = self.configuration.style, self.configuration.singleMultiChangeableStatus == .multi {
                    showCollectionViewIfNeeded(totalCount != 0)
                } else {
                    showCollectionViewIfNeeded(false)
                }
            })
            .disposed(by: disposeBag)

        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.configNaviBar()
            }).disposed(by: disposeBag)
    }

    // MARK: NaviBar
    func configNaviBar() {
        let addBackOrCloseItem = { [weak self ] in
            guard let strongSelf = self else { return }
            if strongSelf.hasBackPage {
                strongSelf.addBackItem()
            } else if strongSelf.presentingViewController != nil {
                strongSelf.addCloseItem()
            } else {
                strongSelf.customNavigationItem.leftBarButtonItem = nil
            }
        }

        switch style {
        case .multi:
            // 多选
            addBackOrCloseItem()
            if !configuration.hiddenSureItem {
                customNavigationItem.rightBarButtonItem = sureItem
            }
        case .single:
            // 单选： 只有返回
            addBackOrCloseItem()
        case .singleMultiChangeable:
            switch singleMultiChangeableStatus {
            case .single:
                // 默认单选： 返回 + 多选
                addBackOrCloseItem()
                customNavigationItem.rightBarButtonItem = multiSelectItem
            case .multi:
                // 默认多选： 取消 + 确定
                customNavigationItem.leftBarButtonItem = cancelItem
                customNavigationItem.rightBarButtonItem = sureItem
            }
        }

        if case .singleMultiChangeable = style, singleMultiChangeableStatus == .multi {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        } else {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }

    @objc
    func multiSelectDidClick() {
        guard case .singleMultiChangeable = style, singleMultiChangeableStatus == .single else {
            return
        }
        singleMultiChangeableStatus = .multi
        configNaviBar()
        searchVC.reloadData()
    }

    @objc
    func cancelDidClick() {
        guard case .singleMultiChangeable = style, singleMultiChangeableStatus == .multi else {
            return
        }
        singleMultiChangeableStatus = .single
        dataSource.reset()
        configNaviBar()
        selectedCollectionView.reloadData()
        searchVC.reloadData()
    }

    @objc
    func sureDidClick() {
        if let toolBar = self.navigationController?.toolbar as? SyncMessageToolbar {
            contactPicker.finishSelect(extra: toolBar.syncRecord)
        } else {
            contactPicker.finishSelect()
        }
    }

    // MARK: SearchView & CollectionView
    @objc
    fileprivate func searchTextChanged() {
        guard let searchField = searchFieldWrapperView else { return }
        view.bringSubviewToFront(searchVC.view)
        searchVC.view.isHidden = (searchField.searchUITextField.text ?? "").isEmpty
        if searchField.searchUITextField.markedTextRange == nil {
            searchVC.search(text: searchField.searchUITextField.text ?? "")
        }
    }

    @objc
    fileprivate func searchTextClick() {
        let host = DomainSettingManager.shared.currentSetting["applink"]?.first ?? "applink.feishu.cn"
        let urlString = "https://" + host + "/client/search/open?target=CONTACTS&source=contacts_list"
        if let url = URL(string: urlString) {
            self.contactUserResolver.navigator.open(url, from: self)
        }
    }

    // MARK: - UICollectionViewDelegate, UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        guard let cell = collectionView.cellForItem(at: indexPath) as? ContactAvatarCollectionCell else {
            return
        }
        if let cellID = cell.cellID {
            let item = selectedContactItems[indexPath.row]
            if case .chatter(let chatterInfo) = item {
                self.dataSource.removeChatter(chatterInfo)
            }
            dataSource.removeChat(chatId: cellID)
            dataSource.removeMail(mail: cellID)
            dataSource.removeMeetingGroup(groupChatId: cellID)
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedContactItems.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier = String(describing: ContactAvatarCollectionCell.self)
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? ContactAvatarCollectionCell else {
            return UICollectionViewCell()
        }

        let item = self.selectedContactItems[indexPath.row]
        switch item {
        case .chatter(let chatterInfo):
            let chatterId = chatterInfo.ID
            cell.cellID = chatterId
            let chatterAPI = self.chatterAPI
            Observable.just(chatterAPI.getChatterFromLocal(id: chatterId))
                .flatMap { (chatter) -> Observable<Chatter?> in
                    if let chatter = chatter {
                        // .observeOn(MainScheduler.instance) is not neccessory
                        // because we want to be sure that when we have the corresponding chatter locally,
                        // the observable sends its noNext signal synchronously
                        return Observable.just(chatter)
                    } else {
                        return chatterAPI.getChatter(id: chatterId).observeOn(MainScheduler.instance)
                    }
                }
                .subscribe(onNext: { (chatter) in
                    if let chatter = chatter, (cell.cellID ?? "") == chatter.id {
                        cell.set(entityId: chatter.id, avatarKey: chatter.avatarKey)
                    }
                })
                .disposed(by: self.disposeBag)
        case .bot(let bot):
            cell.set(entityId: bot.id, avatarKey: bot.avatarKey)
        case .chat(let chatId), .meetingGroup(let chatId):
            cell.cellID = chatId
            let chatAPI = self.chatAPI
            chatAPI.fetchChat(by: chatId, forceRemote: false)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { (chat) in
                    if let chat = chat, (cell.cellID ?? "") == chat.id {
                        cell.set(entityId: chat.id, avatarKey: chat.avatarKey)
                    }
                })
                .disposed(by: self.disposeBag)
        case .mail(let mail):
            cell.cellID = mail
            cell.set(mail: mail)
        case .unknown:
            break
        }

        return cell
    }
}

extension LKContactViewController {

    var selectedExternalChatterIds: [String] {
        var externalChatterIds: [String] = []
        for item in self.selectedContactItems {
            if case .chatter(let chatterInfo) = item {
                if chatterInfo.isExternal {
                    externalChatterIds.append(chatterInfo.ID)
                }
            }
        }
        return externalChatterIds
    }

}
