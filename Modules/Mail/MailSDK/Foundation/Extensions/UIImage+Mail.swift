//
//  UIImage+Docs.swift
//  Common
//
//  Created by weidong fu on 5/1/2018.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import LarkDocsIcon

extension UIImage: MailExtensionCompatible {}
extension MailExtension where BaseType == UIImage {
    func alpha(_ value: CGFloat) -> UIImage? {
        let format = self.base.imageRendererFormat
        format.opaque = false
        format.scale = self.base.scale
        return UIGraphicsImageRenderer(size: self.base.size, format: format).image { _ in
            self.base.draw(at: .zero, blendMode: .normal, alpha: value)
        }
    }
}

extension UIImage {
    func resized(withPercentage percentage: CGFloat, isOpaque: Bool = true) -> UIImage? {
        let canvas = CGSize(width: size.width * percentage, height: size.height * percentage)
        let format = imageRendererFormat
        format.opaque = isOpaque
        return UIGraphicsImageRenderer(size: canvas, format: format).image {
            _ in draw(in: CGRect(origin: .zero, size: canvas))
        }
    }

    func data(quality: CGFloat) -> Data? {
        guard let data = jpegData(compressionQuality: quality) else {
            MailLogger.error("get jpeg data fail")
            return nil
        }

        return data
    }

    static func from(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        return UIGraphicsImageRenderer(size: rect.size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: rect.size))
        }
    }

    static func getIconFromDocs(with fileName: String, size: CGSize) -> UIImage {
        let fileType = LarkDocsIcon.DriveFileType(fileExtension: (fileName as NSString).pathExtension.lowercased())
        MailLogger.info("[Mail_WPS_Icon] Trying to getIconFromDocs with fileType \(fileType)")
        guard let icon = fileType.squareImage else {
            return UDIcon.getIconByKey(.fileUnknowColorful, size: size)
            MailLogger.info("[Mail_WPS_Icon] Failed to getIconFromDocs")
        }
        MailLogger.info("[Mail_WPS_Icon] Succeeded to getIconFromDocs")
        return icon
    }

    static func fileLadderIcon(with fileName: String) -> UIImage {
        return fileLadderIcon(with: fileName, size: CGSize(width: 70, height: 70))
    }
    static func fileLadderIcon(with fileName: String, size: CGSize) -> UIImage {
        switch getFileType(fileName: fileName) {
        case .ae:
            return UDIcon.getIconByKey(.fileAeColorful, size: size)
        case .ai:
            return UDIcon.getIconByKey(.fileAiColorful, size: size)
        case .apk:
            return UDIcon.getIconByKey(.fileAndroidColorful, size: size)
        case .audio:
            return UDIcon.getIconByKey(.fileAudioColorful, size: size)
        case .excel:
            return UDIcon.getIconByKey(.fileExcelColorful, size: size)
        case .image:
            return UDIcon.getIconByKey(.fileImageColorful, size: size)
        case .pdf:
            return UDIcon.getIconByKey(.filePdfColorful, size: size)
        case .ppt:
            return UDIcon.getIconByKey(.filePptColorful, size: size)
        case .psd:
            return UDIcon.getIconByKey(.filePsColorful, size: size)
        case .sketch:
            return UDIcon.getIconByKey(.fileSketchColorful, size: size)
        case .txt:
            return UDIcon.getIconByKey(.fileTextColorful, size: size)
        case .video:
            return UDIcon.getIconByKey(.fileVideoColorful, size: size)
        case .word:
            return UDIcon.getIconByKey(.fileWordColorful, size: size)
        case .zip:
            return UDIcon.getIconByKey(.fileZipColorful, size: size)
        case .keynote:
            return UDIcon.getIconByKey(.fileKeynoteColorful, size: size)
        case .eml:
            return UDIcon.getIconByKey(.fileEmlColorful, size: size)
        case .msg:
            return UDIcon.getIconByKey(.fileMsgColorful, size: size)
        case .ics:
            return UDIcon.getIconByKey(.fileCalendarColorful, size: size)
        case .pages:
            return UDIcon.getIconByKey(.filePagesColorful, size: size)
        case .numbers:
            return UDIcon.getIconByKey(.fileNumbersColorful, size: size)
        case .wps, .et:
            return getIconFromDocs(with: fileName, size: size)
        case .unknown:
            return UDIcon.getIconByKey(.fileUnknowColorful, size: size)
        }
    }

    static func fileBgColor(with fileName: String, withSize size: CGSize) -> UIColor {
        switch fileBgColorType(with: fileName) {
        case .blue:
            return UDColor.attachmentCardBgBlue(withSize: size)
        case .red:
            return UDColor.attachmentCardBgRed(withSize: size)
        case .green:
            return UDColor.attachmentCardBgGreen(withSize: size)
        case .orange:
            return UDColor.attachmentCardBgOrange(withSize: size)
        case .violet:
            return UDColor.attachmentCardBgViolet(withSize: size)
        case .yellow:
            return UDColor.attachmentCardBgYellow(withSize: size)
        case .grey:
            return UDColor.attachmentCardBgGrey(withSize: size)
        }
    }

    static func fileBgColorType(with fileName: String) -> FileIconColorType {
        switch getFileType(fileName: fileName) {
        case .pdf:
            return .red
        case .psd, .txt, .video, .word, .zip, .keynote, .eml, .msg, .wps:
            return .blue
        case .apk, .audio, .excel, .numbers, .et:
            return .green
        case .ai, .ppt, .sketch, .ics, .pages:
            return .orange
        case .ae:
            return .violet
        case .image:
            return .yellow
        case .unknown:
            return .grey
        }
    }

    enum FileType {
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
        case ics
        case pages
        case numbers
        case wps
        case et
        case unknown
    }

    enum FileIconColorType: String {
        case blue
        case red
        case green
        case orange
        case violet
        case yellow
        case grey
    }

    private static func getFileType(fileName: String) -> FileType {
        switch (fileName as NSString).pathExtension.lowercased() {
        case "aep", "aepx":
            return .ae
        case "ai":
            return .ai
        case "apk":
            return .apk
        case "mp3", "m4a", "wav", "aac", "au", "flac", "ogg", "amr", "wma", "mld", "mldl":
            return .audio
        case "xls", "xlsx", "csv", "xlsm":
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
        case "doc", "docx", "dot", "dotx":
            return .word
        case "zip", "rar", "tar", "7z":
            return .zip
        case "key":
            return .keynote
        case "eml":
            return .eml
        case "msg":
            return .msg
        case "ics":
            return .ics
        case "pages":
            return .pages
        case "numbers":
            return .numbers
        case "wps":
            return .wps
        case "et":
            return .et
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
                return .unknown
            }
        }
        return .unknown
    }
}
