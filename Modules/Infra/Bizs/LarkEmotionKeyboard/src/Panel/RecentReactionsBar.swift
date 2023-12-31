//
//  RecentReactionBar.swift
//  LarkChat
//
//  Created by 李晨 on 2019/1/29.
//

import Foundation
import UIKit
import LarkEmotion
import LKCommonsLogging

public protocol RecentReactionsBarDelegate: AnyObject {
    /// 点击了more按钮
    func recentReactionsBarDidClickMoreButton(_ bar: RecentReactionsBar)
}

public final class RecentReactionsBar: UIView {
    private static let logger = Logger.log(RecentReactionsBar.self, category: "Module.LarkEmotionKeyboard.RecentReactionsBar")

    // MARK: Public
    public var moreIconColor: UIColor?
    public var items: [MenuReactionItem] {
        didSet {
            self.updateReactionsView()
        }
    }
    public var clickMoreBlock: (() -> Void)?
    public weak var delegate: RecentReactionsBarDelegate?
    public var showMore: Bool = false {
        didSet {
            if self.showMore {
                self.closeIconImageView?.transform = CGAffineTransform(rotationAngle: .pi / 4)
            } else {
                self.closeIconImageView?.transform = CGAffineTransform.identity
            }
        }
    }

    // MARK: Read-only
    public let reactionSize: CGSize
    public let moreIconSize: CGSize
    public let reactionBarHeight: CGFloat
    public let edgeInset: UIEdgeInsets
    // public fileprivate(set) lazy var reactionLayout: ReactionFlowLayout = ReactionFlowLayout(delegate: self)
    public fileprivate(set) lazy var reactionLayout: RecentReactionsFlowLayout = RecentReactionsFlowLayout()
    public fileprivate(set) lazy var reactionCollection: UICollectionView =
        UICollectionView(frame: CGRect.zero, collectionViewLayout: reactionLayout)

    // MARK: Private
    private var supportMoreReactions: Bool {
        didSet {
            if supportMoreReactions == oldValue {
                return
            }
            self.updateReactionsView()
        }
    }
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
    private let reactionImageFetcher: ReactionImageDelegate.Type?
    private var closeIconImageView: UIImageView?
    private var separatorLine: UIImageView = UIImageView()

