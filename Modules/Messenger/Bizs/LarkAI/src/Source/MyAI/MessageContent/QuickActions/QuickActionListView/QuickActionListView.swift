//
//  QuickActionListView.swift
//  LarkAI
//
//  Created by Hayden on 22/8/2023.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import UniverseDesignColor
import LarkMessengerInterface
import LarkMessageCore
import LarkAIInfra

final class QuickActionListView: UIStackView {

    var onTapped: ((AIQuickActionModel) -> Void)?

    private var buttons: [QuickActionListButton] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .vertical
        alignment = .leading
        distribution = .equalSpacing
        spacing = Cons.buttonSpacing
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 设置内容，内部不持有 QuickActionListViewLayout，做到单项数据流
    func setup(layout: QuickActionListViewLayout, onTapped: ((AIQuickActionModel) -> Void)?) {
        self.onTapped = onTapped
        arrangedSubviews.forEach { $0.removeFromSuperview() }
        for action in layout.quickActionList {
            let button = QuickActionListButton(with: action)
            button.onTapped = self.onTapped
            buttons.append(button)
            addArrangedSubview(button)
        }
    }
}

extension QuickActionListView {

    enum Cons {
        static var loadingButtonWidth: CGFloat { 53 }
        static var buttonSpacing: CGFloat { 6.auto() }
        static var listHeightForLoading: CGFloat {
            QuickActionListButton.Cons.buttonHeight(withContent: " ", constraintWidth: .greatestFiniteMagnitude)
        }
        static func listHeight(with quickActions: [AIQuickActionModel], constraintWidth: CGFloat) -> CGFloat {
            guard !quickActions.isEmpty else { return 0 }
            let buttonsHeight = quickActions.reduce(0, { res, action in
                res + QuickActionListButton.Cons.buttonHeight(withContent: action.displayName, constraintWidth: constraintWidth)
            })
            let totalSpacing = buttonSpacing * CGFloat(quickActions.count - 1)
            return buttonsHeight + totalSpacing
        }
    }
}
