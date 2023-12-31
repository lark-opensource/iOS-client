//
//  ExportDocumentViewModel.swift
//  SKBrowser
//
//  Created by lizechuang on 2020/11/20.
//

import Foundation
import SKResource
import SKCommon
import SKFoundation
import UniverseDesignIcon

public struct ExportDocumentItemInfo {
    var exportDocDownloadType: ExportDocumentType
    var markImage: UIImage
    var markTitle: String
}

enum ExportDocumentType: String {
    // 需要native&后台配合处理
    case docx
    case xlsx
    case pptx
    case pdf
    case slide2pdf
    case slide2png
    // 需要native&frontend配合处理
    case docsLongImage
    case sheetLongImage
    case sheetText

    var exportNeedFrontend: Bool {
        switch self {
        case .docsLongImage, .sheetLongImage, .sheetText:
            return true
        default:
            return false
        }
    }
    
    var exportSupportComment: Bool {
        switch self {
        case .pdf, .docx:
            return true
        default:
            return false
        }
    }

    var reportDescription: String {
        switch self {
        case .docx:
            return "word"
        case .xlsx:
            return "excel"
        case .pptx:
            return "pptx"
        case .pdf:
            return "pdf"
        case .docsLongImage, .sheetLongImage:
            return "jpg_long"
        default:
            return ""
        }
    }

    var reportDescriptionV2: String {
        switch self {
        case .docx:
            return "docx"
        case .xlsx:
            return "xlsx"
        case .pptx:
            return "pptx"
        case .pdf:
            return "pdf"
        case .docsLongImage, .sheetLongImage:
            return "image"
        default:
            return ""
        }
    }
}

class ExportDocumentViewModel {
    private(set) var titleText: String
    private(set) var docsInfo: DocsInfo
    private(set) var isFromSpaceList: Bool
    private(set) var hideLongPicAlways: Bool
    private(set) var isSheetCardMode: Bool
    private(set) var isEditor: Bool
    private(set) weak var hostViewController: UIViewController?
    private(set) var popoverSourceFrame: CGRect?
    private(set) var padPopDirection: UIPopoverArrowDirection?
    private(set) weak var sourceView: UIView?
    public weak var proxy: ExportLongImageProxy?
    private(set) var hostSize: CGSize // 父VC整体宽高
    private(set) var containerID: String?
    private(set) var containerType: String?
    private(set) var module: PageModule

    private let edManager = ExportDocumentDownloadManager.shared

    init(titleText: String = BundleI18n.SKResource.LarkCCM_Docs_DownloadAs_Menu_Mob,
         docsInfo: DocsInfo,
         hostSize: CGSize,
         isFromSpaceList: Bool,
         hideLongPicAlways: Bool = false,
         isSheetCardMode: Bool = false,
         isEditor: Bool,
         hostViewController: UIViewController?,
         module: PageModule,
         containerID: String?,
         containerType: String?,
         popoverSourceFrame: CGRect? = nil,
         padPopDirection: UIPopoverArrowDirection? = nil,
         sourceView: UIView? = nil,
         proxy: ExportLongImageProxy? = nil) {
        self.titleText = titleText
        self.docsInfo = docsInfo
        self.hostSize = hostSize
        self.isFromSpaceList = isFromSpaceList
        self.hideLongPicAlways = hideLongPicAlways
        self.isSheetCardMode = isSheetCardMode
        self.isEditor = isEditor
        self.hostViewController = hostViewController
        self.popoverSourceFrame = popoverSourceFrame
        self.padPopDirection = padPopDirection
        self.sourceView = sourceView
        self.proxy = proxy
        self.module = module
        self.containerID = containerID
        self.containerType = containerType
        edManager.resetConfig(hostViewController: hostViewController,
                                          popoverSourceFrame: popoverSourceFrame,
                                          padPopDirection: padPopDirection,
                                          sourceView: sourceView)
    }

    func startToExportDocument(_ info: ExportDocumentItemInfo, needComment: Bool?) {
        if info.exportDocDownloadType.exportNeedFrontend {
            _exportLongImage(info.exportDocDownloadType, docsInfo: docsInfo)
        } else {
            let trackerParams = _trackerExportBaseParamsWithDocsInfo(docsInfo, type: info.exportDocDownloadType)
            edManager.exportDocumentWithType(info.exportDocDownloadType, docsInfo: docsInfo, needComment: needComment, trackerParams: trackerParams)
        }
    }

    lazy var wordItemInfo: ExportDocumentItemInfo = {
        let type: ExportDocumentType = .docx
        let markImage = UDIcon.getIconByKey(.fileRoundWordColorful, size: CGSize(width: 48, height: 48))
        let markTitle = BundleI18n.SKResource.Doc_Document_ExportWord
        let item = ExportDocumentItemInfo(exportDocDownloadType: type, markImage: markImage, markTitle: markTitle)
        return item
    }()

    lazy var pdfItemInfo: ExportDocumentItemInfo = {
        let type: ExportDocumentType = .pdf
        let markImage = UDIcon.getIconByKey(.fileRoundPdfColorful, size: CGSize(width: 48, height: 48))
        let markTitle = BundleI18n.SKResource.Doc_Document_ExportPDF
        let item = ExportDocumentItemInfo(exportDocDownloadType: type, markImage: markImage, markTitle: markTitle)
        return item
    }()

