//
//  ReactionPanel.swift
//  LarkEmotionKeyboard
//
//  Created by phoenix on 2023/3/28.
//

import Foundation
import RxSwift
import LarkFloatPicker
import LKCommonsLogging
import UIKit
import RustPB
import LarkEmotion
import LarkSetting

/// - Parameters:
///   - reactionKey: 表情 key
///   - index: 下标
///   - isSkintonePanel: 选中的表情是否为多肤色
///   - skintoneEmojiSelectWay: 多肤色表情的选中方式
public typealias ClickReactionBlock = ((_ reactionKey: String,
                                        _ index: Int,
                                        _ isSkintonePanel: Bool,
                                        _ skintoneEmojiSelectWay: SelectedWay?) -> Void)

// Reaction面板配置参数
public struct ReactionPanelConfig {
    public static let defaultSectionHeaderHeight: CGFloat = 26
    public static let defaultSpaceBetweenRow: CGFloat = 14
    // 点击回调
    let clickReactionBlock: ClickReactionBlock?
    // 面板滚动的回调
    let scrollViewDidScrollBlock: ((_ contentOffset: CGPoint) -> Void)?
    // 每个表情的大小
    let reactionSize: CGSize
    // 面板的边距
    let edgeInset: UIEdgeInsets
    // 每个Section的边距
    let sectionInset: UIEdgeInsets
    // 表情列表的行间距
    let spaceBetweenRow: CGFloat
    // 每行表情数
    let numberInRow: Int
    // 每个Section头部高度
    let sectionHeaderHeight: CGFloat
    // 是否支持新版菜单（是否显示「最常使用」模块，需要改名）
    let supportSheetMenu: Bool
    // 场景参数, 用于统计接入该组件的业务方。新增的业务方可以在组件侧同学新增
    let scene: ReactionPanelScene
    /// 过滤器，用于控制显示的模块。例：如仅显示「默认表情」
    /// filer = { group in
    ///    group.type == .default
    /// }
    let filter: ((ReactionGroup) -> Bool)?

    // 初始化
    public init(clickReactionBlock: ClickReactionBlock? = nil,
                scrollViewDidScrollBlock: ((_ contentOffset: CGPoint) -> Void)? = nil,
                reactionSize: CGSize = CGSize(width: 28, height: 28),
                edgeInset: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
                sectionInset: UIEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 10, right: 16),
                spaceBetweenRow: CGFloat = defaultSpaceBetweenRow,
                numberInRow: Int = 7,
                sectionHeaderHeight: CGFloat = defaultSectionHeaderHeight,
                supportSheetMenu: Bool = false,
                scene: ReactionPanelScene = .unknown,
                filter: ((ReactionGroup) -> Bool)? = nil) {
        self.clickReactionBlock = clickReactionBlock
        self.scrollViewDidScrollBlock = scrollViewDidScrollBlock
        self.reactionSize = reactionSize
        self.edgeInset = edgeInset
        self.sectionInset = sectionInset
        self.spaceBetweenRow = spaceBetweenRow
        self.numberInRow = numberInRow
        self.sectionHeaderHeight = sectionHeaderHeight
        self.supportSheetMenu = supportSheetMenu
        self.scene = scene
        self.filter = filter
    }
}


public final class ReactionPanel: UIView {
    private static let logger = Logger.log(ReactionPanel.self, category: "Module.LarkEmotionKeyboard.ReactionPanel")

    // 表情注入服务
    private let dependency: EmojiDataSourceDependency? = EmojiImageService.default
    // 数据源：组件内部闭环，不向外暴露
    private let reactionGroups: [ReactionGroup]

