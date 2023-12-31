//
//  CalendarShareForwardViewController.swift
//  Calendar
//
//  Created by Hongbin Liang on 8/14/23.
//

import Foundation
import LarkContainer
import LarkUIKit
import RxRelay
import RxSwift
import UniverseDesignButton
import UniverseDesignTabs
import LarkAlertController
import UniverseDesignActionPanel

struct CalendarShareParams {
    var calID: String
    var comment: String?
    var members: [Rust.CalendarMember]
    var forbiddenList: [String]

    typealias MemberCommit = Server.CalendarMemberCommit
    var memberCommits: [MemberCommit] {

        let transform = { (member: Rust.CalendarMember) -> MemberCommit in
            var commit = MemberCommit()

            switch member.accessRole {
            case .owner: commit.accessRole = .owner
            case .writer: commit.accessRole = .writer
            case .reader: commit.accessRole = .reader
            case .freeBusyReader: commit.accessRole = .freeBusyReader
            default: commit.accessRole = .unknown
            }

            if member.memberType == .individual {
                commit.memberType = .individual
                var user = MemberCommit.User()
                user.userID = member.memberID
                commit.user = user
            } else {
                commit.memberType = .group
                var group = MemberCommit.Group()
                group.groupID = member.memberID
                commit.group = group
            }
            return commit
        }

        return members.map(transform)
    }
}

protocol CalendarShareForwardVCDelegate: AnyObject {
    func finishShare(from: CalendarShareForwardViewController, params: CalendarShareParams)
}

class CalendarShareForwardViewController: UIViewController, UserResolverWrapper {

    var currentNavigationItem: UINavigationItem?
    weak var delegate: CalendarShareForwardVCDelegate?

    let userResolver: UserResolver

    @ScopedInjectedLazy var rustAPI: CalendarRustAPI?
    @ScopedInjectedLazy var calendarDependency: CalendarDependency?

    private var storedRightBarItem: UIBarButtonItem?
    private lazy var childVC: UIViewController = {
        return calendarDependency?.getForwardTabVC(delegate: self) ?? UIViewController()
    }()

    private let calContext: CalendarShareContext
    private var calParams: CalendarShareParams

    private let bag = DisposeBag()

    init(with context: CalendarShareContext, userResolver: UserResolver) {
        calContext = context
        self.userResolver = userResolver
        calParams = .init(calID: context.calID, members: [], forbiddenList: [])
        super.init(nibName: nil, bundle: nil)
        storedRightBarItem = multiSelectItem
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(childVC)
        childVC.view.frame = view.frame
        view.addSubview(childVC.view)
        childVC.didMove(toParent: self)
    }

    func resetNaviItemIfNeeded() {
        guard (currentNavigationItem?.rightBarButtonItem).isNil else { return }
        currentNavigationItem?.rightBarButtonItem = storedRightBarItem
    }

