//
//  LarkRichTextCoreUtils+Doc.swift
//  LarkRichTextCore
//
//  Created by Yuri on 2023/6/5.
//

import Foundation
import RustPB

public final class LarkRichTextCoreUtils {
    public enum FileType {
        case ae
        case ai
        case apk
        case audio
        case excel
        case image
        case pdf
        case ppt
        case psd
        case sketch
        case txt
        case video
        case word
        case zip
        case keynote
        case eml
        case msg
        case pages
        case numbers
        case heic
        case unknow
    }
}

public extension LarkRichTextCoreUtils {

    public static func docIcon(docType: RustPB.Basic_V1_Doc.TypeEnum, fileName: String) -> UIImage {
        switch docType {
        case .unknown:
            return Resources.doc_unknow_icon
        case .doc:
            return Resources.doc_doc_icon
        case .sheet:
            return Resources.doc_sheet_icon
        case .bitable:
            return Resources.doc_bitable_icon
        case .mindnote:
            return Resources.doc_mindnote_icon
        case .slide:
            return Resources.doc_slide_icon
        case .file:
            return LarkRichTextCoreUtils.docIcon(fileName: fileName)
        case .docx:
            return Resources.doc_docx_icon
        case .wiki:
            return Resources.icon_Wiki_doc_circle
        case .folder:
            return Resources.doc_folder_icon
        case .catalog:
            return Resources.icon_wiki_catalog_circle
        case .slides:
            return Resources.doc_slides_icon
        case .shortcut:
            assert(false, "new value")
            return Resources.doc_unknow_icon
        @unknown default:
            assert(false, "new value")
            return Resources.doc_unknow_icon
        }
    }

    // nolint: cyclomatic_complexity
    public static func docIcon(fileName: String) -> UIImage {
        switch getFileType(fileName: fileName) {
        case .ae:
            return Resources.doc_ae_icon
        case .ai:
            return Resources.doc_ai_icon
        case .apk:
            return Resources.doc_android_icon
        case .audio:
            return Resources.doc_music_icon
        case .excel:
            return Resources.doc_excel_icon
        case .image, .heic:
            return Resources.doc_image_icon
        case .pdf:
            return Resources.doc_pdf_icon
        case .ppt:
            return Resources.doc_ppt_icon
        case .psd:
            return Resources.doc_ps_icon
        case .sketch:
            return Resources.doc_sketch_icon
        case .txt:
            return Resources.doc_txt_icon
        case .video:
            return Resources.doc_video_icon
        case .word:
            return Resources.doc_word_icon
        case .zip:
            return Resources.doc_zip_icon
        case .keynote:
            return Resources.doc_keynote_icon
        case .pages:
            return Resources.doc_pages_icon
        case .numbers:
            return Resources.doc_numbers_icon
        default:
            return Resources.doc_unknow_icon
        }
    }

    static func docUrlIcon(docType: RustPB.Basic_V1_Doc.TypeEnum, size: CGSize) -> UIImage {
        var image = Resources.docUrlIcon_doc_icon
        switch docType {
        case .unknown:
            image = Resources.docUrlIcon_doc_icon
        case .doc:
            image = Resources.docUrlIcon_doc_icon
        case .sheet:
            image = Resources.docUrlIcon_sheet_icon
        case .bitable:
            image = Resources.docUrlIcon_bitable_icon
        case .mindnote:
            image = Resources.docUrlIcon_mindnote_icon
        case .slide:
            image = Resources.docUrlIcon_slide_icon
        case .file:
            image = Resources.docUrlIcon_file_icon
        case .docx:
            image = Resources.docUrlIcon_docx_icon
        case .wiki:
            image = Resources.docUrlIcon_doc_icon
        case .folder:
            image = Resources.docUrlIcon_folder_icon
        case .catalog:
            // 产品决策先用 doc 的 icon
            // image = Resources.docUrlIcon_folder_icon
            image = Resources.docUrlIcon_doc_icon
        case .slides:
            image = Resources.docUrlIcon_slides_icon
        case .shortcut:
            assert(false, "new value")
            image = Resources.docUrlIcon_doc_icon
        @unknown default:
            assert(false, "new value")
            image = Resources.docUrlIcon_doc_icon
        }
        return image
            .ud.resized(to: size)
            .ud.withTintColor(UIColor.ud.textLinkNormal)
    }

    // nolint: cyclomatic_complexity
    static func getFileType(fileName: String) -> FileType {
        var pathExtension = ""
        if let pointIndex = fileName.lastIndex(of: ".") {
            pathExtension = String(fileName[fileName.index(after: pointIndex)...])
        }
        switch pathExtension.lowercased() {
        case "aep", "aepx":
            return .ae
        case "ai":
            return .ai
        case "apk":
            return .apk
        case "mp3", "m4a", "wav", "aac", "au", "flac", "ogg", "amr", "wma", "mld", "mldl":
            return .audio
        case "xls", "xlsx", "csv", "xlsm", "et":
            return .excel
        case "jpg", "jpeg", "png", "bmp", "tif", "tiff", "svg", "raw", "gif":
            return .image
        case "pdf":
            return .pdf
        case "ppt", "pptx", "pps", "ppsx", "pot", "potx":
            return .ppt
        case "psd":
            return .psd
        case "sketch":
            return .sketch
        case "txt":
            return .txt
        case "mp4", "mov", "wmv", "avi", "mpg", "mpeg", "m4v", "rm", "rmvb", "flv", "mkv":
            return .video
        case "doc", "docx", "dot", "dotx", "wps":
            return .word
        case "zip", "rar", "tar", "7z":
            return .zip
        case "key":
            return .keynote
        case "eml":
            return .eml
        case "msg":
            return .msg
        case "pages":
            return .pages
        case "numbers":
            return .numbers
        case "heic", "heif":
            return .heic
        default:
            return transformUnknownFileType(fileName: fileName)
        }
    }

    //解析含有两个点的拓展名，例如.tar.gz等
    private static func transformUnknownFileType(fileName: String) -> FileType {
        let splitedList = fileName.split(separator: ".")
        if splitedList.count > 2 {
            let extendedNameWithTwoDots = "\(splitedList[splitedList.count - 2]).\(splitedList.last ?? "")"
            switch extendedNameWithTwoDots.lowercased() {
            case "tar.gz", "tar.xz", "tar.bz2":
                return .zip
            default:
                return .unknow
            }
        }
        return .unknow
    }
}
