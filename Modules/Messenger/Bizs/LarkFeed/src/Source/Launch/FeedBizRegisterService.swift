//
//  FeedBizRegisterService.swift
//  LarkFeed
//
//  Created by aslan on 2022/2/14.
//

import UIKit
import Foundation
import Swinject
import LarkContainer
import AppContainer
import LarkFeedBanner
import LarkAppConfig
import LarkNavigation
import EENavigator
import RustPB
import LarkModel
import LarkMessengerInterface
import LarkSDKInterface
import LarkAccountInterface
import LarkOpenFeed
import LarkUIKit
import RxSwift
import LarkTab
import UniverseDesignDrawer
import LKLoadable
import LarkFeedBase

public final class FeedBizRegisterService {

    init() {}

    public func regist(container: Container) {
        registerFeedListViewModels(container: container)
        registerFeedListViewControllers(container: container)
        registerFeedCard(container: container)
        registerHeaders()
        registerSideBarVC(container)
        assemblePad(container)
        otherBizRegister(container)
        _ = FeedFeatureGatingImpl()
    }

    // MARK: - FeedViewModelFactory 注册各个type的ListVM
    func registerFeedListViewModels(container: Container) {
        FeedViewModelFactory.register(type: .message, viewModelBuilder: { _, context -> FeedListViewModel in
            guard let resolver = (context as? UserResolverWrapper)?.userResolver else {
                throw ContainerError.noResolver
            }
            return try resolver.resolve(assert: AllFeedListViewModel.self)
        })

        FeedViewModelFactory.register(type: .general, viewModelBuilder: { type, context -> FeedListViewModel in
            guard let resolver = (context as? UserResolverWrapper)?.userResolver else {
                throw ContainerError.noResolver
            }
            let dependency = try resolver.resolve(assert: FeedListViewModelDependency.self)
            let baseDependency = try resolver.resolve(assert: BaseFeedsViewModelDependency.self)
            let feedContext = try resolver.resolve(assert: FeedContextService.self)
            return FeedListViewModel(filterType: type,
                                     dependency: dependency,
                                     baseDependency: baseDependency,
                                     feedContext: feedContext)
        })

        FeedViewModelFactory.register(type: .done, viewModelBuilder: { type, context -> FeedListViewModel in
            guard let resolver = (context as? UserResolverWrapper)?.userResolver else {
                throw ContainerError.noResolver
            }
            let dependency = try resolver.resolve(assert: FeedListViewModelDependency.self)
            let baseDependency = try resolver.resolve(assert: BaseFeedsViewModelDependency.self)
            let feedContext = try resolver.resolve(assert: FeedContextService.self)
            return DoneFeedListViewModel(filterType: type,
                                         dependency: dependency,
                                         baseDependency: baseDependency,
                                         feedContext: feedContext)
        })

        FeedViewModelFactory.register(type: .mute, viewModelBuilder: { type, context -> FeedListViewModel in
            guard let resolver = (context as? UserResolverWrapper)?.userResolver else {
                throw ContainerError.noResolver
            }
            let dependency = try resolver.resolve(assert: FeedListViewModelDependency.self)
            let baseDependency = try resolver.resolve(assert: BaseFeedsViewModelDependency.self)
            let feedContext = try resolver.resolve(assert: FeedContextService.self)
            return FeedMuteListViewModel(filterType: type,
                                         dependency: dependency,
                                         baseDependency: baseDependency,
                                         feedContext: feedContext)
        })

        FeedViewModelFactory.register(type: .at, viewModelBuilder: { type, context -> FeedListViewModel in
            guard let resolver = (context as? UserResolverWrapper)?.userResolver else {
                throw ContainerError.noResolver
            }
            let pushCenter = try resolver.userPushCenter
            let pushFeedFilterSettings = pushCenter.observable(for: LarkFeed.FiltersModel.self)
            let atDependency = AtViewModelDependencyImpl(
                pushFeedFilterSettings: pushFeedFilterSettings,
                feedAPI: try resolver.resolve(assert: FeedAPI.self))
            let dependency = try resolver.resolve(assert: FeedListViewModelDependency.self)
            let baseDependency = try resolver.resolve(assert: BaseFeedsViewModelDependency.self)
            let feedContext = try resolver.resolve(assert: FeedContextService.self)
            return AtFeedListViewModel(filterType: type,
                                       atDependency: atDependency,
                                       dependency: dependency,
                                       baseDependency: baseDependency,
                                       feedContext: feedContext)
        })
    }