    public var isCommonlyUsedABTestEnable: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: "im.emoji.commonly_used_abtest")
    }

    // 表情大小
    private let reactionSize: CGSize
    // 面板的边距
    private let edgeInset: UIEdgeInsets
    // 每个Section的边距
    private let sectionInset: UIEdgeInsets
    // 每个Section头部高度
    private let sectionHeaderHeight: CGFloat
    // 行间距
    private let spaceBetweenRow: CGFloat
    // 显示列数
    private let numberInRow: Int
    // 是否支持新版菜单
    private let supportSheetMenu: Bool
    // 场景参数
    private let scene: ReactionPanelScene
    
    let disposeBag = DisposeBag()

    // 面板高度
    public var panelHeight: CGFloat {
        // 视觉稿上要求默认表情显示6行半
        var showNumber: CGFloat = 6.7
        var numberOfRow: Int = 7
        if UIDevice.current.userInterfaceIdiom == .pad && self.scene == .todo {
            showNumber = 4.7
            numberOfRow = 5
        }
        return self.edgeInset.top + self.sectionHeaderHeight + self.sectionInset.top + showNumber * self.reactionSize.height + CGFloat(numberOfRow - 1) * self.spaceBetweenRow
    }
    // 最常使用表情的数量，打底是7个，需要根据实际的图片宽度计算最终值
    private var userReactionsCount: Int = 7
    // 布局器
    public private(set) lazy var layout: EmotionLeftAlignedFlowLayout = EmotionLeftAlignedFlowLayout()
    // 面板容器
    public private(set) lazy var collection: UICollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)

    // 选中某个表情的回调：表情Key、是否在多肤色面板上选中的、多肤色面板选中方式
    public var clickReactionBlock: ClickReactionBlock?
    // 面板滚动的回调
    public var scrollViewDidScrollBlock: ((_ contentOffset: CGPoint) -> Void)?

    // 初始化
    public init(config: ReactionPanelConfig) {
        self.clickReactionBlock = config.clickReactionBlock
        self.scrollViewDidScrollBlock = config.scrollViewDidScrollBlock
        self.reactionSize = config.reactionSize
        self.edgeInset = config.edgeInset
        self.sectionInset = config.sectionInset
        self.sectionHeaderHeight = config.sectionHeaderHeight
        self.spaceBetweenRow = config.spaceBetweenRow
        self.numberInRow = config.numberInRow
        self.supportSheetMenu = config.supportSheetMenu
        self.scene = config.scene
        
        let groups: [ReactionGroup]
        // 通过表情服务获取数据源：新版菜单要加上mru分组，产品说的>_<
        if self.supportSheetMenu {
            var allGroups: [ReactionGroup] = self.dependency?.getAllReactions() ?? []
            let mruGroup = ReactionGroup(type: .unknown, iconKey: "", title: BundleI18n.LarkEmotionKeyboard.Lark_IM_FrequentlyUsedEmojis_Title, source: "", entities: self.dependency?.getMRUReactions() ?? [])
            allGroups.insert(mruGroup, at: 0)
            groups = allGroups
        } else {
            // 旧版菜单只需要默认表情就行
            groups = self.dependency?.getAllReactions() ?? []
        }
        if let filter = config.filter {
            self.reactionGroups = groups.filter(filter)
        } else {
            self.reactionGroups = groups
        }
        
        super.init(frame: .zero)

        self.backgroundColor = UIColor.clear

        collection.backgroundColor = UIColor.clear
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.isPagingEnabled = false
        collection.dataSource = self
        collection.delegate = self

        let cellIdentifier = String(describing: ReactionCollectionCell.self)
        collection.register(ReactionCollectionCell.self, forCellWithReuseIdentifier: cellIdentifier)
        let emptyIdentifier = String(describing: UICollectionViewCell.self)
        collection.register(UICollectionViewCell.self, forCellWithReuseIdentifier: emptyIdentifier)
        let sectionIdentified = String(describing: EmotionHeaderView.self)
        collection.register(EmotionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: sectionIdentified)

        self.addSubview(collection)
        collection.snp.makeConstraints({ make in
            make.edges.equalToSuperview().inset(self.edgeInset)
        })
        collection.accessibilityIdentifier = "menu.more.bar.collection"

        // 日志上报
        var params: [String: String] = [:]
        var extraInfo: [(title: String, entitiesCount: Int)] = []
        for group in self.reactionGroups {
            let tuples = (title: group.title, entitiesCount: group.entities.count)
            extraInfo.append(tuples)
        }
        params["count"] = "\(self.reactionGroups.count)"
        params["groups"] = "\(extraInfo)"
        Self.logger.info("ReactionPanel: reaction groups info", additionalData: params)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        // 新版菜单有最常使用表情
        if self.supportSheetMenu {
            // 最常使用表情里面会有企业自定义表情，所以每次布局发生变化都需要重新计算一行能显示几个
            self.setupUserReactions()
        }
    }

    private var minimumInteritemSpacing: CGFloat {
        let number = CGFloat(self.numberInRow)
        let allIconWidth = self.reactionSize.width * number
        let allSpace = self.collection.bounds.width - allIconWidth - self.sectionInset.left - self.sectionInset.right
        var space = allSpace / 6.0
        if number - 1 > 0 {
            space = allSpace / (number - 1)
        }
        return space
    }

    // 返回ReactionEntity
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

    // 计算最常使用表情一行显示几个
    private func setupUserReactions() {
        let userReactions = self.dependency?.getMRUReactions() ?? []
        // 容器宽度
        let containerWidth = self.bounds.width
        // 最多显示7个
        var maxNumber: Int = 7
        var maxLine: Int = 1
        if isCommonlyUsedABTestEnable {
            // FG打开的时候需要显示两行，也就是最多14个
            maxNumber = 14
            maxLine = 2
        }
        // 实际显示个数，需要动态计算
        var count: Int = 0
        // 左边距
        let leftSpace: CGFloat = self.sectionInset.left + self.edgeInset.left
        // 右边距
        let rightSpace: CGFloat = self.sectionInset.right + self.edgeInset.right
        // 日志上报
        var extraInfo: [(key: String, index: Int, disW: CGFloat, disH: CGFloat, entW: CGFloat, entH: CGFloat, imgW: CGFloat, imgH: CGFloat)] = []
        // 计算出panel的宽度
        let panelWidth = containerWidth - rightSpace - leftSpace
        // 列间距
        let minSpace = minimumInteritemSpacing
        var width: CGFloat = 0
        // 从一行开始算
        var line: Int = 1
        // 计算一行实际显示的个数
        for reaction in userReactions {
            // 图片的默认高度：28
            let iconHeight: CGFloat = self.reactionSize.height
            // 图片的默认宽度：28
            var iconWidth: CGFloat = self.reactionSize.width
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
            // 给个2像素的误差
            if width > (panelWidth + minSpace + 2) {
                let tuples = (key: reaction.key, index: count + 1, disW: iconWidth, disH: iconHeight, entW:entitySize.width, entH:entitySize.height, imgW: imageSize.width, imgH:imageSize.height)
                extraInfo.append(tuples)
                // 到这边说明该行已经布局不下，需要换行了，换行后累计宽度要重置
                width = 0
                // 如果已经达到最大行数，那就直接跳出循环
                if line == maxLine {
                    break
                } else {
                    // 还没到最大行数，那么正常换行
                    line += 1
                    // 换行以后的累计宽度
                    width += (iconWidth + minSpace)
                }
            }
            count += 1
            let tuples = (key: reaction.key, index: count, disW: iconWidth, disH: iconHeight, entW:entitySize.width, entH:entitySize.height, imgW: imageSize.width, imgH:imageSize.height)
            extraInfo.append(tuples)
        }
        self.userReactionsCount = min(maxNumber, count)
        let number = self.userReactionsCount
        // 日志上报
        var params: [String: String] = [:]
        params["panelWidth"] = "\(panelWidth)"
        params["minSpace"] = "\(minSpace)"
        params["number"] = "\(number)"
        params["items"] = "\(extraInfo)"
        Self.logger.info("ReactionPanel: mru reactions info", additionalData: params)
    }
}

