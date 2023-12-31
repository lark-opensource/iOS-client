//
//  FeedHeaderView.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/7/3.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import LKCommonsLogging
import LarkModel
import LarkContainer
import LarkOpenFeed

protocol FeedHeaderViewInterface: UIView {
    // 高度变化
    var updateHeightDriver: Driver<(CGFloat, HeaderUpdateHeightStyle)> { get }
    func layout()
    func updateShortcut(feeds: [FeedPreview])
    var heightAboveShortcut: CGFloat { get }
    var preAllowVibrate: Bool { get }
    // 开始拖拽
    func scrollViewWillBeginDragging()
    // 滚动中
    func scrollViewDidScroll(offsetY: CGFloat)
    // 结束拖拽
    func scrollViewDidEndDragging(offsetY: CGFloat)
}

final class FeedHeaderView: UIView, FeedHeaderViewInterface {
    let disposeBag = DisposeBag()

    var viewModels = [FeedHeaderItemViewModelProtocol]()
    var visibleViewModels = [FeedHeaderItemViewModelProtocol]()
    var sortedSubViews = [UIView]()
    var headerViewsMap = [FeedHeaderItemType: UIView]() // 改成弱引用
    // var headerViewsMap: [FeedHeaderItemType: UIView] = NSMapTable<FeedHeaderItemType, UIView>()

    // 特化的shortcut（置顶区域）
    weak var shortcutsViewModel: ShortcutsViewModel?
    weak var shortcutsView: ShortcutsCollectionView?

    // 适配ipad
    var oldWidth: CGFloat = 0

    // 高度变化
    var updateHeightRelay = BehaviorRelay<(CGFloat, HeaderUpdateHeightStyle)>(value: (0, .normal))
    var updateHeightDriver: Driver<(CGFloat, HeaderUpdateHeightStyle)> {
        return updateHeightRelay.asDriver()
    }

    init(frame: CGRect, context: UserResolver) {
        super.init(frame: frame)
        bindViewModels(context: context)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
