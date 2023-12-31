//
//  TemporaryTabContainer.swift
//  AnimatedTabBar
//
//  Created by yaoqihao on 2023/6/25.
//

import Foundation
import LarkTab
import SnapKit
import LarkUIKit
import LarkContainer
import LarkKeyCommandKit
import LKCommonsLogging
import RxSwift
import RxCocoa

final public class TemporaryTabContainer: UIViewController {
    static let logger = Logger.log(TemporaryTabContainer.self, category: "Module.TemporaryTabContainer")

    public var tabContainable: TabContainable?
    lazy var navi: LkNavigationController = LkNavigationController(rootViewController: UIViewController())

    public var closeCallback: ((TabContainable) -> Void)?

    public var traitCollectionDidChangeCallback: ((TabContainable) -> Void)?

    public override func keyBindings() -> [KeyBindingWraper] {
        return [
            KeyCommandBaseInfo(input: "w", modifierFlags: .command,
                               discoverabilityTitle: BundleI18n.AnimatedTabBar.Lark_Shortcuts_CloseCurrentTab_Text)
                .binding(handler: { [weak self] in
                    self?.closeTabContainable()
                }).wraper
        ]
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        navi.update(style: .clear)
        self.addChild(navi)
        self.view.addSubview(navi.view)
        navi.view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navi.beginAppearanceTransition(true, animated: animated)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navi.endAppearanceTransition()
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navi.beginAppearanceTransition(false, animated: animated)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navi.endAppearanceTransition()
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if let tab = self.tabContainable {
            self.traitCollectionDidChangeCallback?(tab)
        }
    }

    func update(tabContainable: TabContainable) {
        Self.logger.info("Update TabContainable, id: \(tabContainable.tabContainableIdentifier)")
        removeTabContainable()
        self.tabContainable = tabContainable
        tabContainable.willMoveToTemporary()
        self.navi.setViewControllers([tabContainable], animated: false)
        if !tabContainable.isCustomTemporaryNavigationItem {
            self.title = tabContainable.tabTitle
        }
        titleText.accept(tabContainable.tabTitle)
    }

    func removeTabContainable() {
        self.tabContainable?.willRemoveFromTemporary()
        Self.logger.info("Remove TabContainable, id: \(self.tabContainable?.tabContainableIdentifier)")
        self.tabContainable?.beginAppearanceTransition(false, animated: false)
        self.tabContainable?.endAppearanceTransition()
        self.tabContainable?.view.removeFromSuperview()
        self.tabContainable?.removeFromParent()
        self.tabContainable = nil
    }

    func closeTabContainable() {
        Self.logger.info("Close TabContainable, id: \(self.tabContainable?.tabContainableIdentifier)")

        if let tab = self.tabContainable {
            self.closeCallback?(tab)
        }
        self.removeTabContainable()
    }
}

extension TemporaryTabContainer: LarkNaviBarProtocol {
    public var titleText: BehaviorRelay<String> {
        guard let tabContainable = tabContainable else { return BehaviorRelay(value: "") }
        return BehaviorRelay(value: tabContainable.tabTitle)
    }

    public var isNaviBarEnabled: Bool {
        false
    }

    public var isDrawerEnabled: Bool {
        true
    }
}
