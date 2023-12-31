//
//  Layout+Block.swift
//  templateDemo
//
//  Created by  bytedance on 2021/3/29.
//

import UIKit
import LarkStorage
import LarkSetting

/// Block布局
extension WPTemplateLayout {
    /// 实现Block布局
    func setupBlockLayout(section: Int, model: GroupComponent) {
        if let wrapper = model as? BlockLayoutComponent,
           let layout = wrapper.layoutParams {

            let blockLeftMargin = CGFloat(layout.marginLeft)
            let blockTopMargin = (section == 0) ? 0 : CGFloat(layout.marginTop)
            let blockBottomMargin = CGFloat(layout.marginBottom)
            let blockRightMargin = CGFloat(layout.marginRight)

            let blockWidth = collectionViewWidth - blockLeftMargin - blockRightMargin

            let blockHeight: CGFloat
            if let component = wrapper.nodeComponents.first as? BlockComponent,
               let block = component.blockModel,
               block.isAutoSizeBlock {
                if let cacheH = getBlockHeightFromCache(block: block) {
                    blockHeight = cacheH
                } else {
                    blockHeight = cardDefaultHeight
                }
                Self.logger.info("[BLKH] auto block use height: \(blockHeight)")
            } else if let height = Int(layout.height) {
                // 编辑器配置高度端上不做限制，编辑器去限制
                blockHeight = CGFloat(height)
                Self.logger.info("[BLKH] use editor block height: \(blockHeight)")
            } else {
                blockHeight = cardDefaultHeight
                Self.logger.info("[BLKH] use default block height: \(blockHeight)")
            }

            contentHeight += blockTopMargin

            // Content 布局计算
            let indexPath = IndexPath(row: 0, section: section)
            let atrr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            let frame = CGRect(
                x: blockLeftMargin,
                y: contentHeight,
                width: blockWidth,
                height: blockHeight
            )
            atrr.frame = frame
            cellAttrbutesData[indexPath] = atrr
            contentHeight += frame.height
            contentHeight += blockBottomMargin
        }
    }

    private func getBlockHeightFromCache(block: BlockModel) -> CGFloat? {
        let store = KVStores.in(space: .user(id: userId), domain: Domain.biz.workplace).mmkv()
        let model: CGFloat? = store.value(forKey: WPCacheKey.blockHeightLynx(blockId: block.blockId))
        Self.logger.info("[\(WPCacheKey.blockHeightLynx(blockId: block.blockId))] cache \(model == nil ? "miss" : "hit").")
        return model
    }
}
