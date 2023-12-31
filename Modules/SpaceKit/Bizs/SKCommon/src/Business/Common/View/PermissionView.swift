//
//  PermissionView.swift
//  SpaceKit
//
//  Created by Ryan on 2019/2/15.
//

import UIKit
import SKResource
import SKFoundation
import SKUIKit
import RxSwift
import RxCocoa
import SnapKit
import UniverseDesignColor
import UniverseDesignActionPanel
import UniverseDesignEmpty
import UniverseDesignInput

public final class PermissionView: UIControl {
    private lazy var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: emptyConfig)
        emptyView.useCenterConstraints = true
        return emptyView
    }()
    private lazy var emptyConfig: UDEmptyConfig = {
        let config = UDEmptyConfig(title: .init(titleText: BundleI18n.SKResource.Doc_Permission_NoPermissionAccess),
                                   type: .noAccess)
        return config
    }()
    
    private lazy var line1: UIView = createLineView()
    private lazy var line2: UIView = createLineView()
    private lazy var line3: UIView = createLineView()

    private var permRole: Int = 1
    private var isFolderV2: Bool = false


    private lazy var applyLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.N500
        label.text = BundleI18n.SKResource.Doc_Facade_ApplyFor
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    public lazy var markTextField: UDTextField = {
        let textField = UDTextField()
        var config = UDTextFieldUIConfig()
        config.textColor = UIColor.ud.N500
        config.font = UIFont.systemFont(ofSize: 14)

        textField.config = config
        textField.placeholder = BundleI18n.SKResource.Doc_Facade_AddRemarks
        return textField
    }()

    private lazy var memberLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.colorfulBlue
        label.text = BundleI18n.SKResource.Doc_Facade_Member
        label.font = UIFont.systemFont(ofSize: 14)
        label.isUserInteractionEnabled = true
        return label
    }()

    public lazy var sendRequestButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.Doc_Facade_SendRequest, for: .normal)
        button.setTitleColor(UDColor.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = UIColor.ud.colorfulBlue
        button.layer.cornerRadius = 6
        return button
    }()

    private func createLineView() -> UIView { //() -> UIView in
        let view = UIView()
        view.backgroundColor = UIColor.ud.N300
        return view
    }

    public var requestPermissionHandler: ((String?, Int) -> Void)?
    public var presentHandler: ((UIViewController) -> Void)?

    private let disposeBag = DisposeBag()
    private let keyboard = Keyboard()
    private var keyboardConstraint: Constraint?

    public init(isFolderV2: Bool) {
        self.isFolderV2 = isFolderV2
        super.init(frame: .zero)
        setupUI()
        setupKeyboardMonitor()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBody
        addSubview(emptyView)
        emptyView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(160).priority(.low)
            make.left.right.equalToSuperview()
        }

        addSubview(line1)
        line1.snp.makeConstraints { (make) in
            make.top.equalTo(emptyView.snp.bottom).offset(36)
            make.left.equalTo(34)
            make.right.equalTo(-34)
            make.height.equalTo(0.5)
        }
        addSubview(applyLabel)
        applyLabel.snp.makeConstraints { (make) in
            make.left.equalTo(line1)
            make.top.equalTo(line1.snp.bottom).offset(20)
        }

        addSubview(memberLabel)
        memberLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(applyLabel.snp.centerY)
            make.right.equalTo(line1)
        }

        addSubview(line2)
        line2.snp.makeConstraints { (make) in
            make.top.greaterThanOrEqualToSuperview().priority(.required)
            make.top.equalTo(applyLabel.snp.bottom).offset(20)
            make.left.equalTo(34)
            make.right.equalTo(-34)
            make.height.equalTo(0.5)
        }

        addSubview(markTextField)
        markTextField.snp.makeConstraints { (make) in
            make.left.right.equalTo(line1)
            make.top.equalTo(line2.snp.bottom).offset(20)
        }

        addSubview(line3)
        line3.snp.makeConstraints { (make) in
            make.top.equalTo(markTextField.snp.bottom).offset(20)
            make.left.equalTo(34)
            make.right.equalTo(-34)
            make.height.equalTo(0.5)
        }

        addSubview(sendRequestButton)
        sendRequestButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.left.equalTo(34)
            make.right.equalTo(-34)
            make.height.equalTo(40)
            make.top.equalTo(line3.snp.bottom).offset(50)
            keyboardConstraint = make.bottom.equalToSuperview().priority(.high).constraint
        }
        keyboardConstraint?.deactivate()

        rx.controlEvent(.touchUpInside)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                if self.markTextField.isFirstResponder {
                    self.markTextField.resignFirstResponder()
                }
            })
            .disposed(by: disposeBag)

        sendRequestButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                guard let handler = self.requestPermissionHandler else {
                    spaceAssertionFailure("request permission handler is nil")
                    return
                }
                handler(self.markTextField.text, self.permRole)
            })
        .disposed(by: disposeBag)
        
        if isFolderV2 {
            memberLabel.text = BundleI18n.SKResource.Drive_Drive_ReadPermission
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapMemberLabelAction(_:)))
            memberLabel.addGestureRecognizer(tap)
        }
    }

    public func update(ownerName: String) {
        emptyConfig.description = .init(descriptionText: BundleI18n.SKResource.Doc_Share_ShareOwner + ": " + ownerName)
        emptyView.update(config: emptyConfig)
    }

    /// 外部租户需要隐藏申请按钮等内容
    public func hideForOutsideCompany() {
        line1.isHidden = true
        line2.isHidden = true
        line3.isHidden = true
        applyLabel.isHidden = true
        memberLabel.isHidden = true
        markTextField.isHidden = true
        sendRequestButton.isHidden = true

        sendRequestButton.isUserInteractionEnabled = false
        emptyView.snp.remakeConstraints { (make) in
            make.center.left.right.equalToSuperview()
        }
}

    public func showApplyPermissionInterface() {
        line1.isHidden = false
        line2.isHidden = false
        line3.isHidden = false
        applyLabel.isHidden = false
        memberLabel.isHidden = false
        markTextField.isHidden = false
        sendRequestButton.isHidden = false

        sendRequestButton.isUserInteractionEnabled = true
        emptyView.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(160).priority(.low)
            make.left.right.equalToSuperview()
        }
    }
    
    @objc
    private func handleTapMemberLabelAction(_ recognizer: UIGestureRecognizer) {
        let isReadPermission = (permRole == 1)
        let actionSheet = UDActionSheet.actionSheet()
        actionSheet.addItem(text: BundleI18n.SKResource.Drive_Drive_ReadPermission, textColor: isReadPermission ? UIColor.ud.colorfulBlue : UIColor.ud.N900) { [weak self] in
            self?.memberLabel.text = BundleI18n.SKResource.Drive_Drive_ReadPermission
            self?.permRole = 1
        }
        actionSheet.addItem(text: BundleI18n.SKResource.Drive_Drive_EditPermission, textColor: !isReadPermission ? UIColor.ud.colorfulBlue : UIColor.ud.N900) { [weak self] in
            self?.memberLabel.text = BundleI18n.SKResource.Drive_Drive_EditPermission
            self?.permRole = 2
        }
        actionSheet.addItem(text: BundleI18n.SKResource.Drive_Drive_Cancel, style: .cancel)
        self.presentHandler?(actionSheet)
    }

    private func setupKeyboardMonitor() {
        keyboard.on(event: .willShow) { [weak self] opt in
            self?.updateKeyboardConstraintIfNeed(keyboardFrame: opt.endFrame, animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .didShow) { [weak self] opt in
            self?.updateKeyboardConstraintIfNeed(keyboardFrame: opt.endFrame, animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .willHide) { [weak self] opt in
            self?.resetKeyboardConstraint(animationDuration: opt.animationDuration)
        }
        keyboard.on(event: .didHide) { [weak self] _ in
            self?.resetKeyboardConstraint(animationDuration: nil)
        }
        keyboard.start()
    }

    private func updateKeyboardConstraintIfNeed(keyboardFrame: CGRect, animationDuration: Double?) {
        keyboardConstraint?.activate()
        sendRequestButton.snp.updateConstraints { make in
            make.bottom.equalToSuperview().inset(keyboardFrame.height).priority(.high)
        }
        if let duration = animationDuration {
            UIView.animate(withDuration: duration) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }

    private func resetKeyboardConstraint(animationDuration: Double?) {
        keyboardConstraint?.deactivate()
        if let duration = animationDuration {
            UIView.animate(withDuration: duration) {
                self.layoutIfNeeded()
            }
        } else {
            layoutIfNeeded()
        }
    }
}
