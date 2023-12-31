//
//  FloatPickerBackgroundMaskView.swift
//
//  Created by bytedance on 2022/1/5.
//
import Foundation
import UIKit

final class FloatPickerBackgroundMaskView: UIView {
    var tapCallBack: (() -> Void)?

    init() {
        super.init(frame: .zero)
        self.backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.tapCallBack?()
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
}
