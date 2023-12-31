//
//  EventInterface.swift
//  LarkOpenFeed
//
//  Created by xiaruzhen on 2022/9/26.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkTag
import Swinject
import SnapKit
import LarkContainer

public protocol EventItem {
    var biz: EventBiz { get } // 与 provider 关系绑定
    var id: String { get } // 是否会跟其他业务冲突
    var position: Int { get } // 排序使用。如果多个事件positon冲突了，则根据id大小来排
    func tap()
    var description: String { get }
}

public extension EventItem {
    public var description: String {
        return "biz: \(biz), itemId: \(id), position: \(position)"
    }
}

public protocol EventFeedHeaderViewItem: EventItem {
    // feed header 使用
    var icon: UIImage { get }
    var status: String { get }
    var title: String { get }
    var tags: [LarkTag.TagType] { get }
    var tagItems: [LarkTag.Tag] { get }
}

public extension EventFeedHeaderViewItem {
    var tagItems: [LarkTag.Tag] { [] }
}

public enum EventListCellCalHeightMode {
    case automaticDimension // 自动计算高度，由垂直约束和内容决定高低
    case manualDimension(CGFloat) // 手动指定高度
}

public protocol EventListCellItem: EventItem {
    var reuseId: String { get } // cell 重用标识符。eventList使用
    var calHeightMode: EventListCellCalHeightMode { get } // 默认自动计算高度
}

public extension EventListCellItem {
    public var calHeightMode: EventListCellCalHeightMode {
        return .automaticDimension
    }
}

public protocol EventItemCell: UITableViewCell {
    var item: EventItem? { get set } // 绑定的事件模型
}

public enum EventBiz: String {
    case vc // 会议
    case live // 直播
}

public protocol EventProvider {
    var biz: EventBiz { get }
    var cellTypes: [String: UITableViewCell.Type] { get } // 所需要的 cell类型 的字典
    func fillter(items: [EventItem]) // 过滤具体的items
    func fillterAllitems()
}

public enum EventDataCommand {
    case insertOrUpdate([String: EventItem])
    case remove([String])
}

//public class EventContext {
//    public let container: Swinject.Container
//}

public final class EventFactory {
    public typealias ProviderBuilder = (_ context: UserResolver, PublishRelay<EventDataCommand>) -> EventProvider?

    private static var builders: [ProviderBuilder] = []

    // 需要由业务方注入自身的provider
    public static func register(providerBuilder: @escaping ProviderBuilder) {
        EventFactory.builders.append(providerBuilder)
    }

    // 构造并获取 provider
    public static func allProviders(context: UserResolver, dataCommand: PublishRelay<EventDataCommand>) -> [EventProvider] {
        EventFactory.builders.compactMap { $0(context, dataCommand) }
    }
}
