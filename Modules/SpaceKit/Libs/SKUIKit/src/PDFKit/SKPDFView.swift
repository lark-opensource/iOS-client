//
//  SKPDFView.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/6/7.
//  

import UIKit
import PDFKit
import LarkEMM
import SKFoundation
import RxSwift
import RxCocoa

public protocol SKSystemMenuInterceptorProtocol: AnyObject {
    // 返回 nil 表示遵循默认的流程
    func canPerformSystemMenuAction(_ action: Selector, withSender sender: Any?) -> Bool?
    // 返回是否需要执行默认的 copy 方法
    func interceptCopy(_ sender: Any?) -> Bool
}

public extension SKSystemMenuInterceptorProtocol {
    func canPerformSystemMenuAction(_ action: Selector, withSender sender: Any?) -> Bool? {
        return nil
    }

    func interceptCopy(_ sender: Any?) -> Bool { return false }
}

public final class SKPDFView: PDFView {

    public struct Identifier {
        public static let copy = "pdfCopyMenuId"
    }
    /// 允许外部设置自定义menu
    public var customMenus = BehaviorRelay<[PDFMenuType]>(value: [])

    /// 需要拦截气泡菜单的id，当前安全拦截遗漏时，这里可以作为补充
    public var hiddenIdentifiers: [String] = []
    
    /// 是否可以拦截PDFDocumentView的canPerformAction方法，用于拦截iOS 16以下的的气泡菜单
    public var canSwizzleDocumentView = false

    public var canShowMenu: Bool {
        return !customMenus.value.isEmpty
    }

    private var swizzled = false
    
    public var hideSystemMenu: Bool = false

    var oldPerformIMP: OpaquePointer?

    public weak var systemMenuInterceptor: SKSystemMenuInterceptorProtocol?

    var customMenuIdentifiers: [String] {
        guard canShowMenu else { return [] }
        return customMenus.value.map({ $0.identifier })
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addPDFViewSelectionChangedNoti()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if !customMenuIdentifiers.isEmpty {
            return customMenuIdentifiers.contains(action.description)
        }
        if let remainItems = SCPasteboard.general(SCPasteboard.defaultConfig()).canRemainActionsDescrption(ignorePreCheck: true), remainItems.contains(action.description) {
            return systemMenuInterceptor?.canPerformSystemMenuAction(action, withSender: sender)
                ?? super.canPerformAction(action, withSender: sender)
        }
        if hideSystemMenu && UserScopeNoChangeFG.WWJ.ccmSecurityMenuProtectEnable { return false }
        return systemMenuInterceptor?.canPerformSystemMenuAction(action, withSender: sender)
            ?? super.canPerformAction(action, withSender: sender)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if self.canSwizzleDocumentView {
            self.documentView?.weakParentPDFView = WeakReference(self)
        }
    }

    @available(iOS 13.0, *)
    public override func buildMenu(with builder: UIMenuBuilder) {
        if #available(iOS 16.0, *), UserScopeNoChangeFG.HYF.pdfInlineAIMenuEnable, canShowMenu {
            guard let hiddenItems = SCPasteboard.general(SCPasteboard.defaultConfig()).hiddenItemsDescrption(ignorePreCheck: true) else {
                return
            }
            hiddenItems.forEach { identifier in
                builder.remove(menu: identifier)
            }

            hiddenIdentifiers.forEach {
                let identifier = UIMenu.Identifier(rawValue: $0)
                if !hiddenItems.contains(identifier) {
                    builder.remove(menu: identifier)
                }
            }
            
            for menu in customMenus.value {
                guard let sel = self.itemSelectorForPDFView(target: self, with: menu) else {
                    continue
                }
                let menuElements: [UIMenuElement] = [UICommand(title: menu.title, action: sel)]
                let customMenu = UIMenu(identifier: UIMenu.Identifier(menu.identifier), options: .displayInline, children: menuElements)
                builder.insertChild(customMenu, atStartOfMenu: .root)
            }
        }

        super.buildMenu(with: builder)
        guard hideSystemMenu && UserScopeNoChangeFG.WWJ.ccmSecurityMenuProtectEnable else { return }
        guard let hiddenItems = SCPasteboard.general(SCPasteboard.defaultConfig()).hiddenItemsDescrption(ignorePreCheck: true) else {
            return
        }
        hiddenItems.forEach { identifier in
            builder.remove(menu: identifier)
        }
    }

    public override func copy(_ sender: Any?) {
        guard let interceptor = systemMenuInterceptor else {
            super.copy(sender)
            return
        }
        if !interceptor.interceptCopy(sender) {
            super.copy(sender)
        }
    }
    

    // 16.0以下需要通过hook DocumentView方法拦截系统气泡菜单
    public func swizzleDocumentViewIfNeed() {
        guard canShowMenu,
              canSwizzleDocumentView,
              !swizzled else {
            return
        }
        if #available(iOS 16.0, *) {
          // 不需要处理
        } else {
            self.documentView?.weakParentPDFView = WeakReference(self)
            let res = PDFSwizzlingUtils.shared.swizzleDocumentView(pdfView: self)
            swizzled = res
        }
    }

    private func addPDFViewSelectionChangedNoti() {
        guard UserScopeNoChangeFG.HYF.pdfInlineAIMenuEnable else { return }
        if #available(iOS 16.0, *) {
            // do nothing
        } else {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(selectionChangeNotification),
                                                   name: NSNotification.Name.PDFViewSelectionChanged,
                                                   object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(clearMenuItems), name: UIMenuController.didHideMenuNotification, object: nil)
        }
    }
    
    
    @objc
    private func clearMenuItems() {
        UIMenuController.shared.menuItems = []
    }
    
    @objc
    func selectionChangeNotification() {
        guard canShowMenu else {
            UIMenuController.shared.menuItems = []
            DocsLogger.info("[AILogger] [pdf] canShowMenu is false")
            return
        }
        guard let documentView = self.documentView else {
            DocsLogger.error("[AILogger] [pdf] documentView is nil")
            return
        }
        swizzleDocumentViewIfNeed()
        UIMenuController.shared.menuItems = customMenus.value.compactMap({
            if let sel = self.itemSelectorForPDFView(target: documentView, with: $0) {
                return UIMenuItem(title: $0.title, action: sel)
            } else {
                return nil
            }
        })
        DocsLogger.debug("[AILogger] [pdf] menuItems:\(UIMenuController.shared.menuItems)")
    }
    
    /// 构建气泡菜单响应Selector
    private func itemSelectorForPDFView(target: UIView, with menu: PDFMenuType) -> Selector? {
        guard let targetClass = object_getClass(target) else {
            return nil
        }
        let block = { [weak self] in
            guard let self = self else { return }
            if menu.identifier == SKPDFView.Identifier.copy {
                if let interceptor = self.systemMenuInterceptor, interceptor.interceptCopy(nil) {
                    DocsLogger.warning("[AILogger] [pdf] copy interceptor is working")
                    return
                }
            }
            menu.callback(self.currentSelection?.string ?? "", self.pointId)
        }
        let aSelector = selector(uid: menu.identifier, classes: [targetClass], block: block)
        return aSelector
    }
}
