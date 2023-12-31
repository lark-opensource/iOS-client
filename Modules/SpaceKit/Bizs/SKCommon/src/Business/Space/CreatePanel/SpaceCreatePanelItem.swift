//
//  SpaceCreatePanelItem.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/1/14.
//

import Foundation
import RxSwift
import RxRelay
import SKResource
import SKFoundation
import LarkLocalizations
import UniverseDesignIcon
import SKInfra
import LarkDocsIcon

public struct SpaceCreatePanelItem {

    public struct CreateEvent {
        public let createController: UIViewController
        public let itemEnable: Bool

        public init(createController: UIViewController, itemEnable: Bool) {
            self.createController = createController
            self.itemEnable = itemEnable
        }
    }

    public let enableState: Observable<Bool>
    public let title: String
    public let icon: UIImage
    public let clickHandler: (CreateEvent) -> Void
    public let itemType: CreateItemType
    public init(enableState: Observable<Bool>,
                title: String,
                icon: UIImage,
                clickHandler: @escaping (CreateEvent) -> Void,
                itemType: CreateItemType = .other) {
        self.enableState = enableState
        self.title = title
        self.icon = icon
        self.clickHandler = clickHandler
        self.itemType = itemType
    }
}

public enum CreateItemType {
    case doc
    case docx
    case other
}

public extension SpaceCreatePanelItem {

    private typealias T = BundleI18n.SKResource

    typealias CreateHandler = (CreateEvent) -> Void

    // Lark 和单品使用的创建icon不一致，需要区分
    enum Lark {
        private static let iconSize = CGSize(width: 28, height: 28)
        static func docs(clickHandler: @escaping CreateHandler) -> SpaceCreatePanelItem {
            let icon = UDIcon.getIconByKey(.fileDocColorful, size: iconSize)
            return SpaceCreatePanelItem(enableState: .just(true), title: T.Doc_Facade_Document, icon: icon, clickHandler: clickHandler, itemType: .doc)
        }

        static func docX(enableState: Observable<Bool> = .just(true), clickHandler: @escaping CreateHandler) -> SpaceCreatePanelItem {
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
            return SpaceCreatePanelItem(enableState: enableState, title: title, icon: icon, clickHandler: clickHandler, itemType: .docx)
        }

        static func sheet(enableState: Observable<Bool> = .just(true), clickHandler: @escaping CreateHandler) -> SpaceCreatePanelItem {
            let icon = UDIcon.getIconByKey(.fileSheetColorful, size: iconSize)
            return SpaceCreatePanelItem(enableState: enableState, title: T.Doc_Facade_CreateSheet, icon: icon, clickHandler: clickHandler)
        }

        static func mindNote(enableState: Observable<Bool>, clickHandler: @escaping CreateHandler) -> SpaceCreatePanelItem {
            let icon = UDIcon.getIconByKey(.fileMindnoteColorful, size: iconSize)
            return SpaceCreatePanelItem(enableState: enableState, title: T.Doc_Facade_MindNote, icon: icon, clickHandler: clickHandler)
        }

        static func bitable(enableState: Observable<Bool>, clickHandler: @escaping CreateHandler) -> SpaceCreatePanelItem {
            var icon: UIImage
            if UserScopeNoChangeFG.QYK.btSquareIcon {
                icon = LarkDocsIconForBase.Base.base_default_icon
            } else {
                icon = UDIcon.getIconByKey(.fileBitableColorful, size: iconSize)
            }
            return SpaceCreatePanelItem(enableState: enableState, title: T.Doc_Facade_Bitable, icon: icon, clickHandler: clickHandler)
        }

        static func nonSquareBase(enableState: Observable<Bool>, clickHandler: @escaping CreateHandler) -> SpaceCreatePanelItem {
            let icon = UDIcon.getIconByKey(.fileBitableColorful, size: iconSize)
            return SpaceCreatePanelItem(enableState: enableState, title: T.Doc_Facade_Bitable, icon: icon, clickHandler: clickHandler)
        }

        static func folder(enableState: Observable<Bool>, clickHandler: @escaping CreateHandler) -> SpaceCreatePanelItem {
            let icon = UDIcon.getIconByKey(.fileFolderColorful, size: iconSize)
            return SpaceCreatePanelItem(enableState: enableState, title: T.Doc_Facade_Folder, icon: icon, clickHandler: clickHandler)
        }

        static func uploadImage(enableState: Observable<Bool>, clickHandler: @escaping CreateHandler) -> SpaceCreatePanelItem {
            let icon = UDIcon.getIconByKey(.fileImageColorful, size: iconSize)
            return SpaceCreatePanelItem(enableState: enableState, title: T.CreationMobile_Docs_UploadImage_Tab, icon: icon, clickHandler: clickHandler)
        }

        static func uploadFile(enableState: Observable<Bool>, clickHandler: @escaping CreateHandler) -> SpaceCreatePanelItem {
            let icon = UDIcon.getIconByKey(.uploadfile2Colorful, size: iconSize)
            return SpaceCreatePanelItem(enableState: enableState, title: T.CreationMobile_Docs_UploadFile_Tab, icon: icon, clickHandler: clickHandler)
        }
        
        static func bitableSurvey(enableState: Observable<Bool>, clickHandler: @escaping CreateHandler) -> SpaceCreatePanelItem {
            let icon: UIImage = UDIcon.getIconByKey(.fileFormColorful, size: iconSize)
            let title = BundleI18n.SKResource.Bitable_Homepage_New_Form_Button
            return SpaceCreatePanelItem(enableState: enableState, title: title, icon: icon, clickHandler: clickHandler)
        }
    }
}
