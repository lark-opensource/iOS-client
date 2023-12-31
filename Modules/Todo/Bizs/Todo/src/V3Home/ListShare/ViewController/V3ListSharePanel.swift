//
//  V3ListSharePanelViewController.swift
//  Todo
//
//  Created by GCW on 2022/12/23.
//

import Foundation
import LarkUIKit
import LarkContainer
import LarkSnsShare
import UniverseDesignIcon
import RxSwift
import RxCocoa
import EENavigator
import LarkEMM
import LKCommonsLogging
import TodoInterface
import LarkAccountInterface
import LarkSensitivityControl

final class V3ListSharePanel: UserResolverWrapper {
    var userResolver: LarkContainer.UserResolver
    weak var sourceVC: UIViewController?
    weak var shareBtn: UIView?

    private var applink: String
    private var handleShare: (() -> Void)?
    private let disposeBag = DisposeBag()
    private var container: Rust.TaskContainer

    @ScopedInjectedLazy private var listApi: TaskListApi?
    @ScopedInjectedLazy private var routeDependency: RouteDependency?

    private var currentUserId: String { userResolver.userID }
    // 用于过滤的ID数组
    private var selectedIds: [String] = []
    // 分享内容
    private lazy var contentContext = ShareContentContext.text(TextPrepare(content: "", customCallbackUserInfo: [:]))
    private lazy var avatarGroupView: AvatarGroupView = {
        let avatarGroupView = AvatarGroupView(style: .superBig)
        return avatarGroupView
    }()
    private var avatars: [CheckedAvatarViewData] = []
    private var sharePanel: LarkSharePanel?

    private static let logger = Logger.log(V3ListSharePanel.self, category: "Todo.V3ListSharePanel")

