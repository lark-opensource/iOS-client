//
//  MoreReactionsBar.swift
//  LarkChat
//
//  Created by 李晨 on 2019/2/2.
//

import Foundation
import SnapKit
import LarkContainer
import RxSwift
import LarkFloatPicker
import LKCommonsLogging
import UIKit
import RustPB
import LarkEmotion

public final class MoreReactionsBar: UIView {
    private static let logger = Logger.log(MoreReactionsBar.self, category: "Module.LarkEmotionKeyboard.MoreReactionsBar")
    
    // reaction注入服务
    private let dependency: EmojiDataSourceDependency?

    // MARK: Private
    private let numberOfRow: Int
    private let numberInRow: Int
    private let reactionImageFetcher: ReactionImageDelegate.Type?
    private let iconSize: CGSize
    private let spaceBetweenRow: CGFloat
    private let sectionHeaderHeight: CGFloat = 26
    // 依赖LarkMenuController用户态改造，TODO：@qujieye
    @InjectedLazy var skinApi: ReactionSkinTonesAPI
    let disposeBag = DisposeBag()

    // 默认支持长按手势
    public var reactionSupportSkinTones: Bool = true
    public var barHeight: CGFloat {
        // 产品要求固定高度271.0，个人感觉根据显示多少行来计算比较合适，最终产品也没发现>_<
        // 视觉稿上要求默认表情显示出来6行半
        let showNumber: CGFloat = 7.2
        return sectionHeaderHeight + self.edgeInset.top + self.spaceBetweenRow + showNumber * self.iconSize.height + CGFloat(self.numberOfRow - 1) * self.spaceBetweenRow
    }
    // 最近发送reaction的数量，打底是7个，需要根据实际的图片宽度计算最终值
    private var recentReactionsCount: Int = 7

    public let edgeInset: UIEdgeInsets
    public private(set) lazy var reactionLayout: EmotionLeftAlignedFlowLayout = EmotionLeftAlignedFlowLayout()
    public private(set) lazy var reactionPanelCollection: UICollectionView =
        UICollectionView(frame: CGRect.zero, collectionViewLayout: reactionLayout)

    // MARK: Public
    public var clickReactionBlock: ClickReactionBlock?
    public var clickCloseBlock: (() -> Void)?
    public var scrollViewDidScrollBlock: ((_ contentOffset: CGPoint) -> Void)?
    public var closeInTop: Bool {
        didSet {
            self.reactionPanelCollection.reloadData()
        }
    }
    public var closeIconColor: UIColor?
    public var reactionGroups: [ReactionGroup] {
        didSet {
            self.reactionPanelCollection.reloadData()
        }
    }

    // MARK: Functions
    public init(config: MoreReactionPanelConfig,
                reactionImageFetcher: ReactionImageDelegate.Type? = defaultReactionImageService) {
        self.numberOfRow = config.numberOfRow
        self.numberInRow = config.numberInRow
        self.clickReactionBlock = config.clickReactionBlock
        self.clickCloseBlock = config.clickCloseBlock
        self.scrollViewDidScrollBlock = config.scrollViewDidScrollBlock
        self.closeInTop = config.closeInTop
        self.closeIconColor = config.closeIconColor
        self.reactionGroups = config.reactionGroups
        self.reactionImageFetcher = reactionImageFetcher
        self.iconSize = config.iconSize
        self.spaceBetweenRow = config.spaceBetweenRow
        self.edgeInset = config.reactionLayoutEdgeInset
        self.dependency = EmojiImageService.default
        assert(reactionImageFetcher != nil, "reactionImageFetcher不能为空！若采用默认实现，请引入icon这个subspec")

        super.init(frame: .zero)

        self.backgroundColor = config.backgroundColor

        reactionPanelCollection.backgroundColor = config.reactionCollectionBackgroundColor
        reactionPanelCollection.showsVerticalScrollIndicator = false
        reactionPanelCollection.showsHorizontalScrollIndicator = false
        reactionPanelCollection.isPagingEnabled = false
        reactionPanelCollection.dataSource = self
        reactionPanelCollection.delegate = self

        let cellIdentifier = String(describing: ReactionCell.self)
        reactionPanelCollection.register(ReactionCell.self, forCellWithReuseIdentifier: cellIdentifier)
        let emptyIdentifier = String(describing: UICollectionViewCell.self)
        reactionPanelCollection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: emptyIdentifier)
        let sectionIdentified = String(describing: EmotionHeaderView.self)
        reactionPanelCollection.register(EmotionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: sectionIdentified)

