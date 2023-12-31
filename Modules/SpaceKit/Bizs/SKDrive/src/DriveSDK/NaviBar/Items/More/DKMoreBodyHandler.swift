//
//  DKMoreBodyHandler.swift
//  SpaceKit
//
//  Created by Weston Wu on 2020/6/16.
//  swiftlint:disable cyclomatic_complexity

import UIKit
import LarkUIKit
import EENavigator
import SKCommon
import SKResource
import UniverseDesignActionPanel

class DKNaviBarBodyHandler: TypedRouterHandler<DKNaviBarBody> {

    override func handle(_ body: DKNaviBarBody, req: Request, res: Response) {
        switch body.bodyType {
        case .unknown:
            assertionFailure("Use subclass of DKNaviBarBody and override bodyType property")
            res.end(resource: nil)
        case .more:
            guard let moreBody = body as? DKNaviBarMoreBody else {
                assertionFailure("Use subclass of DKNaviBarBody and override bodyType property")
                res.end(resource: nil)
                return
            }
            let moreHandler = DKNaviBarMoreBodyHandler()
            moreHandler.handle(moreBody, req: req, res: res)
        }
    }

}

class DKNaviBarMoreBodyHandler: TypedRouterHandler<DKNaviBarMoreBody> {
    override func handle(_ body: DKNaviBarMoreBody, req: Request, res: Response) {
        var popSource: UDActionSheetSource?
        if let sourceView = body.sourceView {
            popSource = UDActionSheetSource(sourceView: sourceView, sourceRect: body.sourceRect ?? .zero)
        }
        let moreVC = UDActionSheet.actionSheet(popSource: popSource, autoDissmissWhenChangeStatus: true)
        body.items.forEach { item in
            let itemTitle = title(for: item, body: body)
            if item.type == .cancel {
                moreVC.addItem(text: itemTitle.text, style: .cancel)
            } else {
                if item.type == .saveToSpace && body.saveState == .unable {
                    // 无法保存到云空间时，不添加 saveToSpace 到 actionSheet 中
                    return
                }
                moreVC.addItem(text: itemTitle.text, textColor: itemTitle.textColor) {
                    item.handler(body.sourceView, body.sourceRect)
                }
            }
        }
        res.end(resource: moreVC)
    }

    private func title(for item: DKMoreItem, body: DKNaviBarMoreBody) -> (text: String, textColor: UIColor?) {
        let disableColor = UIColor.ud.N900.withAlphaComponent(DKConstant.disabledTextAlpha)
        switch item.type {
        case .openWithOtherApp:
            let canOpen = (item.itemState == .normal)
            let color = canOpen ? nil : disableColor
            return (BundleI18n.SKResource.Drive_Drive_OpenWithOtherApps, color)
        case .saveToSpace:
            switch body.saveState {
            case .unsave:
                let canOpen = (item.itemState == .normal)
                let color = canOpen ? nil : disableColor
                return (BundleI18n.SKResource.Drive_Drive_SaveToSpace, color)
            case .saved:
                return (BundleI18n.SKResource.Drive_Sdk_ViewInSpace, nil)
            case .unable:
                return ("", nil)
            }
        case .loopupInChat:
            return (BundleI18n.SKResource.Drive_Sdk_ViewInChat, nil)
        case .forward:
            return (BundleI18n.SKResource.Drive_Sdk_Forward, nil)
        case .forwardToChat:
            return (BundleI18n.SKResource.Drive_Drive_ShareToChat, nil)
        case .saveToFile:
            let canOpen = (item.itemState == .normal)
            let color = canOpen ? nil : disableColor
            return (BundleI18n.SKResource.Drive_Drive_SaveToFile, color)
        case .saveToAlbum:
            let canOpen = (item.itemState == .normal)
            let color = canOpen ? nil : disableColor
            return (BundleI18n.SKResource.Doc_Facade_SaveToAlbum, color)
        case let .importAsOnlineFile(type):
            let title: String
            if type.canImportAsDocs {
                title = BundleI18n.SKResource.Doc_Facade_ImportAsDoc
            } else if type.canImportAsSheet {
                title = BundleI18n.SKResource.Doc_Facade_ImportAsSheet
            } else if type.canImportAsMindnote {
                title = BundleI18n.SKResource.Doc_Facade_ImportAsMindnote
            } else {
                // 未知类型统一返回文档
                title = BundleI18n.SKResource.Doc_Facade_ImportAsDoc
            }
            let canOpen = (item.itemState == .normal)
            let color = canOpen ? nil : disableColor
            return (title, color)
        case .cancel:
            return (BundleI18n.SKResource.Drive_Drive_Cancel, nil)
        case .saveToLocal:
            let canOpen = (item.itemState == .normal)
            let color = canOpen ? nil : disableColor
            return (BundleI18n.SKResource.CreationMobile_ECM_SaveToLocal_option, color)
        case .customUserDefine:
            return (item.text, item.textColor)
        }
    }
}
