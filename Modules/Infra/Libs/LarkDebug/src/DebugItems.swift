//
//  FlexDebugItem.swift
//  LarkDebug
//
//  Created by CharlieSu on 11/25/19.
//

import UIKit
import LarkDebugExtensionPoint
#if !LARK_NO_DEBUG
import Foundation
import EEPodInfoDebugger
import EENavigator
import Logger
import UniverseDesignToast
import LarkSensitivityControl

#if canImport(FLEX)
import FLEX

struct FlexDebugItem: DebugCellItem {
    let title: String = "Flex"
    let type: DebugCellType = .switchButton

    var isSwitchButtonOn: Bool { return !FLEXManager.shared.isHidden }

    let switchValueDidChange: ((Bool) -> Void)? = { (isOn: Bool) in
        if isOn {
            if #available(iOS 13.0, *), let scene = UIApplication.shared.keyWindow?.windowScene {
                FLEXManager.shared.showExplorer(from: scene)
            } else {
                FLEXManager.shared.showExplorer()
            }
        } else {
            FLEXManager.shared.hideExplorer()
        }
    }
}
#endif

struct OverlayDebugItem: DebugCellItem {
    let title: String = "Overlay"
    let type: DebugCellType = .switchButton

    let isSwitchButtonOn = false

    let switchValueDidChange: ((Bool) -> Void)? = { (isOn: Bool) in
        if isOn {
            if let aClass = NSClassFromString("DebugOverlay") {
                let sel = NSSelectorFromString("toggleOverlay")
                 if let myClass = aClass as AnyObject as? NSObjectProtocol {
                    if myClass.responds(to: sel) {
                        myClass.perform(sel)
                    }
                 }
            }
        }
    }
}

private var fpsMonitor: FPSMonitor?
struct FPSDebugItem: DebugCellItem {
    let title = "FPS监测"
    let type: DebugCellType = .switchButton

    var isSwitchButtonOn: Bool { return fpsMonitor != nil }

    var switchValueDidChange: ((Bool) -> Void)?

    init() {
        self.switchValueDidChange = { (isOn: Bool) in
            if isOn {
                fpsMonitor?.close()
                fpsMonitor = FPSMonitor()
                fpsMonitor?.updateInterval = 0.25
                fpsMonitor?.open()
            } else {
                fpsMonitor?.close()
                fpsMonitor = nil
            }
        }
    }
}

struct CommitInfo: DebugCellItem {
    var title: String { return "Build commit (Top 3)" }
    var detail: String {
        DebugPodInfoForwarding.buildCommits
    }

    var type: DebugCellType { return .none }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Self.writeToBoard(detail, debugVC: debugVC)
    }
}

struct XcodeInfo: DebugCellItem {
    var title: String { return "Xcode version" }
    var detail: String { return version() }

    var type: DebugCellType { return .none }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Self.writeToBoard(detail, debugVC: debugVC)
    }

    @inline(__always)
    private func version() -> String {
        Bundle.main.infoDictionary?["DTXcodeBuild"] as? String ?? "unknown"
    }
}

struct PodInfoItem: DebugCellItem {
    var title: String { return "Pod Infos" }

    var type: DebugCellType { return .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Navigator.shared.push(DebugPodInfoForwarding.controller { content in //Global
            Self.writeToBoard(content, debugVC: debugVC)
        }, from: debugVC)
    }
}

struct MacConsoleDebugItem: DebugCellItem {
    var title: String { return "MacConsole (via USB)" }
    let type: DebugCellType = .switchButton

    var isSwitchButtonOn: Bool { return false }

    let switchValueDidChange: ((Bool) -> Void)? = { (isOn: Bool) in
        if isOn {
            Logger.add(appender: MacConsoleAppender.shared)
        } else {
            Logger.remove(appenderType: MacConsoleAppender.self)
        }
    }
}

struct SDKProxyInfoItem: DebugCellItem {
    var title: String { return "SDK Proxy" }

    var type: DebugCellType { return .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Navigator.shared.push(SDKProxyDebugController(), from: debugVC)  //Global
    }
}

struct SandboxItem: DebugCellItem {
    var title: String { return "沙盒浏览" }

    var type: DebugCellType { return .disclosureIndicator }

    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        Navigator.shared.push(SandboxViewController(), from: debugVC)  //Global
    }
}
#endif

extension DebugCellItem {

    public static func writeToBoard(_ string: String, debugVC: UIViewController? = nil) {
        #if !LARK_NO_DEBUG
        UIPasteboard.general.string = string
        if let debugVC = debugVC {
            UDToast.showTips(with: "Copied", on: debugVC.view, delay: 1.5)
        }
        #endif
    }
}