    init(
        resolver: UserResolver,
        container: Rust.TaskContainer,
        sourceVC: UIViewController,
        applink: String,
        handleShare: @escaping () -> Void, shareBtn: UIView?
    ) {
        self.userResolver = resolver
        self.container = container
        self.sourceVC = sourceVC
        self.shareBtn = shareBtn
        self.applink = applink
        self.handleShare = handleShare
        initAvatarsData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getDataSource() -> [[ShareSettingItem]] {
        let dataSource =
            [
                [
                    ShareSettingItem(
                        identifier: "inviteAssistant",
                        icon: UDIcon.getIconByKey(.memberAddOutlined, iconColor: UIColor.ud.iconN1),
                        title: I18N.Todo_ShareList_InviteCollaborators_Title,
                        subTitle: nil,
                        customView: nil,
                        handler: { [weak self] _ in
                            guard let self = self else { return }
                            self.closeSharePanel()
                            V3Home.Track.clickListInvite(with: self.container)
                            self.showInvitorPicker()
                        }
                    ),
                    ShareSettingItem(
                        identifier: "manageAssistant",
                        icon: UDIcon.getIconByKey(.groupOutlined, iconColor: UIColor.ud.iconN1),
                        title: I18N.Todo_ListCard_Collaborators_Text,
                        subTitle: nil,
                        customView: avatarGroupView,
                        handler: { [weak self] _ in
                            guard let self = self, let sourceVC = self.sourceVC else { return }
                            self.closeSharePanel()
                            V3Home.Track.clickListManage(with: self.container)
                            self.closeSharePanel()
                            let vm = V3ListShareViewModel(resolver: self.userResolver, taskListInput: self.container, scene: .manage)
                            let vc = V3ListShareViewController(resolver: self.userResolver, viewModel: vm, scene: .manage)
                            vc.handleCloseSharePanel = { [weak self] in
                                guard let self = self else { return }
                                self.sourceVC?.dismiss(animated: true)
                            }
                            let newVC = LkNavigationController(rootViewController: vc)
                            sourceVC.present(newVC, animated: true, completion: nil)
                        }
                    )
                ]
            ]
        return dataSource
    }

    func showSharePanel() {
        guard let sourceVC = sourceVC, let handleShare = handleShare else { return }
        // 侧边栏点击时，目前不会传shareBtn
        let shareBtn = shareBtn ?? UIView()
        let popConfig = PopoverMaterial(
            sourceView: shareBtn,
            sourceRect: shareBtn.bounds,
            direction: .up
        )
        let customSharePanel = LarkSharePanel(
            userResolver: userResolver,
            with: [.custom(
                CustomShareContext(
                    identifier: "shareToIM",
                    itemContext: CustomShareItemContext(
                        title: I18N.Todo_ShareList_ShareToChat_Title,
                        icon: UDIcon.getIconByKey(.forwardOutlined, iconColor: UIColor.ud.iconN1)
                    ),
                    content: CustomShareContent.text("", [:]),
                    action: { [weak self] (_, _, _) in
                        V3Home.Track.clickListSendToChat(with: self?.container)
                        handleShare()
                    }
                )
            ),
                .copy],
            shareContent: contentContext,
            on: sourceVC,
            popoverMaterial: popConfig,
            productLevel: "",
            scene: "",
            pasteConfig: .scPaste
        )
        customSharePanel.title = I18N.Todo_ShareList_Title
        customSharePanel.setShareSettingDataSource(dataSource: getDataSource())
        sharePanel = customSharePanel

        V3Home.Track.viewShareListPanel(with: container)
        sharePanel?.show({ [weak self] (result, type) in
            guard let self = self, let window = self.sourceVC?.view.window else { return }
            if result.isSuccess() {
                switch type {
                case .copy:
                    do {
                        V3Home.Track.clickListCopyLink(with: self.container)
                        let config = PasteboardConfig(token: Token("LARK-PSDA-task-list-link-copy"))
                        try SCPasteboard.generalUnsafe(config).string = self.applink
                        Utils.Toast.showTips(with: I18N.Lark_Legacy_CopySuccess, on: window)
                    } catch { }
                default:
                    break
                }
            }
        })
    }

    func showInvitorPicker() {
        guard let sourceVC = self.sourceVC else { return }
        var routeParams = RouteParams(from: sourceVC)
        routeParams.prepare = { $0.modalPresentationStyle = .formSheet }
        routeParams.wrap = LkNavigationController.self
        routeDependency?.showSharePicker(
            title: I18N.Todo_ShareList_InviteCollaborators_Title,
            selectedChatterIds: selectedIds,
            selectedCallback: { [weak self] (fromVC, userInfos, groupInfos) in
                guard let self = self else { return }
                var users = userInfos.map {
                    return MemberData(
                        userId: $0.identifier,
                        name: $0.name,
                        avatar: AvatarSeed(avatarId: $0.identifier, avatarKey: $0.avatarKey),
                        memberDepart: "",
                        memberType: .user
                    )
                }
                let groups = groupInfos.map {
                    return MemberData(
                        userId: $0.identifier,
                        name: $0.name,
                        avatar: AvatarSeed(avatarId: $0.identifier, avatarKey: $0.avatarKey),
                        memberDepart: "",
                        memberType: .group
                    )
                }
                users.append(contentsOf: groups)
                self.showShareManage(memberDatas: users, fromVC: fromVC)
            },
            params: routeParams
        )
    }

    func closeSharePanel() {
        guard let sharePanel = self.sharePanel else { return }
        sharePanel.dismiss(animated: true)
    }

    func showShareManage(memberDatas: [MemberData], fromVC: UIViewController?) {
        guard let fromVC = fromVC else { return }
        let invitor = V3ListShareViewModel.transformInviteData(container: container, memberDatas: memberDatas)
        let vm = V3ListShareViewModel(resolver: userResolver, taskListInput: self.container, scene: .share, invitorData: invitor)
        let vc = V3ListShareViewController(resolver: userResolver, viewModel: vm, scene: .share)
        vc.handleCloseSharePanel = { [weak self] in
            self?.sourceVC?.dismiss(animated: true)
        }
        let newVC = LkNavigationController(rootViewController: vc)
        fromVC.present(newVC, animated: true, completion: nil)
    }

    func initAvatarsData() {
        listApi?.getPagingTaskListMembers(with: container.guid, cursor: "", count: 10)
            .take(1).asSingle()
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] res in
                    guard let self = self else { return }
                    let avatars = res.taskListMembers.compactMap { (member: Rust.TaskListMember) -> CheckedAvatarViewData? in
                        var icon: CheckedAvatarViewData.IconType?
                        switch member.member.type {
                        case .user:
                            icon = .avatar(AvatarSeed(avatarId: member.member.user.userID, avatarKey: member.member.user.avatarKey))
                        case .group:
                            icon = .avatar(AvatarSeed(avatarId: member.member.chat.chatID, avatarKey: member.member.chat.avatarKey))
                        case .docs:
                            let height = CheckedAvatarView.Style.superBig.height
                            icon = .image(UDIcon.getIconByKey(.fileRoundDocxColorful, size: CGSize(width: height, height: height)))
                        case .app, .unknown:
                            return nil
                        @unknown default:
                            return nil
                        }
                        return CheckedAvatarViewData(icon: icon)
                    }
                    // 查找owner信息，构建过滤元素，添加owner与当前用户
                    var owner: Rust.TaskListMember?
                    for item in res.taskListMembers {
                        if item.member.member == .user(item.member.user), item.role == .owner {
                            owner = item
                            break
                        }
                    }
                    self.selectedIds.append(self.currentUserId)
                    if let ownerId = owner?.member.user.userID, ownerId != self.currentUserId {
                        self.selectedIds.append(ownerId)
                    }
                    // 大于两个头像则：1个头像+数字；否则是头像
                    let maxCount = avatars.count > 2 ? 1 : avatars.count
                    let remainCount: Int? = Int(res.totalCount) > maxCount ? (Int(res.totalCount) - maxCount) : nil
                    self.avatarGroupView.viewData = AvatarGroupViewData(
                        avatars: Array(avatars.prefix(maxCount)),
                        style: .superBig,
                        remainCount: remainCount
                    )
                },
                onError: { err in
                    Self.logger.error("initFetchTaskListMembers err: \(err)")
                })
            .disposed(by: disposeBag)
    }
}
