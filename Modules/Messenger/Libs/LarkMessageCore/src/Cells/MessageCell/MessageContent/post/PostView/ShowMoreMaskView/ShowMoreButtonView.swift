//
//  ShowMoreMskButton.swift
//  LarkMessageCore
//
//  Created by chenziyue on 2022/1/18.
//

import UIKit
import Foundation
import LarkInteraction
import UniverseDesignTheme
import UniverseDesignColor

// 由于展开button从原来的父容器中被抽离出来无法满足原文译文两个button对齐，为了保持对齐，将展开button放在原来的父容器，虚化效果被单独抽离出来。
public final class ShowMoreButtonView: UIView {

    static var maskHeight: CGFloat {
        return ShowMoreButton.caculatedSize.height + 28
    }

    var showMoreHandler: (() -> Void)?

    lazy var showMoreButton: ShowMoreButton = {
        let button = ShowMoreButton(frame: .zero)
        button.addTarget(self, action: #selector(showMoreButtonTapped), for: .touchUpInside)
        return button
    }()

    public override var frame: CGRect {
        didSet {
            var buttonFrame = CGRect(origin: .zero, size: ShowMoreButton.caculatedSize)
            buttonFrame.center = bounds.center
            showMoreButton.frame = buttonFrame
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        self.addSubview(showMoreButton)
        showMoreButton.sizeToFit()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func showMoreButtonTapped() {
        self.showMoreHandler?()
    }
}
