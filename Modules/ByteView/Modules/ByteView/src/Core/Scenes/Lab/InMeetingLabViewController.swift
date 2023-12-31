//
//  InMeetingLabViewController.swift
//  ByteView
//
//  Created by liquanmin on 2020/9/16.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//
// 设计图：https://www.figma.com/file/gNAhnQ7Uv1XsomEzlx9mCJ/V3.33%E7%A7%BB%E5%8A%A8%E7%AB%AF%E5%A2%9E%E5%8A%A0VCLabs?node-id=332%3A1357

import Foundation
import SnapKit
import UIKit
import UniverseDesignColor
import RxSwift
import Action
import RxCocoa
import UniverseDesignIcon
import ByteViewCommon
import ByteViewMeeting
import ByteViewTracker
import ByteViewRtcBridge
import ByteViewUI

struct InMeetingLabVCLayout {
    static func backTopMargin(isRegular: Bool) -> CGFloat {
        return isRegular ? 19 : 10
    }

    static func isRegular() -> Bool { VCScene.rootTraitCollection?.isRegular ?? false }

    static let regularWidth: CGFloat = 624
    static let regularHeight: CGFloat = 520
    static let regularMaxHeight: CGFloat = 746
}

class InMeetingLabViewController: BaseViewController {
    enum Location {
        case preview
        case lobby
        case preLobby
        case settings
    }
    var location: Location = .preview
    var perfWarningDisplayed = false

    var viewModel: InMeetingLabViewModel
    var isLandscapeMode: Bool { return viewModel.fromSource == .inMeet && currentLayoutContext.layoutType == .phoneLandscape } // preview进入特效不横屏
    lazy var labView: LabView = {
        var renderMode: ByteViewRenderMode = Display.phone ? .renderModeHidden : .renderModeFit
        let view = LabView(frame: .zero, vm: viewModel, renderMode: renderMode)
        return view
    }()

    private lazy var backButton: UIButton = {
        let button = EnlargeTouchButton(padding: 10)
        button.addInteraction(type: .highlight, shape: .roundedRect(CGSize(width: 44, height: 40), nil))
        if Display.pad {
            button.layer.shadowOpacity = 1.0
            button.layer.shadowRadius = 0.5
            button.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        }
        return button
    }()

    lazy var titleLable: UILabel = {
        let label = UILabel()
        label.text = I18n.View_G_Effects
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        return label
    }()

    lazy var tipsView: LabTipsView = {
        let tipsView = LabTipsView(frame: .zero, tipsText: I18n.View_VM_SettingsWillTakeEffectImmediately)
        tipsView.setContentHuggingPriority(.required, for: .vertical)
        return tipsView
    }()

