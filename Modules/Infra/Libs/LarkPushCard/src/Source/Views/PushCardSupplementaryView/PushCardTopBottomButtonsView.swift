//
//  PushCardTopBottomButtonsView.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/10/20.
//

import Foundation
import UIKit
import FigmaKit

protocol PushCardTopBottonButtonDelegate: AnyObject {
    func pushCardHeaderClickToStack()
    func pushCardHeaderClickClear()
}

final class PushCardTopBottomButtonsView: UIView {
    weak var delegate: PushCardTopBottonButtonDelegate?

    lazy var needClear: Bool = true

    private lazy var stackButton: UIButton = UIButton()
    private lazy var clearButton: UIButton = UIButton()
    private lazy var clearBlurView: BackgroundBlurView = BackgroundBlurView()
    private lazy var stackBlurView: BackgroundBlurView = BackgroundBlurView()
    private lazy var clearState: PushCardsCleanState = .closeIcon {
        didSet {
            self.updateButtonState()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setComponents()
        setAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.setBlurView(blurView: self.stackBlurView, button: self.stackButton)
        self.setBlurView(blurView: self.clearBlurView, button: self.clearButton)
    }

    func setBlurView(blurView: BackgroundBlurView, button: UIButton) {
        blurView.frame = button.bounds
        blurView.layer.shadowOpacity = 0
        blurView.isUserInteractionEnabled = false
        blurView.layer.borderWidth = Cons.borderWidth
        blurView.layer.cornerRadius = clearButton.layer.cornerRadius
        blurView.layer.masksToBounds = true
        blurView.layer.ud.setBorderColor(Colors.borderColor)
        blurView.fillColor = Colors.bgColor
        blurView.blurRadius = 50
        blurView.fillOpacity = 0.9
        StaticFunc.setShadow(on: blurView)
    }
}

private extension PushCardTopBottomButtonsView {
    func setComponents() {
        self.addSubview(stackButton)
        self.addSubview(clearButton)
    }

    func setAppearance() {
        setButton(stackButton,
                  title: BundleI18n.LarkPushCard.Lark_Meetings_ShowLessCard_Button,
                  image: nil)
        setButton(clearButton,
                  title: nil,
                  image: Cons.closeIcon)

        stackButton.addTarget(self, action: #selector(clickToStack), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clickClean), for: .touchUpInside)

        self.remakeButtonsConstraints()
        stackButton.insertSubview(stackBlurView, at: 0)
        stackButton.backgroundColor = .clear
        if #available(iOS 13.0, *) {
            clearButton.insertSubview(clearBlurView, at: 0)
            clearButton.backgroundColor = .clear
        } else {
            clearButton.layer.ud.setBorderColor(Colors.borderColor)
            clearButton.layer.borderWidth = Cons.borderWidth
            clearButton.backgroundColor = UIColor.ud.staticWhite
        }
    }

    func setButton(_ button: UIButton, title: String?, image: UIImage?) {
        button.setTitle(title, for: .normal)
        button.setImage(image, for: .normal)
        button.setTitleColor(Colors.buttonTitleColor, for: .normal)
        button.layer.cornerRadius = Cons.cardHeaderBtnHeight / 2
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: UIFont.Weight.regular)
    }
}

private extension PushCardTopBottomButtonsView {

    @objc
    func clickToStack() {
        self.delegate?.pushCardHeaderClickToStack()
        self.needClear = false
        self.clearState = .closeIcon
    }

    @objc
    func clickClean() {
        self.needClear = true
        self.clearState = (clearState == .clearText) ? .closeIcon : .clearText
    }

    func remakeButtonsConstraints() {
        self.clearButton.sizeToFit()
        self.clearButton.snp.remakeConstraints { make in
            switch self.clearState {
            case .clearText:
                make.width.equalTo(self.clearButton.frame.width + Cons.cardHeaderBtnPadding * 2)
                make.height.equalTo(Cons.cardHeaderBtnHeight)
            case .closeIcon:
                make.width.height.equalTo(Cons.cardHeaderBtnHeight)
            }
            make.centerY.equalTo(self.stackButton)
            make.trailing.equalToSuperview()
        }

        self.stackButton.sizeToFit()
        self.stackButton.snp.remakeConstraints { make in
            make.width.equalTo(stackButton.frame.width + Cons.cardHeaderBtnPadding * 2)
            make.height.equalTo(Cons.cardHeaderBtnHeight)
            make.trailing.equalTo(self.clearButton.snp.leading).offset(-Cons.cardHeaderButtonSpacing)
            make.centerY.equalToSuperview()
        }
    }

    func updateButtonState() {
        switch clearState {
        case .clearText:
            self.clearButton.setImage(nil, for: .normal)
            self.clearButton.setTitleColor(.clear, for: .normal)
            self.clearButton.setTitle(BundleI18n.LarkPushCard.Lark_Meetings_ClearAllCard_Button, for: .normal)
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
                self.clearButton.sizeToFit()
                self.clearButton.snp.remakeConstraints { make in
                    make.width.equalTo(self.clearButton.frame.width + Cons.cardHeaderBtnPadding * 2)
                    make.height.equalTo(Cons.cardHeaderBtnHeight)
                    make.centerY.equalTo(self.stackButton)
                    make.trailing.equalToSuperview()
                }
                self.layoutIfNeeded()
            } completion: { _ in
                self.clearButton.setTitleColor(Colors.buttonTitleColor, for: .normal)
                self.clearButton.addTarget(self, action: #selector(self.clickClean), for: .touchUpInside)
            }
        case .closeIcon:
            if needClear {
                self.delegate?.pushCardHeaderClickClear()
            }
            self.remakeButtonsConstraints()
            setButton(clearButton,
                      title: nil,
                      image: Cons.closeIcon)
        }
    }
}
