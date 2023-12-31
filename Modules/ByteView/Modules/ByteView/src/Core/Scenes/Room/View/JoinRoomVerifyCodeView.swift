//
//  JoinRoomVerifyCodeView.swift
//  ByteView
//
//  Created by kiri on 2023/6/9.
//

import Foundation

final class JoinRoomVerifyCodeView: JoinRoomChildView {
    let textField = JoinRoomVerifyCodeTextField()

    override func setupViews() {
        super.setupViews()
        addSubview(textField)
        textField.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(20)
            make.top.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(0)
        }
    }

    private var inputSize: CGFloat { style == .popover ? 40 : 48 }
    override func updateStyle() {
        self.textField.inputSize = CGSize(width: inputSize, height: inputSize)
        self.textField.snp.updateConstraints { make in
            make.bottom.equalToSuperview().inset(style == .popover ? 0 : 8)
        }
    }

    private var state: JoinRoomVerifyCodeState = .idle
    override func updateRoomInfo(_ viewModel: JoinRoomTogetherViewModel) {
        self.state = viewModel.verifyCodeState
        textField.updateVerifyCode(viewModel.verifyCode, state: state)
    }

    override func fitContentHeight(maxWidth: CGFloat) -> CGFloat {
        if style == .popover {
            return 16 + inputSize
        } else {
            return 16 + inputSize + 8
        }
    }
}
