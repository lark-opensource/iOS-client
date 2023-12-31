//
//  Layout+CommonAndRecommend.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/4/13.
//

import Foundation
import UIKit

/// 常用、推荐应用 - 布局解析
extension WPTemplateLayout {

    // MARK: private functions

    /// 获取 我的常用 组件的 size
    /// - Parameter layoutParam: 下发 layout 参数
    /// - Returns: size
    private func getContentSize(layoutParam: BaseComponentLayout) -> CGSize {
        if let height = NumberFormatter().number(from: layoutParam.height) {
            return CGSize(
                width: collectionViewWidth - CGFloat(layoutParam.marginLeft) - CGFloat(layoutParam.marginRight),
                height: CGFloat(truncating: height)
            )
        } else {
            return CGSize(
                width: collectionViewWidth - CGFloat(layoutParam.marginLeft) - CGFloat(layoutParam.marginRight),
                height: listLayoutStateTipHeight
            )
        }
    }

    /// 设置 header
    /// - Parameters:
    ///   - section: section
    ///   - height: 标题栏高度
    private func setupHeader(section: Int, height: Int) {
        commonAndRecommendHeaderHeight = CGFloat(height)
        setupHeaderViewAttr(
            section: section,
            row: 0,
            width: collectionViewWidth,
            height: CGFloat(height),
            left: 0,
            needPressInset: false
        )
    }

