//
//  DriveFileType.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/15.
// swiftlint:disable file_length

import SKFoundation
import SKResource
import LarkReleaseConfig
import UniverseDesignColor
import UniverseDesignIcon
import LarkAppConfig
import LarkDocsIcon
import SKFoundation

extension DriveFileType {
    public var mimeType: String {
        return MIMETypes[rawValue] ?? defaultMIMEType
    }


    public var isSupportHTML: Bool {
        switch self {
        case .xls, .xlsx, .xlsm:
            return true
        default:
            return false
        }
    }

    public var canImportAsDocs: Bool {
        switch self {
        case .doc, .docx:
            return true
        default:
            return false
        }
    }

    public var canImportAsSheet: Bool {
        switch self {
        case .xls, .xlsx, .csv:
            return true
        default:
            return false
        }
    }

    public var canImportAsMindnote: Bool {
        switch self {
        case .xmind, .opml, .mm:
            return true
        default:
            return false
        }
    }

    // 原生支持打开（i.e. Quick Look(普通PDF/ Office/ )/ 代码/ 后台不支持转码的音视频/ ）
    public var isSupport: Bool {
        switch self {
        case .pdf, // 使用PDF Steaming的话，需要从后台下载线性化的文件
            .doc, .docx, .dot, .dotx,
            .xls, .xlsx, .xlsm, .csv,
            .ppt, .pptx, .pps, .ppsx, .pot, .potx,
            .keynote, .pages, .numbers, .key,
            .jpeg, .jpg, .png, .bmp, .tif, .tiff, .svg, .gif, .heic, .heif,    //missing:  .raw
            .mp4, .mov, .m4v,  //missing: 大部分视频
            .mp3, .wav, .m4a, .amr, .aac, .au, .flac,
            .txt, .rtf, .log, .md,
            .c, .h, .m, .cpp, .swift, .html, .css, .js, .java,
            .py, .php, .json, .xml, .rb, .go, .cs, .kt, .sql,
            .htm, .matlab, .gradle, .groovy, .webp,
            .zip, .rar, .tar, .tarGz, .tarBz2: // 本地支持的压缩文件格式
            return true
        default: return false
        }
    }
    
    // AVPlayer支持的多媒体文件
    public var isAVPlayerSupport: Bool {
        switch self {
        case .mp4, .mov, .m4v,
             .mp3, .wav, .m4a, .aac, .au, .flac:
            return true
        default:
            return false
        }
    }
    
    // TTPlayer支持的多媒体文件： https://bytedance.feishu.cn/wiki/wikcnsBEXVphz3NWgdLd9fFL20e
    public var isTTPlayerSupport: Bool {
        switch self {
        case .mp4, .mov: // video, flv非h264编码会导致白屏，暂不支持，  .mpd, .m3u8为在线视频类型
            return true
        case .mp3, .wav, .m4a: // audio
            return true
        default:
            return false
        }
    }
    
    // DriveVideoPlayer支持播放的类型
    public var isVideoPlayerSupport: Bool {
        return isAVPlayerSupport || isTTPlayerSupport
    }

    public var fileSizeLimits: UInt64 {
        switch self {
        case _ where self.isText:
            return DriveFeatureGate.textPreviewMaxSize
        case .webp:
            return DriveFeatureGate.webpPreviewMaxSize
        default:
            return UInt64.max
        }
    }

    // 优先使用本地能力来预览
    public var preferLocalPreview: Bool {
        switch self {
        case _ where self.isWord
            || self.isIWork
                || self.isCode:
            return true
        case .pdf:
            return true
        default: return false
        }
    }

    /// 优先使用后端转码预览的文件类型
    public var preferRemotePreviewInVCFollow: Bool {
        switch self {
        case _ where self.isPPT
            || self.isExcel
            || self.isWord:
            return true
        default: return false
        }
    }

    // iwork套件类型文件
    public var isIWork: Bool {
        switch self {
        case .keynote, .pages, .numbers, .key:
            return true
        default:
            return false
        }
    }

    public var isSupportMultiPics: Bool {
        return self.isImage && self != .svg && self != .gif
    }

    public var isSupportAreaComment: Bool {
        return (self.isImage && self != .svg && self != .gif)
    }
    
    public var isAblumImage: Bool {
        switch self {
        case .heif, .jpeg, .jpg, .png, .gif, .tiff, .heic:
            return true
        default:
            return false
        }
    }
    
    public var isAblumVideo: Bool {
        switch self {
        case .mp4, .mov:
            return true
        default:
            return false
        }
    }
    
    public var isWpsOffice: Bool {
        if UserScopeNoChangeFG.MJ.etAndWpsFileTypeEnable {
            return self.isPPT || self.isWord || self.isExcel || self == .wps || self == .et
        } else {
            return self.isPPT || self.isWord || self.isExcel
        }
    }
}

extension DriveFileType {

//    /// 该文件格式是否支持视频转码的判断
//    public func canVideoTranscoding() -> Bool {
//        switch self {
//        case .mp4: return true
//        default: return false
//        }
//    }

    public func needSaveCache() -> Bool { // 视频暂时不缓存
        switch self {
        case _ where self.isVideo :
            return false
        default: return true
        }
    }
}
