//
//  FileFormatCompatibility.swift
//  LarkFile
//
//  Created by SuPeng on 12/9/18.
//

import Foundation
import LarkFoundation

extension FileFormat {
    var isCompatible: Bool {
        switch self {
        case .unknown, .image(.svg):
            return false
        case .txt, .md, .html, .json, .pdf, .rtf, .image:
            return true
        case .video(let videoFormat):
            switch videoFormat {
            case .avi, .wmv, .mpg, .flv:
                return false
            case .mpeg4, .mov:
                return true
            @unknown default:
                assert(false, "new value")
                return false
            }
        case .audio, .office, .appleOffice:
            return true
        @unknown default:
            assert(false, "new value")
            return false
        }
    }
}
