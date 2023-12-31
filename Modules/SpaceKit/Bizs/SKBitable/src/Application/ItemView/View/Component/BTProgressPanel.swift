//
//  BTProgressPanel.swift
//  SKBitable
//
//  Created by yinyuan on 2022/11/20.
//
import UIKit
import RxCocoa
import RxSwift
import RxRelay
import SKCommon
import SKUIKit
import UniverseDesignColor
import SKResource
import UniverseDesignInput
import UniverseDesignIcon

final class BTProgressPanel: UIView {

    weak var delegate: BTProgressPanelDelegate?
    
    private var keyboard: Keyboard?
    private var keyboardHeight: CGFloat = 0
    
    private final class Constants {
        static let mainViewHeight = 244.0
        static let mainViewFullHeight = 312.0 + 34.0
    }

    lazy var titleView = SKDraggableTitleView().construct { it in
        it.topLine.isHidden = true
        it.titleLabel.text = BundleI18n.SKResource.Bitable_Progress_SetProgress
        it.rightButton.setTitle(BundleI18n.SKResource.Bitable_Common_ButtonDone, for: .normal)
        it.rightButton.addTarget(self, action: #selector(doneClick), for: .touchUpInside)
        it.leftButton.isHidden = true
    }
    
    lazy var mainView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12.0
        view.layer.maskedCorners = .top
        view.layer.masksToBounds = true
        view.backgroundColor = UDColor.bgFloat
        
        view.layer.shadowColor = UIColor(red: 0.122, green: 0.137, blue: 0.161, alpha: 0.09).cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 8
        view.layer.shadowOffset = CGSize(width: 0, height: -4)
        
        view.addSubview(titleView)
        view.addSubview(slider)
        view.addSubview(progressTextField)
        
        titleView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(60)
        }
        slider.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(36)
            make.top.equalTo(titleView.snp.bottom).offset(32)
        }
        progressTextField.snp.makeConstraints { make in
            make.top.equalTo(slider.snp.bottom).offset(32)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(48)
        }
        return view
    }()
    
    lazy var progressTextField: BTUDConditionalTextField = {
        let view = BTUDConditionalTextField()
        view.config.isShowBorder = true
        view.config.clearButtonMode = .whileEditing
        view.input.keyboardType = .decimalPad
        let kbView = BTNumberKeyboardView(target: view.input)
        view.input.inputView = kbView
        view.input.inputAccessoryView = nil
        view.delegate = self
        view.baseContext = baseContext
        view.input.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
        return view
    }()
    
    lazy var slider: BTSlider = {
        let slider = BTSlider()
        slider.delegate = self
        return slider
    }()
    
    let baseContext: BaseContext?

    init(baseContext: BaseContext?) {
        self.baseContext = baseContext
        super.init(frame: .zero)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        layer.ud.setShadowColor(UDColor.shadowDefaultLg)
        layer.shadowOpacity = 1
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: -6)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeClick))
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)
        
        addSubview(mainView)

        mainView.snp.makeConstraints { make in
            make.height.equalTo(Constants.mainViewFullHeight)
            make.right.left.bottom.equalToSuperview()
        }
    }
    
    func show(completion: (() -> Void)? = nil) {
        self.mainView.transform = CGAffineTransformMakeTranslation(0, Constants.mainViewFullHeight)
        UIView.animate(withDuration: 0.25) {
            self.mainView.transform = CGAffineTransformMakeTranslation(0, 0)
        } completion: { (completed) in
            if completed { completion?() }
        }
        startKeyBoardObserver()
        self.progressTextField.input.becomeFirstResponder()
    }

    func hide(immediately: Bool, clickDone: Bool) {
        self.progressTextField.endEditing(true)
        if immediately {
            mainView.transform = CGAffineTransformMakeTranslation(0, Constants.mainViewFullHeight)
            self.layoutIfNeeded()
            self.didHide(clickDone: clickDone)
        } else {
            UIView.animate(withDuration: 0.25) {
                self.mainView.transform = CGAffineTransformMakeTranslation(0, Constants.mainViewFullHeight)
                self.backgroundColor = .clear
            } completion: { (completed) in
                if completed {
                    self.didHide(clickDone: clickDone)
                }
            }
        }
    }
    
    private func didHide(clickDone: Bool) {
        self.progressTextField.endEditing(true)
        keyboard?.stop()
        removeFromSuperview()
        delegate?.close(self, clickDone: clickDone)
    }
    
    @objc
    private func closeClick() {
        self.hide(immediately: false, clickDone: false)
    }
    
    @objc
    private func doneClick() {
        self.hide(immediately: false, clickDone: true)
    }
    
    @objc
    private func textFieldDidChange(textField: UITextField) {
        if textField.markedTextRange == nil || textField.markedTextRange?.isEmpty == true {
            self.delegate?.textFieldDidChange(self, textField: textField)
        }
    }
    
    private func startKeyBoardObserver() {
        keyboard = Keyboard(listenTo: [progressTextField.input], trigger: "bitableprogress")
        keyboard?.on(events: [.willShow, .didShow]) { [weak self] option in
            guard let self = self else { return }
            let offset = Constants.mainViewFullHeight - Constants.mainViewHeight
            let keyboardHeight = option.endFrame.height
            self.keyboardHeight = keyboardHeight
            self.mainView.transform = CGAffineTransformMakeTranslation(0, -keyboardHeight + offset)
        }
        keyboard?.on(events: [.willHide, .didHide]) { [weak self] _ in
            guard let self = self else { return }
            self.keyboardHeight = 0
            self.mainView.transform = CGAffineTransformMakeTranslation(0, 0)
        }
        keyboard?.start()
    }
}

extension BTProgressPanel: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == self ? true : false
    }
}

extension BTProgressPanel: UDTextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textFieldDidBeginEditing(self, textField: textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.textFieldDidEndEditing(self, textField: textField)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            self.progressTextField.endEditing(true)
            textFieldDidEndEditing(textField)
            return false
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.progressTextField.endEditing(true)
        textFieldDidEndEditing(textField)
        return true
    }
    
}

extension BTProgressPanel: BTSliderDelegate {
    func sliderValueChanged(slider: BTSlider, value: Double) {
        self.delegate?.progressChanged(self, value: value)
    }
}

protocol BTProgressPanelDelegate: AnyObject {
    func close(_ panel: BTProgressPanel, clickDone: Bool)
    func progressChanged(_ panel: BTProgressPanel, value: Double)
    func textFieldDidBeginEditing(_ panel: BTProgressPanel, textField: UITextField)
    func textFieldDidChange(_ panel: BTProgressPanel, textField: UITextField)
    func textFieldDidEndEditing(_ panel: BTProgressPanel, textField: UITextField)
}
