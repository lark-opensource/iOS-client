//
//  DriveFileType.swift
//  DocsSDK
//
//  Created by Duan Ao on 2019/1/15.
//

import Foundation

/// 文件类型
let harmfulTypes = ["app", "bat", "chm",
                    "cmd", "com", "cpl",
                    "csh", "dll", "exe",
                    "hta", "jar", "js",
                    "jse", "ksh", "lnk",
                    "msc", "msh", "msh1",
                    "msh2", "mshxml", "msh1xml",
                    "msh2xml", "msi", "msp",
                    "mst", "msu", "pif",
                    "pl", "prg", "ps1",
                    "ps1xml", "ps2", "ps2xml",
                    "psc1", "psc2", "psd1",
                    "psdm1", "py", "pyc",
                    "pyo", "pyw", "pyz",
                    "pyzw", "scf", "scr",
                    "sct", "shb", "shs",
                    "vb", "vbe", "vbs",
                    "ws", "wsc", "wsf",
                    "wsh"]
enum DriveFileType: String {
    /// 未知文件
    case unknown
    /// PDF
    case pdf
    /// 文本
    case txt, rtf
    /// Excel
    case xls, xlsx, xlsm, csv
    /// Word
    case doc, docx, dot, dotx
    /// keynote
    case keynote, pages, numbers, key
    /// PPT
    case ppt, pptx, pps, ppsx, pot, potx
    /// Audio
    case mp3, wav, m4a, wma, amr, aac, au, flac
    /// Image
    case jpeg, jpg, png, bmp, tif, tiff, svg, raw, gif, heic
    /// Video
    case mp4, mov, wmv, m4v, avi, mpg, mpeg, rm, rmvb, flv, mkv, ogv, ogg
    /// 代码文件
    case c, h, m, cpp, swift, html, css, java, php, json, xml, md
    /// 压缩文件
    case zip, rar, tar, apk
    case is7z = "7z"
    /// 设计文件
    case psd, ai, aep, sketch
    /// harmful
    case app, bat, chm, cmd,
         com, cpl, csh, dll,
         exe, hta, jar, js,
         jse, ksh, lnk, msc,
         msh, msh1, msh2, mshxml,
         msh1xml, msh2xml, msi,
         msp, mst, msu, pif,
         pl, prg, ps1, ps1xml,
         ps2, ps2xml, psc1, psc2,
         psd1, psdm1, py, pyc,
         pyo, pyw, pyz, pyzw,
         scf, scr, sct, shb,
         shs, vb, vbe, vbs,
         ws, wsc, wsf, wsh

    init(fileExtension: String?) {
        guard let fileExtension = fileExtension?.lowercased(),
            let type = DriveFileType(rawValue: fileExtension) else {
                self = .unknown
                return
        }
        self = type
    }
    var isHarmful: Bool {
        return harmfulTypes.contains(where: { $0 == self.rawValue })
    }
}

extension DriveFileType {
    var canShowWaterMark: Bool {
        switch self {
        case .pdf, .numbers, . pages: return false
        case _ where self.isPPT || self.isWord || self.isExcel || self.isKeynote : return false
        default: return true
        }
    }

