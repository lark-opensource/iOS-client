//
//  DriveFileType.swift
//  DocsSDK
//
//  Created by Duan Ao on 2019/1/15.
//

import UIKit
import Foundation
import UniverseDesignIcon

/// 文件类型
enum CommonFileType: String {

    /// PDF
    case pdf
    /// 文本
    case txt, rtf
    /// Word
    case doc, docx, dot, dotx, wps
    /// Excel
    case xls, xlsx, xlsm, csv, et
    /// PPT
    case ppt, pptx, pps, ppsx, pot, potx
    /// keynote
    case keynote, pages, numbers, key
    /// Image
    case jpeg, jpg, png, bmp, tif, tiff, svg, raw, gif, heic
    /// Video
    case mp4, mov, wmv, m4v, avi, mpg, mpeg, rm, rmvb, flv, mkv, ogv, ogg
    /// Audio
    case mp3, wav, m4a, wma, amr, aac, au, flac
    /// 压缩文件
    case zip, rar, tar, apk
    case is7z = "7z"
    /// 设计文件
    case psd, ai, aep, sketch
    /// 代码文件
    case c, h, m, cpp, swift, html, css, js, java, py, php, json, xml, md
    /// 未知文件
    case unknown

    init(fileExtension: String?) {
        guard let fileExtension = fileExtension?.lowercased(),
            let type = CommonFileType(rawValue: fileExtension) else {
                self = .unknown
                return
        }
        self = type
    }

}

extension CommonFileType {

    var canShowWaterMark: Bool {

        switch self {
        case .pdf, .numbers, . pages: return false
        case _ where self.isPPT || self.isWord || self.isExcel || self.isKeynote: return false
        default: return true
        }
    }

    var isVideo: Bool {
        switch self {
        case .mp4, .mov, .wmv, .m4v, .avi,
             .mpg, .mpeg, .rm, .rmvb, .flv,
             .mkv, .ogv, .ogg: return true
        default: return false
        }
    }

    var isAudio: Bool {
        switch self {
        case .mp3, .wav, .m4a, .wma, .amr,
             .aac, .au, .flac: return true
        default: return false
        }
    }

    var isMedia: Bool {
        return isVideo || isAudio
    }

    var isImage: Bool {
        switch self {
        case .jpeg, .jpg, .png, .bmp, .tif, .tiff,
             .svg, .raw, .gif, .heic: return true
        default: return false
        }
    }

    var isTxt: Bool {
        switch self {
        case .txt, .rtf: return true
        case _ where self.isCode: return true
        default: return false
        }
    }

    var isWord: Bool {
        switch self {
        case .doc, .docx, .dot, .dotx, .wps: return true
        default: return false
        }
    }

    var isExcel: Bool {
        switch self {
        case .xls, .xlsx, .xlsm, .csv, .et: return true
        default: return false
        }
    }

    var isPPT: Bool {
        switch self {
        case .ppt, .pptx, .pps, .ppsx, .pot, .potx: return true
        default: return false
        }
    }

    var isKeynote: Bool {
        switch self {
        case .keynote, .key: return true
        default: return false
        }
    }

    var isZip: Bool {
        switch self {
        case .zip, .rar, .is7z, .tar: return true
        default: return false
        }
    }

    var isCode: Bool {
        switch self {
        case .c, .h, .m, .cpp, .swift, .html, .css, .js, .java, .py, .php, .json, .xml, .md: return true
        default: return false
        }
    }

    // 原生支持打开（i.e. Quick Look(普通PDF/ Office/ )/ 代码/ 后台不支持转码的音视频/ ）
    var isSupport: Bool {
        switch self {
        case .pdf, // 使用PDF Steaming的话，需要从后台下载线性化的文件
        .txt, .rtf,
        .doc, .docx, .dot, .dotx,
        .xlsx, .xlsm, .csv,         // 撤销xls的支持，部分xls无法正常打开
        .ppt, .pptx, .pps, .ppsx, .pot, .potx,
        .keynote, .pages, .numbers, .key,
        .jpeg, .jpg, .png, .bmp, .tif, .tiff, .svg, .gif, .heic,        // missing:  .raw
        .mp4, .mov, .wmv, .m4v, .avi, .mpg, .mpeg, .rm, .rmvb, .flv, .mkv, .ogg,  // missing: ogv
        .mp3, .wav, .m4a, .wma, .amr, .aac, .au, .flac,
        .c, .h, .m, .cpp, .swift, .html, .css, .js, .java, .py, .php, .json, .xml, .md: return true
        // missing: zip, rar, tar, apk, 7z, psd, ai, aep, sketch
        default: return false
        }
    }

    // 优先使用本地能力来预览
    var preferLocalPreview: Bool {
        switch self {
        case _ where self.isPPT || self.isWord || self.isExcel || self.isKeynote || self.isCode || self.isTxt:
            return true
        default: return false
        }
    }

    var isSupportMultiPics: Bool {
        return self.isImage && self != .svg && self != .gif
    }

    private var imageType: UDIconType {
        switch self {
        case .pdf:
            return .filePdfColorful
        case .aep:
            return .fileAeColorful
        case .ai:
            return .fileAiColorful
        case .apk:
            return .fileAndroidColorful
        case .psd:
            return .filePsColorful
        case .sketch:
            return .fileSketchColorful
        case _ where self.isExcel:
            return .fileExcelColorful
        case _ where self.isKeynote:
            return .fileKeynoteColorful
        case _ where self.isPPT:
            return .filePptColorful
        case _ where self.isTxt:
            return .fileTextColorful
        case _ where self.isWord:
            return .fileWordColorful
        case _ where self.isZip:
            return .fileZipColorful
        case _ where self.isImage:
            return .fileImageColorful
        case _ where self.isVideo:
            return .fileVideoColorful
        case _ where self.isAudio:
            return .fileAudioColorful
        default:
            return .fileUnknowColorful
        }
    }

    /// Loading 上使用的 icon
    var iconImage: UIImage? {
        return UDIcon.getIconByKey(imageType, size: CGSize(width: 36, height: 36)).withRenderingMode(.alwaysOriginal)
    }
}