        self.addSubview(reactionPanelCollection)
        reactionPanelCollection.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        reactionPanelCollection.accessibilityIdentifier = "menu.more.bar.collection"

        // 日志上报
        var params: [String: String] = [:]
        var extraInfo: [(title: String, entitiesCount: Int)] = []
        for group in self.reactionGroups {
            let tuples = (title: group.title, entitiesCount: group.entities.count)
            extraInfo.append(tuples)
        }
        params["count"] = "\(self.reactionGroups.count)"
        params["groups"] = "\(extraInfo)"
        Self.logger.info("reaction panel: more reactions bar groups info", additionalData: params)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
    }

    private var minimumInteritemSpacing: CGFloat {
        let size = self.iconSize
        let number = self.numberInRow
        let insets = self.edgeInset

        let space = CGFloat(
            (self.reactionPanelCollection.bounds.width -
                size.width * CGFloat(number) -
                insets.left -
                insets.right) /
                CGFloat(number - 1)
            )
        return space
    }

    // 返回reactionEntity
    public func reactionEntityForIndexPath(indexPath: IndexPath) -> ReactionEntity? {
        guard indexPath.section < self.reactionGroups.count, indexPath.row < self.reactionGroups[indexPath.section].entities.count else {
            return nil
        }
        return self.reactionGroups[indexPath.section].entities[indexPath.row]
    }

    public func reactionEntityTypeForIndexPath(indexPath: IndexPath) -> Im_V1_EmojiPanel.TypeEnum {
        guard indexPath.section < self.reactionGroups.count else {
            return .unknown
        }
        return self.reactionGroups[indexPath.section].type
    }

    // 计算最近使用的reactions一行显示几个
    private func setupRecentReactions() {
        let recentReactions = self.dependency?.getMRUReactions() ?? []
        // 容器宽度
        let containerWidth = self.bounds.width
        // 最多显示7个
        let maxNumber: Int = 7
        // 实际显示个数，需要动态计算
        var count: Int = 0
        // 左边距
        let leftSpace: CGFloat = self.edgeInset.left
        // 右边距
        let rightSpace: CGFloat = self.edgeInset.right
        // 日志上报
        var extraInfo: [(key: String, index: Int, displayWidth: CGFloat, displayHeight: CGFloat, entityWidth: CGFloat, entityHeight: CGFloat, imageWidth: CGFloat, imageHeight: CGFloat)] = []
        // 计算出panel的宽度
        let panelWidth = containerWidth - rightSpace - leftSpace
        // 列间距
        let minSpace = (containerWidth - self.iconSize.width * CGFloat(maxNumber) - leftSpace - rightSpace) / CGFloat(maxNumber - 1)
        var width: CGFloat = 0
        // 计算一行实际显示的个数
        for reaction in recentReactions {
            // 图片的默认高度：28
            let iconHeight: CGFloat = self.iconSize.height
            // 图片的默认宽度：28
            var iconWidth: CGFloat = self.iconSize.width
            // 取出服务端返回的实际size
            let entitySize = reaction.size
            var size = entitySize
            var imageSize = CGSize(width: 0, height: 0)
            // 如果图片大小和服务端给的不一致，以实际图片大小为准
            if let image = EmotionResouce.shared.imageBy(key: reaction.key) {
                imageSize = image.size
                // 这样比较是为了忽略1像素的误差
                if abs(imageSize.width - entitySize.width) > 1 || abs(imageSize.height - entitySize.height) > 1 {
                    size = image.size
                }
            }
            // 产品对默认表情有个规则：在96高的情况下，宽度在96~134之间（4倍图）转化下就是在24高度下，宽度限制在24~33.5之间
            // 根据上面的规则在32的高度限制下，宽度应该限制在32~44.6之间
            // 如果宽度大于45（对44.6向下取整），说明是企业自定义表情，宽度有自己的计算规则，否则宽度固定为默认表情宽度
            var threshold: CGFloat = 45.0
            if size.height == 48 {
                // 根据上面的规则在48的高度限制下，宽度应该限制在48~67之间
                threshold = 67.0
            }
            if size.height != 0 && size.width > threshold {
                // 这种情况下icon的宽度需要根据图片比例计算哦
                iconWidth = iconHeight * size.width / size.height
            }
            width += (iconWidth + minSpace)
            // 这样写是为了能过CI检测：会限制每行最多的字符
            let k = reaction.key
            let dw = iconWidth
            let dh = iconHeight
            let ew = entitySize.width
            let eh = entitySize.height
            let iw = imageSize.width
            let ih = imageSize.height
            // 给个2像素的误差
            if width > (panelWidth + minSpace + 2) {
                let tuples = (key: k, index: count + 1, displayWidth: dw, displayHeight: dh, entityWidth:ew, entityHeight:eh, imageWidth: iw, imageHeight:ih)
                extraInfo.append(tuples)
                break
            }
            count += 1
            let tuples = (key: k, index: count, displayWidth: dw, displayHeight: dh, entityWidth:ew, entityHeight:eh, imageWidth: iw, imageHeight:ih)
            extraInfo.append(tuples)
        }
        self.recentReactionsCount = min(maxNumber, count)
        let numberOfOneRow = self.recentReactionsCount
        // 日志上报
        var params: [String: String] = [:]
        params["panelWidth"] = "\(panelWidth)"
        params["minSpace"] = "\(minSpace)"
        params["numberOfOneRow"] = "\(numberOfOneRow)"
        params["items"] = "\(extraInfo)"
        Self.logger.info("emotion keyboard: keyboard recent emojis info", additionalData: params)
    }
}