extension ReactionPanel: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let reaction = self.reactionGroups[indexPath.section].entities[indexPath.row]
        // 回调给业务方
        self.clickReactionBlock?(reaction.selectSkinKey, indexPath.section, false, nil)
    }
}

extension ReactionPanel: UICollectionViewDataSource {

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.reactionGroups.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.supportSheetMenu && section == 0 {
            return self.userReactionsCount
        }
        return self.reactionGroups[section].entities.count
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let name = String(describing: EmotionHeaderView.self)
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: name, for: indexPath)
            if let emotionHeaderView = cell as? EmotionHeaderView, indexPath.section < self.reactionGroups.count {
                let iconKey = self.reactionGroups[indexPath.section].iconKey
                let str = self.reactionGroups[indexPath.section].title
                emotionHeaderView.setData(model: EmotionHeaderModel(iconKey: iconKey, titleName: str), xOffset: self.sectionInset.left)
                emotionHeaderView.backgroundColor = UIColor.clear
            }
            return cell
        }
        return UICollectionReusableView()
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellIdentifier = String(describing: ReactionCollectionCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        if let collectionCell = cell as? ReactionCollectionCell {
            let reactionEntity = self.reactionEntityForIndexPath(indexPath: indexPath)
            collectionCell.setCellContent(reactionEntity: reactionEntity, delegate: self)
        }
        cell.accessibilityIdentifier = "menu.more.bar.collection.send.cell.\(indexPath.row)"
        return cell
    }
}

