//
//  EncryptionUpgradeViewController.swift
//  LarkSecurityCompliance
//
//  Created by AlbertSun on 2023/5/16.
//

import Foundation
import SnapKit
import LarkUIKit
import RxSwift
import RxCocoa
import LarkSecurityComplianceInfra

import UniverseDesignColor
import UniverseDesignButton
import UniverseDesignTheme
import UniverseDesignFont
import UniverseDesignProgressView

struct States {
    let inProgress = EncryptionUpgradeStateInProgress()
    let succeeded = EncryptionUpgradeStateSucceeded()
    let failed = EncryptionUpgradeStateFailed()

    private let allStates: [EncryptionUpgradeState]

    init() {
        self.allStates = [inProgress, succeeded, failed]
    }

    subscript(state: EncryptionUpgrade.State) -> EncryptionUpgradeState {
        // swiftlint:disable:next implicit_getter
        get {
            switch state {
            case .inProgress:
                return inProgress
            case .succeeded:
                return succeeded
            case .failed:
                return failed
            }
        }
    }

    func onThemeChanged(withDarkMode: Bool) {
        allStates.forEach { $0.onThemeChange(withDarkMode: withDarkMode) }
    }
}

final class EncryptionUpgradeViewController: BaseViewController<EncryptionUpgradeViewModel> {

    var isRekeyInProgress: Bool {
        currentState == .inProgress
    }

    private let container = Container(frame: LayoutConfig.bounds, states: States())

    private let disposeBag = DisposeBag()

    private var currentState: EncryptionUpgrade.State = .inProgress {
        didSet {
            Logger.info("didset state:\(currentState)")
            if currentState != oldValue {
                updateOnStateChanged(currentState)
            }
        }
    }

    deinit {
        Logger.info("viewController deinit")
    }

    private var latestProgress = EncryptionUpgrade.Progress(percentage: 0, eta: 0) {
        didSet {
            Logger.info("didset progress:\(latestProgress)")
            updateLatestProgress(latestProgress)
        }
    }

    override func loadView() {
        Logger.info("load container")
        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        isNavigationBarHidden = true
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Logger.info("view did appear")
        viewModel.trackStateShow(currentState)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Logger.info("view did disappear")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        Logger.info("trait did change")
        guard #available(iOS 13.0, *),
              traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            return
        }

        let isDarkModeTheme = self.traitCollection.userInterfaceStyle == .dark
        Logger.info("theme changed to dark mode:\(isDarkModeTheme)")
        container.states.onThemeChanged(withDarkMode: isDarkModeTheme)
        updateImageOnThemeChange()
    }

    private func bindViewModel() {
        viewModel.stateUpdateSignal
            .drive { [weak self] state in
                Logger.info("receive state signal:\(state)")
                self?.currentState = state
            }.disposed(by: disposeBag)

        viewModel.progressUpdateSignal
            .filter { [weak self] _ in
                self?.currentState == .inProgress
            }
            .drive { [weak self] progress in
                Logger.info("receive progress signal:\(progress)")
                self?.latestProgress = progress
            }.disposed(by: disposeBag)

        viewModel.skipButton
            .map { [weak self] in self }
            .bind(to: viewModel.skipAlertShow)
            .disposed(by: disposeBag)

        viewModel.laterButton
            .map { [weak self] in self }
            .bind(to: viewModel.laterAlertShow)
            .disposed(by: disposeBag)

        container.skipButton.rx.tap
            .bind(to: viewModel.skipButton)
            .disposed(by: disposeBag)

        container.tryAgainButton.rx.tap
            .bind(to: viewModel.retryButton)
            .disposed(by: disposeBag)

        container.updateLaterButton.rx.tap
            .bind(to: viewModel.laterButton)
            .disposed(by: disposeBag)
    }

    private func updateOnStateChanged(_ state: EncryptionUpgrade.State) {
        container.state = state
        viewModel.trackStateShow(state)
    }

    private func updateLatestProgress(_ progress: EncryptionUpgrade.Progress) {
        container.states.inProgress.progress = progress
    }

    private func updateImageOnThemeChange() {
        container.imageView.image = container.states[currentState].image
    }
}

private final class Container: UIView {