extension MoreReactionsBar: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let reaction = self.reactionGroups[indexPath.section].entities[indexPath.row]
        self.clickReactionBlock?(reaction.selectSkinKey, indexPath.section, false, nil)
    }
    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? EmotionHighlightCollectionCell else {
            return
        }
        cell.showHighlightedBackgroundView()
    }

    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? EmotionHighlightCollectionCell else {
            return
        }
        cell.hideHighlightedBackgroundView()
    }
}

extension MoreReactionsBar: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.reactionGroups.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.reactionGroups[section].entities.count
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let name = String(describing: EmotionHeaderView.self)
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: name, for: indexPath)
            if let emotionHeaderView = cell as? EmotionHeaderView, indexPath.section < self.reactionGroups.count {
                let iconKey = self.reactionGroups[indexPath.section].iconKey
                let str = self.reactionGroups[indexPath.section].title
                emotionHeaderView.setData(model: EmotionHeaderModel(iconKey: iconKey, titleName: str), xOffset: 18)
            }
            return cell
        }
        return UICollectionReusableView()
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier = String(describing: ReactionCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        if let collectionCell = cell as? ReactionCell {
            collectionCell.icon.image = EmotionResouce.placeholder
            collectionCell.icon.transform = CGAffineTransform.identity
            collectionCell.reactionImageFetcher = self.reactionImageFetcher
            let reactionEntity = self.reactionEntityForIndexPath(indexPath: indexPath)
            collectionCell.setReactionEntity(reactionEntity, delegate: self)
        }
        cell.accessibilityIdentifier = "menu.more.bar.collection.send.cell.\(indexPath.row)"
        return cell
    }
}

