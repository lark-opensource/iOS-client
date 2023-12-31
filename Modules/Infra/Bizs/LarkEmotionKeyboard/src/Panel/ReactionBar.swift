//
//  ReactionBar.swift
//  LarkEmotionKeyboard
//
//  Created by phoenix on 2023/3/31.
//

import Foundation
import UIKit
import LarkEmotion
import LKCommonsLogging

// ReactionBarConfig
public struct ReactionBarConfig {
    public static let defaultBarHeight: CGFloat = 28
    public static let defaultSize: CGSize = CGSize(width: 28, height: 28)
    public static let defaultEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    
    // 表情的大小
    let reactionSize: CGSize
    // ReactionBar高度
    let reactionBarHeight: CGFloat
    // 更多按钮大小
    let moreIconSize: CGSize
    // 数据源
    let items: [MenuReactionItem]
    // 点击更多按钮回调
    let clickMoreBlock: (() -> Void)?
    // 是否支持展开更多表情
    let supportMoreReactions: Bool
    // 是否支持新版菜单
    let supportSheetMenu: Bool
    // 面板的边距
    let edgeInset: UIEdgeInsets

    // 初始化
    public init(reactionSize: CGSize = defaultSize,
                reactionBarHeight: CGFloat = defaultBarHeight,
                moreIconSize: CGSize = defaultSize,
                items: [MenuReactionItem],
                clickMoreBlock: (() -> Void)? = nil,
                supportMoreReactions: Bool = false,
                supportSheetMenu: Bool = false,
                edgeInset: UIEdgeInsets = defaultEdgeInsets) {
        self.reactionSize = reactionSize
        self.reactionBarHeight = reactionBarHeight
        self.moreIconSize = moreIconSize
        self.items = items
        self.clickMoreBlock = clickMoreBlock
        self.supportMoreReactions = supportMoreReactions
        self.supportSheetMenu = supportSheetMenu
        self.edgeInset = edgeInset
    }
}

public protocol ReactionBarDelegate: AnyObject {
    /// 点击了more按钮
    func reactionsBarDidClickMoreButton(_ bar: ReactionBar)
}

public final class ReactionBar: UIView {
    private static let logger = Logger.log(ReactionBar.self, category: "Module.LarkEmotionKeyboard.ReactionBar")

    // 数据源
    public var items: [MenuReactionItem] {
        didSet {
            self.updateReactionsView()
        }
    }
    // 点击更多按钮回调
    public var clickMoreBlock: (() -> Void)?
    
    public weak var delegate: ReactionBarDelegate?
    
    // 是否显示更多表情动画
    public var showMore: Bool = false {
        didSet {
            if self.showMore {
                self.closeIconImageView?.transform = CGAffineTransform(rotationAngle: .pi / 4)
            } else {
                self.closeIconImageView?.transform = CGAffineTransform.identity
            }
        }
    }

