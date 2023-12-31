//
//  WABridgeName+Define.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/12/3.
//

import Foundation

//MARK: BriageService For Base Plugin
extension WABridgeName {
    
    // Util
    public static let logger = WABridgeName("tt.util.logger")
    public static let getBaseInfo = WABridgeName("tt.util.getBaseInfo")
    
    // Open
    public static let loadFinish = WABridgeName("tt.open.loadFinish")
    public static let documentReady = WABridgeName("tt.open.documentReady")
    
    // User
    public static let getUserInfo = WABridgeName("tt.user.getUserInfo")
}

//MARK: BriageService For UI Plugin
extension WABridgeName {
    //interaction
    public static let showToast = WABridgeName("tt.interaction.showToast")
    public static let hideToast = WABridgeName("tt.interaction.hideToast")
    
    //titlebar
    public static let setTitle = WABridgeName("tt.titlebar.setTitle")
    public static let configTitleBar = WABridgeName("tt.titlebar.config")
    
    //navigation
    public static let closePage = WABridgeName("tt.navigation.closePage")
    public static let refreshPage = WABridgeName("tt.navigation.refresh")
    
    public static let showMenu = WABridgeName("tt.ui.showMoreMenu")
    
    public static let openUserProfile = WABridgeName("tt.user.openProfile")
    
    public static let openChat = WABridgeName("tt.chat.open")
}
