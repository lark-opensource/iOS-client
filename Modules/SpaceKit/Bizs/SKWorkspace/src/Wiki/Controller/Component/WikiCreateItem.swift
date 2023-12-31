//
//  WikiCreateItem.swift
//  SKWikiV2
//
//  Created by Weston Wu on 2021/12/16.
//

import UniverseDesignIcon
import SKResource
import SKCommon
import LarkLocalizations
import SKInfra
import LarkDocsIcon
import SKFoundation

public struct WikiCreateItem {
    public enum ItemType {
        case docx
        case doc
        case other
    }
    let title: String
    let icon: UIImage
    var enable: Bool
    var itemType: ItemType = .other
    let action: () -> Void

    private static let iconSize = CGSize(width: 28, height: 28)
    private typealias T = BundleI18n.SKResource
    
    public init(title: String, icon: UIImage, enable: Bool, itemType: ItemType = .other, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.enable = enable
        self.itemType = itemType
        self.action = action
    }

    public static func docs(enable: Bool, action: @escaping () -> Void) -> WikiCreateItem {
        let icon = UDIcon.getIconByKey(.fileDocColorful, size: iconSize)
        return WikiCreateItem(title: T.Doc_Facade_Document, icon: icon, enable: enable, itemType: .doc, action: action)
    }

    public static func docX(enable: Bool, action: @escaping () -> Void) -> WikiCreateItem {
        // docX的名字需要做成可配置, 优先读mina，兜底用 doc 的名字
        let title: String
        if let minaName = SettingConfig.docxMinaName {
            if let currentLanguageCode = LanguageManager.currentLanguage.languageCode,
               let remoteName = minaName[currentLanguageCode] {
                // 优先读当前地区的名字
                title = remoteName
            } else if let enName = minaName["en"] as? String {
                // 读不到当前地区的名字，尝试读英文名兜底
                title = enName
            } else {
                // 都读不到用 docs 兜底
                title = T.Doc_Facade_Document
            }
        } else {
            // 读 mina 失败，用 docs 兜底
            title = T.Doc_Facade_Document
        }

        let icon = UDIcon.getIconByKey(.fileDocxColorful, size: iconSize)
        return WikiCreateItem(title: title, icon: icon, enable: enable, itemType: .docx, action: action)
    }

    public static func sheet(enable: Bool, action: @escaping () -> Void) -> WikiCreateItem {
        let icon = UDIcon.getIconByKey(.fileSheetColorful, size: iconSize)
        return WikiCreateItem(title: T.Doc_Facade_CreateSheet, icon: icon, enable: enable, action: action)
    }

    public static func mindnote(enable: Bool, action: @escaping () -> Void) -> WikiCreateItem {
        let icon = UDIcon.getIconByKey(.fileMindnoteColorful, size: iconSize)
        return WikiCreateItem(title: T.Doc_Facade_MindNote, icon: icon, enable: enable, action: action)
    }

    public static func bitable(enable: Bool, action: @escaping () -> Void) -> WikiCreateItem {
        var icon: UIImage
        if UserScopeNoChangeFG.QYK.btSquareIcon {
            icon = LarkDocsIconForBase.Base.base_default_icon
        } else {
            icon = UDIcon.getIconByKey(.fileBitableColorful, size: iconSize)
        }
        return WikiCreateItem(title: T.Doc_Facade_Bitable, icon: icon, enable: enable, action: action)
    }

    // 非新版方形的 Base 样式，用于需要和其他文档类型保持一致的场景
    public static func nonSquareBase(enable: Bool, action: @escaping () -> Void) -> WikiCreateItem {
        let icon = UDIcon.getIconByKey(.fileBitableColorful, size: iconSize)
        return WikiCreateItem(title: T.Doc_Facade_Bitable, icon: icon, enable: enable, action: action)
    }
    
    public static func bitableSurvey(enable: Bool, action: @escaping () -> Void) -> WikiCreateItem {
        var icon: UIImage
        icon = UDIcon.getIconByKey(.fileFormColorful, size: iconSize)
        let title = BundleI18n.SKResource.Bitable_Homepage_New_Form_Button
        return WikiCreateItem(title: title, icon: icon, enable: enable, action: action)
    }
    
    public static func uploadImage(enable: Bool, action: @escaping () -> Void) -> WikiCreateItem {
        let icon = UDIcon.getIconByKey(.fileImageColorful, size: iconSize)
        return WikiCreateItem(title: T.CreationMobile_Docs_UploadImage_Tab, icon: icon, enable: enable, action: action)
    }

    public static func uploadFile(enable: Bool, action: @escaping () -> Void) -> WikiCreateItem {
        let icon = UDIcon.getIconByKey(.uploadfile2Colorful, size: iconSize)
        return WikiCreateItem(title: T.CreationMobile_Docs_UploadFile_Tab, icon: icon, enable: enable, action: action)
    }
}

public extension WikiCreateItem {
    var createPanelItem: SpaceCreatePanelItem {
        SpaceCreatePanelItem(enableState: .just(enable),
                             title: title,
                             icon: icon) { event in
            event.createController.dismiss(animated: true, completion: action)
        }
    }
}