    var isAudio: Bool {
        switch self {
        case .mp3, .wav, .m4a, .wma, .amr,
             .aac, .au, .flac: return true
        default: return false
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

    var isAlbumVideo: Bool {
        switch self {
        case .mp4, .mov:
            return true
        default:
            return false
        }
    }

    var isMedia: Bool {
        return isVideo || isAudio
    }

    var isTxt: Bool {
        switch self {
        case .txt, .rtf: return true
        case _ where self.isCode: return true
        default: return false
        }
    }

    var isImage: Bool {
        switch self {
        case .jpeg, .jpg, .png, .bmp, .tif, .tiff,
             .svg, .raw, .gif, .heic: return true
        default: return false
        }
    }
    
    var isAlbumImage: Bool {
        switch self {
        case .jpeg, .jpg, .png, .gif, .tiff, .heic:
            return true
        default:
            return false
        }
    }

    var isExcel: Bool {
        switch self {
        case .xls, .xlsx, .xlsm, .csv: return true
        default: return false
        }
    }

    var isWord: Bool {
        switch self {
        case .doc, .docx, .dot, .dotx: return true
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

    var isCode: Bool {
        switch self {
        case .c, .h, .m, .cpp, .swift, .html, .css, .js, .java, .py, .php, .json, .xml, .md: return true
        default: return false
        }
    }

    var isZip: Bool {
        switch self {
        case .zip, .rar, .is7z, .tar: return true
        default: return false
        }
    }

    // 原生支持打开（i.e. Quick Look(普通 PDF/ Office/ )/ 代码 / 后台不支持转码的音视频/ ）
    var isSupport: Bool {
        switch self {
        case .pdf, // 使用 PDF Steaming 的话，需要从后台下载线性化的文件
        .txt, .rtf,
        .doc, .docx, .dot, .dotx,
        .xlsx, .xlsm, .csv, // 撤销xls的支持，部分xls无法正常打开
        .ppt, .pptx, .pps, .ppsx, .pot, .potx,
        .keynote, .pages, .numbers, .key,
        .jpeg, .jpg, .png, .bmp, .tif, .tiff, .svg, .gif, .heic, // missing:  .raw
        .mp4, .mov, .wmv, .m4v, .avi, .mpg, .mpeg, .rm, .rmvb, .flv, .mkv, .ogg, // missing: ogv
        .mp3, .wav, .m4a, .wma, .amr, .aac, .au, .flac,
        .c, .h, .m, .cpp, .swift, .html, .css, .js, .java, .py, .php, .json, .xml, .md: return true
        // missing: zip, rar, tar, apk, 7z, psd, ai, aep, sketch
        default: return false
        }
    }

    var isSupportMultiPics: Bool {
        return self.isImage && self != .svg && self != .gif
    }

    // 优先使用本地能力来预览
    var preferLocalPreview: Bool {
       switch self {
       case _ where self.isPPT || self.isWord || self.isExcel || self.isKeynote || self.isCode || self.isTxt:
           return true
       default: return false
       }
    }

    private var imageName: String {
        switch self {
        case _ where self.isExcel:
            return "excel"
        case _ where self.isKeynote:
            return "keynote"
        case _ where self.isPPT:
            return "ppt"
        case _ where self.isTxt:
            return "txt"
        case _ where self.isWord:
            return "word"
        case _ where self.isZip:
            return "zip"
        case _ where self.isImage:
            return "image"
        case _ where self.isVideo:
            return "video"
        case _ where self.isAudio:
            return "music"
        case .pdf:
            return "pdf"
        case .aep:
            return "ae"
        case .ai:
            return "ai"
        case .apk:
            return "apk"
        case .psd:
            return "ps"
        case .sketch:
            return "sketch"
        default:
            return "other"
        }
    }

    /// Quick Access 上使用的 icon
    var quickAccessImage: UIImage? {
        return I18n.image(named: "docstype_quickAccess_\(imageName)")
    }
    /// List 上使用的 icon
    var iconImage: UIImage? {
        return I18n.image(named: "docstype_file_\(imageName)")
    }
    /// Pin 一个 file 时的缩略图
    var thumbnailImage: UIImage? {
        return I18n.image(named: "thumbnail_file_\(imageName)")
    }
    /// Pin Folder 里有 file 时的缩略图
    var thumbnailIconImage: UIImage? {
        return I18n.image(named: "thumbnail_icon_file_\(imageName)")
    }
    /// Loading 上使用的 icon
    var loadingImage: UIImage? {
        return I18n.image(named: "drive_loading_\(imageName)")
    }
}

protocol DriveFileCacheable {
    var type: String { get }
    var fileToken: String { get }
}

extension DriveFileCacheable {

    var fileType: DriveFileType {
        return DriveFileType(fileExtension: type)
    }

}
