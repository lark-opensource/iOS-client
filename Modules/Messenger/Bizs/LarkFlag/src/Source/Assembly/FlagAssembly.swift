//
//  FlagAssembly.swift
//  LarkFlag
//
//  Created by phoenix on 2022/5/29.
//

import Foundation
import Swinject
import LarkAssembler
import BootManager
import LarkOpenFeed
import LarkMessageCore
import LarkChat
import LarkSetting
import LarkContainer
import RustPB
import LarkRustClient
import RxSwift
import LKCommonsLogging
import LKCommonsTracker
import Homeric
import LarkMessageBase
import LKLoadable

enum FlagSetting {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.flag") // Global
        return v
    }
    //是否开启兼容
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

/// FlagAssembly
public final class FlagAssembly: LarkAssemblyInterface {
    public init() {}

    @_silgen_name("Lark.Feed.Filter.Flag")
    static public func registerFlagListVC() {
        // 向FeedModuleVCFactory注册标记列表的VC
        FeedFilterTabSourceFactory.register(type: .flag,
                                            normalIcon: Resources.sidebar_filtertab_flag,
                                            selectedIcon: Resources.sidebar_filtertab_flag_selected,
                                            supportTempTop: false,
                                            titleProvider: {
            return BundleI18n.LarkFlag.Lark_IM_Marked_TabTitle
        }, responder: .subVC({ _, context -> FlagListViewController in
            guard let resolver = (context as? UserResolverWrapper)?.userResolver else {
                throw ContainerError.noResolver
            }
            SwiftLoadable.startOnlyOnce(key: "LarkFlag_LarkFlagAssembly_regist")
            let cellViewModelFactory = FlagCellViewModelFactory(userResolver: resolver)
            let dataDependency = try FlagDataDependencyImpl(userResolver: resolver)
            let context = FlagListMessageContext(resolver: resolver,
                                                 dragManager: DragInteractionManager(),
                                                 defaulModelSummerizeFactory: DefaultMesageSummerizeFactory(userResolver: resolver))
            let listVM = FlagListViewModel(userResolver: resolver, cellViewModelFactory: cellViewModelFactory, dataDependency: dataDependency, context: context)
            let feedContext = try resolver.resolve(assert: FeedContextService.self)
            let listController = FlagListViewController(viewModel: listVM, feedContext: feedContext)
            let dispatcher = RequestDispatcher(userResolver: resolver, label: "FlagListCellFactory")
            listController.cellFactory = FlagListCellFactory(
                dispatcher: dispatcher,
                tableView: listController.tableView
            )
            context.pageAPI = listController
            context.dataSourceAPI = listVM
            FlagActionFactory(
                dispatcher: dispatcher,
                controller: listController,
                assetsProvider: listVM
            ).registerActions()
            return listController
        }))
    }

    // MARK: - 注入PUSH服务
    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushFeedEntityPreviews, PushFeedHandler.init(resolver:))
        (Command.pushFlags, PushFlagHandler.init(resolver:))
        (Command.pushInboxCards, PushInboxHandler.init(resolver:))
        (Command.pushFeedFilterSettings, PushFeedFilterHandler.init(resolver:))
    }

    @_silgen_name("Lark.LarkFlag_LarkFlagAssembly_regist.LarkFlagAssembly")
    static public func cellFactoryRegister() {
        // 消息卡片注册
        // ContextScene = newChat
        FlagMessageDetailSubFactoryRegistery.register(RecalledContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(TextPostContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(ImageContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(BaseStickerContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(BaseVideoContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(BaseAudioContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(FileContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(FolderContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(LocationContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(ShareGroupContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(BaseVoteContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(NewVoteContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(BaseShareUserCardContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(RedPacketContentFactory.self)

        FlagMessageDetailSubFactoryRegistery.register(ReactionComponentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(MessageStatusComponentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(ChatterStatusLabelFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(ReplyComponentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(ReplyStatusComponentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(UrgentComponentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(UrgentTipsComponentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(ChatMergeForwardContentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(DocPreviewComponentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(URLPreviewComponentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(PinComponentFactory.self)
        FlagMessageDetailSubFactoryRegistery.register(TCPreviewContainerComponentFactory.self)

        // 注册列表页Component
        // ContextScene = pin
        FlagListMessageSubFactoryRegistery.register(PinNewVoteContentFactory.self)
        FlagListMessageSubFactoryRegistery.register(ThreadShareGroupContentFactory.self)
        FlagListMessageSubFactoryRegistery.register(ThreadShareUserCardContentFactory.self)
        FlagListMessageSubFactoryRegistery.register(PinEventShareComponentFactory.self)
        FlagListMessageSubFactoryRegistery.register(PinEventRSVPComponentFactory.self)
        FlagListMessageSubFactoryRegistery.register(PinMergeForwardContentFactory.self)
        FlagListMessageSubFactoryRegistery.register(PinRoundRobinComponentFactory.self)
        FlagListMessageSubFactoryRegistery.register(PinAppointmentComponentFactory.self)
    }
}
