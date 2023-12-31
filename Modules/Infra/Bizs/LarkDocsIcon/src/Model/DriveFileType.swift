//
//  DriveFileType.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/6/16.
//  从SKCommon下层下来的

import Foundation
import LarkContainer
/// 文件类型
public enum DriveFileType: String {

    /// PDF
    case pdf
    /// Word
    case doc, docx, dot, dotx, dotm
    /// Excel
    case xls, xlsx, xlsm, csv, xlsb, xlm
    /// PPT
    case ppt, pptx, pps, ppsx, pot, potx, pptm, potm, ppsm
    /// keynote
    case keynote, pages, numbers, key
    /// Image
    case jpeg, jpg, png, bmp, tif, tiff, svg, raw, gif, heic, heif, webp,
         ico, arw, cr2, crw, dcr, dcs, dng, dwg, erf, kdc, mef, mos, mrw, nef, nrw, orf, pef, ppm, r3d, raf, rw2, rwl, sr2, svgz, wbmp, x3f,
         is3rf = "3rf"
    /// Video
    case mp4, mov, wmv, m4v, avi, mpg, mpeg, rm, rmvb, flv, mkv, ogv,
         asf, dv, f4v, m2t, mpe, mts, mxf, vob, webm, ts,
         is3gp = "3gp", is3gpp = "3gpp", is3gpp2 = "3gpp2"
    /// Audio
    case mp3, wav, m4a, wma, amr, aac, au, flac,
         cda, oga, ogg, m4r, air, aiff
    /// 压缩文件
    case zip, rar, tar, gz, tgz,
         tarGz = "tar.gz", tarBz2 = "tar.bz2", lzma, tarLzma = "tar.lzma", is7z = "7z",
         bz2, cab, zipx, jar, ace, arj, lzh, z, bz, cpio, iso, lha, lz, tbz, taz, tbz2, tlz, txz, tz, xar, xz
    /// 安装包
    case apk, ipa
    /// 设计文件
    case psb, psd, ai, aep, sketch
    /// 文本
    case txt, rtf, log
    case md
    /// 代码文件
    case c, h, m, cpp, swift, html, css, js, java,
         py, php, json, xml, rb, go, cs, kt, sql, htm, matlab, gradle, groovy,
         sh, bash, scss, less, tsx, jsx, ejs, jsp, vue, r, scala, pl, hs, lua, dart, conf, coffee, rs, url, webloc, website,
         `as`, as3, asm, aspx, asp, bat, cc, cmake, cxx, diff, erb, erl, gvy, haml, hh, hpp, hxx, lst, make, ml, out, patch,
         plist, properties, sass, script, scm, sml, vb, vi, vim, xhtml, xsd, xsl, yaml, yml, markdown, mdown, mkdn
    /// 思维笔记
    case xmind, opml, mm
    /// mail 文件
    case eml
    /// msg 文件
    case msg
    /// wps文件类型
    case et, wps
    /// 未知文件
    case unknown

    public init(fileExtension: String?) {
        guard let fileExtension = fileExtension?.lowercased(),
            let type = DriveFileType(rawValue: fileExtension) else {
            self = .unknown
            return
        }
        self = type
    }

    
}


extension DriveFileType {
    
    public var isVideo: Bool {
        switch self {
        case .mp4, .mov, .wmv, .m4v, .avi, .mpg, .mpeg, .rm, .rmvb, .flv, .mkv, .ogv, .ogg,
             .asf, .dv, .f4v, .m2t, .mpe, .mts, .mxf, .vob, .webm, .ts, .is3gp, .is3gpp, .is3gpp2: return true
        default: return false
        }
    }

    public var isAudio: Bool {
        switch self {
        case .mp3, .wav, .m4a, .wma, .amr, .aac, .au, .flac,
             .cda, .oga, .ogg, .m4r, .air, .aiff: return true
        default: return false
        }
    }

    public var isMedia: Bool {
        return isVideo || isAudio
    }

    public var isImage: Bool {
        switch self {
        case .jpeg, .jpg, .png, .bmp, .tif, .tiff, .svg, .raw, .gif, .heic, .heif, .webp,
                .ico, .arw, .cr2, .crw, .dcr, .dcs, .dng, .dwg, .erf, .kdc, .mef, .mos, .mrw, .psd,
             .nef, .nrw, .orf, .pef, .ppm, .r3d, .raf, .rw2, .rwl, .sr2, .svgz, .wbmp, .x3f, .is3rf: return true
        default: return false
        }
    }

    public var isText: Bool {
        switch self {
        case .txt, .rtf, .log: return true
        case .md: return true
        case _ where self.isCode: return true
        default: return false
        }
    }

    public var isRichText: Bool {
        switch self {
        case .rtf, .html: return true
        default: return false
        }
    }

    public var isWord: Bool {
        let featureGating = try? Container.shared.getCurrentUserResolver().resolve(type: DocsIconFeatureGating.self)
        switch self {
        case .doc, .docx, .dot, .dotx, .dotm: return true
        case .wps: return featureGating?.etAndWpsFileTypeEnable == true
        default: return false
        }
    }

    public var isPDF: Bool {
        return self == .pdf
    }
    
    public var isExcel: Bool {
        let featureGating = try? Container.shared.getCurrentUserResolver().resolve(type: DocsIconFeatureGating.self)
        switch self {
        case .xls, .xlsx, .xlsm, .csv, .xlm, .xlsb: return true
        case .et: return featureGating?.etAndWpsFileTypeEnable == true
        default: return false
        }
    }

    public var isPPT: Bool {
        switch self {
        case .ppt, .pptx, .pps, .ppsx, .pot, .potx, .pptm, .potm, .ppsm: return true
        default: return false
        }
    }
    
    public var isOffice: Bool {
        return self.isPPT || self.isWord || self.isExcel
    }

    public var isKeynote: Bool {
        switch self {
        case .keynote, .key: return true
        default: return false
        }
    }

    public var isArchive: Bool {
        switch self {
        case .zip, .rar,
             .tar, .gz, .tgz, .tarGz,
             .bz2, .tarBz2,
             .lzma, .tarLzma,
             .is7z,
             .cab, .zipx, .jar, .ace, .arj, .lzh, .z, .bz, .cpio, .iso, .lha, .lz, .tbz, .taz, .tbz2, .tlz, .txz, .tz, .xar, .xz:
            return true
        default: return false
        }
    }
    
    public var isCode: Bool {
        switch self {
        case .c, .h, .m, .cpp, .swift, .html, .css, .js, .java,
             .py, .php, .json, .xml, .rb, .go, .cs, .kt, .sql,
             .htm, .matlab, .gradle, .groovy,
             .sh, .bash, .scss, .less, .tsx, .jsx, .ejs, .jsp, .vue, .r, .scala, .pl, .hs, .lua, .dart, .conf, .coffee, .rs, .url, .webloc, .website,
             .as, .as3, .asm, .aspx, .asp, .bat, .cc, .cmake, .cxx, .diff, .erb, .erl, .gvy, .haml, .hh, .hpp, .hxx, .lst, .make, .ml, .out, .patch,
             .plist, .properties, .sass, .script, .scm, .sml, .vb, .vi, .vim, .xhtml, .xsd, .xsl, .yaml, .yml, .markdown, .mdown, .mkdn: return true
        default: return false
        }
    }
    
    public var needCheckAdditionExtension: Bool {
        switch self {
        case .gz, .bz2, .lzma:
            return true
        default:
            return false
        }
    }

}
