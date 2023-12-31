//
//  BitableInfo.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2022/10/26.
//

import Foundation
import RustPB

/// 多维表格
/// Videoconference_V1_BitableInfo
public struct BitableInfo: Equatable {

    public var url: String

    public var title: String

    public var owner: ByteviewUser

}
