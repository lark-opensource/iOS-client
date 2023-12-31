//
//  DriveFileType+Icon.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/12/8.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor

public extension DriveFileType {
    // MARK: 图标见 DS 设计规范：https://www.figma.com/file/QZuuLpslxDS1AE5LfwtsQo/%F0%9F%8C%9E-Light-03-Icons-and-Logo?node-id=4534%3A968
    // 另见：https://bytedance.feishu.cn/wiki/wikcnGcQUbacESJFxrzkxHC085f

    // 圆形彩色填充的 icon
    var roundColorfulImageKey: UDIconType? {
        switch self {
        case .eml:
            return .fileRoundEmlColorful
        case .msg:
            return .fileRoundMsgColorful
        case .pdf:
            return .fileRoundPdfColorful
        case .csv:
            return .fileRoundCsvColorful
        case .aep:
            return .fileRoundAeColorful
        case .ai:
            return .fileRoundAiColorful
        case .apk:
            return .fileRoundAndroidColorful
        case .ipa:
            return .fileRoundIosColorful
        case .psd:
            return .fileRoundPsColorful
        case .sketch:
            return .fileRoundSketchColorful
        case .numbers:
            return .fileRoundNumbersColorful
        case .pages:
            return .fileRoundPagesColorful
        case .wps:
            return .fileRoundWordColorful
        case .et:
            return .fileRoundExcelColorful
        case _ where self.isExcel:
            return .fileRoundExcelColorful
        case _ where self.isKeynote:
            return .fileRoundKeynoteColorful
        case _ where self.isPPT:
            return .fileRoundPptColorful
        case _ where self.isCode, .log, .md: // 要求 .log, .md 展示代码的图标
            return .fileRoundCodeColorful
        case _ where self.isText:
            return .fileRoundTextColorful
        case _ where self.isWord:
            return .fileRoundWordColorful
        case _ where self.isArchive:
            return .fileRoundZipColorful
        case _ where self.isImage:
            return .fileRoundImageColorful
        case _ where self.isVideo:
            return .fileRoundVideoColorful
        case _ where self.isAudio:
            return .fileRoundAudioColorful
        default:
            return nil
        }
    }

    /// 圆形的 icon
    var roundImage: UIImage? {
        guard let iconKey = roundColorfulImageKey else { return nil }
        return UDIcon.getIconByKeyNoLimitSize(iconKey)
    }

    // 方形彩色填充 icon
    var squareColorfulImageKey: UDIconType? {
        switch self {
        case .eml:
            return .fileEmlColorful
        case .msg:
            return .fileMsgColorful
        case .pdf:
            return .filePdfColorful
        case .csv:
            return .fileCsvColorful
        case .aep:
            return .fileAeColorful
        case .ai:
            return .fileAiColorful
        case .apk:
            return .fileAndroidColorful
        case .ipa:
            return .fileIosColorful
        case .psd:
            return .filePsColorful
        case .sketch:
            return .fileSketchColorful
        case .numbers:
            return .fileNumbersColorful
        case .pages:
            return .filePagesColorful
        case .wps:
            return .fileWordColorful
        case .et:
            return .fileExcelColorful
        case _ where self.isExcel:
            return .fileExcelColorful
        case _ where self.isKeynote:
            return .fileKeynoteColorful
        case _ where self.isPPT:
            return .filePptColorful
        case _ where self.isCode, .log, .md: // 要求 .log, .md 展示代码的图标
            return .fileCodeColorful
        case _ where self.isText:
            return .fileTextColorful
        case _ where self.isWord:
            return .fileWordColorful
        case _ where self.isArchive:
            return .fileZipColorful
        case _ where self.isImage:
            return .fileImageColorful
        case _ where self.isVideo:
            return .fileVideoColorful
        case _ where self.isAudio:
            return .fileAudioColorful
        default:
            return nil
        }
    }

    /// 方形 icon
    var squareImage: UIImage? {
        let iconKey: UDIconType
        if let squareColorfulImageKey {
            iconKey = squareColorfulImageKey
        } else {
            iconKey = .fileUnknowColorful
        }
        return UDIcon.getIconByKey(iconKey, size: CGSize(width: 48, height: 48))
    }

