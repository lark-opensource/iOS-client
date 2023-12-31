//
//  BaseMomentCellViewModel.swift
//  Moment
//
//  Created by zc09v on 2021/1/6.
//

import UIKit
import Foundation
import AsyncComponent
import RxSwift
import LarkMessageBase
import Swinject
import EEAtomic
import LarkMessageCore
import EENavigator

public enum MomentContextScene: Equatable {
    // 社区feed流页面
    case feed(RawData.PostTab)
    // 动态详情页
    case postDetail
    /// profile
    case profile
    /// 板块详情页(tabsView.selectedIndex,categoryId)
    case categoryDetail(Int, String)
    /// hashTag详情页(tabsView.selectedIndex,hashTagId)
    case hashTagDetail(Int, String)

    case unknown

    public var isFeed: Bool {
        switch self {
        case .feed:
            return true
        default:
            return false
        }
    }

    public var isCategoryDetail: Bool {
        switch self {
        case .categoryDetail:
            return true
        default:
            return false
        }
    }

    public var isHashTagDetail: Bool {
        switch self {
        case .hashTagDetail:
            return true
        default:
            return false
        }
    }
}

/// 通用的页面能力
protocol PageAPI: UIViewController {
    /// 宿主页面宽度
    var hostSize: CGSize { get }
    /// 回复某一条评论
    func reply(by commentData: RawData.CommentEntity, fromMenu: Bool)
    /// 回复动态
    func reply(by postData: RawData.PostEntity)

    /// 刷新一下tableView的数据
    func refreshTableView()

    var scene: MomentContextScene { get }

    var childVCMustBeModalView: Bool { get }

    var reactionMenuBarInset: UIEdgeInsets? { get }

    var reactionMenuBarFromVC: UIViewController { get }
}

extension PageAPI {
    func reply(by commentData: RawData.CommentEntity, fromMenu: Bool) {}
    func reply(by postData: RawData.PostEntity) {}
    var childVCMustBeModalView: Bool { false }
    var reactionMenuBarInset: UIEdgeInsets? { nil }
    var reactionMenuBarFromVC: UIViewController { self }
    func refreshTableView() {}
}

/// 通用的页面能力
protocol DataSourceAPI: AnyObject {
    /// 更新某一行cell
    func reloadRow(by indentifyId: String, animation: UITableView.RowAnimation)
    /// 锁数据队列
    ///
    /// - Parameter pause: 是否锁住
    func pauseDataQueue(_ pause: Bool)

    /// 更新所有数据
    func reloadData()

    /// 是否展示板块来源
    func showPostFromCategory() -> Bool

    /// 上次阅读位置
    func lastReadPostId() -> String?

    //向页面请求一些参数，不同的页面可能需要请求不同的参数
    func getTrackValueForKey(_ key: MomentsTrackParamKey) -> Any?

    /// 用于更新点踩的内容信息
    func updatePostCellDislike(isSelfDislike: Bool?, postId: String)
}

//向页面请求的参数种类，配合DataSourceAPI的getTrackValueForKey方法使用
enum MomentsTrackParamKey {
    //String
    case profileUserId
    //Bool
    case isFollow
    //MomentsTracer.PageIdInfo
    case pageIdInfo
}

/// 路由类型
public enum NavigatorType {
    case open
    case push
    case present
    case showDetail
}

public protocol BaseMomentContextInterface: AsyncComponent.Context {
    func reloadData()
    func reloadRow(by indentifyId: String, animation: UITableView.RowAnimation)
    func getColor(for key: ColorKey, type: Type) -> UIColor
}

public final class BaseMomentContext: BaseMomentContextInterface {
    weak var pageAPI: PageAPI?
    weak var dataSourceAPI: DataSourceAPI?
    public let pageContainer: PageContainer
    let inlinePreviewVM: MomentInlineViewModel
    let disposeBag: DisposeBag = DisposeBag()

    public init() {
        let container = PageServiceContainer()
        self.pageContainer = container
        self.colorService = ChatColorConfig()
        self.inlinePreviewVM = MomentInlineViewModel()
    }

    public func reloadData() {
        self.dataSourceAPI?.reloadData()
    }

    public func reloadRow(by indentifyId: String, animation: UITableView.RowAnimation) {
        self.dataSourceAPI?.reloadRow(by: indentifyId, animation: animation)
    }

    public var maxCellWidth: CGFloat {
        return self.pageAPI?.hostSize.width ?? 0
    }

    public func getColor(for key: ColorKey, type: Type) -> UIColor {
        return colorService.getColor(for: key, type: type)
    }

    private var colorService: ColorConfigService
}

class BaseMomentCellViewModel<C: BaseMomentContextInterface>: ViewModel {
    /// 对应cell的reused identifier
    open var identifier: String {
        assertionFailure("must override")
        return "cell"
    }

    /// 渲染引擎
    public let renderer: ASComponentRenderer

    /// 负责绑定VM和Component，避免Component对VM造成污染
    public let binder: ComponentBinder<C>

    /// 上下文，容器或者顶层VC提供的能力
    public let context: C

    /// 负责统一回收RX相关的订阅
    public let disposeBag = DisposeBag()

    /// CellViewModel构造方法
    ///
    /// - Parameters:
    ///   - context: 上下文
    ///   - binder: VM和Component的binder，通过传入不同的binder，可以将VM绑定到不同的VM
    public init(context: C, binder: ComponentBinder<C>) {
        self.context = context
        self.binder = binder
        self.renderer = ASComponentRenderer(binder.component)
        super.init()
    }

    /// 重新计算布局
    public func calculateRenderer() {
        binder.update(with: self)
        renderer.update(rootComponent: binder.component)
    }

    /// size 发生变化，更新 binder, 并且触发 renderer
    override open func onResize() {
        binder.update(with: self)
        super.onResize()
        renderer.update(rootComponent: binder.component)
    }

    /// 获取ReusableCell（通过vm的布局信息和identifier来计算）
    ///
    /// - Parameters:
    ///   - tableView: 目标tableView
    ///   - cellId: cell的唯一标识符（例如消息id）
    /// - Returns: 可重用的MessageCommonCell
    open func dequeueReusableCell(_ tableView: UITableView, cellId: String) -> MomentCommonCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? MomentCommonCell ??
            MomentCommonCell(style: .default, reuseIdentifier: identifier)
        cell.contentView.tag = 0
        cell.update(with: renderer, cellId: cellId)
        return cell
    }
}
