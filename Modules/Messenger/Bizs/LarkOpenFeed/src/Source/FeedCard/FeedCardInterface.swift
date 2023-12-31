//
//  FeedCardInterface.swift
//  LarkOpenFeed
//
//  Created by liuxianyu on 2022/5/23.
//

import UIKit
import Foundation
import LarkSceneManager
import LarkModel
import LarkSwipeCellKit
import RustPB
import RxSwift

/// 当前Cell处在哪种类型的页面，不同页面可能有定制化的需求，也交由Cell实现
public enum FeedBizType {
    case inbox              // 收件箱
    case done               // 已完成
    case box                // 会话盒子
    case flag               // 标记
    case label              // 标签分组
}

// MARK: cell左右滑动协议
public protocol FeedSwipingCellInterface: SwipeTableViewCell {
    // 是否出现了左右滑入口
    var isSwiping: Bool { get }
}

public extension FeedSwipingCellInterface {
    // 是否出现了左右滑入口
    var isSwiping: Bool {
        swipeView.frame.origin.x != 0
    }
}

// MARK: cell 协议
public protocol FeedCardCellInterface: FeedSwipingCellInterface {
    // 填充Cell内容
    func set(cellViewModel: FeedCardViewModelInterface)

    // 点击feed操作
    func didSelectCell(from: UIViewController)

    // cell 将要展示时，可以在这里触发业务方预加载逻辑
    func willDisplay()

    // cell 结束展示时
    func didEndDisplay()

    // 用于返回 cell 拖拽手势
    func supportDragScene() -> Scene?
}

// MARK: cell vm 协议
public protocol FeedCardViewModelInterface: AnyObject {
    // feed 模型
    var feedPreview: FeedPreview { get set }
    // feed 关联的业务数据
    var basicData: IFeedPreviewBasicData { get }
    // feed 关联的业务数据
    var bizData: FeedPreviewBizData { get }
    // feed cell 高度
    var cellRowHeight: CGFloat { get }
    // feed card 选中状态 for iPad
    var selected: Bool { get set }
    // component vm 集合
    var componentVMMap: [FeedCardComponentType: FeedCardBaseComponentVM] { get }
    // TODO: open feed 待feedaction上线后移除该接口
    func checkClearBadgeSetting(feedPreviewPBType: Basic_V1_FeedCard.EntityType) -> Bool
}

// TODO: open feed 新action框架全量后可删除
public protocol BaseFeedTableCellMute {
    func isSupportMute() -> Bool
    func setMute() -> Single<Void>
}
