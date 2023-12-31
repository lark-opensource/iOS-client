//
//  BlockCacheKey.swift
//  OPBlockInterface
//
//  Created by Meng on 2023/3/20.
//

import Foundation
import LarkStorage

/// Block 缓存 key 定义
///
/// 规范:
/// 1. 接入 LarkStorage 后 Block 所有的缓存相关的 key 收敛到此处。
/// 2. Block 相关 KV 缓存均使用 MMKV。
/// 3. key 已经经过 LarkStorage space 和 domain 隔离，不需要再自己加前缀了，一般直接带有业务语义即可。
/// 4. 建议 key 的命名方式：小写字母 + 下划线 + 数字，数字不能在首位。
/// 5. 每个 key 必须明确通过注释说明其含义，并明确说明其 value 所对应的数据类型。
///
/// Space:
/// 1. 使用 LarkStorage 的 space 概念。
/// 2. 缓存 key 需要区分维度，目前默认需要有 user 维度，在此基础上使用对应的 domain。
/// 3. 全局 space 维度 key，定义在 `BlockCacheKey.Global`。
///
/// Domain:
/// 1. 使用 LarkStorage 的 domain 概念。
/// 2. Block 缓存的统一根 domain: `Domain.biz.block`。
/// 3. `BlockCacheKey` 内的 key，存储在 user space + `Domain.biz.block` domain。
/// 4. `BlockCacheKey.Block` 内的 key，存储在 user space + `Domain.biz.block.{blockId}` domain，表示 BlockId 维度数据。
/// 5. `BlockCacheKey.BlockType` 内的 key，存储在 user space + `Domain.biz.block.{blockTypeId}` domain，表示 BlockTypeId 维度的数据。
/// 6. `BlockCacheKey.BlockType.Host` 内的 key，存储在 user space + `Domain.biz.block.{blockTypeId}.{host}` domain，表示 BlockTypeId 维度某个宿主维度的数据。
///
public enum BlockCacheKey {

    /// 全局维度数据
    public enum Global {

    }

    /// BlockId 维度存储的数据
    public enum Block {
        /// Block 首次加载标记。
        ///
        /// - Value: `Bool`
        public static let firstBootRecord = "first_boot_record"

        /// Block Entity 缓存时间。
        ///
        /// - Value: `Int`(timestamp)
        public static let entityTimestamp = "entity_timestamp"

        /// Block Entity 缓存。
        ///
        /// - Value: `BlockInfo`
        public static let entityData = "entity_data"
    }

    /// BlockTypeId 维度存储的数据
    public enum BlockType {
        /// 宿主维度存储的数据
        public enum Host {
            /// Block GuideInfo 缓存时间。
            ///
            /// - Value: `Int`(timestamp)
            public static let guideInfoTimestamp = "guide_info_timestamp"

            /// Block GuideInfo 缓存。
            ///
            /// - Value: `Bool`
            public static let guideInfoData = "guide_info_data"
        }
    }
}
