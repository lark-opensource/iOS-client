//
//  GroupViewController.swift
//  Lark
//
//  Created by 刘晚林 on 2016/12/23.
//  Copyright © 2016年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import LarkUIKit
import LarkModel
import LarkSDKInterface
import LarkKeyCommandKit
import LarkMessengerInterface
import EENavigator
import LarkCore
import LarkFeatureGating
import UniverseDesignEmpty
import LarkSearchCore
import LarkContainer
import RustPB

final class GroupsViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource,
                            TableViewKeyboardHandlerDelegate, UserResolverWrapper {

    fileprivate var createdGroupTableView: UITableView = UITableView()

    fileprivate var joinedGroupTableView: UITableView = UITableView()

    fileprivate var createdGroups: [Chat] = []

    fileprivate var joinedGroups: [Chat] = []

    fileprivate var segmentView: SegmentView = {
        let segment = StandardSegment(withHeight: 40)
        segment.lineStyle = .adjust
        segment.backgroundColor = UIColor.ud.bgBody
        return SegmentView(segment: segment)
    }()

    fileprivate let disposeBag = DisposeBag()

    private let router: GroupsViewControllerRouter

    private let viewModel: GroupsViewModel
    private let newGroupBtnHidden: Bool
    private let chooseGroupHandler: ((UIViewController, Chat, ChatFromWhere) -> Void)?
    private let dismissHandler: (() -> Void)?

    private var createdTablekeyboardHandler: TableViewKeyboardHandler?
    private var joinedTablekeyboardHandler: TableViewKeyboardHandler?
    var userResolver: LarkContainer.UserResolver
    override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() +
            ((segmentView.segment.currentSelectedIndex == 0 ?
                createdTablekeyboardHandler : joinedTablekeyboardHandler)?.baseSelectiveKeyBindings ?? [])
    }

    init(
        viewModel: GroupsViewModel,
        router: GroupsViewControllerRouter,
        newGroupBtnHidden: Bool,
        chooseGroupHandler: ((UIViewController, Chat, ChatFromWhere) -> Void)?,
        dismissHandler: (() -> Void)?,
        resolver: UserResolver
    ) {
        viewModel.pageCount = Int(max(UIScreen.main.bounds.width, UIScreen.main.bounds.height) / 68 * 1.5 + 1)
        self.viewModel = viewModel
        self.router = router
        self.newGroupBtnHidden = newGroupBtnHidden
        self.chooseGroupHandler = chooseGroupHandler
        self.dismissHandler = dismissHandler
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        isToolBarHidden = true

        if !newGroupBtnHidden {
             let rightButton = LKBarButtonItem(title: BundleI18n.LarkContact.Lark_Legacy_Groupchat)
             rightButton.setBtnColor(color: UIColor.ud.colorfulBlue)
             rightButton.setProperty(font: UIFont.systemFont(ofSize: 16), alignment: .center)
             rightButton.addTarget(self, action: #selector(didClickCreateGroupButton), for: .touchUpInside)
             navigationItem.rightBarButtonItem = rightButton
        }

        self.view.addSubview(segmentView)
        segmentView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        createdGroupTableView.backgroundColor = UIColor.ud.bgBody
        createdGroupTableView.rowHeight = 68
        createdGroupTableView.tableFooterView = UIView()
        createdGroupTableView.separatorStyle = .none

        joinedGroupTableView.backgroundColor = UIColor.ud.bgBody
        joinedGroupTableView.rowHeight = 68
        joinedGroupTableView.tableFooterView = UIView()
        joinedGroupTableView.separatorStyle = .none

        segmentView.set(views:
            [(title: BundleI18n.LarkContact.Lark_Groups_MyGroups, view: createdGroupTableView),
             (title: BundleI18n.LarkContact.Lark_Legacy_GroupJoinedGroup, view: joinedGroupTableView)]
        )
        (segmentView.segment as? StandardSegment)?.selectedIndexDidChangeBlock = { [weak self] _, newIndex in
            let segmentTab: String = (newIndex == 1) ? "joined" : "created"
            if newIndex == 1 {
                ContactTracker.Group.Click.JoinedGroup()
            } else {
                ContactTracker.Group.Click.CreatedGroup()
            }
           self?.viewModel.trackClickGroupSegment(segment: segmentTab)
        }

        createdGroupTableView.delegate = self
        createdGroupTableView.dataSource = self
        joinedGroupTableView.delegate = self
        joinedGroupTableView.dataSource = self

        let name = String(describing: GroupsTableViewCell.self)
        createdGroupTableView.register(GroupsTableViewCell.self, forCellReuseIdentifier: name)
        joinedGroupTableView.register(GroupsTableViewCell.self, forCellReuseIdentifier: name)

        self.bindViewModel()

        createdTablekeyboardHandler = TableViewKeyboardHandler(
            options: [.selectFirstByDefault(selected: false),
                      .scrollPosition(position: .none),
                      .allowCellFocused(focused: Display.pad)]
        )
        createdTablekeyboardHandler?.delegate = self
        joinedTablekeyboardHandler = TableViewKeyboardHandler(
            options: [.selectFirstByDefault(selected: false),
                      .scrollPosition(position: .none),
                      .allowCellFocused(focused: Display.pad)]
        )
        joinedTablekeyboardHandler?.delegate = self

        self.viewModel.trackEnterContactGroups()
        MyGroupAppReciableTrack.myGroupPageFirstRenderCostTrack()
        ContactTracker.Group.View(resolver: userResolver)

        // Picker 埋点
        SearchTrackUtil.trackPickerManageGroupView()
    }

    @objc
    private func didClickCreateGroupButton() {
        presentGroupChatController(from: self)
    }

    override func closeBtnTapped() {
        dismissHandler?()
        super.closeBtnTapped()
    }

    override func backItemTapped() {
        dismissHandler?()
        super.backItemTapped()
    }

    func presentGroupChatController(from: UIViewController) {
        let createGroupBlock = makeCreateGroupBlock(from: from)
        let body = CreateGroupBody(createGroupBlock: createGroupBlock, from: .mygroup)
        navigator.present(body: body,
                                 from: from,
                                 prepare: { $0.modalPresentationStyle = LarkCoreUtils.formSheetStyle() })
    }

    private func makeCreateGroupBlock(from: UIViewController) -> (Chat?, UIViewController, Int64, [AddExternalContactModel], RustPB.Im_V1_CreateChatResponse.ChatPageLinkResult?) -> Void {
        return { (chat, vc, cost, notFriendContacts, _) in
            vc.dismiss(animated: true, completion: { [weak from, weak self] in
                guard let chat = chat, let from = from, let `self` = self else { return }
                let createGroupToChatInfo = CreateGroupToChatInfo(way: .unKnown,
                                                                  syncMessage: false,
                                                                  messageCount: 0,
                                                                  memberCount: Int(chat.userCount),
                                                                  cost: Int64(cost))
                let body = ChatControllerByChatBody(chat: chat,
                                                    fromWhere: .mygroup,
                                                    extraInfo: [CreateGroupToChatInfo.key: createGroupToChatInfo])
                self.navigator.showDetailOrPush(body: body,
                                                  wrap: LkNavigationController.self,
                                                  from: from,
                                                  completion: { [weak self] (_, _) in
                                                    // 创群成功后present加好友弹窗
                                                    self?.presentAddContactAlert(chatId: chat.id,
                                                                                 isNotFriendContacts: notFriendContacts,
                                                                                 from: from)
                })
            })
        }
    }

    private func presentAddContactAlert(chatId: String,
                                        isNotFriendContacts: [AddExternalContactModel],
                                        from: UIViewController?) {
        guard !isNotFriendContacts.isEmpty, let from = from else { return }
        // 人数为1使用单人alert
        if isNotFriendContacts.count == 1 {
            let contact = isNotFriendContacts[0]
            var source = Source()
            source.sourceType = .chat
            source.sourceID = chatId
            let addContactBody = AddContactApplicationAlertBody(userId: isNotFriendContacts[0].ID,
                                                                chatId: chatId,
                                                                source: source,
                                                                displayName: contact.name,
                                                                targetVC: from,
                                                                businessType: .groupConfirm)
            navigator.present(body: addContactBody, from: from)
            return
        }
        // 人数大于1使用多人alert
        let dependecy = MSendContactApplicationDependecy(source: .chat)
        let addContactApplicationAlertBody = MAddContactApplicationAlertBody(
                                contacts: isNotFriendContacts,
                                source: .createGroup,
                                dependecy: dependecy,
                                businessType: .groupConfirm)
        navigator.present(body: addContactApplicationAlertBody, from: from)
    }

    private func bindCraeteGroupLoadMore() {
        self.createdGroupTableView.addBottomLoadMoreView { [weak self] in
            guard let self = self else {
                return
            }
            self.viewModel.loadMoreManageGroup().asDriver(onErrorJustReturn: true)
                .drive(onNext: { [weak self] (isEnd) in
                    self?.createdGroupTableView.enableBottomLoadMore(!isEnd)
                }).disposed(by: self.disposeBag)
        }
    }

    private func bindJoinedGroupLoadMore() {
        self.joinedGroupTableView.addBottomLoadMoreView { [weak self] in
            guard let self = self else {
                return
            }
            self.viewModel.loadMoreJoinGroup().asDriver(onErrorJustReturn: true)
                .drive(onNext: { [weak self] (isEnd) in
                    self?.joinedGroupTableView.enableBottomLoadMore(!isEnd)
                }).disposed(by: self.disposeBag)
        }
    }

    private func bindViewModel() {
        self.loadingPlaceholderView.isHidden = false
        self.viewModel.loadData()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.loadingPlaceholderView.isHidden = true
            }, onError: { [weak self] error in
                if let apiError = error.underlyingError as? APIError {
                    MyGroupAppReciableTrack.myGroupPageError(errorCode: Int(apiError.code),
                                                             errorMessage: apiError.localizedDescription)
                } else {
                    MyGroupAppReciableTrack.myGroupPageError(errorCode: (error as NSError).code,
                                                             errorMessage: (error as NSError).localizedDescription)
                }
                self?.loadingPlaceholderView.isHidden = true
            }, onCompleted: { [weak self] in
                self?.addDataEmptyViewIfNeed()
            }).disposed(by: self.disposeBag)

        self.viewModel.createdGroupsObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (createdGroups) in
                self?.createdGroups = createdGroups
                self?.createdGroupTableView.reloadData()
                self?.bindCraeteGroupLoadMore()
            }).disposed(by: self.disposeBag)

        self.viewModel.joinedGroupsObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (createdGroups) in
                self?.joinedGroups = createdGroups
                self?.joinedGroupTableView.reloadData()
                self?.bindJoinedGroupLoadMore()
            }).disposed(by: self.disposeBag)
    }

    // MARK: - TableViewKeyboardHandlerDelegate
    func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        if handlerToGetTable === createdTablekeyboardHandler {
            return createdGroupTableView
        } else {
            return joinedGroupTableView
        }
    }
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        let group: LarkModel.Chat
        let fromWhere: ChatFromWhere
        if tableView == createdGroupTableView {
            group = createdGroups[indexPath.row]
            fromWhere = .mygroupCreated
        } else {
            group = joinedGroups[indexPath.row]
            fromWhere = .mygroupJoined
        }
        if let handler = chooseGroupHandler {
            handler(self, group, fromWhere)
        } else {
            router.didSelectBotWithGroup(self, chat: group, fromWhere: fromWhere)
        }
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.trackClickEnterChat(groupId: group.id)
        ContactTracker.Group.Click.Avatar()
    }
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == createdGroupTableView {
            return self.createdGroups.count
        } else {
            return self.joinedGroups.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let name = String(describing: GroupsTableViewCell.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: name) as? GroupsTableViewCell {
            if tableView == createdGroupTableView {
                cell.setContent(self.createdGroups[indexPath.row],
                                currentTenantId: self.viewModel.currentTenantId,
                                currentUserType: viewModel.currentUserType)
            } else {
                cell.setContent(self.joinedGroups[indexPath.row],
                                currentTenantId: self.viewModel.currentTenantId,
                                currentUserType: viewModel.currentUserType)
            }
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }
}

private extension GroupsViewController {

    private func addDataEmptyViewIfNeed() {
        func generateEmptyDataView() -> UDEmptyView {
            let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkContact.Lark_Legacy_Emptymygroup)
            return UDEmptyView(config: UDEmptyConfig(description: desc, type: .noGroup))
        }
        if self.createdGroups.isEmpty {
            let emptyDataView = generateEmptyDataView()
            self.createdGroupTableView.addSubview(emptyDataView)
            emptyDataView.useCenterConstraints = true
            emptyDataView.snp.makeConstraints { (make) in
                make.left.top.height.width.equalToSuperview()
            }
        }
        if self.joinedGroups.isEmpty {
            let emptyDataView = generateEmptyDataView()
            self.joinedGroupTableView.addSubview(emptyDataView)
            emptyDataView.useCenterConstraints = true
            emptyDataView.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.height.width.equalToSuperview()
            }
        }
    }
}
