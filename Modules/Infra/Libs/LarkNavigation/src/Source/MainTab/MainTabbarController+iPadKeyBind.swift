//
//  MainTabbarController+iPadKeyBind.swift
//  LarkNavigation
//
//  Created by 袁平 on 2021/1/22.
//

import Foundation
import LarkKeyCommandKit
import LarkTab
import AnimatedTabBar

// iPad KeyBind
extension MainTabbarController {
    func switchTabKeyCommand() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(input: "1", modifierFlags: .command).binding(handler: { [weak self] in
                self?.switchTab(index: 1)
            }).wraper,
            KeyCommandBaseInfo(input: "2", modifierFlags: .command).binding(handler: { [weak self] in
                self?.switchTab(index: 2)
            }).wraper,
            KeyCommandBaseInfo(input: "3", modifierFlags: .command).binding(handler: { [weak self] in
                self?.switchTab(index: 3)
            }).wraper,
            KeyCommandBaseInfo(input: "4", modifierFlags: .command).binding(handler: { [weak self] in
                self?.switchTab(index: 4)
            }).wraper,
            KeyCommandBaseInfo(input: "5", modifierFlags: .command).binding(handler: { [weak self] in
                self?.switchTab(index: 5)
            }).wraper,
            KeyCommandBaseInfo(input: "6", modifierFlags: .command).binding(handler: { [weak self] in
                self?.switchTab(index: 6)
            }).wraper,
            KeyCommandBaseInfo(input: "7", modifierFlags: .command).binding(handler: { [weak self] in
                self?.switchTab(index: 7)
            }).wraper,
            KeyCommandBaseInfo(input: "8", modifierFlags: .command).binding(handler: { [weak self] in
                self?.switchTab(index: 8)
            }).wraper,
            KeyCommandBaseInfo(input: "9", modifierFlags: .command).binding(handler: { [weak self] in
                self?.switchTab(index: 9)
            }).wraper,
            KeyCommandBaseInfo(input: "l", modifierFlags: [.command, .shift],
                               discoverabilityTitle: BundleI18n.LarkNavigation.Lark_Shortcuts_ExpandMoreInNavbar_Text)
            .binding(handler: { [weak self] in
                self?.openMoreItem()
            }).wraper,
            KeyCommandBaseInfo(input: "t", modifierFlags: [.command, .shift],
                               discoverabilityTitle: BundleI18n.LarkNavigation.Lark_Shortcuts_ReopenTab_Text)
            .binding(handler: { [weak self] in
                self?.reopenClosedTemporaryTab()
            }).wraper
        ]
    }

    private func switchTab(index: Int) {
        switchMainTab(to: index - 1)
    }

    private func openMoreItem() {
        switch tabbarStyle {
        case .edge:
            edgeTab?.openMoreFromKeyCommand()
        case .bottom: // C 视图不响应快捷键
            break
        @unknown default:
            break
        }
    }
    
    private func findSameTabIn(items: [AbstractTabBarItem], with tab: TabCandidate) -> AbstractTabBarItem? {
        return items.first { item in
            if let tabbarItem = item as? TabBarItem {
                return tabbarItem.tranformTo().id == tab.id
            }
            return false
        }
    }

    func reopenClosedTemporaryTab() {
        switch tabbarStyle {
        case .edge:
            if let closeTabString = closeTemporaryTab.pop() {
                let context = [NavigationKeys.launcherFrom: NavigationKeys.LauncherFrom.temporary]
                self.temporaryTabService.showTab(url:closeTabString, context: context)
            }
        case .bottom: // C 视图不响应
            break
        @unknown default:
            break
        }
    }
}