    private func finishSelect(result: ForwardSelectResult) {
        guard let rustAPI = rustAPI else { return }
        let (items, hasFilteredPrivate) = result
        if calContext.isManager {

            let shareCtxRequest = rustAPI.fetchCalendar(calendarID: calContext.calID)
            let memberRequest = rustAPI.getCalendarMembersWithCheck(calendarId: calContext.calID, userIds: items.userIds, chatIds: items.groupIds, ignoreTimeout: false)

            Observable.combineLatest(shareCtxRequest, memberRequest).take(1)
                .subscribeForUI(onNext: { [weak self] (calendarWithMember, membersCheckedResult) in
                    guard let self = self, let calendarWithMember = calendarWithMember else { return }
                    let (members, hasMemberInhibited, rejectedUsers) = membersCheckedResult
                    var membersAfterFiltered = members

                    self.change(toastStatus: .remove)
                    if self.storedRightBarItem != self.multiSelectItem { self.updateRightNaviButton(with: self.nextItem) }

                    let calendarPB = calendarWithMember.calendar
                    let originalServerM = calendarWithMember.members

                    let shareOptioins = calendarPB.shareOptions

                    if hasMemberInhibited { self.calParams.forbiddenList = rejectedUsers }

                    if shareOptioins.externalDefaultTopOption == .shareOptPrivate {
                        membersAfterFiltered = membersAfterFiltered.filter({ $0.relationType == .internal })
                    }

                    if hasMemberInhibited || membersAfterFiltered.count != items.count || hasFilteredPrivate {
                        self.change(toastStatus: .tips(I18n.Calendar_G_NoPermissionToAddCertainUsers_Toast, fromWindow: true))
                    }

                    guard !membersAfterFiltered.isEmpty else { return }

                    // 若默认权限设置不合法（高于 admin 最新配置）- follow new setting.
                    let innerDefault = min(shareOptioins.innerDefault, shareOptioins.innerDefaultTopOption).cd.mappedAccessRole ?? .freeBusyReader
                    let externalDefault = min(shareOptioins.externalDefault, shareOptioins.externalDefaultTopOption).cd.mappedAccessRole ?? .freeBusyReader

                    let lastEdited = self.calParams.members

                    let membersAfterAuth = membersAfterFiltered.map {
                        var member = $0
                        member.accessRole = $0.relationType == .external ? externalDefault : innerDefault

                        if let serverM = originalServerM.first(where: { $0.memberID == member.memberID }) {
                            if $0.relationType == .external {
                                member.accessRole = min(
                                    serverM.accessRole,
                                    shareOptioins.topOption(
                                        of: member.memberType,
                                        isExternal: member.relationType == .external
                                    ).cd.mappedAccessRole ?? .owner
                                )
                            } else {
                                member.accessRole = serverM.accessRole
                            }
                        }

                        if let lastEditedM = lastEdited.first(where: { $0.memberID == member.memberID }) {
                            member.accessRole = lastEditedM.accessRole
                        }

                        return member
                    }
                    let authContext = AuthRelatedContext(
                        calendarOwnerID: calendarPB.calendarOwnerID,
                        currentUID: self.userResolver.userID,
                        isManager: self.calContext.isManager,
                        shareOptions: shareOptioins
                    )
                    let authSettingVC = CalendarShareAuthSettingViewController(members: membersAfterAuth, authContext: authContext)
                    authSettingVC.delegate = self
                    self.navigationController?.pushViewController(authSettingVC, animated: true)
                }, onError: { [weak self] error in
                    guard let self = self else { return }

                    if error.errorType() == .calendarIsPrivateErr {
                        self.change(toastStatus: .failure(I18n.Calendar_G_CantSharePrivateCalendar))
                    } else if error.errorType() == .calendarIsDeletedErr {
                        self.change(toastStatus: .failure(I18n.Calendar_Common_CalendarDeleted))
                    } else {
                        self.change(toastStatus: .failure(I18n.Calendar_Bot_SomethingWrongToast))
                    }

                    self.updateRightNaviButton(with: self.nextItem)

                    CalendarBiz.shareLogger.info(error.localizedDescription)
                }).disposed(by: bag)
        } else {
            change(toastStatus: .remove)
            if storedRightBarItem != multiSelectItem { updateRightNaviButton(with: confirmItem) }
            rustAPI.getCalendarMembers(with: calContext.calID, userIds: items.userIds, chatIds: items.groupIds)
                .subscribeForUI { [weak self] members in
                    guard let self = self else { return }
                    if hasFilteredPrivate {
                        self.change(toastStatus: .tips(I18n.Calendar_G_NoPermissionToAddCertainUsers_Toast, fromWindow: true))
                    }
                    guard !members.isEmpty else { return }
                    let membersAfterAuth = members.map {
                        var member = $0
                        // server 不会读，无意义
                        member.accessRole = .unknownAccessRole
                        return member
                    }
                    self.leaveMessage(from: self, with: membersAfterAuth)
                } onError: { [weak self] error in
                    guard let self = self else { return }
                    self.change(toastStatus: .failure(I18n.Calendar_Bot_SomethingWrongToast))
                    CalendarBiz.shareLogger.info(error.localizedDescription)
                }.disposed(by: bag)
        }
    }

    private func leaveMessage(from: UIViewController, with selectedResults: [Rust.CalendarMember]) {

        let alertController = LarkAlertController()
        alertController.setTitle(text: I18n.Calendar_Detail_ShareSeparatelyTo, alignment: .left)

        let content = MessageLeavingContentView()
        let avatarInfos: [AvatarInfoTuple] = selectedResults.map { ($0.memberID, $0.avatarKey) }
        content.setupContent(with: calParams.comment, avatars: avatarInfos)
        alertController.setContent(view: content)
        alertController.addCancelButton()
        alertController.addPrimaryButton(
            text: I18n.Calendar_G_ShareTo_SendWithNumber_Button(number: avatarInfos.count),
            dismissCompletion: { [weak self, from] in
                guard let self = self else { return }
                from.change(toastStatus: .loading(info: I18n.Calendar_Share_Sharing, disableUserInteraction: false, fromWindow: true))
                self.calParams.members = selectedResults
                self.calParams.comment = content.inputTextView.text
                self.delegate?.finishShare(from: self, params: self.calParams)
                self.dismiss(animated: true)
            }
        )
        present(alertController, animated: true)
    }

