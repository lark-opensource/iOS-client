//
//  PasswordRequirementView.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/11/29.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import SnapKit
import RxSwift
import RxCocoa
import SKUIKit
import SKResource

class PasswordRequirementView: UIView {
    
    private let iconView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    private let viewModel: PasswordRequirementViewModel
    private let disposeBag = DisposeBag()

    init(viewModel: PasswordRequirementViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupUI()
        setupVM()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        isUserInteractionEnabled = false
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.left.equalToSuperview()
            make.top.equalToSuperview().inset(3)
        }
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(2.5)
            make.right.equalToSuperview()
            make.left.equalTo(iconView.snp.right).offset(4)
        }
    }

    func setupVM() {
        let paragraphStyle = NSMutableParagraphStyle()
        let font = UIFont.systemFont(ofSize: 16)
        paragraphStyle.lineSpacing = 2.5
//        paragraphStyle.paragraphSpacingBefore = paragraphStyle.lineSpacing / 2
        titleLabel.attributedText = NSAttributedString(string: viewModel.message, attributes: [.paragraphStyle: paragraphStyle])

        viewModel.visableDriver.drive(onNext: { [weak self] visable in
            self?.isHidden = !visable
        })
        .disposed(by: disposeBag)

        viewModel.stateDriver.drive(onNext: { [weak self] state in
            self?.update(state: state)
        })
        .disposed(by: disposeBag)
    }

    private func update(state: CustomPasswordViewModel.State) {
        switch state {
        case .notify:
            titleLabel.textColor = UDColor.textTitle
            iconView.image = UDIcon.succeedHollowFilled.ud.withTintColor(UDColor.iconDisabled)
        case .pass:
            titleLabel.textColor = UDColor.textTitle
            iconView.image = UDIcon.succeedHollowFilled.ud.withTintColor(UDColor.functionSuccess400)
        case .warning:
            titleLabel.textColor = UDColor.functionDanger400
            iconView.image = UDIcon.errorColorful
        }
    }
}

class PasswordNaviBar: UIView {

    let cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.LarkCCM_CM_CustomPassword_Cancel_Button
,
                        for: .normal)
        button.setTitleColor(UDColor.textTitle, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        return button
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.LarkCCM_CM_CustomPassword_ChangePassword_Title

        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textColor = UDColor.textTitle
        return label
    }()

    let saveButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.LarkCCM_CM_CustomPassword_Save_Button
,
                        for: .normal)
        button.setTitleColor(UDColor.textLinkNormal, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        return button
    }()

    private let divider: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 48)
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(cancelButton)
        addSubview(titleLabel)
        addSubview(saveButton)
        addSubview(divider)

        cancelButton.snp.makeConstraints { make in
            make.left.equalTo(safeAreaLayoutGuide.snp.left).inset(12)
            make.top.equalTo(safeAreaLayoutGuide.snp.top).inset(12)
            make.height.equalTo(22)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(cancelButton)
        }

        saveButton.snp.makeConstraints { make in
            make.right.equalTo(safeAreaLayoutGuide.snp.right).inset(12)
            make.centerY.equalTo(cancelButton)
            make.height.equalTo(22)
        }

        divider.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.left.right.bottom.equalToSuperview()
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard super.point(inside: point, with: event) else { return false }
        for subview in subviews {
            guard !subview.isHidden, subview.alpha > 0, subview.isUserInteractionEnabled else {
                continue
            }
            let pointInSubview = convert(point, to: subview)
            if subview.point(inside: pointInSubview, with: event) {
                return true
            }
        }
        return false
    }
}


class PasswordHeaderView: UIView {
    private let passwordLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textCaption
        label.font = .systemFont(ofSize: 16)
        label.text = BundleI18n.SKResource.LarkCCM_CM_CustomPassword_Password_Title

        return label
    }()

    let randomButton: UIButton = {
        let button = UIButton()
        button.setTitle(BundleI18n.SKResource.LarkCCM_CM_CustomPassword_RandomGenerated_Button,
                        for: .normal)
        button.setTitleColor(UDColor.textLinkHover, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(passwordLabel)
        passwordLabel.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
        }
        addSubview(randomButton)
        randomButton.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard super.point(inside: point, with: event) else { return false }
        for subview in subviews {
            guard !subview.isHidden, subview.alpha > 0, subview.isUserInteractionEnabled else {
                continue
            }
            let pointInSubview = convert(point, to: subview)
            if subview.point(inside: pointInSubview, with: event) {
                return true
            }
        }
        return false
    }
}

class PasswordLevelIndicatorView: UIView {

    private class IndicatorView: UIView {
        override var intrinsicContentSize: CGSize { CGSize(width: 21, height: 4) }
    }

    private let stackView: UIStackView = {
        let view = PassThroughStackView()
        view.axis = .horizontal
        view.spacing = 2
        view.alignment = .center
        view.distribution = .fill
        return view
    }()

    private let levelLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    private let weakIndicator = IndicatorView()
    private let middleIndicator = IndicatorView()
    private let strongIndicator = IndicatorView()
    private let levelModel: CustomPasswordViewModel.LevelModel
    private let disposeBag = DisposeBag()

    init(levelModel: CustomPasswordViewModel.LevelModel, externalVisableDriver: Driver<Bool>) {
        self.levelModel = levelModel
        super.init(frame: .zero)
        setupUI()
        setupVM(externalVisableDriver: externalVisableDriver)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        isUserInteractionEnabled = false
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.top.bottom.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        stackView.addArrangedSubview(levelLabel)
        levelLabel.snp.makeConstraints { make in
            make.height.equalTo(20)
        }
        stackView.setCustomSpacing(4, after: levelLabel)
        stackView.addArrangedSubview(weakIndicator)
        stackView.addArrangedSubview(middleIndicator)
        stackView.addArrangedSubview(strongIndicator)
    }

    private func setupVM(externalVisableDriver: Driver<Bool>) {
        Driver.combineLatest(levelModel.visableDriver, externalVisableDriver) { $0 && $1 }
            .drive(onNext: { [weak self] visable in
                self?.isHidden = !visable
            })
            .disposed(by: disposeBag)

        levelModel.levelDriver.drive(onNext: { [weak self] level in
            self?.update(level: level)
        })
        .disposed(by: disposeBag)
    }

    private func update(level: PasswordLevelRule.Level) {
        switch level {
        case let .strong(message):
            [weakIndicator, middleIndicator, strongIndicator].forEach { indicator in
                indicator.backgroundColor = UDColor.functionSuccess400
            }

            levelLabel.text = message
            levelLabel.textColor = UDColor.functionSuccess400
        case let .middle(message):
            [weakIndicator, middleIndicator].forEach { indicator in
                indicator.backgroundColor = UDColor.textLinkHover
            }
            strongIndicator.backgroundColor = UDColor.iconDisabled

            levelLabel.text = message
            levelLabel.textColor = UDColor.textLinkHover
        case let .weak(message):
            weakIndicator.backgroundColor = UDColor.functionWarning350
            [middleIndicator, strongIndicator].forEach { indicator in
                indicator.backgroundColor = UDColor.iconDisabled
            }

            levelLabel.text = message
            levelLabel.textColor = UDColor.functionWarning350
        case .unknown:
            [weakIndicator, middleIndicator, strongIndicator].forEach { indicator in
                indicator.backgroundColor = UDColor.iconDisabled
            }

            levelLabel.text = nil
            levelLabel.textColor = UDColor.iconDisabled
        }
    }
}
