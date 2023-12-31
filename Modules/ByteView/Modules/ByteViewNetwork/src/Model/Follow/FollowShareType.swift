//
//  FollowShareType.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

public enum FollowShareType: Int, Hashable {
    case unknown // = 0
    case ccm // = 1
    case google // = 2
    case universal // = 3
}

public enum FollowShareSubType: Int, Hashable {
    case unknown // = 0
    case ccmDoc // = 1
    case ccmSheet // = 2
    case ccmMindnote // = 3
    case ccmWord // = 4
    case ccmExcel // = 5
    case ccmPpt // = 6
    case ccmPdf // = 7

    /// 多维表格
    case ccmBitable // = 8

    /// 演示文稿
    case ccmDemonstration // = 9
    case ccmWikiDoc // = 10
    case ccmWikiSheet // = 11
    case ccmWikiMindnote // = 12
    case ccmWikiDocX // = 13
    case ccmDocx = 22
    case googleDoc = 51
    case googleSheet // = 52
    case googleSlide // = 53
    case googleWord // = 54
    case googleExcel // = 55
    case googlePpt // = 56
    case googlePdf // = 57
}

extension FollowShareType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .ccm:
            return "ccm"
        case .google:
            return "google"
        case .universal:
            return "universal"
        }
    }
}

extension FollowShareSubType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .ccmDoc:
            return "ccmDoc"
        case .ccmSheet:
            return "ccmSheet"
        case .ccmMindnote:
            return "ccmMindnote"
        case .ccmWord:
            return "ccmWord"
        case .ccmExcel:
            return "ccmExcel"
        case .ccmPpt:
            return "ccmPpt"
        case .ccmPdf:
            return "ccmPdf"
        case .ccmBitable:
            return "ccmBitable"
        case .ccmDemonstration:
            return "ccmDemonstration"
        case .ccmWikiDoc:
            return "ccmWikiDoc"
        case .ccmWikiSheet:
            return "ccmWikiSheet"
        case .ccmWikiMindnote:
            return "ccmWikiMindnote"
        case .ccmWikiDocX:
            return "ccmWikiDocX"
        case .ccmDocx:
            return "ccmDocx"
        case .googleDoc:
            return "googleDoc"
        case .googleSheet:
            return "googleSheet"
        case .googleSlide:
            return "googleSlide"
        case .googleWord:
            return "googleWord"
        case .googleExcel:
            return "googleExcel"
        case .googlePpt:
            return "googlePpt"
        case .googlePdf:
            return "googlePdf"
        }
    }
}
