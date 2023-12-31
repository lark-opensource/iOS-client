//
//  ActionSheetAdapter.swift
//  LarkUIKit
//
//  Created by Jiayun Huang on 2019/9/11.
//

import UIKit
import Foundation
import RxSwift
import LarkTraitCollection

public enum ReminderLevel {
    /// 强提醒，R 下是 alert， C 下是 actionSheet
    /// view 用于判断当前的全局 traitCollection，以此来决定创建哪种弹窗
    case high(view: UIView)
    /// R 下是 popover， C 下是 actionSheet
    /// source 用于指定 popover 时指向的 view
    case normal(source: ActionSheetAdapterSource)
    /// 某些情况会找不到触发事件的 view，比如 JsSDK 注册的事件，此时使用自定义的 ActionSheet 来展示
    case normalWithCustomActionSheet
}

public final class ActionSheetAdapter {
    private var disposeBag = DisposeBag()

    private weak var presentingVC: UIViewController?

    private var reminderLevel: ReminderLevel?

    public init() {}

    public func create(level: ReminderLevel,
                       title: String? = nil,
                       titleColor: UIColor? = nil) -> UIViewController {
        reminderLevel = level

        var presentingVC: UIViewController!
        if UIDevice.current.userInterfaceIdiom == .pad {
            switch level {
            case .normal(let source):
                presentingVC = createNormalLevelVC(source: source, title: title, titleColor: titleColor)
            case .high(let view):
                observeTraitCollectionChange(for: view)
                presentingVC = createHighLevelVC(view: view, title: title, titleColor: titleColor)
            case .normalWithCustomActionSheet:
                presentingVC = createCustomActionSheet(title: title)
            }
        } else {
            presentingVC = createCustomActionSheet(title: title)
        }
        presentingVC.actionSheetAdapter = self
        self.presentingVC = presentingVC
        return presentingVC
    }

    @discardableResult
    public func addItem(
        title: String,
        textColor: UIColor? = nil,
        icon: UIImage? = nil,
        entirelyCenter: Bool = false,
        action: @escaping () -> Void
        ) -> NSObject? {
        guard let vc = presentingVC as? ActionSheetAdapterProtocol else {
            assertionFailure("ActionSheetAdapter presenting vc type error")
            return nil
        }
        return vc.addActionItem(title: title, textColor: textColor, icon: icon, entirelyCenter: entirelyCenter, action: action)
    }

    @discardableResult
    public func addCancelItem(
        title: String,
        textColor: UIColor? = nil,
        icon: UIImage? = nil,
        entirelyCenter: Bool = false,
        cancelAction: (() -> Void)? = nil
        ) -> NSObject? {
        guard let vc = presentingVC as? ActionSheetAdapterProtocol else {
            assertionFailure("ActionSheetAdapter presenting vc type error")
            return nil
        }
        return vc.addCancelActionItem(title: title, textColor: textColor, icon: icon, entirelyCenter: entirelyCenter, action: cancelAction)
    }

    @discardableResult
    public func addRedCancelItem(
        title: String,
        icon: UIImage? = nil,
        cancelAction: (() -> Void)? = nil
        ) -> NSObject? {
        guard let vc = presentingVC as? ActionSheetAdapterProtocol else {
            assertionFailure("ActionSheetAdapter presenting vc type error")
            return nil
        }
        return vc.addRedCancelActionItem(title: title, icon: icon, cancelAction: cancelAction)
    }
}

private extension ActionSheetAdapter {
    func observeTraitCollectionChange(for view: UIView) {
        disposeBag = DisposeBag()

        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.dismissIfNeeded()
            }).disposed(by: disposeBag)

        RootTraitCollection.observer
            .observeRootTraitCollectionDidChange(for: view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.dismissIfNeeded()
            }).disposed(by: disposeBag)
    }

    func dismissIfNeeded() {
        /// 对 normal level 的，系统自动会在 C/R 切换时做 actionSheet 和 popover 的切换，因此不用dismiss
        if let reminderLevel = reminderLevel,
            case .high = reminderLevel,
            let vc = presentingVC {
                vc.dismiss(animated: false)
        }
    }
}

/// create
private extension ActionSheetAdapter {
    func createNormalLevelVC(source: ActionSheetAdapterSource,
                             title: String? = nil,
                             titleColor: UIColor? = nil,
                             backgroundColor: UIColor? = nil
                             ) -> UIViewController {
        /// normal level, 需要提供 source，用 UIAlertController 实现，R -> C 变换系统默认实现 ActionSheet 和 popover 的转换
        let presentingVC = createAlertController(style: .actionSheet, title: title, titleColor: titleColor)
        presentingVC.popoverPresentationController?.sourceView = source.sourceView
        presentingVC.popoverPresentationController?.sourceRect = source.sourceRect
        presentingVC.popoverPresentationController?.permittedArrowDirections = source.arrowDirection
        presentingVC.popoverPresentationController?.backgroundColor = backgroundColor

        return presentingVC
    }

    func createHighLevelVC(view: UIView,
                           title: String? = nil,
                           titleColor: UIColor? = nil) -> UIViewController {
        /// high level, view 用于判断当前的全局 TraitCollection
        /// 在 R 下用 UIAlertController 实现
        /// 在 C 下用自定义 ActionSheet 实现
        /// 因为对 high level来说，不会有 popover 样式，因此提供的 view 只需要是层级树中的任意 view
        if view.window?.lkTraitCollection.horizontalSizeClass == .regular {
            let presentingVC = createAlertController(style: .alert, title: title, titleColor: titleColor)
            return presentingVC
        }
        return createCustomActionSheet(title: title)
    }

    func createCustomActionSheet(title: String? = nil) -> UIViewController {
        let title = title ?? ""
        return ActionSheet(title: title)
    }

    func createAlertController(style: UIAlertController.Style,
                               title: String? = nil,
                               titleColor: UIColor? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: style)
        if let title = title {
            let color = titleColor ?? UIAlertController.UIStyle.titleColor
            let attributeString =
                NSAttributedString(string: title,
                                   attributes: [.foregroundColor: color,
                                                .font: UIFont.systemFont(ofSize: UIAlertController.UIStyle.titleFontSize)])
            alert.setValue(attributeString, forKey: "attributedTitle")
        }
        return alert
    }
}
