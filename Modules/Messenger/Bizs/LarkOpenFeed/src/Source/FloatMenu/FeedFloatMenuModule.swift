//
//  FeedFloatMenuModule.swift
//  LarkOpenFeed
//
//  Created by liuxianyu on 2022/11/29.
//

import UIKit
import Foundation
import Swinject
import LarkOpenIM

// 所有业务如果需要接入floatMenu，需要声明业务对应枚举，枚举值大小会影响展示优先级(优先级递增)
public enum FloatMenuOptionType: Int {
    case unknown
    case scanQRCode          // 扫一扫
    case newGroup            // 创建群组
    case inviteMember        // 添加团队成员
    case inviteExternal      // 添加外部联系人
    case createDocs          // 创建文档
    case shareScreen         // 会议室投屏
    case newMeeting          // 新会议
    case joinMeeting         // 加入会议
}

public struct FloatMenuOptionItem {
    public let icon: UIImage
    public let title: String
    public let type: FloatMenuOptionType
    public init(icon: UIImage, title: String, type: FloatMenuOptionType) {
        self.icon = icon
        self.title = title
        self.type = type
    }
}

/// Feed中FloatMenu区域抽象Module，VC持有该Module完成FloatMenu创建/显示/更新。
public class BaseFeedFloatMenuModule: Module<FeedFloatMenuContext, FeedFloatMenuMetaModel> {
    override open class var loadableKey: String {
        return "BaseFeedFloatMenuModule"
    }

    // 注册的SubModule集合
    var subModuleTypes: [BaseFeedFloatMenuSubModule.Type] {
        return []
    }

    // SubModule排序数组，决定展示的先后顺序
    let sortTypes: [FloatMenuOptionType] = [.scanQRCode,
                                            .newGroup,
                                            .inviteMember,
                                            .inviteExternal,
                                            .createDocs,
                                            .shareScreen,
                                            .newMeeting,
                                            .joinMeeting]

    /// 按顺序排列的所有实例化的直接SubModule
    private var subModules: [BaseFeedFloatMenuSubModule] = []
    /// 所有能处理当前context的SubModule
    private var canHandleSubModules: [BaseFeedFloatMenuSubModule] = []

    /// 实例化subModules
    public override func onInitialize() {
        let canInitSubModules = self.subModuleTypes
            .filter({ $0.canInitialize(context: self.context) })
            .map({ $0.init(context: self.context) })
        self.subModules = self.reorder(array: canInitSubModules, by: sortTypes)
        self.subModules.forEach({ $0.registServices(container: self.context.container) })
    }

    /// subModules -> canHandleSubModules
    @discardableResult
    public override func handler(model: FeedFloatMenuMetaModel) -> [Module<FeedFloatMenuContext, FeedFloatMenuMetaModel>] {
        self.canHandleSubModules = []
        self.subModules.forEach { (module) in
            // 如果能处理
            if module.canHandle(model: model) {
                // 遍历hander结果
                (module.handler(model: model) as? [BaseFeedFloatMenuSubModule] ?? []).forEach { (_) in
                    self.canHandleSubModules.append(module)
                }
            }
        }
        return [self]
    }

    public override func modelDidChange(model: FeedFloatMenuMetaModel) {
        self.canHandleSubModules.forEach({ $0.modelDidChange(model: model) })
    }

    public func didClick(_ type: FloatMenuOptionType) {
        guard let module = self.canHandleSubModules.first(where: { $0.type == type }) else { return }
        module.didClick()
    }

    /// 构建选项数据
    public func collectItems(model: FeedFloatMenuMetaModel) -> [FloatMenuOptionItem] {
        let items: [FloatMenuOptionItem] = self.canHandleSubModules.compactMap { module -> FloatMenuOptionItem? in
            guard let item = module.menuOptionItem(model: model) else { return nil }
            return item
        }
        return items
    }

    private func reorder(array: [BaseFeedFloatMenuSubModule],
                         by preferredOrder: [FloatMenuOptionType]) -> [BaseFeedFloatMenuSubModule] {
        return array
            .filter({ preferredOrder.contains($0.type) })
            .sorted { (a, b) -> Bool in
                guard let first = preferredOrder.firstIndex(of: a.type) else {
                    return false
                }
                guard let second = preferredOrder.firstIndex(of: b.type) else {
                    return true
                }
                return first < second
            }
    }
}

public final class FeedFloatMenuModule: BaseFeedFloatMenuModule {
    private static var normalSubModuleTypes: [FeedFloatMenuSubModule.Type] = []

    override var subModuleTypes: [BaseFeedFloatMenuSubModule.Type] {
        return Self.normalSubModuleTypes
    }

    public static func register(_ type: FeedFloatMenuSubModule.Type) {
        #if DEBUG
        if normalSubModuleTypes.contains(where: { $0 == type }) {
            assertionFailure("FeedFloatMenuSubModule \(type) has already been registered")
        }
        #endif
        normalSubModuleTypes.append(type)
    }

    public override static func onLoad(context: FeedFloatMenuContext) {
        launchLoad()
        // 对subModules依次调用onLoad
        normalSubModuleTypes.forEach({ $0.onLoad(context: context) })
    }

    /// 对subModules依次调用registGlobalServices
    public override class func registGlobalServices(container: Container) {
        normalSubModuleTypes.forEach({ $0.registGlobalServices(container: container) })
    }
}
