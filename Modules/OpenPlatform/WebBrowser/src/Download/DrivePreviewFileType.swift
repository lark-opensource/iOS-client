//
//  DrivePreviewFileType.swift
//  WebBrowser
//
//  Created by Ding Xu on 2022/7/21.
//

import Foundation
import UniverseDesignIcon

enum DriveFileType: String {
    /// 未知文件
    case unknown
    /// Word
    case doc, docx, dot, dotx
    /// Excel
    case xls, xlsx, xlsm, csv
    /// PPT
    case ppt, pptx, pps, ppsx, pot, potx
    /// iWork
    case key, pages, numbers
    /// PDF
    case pdf
    /// Video
    case mp4, m4v, mp4v, mpg4, mov, flv, ts
    case is3gp = "3gp"
    /// Audio
    case mp3, wav, m4a, aac, au, amr, flac, ogg
    /// Image
    case jpeg, jpg, png, bmp, tif, tiff, heic, heif, gif, svg, webp
    /// 文本
    case log, txt, rtf
    /// 代码文件
    case c, h, m, cpp, swift, htm, html, css, js, json, java, py, php, xml, md, rb, go, cs, kt, sql
    /// 压缩文件
    case zip, rar, tar
    case tarGz = "tar.gz"
    case tarBz2 = "tar.bz2"
    /// 危险文件, 预留
    
    var isWord: Bool {
        switch self {
        case .doc, .docx, .dot, .dotx: return true
        default: return false
        }
    }
    
    var isExcel: Bool {
        switch self {
        case .xls, .xlsx, .xlsm, .csv: return true
        default: return false
        }
    }
    
    var isPPT: Bool {
        switch self {
        case .ppt, .pptx, .pps, .ppsx, .pot, .potx: return true
        default: return false
        }
    }
    
    var isiWork: Bool {
        switch self {
        case .key, .pages, .numbers: return true
        default: return false
        }
    }
    
    var isVideo: Bool {
        switch self {
        case .mp4, .m4v, .mp4v, .mpg4, .mov, .flv, .ts, .is3gp: return true
        default: return false
        }
    }
    
    var isAudio: Bool {
        switch self {
        case .mp3, .wav, .m4a, .aac, .au, .amr, .flac, .ogg: return true
        default: return false
        }
    }
    
    var isMedia: Bool {
        return isVideo || isAudio
    }
    
    var isImage: Bool {
        switch self {
        case .jpeg, .jpg, .png, .bmp, .tif, .tiff, .heic, .heif, .gif, .svg, .webp: return true
        default: return false
        }
    }
    
    var isTxt: Bool {
        switch self {
        case .log, .txt, .rtf: return true
        case _ where self.isCode: return true
        default: return false
        }
    }
    
    var isCode: Bool {
        switch self {
        case .c, .h, .m, .cpp, .swift, .htm, .html, .css, .js, .json, .java, .py, .php, .xml, .md, .rb, .go, .cs, .kt, .sql: return true
        default: return false
        }
    }
    
    var isZip: Bool {
        switch self {
        case .zip, .rar, .tar: return true
        default: return false
        }
    }
    
    var isSupportLocalPreview: Bool {
        switch self {
        case .pdf, .csv, .log, .txt, .md, .rtf, .c, .h, .m, .cpp, .swift, .htm, .html, .css, .js, .json, .java, .py, .php, .xml, .md, .rb, .go, .cs, .kt, .sql, .doc, .docx, .dot, .dotx, .xls, .xlsx, .xlsm, .ppt, .pptx, .pps, .ppsx, .pot, .potx, .key, .pages, .numbers, .mp3, .wav, .m4a, .aac, .au, .flac, .mp4, .m4v, .mp4v, .mpg4, .mov, .jpeg, .jpg, .png, .bmp, .tif, .tiff, .heic, .heif, .gif, .svg, .webp, .zip, .rar, .tarGz, .tarBz2, .tar: return true
        default: return false
        }
    }
    
    var squareImage: UIImage? {
        switch self {
        case .pdf:
            return colorUDIconByKey(.filePdfColorful)
        case .csv:
            return colorUDIconByKey(.fileCsvColorful)
        case .numbers:
            return colorUDIconByKey(.fileNumbersColorful)
        case .pages:
            return colorUDIconByKey(.filePagesColorful)
        case .key:
            return colorUDIconByKey(.fileKeynoteColorful)
        case _ where self.isExcel:
            return colorUDIconByKey(.fileExcelColorful)
        case _ where self.isPPT:
            return colorUDIconByKey(.filePptColorful)
        case _ where self.isCode, .log, .md: // 要求 .log, .md 展示代码的图标
            return colorUDIconByKey(.fileCodeColorful)
        case _ where self.isTxt:
            return colorUDIconByKey(.fileTextColorful)
        case _ where self.isWord:
            return colorUDIconByKey(.fileWordColorful)
        case _ where self.isImage:
            return colorUDIconByKey(.fileImageColorful)
        case _ where self.isVideo:
            return colorUDIconByKey(.fileVideoColorful)
        case _ where self.isAudio:
            return colorUDIconByKey(.fileAudioColorful)
        case _ where self.isZip:
            return colorUDIconByKey(.fileZipColorful)
        default:
            return colorUDIconByKey(.fileUnknowColorful)
        }
    }
    
    private func colorUDIconByKey(_ key: UniverseDesignIcon.UDIconType) -> UIImage {
        return UDIcon.getIconByKey(key, size: CGSize(width: 90, height: 90))
    }
    
    init(fileExtension: String?) {
        guard let fileExtension = fileExtension?.lowercased(),
              let type = DriveFileType(rawValue: fileExtension) else {
            self = .unknown
            return
        }
        self = type
    }
}
