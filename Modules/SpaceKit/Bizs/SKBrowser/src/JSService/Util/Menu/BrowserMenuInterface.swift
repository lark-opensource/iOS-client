//
//  BrowserMenuInterface.swift
//  SKBrowser
//
//  Created by lizechuang on 2021/2/4.
//

import Foundation
import RxSwift
import UniverseDesignActionPanel
import SKUIKit
import SKFoundation

struct BrowserMenuItem {
    var id: String
    var text: String
    var style: Int
    var isCancel: Bool

    func alertActionStyle() -> UDActionSheetItem.Style {
        switch style {
        case 0:
            return .default
        case 1:
            return .destructive
        default:
            return .default
        }
    }
}

class BrowserMenu {

    private let selectActionPublishSubject: PublishSubject<String> = PublishSubject<String>()
    var selectAction: Observable<String> {
        return selectActionPublishSubject.asObserver()
    }

    let menuItems: [BrowserMenuItem]

    let title: String?

    private lazy var menu: UDActionSheet? = _constructMenu()

    init(_ menuItems: [BrowserMenuItem], title: String? = nil) {
        self.menuItems = menuItems
        self.title = title
    }

    // 展示
    func present(fromVc: UIViewController?) {
        guard let fromVc = fromVc else {
            DocsLogger.info("fromVc is nil")
            return
        }
        if let menu = menu {
            fromVc.present(menu, animated: true, completion: nil)
        }
    }

    // 关闭
    func dismiss() {
        menu?.dismiss(animated: true, completion: nil)
    }

    private func _constructMenu() -> UDActionSheet {

        let alertVC = UDActionSheet.actionSheet(title: self.title) {
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.1, execute: {
                self.selectActionPublishSubject.onCompleted()
                self.menu = nil
            })
        }

        // 构造 action
        menuItems.forEach { menuItem in
            if menuItem.isCancel {
                alertVC.addItem(text: menuItem.text, style: .cancel)
                return
            }
            let handler: () -> Void = {
                // 这里是故意持有的，避免 self 被释放，下面监听 didDismiss 来释放 self
                self.selectActionPublishSubject.onNext(menuItem.id)
            }

            let style = menuItem.alertActionStyle()
            switch style {
            case .destructive: // 目前只有destructive模式下需要设置为红色
                alertVC.addItem(text: menuItem.text, textColor: UIColor.ud.colorfulRed, action: handler)
            default:
                alertVC.addItem(text: menuItem.text, style: style, action: handler)
            }
        }

        return alertVC
    }
}