    // MARK: - FeedFilterTabSourceFactory 注册各个Tab的VC
    func registerFeedListViewControllers(container: Container) {

        func getAllFeedListVC(filterType: Feed_V1_FeedFilter.TypeEnum, context: Any) throws -> FeedListViewController {
            guard let resolver = (context as? UserResolverWrapper)?.userResolver else {
                throw ContainerError.noResolver
            }
            let allFeedsViewModel = try resolver.resolve(assert: AllFeedListViewModel.self)
            allFeedsViewModel.trySwitchFirstTab(filterType)
            let feedVC = try AllFeedListViewController(allFeedsViewModel: allFeedsViewModel)
            return feedVC
        }

        func getFeedListVC(for type: Feed_V1_FeedFilter.TypeEnum, context: Any) throws -> FeedListViewController {
            let vm = try FeedViewModelFactory.viewModel(for: type, context: context)
            let feedVC = try FeedListViewController(listViewModel: vm)
            return feedVC
        }

        // 全部
        FeedFilterTabSourceFactory.register(type: .inbox,
                                            normalIcon: Resources.sidebar_filtertab_message,
                                            selectedIcon: Resources.sidebar_filtertab_message_selected,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Feed_FilterAll
        }, responder: .subVC({ _, context -> FeedListViewController in
            return try getAllFeedListVC(filterType: .inbox, context: context)
        }))

