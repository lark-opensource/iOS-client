//
//  DKMoreItemType.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/22.
//

import Foundation

enum DKMoreItemType {
    case space // 云盘预览
    case attach(items: [DKMoreItem]) // 附件预览
}
