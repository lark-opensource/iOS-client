//
//  BTDDUIBaseModel.swift
//  SKBitable
//
//  Created by X-MAN on 2023/4/12.
//

import Foundation
import HandyJSON
import SKCommon
import SKBrowser
import UniverseDesignIcon
import SKResource
import SKFoundation
import SpaceInterface

typealias ComponentType = BTDDUIBaseModel.ComponentType
typealias ComponentAction = BTDDUIBaseModel.ComponentAction

enum BTDDUIError: String, Error {
    case paramsInvalid = "paramsInvalid"
    case constructComponentFailed = "constructComponentFailed"
    case payloadInvalid = "payloadInvalid"
    case unmountFailed = "unmountFailed"
    case setDataWithoutComponent = "setDataWithoutComponent"
    case componentAlreadyMounted = "componentAlreadyMounted"
    case componentMountFailed = "componentMountFailed"
    case setDataFailedInvalidData = "setDataFailedInvalidData"
}

struct BTDDUIBaseModel: HandyJSON {
    
    enum ComponentAction: String, HandyJSONEnum {
        case mount
        case unmount
        case setData
    }
    
    enum ComponentType: String, HandyJSONEnum {
        case filterStepPanel
        case filterConjunctionPanel
        case unknown
        case filterLarkFormFieldVisibilityPanel
        case colorPanel
        case formsSharePanel
    }
    
    var componentId: String = ""
    var action: ComponentAction = .mount
    var componentType: ComponentType = .unknown
    var payload: Any? = nil
    var mounted: Bool = false
    var callback: String?
    var onUnmounted: String?
    var onMounted: String?
    
    var commonParams: [String: Any] {
        return [
            "action": action.rawValue,
            "componentId": componentId,
            "componentType": componentType.rawValue,
        ]
    }
}

struct BTDDUIContext {
    var id: String
    var uiConfig: BrowserUIConfig?
    var modelConfig: BrowserModelConfig?
    var navigator: BrowserNavigator?
    var callbackId: String
    
    func emitEvent(_ callbackId: String, args: [String: Any]) {
        let params: [String: Any] = [
            "callbackId": callbackId,
            "options": args
        ]
        self.modelConfig?.jsEngine.callFunction(DocsJSCallBack(self.callbackId), params: params, completion: { _, error in
            if let error = error {
                DocsLogger.btError("[BTDDUIComponentProtocol] callback to web failed error: \(error)")
            }
        })
    }
}



struct BTImageWidgetModel: BTWidgetModelProtocol, Codable, HandyJSON {
    var onClick: String?
    var backgroundColor: String?
    var borderColor: String?
    var udToken: String?
    var url: String?
    var tintColor: String?
    var realKey: String { bitableRealUDKey(self.udToken) ?? "" }
    var image: UIImage? {
        var img = UDIcon.getIconByString(udToken ?? "") ?? UDIcon.getIconByString(realKey)
        if let tintColor = tintColor {
            img = img?.ud.withTintColor(UIColor.docs.rgb(tintColor))
        }
        return img
    }
}

struct BTTextWidgetModel: BTWidgetModelProtocol, Codable, HandyJSON {
    var text: String?
    var placeholder: String?
    var onClick: String?
    var backgroundColor: String?
    var borderColor: String?
    var textColor: String?
}

struct BTTitleWidgetModel: BTWidgetModelProtocol, Codable, HandyJSON {
    var onClick: String?
    var backgroundColor: String?
    var borderColor: String?
    var leftIcon: BTImageWidgetModel?
    var centerText: BTTextWidgetModel?
    var rightText: BTTextWidgetModel?
}

struct BTInputWidgetModel: BTWidgetModelProtocol, Codable, HandyJSON {
    var onClick: String?
    var backgroundColor: String?
    var borderColor: String?
    var placeholder: String?
    var leftIcon: BTImageWidgetModel?
    var onInputChanged: String?
    var text: String?
}

struct BTCheckBoxWidgetModel: BTWidgetModelProtocol, Codable, HandyJSON {
    var onClick: String?
    var backgroundColor: String?
    var borderColor: String?
    var checked: Bool?
}

struct BTTimePickWidgetModel: BTWidgetModelProtocol, Codable {
    var onClick: String?
    var backgroundColor: String?
    var borderColor: String?
    var timeZone: String?
    var timestamp: TimeInterval?
    var timeFormat: String?
    var dateFormat: String?
}

struct BTConditionEditModel: BTWidgetModelProtocol, Codable, HandyJSON {
    var onClick: String?
    var backgroundColor: String?
    var borderColor: String?
    var checked: Bool?
    var isShow: Bool?
    var contentImg: BTImageWidgetModel?
    var contentText: BTTextWidgetModel?
    var rightIcon: BTTextWidgetModel?
    var isSync: Bool?
    
    var fieldCommonData: BTFieldCommonData {
        return BTFieldCommonData(id: "",
                                 name: contentText?.text ?? "",
                                 icon: contentImg?.image,
                                 showLighting: isSync ?? false,
                                 rightIocnType: .arraw,
                                 selectedType: .textHighlight,
                                 isShow: isShow,
                                 callbackId: onClick)
    }
    
    var capsuleModel: BTCapsuleModel {
        let model = BTCapsuleModel(id: "",
                                   text: contentText?.text ?? "",
                                   color: BTColorModel(color: contentText?.backgroundColor ?? "0xFFFFFF",
                                                       textColor: contentText?.textColor ?? "0x000000"),
                                   isSelected: checked ?? false,
                                   isShow: isShow,
                                   callbackId: onClick)
        return model
    }
    
    var linkRecordModel: BTLinkRecordModel {
        let model = BTLinkRecordModel(id: "",
                                      text: self.contentText?.text ?? "",
                                      isSelected: checked ?? false,
                                      isShow: isShow,
                                      callbackId: onClick)
        return model
    }
    
    var chatterModel: MemberItem {
        return MemberItem(identifier: "",
                          selectType: (checked == true) ? .blue : .gray,
                          imageURL: contentImg?.url,
                          title: self.contentText?.text ?? "",
                          detail: nil,
                          token: nil,
                          isExternal: false,
                          displayTag: nil,
                          isCrossTenanet: false,
                          isShow: isShow,
                          callbackId: onClick)
    }
    
    func convertCommonDataItem(with callabck: ((_ cell: BTCommonCell, _ id: String?, _ userInfo: Any?) -> Void)?) -> BTCommonDataItem {
        return BTCommonDataItem(id: "",
                                selectable: true,
                                selectCallback: callabck,
                                leftIcon: .init(image: (checked ?? false) ?
                                                BundleResources.SKResource.Bitable.icon_bitable_selected :
                                                BundleResources.SKResource.Bitable.icon_bitable_unselected,
                                                size: CGSize(width: 20, height: 20)),
                                mainTitle: BTCommonDataItemTextInfo(text: self.contentText?.text))
    }
    
}