    private let disposeBag = DisposeBag()

    let infoContainer = UIView()

    let imageView = UIImageView()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    let descLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    let successProgressBarContainer = UIView()

    let progressBarFilled: UDProgressView
    let progressBarUnFilled: UDProgressView
    let checkBoxView: UIImageView
    let skipButton: UIButton
    let updateLaterButton: UIButton
    let tryAgainButton: UIButton

    let states: States

    var state: EncryptionUpgrade.State = .inProgress {
        didSet {
            updateUI(with: state)
            states[oldValue].hide()
            states[state].show()
            Logger.info("state view changed from \(oldValue) to \(state)")
        }
    }

    init(frame: CGRect, states: States) {
        self.states = states
        // set up consoles
        progressBarUnFilled = states.inProgress.progressBar
        skipButton = states.inProgress.rightCornerSkipButton

        progressBarFilled = states.succeeded.progressBar
        checkBoxView = states.succeeded.checkBoxView

        updateLaterButton = states.failed.updateLaterButton
        tryAgainButton = states.failed.tryAgainButton

        super.init(frame: frame)

        var isDarkModeTheme = false
        if #available(iOS 13.0, *) {
            isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        states.onThemeChanged(withDarkMode: isDarkModeTheme)

        // set up default ui
        titleLabel.text = states.inProgress.title
        descLabel.text = states.inProgress.text
        imageView.image = states.inProgress.image

        setupViews()
        bindEtaUpdate()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private func setupViews() {
        addSubview(infoContainer)
        addSubview(skipButton)
        infoContainer.addSubview(imageView)
        infoContainer.addSubview(titleLabel)
        infoContainer.addSubview(descLabel)
        infoContainer.addSubview(progressBarUnFilled)
        infoContainer.addSubview(successProgressBarContainer)
        infoContainer.addSubview(tryAgainButton)
        infoContainer.addSubview(updateLaterButton)
        successProgressBarContainer.addSubview(progressBarFilled)
        successProgressBarContainer.addSubview(checkBoxView)

        infoContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.right.equalTo(LayoutConfig.safeAreaInsets.right).offset(-46)
            make.left.equalTo(LayoutConfig.safeAreaInsets.left).offset(46)
        }

        imageView.snp.makeConstraints { make in
            make.centerX.top.equalToSuperview()
            make.width.height.equalTo(120)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(24)
            make.top.equalTo(imageView.snp.bottom).offset(20)
        }

        descLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(Display.pad ? 480 : 290)
            make.right.left.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }

        progressBarUnFilled.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(272)
            make.top.equalTo(descLabel.snp.bottom).offset(20)
        }

        successProgressBarContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(295)
            make.top.equalTo(descLabel.snp.bottom).offset(20)
        }

        progressBarFilled.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
            make.width.equalTo(272)
        }

        checkBoxView.snp.makeConstraints { make in
            make.centerY.equalTo(progressBarFilled)
            make.width.height.equalTo(11)
            make.left.equalTo(progressBarFilled.snp.right).offset(12)
        }

        tryAgainButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(48)
            make.width.equalTo(Display.pad ? 280 : 257)
            make.top.equalTo(descLabel.snp.bottom).offset(16)
        }

        updateLaterButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(48)
            make.width.equalTo(Display.pad ? 280 : 257)
            make.top.equalTo(tryAgainButton.snp.bottom).offset(12)
            make.bottom.equalToSuperview()
        }

        skipButton.snp.makeConstraints { make in
            make.top.equalTo(LayoutConfig.safeAreaInsets.top).offset(55)
            make.height.equalTo(22)
            make.width.greaterThanOrEqualTo(32)
            make.right.equalTo(LayoutConfig.safeAreaInsets.right)
        }
    }
}

// update UI
extension Container {
    private func updateUI(with type: EncryptionUpgrade.State) {
        Logger.info("container update UI on state change:\(type)")
        titleLabel.text = states[type].title
        imageView.image = states[type].image
        descLabel.text = states[type].text
    }

    private func bindEtaUpdate() {
        states.inProgress.textSignal
            .drive(self.descLabel.rx.text)
            .disposed(by: disposeBag)
    }
}
