//
//  MeetTabTraitCollectionManager.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2023/4/21.
//

import Foundation
import ByteViewCommon

/// 线上直接获取 TraitCollection 存在奔溃
/// https://t.wtturl.cn/AW9fXbF/
/// 统一管控
final class MeetTabTraitCollectionManager {

    static let shared = MeetTabTraitCollectionManager()

    @RwAtomic
    var isRegular: Bool = false
}
