//
//  WAContainerViewModel+Plugin.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/16.
//

import Foundation

extension WAContainerViewModel {
    
    func reigisterBasePlugins() {
        self.pluginManager.register(plugin: BaseBridgePlugin(host: self))
        self.pluginManager.register(plugin: OpenURLPlugin(host: self))
        self.pluginManager.register(plugin: BaseInfoPlugin(host: self))
    }
    
    func reigisterUIPlugins() {
        self.pluginManager.register(plugin: UIBridgePlugin(host: self))
        self.pluginManager.register(plugin: TitleBarPlugin(host: self))
        self.pluginManager.register(plugin: MoreMenuPlugin(host: self))
        self.pluginManager.register(plugin: OpenUserProfilePlugin(host: self))
        self.pluginManager.register(plugin: ChatPlugin(host: self))
        self.pluginManager.register(plugin: PagePlugin(host: self))
    }
}
