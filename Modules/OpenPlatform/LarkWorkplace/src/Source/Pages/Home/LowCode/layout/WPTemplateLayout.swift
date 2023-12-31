//
//  WPTemplateLayout.swift
//  templateDemo
//
//  Created by  bytedance on 2021/3/11.
//

import UIKit
import OPSDK
import LKCommonsLogging

/// UICollectionViewFlowLayout是一个专门用来管理collectionView布局的类，
/// 因此，collectionView在进行UI布局前，会通过这个类的对象获取相关的布局信息，FlowLayout类将这些布局信息全部存放在了一个数组中
/// 数组中是UICollectionViewLayoutAttributes类，这个类是对item布局的具体设置
/// 在collectionView布局时，会调用FlowLayout类layoutAttributesForElementsInRect：方法来获取这个布局配置数组
/// 另外，FlowLayout类在进行布局之前，会调用prepareLayout方法
/// 简单来说，自定义一个FlowLayout布局类就是两个步骤：
/// 1、在prepare方法中设计好我们的布局配置数据，缓存下来。并计算出内容空间collectionViewContentSize（可滚动的空间）
/// 2、返回我们的配置数组 layoutAttributesForElementsInRect方法中，返回当前可视frame需要展示的内容
final class WPTemplateLayout: UICollectionViewFlowLayout {
    static let logger = Logger.log(WPTemplateLayout.self)

    var enableRecentlyUsedApp: Bool {
        return configService.fgValue(for: .enableRecentlyUsedApp)
    }
    /// 自定义布局配置数据（cell）
    var cellAttrbutesData = [IndexPath: UICollectionViewLayoutAttributes]()
    /// 自定义布局配置数据（supplementary）
    var supplementaryAttrbutesData = [IndexPath: UICollectionViewLayoutAttributes]()
    /// decoration Attributes数据
    var decorationAttributesData = [IndexPath: BackgroundDecorationViewLayoutAttributes]()
    /// 可视区域的布局数据
    var visibleAttrbutes = [UICollectionViewLayoutAttributes]()
    /// 首屏可视cell的indexPath
    var firstFrameCellIndex = [IndexPath]()
    /// 布局渲染model
    var layoutModel: [GroupComponent]
    /// 已完成渲染的高度
    var contentHeight: CGFloat = 0
    /// 我的常用 header 高度
    var commonAndRecommendHeaderHeight: CGFloat = 0
    /// decoraion 代理
    weak var decorationDelegate: CollectionViewGroupBackgroundDelegate?

    /// collectionView必须知道「自己的内容大小」来决定滚动区域
    override var collectionViewContentSize: CGSize {
        return CGSize(width: collectionViewWidth, height: contentHeight)
    }

    var collectionViewWidth: CGFloat {
        // swiftlint:disable force_unwrapping
        return collectionView!.frame.width
        // swiftlint:enable force_unwrapping
    }

    // Layout 依赖不合理，需要后续优化
    let userId: String
    let configService: WPConfigService

    init(
        userId: String,
        configService: WPConfigService,
        layoutModel: [GroupComponent]
    ) {
        self.userId = userId
        self.configService = configService
        self.layoutModel = layoutModel
        super.init()
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        /// 注册®️background
        self.register(WPGroupBackground.self, forDecorationViewOfKind: groupBackgroundID)
    }

    override func prepare() {
        resetLayoutParams()
        prepareLayoutData()
    }