extension MoreReactionsBar: UICollectionViewDelegateFlowLayout {

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if let reactionEntity = self.reactionEntityForIndexPath(indexPath: indexPath) {
            // 只有企业自定义表情才需要每个元素分别计算大小，其他类型表情返回固定大小就行
            let type: Im_V1_EmojiPanel.TypeEnum = self.reactionEntityTypeForIndexPath(indexPath: indexPath)
            if type == .default {
                // 返回默认值
                return self.iconSize
            } else if type == .unknown {
                // 图片的默认高度：28
                let iconHeight: CGFloat = self.iconSize.height
                // 图片的默认宽度：28
                var iconWidth: CGFloat = self.iconSize.width
                // 取出服务端返回的实际size
                let entitySize = reactionEntity.size
                var size = entitySize
                // 如果图片大小和服务端给的不一致，以实际图片大小为准
                var imageSize = CGSize(width: 0, height: 0)
                if let image = EmotionResouce.shared.imageBy(key: reactionEntity.key) {
                    imageSize = image.size
                    // 这样比较是为了忽略1像素的误差
                    if abs(imageSize.width - entitySize.width) > 1 || abs(imageSize.height - entitySize.height) > 1 {
                        size = image.size
                    }
                }
                // 产品对默认表情有个规则：在96高的情况下，宽度在96~134之间（4倍图）转化下就是在24高度下，宽度限制在24~33.5之间
                // 根据上面的规则在32的高度限制下，宽度应该限制在32~44.6之间
                // 如果宽度大于45（对44.6向下取整），说明是企业自定义表情，宽度有自己的计算规则，否则宽度固定为默认表情宽度
                var threshold: CGFloat = 45.0
                if size.height == 48 {
                    // 根据上面的规则在48的高度限制下，宽度应该限制在48~67之间
                    threshold = 67.0
                }
                if size.height != 0 && size.width > threshold {
                    // 这种情况下icon的宽度需要根据图片比例计算哦
                    iconWidth = iconHeight * size.width / size.height
                }
                return CGSize(width: iconWidth, height: iconHeight)
            }
            // 图片的默认高度：28
            let iconHeight: CGFloat = self.iconSize.height
            // 图片的默认宽度：28
            var iconWidth: CGFloat = self.iconSize.width
            // 取出服务端返回的实际size
            let entitySize = reactionEntity.size
            var size = entitySize
            // 如果图片大小和服务端给的不一致，以实际图片大小为准
            if let image = EmotionResouce.shared.imageBy(key: reactionEntity.key) {
                // 这样比较是为了忽略1像素的误差
                if abs(image.size.width - entitySize.width) > 1 || abs(image.size.height - entitySize.height) > 1 {
                    size = image.size
                }
            }
            if size.height != 0 {
                // 宽度等比缩放
                iconWidth = iconHeight * size.width / size.height
            }
            return CGSize(width: iconWidth, height: iconHeight)
        }
        // 返回默认值
        return self.iconSize
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        if section == self.reactionGroups.count - 1 {
            // 最后一行下边距要宽一点：UIEdgeInsets(top: 6, left: 16, bottom: 20, right: 16)
            return self.edgeInset
        }
        return UIEdgeInsets(top: 6, left: 16, bottom: 8, right: 16)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return self.spaceBetweenRow
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        return self.minimumInteritemSpacing
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        // 宽度只需要设置一个0.1，系统会默认拉长为所在视图的宽度
        return CGSize(width: 0.1, height: self.sectionHeaderHeight)
    }
}

extension MoreReactionsBar: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollViewDidScrollBlock?(scrollView.contentOffset)
    }
}

extension MoreReactionsBar: ReactionCellDelegate {
    func onSkinTonesDidSelectedReactionKey(_ newSkinKey: String, oldSkinKey: String, defaultKey: String, selectedWay: SelectedWay) {
        var newSkinKey = newSkinKey
        if let reactionkey = EmotionResouce.shared.reactionKeyBy(emotionKey: newSkinKey) {
            newSkinKey = reactionkey
        }
        self.clickReactionBlock?(newSkinKey, 0, true, selectedWay)
        /// 新旧Key不一致的时候，更新请求
        if oldSkinKey != newSkinKey {
            self.skinApi.updateReactionSkin(defaultReactionKey: defaultKey, skinKey: newSkinKey).subscribe(onError: { error in
                Self.logger.error("reaction panel: emoji updateReactionSkin", error: error)
            }).disposed(by: disposeBag)
        }
    }
    func supportSkinTones() -> Bool {
        return self.reactionSupportSkinTones
    }
}
