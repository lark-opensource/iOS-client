//
//  VcDocType.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/17.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_VcDocs.DocType
public enum VcDocType: Int, Hashable {
    case unknown // = 0
    case doc // = 1
    case sheet // = 2
    case bitable // = 3
    case mindnote // = 4
    case file // = 5
    case slide // = 6
    case folder // = 7
    case dustbin // = 8
    case personalFolder // = 9
    case sharewithmeFolder // = 10
    case shareFolder // = 11
    case link // = 12
    case demonstration // = 13
    case wiki // = 14
    case docx // = 15
}

/// Videoconference_V1_VcDocs.DocSubType
public enum VcDocSubType: Int, Hashable {
    case unknown // = 0
    case photo // = 1
    case pdf // = 2
    case txt // = 3
    case word // = 4
    case excel // = 5
    case ppt // = 6
    case video // = 7
    case audio // = 8
    case zip // = 9
    case psd // = 10
    case apk // = 11
    case sketch // = 12
    case ae // = 13
    case keynote // = 14
}

extension VcDocType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .doc:
            return "doc"
        case .sheet:
            return "sheet"
        case .bitable:
            return "bitable"
        case .mindnote:
            return "mindnote"
        case .file:
            return "file"
        case .slide:
            return "slide"
        case .folder:
            return "folder"
        case .dustbin:
            return "dustbin"
        case .personalFolder:
            return "personalFolder"
        case .sharewithmeFolder:
            return "sharewithmeFolder"
        case .shareFolder:
            return "shareFolder"
        case .link:
            return "link"
        case .demonstration:
            return "demonstration"
        case .wiki:
            return "wiki"
        case .docx:
            return "docx"
        }
    }
}

extension VcDocSubType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "docx"
        case .photo:
            return "docx"
        case .pdf:
            return "docx"
        case .txt:
            return "docx"
        case .word:
            return "docx"
        case .excel:
            return "docx"
        case .ppt:
            return "docx"
        case .video:
            return "docx"
        case .audio:
            return "docx"
        case .zip:
            return "docx"
        case .psd:
            return "docx"
        case .apk:
            return "docx"
        case .sketch:
            return "docx"
        case .ae:
            return "docx"
        case .keynote:
            return "docx"
        }
    }
}
