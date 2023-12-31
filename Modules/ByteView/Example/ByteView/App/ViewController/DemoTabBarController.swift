//
//  DemoTabBarController.swift
//  ByteView_Example
//
//  Created by kiri on 2023/8/31.
//

import Foundation
import UIKit
import UniverseDesignTheme
import UniverseDesignIcon
import Swinject
import LarkContainer
import ByteViewUI
import LarkUIKit
import EENavigator
import LarkTab
import LarkAccountInterface
import BootManager

final class DemoTabBarController: UITabBarController, UINavigationControllerDelegate {
    lazy var resolver = Container.shared.getCurrentUserResolver()
    private var vcTopViewBottomConstraint: NSLayoutConstraint?
    override func viewDidLoad() {
        super.viewDidLoad()
        var vcs: [UIViewController] = [
            LkNavigationController(rootViewController: MeetingTestViewController(resolver: resolver)),
            LkNavigationController(rootViewController: PersonListViewController(resolver: resolver)),
            LkNavigationController(rootViewController: MineViewController(resolver: resolver))
        ]
        if let vc = resolver.navigator.response(for: Tab.byteview.url).resource as? UIViewController {
            vc.vcTabIdentifier = Tab.byteview.url.absoluteString
            vc.title = "视频会议"
            vc.tabBarItem = UITabBarItem(title: vc.title, image: UDIcon.getIconByKey(.tabVideoFilled), tag: 0)
            vcs.insert(LkNavigationController(rootViewController: vc), at: 1)
        }
        var bizTabs: [BizTab] = []
        #if canImport(LarkFeed)
        bizTabs.append(BizTab(url: Tab.feed.url, title: "消息", icon: .tabChatFilled))
        #endif
        #if canImport(CCMMod)
        bizTabs.append(BizTab(url: Tab.doc.url, title: "云文档", icon: .tabDriveFilled))
        bizTabs.append(BizTab(url: Tab.base.url, title: "多维表格", icon: .tabBitableFilled))
        bizTabs.append(BizTab(url: Tab.wiki.url, title: "知识库", icon: .tabWikiFilled))
        #endif
        #if canImport(CalendarMod)
        bizTabs.append(BizTab(url: Tab.calendar.url, title: "日历", icon: .tabCalendarFilled))
        #endif
        #if canImport(LarkWorkplace)
        bizTabs.append(BizTab(url: Tab.appCenter.url, title: "工作台", icon: .tabAppFilled))
        #endif
        #if canImport(LarkMail)
        bizTabs.append(BizTab(url: Tab.mail.url, title: "邮箱", icon: .tabMailFilled))
        #endif
        #if canImport(LarkContact)
        bizTabs.append(BizTab(url: Tab.contact.url, title: "联系人", icon: .tabContactsFilled))
        #endif
        #if canImport(Moment)
        bizTabs.append(BizTab(url: Tab.moment.url, title: "字节圈", icon: .tabCommunityFilled))
        #endif
        #if canImport(Todo)
        bizTabs.append(BizTab(url: Tab.todo.url, title: "任务", icon: .tabTodoFilled))
        #endif
        #if canImport(MinutesMod)
        bizTabs.append(BizTab(url: Tab.minutes.url, title: "妙记", icon: .tabMinutesFilled))
        #endif
        bizTabs.forEach { tab in
            if let vc = resolver.navigator.response(for: tab.url).resource as? UIViewController {
                vc.vcTabIdentifier = tab.url.absoluteString
                vc.title = tab.title
                vc.tabBarItem = UITabBarItem(title: tab.title, image: UDIcon.getIconByKey(tab.icon), tag: vcs.count)
                vcs.append(LkNavigationController(rootViewController: vc))
            }
        }
        Navigator.shared.tabProvider = { [weak self] in
            DemoTabProvider(self)
        }
        self.viewControllers = vcs
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NewBootManager.shared.afterFirstRender()
    }

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        setNavigationStyle(navigationController, viewController: viewController)
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        setNavigationStyle(navigationController, viewController: viewController)
    }

    private func setNavigationStyle(_ navigationController: UINavigationController, viewController: UIViewController) {
        let navigationItem = viewController.navigationItem
        var items: [UIBarButtonItem] = []
        if let item = navigationItem.leftBarButtonItem {
            items.append(item)
        }
        if let item = navigationItem.rightBarButtonItem {
            items.append(item)
        }
        if let item = navigationItem.leftBarButtonItems {
            items.append(contentsOf: item)
        }
        if let item = navigationItem.rightBarButtonItems {
            items.append(contentsOf: item)
        }
        if let item = navigationItem.backBarButtonItem {
            items.append(item)
        }
        items.forEach { item in
            if let btn = item.customView as? UIButton {
                btn.tintColor = .ud.iconN1
            } else if let view = item.customView {
                for case let obj as UIButton in view.subviews {
                    obj.tintColor = .ud.iconN1
                }
            }
        }
        if let label = navigationItem.titleView as? UILabel {
            label.textColor = .ud.textTitle
            if let s = label.attributedText {
                let newString = NSMutableAttributedString(attributedString: s)
                newString.addAttribute(.foregroundColor, value: UIColor.ud.textTitle,
                                       range: NSRange(location: 0, length: s.length))
                label.attributedText = newString
            }
        }

        if !(viewController is BaseViewController) {
            navigationController.setNavigationBarHidden(false, animated: false)
            if #available(iOS 13, *) {
                navigationController.vc.updateBarStyle(UDThemeManager.getRealUserInterfaceStyle() == .dark ? .dark : .light)
            } else {
                navigationController.vc.updateBarStyle(.light)
            }
        }
    }

    private struct BizTab {
        let url: URL
        let title: String
        let icon: UDIconType
    }
}

private final class DemoTabProvider: TabProvider {
    init(_ tabbar: UITabBarController?) {
        self.tabbarController = tabbar
    }
    weak var tabbarController: UITabBarController?
    func switchTab(to tabIdentifier: String) {
        guard let tabbar = self.tabbarController,
              let vcs = tabbar.viewControllers?.compactMap({ $0 as? UINavigationController }) else {
            return
        }
        for nav in vcs {
            if let root = nav.viewControllers.first, root.vcTabIdentifier == tabIdentifier {
                tabbar.selectedViewController = nav
                return
            }
        }
    }
}

extension UIViewController {
    private static var vcTabIdentifierKey: UInt8 = 0

    var vcTabIdentifier: String? {
        get {
            objc_getAssociatedObject(self, &Self.vcTabIdentifierKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &Self.vcTabIdentifierKey, newValue, .OBJC_ASSOCIATION_COPY)
        }
    }

    func demoPushOrPresent(_ vc: UIViewController) {
        if UIDevice.current.userInterfaceIdiom == .phone {
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            self.demoPresent(vc)
        }
    }

    func demoPresent(_ vc: UIViewController) {
        self.presentDynamicModal(vc, regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                 compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
    }

    func demoPresent(body: EENavigator.Body, navigator: Navigatable?) {
        guard let vc = navigator?.response(for: body).resource as? UIViewController else {
            return
        }
        self.demoPresent(vc)
    }
}

extension UITraitCollection {
    var isRegular: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }
}
