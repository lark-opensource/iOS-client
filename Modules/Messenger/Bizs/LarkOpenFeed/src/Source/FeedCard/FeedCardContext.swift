//
//  FeedCardContext.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2023/1/8.
//

import Foundation
import LarkContainer
import LarkModel
import RustPB

//  FeedCard 用于获取一些context
public class FeedCardContext {
    // 用户态容器
    public let userResolver: UserResolver
    // feed业务域内流通的全局上下文
    public let feedContextService: FeedContextService
    // feedCardButton 相关服务
    public let ctaConfigService: FeedCTAConfigService

    // feed card cell 面向 tableview 的注册器
    public typealias FeedCardReigsteCellHandler = (UITableView, UserResolver) -> Void
    public static var registerCell: FeedCardReigsteCellHandler?

    // feed card vm 构造器
    public typealias FeedCardViewModelBuilder = (_ feedPreview: FeedPreview,
                                                 _ userResolver: UserResolver,
                                                 _ feedCardModuleManager: FeedCardModuleManager,
                                                 _ bizType: FeedBizType,
                                                 _ filterType: Feed_V1_FeedFilter.TypeEnum,
                                                 _ extraData: [AnyHashable: Any]) -> FeedCardViewModelInterface?
    public static var cellViewModelBuilder: FeedCardViewModelBuilder?

    public init(resolver: UserResolver,
                feedContextService: FeedContextService,
                ctaConfigService: FeedCTAConfigService) {
        self.userResolver = resolver
        self.feedContextService = feedContextService
        self.ctaConfigService = ctaConfigService
    }

    // 获取 feed card cell，该函数内部同时给该 cell 传入 cell view model，进行渲染
    public static func dequeueReusableCell(feedCardModuleManager: FeedCardModuleManager,
                                           viewModel: FeedCardViewModelInterface,
                                           tableView: UITableView,
                                           indexPath: IndexPath) -> FeedCardCellInterface? {
        guard let reuseId = Self.getFeedCardCellReuseId(feedCardModuleManager: feedCardModuleManager, viewModel: viewModel),
              let cell = tableView.dequeueReusableCell(withIdentifier: reuseId, for: indexPath) as? FeedCardCellInterface else {
            return nil
        }
        cell.set(cellViewModel: viewModel)
        return cell
    }

    // 获取 feed card cell 重用标识符
    public static func getFeedCardCellReuseId(feedCardModuleManager: FeedCardModuleManager,
                                              viewModel: FeedCardViewModelInterface) -> String? {
        guard let module = feedCardModuleManager.modules[viewModel.feedPreview.basicMeta.feedCardType] else {
            return nil
        }
        return String(module.type.rawValue)
    }

    // 构造 feed 组件：第一种方法
    public static func buildComponentVO(componentType: FeedCardComponentType,
                                        feedPreview: FeedPreview,
                                        feedCardModuleManager: FeedCardModuleManager) -> FeedCardBaseComponentVM? {
        guard let feedCardModule = feedCardModuleManager.modules[feedPreview.basicMeta.feedCardType],
            let factory = feedCardModuleManager.componentFactories[componentType] else { return nil }
        let componentVM = Self.buildComponentVO(componentType: componentType,
                                                feedPreview: feedPreview,
                                                factory: factory,
                                                feedCardModule: feedCardModule)
        return componentVM
    }

    // 构造 feed 组件：第二种方法
    public static func buildComponentVO(componentType: FeedCardComponentType,
                                        feedPreview: FeedPreview,
                                        factory: FeedCardBaseComponentFactory,
                                        feedCardModule: FeedCardBaseModule) -> FeedCardBaseComponentVM {
        let componentVM: FeedCardBaseComponentVM
        if let _componentVM = feedCardModule.customComponentVM(componentType: componentType, feedPreview: feedPreview) {
            // 业务方异化组件数据
            componentVM = _componentVM
        } else {
            // 默认组件数据
            componentVM = factory.creatVM(feedPreview: feedPreview)
        }
        return componentVM
    }
}