    // 方形线框 icon
    var outlinedImageKey: UDIconType? {
        switch self {
        case .eml:
            return .fileEmlOutlined
        case .msg:
            return .fileMsgOutlined
        case .pdf:
            return .fileLinkPdfOutlined
        case .csv:
            return .fileCsvOutlined
        case .aep:
            return .fileAeOutlined
        case .ai:
            return .fileAiOutlined
        case .apk:
            return .fileAndroidOutlined
        case .ipa:
            return .fileIosOutlined
        case .psd:
            return .filePsOutlined
        case .sketch:
            return .fileSketchOutlined
        case .numbers:
            return .fileNumbersOutlined
        case .pages:
            return .filePagesOutlined
        case .wps:
            return .fileLinkWord2Outlined
        case .et:
            return .fileLinkExcelOutlined
        case _ where self.isExcel:
            return .fileLinkExcelOutlined
        case _ where self.isKeynote:
            return .fileKeynoteOutlined
        case _ where self.isPPT:
            return .fileLinkPptOutlined
        case _ where self.isCode, .log, .md: // 要求 .log, .md 展示代码的图标
            return .fileCodeOutlined
        case _ where self.isText:
            return .fileLinkTextOutlined
        case _ where self.isWord:
            return .fileLinkWord2Outlined
        case _ where self.isArchive:
            return .fileLinkZipOutlined
        case _ where self.isImage:
            return .fileLinkImageOutlined
        case _ where self.isVideo:
            return .fileLinkVideoOutlined
        case _ where self.isAudio:
            return .fileLinkAudioOutlined
        default:
            return nil
        }
    }

    // 融合了 shortcut 的方形线框 icon
    var shortcutOutlinedImageKey: UDIconType? {
        switch self {
        case .eml:
            return .fileEmlShortcutOutlined
        case .msg:
            return .fileMsgShortcutOutlined
        case .pdf:
            return .fileLinkPdfShortcutOutlined
        case .csv:
            return .fileCsvShortcutOutlined
        case .aep:
            return .fileAeShortcutOutlined
        case .ai:
            return .fileAiShortcutOutlined
        case .apk:
            return .fileAndroidShortcutOutlined
        case .ipa:
            return .fileIosShortcutOutlined
        case .psd:
            return .filePsShortcutOutlined
        case .sketch:
            return .fileSketchShortcutOutlined
        case .numbers:
            return .fileNumbersShortcutOutlined
        case .pages:
            return .filePagesShortcutOutlined
        case .wps:
            return .fileLinkWord2ShortcutOutlined
        case .et:
            return .fileLinkExcelShortcutOutlined
        case _ where self.isExcel:
            return .fileLinkExcelShortcutOutlined
        case _ where self.isKeynote:
            return .fileKeynoteShortcutOutlined
        case _ where self.isPPT:
            return .fileLinkPptShortcutOutlined
        case _ where self.isCode, .log, .md: // 要求 .log, .md 展示代码的图标
            return .fileCodeShortcutOutlined
        case _ where self.isText:
            return .fileLinkTextShortcutOutlined
        case _ where self.isWord:
            return .fileLinkWord2ShortcutOutlined
        case _ where self.isArchive:
            return .fileLinkZipShortcutOutlined
        case _ where self.isImage:
            return .fileLinkImageShortcutOutlined
        case _ where self.isVideo:
            return .fileLinkVideoShortcutOutlined
        case _ where self.isAudio:
            return .fileLinkAudioShortcutOutlined
        default:
            return nil
        }
    }

    /// 图标的前景和背景色（前景色是图标本色，背景色是图标外面 container 的颜色对应的 100）
    var imageColor: (foreground: UIColor, background: UIColor) {
        switch self {
        case .pdf:
            return (foreground: UDColor.colorfulRed, background: UDColor.R100)
        case .csv, .apk, .numbers:
            return (foreground: UDColor.colorfulGreen, background: UDColor.G100)
        case .aep:
            return (foreground: UDColor.colorfulViolet, background: UDColor.V100)
        case .ai, .sketch, .pages:
            return (foreground: UDColor.colorfulOrange, background: UDColor.O100)
        case .ipa, .psd:
            return (foreground: UDColor.colorfulBlue, background: UDColor.B100)
        case .wps:
            return (foreground: UDColor.colorfulBlue, background: UDColor.B100)
        case .et:
            return (foreground: UDColor.colorfulGreen, background: UDColor.G50)
        case _ where self.isExcel:
            return (foreground: UDColor.colorfulGreen, background: UDColor.G50)
        case _ where self.isKeynote:
            return (foreground: UDColor.colorfulBlue, background: UDColor.B100)
        case _ where self.isPPT:
            return (foreground: UDColor.colorfulOrange, background: UDColor.O100)
        case _ where self.isCode, .log, .md: // 要求 .log, .md 展示代码的图标
            return (foreground: UDColor.colorfulBlue, background: UDColor.B50)
        case _ where self.isText:
            return (foreground: UDColor.colorfulBlue, background: UDColor.B100)
        case _ where self.isWord:
            return (foreground: UDColor.colorfulBlue, background: UDColor.B100)
        case _ where self.isArchive:
            return (foreground: UDColor.colorfulBlue, background: UDColor.B100)
        case _ where self.isImage:
            return (foreground: UDColor.colorfulYellow, background: UDColor.Y100)
        case _ where self.isVideo:
            return (foreground: UDColor.colorfulBlue, background: UDColor.B100)
        case _ where self.isAudio:
            return (foreground: UDColor.colorfulGreen, background: UDColor.G100)
        default:
            return (foreground: UDColor.N500, background: UDColor.N100) // N100 颜色太浅
        }
    }
}
