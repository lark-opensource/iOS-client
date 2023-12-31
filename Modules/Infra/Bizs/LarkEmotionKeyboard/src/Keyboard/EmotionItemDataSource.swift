//
//  EmotionItemDataSource.swift
//  LarkUIKit
//
//  Created by 李晨 on 2019/8/13.
//

import UIKit
import Foundation

public protocol EmotionItemDataSourceItem: AnyObject {}

/// EmotionHighlightCollectionCell
public protocol EmotionHighlightCollectionCell {
    /// show the hightlight background needed
    func showHighlightedBackgroundView ()

    /// hide the hightlight background needed
    func hideHighlightedBackgroundView ()
}

public protocol EmotionItemDataSourceSet: EmotionItemDataSourceItem {
    /// ID
    var identifier: String { get }

    /// 初始化 keyboard 可以用来刷新
    func setupEmotion(keyboard: EmotionKeyboardView)

    func sourceItems() -> [EmotionItemDataSource]
}

public protocol EmotionItemDataSource: EmotionItemDataSourceItem {
    /// ID
    var identifier: String { get }

    /// 触发时机：
    /// 1、用户在EmotionKeyboard中从其他DataSource切到当前DataSource；
    /// 2、用户在KeyboardPanel中从其他Keyboard切到EmotionKeyboard，默认会把当前所在的DataSource调用一次didSelect。
    func didSelect()

    /// 触发时机：用户在 EmotionKeyboard 中从其他 DataSource 切到当前 DataSource；
    func didSwitch()

    /// 每行显示几个表情：例如最近使用的表情
    func numberOfOneRow() -> Int

    /// 每个表情的默认size
    func emotionItemDefaultSize() -> CGSize

    /// 每个表情的具体size：具体到某行某列，引入LarkValue后表情就不是等宽的了
    func emotionItemSize(indexPath: IndexPath) -> CGSize

    /// 每个secion对应的contentInset
    func collectionView(collectionView: UICollectionView,
                        insetForSectionAt section: Int,
                        bottomBarHeight: CGFloat) -> UIEdgeInsets

    /// 表情的 insets
    func emotionInsets() -> UIEdgeInsets

    /// 是否需要添加空占位图，目前section不一定只有1个，所以需要上层自己判断
    func needAddEmptyView() -> Bool

    /// 表情的行间距
    func emotionLineSpacing() -> CGFloat

    /// 表情的列间距
    func emotionMinimumInteritemSpacing(section: Int) -> CGFloat

    /// section头部视图大小，初始化后不会改变
    func headerReferenceSize() -> CGSize

    /// section头部视图
    func collectionView(collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView

    /// section数
    func numberOfSections() -> Int

    /// 表情个数
    func numberOfEmotions(section: Int) -> Int

    /// 点击表情
    func didSelectEmotion(indexPath: IndexPath)

    /// 表情 icon
    func setupSourceIconImage(_ callback: @escaping (UIImage) -> Void)

    /// 更新 action button
    func updateActionBtnIfNeeded()

    /// action view 宽度
    func emotionActionViewWidth() -> CGFloat

    /// action view
    func emotionActionView(excludeSendBtn: Bool) -> UIView?

    /// empty view
    func emotionEmptyView() -> UIView?

    /// 在indexPath上进行了长按操作
    func longPressedAt(indexPath: IndexPath, cell: UICollectionViewCell)

    /// 在长按结束
    func longPressedEnd(indexPath: IndexPath, cell: UICollectionViewCell)

    /// 配置返回 cell
    func collectionCell(collection: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell

    /// 初始化 collection， 用来注册 cell
    func setupCollectionView(containerView: EmotionKeyboardItemView, collection: UICollectionView)

    /// cell被高亮
    func didHighlightItemAt(indexPath: IndexPath, cell: UICollectionViewCell?)

    /// cell被取消高亮
    func didUnHighlightItemAt(indexPath: IndexPath, cell: UICollectionViewCell?)

    func onKeyboardStatusChange(isFold: Bool)
}