    // 表情大小
    public let reactionSize: CGSize
    // 更多按钮大小
    public let moreIconSize: CGSize
    // ReactionBar高度
    public let reactionBarHeight: CGFloat
    // ReactionBar边距
    public let edgeInset: UIEdgeInsets
    // 布局
    public let layout: RecentReactionsFlowLayout = RecentReactionsFlowLayout()
    // 列表控件
    public fileprivate(set) lazy var collection: UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)

    // 是否显示更多按钮
    private var supportMoreReactions: Bool {
        didSet {
            if supportMoreReactions == oldValue {
                return
            }
            self.updateReactionsView()
        }
    }
    
    // 是否支持新版菜单
    private var supportSheetMenu: Bool {
        didSet {
            if supportSheetMenu == oldValue {
                return
            }
            self.updateReactionsView()
        }
    }
    
    private var viewWidth: CGFloat = 0
    private let maxItemCount: Int = 7
    private var closeIconImageView: UIImageView?
    private var separatorLine: UIImageView = UIImageView()

    // 初始化
    public init(config: ReactionBarConfig) {
        self.items = config.items
        self.clickMoreBlock = config.clickMoreBlock
        self.reactionSize = config.reactionSize
        self.moreIconSize = config.moreIconSize
        self.reactionBarHeight = config.reactionBarHeight
        self.supportMoreReactions = config.supportMoreReactions
        self.supportSheetMenu = config.supportSheetMenu
        self.edgeInset = config.edgeInset

        super.init(frame: .zero)

        collection.backgroundColor = UIColor.clear
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.isPagingEnabled = false
        collection.dataSource = self
        collection.delegate = self

        let cellIdentifier = String(describing: ReactionCollectionCell.self)
        collection.register(ReactionCollectionCell.self, forCellWithReuseIdentifier: cellIdentifier)

        self.addSubview(collection)
        // collection的高度和reactionSize的高度一致，并且在ReactionBar居中，宽度撑满ReactionBar
        let collectionHeight = self.reactionSize.height
        collection.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(collectionHeight)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if self.viewWidth != self.bounds.width {
            self.viewWidth = self.bounds.width
            self.updateReactionsView()
        }
    }

    private func updateReactionsView() {
        self.layout.invalidateLayout()
        self.collection.reloadData()
    }

    private var showItemCount: Int {
        guard self.collection.bounds.width > 0 else {
            return self.maxItemCount
        }
        // 日志上报
        var extraInfo: [(key: String, index: Int, disW: CGFloat, disH: CGFloat, entW: CGFloat, entH: CGFloat, imgW: CGFloat, imgH: CGFloat)] = []
        // 计算出最多显示Reaction的个数，需要考虑隐藏更多按钮的情况
        let maxNumber: Int = (self.supportMoreReactions ? self.maxItemCount : self.maxItemCount + 1)
        // 计算出最长的显示宽度，需要考虑隐藏更多按钮的情况
        var panelWidth = self.collection.bounds.width - self.edgeInset.right - self.edgeInset.left
        if self.supportMoreReactions {
            // 如果有更多按钮的话需要去掉更多按钮的宽度
            panelWidth -= self.moreIconSize.width
        }
        // 根据是否需要显示更多按钮决定最后一个显示的item是否要右对齐
        self.layout.lastItemAlignedRight = self.supportMoreReactions
        // 计算实际需要显示的reaction个数
        let minSpace: CGFloat = self.minimumInteritemSpacing
        var width: CGFloat = 0
        var count: Int = 0
        for item in self.items {
            // 高度固定等于默认高度
            let displayHeight = self.reactionSize.height
            // 宽度先等于默认宽度，之后按照服务端时间给的大小等比缩放
            var displayWidth = self.reactionSize.width
            // 取出服务端返回的实际size
            let entitySize = item.reactionEntity.size
            var size = entitySize
            var imageSize = CGSize(width: 0, height: 0)
            // 如果图片大小和服务端给的不一致，以实际图片大小为准
            if let image = EmotionResouce.shared.imageBy(key: item.reactionEntity.key) {
                imageSize = image.size
                // 这样比较是为了忽略1像素的误差
                if abs(imageSize.width - entitySize.width) > 1 || abs(imageSize.height - entitySize.height) > 1 {
                    size = image.size
                }
            }
            // 产品对默认表情有个规则：在96高的情况下，宽度在96~134之间（4倍图）转化下就是在24高度下，宽度限制在24~33.5之间
            // 根据上面的规则在32的高度限制下，宽度应该限制在32~44.6之间
            if size.height != 0 {
                // 如果宽度大于45（对44.6向下取整），说明是企业自定义表情，容器宽度有自己的计算规则
                if size.width > 45 {
                    // 宽度等比缩放
                    displayWidth = displayHeight * size.width / size.height
                } else {
                    // 默认表情（32高度下，宽度限制在32~44.6之间）容器的大小是等宽等高的
                    displayWidth = displayHeight
                }
            }
            let key = item.reactionEntity.key
            if width + displayWidth > (panelWidth + 3) {
                let tuples = (key: key, index: count + 1, disW: displayWidth, disH: displayHeight, entW:entitySize.width, entH:entitySize.height, imgW: imageSize.width, imgH:imageSize.height)
                extraInfo.append(tuples)
                break
            }
            count += 1
            width += (displayWidth + minSpace)
            let tuples = (key: key, index: count, disW: displayWidth, disH: displayHeight, entW:entitySize.width, entH:entitySize.height, imgW: imageSize.width, imgH:imageSize.height)
            extraInfo.append(tuples)
        }
        let reactionsCount = min(maxNumber, count)
        // 日志上报
        var params: [String: String] = [:]
        params["panelWidth"] = "\(panelWidth)"
        params["minSpace"] = "\(minSpace)"
        params["reactionsCount"] = "\(reactionsCount)"
        params["items"] = "\(extraInfo)"
        Self.logger.info("ReactionBar: reactions info", additionalData: params)

        // 经过计算后发现实际显示的Reaction要比数据源里面的少
        if reactionsCount < self.items.count {
            let start = reactionsCount
            let end = self.items.count
            // 数据源里面去掉不要显示的
            self.items.removeSubrange(start..<end)
        }
        return reactionsCount + (self.supportMoreReactions ? 1 : 0)
    }

    private var minimumInteritemSpacing: CGFloat {
        let size = self.reactionSize
        let number = self.maxItemCount
        let insets = self.edgeInset

        let space = CGFloat(
            (self.collection.bounds.width -
                size.width * CGFloat(number) -
                insets.left -
                insets.right) /
                CGFloat(number - 1)
            )
        return space
    }

}

