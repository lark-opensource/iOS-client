//
//  SensitivityViewControl.swift
//  LarkSecurityCompliance
//
//  Created by bytedance on 2022/9/1.
//

import UIKit
import UniverseDesignEmpty
import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignTheme
import UniverseDesignDialog
import UniverseDesignFont
import UniverseDesignToast
import RxSwift
import RxCocoa
import SnapKit
import LarkUIKit
import LarkSecurityComplianceInfra
import LarkSecurityCompliance

final class SensitivityViewControl: BaseViewController<SensitivityControlViewModel>, UITextFieldDelegate {

    private let container = Container(frame: LayoutConfig.bounds)
    private let bag = DisposeBag()

    override func loadView() {
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        isNavigationBarHidden = true
        bindViewModel()
        container.textField.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            // 如果当前设置主题一致，则不需要切换资源
            return
        }

        let isDarkModeTheme = self.traitCollection.userInterfaceStyle == .dark

        let topColor: UIColor = isDarkModeTheme ? UIColor.ud.rgb("#192031") : UIColor.ud.rgb("#DFE9FF")
        let bottomColor: UIColor = isDarkModeTheme ? UIColor.ud.rgb("#191A1C") : UIColor.ud.rgb("#FFFFFF").withAlphaComponent(0)
        container.gradientViewHeader.colors = [topColor, bottomColor]
        container.gradientViewHeader.layoutIfNeeded()
    }

    private func bindViewModel() {
        container.pasteBoardTestButton.rx.tap
            .bind(to: viewModel.sensitivityControlPasteboardTest)
            .disposed(by: bag)
        container.originPasteBoardTestButton.rx.tap
            .bind(to: viewModel.sensitivityControlOriginPasteboardTest)
            .disposed(by: bag)
        container.locationTestButton.rx.tap
            .bind(to: viewModel.sensitivityControlLocationTest)
            .disposed(by: bag)
        container.locationTestLaterButton.rx.tap
            .bind(to: viewModel.sensitivityControlLocationLaterTest)
            .disposed(by: bag)
        container.iPTestButton.rx.tap
            .bind(to: viewModel.sensitivityControlIPTest)
            .disposed(by: bag)
        container.iPTestLaterButton.rx.tap
            .bind(to: viewModel.sensitivityControlIPLaterTest)
            .disposed(by: bag)
        container.closeButton.rx.tap
            .bind(to: viewModel.dismissCurrentWindow)
            .disposed(by: bag)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // 收起键盘
        textField.resignFirstResponder()
        viewModel.tokenIdentifier = textField.text
        return true
    }

}

private final class Container: UIView, UITextFieldDelegate {

    let bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    let centerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    let detailView = DetailView(frame: .zero)

    let textField: UITextField = {
        let field = UITextField(frame: .zero)
        field.borderStyle = UITextField.BorderStyle.roundedRect
        field.keyboardType = UIKeyboardType.asciiCapable
        field.resignFirstResponder()
        field.placeholder = "PasteboardTest"
        return field
    }()

