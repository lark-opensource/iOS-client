//
//  InterpreterManageButtonView.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/10/20.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

class InterpreterManageBottomView: UIView {

    private struct Layout {
        static let startButtonRegularLeftOffset: CGFloat = 16
        static let startButtonCompactLeftOffset: CGFloat = 16
        static var startButtonPhoneLeftOffset: CGFloat = 16
        static let stopButtonRightOffset: CGFloat = 16
        static var buttonHeight: CGFloat = 48
    }

    var buttonTopOffset: CGFloat {
        if isPhoneLandscape {
            return 10
        }
        return 16
    }

    var stopButtonBottomOffset: CGFloat {
        if isPhoneLandscape {
            return 10
        }
        return 14
    }

    var stopButtonLeftOffset: CGFloat {
        if isPhoneLandscape {
            return 16
        }
        return 20
    }

    var startButtonBottomOffset: CGFloat {
        if isPhoneLandscape {
            return 10
        }
        return 14
    }

    enum Style {
        case start
        case manage
    }

    lazy var startButton: UIButton = {
        return createCommonStyleButton(title: I18n.View_G_StartInterpretation)
    }()

    lazy var saveButton: UIButton = {
        return createCommonStyleButton(title: I18n.View_G_SaveChanges)
    }()

    lazy var stopButton: UIButton = {
        let button = UIButton()
        button.setTitle(I18n.View_G_StopButton, for: .normal)
        button.setTitleColor(UIColor.ud.functionDangerContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.functionDangerContentDefault, for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.R100, for: .highlighted)
        button.layer.ud.setBorderColor(UIColor.ud.functionDangerContentDefault)
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 10.0
        button.layer.masksToBounds = true
        button.addInteraction(type: .lift)

        return button
    }()

    var style: Style = .start

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBase
        addSubview(startButton)
        addSubview(saveButton)
        addSubview(stopButton)

        resetLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func resetLayout(isRegular: Bool = false) {
        startButton.isHidden = style != .start
        saveButton.isHidden = style == .start
        stopButton.isHidden = style == .start

        startButton.snp.remakeConstraints { (maker) in
            let leftOffset = Display.phone ? Layout.startButtonPhoneLeftOffset :
                (isRegular ? Layout.startButtonRegularLeftOffset : Layout.startButtonCompactLeftOffset)
            maker.left.right.equalTo(safeAreaLayoutGuide).inset(leftOffset)
            maker.top.equalToSuperview().inset(buttonTopOffset)
            maker.bottom.equalTo(safeAreaLayoutGuide).inset(startButtonBottomOffset)
            maker.height.equalTo(Layout.buttonHeight)
        }

        stopButton.snp.remakeConstraints { (maker) in
            maker.left.equalTo(safeAreaLayoutGuide).inset(stopButtonLeftOffset)
            maker.right.equalTo(saveButton.snp.left).offset(-Layout.stopButtonRightOffset)
            maker.top.equalToSuperview().inset(buttonTopOffset)
            maker.bottom.equalTo(safeAreaLayoutGuide).inset(stopButtonBottomOffset)
            maker.height.equalTo(Layout.buttonHeight)
        }

        saveButton.snp.remakeConstraints { (maker) in
            maker.left.equalTo(stopButton.snp.right).offset(Layout.stopButtonRightOffset)
            maker.right.equalTo(safeAreaLayoutGuide).inset(stopButtonLeftOffset)
            maker.top.bottom.height.equalTo(stopButton)
            maker.width.equalTo(stopButton)
        }
    }

    private func createCommonStyleButton(title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .highlighted)
        button.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .disabled)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.fillDisabled, for: .disabled)
        button.layer.cornerRadius = 10.0
        button.layer.masksToBounds = true
        button.isEnabled = false
        button.addInteraction(type: .lift)
        return button
    }
}