    lazy var excelItemInfo: ExportDocumentItemInfo = {
        let type: ExportDocumentType = .xlsx
        let markImage = UDIcon.getIconByKey(.fileRoundExcelColorful, size: CGSize(width: 48, height: 48))
        let markTitle = BundleI18n.SKResource.Doc_Document_ExportExcel
        let item = ExportDocumentItemInfo(exportDocDownloadType: type, markImage: markImage, markTitle: markTitle)
        return item
    }()

    lazy var docsLongImageItemInfo: ExportDocumentItemInfo = {
        let type: ExportDocumentType = .docsLongImage
        let markImage = UDIcon.getIconByKey(.fileRoundImageColorful, size: CGSize(width: 48, height: 48))
        let markTitle = BundleI18n.SKResource.Doc_Document_ExportImage
        let item = ExportDocumentItemInfo(exportDocDownloadType: type, markImage: markImage, markTitle: markTitle)
        return item
    }()

    lazy var sheetLongImageItemInfo: ExportDocumentItemInfo = {
        let type: ExportDocumentType = .sheetLongImage
        let markImage = UDIcon.getIconByKey(.fileRoundImageColorful, size: CGSize(width: 48, height: 48))
        let markTitle = BundleI18n.SKResource.Doc_Document_ExportLongImage
        let item = ExportDocumentItemInfo(exportDocDownloadType: type, markImage: markImage, markTitle: markTitle)
        return item
    }()

    lazy var sheetCardImageItemInfo: ExportDocumentItemInfo = {
        let type: ExportDocumentType = .sheetLongImage
        let markImage = UDIcon.getIconByKey(.fileRoundImageColorful, size: CGSize(width: 48, height: 48))
        let markTitle = BundleI18n.SKResource.CreationMobile_Sheets_Pic
        let item = ExportDocumentItemInfo(exportDocDownloadType: type, markImage: markImage, markTitle: markTitle)
        return item
    }()

    lazy var sheetCardTextItemInfo: ExportDocumentItemInfo = {
        let type: ExportDocumentType = .sheetText
        let markImage = UDIcon.getIconByKey(.fileRoundTextColorful, size: CGSize(width: 48, height: 48))
        let markTitle = BundleI18n.SKResource.CreationMobile_Sheets_Text
        let item = ExportDocumentItemInfo(exportDocDownloadType: type, markImage: markImage, markTitle: markTitle)
        return item
    }()

    lazy var itemsInfo: [ExportDocumentItemInfo] = {
        if docsInfo.inherentType == .doc || docsInfo.inherentType == .docX {
            return !isFromSpaceList && !hideLongPicAlways ? [wordItemInfo, pdfItemInfo, docsLongImageItemInfo] : [wordItemInfo, pdfItemInfo]
        } else if docsInfo.inherentType == .sheet {
            var items = [excelItemInfo]
            if !isFromSpaceList && !hideLongPicAlways {
                items.append(sheetLongImageItemInfo)
            }
            if isSheetCardMode {
                items = [sheetCardImageItemInfo, sheetCardTextItemInfo]
            }
            return items
        }
        return []
    }()
}

extension ExportDocumentViewModel {
    ///导出长图
    private func _exportLongImage(_ type: ExportDocumentType, docsInfo: DocsInfo) {
        if type == .sheetLongImage {
            let params: [String: Any] = ["id": type.rawValue]
            DocsLogger.info("ExportDocumentViewModel 处理sheet导出, params: \(params)")
            proxy?.handleExportSheetLongImage(with: params)
        } else if type == .docsLongImage {
            proxy?.handleExportDocsLongImage()
        } else if type == .sheetText {
            proxy?.handleExportSheetText()
        }
        _trackerExportLongImageWithDocsInfo(docsInfo, type: type)
    }

    private func _trackerExportLongImageWithDocsInfo(_ docsInfo: DocsInfo, type: ExportDocumentType) {
        var params: [String: Any] = _trackerExportBaseParamsWithDocsInfo(docsInfo, type: type)
        // 具体成功与否由导出长图内部逻辑上报，这里只是简单描述一下
        params["status_code"] = "0"
        params["status_name"] = "success"
        DocsTracker.log(enumEvent: .clickExport, parameters: params)
    }

    private func _trackerExportBaseParamsWithDocsInfo(_ docsInfo: DocsInfo, type: ExportDocumentType) -> [String: Any] {
        var params: [String: Any] = [:]
        params["file_id"] = docsInfo.encryptedObjToken
        params["file_type"] = "\(docsInfo.type.name)"
        params["is_owner"] = docsInfo.isOwner ? "true" : "false"
        params["module"] = isFromSpaceList ? "space" : docsInfo.type.name
        params["source"] = isFromSpaceList ? "context_menu" : "top_menu"
        params["is_editor"] = isEditor ? "true" : "false"
        params["export_file_type"] = type.reportDescription
        params["export_file_amount"] = "1" //默认只能导出一个
        return params
    }
}
