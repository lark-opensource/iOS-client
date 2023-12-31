//
//  GroupAdminViewModel.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2021/4/23.
//

import Foundation
import LKCommonsLogging
import LarkSDKInterface
import LarkContainer
import RxSwift
import LarkCore
import LarkTag
import LarkMessengerInterface
import LarkAccountInterface
import LarkModel
import LarkBizTag

public final class GroupAdminViewModel: UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver

    fileprivate static let logger = Logger.log(GroupAdminViewModel.self, category: "Module.IM.LarkChatSetting")
    @ScopedInjectedLazy var chatAPI: ChatAPI?
    @ScopedInjectedLazy private var serverNTPTimeService: ServerNTPTimeService?
    @ScopedInjectedLazy var passportUserService: PassportUserService?
    private var pushChatAdmin: Observable<PushChatAdmin>
    /// 追加自定义Tag
    public typealias AppendTagProvider = (_ chatter: Chatter) -> [LarkBizTag.TagType]?

    var datas: [ChatChatterItem] = []
    var chatId: String {
        chat.id
    }
    private var tenantId: String { passportUserService?.user.tenant.tenantID ?? "" }
    var chat: Chat
    // reload table刷新信号
    var reloadOb: Observable<Void> {
        reloadSubject.asObservable()
    }
    private let appendTagProvider: AppendTagProvider?
    var myUserId: String { userResolver.userID }
    // 默认不能选人的人
    public var defaultUnableSelectedIds: [String]
    private var reloadSubject = PublishSubject<Void>()
    private let disposeBag = DisposeBag()
    var title: String
    var initDisplayMode: ChatChatterDisplayMode
    private var isTrackImGroupAdminView = false

    init(resolver: UserResolver,
         chat: Chat,
         title: String,
         initDisplayMode: ChatChatterDisplayMode = .display,
         defaultUnableSelectedIds: [String] = [],
         pushChatAdmin: Observable<PushChatAdmin>,
         appendTagProvider: AppendTagProvider? = nil) {
        self.chat = chat
        self.title = title
        self.appendTagProvider = appendTagProvider
        self.defaultUnableSelectedIds = defaultUnableSelectedIds
        self.pushChatAdmin = pushChatAdmin
        self.initDisplayMode = initDisplayMode
        self.userResolver = resolver
    }

    func observeData() {
        let chatId = self.chatId
        chatAPI?.fetchChatAdminUsersWithLocalAndServer(chatId: chatId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (res) in
                guard let self = self else { return }
                self.datas = res.compactMap({ (chatter) -> ChatChatterWapper? in
                    self.wrapper(chatter)
                })
                if !self.datas.isEmpty {
                    self.tryTotrackImGroupAdminView(count: self.datas.count)
                }
                self.reloadSubject.onNext(())
            }, onError: { (error) in
                Self.logger.error("fetchChatAdminUsers error, error = \(error)")
            }).disposed(by: self.disposeBag)

        pushChatAdmin
            .filter { $0.chatId == chatId }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self else { return }
                self.datas = push.adminUsers.compactMap { (chatter) -> ChatChatterWapper? in
                    self.wrapper(chatter)
                }
                self.reloadSubject.onNext(())
            }).disposed(by: disposeBag)
    }

    /// 包装成 ChatChatterItem
    func wrapper(_ chatter: Chatter) -> ChatChatterWapper? {
        let item = ChatChatterWapper(
            chatter: chatter,
            itemName: self.itemName(for: chatter),
            itemTags: self.itemTags(for: chatter),
            itemCellClass: ChatChatterCell.self,
            itemTimeZoneId: chatter.timeZoneID,
            descInlineProvider: nil,
            descUIConfig: nil)
        return item
    }

    // 获取显示名
    func itemName(for chatter: Chatter) -> String {
        return chatter.displayName(
            chatId: chatId,
            chatType: chat.type,
            scene: chat.oncallId.isEmpty ? .groupMemberList : .oncall)
    }

    // 获取Tag：外部、群主、负责人、机器人等
    func itemTags(for chatter: Chatter) -> [TagDataItem]? {
        var result: [LarkBizTag.TagType] = appendTagProvider?(chatter) ?? []
        var tagDataItems: [TagDataItem] = []

        if chatter.tenantId == tenantId,
            chatter.workStatus.status == .onLeave {
            result.append(.onLeave)
        } else if self.serverNTPTimeService?.afterThatServerTime(time: chatter.doNotDisturbEndTime) ?? false { // 判断勿扰模式
            result.append(.doNotDisturb)
        }

        /// 未注册
        if !chatter.isRegistered {
            result.append(.unregistered)
        } else if chatter.isFrozen {
            result.append(.isFrozen)
            /// 如果出现暂停使用标签的时候 需要移除请假的标签
            result.removeAll { (tagType) -> Bool in
                tagType == .onLeave
            }
        }

        chatter.tagData?.tagDataItems.forEach { item in
            let isExternal = item.respTagType == .relationTagExternal
            if isExternal {
                tagDataItems.append(TagDataItem(tagType: .external,
                                                priority: Int(item.priority)))
            } else {
                let tagDataItem = LarkBizTag.TagDataItem(text: item.textVal,
                                                         tagType: item.respTagType.transform(),
                                                         priority: Int(item.priority))
                tagDataItems.append(tagDataItem)
            }
        }

        if chatter.type == .bot {
            result.append(.robot)
        }
        tagDataItems.append(contentsOf: chatter.eduTags.map({ tag in
            return TagDataItem(text: tag.title,
                               tagType: .customTitleTag,
                               frontColor: tag.style.textColor,
                               backColor: tag.style.backColor)
        }))
        tagDataItems.append(contentsOf: result.map({ type in
            return TagDataItem(tagType: type)
        }))

        return tagDataItems.isEmpty ? nil : tagDataItems
    }

    private func tryTotrackImGroupAdminView(count: Int) {
        guard !isTrackImGroupAdminView else { return }
        isTrackImGroupAdminView.toggle()
        NewChatSettingTracker.imGroupAdminView(chat: chat,
                                               myUserId: myUserId,
                                               isOwner: true,
                                               isAdmin: false,
                                               adminAmount: count)
    }
}
