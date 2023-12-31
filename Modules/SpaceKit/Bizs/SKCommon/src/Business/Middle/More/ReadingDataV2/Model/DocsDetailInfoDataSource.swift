//
//  DocsDetailInfoDataSource.swift
//  SKCommon
//
//  Created by huayufan on 2021/10/19.
//  


import UIKit

public struct DocsDetailInfoBaseInfo {
    
    public typealias RowText = (title: String, value: String)
    
    public var title: String
    public var rowTexts: [RowText]
    
    public init(title: String, rowTexts: [RowText]) {
        self.title = title
        self.rowTexts = rowTexts
    }
}

public enum DocDetainInfoSectionType {
    case createInfo(DocsDetailInfoBaseInfo)
    case fileInfo(DocsDetailInfoBaseInfo) // drive文件的基本信息
    case wordInfo(DocsDetailInfoBaseInfo)
    case readInfo(blocks: [DocsDetailInfoCountModel])
    case readRecordInfo(icon: UIImage)
    case privacySetting(icon: UIImage)
    // 文档操作记录
    case documentActivity(icon: UIImage)

    // nolint: magic number
    var height: CGFloat {
        switch self {
        case .createInfo:
            return 112
        case .wordInfo(let info):
            switch info.rowTexts.count {
            case 1: return 84
            case 2: return 113
            default: return 0
            }
        case .fileInfo:
            return 113
        case .readInfo(let blocks):
            let res = blocks.filter { $0.newsCountText != nil }
            return res.isEmpty ? 150 : 161
        case .readRecordInfo:
            return 51
        case .privacySetting:
            return 51
        case .documentActivity:
            return 51
        }
    }
    // enable-lint
}