extension ReactionBar: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row < self.items.count {
            let item = self.items[indexPath.row]
            item.action(item.type)
        } else {
            self.clickMoreBlock?()
            self.delegate?.reactionsBarDidClickMoreButton(self)
        }
    }
}

extension ReactionBar: UICollectionViewDelegateFlowLayout {

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if indexPath.row < self.items.count {
            // 高度固定等于默认高度
            let displayHeight = self.reactionSize.height
            // 宽度先等于默认宽度，之后按照服务端时间给的大小等比缩放
            var displayWidth = self.reactionSize.width
            // 取出服务端返回的实际size
            let entitySize = self.items[indexPath.row].reactionEntity.size
            var size = entitySize
            // 如果图片大小和服务端给的不一致，以实际图片大小为准
            if let image = EmotionResouce.shared.imageBy(key: self.items[indexPath.row].reactionEntity.key) {
                // 这样比较是为了忽略1像素的误差
                if abs(image.size.width - entitySize.width) > 1 || abs(image.size.height - entitySize.height) > 1 {
                    size = image.size
                }
            }
            // 产品对默认表情有个规则：在96高的情况下，宽度在96~134之间（4倍图）转化下就是在24高度下，宽度限制在24~33.5之间
            // 根据上面的规则在32的高度限制下，宽度应该限制在32~44.6之间
            if size.height != 0 {
                // 如果宽度大于45（对44.6向下取整），说明是企业自定义表情，容器宽度有自己的计算规则
                if size.width > 45 {
                    // 宽度等比缩放
                    displayWidth = displayHeight * size.width / size.height
                } else {
                    // 默认表情（32高度下，宽度限制在32~44.6之间）容器的大小是等宽等高的
                    displayWidth = displayHeight
                }
                return CGSize(width: displayWidth, height: displayHeight)
            }
            // 返回默认值
            return self.reactionSize
        } else {
            // 更多按钮，如果有的话
            return self.moreIconSize
        }
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return self.edgeInset
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return 0
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return self.minimumInteritemSpacing
    }
}

extension ReactionBar: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.showItemCount
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cellIdentifier = String(describing: ReactionCollectionCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        if let collectionCell = cell as? ReactionCollectionCell {
            if indexPath.row < self.items.count {
                if self.supportSheetMenu {
                    collectionCell.backgroundColor = UIColor.clear
                    collectionCell.clipsToBounds = false
                    collectionCell.layer.cornerRadius = 0
                }
                collectionCell.setCellContent(reactionEntity: self.items[indexPath.row].reactionEntity, delegate: nil)
            } else {
                self.closeIconImageView = collectionCell.iconView
                collectionCell.iconView.image = Resources.reactionMore
                var iconWidth = moreIconSize.width
                var iconHeight = moreIconSize.height
                if self.supportSheetMenu {
                    collectionCell.iconView.image = Resources.sheetMenuMore
                    collectionCell.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
                    collectionCell.clipsToBounds = true
                    collectionCell.layer.cornerRadius = collectionCell.bounds.size.width / 2
                    iconWidth  = 20
                    iconHeight = 20
                }
                collectionCell.iconView.snp.remakeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.equalTo(iconWidth)
                    make.height.equalTo(iconHeight)
                }
            }
        }
        return cell
    }
}
