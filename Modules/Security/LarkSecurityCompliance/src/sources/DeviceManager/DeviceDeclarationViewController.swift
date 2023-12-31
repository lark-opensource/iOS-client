//
//  DeviceDeclarationViewController.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/10/19.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignIcon
import LarkButton
import RxSwift
import RxCocoa
import LarkContainer
import EditTextView
import LarkSecurityComplianceInfra

final class DeviceDeclarationViewController: BaseViewController<DeviceStatusViewModel> {
    
    enum Applicability {
        case unapplicable
        case applicable
        case loading
    }
    
    private let disposeBag = DisposeBag()
    private static let characterLimit = 255
    
    private(set) var applyConfirmedButton: UIButton?
    private let justificationInputView = DeviceDeclarationJustificationInputView(characterLimit: characterLimit)

    private var applicability: Applicability = .unapplicable {
        didSet {
            guard applicability != oldValue else { return }
            Logger.info("applicability changed to \(applicability)")
            
            guard let button = applyConfirmedButton else { return }
            switch applicability {
            case .loading:
                button.setTitleColor(UIColor.ud.primaryContentLoading, for: .normal)
            case .applicable:
                button.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
            default:
                button.setTitleColor(UIColor.ud.N400, for: .normal)
            }
            
            button.isEnabled = applicability == .applicable
            navigationItem.leftBarButtonItem?.isEnabled = applicability != .loading
            justificationInputView.isEditable = applicability != .loading
            showLoading(applicability == .loading)
        }
    }
    
    private let loadingIcon: UIImageView = {
        let imageView = UIImageView(image: UDIcon.getIconByKey(.loadingOutlined,
                                                               iconColor: UIColor.ud.primaryContentDefault))
        imageView.isHidden = true
        return imageView
    }()
    
    private func showLoading(_ loading: Bool) {
        if loading {
            loadingIcon.isHidden = false
            loadingIcon.startRotationAnimation()
        } else {
            loadingIcon.isHidden = true
            loadingIcon.stopRotationAnimation()
        }
    }

    override var navigationBarStyle: NavigationBarStyle {
        .custom(UIColor.ud.bgFloat)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = I18N.Lark_SelfDeclareDevice_Title_DeclareReason
        supportSecondaryOnly = true
        view.backgroundColor = UIColor.ud.bgFloatBase
        addNavigationBarRightItem()
        applicability = .applicable
        addCancelItem()
        setupUI()
        bindViewModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Logger.info("device declaration vc presented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        justificationInputView.textField.becomeFirstResponder()
    }
    
    private func setupUI() {
        view.addSubview(justificationInputView)
        justificationInputView.layer.cornerRadius = 10.0
        justificationInputView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview()
        }
        
        if let rightButton = navigationItem.rightBarButtonItem?.customView {
            rightButton.addSubview(loadingIcon)
            loadingIcon.snp.makeConstraints { make in
                make.width.height.equalTo(16)
                make.centerY.equalToSuperview()
                make.right.equalTo(rightButton.snp.left).offset(-4)
            }
        }
    }
    
    private func bindViewModel() {
        // bind applicable
        justificationInputView.rx.inputedText.asDriver(onErrorJustReturn: "")
            .compactMap( Self.isValidReasonText )
            .drive(onNext: { [weak self] isValid in
                guard let self else { return }
                self.navigationItem.rightBarButtonItem?.isEnabled = isValid
                self.applicability = isValid ? .applicable : .unapplicable
            }).disposed(by: disposeBag)
        
        // 申报理由和vm绑定
        justificationInputView.textField.rx.text.orEmpty
            .distinctUntilChanged()
            .bind(to: viewModel.applyReasonText)
            .disposed(by: disposeBag)
        
        // 绑定点击事件，请求回来前进入loading状态
        applyConfirmedButton?.rx.tap.asDriver()
            .drive(onNext: { [weak self] _ in
                guard let self else { return }
                self.viewModel.applyConfirmedButton.onNext(())
                self.applicability = .loading
            }).disposed(by: disposeBag)
        
        // 请求成功退出页面，请求失败停留
        viewModel.applicationResp
            .observeOn(MainScheduler.instance)
            .bind { [weak self] success in
                Logger.info("applicationResp success:\(success)")
                guard let self else {
                    Logger.error("declaration vc is nil")
                    return
                }
                if success {
                    self.dismiss(animated: true) {
                        self.viewModel.deviceDeclarationDismissed.onNext(true)
                    }
                } else {
                    self.applicability = .applicable
                }
            }.disposed(by: disposeBag)
    }
    
    private func addNavigationBarRightItem() {
        let rightItem = LKBarButtonItem(title: I18N.Lark_SelfDeclareDevice_Button_SelfDecareConfirm, fontStyle: .medium)
        rightItem.setProperty(font: LKBarButtonItem.FontStyle.medium.font, alignment: .right)
        rightItem.setBtnColor(color: UIColor.ud.N400)
        applyConfirmedButton = rightItem.button
        navigationItem.rightBarButtonItem = rightItem
    }
    
