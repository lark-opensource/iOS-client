//
//  PushCardFooterView.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/10/19.
//

import Foundation
import UIKit
import FigmaKit

final class PushCardFooterLayer: CALayer {
    override func action(forKey event: String) -> CAAction? {
        if event == "opacity" {
            return nil
        }
        return super.action(forKey: event)
    }
}

final class PushCardFooterView: UICollectionReusableView {
    static var identifier: String = "PushCardFooter"

    class override var layerClass: AnyClass {
        return PushCardFooterLayer.self
    }

    private lazy var footerButtons: PushCardTopBottomButtonsView = PushCardTopBottomButtonsView()

    weak var delegate: PushCardTopBottonButtonDelegate? {
        didSet {
            footerButtons.delegate = delegate
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.addSubview(footerButtons)
        self.footerButtons.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.top.equalToSuperview().offset(Cons.spacingBetweenCards)
            make.height.equalTo(Cons.cardHeaderBtnHeight)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func changeToStack() {
        self.footerButtons.isHidden = true
    }
}
