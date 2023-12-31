//
//  ChatTabModule.swift
//  LarkOpenChat
//
//  Created by 赵家琛 on 2021/6/16.
//

import UIKit
import Foundation
import Swinject
import RustPB
import LarkModel
import LKLoadable
import LarkBadge
import LarkOpenIM

public final class ChatTabModule: Module<ChatTabContext, ChatTabMetaModel> {
    override public class var loadableKey: String {
        return "OpenChat"
    }

    /// 群 tab 触发自定义引导的类型
    public static let guideWhiteList: Set<ChatTabType> = [.url, .doc]

    /// 各业务方注册的SubModule
    private static var subModuleTypes: [ChatTabSubModule.Type] = []
    public static func register(_ type: ChatTabSubModule.Type) {
        #if DEBUG
        if ChatTabModule.subModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("ChatTabSubModule \(type) has already been registered")
        }
        #endif
        ChatTabModule.subModuleTypes.append(type)
    }

    public override static func onLoad(context: ChatTabContext) {
        launchLoad()
        // 对subModules依次调用onLoad
        ChatTabModule.subModuleTypes.forEach({ $0.onLoad(context: context) })
    }

    /// 所有实例化的SubModule
    private var subModules: [ChatTabSubModule] = []
    /// 实例化subModules
    public override func onInitialize() {
        self.subModules = ChatTabModule.subModuleTypes
            .filter({ $0.canInitialize(context: self.context) })
            .map({ $0.init(context: self.context) })
        self.subModules.forEach({ $0.registServices(container: self.context.container) })
    }

    /// 对subModules依次调用registGlobalServices
    public override class func registGlobalServices(container: Container) {
        ChatTabModule.subModuleTypes.forEach({ $0.registGlobalServices(container: container) })
    }

    public func setup(_ contextModel: ChatTabContextModel) {
        self.subModules.forEach { $0.setup(contextModel) }
    }

    public func checkVisible(metaModel: ChatTabMetaModel) -> Bool {
        if let module = self.subModules.first(where: { $0.type == metaModel.type }) {
            return module.checkVisible(metaModel: metaModel)
        }
        return false
    }

    public func preload(metaModel: ChatTabMetaModel) {
        if let module = self.subModules.first(where: { $0.type == metaModel.type }) {
            module.preload(metaModel: metaModel)
        }
    }

    public func jumpTab(model: ChatJumpTabModel) {
        if let module = self.subModules.first(where: { $0.type == model.content.type }) {
            module.jumpTab(model: model)
        }
    }

    public func getContent(metaModel: ChatTabMetaModel, chat: Chat) -> ChatTabContentViewDelegate? {
        if let module = self.subModules.first(where: { $0.type == metaModel.type }) {
            if let contentVC = module.getContent(metaModel: metaModel, chat: chat) {
                return contentVC
            } else {
                return UIViewController()
            }
        }
        return UIViewController()
    }

    /// 添加入口排序
    private let addEntrySortList: [ChatTabType] = [.meetingMinute, .chatAnnouncement]
    private lazy var addEntrySortDic: [ChatTabType: Int] = {
        var sortDic: [ChatTabType: Int] = [:]
        for (index, type) in addEntrySortList.enumerated() {
            sortDic[type] = index
        }
        return sortDic
    }()

    public func getChatAddTabEntry(_ addTabContext: ChatTabContextModel) -> [ChatAddTabEntry] {
        var addEntrys: [ChatAddTabEntry] = []
        for module in self.subModules {
            if let entry = module.getChatAddTabEntry(addTabContext) {
                addEntrys.append(entry)
            }
        }
        return addEntrys.sorted { entry1, entry2 in
            let weight1 = self.addEntrySortDic[entry1.type] ?? 0
            let weight2 = self.addEntrySortDic[entry2.type] ?? 0
            return weight1 < weight2
        }
    }

    public func beginAddTab(metaModel: ChatAddTabMetaModel) {
        if let module = self.subModules.first(where: { $0.type == metaModel.type }) {
            module.beginAddTab(metaModel: metaModel)
            return
        }
        assertionFailure("add unsupport tab type")
    }

    public func checkShouldDisplayContentTopMargin(type: ChatTabType) -> Bool {
        if let subModule = self.subModules.first(where: { $0.type == type }) {
            return subModule.shouldDisplayContentTopMargin
        }
        return true
    }

    public func checkCanSupportLRUCache(type: ChatTabType) -> Bool {
        if let subModule = self.subModules.first(where: { $0.type == type }) {
            return subModule.supportLRUCache
        }
        return true
    }

    public func getTabTitle(_ metaModel: ChatTabMetaModel) -> String {
        if let subModule = self.subModules.first(where: { $0.type == metaModel.type }) {
            return subModule.getTabTitle(metaModel)
        }
        return ""
    }

    public func getImageResource(_ metaModel: ChatTabMetaModel) -> ChatTabImageResource {
        if let subModule = self.subModules.first(where: { $0.type == metaModel.type }) {
            return subModule.getImageResource(metaModel)
        }
        return .image(UIImage())
    }

    public func getBadgePath(_ metaModel: ChatTabMetaModel) -> Path? {
        if let subModule = self.subModules.first(where: { $0.type == metaModel.type }) {
            return subModule.getBadgePath(metaModel)
        }
        return nil
    }

    public func getTabManageItem(_ metaModel: ChatTabMetaModel) -> ChatTabManageItem? {
        if let subModule = self.subModules.first(where: { $0.type == metaModel.type }) {
            return subModule.getTabManageItem(metaModel)
        }
        return nil
    }

    public func getClickParams(_ metaModel: ChatTabMetaModel) -> [AnyHashable: Any]? {
        if let subModule = self.subModules.first(where: { $0.type == metaModel.type }) {
            return subModule.getClickParams(metaModel)
        }
        return nil
    }

    public func getFirstScreenParams(_ metaModels: [ChatTabMetaModel]) -> [AnyHashable: Any] {
        var params: [AnyHashable: Any] = [:]
        self.subModules.forEach { subModule in
            let subModuleParams = subModule.getFirstScreenParams(metaModels.filter { subModule.type == $0.type })
            subModuleParams.forEach { params[$0.key] = $0.value }
        }
        return params
    }
}