    // MARK: Functions
    public init(config: RecentReactionPanelConfig,
                reactionImageFetcher: ReactionImageDelegate.Type? = defaultReactionImageService) {
        self.items = config.items
        self.clickMoreBlock = config.clickMoreBlock
        self.reactionSize = config.reactionSize
        self.moreIconSize = config.moreIconSize
        self.reactionBarHeight = config.reactionBarHeight
        self.moreIconColor = config.moreIconColor
        self.supportMoreReactions = config.supportMoreReactions
        self.supportSheetMenu = config.supportSheetMenu
        self.edgeInset = config.reactionLayoutEdgeInset
        self.reactionImageFetcher = reactionImageFetcher
        assert(reactionImageFetcher != nil, "reactionImageFetcher不能为空！若采用默认实现，请引入icon这个subspec")

        super.init(frame: .zero)

        reactionCollection.backgroundColor = config.reactionCollectionBackgroundColor
        reactionCollection.showsVerticalScrollIndicator = false
        reactionCollection.showsHorizontalScrollIndicator = false
        reactionCollection.isPagingEnabled = false
        reactionCollection.dataSource = self
        reactionCollection.delegate = self

        let cellIdentifier = String(describing: ReactionCell.self)
        reactionCollection.register(ReactionCell.self, forCellWithReuseIdentifier: cellIdentifier)

        self.addSubview(reactionCollection)
        // bar的高度和reactionSize的高度一致，并且整个bar在父容器中居中，宽度撑满父容器
        let barHeight = self.reactionSize.height
        reactionCollection.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(barHeight)
        }
        if self.supportSheetMenu {
            // SheetMenu的话需要加一条分割线
            separatorLine.backgroundColor = UIColor.ud.lineDividerDefault
            self.addSubview(separatorLine)
            separatorLine.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(0.5)
            }
            //self.backgroundColor = UIColor.yellow
            //reactionCollection.backgroundColor = UIColor.green
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
        self.reactionLayout.invalidateLayout()
        self.reactionCollection.reloadData()
    }

    private var showItemCount: Int {
        guard self.reactionCollection.bounds.width > 0 else {
            return self.maxItemCount
        }
        // 日志上报
        var extraInfo: [(key: String, index: Int, displayWidth: CGFloat, displayHeight: CGFloat, entityWidth: CGFloat, entityHeight: CGFloat, imageWidth: CGFloat, imageHeight: CGFloat)] = []
        // 计算出最多显示Reaction的个数，需要考虑隐藏更多按钮的情况
        let maxNumber: Int = (self.supportMoreReactions ? self.maxItemCount : self.maxItemCount + 1)
        // 计算出最长的显示宽度，需要考虑隐藏更多按钮的情况
        var panelWidth = self.reactionCollection.bounds.width - self.edgeInset.right - self.edgeInset.left
        if self.supportMoreReactions {
            // 如果有更多按钮的话需要去掉更多按钮的宽度
            panelWidth -= self.reactionSize.width
        }
        // 根据是否需要显示更多按钮决定最后一个显示的item是否要右对齐
        self.reactionLayout.lastItemAlignedRight = self.supportMoreReactions
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
            // 这样写是为了能过CI检测：会限制每行最多的字符
            let k = item.reactionEntity.key
            let dw = displayWidth
            let dh = displayHeight
            let ew = entitySize.width
            let eh = entitySize.height
            let iw = imageSize.width
            let ih = imageSize.height
            if width + displayWidth > (panelWidth + 3) {
                let tuples = (key: k, index: count + 1, displayWidth: dw, displayHeight: dh, entityWidth:ew, entityHeight:eh, imageWidth: iw, imageHeight:ih)
                extraInfo.append(tuples)
                break
            }
            count += 1
            width += (displayWidth + minSpace)
            let tuples = (key: k, index: count, displayWidth: dw, displayHeight: dh, entityWidth:ew, entityHeight:eh, imageWidth: iw, imageHeight:ih)
            extraInfo.append(tuples)
        }
        let recentReactionsCount = min(maxNumber, count)
        // 日志上报
        var params: [String: String] = [:]
        params["panelWidth"] = "\(panelWidth)"
        params["minSpace"] = "\(minSpace)"
        params["recentReactionsCount"] = "\(recentReactionsCount)"
        params["items"] = "\(extraInfo)"
        Self.logger.info("reaction bar: recent emojis info", additionalData: params)

        // 经过计算后发现实际显示的Reaction要比数据源里面的少
        if recentReactionsCount < self.items.count {
            let start = recentReactionsCount
            let end = self.items.count
            // 数据源里面去掉不要显示的
            self.items.removeSubrange(start..<end)
        }
        return recentReactionsCount + (self.supportMoreReactions ? 1 : 0)
    }

    private var minimumInteritemSpacing: CGFloat {
        let size = self.reactionSize
        let number = self.maxItemCount
        let insets = self.edgeInset

        let space = CGFloat(
            (self.reactionCollection.bounds.width -
                size.width * CGFloat(number) -
                insets.left -
                insets.right) /
                CGFloat(number - 1)
            )
        return space
    }
}

extension RecentReactionsBar: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row < self.items.count {
            let item = self.items[indexPath.row]
            item.action(item.type)
        } else {
            self.clickMoreBlock?()
            self.delegate?.recentReactionsBarDidClickMoreButton(self)
        }
    }
}

extension RecentReactionsBar: UICollectionViewDelegateFlowLayout {
    // nolint: duplicated_code -- 该类为老版本，全量过后就可以删了
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
            return self.reactionSize
        }
    }
    // enable-lint: duplicated_code

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

extension RecentReactionsBar: UICollectionViewDataSource {

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
        let cellIdentifier = String(describing: ReactionCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        if let collectionCell = cell as? ReactionCell {
            if indexPath.row < self.items.count {
                if self.supportSheetMenu {
                    collectionCell.backgroundColor = UIColor.clear
                    collectionCell.clipsToBounds = false
                    collectionCell.layer.cornerRadius = 0
                }
                collectionCell.icon.image = EmotionResouce.placeholder
                let reactionKey = self.items[indexPath.row].type
                collectionCell.reactionImageFetcher = self.reactionImageFetcher
                collectionCell.reactionKey = reactionKey
            } else {
                self.closeIconImageView = collectionCell.icon
                collectionCell.icon.image = Resources.reactionMore
                var iconWidth = moreIconSize.width
                var iconHeight = moreIconSize.height
                if self.supportSheetMenu {
                    collectionCell.icon.image = Resources.sheetMenuMore
                    collectionCell.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.05)
                    collectionCell.clipsToBounds = true
                    collectionCell.layer.cornerRadius = collectionCell.bounds.size.width / 2
                    iconWidth  = moreIconSize.width / 2
                    iconHeight = moreIconSize.height / 2
                }
                if let color = self.moreIconColor {
                    collectionCell.icon.image = collectionCell.icon.image?.withRenderingMode(.alwaysTemplate)
                    collectionCell.icon.tintColor = color
                }
                collectionCell.icon.snp.remakeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.equalTo(iconWidth)
                    make.height.equalTo(iconHeight)
                }
            }
        }
        return cell
    }
}
