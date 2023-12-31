//
//  ChatWidgetCellViewModel.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/1/11.
//

import UIKit
import Foundation
import LarkOpenChat

/// 卡片 CellVM
/// - Cell 的复用更新
/// - 组装卡片的 render + VM
final class ChatWidgetCellViewModel {
    let render: ChatWidgetCellRenderImp
    let context: ChatWidgetContext
    let widgetVM: BaseChatWidgetViewModel
    var metaModel: ChatWidgetCellMetaModel

    public init(
        metaModel: ChatWidgetCellMetaModel,
        context: ChatWidgetContext,
        contentVM: ChatWidgetContentViewModel
    ) {
        self.metaModel = metaModel
        self.context = context
        self.widgetVM = contentVM
        self.render = ChatWidgetCellRenderImp(renderAbility: contentVM)
        self.widgetVM.initRenderer(self.render)
        self.render.layout(self.context.containerSize)
    }

    /// 数据更新 && 计算 size
    func update(_ metaModel: ChatWidgetCellMetaModel) {
        self.metaModel = metaModel
        self.widgetVM.update(metaModel: metaModel)
        self.render.layout(self.context.containerSize)
    }

    var identifier: String {
        return self.widgetVM.identifier
    }

    func willDisplay() {
        self.widgetVM.willDisplay()
    }

    func didEndDisplay() {
        self.widgetVM.didEndDisplay()
    }

    func onResize() {
        self.widgetVM.onResize()
        self.render.layout(self.context.containerSize)
    }

    /// Cell 重用更新
    func dequeueReusableCardCell(_ tableView: UITableView,
                                 cellId: Int64,
                                 longPressHandler: @escaping () -> Void) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.identifier) as? ChatWidgetCardTableViewCell ??
        ChatWidgetCardTableViewCell(style: .default, reuseIdentifier: self.identifier)
        cell.cellId = cellId
        cell.longPressHandler = longPressHandler
        self.render.bind(to: cell.containerView)
        UIView.setAnimationsEnabled(false)
        self.render.renderView()
        UIView.setAnimationsEnabled(true)
        return cell
    }

    func dequeueReusableSortAndDeleteCell(_ collectionView: UICollectionView,
                                          indexPath: IndexPath,
                                          hideMask: Bool,
                                          deleteHandler: @escaping () -> Void) -> UICollectionViewCell {
        let identifier = self.identifier
        collectionView.register(ChatWidgetSortAndDeleteCollectionCell.self, forCellWithReuseIdentifier: identifier)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        if let cell = cell as? ChatWidgetSortAndDeleteCollectionCell {
            cell.set(hideMask: hideMask, deleteHandler: deleteHandler)
            self.render.bind(to: cell.containerView)
            UIView.setAnimationsEnabled(false)
            self.render.renderView()
            UIView.setAnimationsEnabled(true)
        }
        return cell
    }
}
