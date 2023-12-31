//
//  RecordWithTextActionViewWithLID.swift
//  LarkAudio
//
//  Created by 白镜吾 on 2023/2/16.
//

import Foundation
import UIKit
import LarkContainer

/// 按钮组 【取消】【只发语音】【只发文字】【发送】
final class RecordWithTextActionViewWithLID: UIView, BaseRecordWithTextActionView {
    enum Cons {
        static var defaultViewHeight: CGFloat { 74 }
        static var topPadding: CGFloat { 8 }
        static var bottomPadding: CGFloat { 12 }
    }

    lazy var cancelButton: UIButton = AudioKeyboardInteractiveButton(type: .cancel, userResolver: userResolver)
    lazy var sendAudioButton: UIButton = AudioKeyboardInteractiveButton(type: .sendOnlyVoice, userResolver: userResolver)
    lazy var sendTextButton: UIButton = AudioKeyboardInteractiveButton(type: .sendOnlyText, userResolver: userResolver)
    lazy var sendAllButton: UIButton = AudioKeyboardInteractiveButton(type: .sendAll, userResolver: userResolver)

    private let leftView: UIView = UIView()
    private let rightView: UIView = UIView()
    private let onlyAudioView: UIView = UIView()
    private let onlyTextView: UIView = UIView()
    private let centerView: UIView = UIView()
    private let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(frame: .zero)
        self.addSubview(leftView)
        self.addSubview(rightView)
        self.addSubview(onlyAudioView)
        self.addSubview(onlyTextView)
        self.addSubview(centerView)

        leftView.backgroundColor = UIColor.clear
        rightView.backgroundColor = UIColor.clear
        onlyAudioView.backgroundColor = UIColor.clear
        onlyTextView.backgroundColor = UIColor.clear

        self.updateNewLayoutView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateNewLayoutView() {
        self.addSubview(cancelButton)
        self.addSubview(sendAudioButton)
        self.addSubview(sendAllButton)
        self.addSubview(sendTextButton)

        leftView.snp.remakeConstraints { (maker) in
            maker.left.equalToSuperview()
            maker.right.equalTo(onlyAudioView.snp.left)
            maker.height.greaterThanOrEqualTo(54)
            maker.top.equalTo(onlyAudioView)
        }

        onlyAudioView.snp.remakeConstraints { (maker) in
            maker.top.equalToSuperview().offset(Cons.topPadding)
            maker.right.equalTo(onlyTextView.snp.left)
            maker.height.greaterThanOrEqualTo(54).priority(999)
            maker.width.equalTo(leftView)
            maker.width.equalTo(rightView)
            maker.width.equalTo(onlyTextView)
        }

        onlyTextView.snp.remakeConstraints { (maker) in
            maker.right.equalTo(rightView.snp.left)
            maker.height.greaterThanOrEqualTo(54)
            maker.top.equalTo(onlyAudioView)
        }

        rightView.snp.remakeConstraints { (maker) in
            maker.right.equalToSuperview()
            maker.height.greaterThanOrEqualTo(54)
            maker.top.equalTo(onlyAudioView.snp.top)
        }

        centerView.snp.remakeConstraints { (maker) in
            maker.center.equalToSuperview()
            maker.width.height.equalTo(54)
        }
    }

    func setButtonAverage() {

        cancelButton.snp.remakeConstraints { (maker) in
            maker.left.top.width.height.equalTo(leftView)
        }
        sendAudioButton.snp.remakeConstraints { (maker) in
            maker.left.top.width.height.equalTo(onlyAudioView)
        }
        sendTextButton.snp.remakeConstraints { (maker) in
            maker.left.top.width.height.equalTo(onlyTextView)
        }
        sendAllButton.snp.remakeConstraints { (maker) in
            maker.left.top.width.height.equalTo(rightView)
        }
    }

    func setButtomInCenter() {
        cancelButton.snp.remakeConstraints { (maker) in
            maker.left.top.width.height.equalTo(centerView)
        }
        sendAudioButton.snp.remakeConstraints { (maker) in
            maker.left.top.width.height.equalTo(centerView)
        }
        sendAllButton.snp.remakeConstraints { (maker) in
            maker.left.top.width.height.equalTo(centerView)
        }
        sendTextButton.snp.remakeConstraints { (maker) in
            maker.left.top.width.height.equalTo(centerView)
        }
    }

    func getActionViewActualHeight() -> CGFloat {
        guard let cancelButton = cancelButton as? AudioKeyboardInteractiveButton,
              let sendAudioButton = sendAudioButton as? AudioKeyboardInteractiveButton,
              let sendTextButton = sendTextButton as? AudioKeyboardInteractiveButton,
              let sendAllButton = sendAllButton as? AudioKeyboardInteractiveButton else {
            return Cons.defaultViewHeight
        }

        return max(cancelButton.buttonHeight, sendAudioButton.buttonHeight, sendAllButton.buttonHeight, sendTextButton.buttonHeight) + Cons.topPadding
    }
}
