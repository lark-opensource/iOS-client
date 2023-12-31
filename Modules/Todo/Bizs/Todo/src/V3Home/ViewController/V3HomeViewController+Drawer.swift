//
//  V3HomeViewController+Drawer.swift
//  Todo
//
//  Created by wangwanxin on 2022/8/25.
//

import Foundation
import UniverseDesignDrawer
import LarkNavigation
import LarkTab

// MARK: - Home - Drawer

extension V3HomeViewController {

    func registerDrawer() {
        guard case .center = context.scene else { return }
        SideBarMenuSourceFactory.register(
            tab: Tab.todo,
            contentPercentProvider: { _, type in
                var needCustom = false
                switch type {
                case .click(let string):
                    needCustom = string == V3Home.drawerTag
                case .pan:
                    needCustom = true
                default: needCustom = false
                }
                return needCustom ? 0.78 : UDDrawerValues.contentDefaultPercent
            },
            subCustomVCProvider: { [weak self] (_, type, _) in
                guard let self = self else { return nil }
                var needCustom = false
                switch type {
                case .click(let string):
                    if string == V3Home.drawerTag {
                        needCustom = true
                    }
                case .pan:
                    needCustom = true
                default: needCustom = false
                }
                return needCustom ? self.fg.boolValue(for: .organizableTaskList) ? self.sidebarModule : self.drawerModule : nil
            }
        )
    }
}