    private static func isValidReasonText(_ str: String) -> Bool {
        let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count <= characterLimit
    }
}

final class DeviceDeclarationJustificationInputView: UIView {
    private let disposeBag = DisposeBag()
    private let characterLimit: Int
    private static let font = UIFont.systemFont(ofSize: 16)
    private static let backgroundColor = UIColor.ud.bgFloat
    private static let disabledBgColor = UIColor.ud.udtokenInputBgDisabled
    private static let foregroundColor = UIColor.ud.N900
    private static let placeholderColor = UIColor.ud.textPlaceholder
    
    fileprivate let textIMEFiltered = PublishSubject<String>()
    
    fileprivate var isEditable: Bool = true {
        didSet {
            textField.backgroundColor = isEditable ? Self.backgroundColor : Self.disabledBgColor
            textField.textColor = isEditable ? UIColor.ud.textTitle : Self.placeholderColor
            textField.isUserInteractionEnabled = isEditable
        }
    }
    
    fileprivate let textField: LarkEditTextView = {
        let view = LarkEditTextView()
        view.supportNewLine = true
        view.defaultTypingAttributes = [
            .font: font,
            .foregroundColor: foregroundColor
        ]
        view.attributedPlaceholder = NSAttributedString(string: I18N.Lark_SelfDeclareDevice_PH_EnterText,
                                                        attributes: [.foregroundColor: placeholderColor, .font: font])
        view.isScrollEnabled = false
        view.textAlignment = .left
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
        view.backgroundColor = backgroundColor
        view.bdp_cornerRadius = 4
        return view
    }()

    private let textCountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    init(characterLimit: Int) {
        self.characterLimit = characterLimit
        super.init(frame: .zero)
        self.backgroundColor = backgroundColor
        setupUI()
        bindUI()
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    private func setupUI() {
        addSubview(textField)
        addSubview(textCountLabel)
        textField.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(136)
        }
        textCountLabel.snp.makeConstraints { (make) in
            make.height.equalTo(18)
            make.right.equalToSuperview().offset(-12)
            make.bottom.equalTo(textField.snp.bottom).offset(-8)
        }
        let attr = NSAttributedString(string: "\(0)/\(characterLimit)",
                                      attributes: [.foregroundColor: Self.foregroundColor])
        textCountLabel.attributedText = attr
    }
    
    private func bindUI() {
        textField.rx.text.orEmpty.asDriver()
            .distinctUntilChanged()
            .compactMap { [weak self] str -> NSAttributedString? in
                guard let self else { return nil }
                let count: Int
                var attrStr: NSMutableAttributedString
                // filter text from IME
                if let markedRange = textField.markedTextRange, !markedRange.isEmpty {
                    count = str.count - textField.offset(from: markedRange.start, to: markedRange.end)
                    textIMEFiltered.onNext(String(str.prefix(count)))
                } else {
                    count = str.count
                    textIMEFiltered.onNext(str)
                }
                if count > characterLimit {
                    attrStr = NSMutableAttributedString(string: "\(count)",
                                                     attributes: [.foregroundColor: UIColor.ud.colorfulRed])
                    attrStr.append(NSAttributedString(string: "/\(characterLimit)",
                                                      attributes: [.foregroundColor: UIColor.ud.N500]))
                } else {
                    attrStr = NSMutableAttributedString(string: "\(count)/\(characterLimit)",
                                                        attributes: [.foregroundColor: UIColor.ud.N500])
                }
                return attrStr
            }.drive(onNext: { [weak self] text in
                guard let self else { return }
                self.textCountLabel.attributedText = text
                self.makeScrollableIfNeeded()
            }).disposed(by: disposeBag)
    }
    
    private func makeScrollableIfNeeded() {
        let sizeToFit = textField.sizeThatFits(CGSize(width: textField.frame.width, height: CGFLOAT_MAX))
        if sizeToFit.height > textField.frame.height {
            textField.isScrollEnabled = true
            textField.showsVerticalScrollIndicator = true
        }
    }
}

extension Reactive where Base: DeviceDeclarationJustificationInputView {
    fileprivate var inputedText: Observable<String> {
        base.textIMEFiltered.asObserver()
    }
}

private extension UIImageView {
    func startRotationAnimation() {
        stopRotationAnimation()
        layer.speed = 1
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.byValue = Float.pi * 2
        rotationAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        let groupAnimation = CAAnimationGroup()
        groupAnimation.animations = [rotationAnimation]
        groupAnimation.duration = 1.0
        groupAnimation.repeatCount = .infinity
        groupAnimation.isRemovedOnCompletion = false
        groupAnimation.fillMode = .forwards
        layer.add(groupAnimation, forKey: "animation")
    }
    func stopRotationAnimation() {
        layer.removeAllAnimations()
    }
}