    /// 这个方法需要提供 UICollectionView 的视图区域里面所有的格子的布局属性。
    /// - Parameter rect: UICollectionView 的视图区域 CGRect.
    /// - Returns: UICollectionView 的内容视图区域内所有格子的布局属性.
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // 当前可见的标题栏索引
        var headerIndexPaths = [IndexPath]()
        // 当前可见的 Cell 所处的 Section 集合，用于判断我的常用标题栏是否处于可见区域
        var visibleCellSections = [Int]()
        visibleAttrbutes.removeAll(keepingCapacity: true)
        for attrbute in cellAttrbutesData.values {
            if rect.intersects(attrbute.frame) {
                visibleAttrbutes.append(attrbute)
                visibleCellSections.append(attrbute.indexPath.section)
            }
        }
        for attribute in supplementaryAttrbutesData.values {
            if rect.intersects(attribute.frame) {
                headerIndexPaths.append(attribute.indexPath)
            }
            // 常用应用、组件在可见区域
            guard layoutModel.count > attribute.indexPath.section,
                  layoutModel[attribute.indexPath.section].groupType == .CommonAndRecommend else {
                continue
            }
            if visibleCellSections.contains(attribute.indexPath.section) {
                headerIndexPaths.append(attribute.indexPath)
            }
        }
        firstFrameCellIndex.removeAll()
        // 遍历，记录首屏 cell 的 index
        for (index, attr) in self.cellAttrbutesData {
            if rect.intersects(attr.frame) {
                firstFrameCellIndex.append(index)
            }
        }
        for indexPath in headerIndexPaths {
            if let newAttribute = layoutAttributesForSupplementaryView(
                ofKind: UICollectionView.elementKindSectionHeader,
                at: indexPath
            ) {
                visibleAttrbutes.append(newAttribute)
            }
        }
        visibleAttrbutes.append(contentsOf: self.decorationAttributesData.values.filter({
            return rect.intersects($0.frame)
        }))
        Self.logger.info(
            "layoutAttributesForElements",
            additionalData: [
                "rect": "\(rect)",
                "visibleAttrbutes.count": "\(visibleAttrbutes.count)"
            ]
        )
        return visibleAttrbutes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cellAttrbutesData[indexPath]
    }

    override func layoutAttributesForSupplementaryView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        Self.logger.info(
            "layoutAttributesForSupplementaryView",
            additionalData: [
                "collectionView == nil": "\(collectionView == nil)",
                "layoutModel.count": "\(layoutModel.count)",
                "indexPath": "\(indexPath)",
                "layoutModel[indexPath.section].groupType": layoutModel[indexPath.section].groupType.rawValue
            ]
        )
        guard let layoutAttributes = supplementaryAttrbutesData[indexPath],
              elementKind == UICollectionView.elementKindSectionHeader else {
            return nil
        }
        guard let collectionView = collectionView,
              layoutModel.count > indexPath.section,
              layoutModel[indexPath.section].groupType == .CommonAndRecommend else {
            return layoutAttributes
        }

        // 常用标题栏，处理吸顶逻辑
        let appHeader = collectionView.supplementaryView(
            forElementKind: elementKind,
            at: indexPath
        ) as? WPCommonAppHeader
        let headerBottomMargin = getCommonHeaderBottomMargin(indexPath)
        var boundaries = boundries(forSection: indexPath.section)
        boundaries = (boundaries.minimum - headerBottomMargin, boundaries.maximum)
        let contentOffsetY = collectionView.contentOffset.y
        var supplementaryViewFrame = layoutAttributes.frame

        let minimum = boundaries.minimum - supplementaryViewFrame.height
        let maximum = boundaries.maximum - supplementaryViewFrame.height
        // --------------------------------- contentTop
        // |                               |
        // |                               | contentOffsetY
        // |                               |
        // ································  collectionViewTop
        // |                               |
        // |                               |
        // ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ sectionTop = minimum
        // |          sectionHeader        | headerHight
        // ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
        // |                               |
        // |          section X            |
        // |                               |
        // ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ maximum = sectionButtom - headerHight
        // |                               | headerHight
        // ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ sectionButtom
        // |                               |
        if contentOffsetY < minimum {
            // 如果 contentOffsetY 小于分组头最小的位置，则将分组头置于其最小位置
            supplementaryViewFrame.origin.y = minimum
            // 更新 Header 高斯模糊效果 -> 关闭
            appHeader?.updateBlurStyle(isSticked: false)
            layoutAttributes.zIndex = 0
        } else if contentOffsetY == minimum {
            // 吸顶/离顶 临界点
            supplementaryViewFrame.origin.y = contentOffsetY
            // 更新 Header 高斯模糊效果 -> 关闭
            appHeader?.updateBlurStyle(isSticked: false)
            layoutAttributes.zIndex = 0
        } else if contentOffsetY > minimum && contentOffsetY < maximum {
            supplementaryViewFrame.origin.y = contentOffsetY
            // 更新 Header 高斯模糊效果 -> 打开
            appHeader?.updateBlurStyle(isSticked: true)
            layoutAttributes.zIndex = 1
        } else if contentOffsetY >= maximum {
            // 如果 contentOffsetY 大于分组头最小的位置，则将分组头置于其最大位置
            supplementaryViewFrame.origin.y = maximum
            layoutAttributes.zIndex = 1
        } else {
            assertionFailure("should not be here")
            Self.logger.error(
                "should not be here",
                additionalData: [
                    "contentOffsetY": "\(contentOffsetY)",
                    "minimum": "\(minimum)",
                    "maximum": "\(maximum)"
                ]
            )
        }
        layoutAttributes.frame = supplementaryViewFrame
        Self.logger.info(
            "layoutAttributesForSupplementaryView",
            additionalData: [
                "layoutAttributes": "\(layoutAttributes)"
            ]
        )
        return layoutAttributes
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func layoutAttributesForDecorationView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        Self.logger.info(
            "layoutAttributesForDecorationView",
            additionalData: [
                "indexPath": "\(indexPath)",
                "decorationAttributesData[indexPath]": "\(decorationAttributesData[indexPath])"
            ]
        )
        return decorationAttributesData[indexPath]
    }

    // MARK: 具体实现

    private func resetLayoutParams() {
        contentHeight = 0
        cellAttrbutesData.removeAll()
        supplementaryAttrbutesData.removeAll()
        decorationAttributesData.removeAll()
        visibleAttrbutes.removeAll()
    }

    private func prepareLayoutData() {
        Self.logger.debug("layout parse with module number: \(layoutModel.count)")
        for section in 0..<layoutModel.count {
            let group = layoutModel[section]
            switch group.groupType {
            case .Block:
                setupBlockLayout(section: section, model: group)
            case .CommonAndRecommend:
                setupCommonAndRecommend(section: section, model: group)
            }
        }
    }

    /// 添加一个headerView的attributes
    func setupHeaderViewAttr(
        section: Int,
        row: Int,
        width: CGFloat,
        height: CGFloat,
        left: CGFloat,
        needPressInset: Bool? = true
    ) {
        let headerViewIndexPath = IndexPath(row: row, section: section)
        let headerViewAttributes = UICollectionViewLayoutAttributes(
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            with: headerViewIndexPath
        )
        let pressInset = (needPressInset ?? true) ?  WPTemplateHeader.inset : 0 // 按压态边界间隔
        let frame = CGRect(
            x: left - pressInset,
            y: contentHeight,
            width: width + pressInset,
            height: height
        )
        headerViewAttributes.frame = frame
        contentHeight = frame.maxY
        supplementaryAttrbutesData[headerViewIndexPath] = headerViewAttributes
    }

    /// 添加一个BackgroundView的attributes
    func setupBackgroundViewAttr(
        section: Int,
        row: Int,
        width: CGFloat,
        height: CGFloat,
        leftPos: CGFloat
    ) {
        let indexPath = IndexPath(row: row, section: section)
        let attributes = BackgroundDecorationViewLayoutAttributes(
            forDecorationViewOfKind: groupBackgroundID,
            with: indexPath
        )
        // 通过代理方法获取该section卡片装饰图使用的数据model
        attributes.model = decorationDelegate?.collectionView(
            // swiftlint:disable force_unwrapping
            collectionView!,
            // swiftlint:enable force_unwrapping
            layout: self,
            decorationDisplayedForSectionAt: section
        )
        /// ⚠️假设：backgroundView是最后布局的view，contentHeight就是background的bottom，减去height即为top  ❓存在很大的隐患，contentHeight是隐形依赖
        let frame = CGRect(x: leftPos, y: contentHeight - height, width: width, height: height)
        attributes.frame = frame
        attributes.zIndex = -1
        decorationAttributesData[indexPath] = attributes
    }

    private func boundries(forSection section: Int) -> (minimum: CGFloat, maximum: CGFloat) {
        var result = (minimum: CGFloat(0), maximum: CGFloat(0))
        guard let collectionView = collectionView else { return result }
        let numberOfItems = collectionView.numberOfItems(inSection: section)
        guard numberOfItems > 0 else { return result }

        let first = IndexPath(item: 0, section: section)
        let last = IndexPath(item: (numberOfItems - 1), section: section)
        if let firstItem = layoutAttributesForItem(at: first),
           let lastItem = layoutAttributesForItem(at: last) {
            result.minimum = firstItem.frame.minY
            result.maximum = lastItem.frame.maxY

            result.minimum -= headerReferenceSize.height
            result.maximum -= headerReferenceSize.height

            result.minimum -= sectionInset.top
            result.maximum -= sectionInset.top
        }

        return result
    }

    private func getCommonHeaderBottomMargin(_ indexPath: IndexPath) -> CGFloat {
        guard indexPath.section < layoutModel.count, let favoriteComponent =
            layoutModel[indexPath.section] as? CommonAndRecommendComponent else {
            return .zero
        }
        return favoriteComponent.subModuleList.count > 1 ?
            CGFloat(favoriteMultiModuleHeaderBottomMargin)
            : CGFloat(favoriteSingleModuleHeaderBottomMargin)
    }
}

/// collectionView的groupback视图代理
protocol CollectionViewGroupBackgroundDelegate: NSObjectProtocol {
    /// 获取指定section的background的dataModel
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: WPTemplateLayout,
        decorationDisplayedForSectionAt section: Int
    ) -> GroupBackgroundComponent?
}
