//
//  LingoHighlightMenuViewModel.swift
//  LarkAI
//
//  Created by ByteDance on 2023/5/25.
//

import Foundation
import UIKit
import LarkMenuController
import RxSwift
import LKCommonsLogging

final class LingoHighlightMenuViewModel: MenuBarViewModel {
    func update(rect: CGRect, info: MenuLayoutInfo, isFirstTime: Bool) {

    }

    weak var menu: MenuVCProtocol?

    var type: String {
        return "LingoHighlightMenuViewModel"
    }

    var identifier: String {
        return "LingoHighlightMenuViewModel"
    }

    var menuView: UIView {
        return cardView
    }

    var menuSize: CGSize {
        return cardView.frame.size
    }

    func updateMenuVCSize(_ size: CGSize) {
        if originSize != size {
            menu?.dismiss(animated: false, params: nil, completion: nil)
        }
    }
    /// 百科菜单
    lazy var cardView: LingoHighlightMenuView = {
        let cardView = LingoHighlightMenuView(content: self.menuText, tapPoint: self.tapPoint, textView: self.textView)
        return cardView
    }()
    private let menuText: String
    private let originSize: CGSize
    private let tapPoint: CGPoint
    private weak var textView: UITextView?
    private var cardLayout: AIMenuLayout?
    private let selectedActionCallback: AIMenuCardActionCallback?
    private let abandonActionCallback: AIMenuCardActionCallback?
    private let disposeBag = DisposeBag()

    init(originSize: CGSize,
                menuText: String,
                tapPoint: CGPoint,
                textView: UITextView,
                cardLayout: AIMenuLayout?,
                selectedActionCallback: AIMenuCardActionCallback?,
                abandonActionCallback: AIMenuCardActionCallback?) {
        self.originSize = originSize
        self.menuText = menuText
        self.tapPoint = tapPoint
        self.textView = textView
        self.cardLayout = cardLayout
        self.selectedActionCallback = selectedActionCallback
        self.abandonActionCallback = abandonActionCallback
        registerCardViewCallback()
    }

    private func registerCardViewCallback() {
        cardView.selectedActionCallback = { [weak self] in
            guard let self = self else { return }
            self.selectedActionCallback?()
        }
        cardView.abandonActionCallback = { [weak self] in
            guard let self = self else { return }
            self.abandonActionCallback?()
        }
    }
}
