//
//  BTFilterConjunctionPanel.swift
//  SKBitable
//
//  Created by X-MAN on 2023/4/26.
//

import Foundation
import HandyJSON
import SKResource
import SKFoundation
import SpaceInterface

struct BTFilterConjunctionPanelModel: BTDDUIPlayload, Codable {
    var title: BTTitleWidgetModel?
    var datas: [BTConditionEditModel]?
}

final class BTFilterConjunctionPanelComponent: BTDDUIComponentProtocol {
    typealias UIModel = BTFilterConjunctionPanelModel
    
    var model: BTFilterConjunctionPanelModel?
    var currentVC: BTPanelController?
    let baseContext: BaseContext
    
    init(baseContext: BaseContext) {
        self.baseContext = baseContext
    }
    
    static func convert(from payload: Any?) throws -> BTFilterConjunctionPanelModel {
        guard let payload = payload as? NSDictionary,
              let model = try? CodableUtility.decode(BTFilterConjunctionPanelModel.self, withJSONObject: payload)
        else {
            throw BTDDUIError.payloadInvalid
        }
        return model
    }
    
    func mount(with model: BTFilterConjunctionPanelModel) throws {
        self.model = model
        let title = model.title?.centerText?.text ?? BundleI18n.SKResource.Bitable_SingleOption_MeetConditionTitle_Mobile
        guard let hostVC = context?.uiConfig?.hostView.affiliatedViewController else { throw BTDDUIError.componentMountFailed }
        let datas = model.datas?.map({ item in
            return item.convertCommonDataItem { [weak self] _, _, _ in
                if let callbackId = item.onClick {
                    self?.emitEvent(callbackId: callbackId, args: [:])
                }
            }
        }) ?? []
        let controller = BTPanelController(title: title,
                                           data: BTCommonDataModel(groups: [BTCommonDataGroup(groupName: "filter",
                                                                                              items: datas)]),
                                           delegate: nil,
                                           hostVC: hostVC, baseContext: baseContext)
        controller.automaticallyAdjustsPreferredContentSize = false
        BTNavigator.presentSKPanelVCEmbedInNav(controller, from: UIViewController.docs.topMost(of: hostVC) ?? hostVC)
        controller.popoverDisappearBlock = { [weak self] in
            self?.onUnmounted()
            self?.currentVC = nil
        }
        self.onMounted()
        currentVC = controller
    }
    
    func setData(with model: BTFilterConjunctionPanelModel) throws {
        
    }
    
    
    func unmount() {
        currentVC?.dismiss(animated: true)
    }
    
}
