//
//  LarkSplitViewController+KeyCommand.swift
//  LarkSplitViewController
//
//  Created by Yaoguoguo on 2022/8/29.
//

import Foundation
import UIKit
import LarkKeyCommandKit

extension SplitViewController {
    /// 返回快捷键的容器
    public override func keyCommandContainers() -> [LarkKeyCommandKit.KeyCommandContainer] {
        if let present = self.presentedViewController {
            return present.keyCommandContainers()
        }
        var containers: [KeyCommandContainer] = [self]
        if self.isCollapsed {
            containers += self.getCompactVC()?.keyCommandContainers() ?? []
        } else {
            let hasSupplementary = childrenVC[.supplementary] != nil
            switch self.splitMode {
            case .sideOnly:
                containers += childrenVC[.supplementary]?.keyCommandContainers() ?? []
                containers += childrenVC[.primary]?.keyCommandContainers() ?? []
            case .secondaryOnly:
                containers += childrenVC[.secondary]?.keyCommandContainers() ?? []
            case .oneBesideSecondary, .oneOverSecondary:
                containers += childrenVC[.secondary]?.keyCommandContainers() ?? []
                if hasSupplementary {
                    containers += childrenVC[.supplementary]?.keyCommandContainers() ?? []
                } else {
                    containers += childrenVC[.primary]?.keyCommandContainers() ?? []
                }
            case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
                containers += childrenVC[.secondary]?.keyCommandContainers() ?? []
                containers += childrenVC[.supplementary]?.keyCommandContainers() ?? []
                containers += childrenVC[.primary]?.keyCommandContainers() ?? []
            }
        }
        return containers
    }

    public override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + getKeyCommand()
    }

    // command+control+f：全屏/半屏切换
    func getKeyCommand() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(
                input: "f",
                modifierFlags: [.command, .control],
                discoverabilityTitle: BundleI18n.LarkSplitViewController.Lark_Settings_ShortcutsEnterExitFullScreen
            ).binding(
                tryHandle: { (_) -> Bool in
                    // lastDetailVC不为空 && 支持detail页面全屏 && (支持全屏快捷键 || 自动添加全屏按钮) && (当前是双栏模式 || 是detail全屏模式)
                    if let lastDetailVC = self.topMost,
                       lastDetailVC.supportSecondaryOnly,
                       (lastDetailVC.keyCommandToFullScreen || lastDetailVC.autoAddSecondaryOnlyItem),
                       !self.isCollapsed {
                        return true
                    } else {
                        return false
                    }
                },
                target: self,
                selector: #selector(switchFullScreenKeyCommand)
            ).wraper
        ]
    }

    @objc
    func switchFullScreenKeyCommand() {
        if splitMode == .secondaryOnly {
            self.updateBehaviorAndSplitMode(behavior: self.splitBehavior,
                                            splitMode: .twoBesideSecondary,
                                            animated: true)
        } else {
            self.updateBehaviorAndSplitMode(behavior: self.splitBehavior,
                                            splitMode: .secondaryOnly,
                                            animated: true)
        }
    }
}
