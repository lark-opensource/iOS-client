//
//  BlockFirstBootRecordTool.swift
//  Blockit
//
//  Created by xiangyuanyuan on 2022/7/12.
//

import Foundation
import LarkStorage
import LarkSetting
import OPBlockInterface

public final class BlockFirstBootRecordTool {
    public enum BlockBootRecordState: Int {
        case unknown = 0     // blockID获取不到 未知状态
        case firstBoot = 1   // 首次启动
        case bootBefore = 2  // 之前启动过
    }

    private static let FirstBootRecord = "BlockFirstBootRecord"

    /// 记录block启动
    public static func recordBlockBoot(blockID: String?, userId: String) {
        guard let blockID = blockID, !blockID.isEmpty else { return }
        let store = KVStores
            .in(space: .user(id: userId))
            .in(domain: Domain.biz.block.child(blockID))
            .mmkv()
        store.set(true, forKey: BlockCacheKey.Block.firstBootRecord)
    }

    /// 返回是否启动过
    public static func bootBefore(blockID: String?, userId: String) -> BlockBootRecordState {
        guard let blockID = blockID, !blockID.isEmpty else { return .unknown }
        let store = KVStores
            .in(space: .user(id: userId))
            .in(domain: Domain.biz.block.child(blockID))
            .mmkv()
        let firstBootRecord: Bool = store.value(forKey: BlockCacheKey.Block.firstBootRecord) ?? false
        return firstBootRecord ? .bootBefore : .firstBoot
    }
}
