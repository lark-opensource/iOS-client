//
//  PanelBrowserViewConfig.swift
//  EcosystemWeb
//
//  Created by jiangzhongping on 2022/9/1.
//

import UIKit

public enum PanelBrowserStyle: String {
    case low
    case medium
    case high
    
    var styleHeight: Double {
        var rate = 0.86
        switch self {
        case .high:
            rate = 0.86
        case .medium:
            rate = 0.65
        case .low:
            rate = 0.45
        }
        let height = max(300.0, ceil(UIScreen.main.bounds.size.height * rate))
        return height
    }
}

public final class PanelBrowserConfig: NSObject {
    
    private struct Const {
        static let PanelModeKey = "mode"
        static let PanelStyleKey = "panel_style"
        static let PanelSceneKey = "scene"
        static let PanelFromIMOpenBiz = "from_im_open_biz"
    }
    
    public var panelStyle = PanelBrowserStyle.high
    public var scene = ""
    public var mode = ""
    public var fromIMOpenBiz = false
    
    public init(params: Dictionary<String, String>?) {
        
        if let params = params {
            if let mode = params[Const.PanelModeKey] as? String {
                self.mode = mode
            }
            if let scene = params[Const.PanelSceneKey] as? String {
                self.scene = scene
            }
            if let panelStyleString = params[Const.PanelStyleKey] as? String, let panelStyle = PanelBrowserStyle(rawValue: panelStyleString.trimmingCharacters(in: CharacterSet.whitespaces)) {
                self.panelStyle = panelStyle
            }
            if let fromIMOpenBiz = params[Const.PanelFromIMOpenBiz] as? Bool {
                self.fromIMOpenBiz = fromIMOpenBiz
            }
        }
        super.init()
    }
    
    public func usePanel() -> Bool {
        return self.mode == "panel"
    }
}