    let pasteBoardTestButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.primaryBlue)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle("PasteBoard Test", for: .normal)
        return button
    }()

    let originPasteBoardTestButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.primaryBlue)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle("Origin PasteBoard Test", for: .normal)
        return button
    }()

    let locationTestButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.primaryBlue)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle("Location Test", for: .normal)
        return button
    }()

    let locationTestLaterButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.primaryBlue)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle("Location Test after 6s", for: .normal)
        return button
    }()

    let iPTestButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.primaryBlue)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle("IP Test", for: .normal)
        return button
    }()

    let iPTestLaterButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.primaryBlue)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle("IP Test after 6s", for: .normal)
        return button
    }()

    let closeButton: UDButton = {
        let button = UDButton(UDButtonUIConifg.secondaryGray)
        button.titleLabel?.font = UIFont.ud.title4
        button.setTitle("Close Page", for: .normal)
        return button
    }()

    let gradientViewHeader: GradientView = {
        let gradientView = GradientView()
        gradientView.backgroundColor = UIColor.clear
        gradientView.colors = [UIColor.ud.rgb("#DFE9FF") & UIColor.ud.rgb("#192031"),
                               UIColor.ud.rgb("#FFFFFF").withAlphaComponent(0) & UIColor.ud.rgb("#191A1C")]
        gradientView.automaticallyDims = false
        gradientView.direction = .vertical
        return gradientView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        var isDarkModeTheme: Bool = false
        if #available(iOS 13.0, *) {
            isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        let topColor: UIColor = isDarkModeTheme ? UIColor.ud.rgb("#192031") : UIColor.ud.rgb("#DFE9FF")
        let bottomColor: UIColor = isDarkModeTheme ? UIColor.ud.rgb("#191A1C") : UIColor.ud.rgb("#FFFFFF").withAlphaComponent(0)
        gradientViewHeader.colors = [topColor, bottomColor]

        addSubview(gradientViewHeader)

        addSubview(bgView)
        bgView.addSubview(centerView)
        centerView.addSubview(detailView)
        textField.delegate = self
        centerView.addSubview(textField)
        centerView.addSubview(pasteBoardTestButton)
        centerView.addSubview(originPasteBoardTestButton)
        centerView.addSubview(locationTestButton)
        centerView.addSubview(locationTestLaterButton)
        centerView.addSubview(iPTestButton)
        centerView.addSubview(iPTestLaterButton)
        centerView.addSubview(closeButton)

        setConstraints()

    }

    func setConstraints() {
        gradientViewHeader.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(240)
        }

        bgView.snp.makeConstraints { make in
            make.centerX.top.bottom.equalToSuperview()
            if Display.phone {
                make.width.equalToSuperview()
            } else {
                let width = min(400, LayoutConfig.bounds.width)
                make.width.equalTo(width)
            }
        }

        centerView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        detailView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.centerX.equalToSuperview().offset(12)
        }

        textField.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(48)
            make.top.equalTo(detailView.snp.bottom).offset(24)
        }

        pasteBoardTestButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(40)
            make.top.equalTo(textField.snp.bottom).offset(24)
        }

        originPasteBoardTestButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(40)
            make.top.equalTo(textField.snp.bottom).offset(74)
        }

        locationTestButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(40)
            make.top.equalTo(textField.snp.bottom).offset(124)
        }

        locationTestLaterButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(40)
            make.top.equalTo(textField.snp.bottom).offset(174)
        }

        iPTestButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(40)
            make.top.equalTo(textField.snp.bottom).offset(224)
        }

        iPTestLaterButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(40)
            make.top.equalTo(textField.snp.bottom).offset(274)
        }

        closeButton.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(40)
            make.top.equalTo(textField.snp.bottom).offset(324)
            make.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !Display.phone {
            let width = min(400, bounds.width)
            bgView.snp.updateConstraints { make in
                make.width.equalTo(width)
            }
        }
    }
}

private final class DetailView: UIView {

    let dotView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.textPlaceholder
        view.layer.cornerRadius = 3
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SensitivityControl Test"
        label.font = UIFont.ud.headline
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    let detailLabel: UILabel = {
        let label = UILabel()
        label.text = "Triggered by button below"
        label.font = UIFont.ud.body2
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.bgBase
        layer.cornerRadius = 8

        addSubview(dotView)
        addSubview(titleLabel)
        addSubview(detailLabel)

        dotView.snp.makeConstraints { make in
            make.size.equalTo(6)
            make.left.equalTo(16)
            make.top.equalTo(25)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(dotView.snp.right).offset(12)
            make.centerY.equalTo(dotView)
            make.right.lessThanOrEqualTo(-16)
        }
        detailLabel.snp.makeConstraints { make in
            make.left.equalTo(dotView.snp.right).offset(12)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.right.lessThanOrEqualTo(-16)
            make.bottom.equalTo(-20)
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }
}
