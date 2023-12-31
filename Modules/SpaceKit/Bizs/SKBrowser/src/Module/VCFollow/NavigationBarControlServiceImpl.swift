//
// Created by duanxiaochen.7 on 2021/6/1.
// Affiliated with SKBrowser.
//
// Description:

import Foundation
import SKCommon
import SKUIKit
import SpaceInterface

public final class SKNavigationBarControlServiceImpl: SKNavigationBarControlService {

    var oldNavigationMode = SKNavigationBar.NavigationMode.open

    public init() {}

    public func lockNavigationModeRegulated() {
        oldNavigationMode = DocsSDK.navigationMode
        DocsSDK.navigationMode = .allowing(list: [.back, .close, .fullScreenMode, .showInNewScene, .catalog, .done])
    }

    public func restoreNavigationMode() {
        DocsSDK.navigationMode = oldNavigationMode
    }
}