    private func updateRightNaviButton(with item: UIBarButtonItem) {
        currentNavigationItem?.rightBarButtonItem = item
        storedRightBarItem = item
    }

    private lazy var multiSelectItem: LKBarButtonItem = {
        let item = LKBarButtonItem(title: I18n.Calendar_G_Multiselect)
        item.addTarget(self, action: #selector(multiBtnPressed), for: .touchUpInside)
        return item
    }()

    // 管理员
    private lazy var nextItem: LKBarButtonItem = {
        let item = LKBarButtonItem(title: I18n.Calendar_Share_NextStep, fontStyle: .medium)
        item.button.setTitleColor(.ud.textDisabled, for: .disabled)
        item.button.setTitleColor(.ud.primaryContentDefault.withAlphaComponent(0.6), for: .highlighted)
        item.button.setTitleColor(.ud.primaryContentDefault, for: .normal)
        item.addTarget(self, action: #selector(nextBtnPressed), for: .touchUpInside)
        return item
    }()

    private lazy var nextWithLoadingItem: UIBarButtonItem = {
        var btnConfig = UDButtonUIConifg.textBlue
        btnConfig.type = .custom(from: .middle, inset: 1, font: .ud.headline)
        let loadingWithNext = UDButton(btnConfig)
        loadingWithNext.contentHorizontalAlignment = .right
        loadingWithNext.setTitle(I18n.Calendar_Share_NextStep, for: .normal)
        loadingWithNext.showLoading()
        let item = UIBarButtonItem(customView: loadingWithNext)
        return item
    }()

    // 非管理员
    private lazy var confirmItem: UIBarButtonItem = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 90, height: 30))
        button.addTarget(self, action: #selector(confirmBtnPressed), for: .touchUpInside)
        button.setTitleColor(.ud.textDisabled, for: .disabled)
        button.setTitleColor(.ud.primaryContentDefault.withAlphaComponent(0.6), for: .highlighted)
        button.setTitleColor(.ud.primaryContentDefault, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.setTitle(I18n.Calendar_Common_Confirm, for: .normal)
        button.contentHorizontalAlignment = .right
        let item = UIBarButtonItem(customView: button)
        return item
    }()

    @objc
    private func multiBtnPressed() {
        guard let calendarDependency = calendarDependency else { return }
        let toItem = calContext.isManager ? nextItem : confirmItem
        toItem.isEnabled = false
        updateRightNaviButton(with: toItem)
        calendarDependency.changeForwardVCSelectType(vc: childVC, multi: true)
    }

    @objc
    private func nextBtnPressed() {
        guard let calendarDependency = calendarDependency else { return }
        updateRightNaviButton(with: nextWithLoadingItem)
        let results = calendarDependency.getForwardVCSelectedResult(vc: childVC)
        finishSelect(result: results)
    }

    @objc
    private func confirmBtnPressed() {
        guard let calendarDependency = calendarDependency else { return }
        change(toastStatus: .loading(info: I18n.Calendar_Common_Loading, disableUserInteraction: true))
        let results = calendarDependency.getForwardVCSelectedResult(vc: childVC)
        finishSelect(result: results)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension CalendarShareForwardViewController: UDTabsListContainerViewDelegate {
    func listView() -> UIView { view }
}

// Delegate - childVC
public typealias ForwardSelectResult = (items: [CalendarMemberSeed], hasFilteredPrivate: Bool)

extension CalendarShareForwardViewController: CalendarShareForwardDelegate {
    func didSelect(result: ForwardSelectResult) {
        change(toastStatus: .loading(info: I18n.Calendar_Common_Loading, disableUserInteraction: true))
        finishSelect(result: result)
    }

    func selectedChangedInMulti(itemNum: Int) {
        if calContext.isManager {
            nextItem.isEnabled = itemNum != 0
        } else {
            guard let button = confirmItem.customView as? UIButton else { return }
            button.setTitle(I18n.Calendar_G_CreateGroup_ConfirmNumber_Button(number: itemNum), for: .normal)
            button.isEnabled = itemNum != 0
        }
    }
}

// Delegate - middleVC
extension CalendarShareForwardViewController: CalendarShareAuthSettingDelegate {
    func didFinishEdit(from: CalendarShareAuthSettingViewController, with members: [Rust.CalendarMember]) {
        leaveMessage(from: from, with: members)
    }

    func authSettingChanged(from: CalendarShareAuthSettingViewController, with members: [Rust.CalendarMember]) {
        calParams.members = members
    }
}