extension ReactionPanel: UICollectionViewDelegateFlowLayout {

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if let reactionEntity = self.reactionEntityForIndexPath(indexPath: indexPath) {
            // 只有企业自定义表情才需要每个元素分别计算大小，其他类型表情返回固定大小就行
            let type: Im_V1_EmojiPanel.TypeEnum = self.reactionEntityTypeForIndexPath(indexPath: indexPath)
            if type == .default {
                // 默认表情直接返回默认值
                return self.reactionSize
            } else if type == .unknown {
                // 图片的默认高度：28
                let displayHeight: CGFloat = self.reactionSize.height
                // 图片的默认宽度：28
                var displayWidth: CGFloat = self.reactionSize.width
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
                    displayWidth = displayHeight * size.width / size.height
                }
                return CGSize(width: displayWidth, height: displayHeight)
            }
            // 企业自定义表情需要根据固定高度计算显示的宽度
            // 图片的默认高度：28
            let displayHeight: CGFloat = self.reactionSize.height
            // 图片的默认宽度：28
            var displayWidth: CGFloat = self.reactionSize.width
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
            if size.height != 0 {
                // 宽度等比缩放
                displayWidth = displayHeight * size.width / size.height
            }
            return CGSize(width: displayWidth, height: displayHeight)
        }
        // 返回默认值
        return self.reactionSize
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return self.sectionInset
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

extension ReactionPanel: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.scrollViewDidScrollBlock?(scrollView.contentOffset)
    }
}

extension ReactionPanel: ReactionCollectionCellDelegate {
    func onSkinTonesDidSelected(newSkinKey: String, oldSkinKey: String, defaultKey: String, selectedWay: SelectedWay) {
        var newSkinKey = newSkinKey
        if let reactionkey = EmotionResouce.shared.reactionKeyBy(emotionKey: newSkinKey) {
            newSkinKey = reactionkey
        }
        self.clickReactionBlock?(newSkinKey, 0, true, selectedWay)
        // 新旧Key不一致的时候，更新多肤色
        if oldSkinKey != newSkinKey {
            self.dependency?.updateReactionSkin(defaultReactionKey: defaultKey, skinKey: newSkinKey)
        }
    }
}
