//
//  SmartCorrectCardViewModel.swift
//  LarkAI
//
//  Created by ZhangHongyun on 2021/5/28.
//

import UIKit
import Foundation
import LarkMenuController
import RxSwift
import LKCommonsLogging

typealias AIMenuCardActionCallback = (() -> Void)

final class SmartCorrectCardViewModel: MenuBarViewModel {
    public func update(rect: CGRect, info: MenuLayoutInfo, isFirstTime: Bool) {

    }

    public weak var menu: MenuVCProtocol?

    public var type: String {
        return "SmartCorrectCardViewModel"
    }

    public var identifier: String {
        return "SmartCorrectCardViewModel"
    }

    public var menuView: UIView {
        return cardView
    }

    public var menuSize: CGSize {
        return cardView.frame.size
    }

    public func updateMenuVCSize(_ size: CGSize) {
        if originSize != size {
            menu?.dismiss(animated: false, params: nil, completion: nil)
        }
    }
    private static let logger = Logger.log(SmartCorrectCardViewModel.self, category: "SmartCorrect.SmartCorrectCardViewModel")
    /// 纠错卡片
    private lazy var cardView: SmartCorrectCardView = {
        let cardView = SmartCorrectCardView(content: self.targetText, tapPoint: self.tapPoint)
        return cardView
    }()
    private let targetText: String
    private let originSize: CGSize
    private let tapPoint: CGPoint
    /// 展示纠错卡片的layout
    private var cardLayout: AIMenuLayout?
    private let selectedActionCallback: AIMenuCardActionCallback?
    private let abandonActionCallback: AIMenuCardActionCallback?
    private let disposeBag = DisposeBag()

    public init(originSize: CGSize,
                targetText: String,
                tapPoint: CGPoint,
                cardLayout: AIMenuLayout?,
                selectedActionCallback: AIMenuCardActionCallback?,
                abandonActionCallback: AIMenuCardActionCallback?) {
        self.originSize = originSize
        self.targetText = targetText
        self.tapPoint = tapPoint
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
