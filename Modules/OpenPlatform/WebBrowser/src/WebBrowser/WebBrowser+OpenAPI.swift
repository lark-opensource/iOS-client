//
//  WebBrowser+Meta.swift
//  WebBrowser
//
//  Created by luogantong on 2022/5/18.
//

import Foundation

public extension WebBrowser {
    func updateMetas(metas:[Dictionary<String, Any>]){
        let webMetaExtensionItem = self.resolve(WebMetaExtensionItem.self)
        if let item = webMetaExtensionItem {
            item.updateMetas(metas: metas)
        }
    }
    
    func getContainerContext() -> [String : Any]{
        var context = [String : Any]()
        context["containerScene"] = self.configuration.scene.rawValue
        context["fromScene"] = self.configuration.fromScene.rawValue
        return context
    }
}
