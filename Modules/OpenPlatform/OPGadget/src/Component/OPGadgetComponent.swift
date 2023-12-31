//
//  OPGadgetComponent.swift
//  OPGadget
//
//  Created by yinyuan on 2020/11/27.
//

import Foundation
import OPSDK

class OPGadgetComponent: OPNode, OPComponentProtocol {
    
    let bridge: OPBridgeProtocol
    
    var context: OPComponentContext
    
    private var fileReader: OPPackageReaderProtocol
    
    required init(fileReader: OPPackageReaderProtocol, context: OPContainerContext) {
        self.fileReader = fileReader
        self.context = OPComponentContext(context: context)
        self.bridge = OPBaseBridge()
    }
    
    func render(slot: OPViewRenderSlot, data: OPComponentDataProtocol) throws {
        
    }
    
    func addLifeCycleListener(listener: OPComponentLifeCycleProtocol) {
        
    }
    
    func update(data: OPComponentTemplateDataProtocol) throws {
        
    }
    
    func onShow() {
        
    }
    
    func onHide() {
        
    }
    
    func onDestroy() {
        
    }

    func reRender() {

    }
}
