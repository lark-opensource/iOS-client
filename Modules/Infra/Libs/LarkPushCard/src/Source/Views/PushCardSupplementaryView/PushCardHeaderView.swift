//
//  PushCardHeaderView.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/10/19.
//

import Foundation
import UIKit
import FigmaKit

final class PushCardHeaderLayer: CALayer {
    override func action(forKey event: String) -> CAAction? {
        if event == "opacity" {
            return nil
        }
        return super.action(forKey: event)
    }
}

final class PushCardHeaderView: UICollectionReusableView {
    static var identifier: String = "PushCardHeader"

    class override var layerClass: AnyClass {
        return PushCardHeaderLayer.self
    }

    private lazy var headerButtons: PushCardTopBottomButtonsView = PushCardTopBottomButtonsView()

    weak var delegate: PushCardTopBottonButtonDelegate? {
        didSet {
            headerButtons.delegate = delegate
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.addSubview(headerButtons)
        self.headerButtons.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Cons.spacingBetweenCards)
            make.height.equalTo(Cons.cardHeaderBtnHeight)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func changeToStack() {
        self.headerButtons.isHidden = true
    }
}