        // 消息
        FeedFilterTabSourceFactory.register(type: .message,
                                            normalIcon: Resources.sidebar_filtertab_message,
                                            selectedIcon: Resources.sidebar_filtertab_message_selected,
                                            removeMode: .delay,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Feed_FilterChats
        }, responder: .subVC({ _, context -> FeedListViewController in
            return try getAllFeedListVC(filterType: .message, context: context)
        }))

        // 免打扰
        FeedFilterTabSourceFactory.register(type: .mute,
                                            normalIcon: Resources.sidebar_filtertab_mute,
                                            selectedIcon: Resources.sidebar_filtertab_mute_selected,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Feed_FilterMuted
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // @我
        FeedFilterTabSourceFactory.register(type: .atMe,
                                            normalIcon: Resources.sidebar_filtertab_at,
                                            selectedIcon: Resources.sidebar_filtertab_at_selected,
                                            removeMode: .delay,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Feed_FilterMentions
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 未读
        FeedFilterTabSourceFactory.register(type: .unread,
                                            normalIcon: Resources.sidebar_filtertab_unread,
                                            selectedIcon: Resources.sidebar_filtertab_unread_selected,
                                            removeMode: .delay,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Feed_FilterUnread
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 云文档
        FeedFilterTabSourceFactory.register(type: .doc,
                                            normalIcon: Resources.sidebar_filtertab_doc,
                                            selectedIcon: Resources.sidebar_filtertab_doc_selected,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Feed_FilterDocs
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 单聊
        FeedFilterTabSourceFactory.register(type: .p2PChat,
                                            normalIcon: Resources.sidebar_filtertab_p2pchat,
                                            selectedIcon: Resources.sidebar_filtertab_p2pchat_selected,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Feed_FilterPrivateChats
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 群聊
        FeedFilterTabSourceFactory.register(type: .groupChat,
                                            normalIcon: Resources.sidebar_filtertab_group,
                                            selectedIcon: Resources.sidebar_filtertab_group_selected,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Feed_FilterGroupChats
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 机器人
        FeedFilterTabSourceFactory.register(type: .bot,
                                            normalIcon: Resources.sidebar_filtertab_robot,
                                            selectedIcon: Resources.sidebar_filtertab_robot_selected,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Feed_FilterBots
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 服务台
        FeedFilterTabSourceFactory.register(type: .helpDesk,
                                            normalIcon: Resources.sidebar_filtertab_helpdesk,
                                            selectedIcon: Resources.sidebar_filtertab_helpdesk_selected,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Feed_FilterHelpDesk
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 话题群
        FeedFilterTabSourceFactory.register(type: .topicGroup,
                                            normalIcon: Resources.sidebar_filtertab_chatTopic,
                                            selectedIcon: Resources.sidebar_filtertab_chatTopic_selected,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Feed_FilterCircles
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 话题
        FeedFilterTabSourceFactory.register(type: .thread,
                                            normalIcon: Resources.sidebar_filtertab_msgThread,
                                            selectedIcon: Resources.sidebar_filtertab_msgThread_selected,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_IM_FeedFilter_Thread_Title
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 已完成
        FeedFilterTabSourceFactory.register(type: .done,
                                            normalIcon: Resources.sidebar_filtertab_done,
                                            selectedIcon: Resources.sidebar_filtertab_done_selected,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Feed_FilterDone
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 密聊
        FeedFilterTabSourceFactory.register(type: .cryptoChat,
                                            normalIcon: Resources.sidebar_filtertab_chatSecret,
                                            selectedIcon: Resources.sidebar_filtertab_chatSecret_selected,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Feed_FilterSecretChats
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 团队
        FeedFilterTabSourceFactory.register(type: .team,
                                            supportTempTop: false,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Project_T_TeamMenuTab
        }, responder: .subVC({ _, context -> FeedTeamViewController in
            guard let resolver = (context as? UserResolverWrapper)?.userResolver else {
                throw ContainerError.noResolver
            }
            let context = try resolver.resolve(assert: FeedContextService.self)
            let vm = try resolver.resolve(assert: FeedTeamViewModel.self)
            let teamVC = FeedTeamViewController(
                viewModel: vm,
                context: context)
            return teamVC
        }))

        // 标签
        FeedFilterTabSourceFactory.register(type: .tag,
                                            supportTempTop: false,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Core_LabelTab_Title
        }, responder: .subVC({ _, context -> FeedModuleVCInterface in
            guard let resolver = (context as? UserResolverWrapper)?.userResolver else {
                throw ContainerError.noResolver
            }
            let vm = try resolver.resolve(assert: LabelMainListViewModel.self)
            let vc = LabelMainListViewController(vm: vm)
            vm.labelContext.vc = vc
            return vc
        }))

        // 超7天未读分组
        FeedFilterTabSourceFactory.register(type: .unreadOverDays,
                                            normalIcon: Resources.sidebar_filtertab_unreadOverDays,
                                            selectedIcon: Resources.sidebar_filtertab_unreadOverDays_selected,
                                            removeMode: .delay,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_Core_UnreadOver1Week_Tab
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 临时会议群分组
        FeedFilterTabSourceFactory.register(type: .instantMeetingGroup,
                                            normalIcon: Resources.sidebar_filtertab_meeting,
                                            selectedIcon: Resources.sidebar_filtertab_meeting_selected,
                                            removeMode: .delay,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_IM_MeetingGroups_Label
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 日程会议群分组
        FeedFilterTabSourceFactory.register(type: .calendarGroup,
                                            normalIcon: Resources.sidebar_filtertab_cal,
                                            selectedIcon: Resources.sidebar_filtertab_cal_selected,
                                            removeMode: .delay,
                                            titleProvider: {
            return BundleI18n.LarkFeed.Lark_IM_EventMeetings_Filter
        }, responder: .subVC({ type, context -> FeedListViewController in
            return try getFeedListVC(for: type, context: context)
        }))

        // 三栏注册标签
        FeedFilterListSourceFactory.register(
            type: .tag,
            itemsProvider: { context, subTabId -> [FeedFilterListItemInterface] in
                guard let resolver = context as? UserResolver else {
                    throw ContainerError.noResolver
                }
                let vm = try resolver.resolve(assert: LabelMainListViewModel.self)
                let items = vm.dataModule.store.getLabels().map { labelViewModel in
                    FeedFilterListItemModel.transformLabelModel(labelViewModel, subTabId)
                }
                return items
            }, observableProvider: { context -> Observable<Void> in
                guard let resolver = context as? UserResolver else {
                    throw ContainerError.noResolver
                }
                let vm = try resolver.resolve(assert: LabelMainListViewModel.self)
                return vm.dataModule.dataObservable.map({ _ in })
            })

        // 三栏注册团队
        FeedFilterListSourceFactory.register(
            type: .team,
            itemsProvider: { context, subTabId -> [FeedFilterListItemInterface] in
                guard let resolver = context as? UserResolver else {
                    throw ContainerError.noResolver
                }
                let vm = try resolver.resolve(assert: FeedTeamViewModel.self)
                let items = vm.teamUIModel.teamModels.map { teamModel in
                    FeedFilterListItemModel.transformTeamModel(teamModel, subTabId)
                }
                return items
            }, observableProvider: { context -> Observable<Void> in
                guard let resolver = context as? UserResolver else {
                    throw ContainerError.noResolver
                }
                let context = try resolver.resolve(assert: FeedContextService.self)
                let vm = try resolver.resolve(assert: FeedTeamViewModel.self)
                return vm.dataSourceObservable.map({ _ in })
            })

        SideBarMenuSourceFactory.register(
            tab: Tab.feed,
            contentPercentProvider: { _, type in
                var needCustom = false
                switch type {
                case .click(let string):
                    needCustom = string == FeedSideBarClick.tag
                case .pan:
                    needCustom = true
                }
                if needCustom {
                    return Cons.contentPercent
                }
                return UDDrawerValues.contentDefaultPercent
            }, subCustomVCProvider: { (userResolver, type, vc) in
                var needCustom = false
                switch type {
                case .click(let string):
                    if string == FeedSideBarClick.tag {
                        FeedTracker.ThreeColumns.View.mobileGroupViewByClick()
                        needCustom = true
                    }
                case .pan:
                    FeedTracker.ThreeColumns.View.mobileGroupViewBySlide()
                    needCustom = true
                }
                if needCustom {
                    let body = SideBarFilterBody(hostProvider: vc)
                    let result = userResolver.navigator.response(for: body).resource as? UIViewController
                    return result
                }
                return nil
            })

        // Action Factory
        FeedActionFactoryManager.register(factory: { FeedActionDoneFactory() })
        FeedActionFactoryManager.register(factory: { FeedActionDebugFactory() })
        FeedActionFactoryManager.register(factory: { FeedActionJumpFactory() })
        FeedActionFactoryManager.register(factory: { FeedActionShortcutFactory() })
        FeedActionFactoryManager.register(factory: { FeedActionClearBadgeFactory() })
        FeedActionFactoryManager.register(factory: { FeedActionLabelFactory() })
        FeedActionFactoryManager.register(factory: { FeedActionMuteFactory() })
        FeedActionFactoryManager.register(factory: { FeedActionDeleteLabelFactory() })
        FeedActionFactoryManager.register(factory: { FeedActionRemoveFeedFactory() })
    }

    // MARK: - 注册SideBarvc
    func registerSideBarVC(_ container: Container) {
        SideBarVCRegistry.registerSideBarVC { userResolver, vc in
            let body = MineMainBody(hostProvider: vc)
            let response = userResolver.navigator.response(for: body)
            return response.resource as? UIViewController
        }
        SideBarVCRegistry.registerSideBarFilterVC { userResolver, vc in
            let body = FeedFilterBody(hostProvider: vc)
            let response = userResolver.navigator.response(for: body)
            return response.resource as? UIViewController
        }
    }

    // MARK: - 注册feed card
    private func registerFeedCard(container: Container) {
        FeedCardContext.registerCell = { tableView, userResolver in
            guard let feedCardModuleManager = try? userResolver.resolve(assert: FeedCardModuleManager.self) else { return }
            feedCardModuleManager.modules.forEach { (_, module: FeedCardBaseModule) in
                tableView.register(FeedCardCell.self, forCellReuseIdentifier: String(module.type.rawValue))
            }
        }

        FeedCardContext.cellViewModelBuilder = { feedPreview, userResolver, feedCardModuleManager, bizType, filterType, extraData in
            let cellVM = FeedCardCellViewModel.build(feedPreview: feedPreview,
                                                     userResolver: userResolver,
                                                     feedCardModuleManager: feedCardModuleManager,
                                                     bizType: bizType,
                                                     filterType: filterType,
                                                     extraData: extraData)
            return cellVM
        }
    }

    // MARK: - 注册Header
    func registerHeaders() {
        FeedHeaderFactory.register(type: .topBar, viewModelBuilder: { (resolver) -> FeedHeaderItemViewModelProtocol? in
            let pushCenter = try resolver.userPushCenter // swiftlint:disable:this all
            let pushDynamicNetStatus = pushCenter.observable(for: PushDynamicNetStatus.self)
            let dependency = TopBarViewModelDependencyImpl(pushDynamicNetStatus: pushDynamicNetStatus)
            return TopBarViewModel(resolver: resolver, dependency: dependency)
        }) { viewModel -> UIView? in
            guard let topBarViewModel = viewModel as? TopBarViewModel else { return nil }
            return TopBarView(viewModel: topBarViewModel)
        }

        FeedHeaderFactory.register(type: .banner, viewModelBuilder: { (resolver) -> FeedHeaderItemViewModelProtocol? in
            let bannerService = try resolver.resolve(assert: FeedBannerService.self)
            return BannerViewModel(bannerService: bannerService)
        }) { viewModel -> UIView? in
            guard let bannerViewModel = viewModel as? BannerViewModel else { return nil }
            return bannerViewModel.bannerView
        }

        FeedHeaderFactory.register(type: .shortcut, viewModelBuilder: { (resolver) -> FeedHeaderItemViewModelProtocol? in
            let shortcutEnabled = Feed.Feature.shortcutEnabled(resolver)
            guard shortcutEnabled else { return nil }
            let shortcutsViewModel = try resolver.resolve(assert: ShortcutsViewModel.self)
            return shortcutsViewModel
        }) { viewModel -> UIView? in
            guard let shortcutsViewModel = viewModel as? ShortcutsViewModel else { return nil }
            guard let view = try? shortcutsViewModel.userResolver.resolve(assert: ShortcutsCollectionView.self) else { return nil }
            return view
        }
    }

    // MARK: - For iPad
    func assemblePad(_ container: Container) {
        guard Display.pad else { return }
        Navigator.shared.registerObserver.factory(FeedSelectionObserver.init(resolver:))
    }

    func otherBizRegister(_ container: Container) {
        SwiftLoadable.startOnlyOnce(key: "Feed")
    }

    enum Cons {
        static let contentPercent: CGFloat = 0.8
    }
}