    /// 设置内容
    /// - Parameters:
    ///   - model: model
    ///   - maxColumn: 最大列数
    ///   - contentSize: 内容尺寸
    ///   - contentMargin: 内容外边距
    ///   - section: section
    ///   - row: row
    /// - Returns: row
    // swiftlint:disable function_parameter_count
    private func setupContent(
        model: GroupComponent,
        maxColumn: Int,
        contentSize: CGSize,
        contentMargin: UIEdgeInsets,
        section: Int,
        row: Int
    ) -> Int {
        // swiftlint:enable function_parameter_count
        var row = row
        let nodeComponents = model.nodeComponents
        // 内容区域 ❓数据请求回来需要解析成 AppCell 和 Block 两种 按顺序排布的结构
        switch model.componentState {
        case .running:
            // 首先，计算出图标网格的布局
            // swiftlint:disable line_length
            let gridWidth = (contentSize.width - commonAppHorizontalPadding * CGFloat(maxColumn - 1)) / CGFloat(maxColumn)
            let gridHeight = appListItemInnerVGap + WPUIConst.AvatarSize.large + appListItemInnerVGap + doubleLineTextHeight + appListItemInnerVGap
            // swiftlint:enable line_length

            // 准备开始布局
            let iconStartRowOffset: CGFloat = contentMargin.left
            var iconAppRowCount: Int = 0   // Icon应用布局列计数器(换行重置，遇到block重置）
            var beforeType: NodeComponentType = .CommonIconApp
            for i in 0..<nodeComponents.count {
                let item = nodeComponents[i]
                switch item.type {
                case .CommonTips:
                    beforeType = .CommonTips
                    let indexPath = IndexPath(row: row, section: section)
                    let attr: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(
                        forCellWith: indexPath
                    )
                    var groupIsManageable = false
                    if let group = model as? CommonAndRecommendComponent, group.isGroupManageable() {
                        groupIsManageable = true
                    }
                    let manageFavDesc = enableRecentlyUsedApp ?
                    BundleI18n.LarkWorkplace.OpenPlatform_QuickAccessBlc_RearrangeFeatureDesc :
                    BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_ManageFavDesc
                    let noFavPrompt = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_NoFavPrompt
                    let text = groupIsManageable ? manageFavDesc : noFavPrompt
                    var height = (text as NSString).boundingRect(
                        with: CGSize(width: contentSize.width, height: CGFloat(MAXFLOAT)),
                        options: .usesLineFragmentOrigin,
                        // swiftlint:disable init_font_with_token
                        attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)],
                        // swiftlint:enable init_font_with_token
                        context: nil
                    ).height
                    let lineHeight = Int(ceil(height / CGFloat(favoriteTipsHeight)))
                    // swiftlint:disable line_length
                    height = CGFloat(favoriteTipsTopPadding + lineHeight * favoriteTipsHeight + favoriteTipsBottomPadding)
                    // swiftlint:enable line_length
                    attr.frame = CGRect(
                        x: contentMargin.left,
                        y: contentHeight,
                        width: contentSize.width,
                        height: height
                    )
                    cellAttrbutesData[indexPath] = attr
                    row += 1
                    addupContentHeight(with: height)
                case .CommonIconApp:
                    //  |    <-    collectionView.width    ->      |
                    //  |  |      <-    contentWidth    ->      |  |
                    //  |------------------------------------------|
                    //  |   ------    ------    ------    ------   |
                    //  |  | icon |  | icon |  | icon |  | icon |  |
                    //  |  |      |  |      |  |      |  |      |  |
                    //  |   ------    ------    ------    ------   |
                    //  |------------------------------------------|
                    //  |  |      |  |      |  |      |  |      |  |
                    //   ^         ^          ^         ^        ^
                    // marginLeft   gap       gap       gap    marginRight
                    // 设置应用之间的间距
                    if beforeType == .Block {
                        addupContentHeight(with: blockToIconInset)
                    }
                    let iconColumn = iconAppRowCount % maxColumn   // 计算App的网格列坐标
                    // swiftlint:disable line_length
                    let iconCurrentRowOffset = iconStartRowOffset + CGFloat(iconColumn) * gridWidth + CGFloat(iconColumn) * commonAppHorizontalPadding
                    // swiftlint:enable line_length
                    let indexPath = IndexPath(row: row, section: section)
                    let atrr: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(
                        forCellWith: indexPath
                    )
                    // swiftlint:disable implicitly_unwrapped_optional
                    var cellFrame: CGRect!
                    // swiftlint:enable implicitly_unwrapped_optional
                    if let iconComponent = item as? CommonIconComponent, iconComponent.itemModel?.itemType == .addRect {
                        // 方形「添加应用」
                        cellFrame = CGRect(
                            x: contentMargin.left,
                            y: contentHeight,
                            width: contentSize.width,
                            height: contentSize.width * ItemModel.addRectAspectRatio
                        )
                    } else {
                        cellFrame = CGRect(
                            x: iconCurrentRowOffset,
                            y: contentHeight,
                            width: gridWidth,
                            height: gridHeight
                        )
                    }
                    atrr.frame = cellFrame
                    cellAttrbutesData[indexPath] = atrr
                    row += 1

                    iconAppRowCount += 1
                    if iconAppRowCount % maxColumn == 0
                        || i == (nodeComponents.count - 1)  // 最后一个cell
                        || (i < nodeComponents.count - 1 && nodeComponents[i + 1].type == .Block) {  // 换行布局
                        contentHeight = cellFrame.maxY
                        iconAppRowCount = 0
                    }
                    beforeType = .CommonIconApp
                case .Block:
                    if i > 0 {
                        /// 设置应用之间的间距
                        if beforeType == .Block {
                            addupContentHeight(with: blockToBlockInset)
                        } else {
                            addupContentHeight(with: blockToIconInset)
                        }
                    }

                    var blockHeight = blockDefaultHeight
                    if let heightStr = item.layoutParams?.height, let height = Int(heightStr) {
                        blockHeight = CGFloat(height)
                    }
                    let widgetWidth: CGFloat = contentSize.width
                    let widgetHorizontalOffset = contentMargin.left

                    let indexPath = IndexPath(row: row, section: section)
                    let atrr: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(
                        forCellWith: indexPath
                    )
                    let cellFrame = CGRect(
                        x: widgetHorizontalOffset,
                        y: contentHeight,
                        width: widgetWidth,
                        height: blockHeight
                    )
                    atrr.frame = cellFrame
                    cellAttrbutesData[indexPath] = atrr
                    row += 1
                    contentHeight = cellFrame.maxY
                    iconAppRowCount = 0
                    beforeType = .Block
                default:
                    continue
                }
            }
        default:
            // 状态组件示意组件
            let stateViewHeight = model.componentState == .noApp ? 112 : contentSize.height
            let indexPath = IndexPath(row: row, section: section)
            let cellFrame = CGRect(
                x: contentMargin.left,
                y: contentHeight,
                width: contentSize.width,
                height: stateViewHeight
            )
            let atrr: UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            atrr.frame = cellFrame
            cellAttrbutesData[indexPath] = atrr
            row += 1
            contentHeight = cellFrame.maxY
        }
        return row
    }

    /// 设置背景
    /// - Parameters:
    ///   - section: section
    ///   - row: row
    ///   - contentSize: contentSize
    ///   - contentMargin: contentMargin
    private func setupBackground(
        section: Int,
        row: Int,
        contentSize: CGSize,
        contentMargin: UIEdgeInsets,
        backgroundTop: CGFloat
    ) {
        let backgroundHeight = contentHeight - backgroundTop    // 背景bottom对齐内容区底部
        setupBackgroundViewAttr(
            section: section,
            row: row,
            width: contentSize.width,
            height: backgroundHeight,
            leftPos: contentMargin.left
        )
    }

    /// 记录已计算高度
    /// - Parameter height: 变化高度
    private func addupContentHeight(with height: CGFloat) {
        Self.logger.info("increase caculated height", additionalData: [
            "height": "\(height)",
            "currentHeight": "\(contentHeight)"
        ])
        contentHeight += height
    }

    // MARK: internal functions

    /// 设置 我的常用 layout
    /// - Parameters:
    ///   - section: section
    ///   - model: 数据模型
    func setupCommonAndRecommend(section: Int, model: GroupComponent) {
        // ⚠️需要确保基本要素得有，否则走「异常逻辑?」
        // 组件布局参数
        guard let layoutParam = model.layoutParams else { return }
        // 标题栏布局参数
        var headerMargin = calculateHeaderMargin(model: model, componentLayout: layoutParam)
        // 组件外边距
        let contentMargin = UIEdgeInsets(
            top: CGFloat(headerMargin.top),
            left: CGFloat(layoutParam.marginLeft),
            bottom: CGFloat(layoutParam.marginBottom),
            right: CGFloat(layoutParam.marginRight)
        )
        // 组件大小（其中高度为占位，实际高度由内容决定）
        let contentSize: CGSize = getContentSize(layoutParam: layoutParam)
        // 📝 布局记录 - 计入 topMargin
        addupContentHeight(with: contentMargin.top)

        // 背景top默认为组件top
        var backgroundTop: CGFloat = contentHeight

        // 组件内cell计数器
        var row: Int = 0
        // 最大列数
        let maxColumn = Int(ceil(contentSize.width / (commonAppContainerWidth + commonAppHorizontalPadding)))
        guard maxColumn > 0 else {
            Self.logger.error("layout maxColumn error, layout failed")
            assertionFailure("layout maxColumn error, layout failed")
            return
        }

        // 布局附加视图（标题组件）
        var frontSupplementRow: Int = 0

        // 设置 header
        setupHeader(section: section, height: favoriteModuleHeaderHeight)
        frontSupplementRow += 1

        addupContentHeight(with: CGFloat(headerMargin.bottom))

        // 设置 content
        row = setupContent(
            model: model,
            maxColumn: maxColumn,
            contentSize: contentSize,
            contentMargin: contentMargin,
            section: section,
            row: row
        )

        // 设置背景区域
        if (model.extraComponents[.GroupBackground]) != nil {
            // 背景组件
            setupBackground(
                section: section,
                row: row + frontSupplementRow,
                contentSize: contentSize,
                contentMargin: contentMargin,
                backgroundTop: backgroundTop
            )
        }
        // 📝 布局记录 - 应用列表的 BottomMargin
        addupContentHeight(with: contentMargin.bottom)
    }

    private func calculateHeaderMargin(
        model: GroupComponent,
        componentLayout: BaseComponentLayout
    ) -> (top: Int, bottom: Int) {
        var titleTopMargin = favoriteSingleModuleHeaderTopMargin
        var titleBottomMargin = favoriteSingleModuleHeaderBottomMargin
        if let titleComponent = model.extraComponents[.GroupTitle] as? GroupTitleComponent,
            titleComponent.subTitle.count > 1 {
            titleTopMargin = favoriteMultiModuleHeaderTopMargin
            titleBottomMargin = favoriteMultiModuleHeaderBottomMargin
        }
        titleTopMargin += max(componentLayout.marginTop - favoriteModuleHeaderTopGap, 0)
        return (top: titleTopMargin, bottom: titleBottomMargin)
    }
}
