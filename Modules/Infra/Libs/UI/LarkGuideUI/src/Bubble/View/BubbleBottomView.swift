//
//  BubbleBottomView.swift
//  LarkGuide
//
//  Created by zhenning on 2020/5/18.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

public final class BubbleBottomView: UIView {

    typealias BubbleButtonAction = () -> Void

    /// config
    private let bottomConfig: BottomConfig?
    private let rightBtnInfo: ButtonInfo?
    private let leftBtnInfo: ButtonInfo?
    var rightBtnTitle: String? {
        didSet {
            self.rightButton.setTitle(rightBtnTitle, for: UIControl.State.normal)
            updateButtonLayout(button: self.rightButton)
        }
    }
    /// 右按钮点击监听
    var leftBtnTitle: String? {
        didSet {
            self.leftButton.setTitle(leftBtnTitle, for: UIControl.State.normal)
            updateButtonLayout(button: self.leftButton)
        }
    }
    var rightBtnClickObservable: Observable<Void> {
        return self.rightButton.rx.tap.asObservable()
    }
    /// 左按钮点击监听
    var leftBtnClickObservable: Observable<Void> {
        return self.leftButton.rx.tap.asObservable()
    }
    var leftText: String? {
        didSet {
            self.leftTextLabel.text = leftText
        }
    }

    private var isRightBtnHidden: Bool {
        return self.rightBtnInfo == nil
    }
    private var isSubBtnHidden: Bool {
        return self.leftBtnInfo == nil
    }
    private var isleftTextHidden: Bool {
        return self.leftText == nil
    }

    private var rightButton: UIButton = UIButton()
    private(set) var leftButton: UIButton = UIButton()
    private var leftTextLabel: UILabel = UILabel()

    init(bottomConfig: BottomConfig) {
        self.bottomConfig = bottomConfig
        self.leftBtnInfo = bottomConfig.leftBtnInfo
        self.rightBtnInfo = bottomConfig.rightBtnInfo
        self.leftText = bottomConfig.leftText

        super.init(frame: .zero)
        setupUI()
    }

    private func setupUI() {

        if !isRightBtnHidden {
            self.rightButton.titleLabel?.font = Style.buttonDefaultFont
            self.rightButton.setTitleColor(Style.rightBtnTitleDefaultColor, for: UIControl.State.normal)
            self.rightButton.backgroundColor = Style.rightBtnTitleDefaultBackColor
            self.rightButton.layer.cornerRadius = Layout.buttonCornerRadius
            self.addSubview(self.rightButton)
            self.rightButton.snp.makeConstraints { (make) in
                make.right.equalTo(-Layout.contentInset.right)
                make.top.equalToSuperview().offset(Layout.contentInset.top)
                make.height.equalTo(Layout.buttonHeight)
                make.width.equalTo(Layout.buttonMinWidth)
            }

            /// 主按钮出现时，才会出现左侧副按钮，单个按钮显示主按钮
            if !isSubBtnHidden {
                self.leftButton.titleLabel?.font = Style.buttonDefaultFont
                self.leftButton.setTitleColor(Style.leftBtnTitleColor, for: UIControl.State.normal)
                self.addSubview(self.leftButton)

                self.leftButton.snp.makeConstraints { (make) in
                    make.right.equalTo(self.rightButton.snp.left).offset(-Layout.buttonItemSpace)
                    make.top.equalToSuperview().offset(Layout.contentInset.top)
                    make.height.equalTo(Layout.buttonHeight)
                    make.width.equalTo(Layout.buttonMinWidth)
                }
            }
        }

        self.leftTextLabel.textColor = Style.letTitleDefaultTextColor
        self.leftTextLabel.font = Style.buttonDefaultFont
        self.addSubview(self.leftTextLabel)
        self.leftTextLabel.snp.makeConstraints { (make) in
            make.left.equalTo(Layout.contentInset.left)
            make.top.equalToSuperview().offset(Layout.contentInset.top)
            make.height.equalTo(Layout.buttonHeight)
        }

        if let leftText = self.leftText {
            self.leftTextLabel.text = leftText
        }
    }

    private func updateButtonLayout(button: UIButton) {
        let btnWidth = getButtonWidth(button: button)
        button.snp.updateConstraints { (make) in
            make.width.equalTo(btnWidth)
        }
    }

    private func getButtonWidth(button: UIButton) -> CGFloat {
        let buttonPrepareSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: Layout.buttonHeight)
        let btnContentWidth: CGFloat = button.titleLabel?.sizeThatFits(buttonPrepareSize).width ?? 0
        var btnWidth = btnContentWidth + (Layout.buttonInset * 2)
        if btnWidth < Layout.buttonMinWidth {
            btnWidth = Layout.buttonMinWidth
        } else if btnWidth > Layout.buttonMaxWidth {
            btnWidth = Layout.buttonMaxWidth
        }
        return btnWidth
    }

    /// MAKR: - Data

    /// 更新底部
    func updateByStep(currentStep: Int, numberOfSteps: Int) {
        leftTextLabel.isHidden = numberOfSteps <= 1
        leftButton.isHidden = currentStep == 0
        rightButton.isHidden = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BubbleBottomView {
    enum Layout {
        static let contentInset: UIEdgeInsets = UIEdgeInsets(top: 24, left: 20, bottom: 4, right: 20)
        static let buttonHeight: CGFloat = 32
        static let buttonMaxWidth: CGFloat = 91
        static let buttonMinWidth: CGFloat = 72
        static let buttonInset: CGFloat = 8
        static let buttonItemSpace: CGFloat = 8
        static let buttonCornerRadius: CGFloat = 6
        static let viewHeight: CGFloat = Layout.buttonHeight + Layout.contentInset.top + Layout.contentInset.bottom
    }
    enum Style {
        static let buttonDefaultFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        static let rightBtnTitleDefaultColor = UIColor.ud.colorfulBlue
        static let rightBtnTitleDefaultBackColor = UIColor.ud.primaryOnPrimaryFill
        static let leftBtnTitleColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        static let leftBtnTitleDefaultBackColor = UIColor.ud.primaryFillHover
        static let letTitleDefaultTextColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
    }
}