    lazy var titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 0
        stackView.axis = .vertical
        return stackView
    }()

    var perfWarningView: PerfDegradeWarningView?

    /// 判断进入特效页前是否开启摄像头
    private var isCameraOn: Bool { viewModel.isCameraOnBeforeLab }

    /// 判断进入特效页前是否有特效
    let isEffect: Bool

    private var disposeBag = DisposeBag()

    // MARK: - 方法重载

    init(viewModel: InMeetingLabViewModel) {
        self.viewModel = viewModel
        self.isEffect = viewModel.effectManger.isEffectOn()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willBecomeActive),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)

        setupViews()
        setupNavigationBar()
        checkAndSetOrientation()
        self.layoutForTraitCollection(isRegular: VCScene.isRegular)
        viewModel.camera.delegate = self
    }

    override var shouldAutorotate: Bool {
        return viewModel.isFromInMeet ? true : false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return viewModel.isFromInMeet ? .allButUpsideDown : .portrait
    }

    func setupViews() {
        view.addSubview(labView)
        labView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        view.addSubview(backButton)
        backButton.addTarget(self, action: #selector(didClickBackButton), for: .touchUpInside)

        view.addSubview(titleStackView)
        self.titleStackView.addArrangedSubview(titleLable)
        if viewModel.fromSource == .inMeet {
            self.titleStackView.addArrangedSubview(tipsView)
            tipsView.snp.makeConstraints { make in
                make.height.equalTo(13)
            }
        }
        titleLable.snp.makeConstraints { (maker) in
            maker.height.equalTo(24)
        }
        titleStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview().inset(16)
            make.centerY.equalTo(backButton)
        }

        addPerfWarningIfNeeded()
    }

    @objc private func didClickBackButton() {
        switch self.viewModel.fromSource {
        case .preview:
            if Display.pad {
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        case .inMeet:
            if self.isCameraOn {
                let currentIsOn = viewModel.effectManger.isEffectOn()
                if self.isEffect != currentIsOn {
                    viewModel.setting.updateSettings {
                        $0.isInMeetCameraEffectOn = currentIsOn
                    }
                    viewModel.service.postMeetingChanges {
                        $0.isCameraEffectOn = currentIsOn
                    }
                }
            }
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        default:
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }

    private func addPerfWarningIfNeeded() {
        guard self.perfWarningView == nil, !viewModel.setting.featurePerformanceConfig.isEffectValid, !MeetingEffectManger.ignoreStaticPerfDegrade else {
            return
        }
        let location: String
        switch self.location {
        case .lobby, .preLobby:
            location = PerfDegradeTracks.locationWaitingRoom
        case .settings:
            location = PerfDegradeTracks.locationMeetingSetting
        case .preview:
            location = PerfDegradeTracks.locationPreview
        }
        self.perfWarningDisplayed = true
        perfWarningView = PerfDegradeWarningView(style: .staticDegrade, effectManger: viewModel.effectManger)
        PerfDegradeTracks.trackPerfWarningView(content: PerfDegradeTracks.contentStatic,
                                               location: location,
                                               isCamOn: !viewModel.camera.isMuted,
                                               isBackgroundOn: viewModel.effectManger.isVirtualBgEffective,
                                               isAvatarOn: viewModel.pretendService.isAnimojiOn(),
                                               isFilterOn: viewModel.pretendService.isFilterOn(),
                                               isTouchUpOn: viewModel.pretendService.isBeautyOn())
        perfWarningView?.actionButton.rx.tap
            .subscribe(onNext: { [weak self, weak perfWarningView] in
                perfWarningView?.isHidden = true
                MeetingEffectManger.ignoreStaticPerfDegrade = true
                self?.layoutForBackButton()
                PerfDegradeTracks.trackPerfWarningClick(click: PerfDegradeTracks.clickKnown,
                                                        content: PerfDegradeTracks.contentStatic,
                                                        location: location,
                                                        isCamOn: self?.viewModel.camera.isMuted == false,
                                                        isBackgroundOn: self?.viewModel.effectManger.isVirtualBgEffective ?? false,
                                                        isAvatarOn: self?.viewModel.pretendService.isAnimojiOn() ?? false,
                                                        isFilterOn: self?.viewModel.pretendService.isFilterOn() ?? false,
                                                        isTouchUpOn: self?.viewModel.pretendService.isBeautyOn() ?? false)
            })
            .disposed(by: disposeBag)
        layoutPerfWarningIfNeeded()
    }

    private func layoutPerfWarningIfNeeded() {
        if let perfWarningView = perfWarningView, self.perfWarningDisplayed, !perfWarningView.isHidden {
            perfWarningView.removeFromSuperview()
            if isLandscapeMode {
                self.view.addSubview(perfWarningView)
                perfWarningView.snp.remakeConstraints { make in
                    make.left.right.top.equalToSuperview()
                }
            } else if InMeetingLabVCLayout.isRegular() {
                self.labView.addSubview(perfWarningView)
                perfWarningView.snp.remakeConstraints { make in
                    make.top.left.right.equalTo(self.labView.videoView)
                }
            } else {
                self.view.addSubview(perfWarningView)
                perfWarningView.snp.remakeConstraints { make in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(backButton.snp.bottom).offset(10)
                }
            }
        }
    }

    private func isPerfWarningShow() -> Bool {
        if let perfWarningView = perfWarningView, self.perfWarningDisplayed, !perfWarningView.isHidden {
            return true
        }
        return false
    }

    private func layoutViewForOrientation() {
        titleStackView.isHidden = isLandscapeMode
        backButton.layer.cornerRadius = isLandscapeMode ? 20 : 0
        backButton.layer.masksToBounds = true
        let btnBgColor = isLandscapeMode ? UIColor.ud.vcTokenMeetingBgFloatTransparent : .clear
        backButton.vc.setBackgroundColor(btnBgColor, for: .normal)
    }

    private func layoutForBackButton() {
        if isLandscapeMode {
            backButton.snp.remakeConstraints { (maker) in
                if view.orientation == .landscapeRight && Display.iPhoneXSeries {
                    maker.left.equalTo(self.view.safeAreaLayoutGuide)
                } else {
                    maker.left.equalToSuperview().inset(16)
                }
                maker.size.equalTo(40)
                if let perfWarningView = self.perfWarningView, isPerfWarningShow() {
                    maker.top.equalTo(perfWarningView.snp.bottom).offset(20)
                } else {
                    maker.top.equalTo(self.view.safeAreaLayoutGuide).offset(16)
                }
            }
        } else {
            backButton.snp.remakeConstraints { (maker) in
                maker.size.equalTo(24)
                maker.left.equalToSuperview().inset(16)
                maker.top.equalTo(self.view.safeAreaLayoutGuide).offset(InMeetingLabVCLayout.backTopMargin(isRegular: InMeetingLabVCLayout.isRegular()))
            }
        }
    }

    private func getRegularSize() -> CGSize {
        var height: CGFloat = VCScene.isLandscape ? VCScene.bounds.width : VCScene.bounds.height
        let calHeight = height - 44 * 2
        height = calHeight > InMeetingLabVCLayout.regularMaxHeight ? InMeetingLabVCLayout.regularMaxHeight : calHeight
        return CGSize(width: InMeetingLabVCLayout.regularWidth, height: height)
    }

    private func layoutForTraitCollection(isRegular: Bool) {
        if isRegular {
            self.updateDynamicModalSize(getRegularSize())
        }
        view.backgroundColor = isRegular ? UIColor.ud.N00 & UIColor.ud.bgBase : UIColor.ud.N100
        setupTitle()

        var icon: UDIconType?
        if viewModel.fromSource == .preview {
            icon = Display.pad ? .closeSmallOutlined : .leftOutlined
        } else {
            icon = .closeSmallOutlined
        }
        if let icon = icon {
            backButton.setImage(UDIcon.getIconByKey(icon, iconColor: (isRegular || Display.phone ? UIColor.ud.iconN1 : UIColor.ud.primaryOnPrimaryFill), size: CGSize(width: 24, height: 24)), for: .normal)
            backButton.setImage(UDIcon.getIconByKey(icon, iconColor: (isRegular || Display.phone ? UIColor.ud.iconN1 : UIColor.ud.primaryOnPrimaryFill), size: CGSize(width: 24, height: 24)), for: .highlighted)
        }
        backButton.ud.setLayerShadowColor(isRegular || Display.phone ? .clear : UIColor.ud.staticBlack.withAlphaComponent(0.5))

        layoutViewForOrientation()
        layoutPerfWarningIfNeeded()
        layoutForBackButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if Privacy.videoAuthorized {
            viewModel.camera.setMuted(false)
            labView.setCameraMuted(viewModel.camera.isMuted)
        } else {
            labView.setCameraMuted(true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.virtualBgService.labVC = self
        labView.handleExtraToast()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.camera.setMuted(true)
        labView.setCameraMuted(viewModel.camera.isMuted)
    }

    override func viewDidLayoutSubviews() {
        labView.viewDidLayoutSubviews(width: VCScene.bounds.width)
    }

    private func setupNavigationBar() {
        isNavigationBarHidden = true
    }

    func showImagePicker() {
        viewModel.showImagePicker()
    }

    private func setupTitle() {
        let shadow = NSShadow()
        if Display.pad {
            shadow.shadowColor = UIColor.ud.staticBlack.withAlphaComponent(0.5)
            shadow.shadowOffset = CGSize(width: 0, height: 0.5)
            shadow.shadowBlurRadius = 2
        }
        if Display.phone || InMeetingLabVCLayout.isRegular() {
            titleLable.attributedText = NSAttributedString(string: I18n.View_G_Effects, attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .medium), .foregroundColor: UIColor.ud.textTitle])
            tipsView.tipsLabel.attributedText = NSAttributedString(string: I18n.View_VM_SettingsWillTakeEffectImmediately, attributes: [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.ud.textCaption])
        } else {
            titleLable.attributedText = NSAttributedString(string: I18n.View_G_Effects, attributes: [.shadow: shadow, .font: UIFont.systemFont(ofSize: 17, weight: .medium), .foregroundColor: UIColor.ud.primaryOnPrimaryFill])
            tipsView.tipsLabel.attributedText = NSAttributedString(string: I18n.View_VM_SettingsWillTakeEffectImmediately, attributes: [.shadow: shadow, .font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)])
        }
    }

    @objc func willBecomeActive() {
        self.updateDynamicModalSize(getRegularSize())
    }

    deinit {
        Logger.lab.info("lab: InMeetingLabViewController deinit")

        NotificationCenter.default.removeObserver(self)
        viewModel.changeVirtualToDelete(isDelete: false) // 这2行是重置删除状态
        viewModel.isDeleting = false
        if perfWarningDisplayed {
            let location: String
            switch self.location {
            case .lobby, .preLobby:
                location = PerfDegradeTracks.locationWaitingRoom
            case .settings:
                location = PerfDegradeTracks.locationMeetingSetting
            case .preview:
                location = PerfDegradeTracks.locationPreview
            }
            PerfDegradeTracks.trackMeetSettingClickClose(location: location,
                                                         isCamOn: isCameraOn,
                                                         isBackgroundOn: viewModel.effectManger.isVirtualBgEffective,
                                                         isAvatarOn: viewModel.pretendService.isAnimojiOn(),
                                                         isFilterOn: viewModel.pretendService.isFilterOn(),
                                                         isTouchUpOn: viewModel.pretendService.isBeautyOn())
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.checkAndSetOrientation()
        let isRegular = VCScene.isRegular
        self.layoutForTraitCollection(isRegular: isRegular)
        self.labView.layoutTotalViews(isRegular: isRegular)
        if Display.pad {
            self.perfWarningView?.remakeLayout(isRegular: isRegular)
        } else {
            self.perfWarningView?.updatePhoneLayout()
        }
    }

    private func checkAndSetOrientation() {
        layoutViewForOrientation()
        layoutPerfWarningIfNeeded()
        layoutForBackButton()
    }
}

extension InMeetingLabViewController: PreviewCameraDelegate {
    func cameraWasInterrupted(_ camera: PreviewCameraManager) {
        labView.setCameraMuted(true)
    }

    func cameraInterruptionEnded(_ camera: PreviewCameraManager) {
        labView.setCameraMuted(false)
    }

    func didFailedToStartVideoCapture(error: Error) {
        labView.setCameraMuted(true)
    }
}
