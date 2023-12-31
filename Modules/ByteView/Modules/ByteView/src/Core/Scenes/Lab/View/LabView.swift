//
//  LabOperationView.swift
//  ByteView
//
//  Created by liquanmin on 2020/9/16.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewCommon
import UIKit
import UniverseDesignShadow
import ByteViewUI
import ByteViewSetting
import ByteViewRtcBridge

class LabView: UIView {
    struct Layout {
        static let avatarSize: CGFloat = 160
        static let sliderHeight: CGFloat = 76
        static let scrollMaskWidth: CGFloat = 64
        static let videoViewTopOffset: CGFloat = 62
        static let videoViewBottomOffset: CGFloat = 0
        static func isRegular() -> Bool { VCScene.rootTraitCollection?.isRegular ?? false }
    }

    /// iPad regular 模式下的 videoView 高度
    static let regularHeight4VideoView = 320

    private let disposeBag = DisposeBag()
    private let viewModel: InMeetingLabViewModel
    private var isFristLayout: Bool = true
    var titleStackHeight: CGFloat {
        Layout.isRegular() ? 56 : 40
    }

    var videoViewLeftRightOffset: CGFloat {
        return Layout.isRegular() ? 28 : 0
    }

    /// iPad regular 模式下的 videoView 距离左边和顶部的偏移值
    var regularOffset4VideoView: CGPoint {
        CGPoint(x: videoViewLeftRightOffset, y: Layout.videoViewTopOffset)
    }

    // 视频流渲染
    lazy var videoView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.backgroundColor = UIColor.ud.vcTokenMeetingBgCamOff
        view.clipsToBounds = true

        view.addSubview(streamRenderView)
        streamRenderView.frame = view.bounds

        streamRenderView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        //streamRenderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }()

    lazy var streamRenderView: StreamRenderView = {
        let streamRenderView = StreamRenderView()
        streamRenderView.renderMode = videoRenderMode
        streamRenderView.setStreamKey(.local)
        streamRenderView.isLocalRenderMirrorEnabled = false
        return streamRenderView
    }()

    private lazy var scrollMaskView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.isHidden = true

        let layer = CAGradientLayer()
        layer.ud.setColors([UIColor.ud.cgClear, UIColor.ud.N00], bindTo: view)
        layer.locations = [0, 1]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 0)
        layer.frame = CGRect(x: 0, y: 0, width: Layout.scrollMaskWidth, height: titleStackHeight)
        view.layer.insertSublayer(layer, at: 0)
        view.layer.addSublayer(layer)
        return view
    }()

    let videoRenderMode: ByteViewRenderMode

    // 摄像头不可用时的placeHolder
    lazy var placeHolderView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.vcTokenMeetingBgCamOff
        view.clipsToBounds = true
        view.isHidden = Privacy.cameraAccess.value.isAuthorized
        let img = UDIcon.getIconByKey(.videoOffOutlined, iconColor: UIColor.ud.iconDisabled, size: CGSize(width: 150, height: 150))
        let imageView = UIImageView(image: img)
        view.addSubview(imageView)
        imageView.snp.makeConstraints { (maker) in
            maker.size.equalTo(150)
            maker.center.equalToSuperview()
        }
        return view
    }()

    lazy var bottomBgGradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.ud.setColors([UIColor.ud.bgBody.withAlphaComponent(0.7), UIColor.ud.bgBody, UIColor.ud.bgBody], bindTo: self)
        let width = LabVirtualBgView.Layout.viewWidth(isLandscapeMode: true)
        let offset: CGFloat = min(VCScene.bounds.height, VCScene.bounds.width) * 16 / 9 + width - max(VCScene.bounds.height, VCScene.bounds.width)
        let offsetRatio = offset / width
        layer.frame = CGRect(x: 0, y: 0, width: width, height: min(VCScene.bounds.height, VCScene.bounds.width))
        layer.locations = [0, NSNumber(value: offsetRatio), 1.0]
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        return layer
    }()

    lazy var bottomBgView: UIView = {
        let container = UIView()
        container.backgroundColor = Layout.isRegular() ? UIColor.ud.N00 & UIColor.ud.bgBase : UIColor.clear
        container.clipsToBounds = true
        return container
    }()

    private var pageButtons: [(UIView, UIButton)]?
    private lazy var titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = Layout.isRegular() ? 22 : 18
        stackView.axis = .horizontal
        return stackView
    }()

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = Layout.isRegular() ? UIColor.ud.N00 & UIColor.ud.bgBase : UIColor.clear
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        return scrollView
    }()

    private lazy var deleteDoneBtn: UIButton = {
        let button = UIButton()
        button.setTitle(I18n.View_G_Done, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: Layout.isRegular() ? 17 : 14)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.addTarget(self, action: #selector(deleteDoneAction), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private lazy var landscapeArrowBtn: UIButton = {
        let button = EnlargeTouchButton(padding: 10)
        let img = UDIcon.getIconByKey(.vcToolbarRightFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24.0, height: 24.0))
        button.setImage(img, for: .normal)
        button.addTarget(self, action: #selector(landscapeArrowAction), for: .touchUpInside)
        button.isHidden = true
        button.layer.ud.setShadowColor(UIColor.ud.staticBlack.withAlphaComponent(0.5))
        button.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        button.layer.shadowRadius = 2
        button.layer.shadowOpacity = 1
        return button
    }()

    // 分割线
    private lazy var seperatorLine: UIView = {
        let line = UIView(frame: .zero)
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    // 页面指示方块
    private lazy var indicatorView: UIView = {
        let indicator = UIView(frame: .zero)
        indicator.backgroundColor = UIColor.ud.primaryContentDefault
        return indicator
    }()
    // 底部页面的容器
    private lazy var effectContainerView: UIView = {
        let container = UIView(frame: .zero)
        return container
    }()

    // 虚拟背景页面
    private lazy var virtualBgView: LabVirtualBgView = {
        let virtualBgView = LabVirtualBgView(frame: .zero, vm: viewModel)
        virtualBgView.deleteBlock = deleteBlock
        virtualBgView.longPressBlock = longPressBlock
        return virtualBgView
    }()

    // animoji页面
    private lazy var animojiBgView: LabEffectBgView = {
        let animojiBgView = LabEffectBgView(frame: .zero, vm: viewModel, labType: .animoji)
        return animojiBgView
    }()

    // filter页面
    private lazy var filterBgView: LabEffectBgView = {
        let filterBgView = LabEffectBgView(frame: .zero, vm: viewModel, labType: .filter)
        filterBgView.delegate = self
        return filterBgView
    }()

    // retuschieren页面
    private lazy var retuschierenBgView: LabEffectBgView = {
        let retuschierenBgView = LabEffectBgView(frame: .zero, vm: viewModel, labType: .retuschieren)
        retuschierenBgView.delegate = self
        return retuschierenBgView
    }()

    // effectSlider view
    private lazy var effectSliderView: LabEffectSliderView = {
        let effectSliderView = LabEffectSliderView(frame: .zero, vm: viewModel)
        return effectSliderView
    }()

    // tip提示，视图层级区别太大，所以加一个新的专门横屏用
    private lazy var tipsView: LabTipsView = {
        let tipsView = LabTipsView(frame: .zero, tipsText: I18n.View_VM_SettingsWillTakeEffectImmediately)
        tipsView.isHidden = true
        return tipsView
    }()

    // 视频镜像
    private lazy var mirrorSegControl: LabSegmentControl = {
        let view = LabSegmentControl(frame: .zero)
        view.setOptions([.backgroundColor(UIColor.ud.vcTokenMeetingBgFloatTransparent),
                         .cornerRadius(6.0),
                         .animationSpringDamping(1.0),
                         .indicatorViewBackgroundColor(UIColor.ud.udtokenBtnTextBgPriFocus),
                         .indicatorViewCornerRadius(4.0),
                         .segmentPadding(0.0),
                         .segmentSpacing(2.0)])
        let mirrorSegmentFirst = LabMirrorSegment(text: I18n.View_G_OtherSeeMe_Tab)
        let mirrorSegmentSecond = LabMirrorSegment(text: I18n.View_G_SeeMe_Tab)
        if mirrorSegmentFirst.intrinsicContentSize != mirrorSegmentSecond.intrinsicContentSize {
            LabMirrorSegment.updateSizeOf(segments: [mirrorSegmentFirst, mirrorSegmentSecond])
        }
        view.segments = [mirrorSegmentFirst, mirrorSegmentSecond]
        view.isHidden = mirrorSwitchView.isHidden || !mirrorSwitchView.isOn
        view.rx.selectedSegmentIndex.changed.subscribe(onNext: { [weak self] index in
            self?.streamRenderView.isLocalRenderMirrorEnabled = index == 1
        }).disposed(by: disposeBag)
        return view
    }()

    private lazy var mirrorSwitchView: LabSwitchView = {
        let model = LabSwitchViewModel(title: I18n.View_G_VideoMirroring, isDefaultOn: viewModel.setting.isVideoMirrored,
                                       isSwitchEnabled: true) { [weak self] isOn in
            LabTrack.trackTapVideoMirrorSetting(on: isOn)
            self?.viewModel.setting.updateSettings({ $0.isVideoMirrored = isOn }, completion: { (_) in
                DispatchQueue.main.async {
                    self?.resetMirrorSegControl()
                    self?.mirrorSegControl.isHidden = !isOn
                }
            })
        }
        let view = LabSwitchView(frame: .zero, model: model)
        view.isHidden = !viewModel.camera.isFrontCamera
        return view
    }()


    private lazy var extraTipView: LabExtraTipView = {
        let view = LabExtraTipView(frame: self.frame)
        view.isHidden = true
        return view
    }()

    var deleteBlock: ((VirtualBgModel) -> Void)?
    var longPressBlock: (() -> Void)?
    var isBottomViewHidden: Bool = false { // 横屏模式下才有
        didSet {
            let img = UDIcon.getIconByKey(isBottomViewHidden ? .vcToolbarLeftFilled : .vcToolbarRightFilled, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 24.0, height: 24.0))
            landscapeArrowBtn.setImage(img, for: .normal)
        }
    }
    var isLandscapeMode: Bool { return viewModel.fromSource == .inMeet && isPhoneLandscape } // preview进入特效不横屏

    init(frame: CGRect, vm: InMeetingLabViewModel, renderMode: ByteViewRenderMode = .renderModeHidden) {
        self.viewModel = vm
        self.videoRenderMode = renderMode
        super.init(frame: frame)

        deleteBlock = {[weak self] (model: VirtualBgModel) in
            ThemeAlertTrackerV2.trackDisplayPopupAlert(content: .deleteVirtualBackground)
            ByteViewDialog.Builder()
                .colorTheme(.redLight)
                .title(I18n.View_G_DeleteBackgroundQuestion)
                .message(I18n.View_VM_OnceDeleteNoRecover)
                .leftTitle(I18n.View_G_CancelButton)
                .rightTitle(I18n.View_G_Delete)
                .rightHandler({ [weak self] _ in
                    self?.viewModel.deleteVirtualBg(model: model)
                    self?.virtualBgView.reloadCollection()
                    LabTrack.trackTapDeleteVirtual(source: vm.fromSource, model: model)
                })
                .show()
        }
        longPressBlock = { [weak self] in
            if (self?.viewModel.isDeleting) ?? true {
                return
            }
            self?.viewModel.isDeleting = true
            self?.viewModel.changeVirtualToDelete(isDelete: true)
            self?.virtualBgView.reloadCollection()
            self?.stepViewsForDelete()
        }

        setupViews()
        layoutTotalViews(isRegular: Layout.isRegular())
        viewModel.currentPageType.distinctUntilChanged().subscribe(onNext: { [weak self] pageType in
            guard let pageType = pageType else { return }
            self?.switchPage(type: pageType, isFromBtn: false)
            }).disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        Logger.lab.info("lab: LabView deinit")
    }

    // 解决mirrorSegControl在effectSliderView下面无法被点击
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let viewPoint = mirrorSegControl.convert(point, from: self)
        if mirrorSegControl.point(inside: viewPoint, with: event) {
            return mirrorSegControl
        }
        return super.hitTest(point, with: event)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if self.isFristLayout {
            isFristLayout = false
            layoutTotalViews(isRegular: Layout.isRegular())
        }
    }

    func handleExtraToast() {
        guard let model = viewModel.virtualBgService.calendarMeetingVirtual, !model.hasShowedExtraBgTipInLabVC else {
            return
        }
        switch viewModel.virtualBgService.extrabgDownloadStatus {
        case .done:
            if model.hasExtraBg {
                self.showExtraTips()
            }
        case .checking, .download:
            viewModel.virtualBgService.addCalendarListener(self)
        default:
            break
        }
    }

    func showExtraTips() {
        if viewModel.virtualBgService.calendarMeetingVirtual != nil, viewModel.virtualBgService.calendarMeetingVirtual?.hasExtraBg == true, viewModel.virtualBgService.extrabgDownloadStatus == .done, let cellframe = virtualBgView.getExtraBgFrame() {
            let frame = virtualBgView.bgCollectionView.convert(cellframe, to: self)
            extraTipView.isHidden = false
            addSubview(extraTipView)
            extraTipView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            extraTipView.setMarkingFrame(frame: frame)
            viewModel.virtualBgService.calendarMeetingVirtual?.hasShowedExtraBgTipInLabVC = true
        }
    }

    func setupViews() {
        backgroundColor = Layout.isRegular() || Display.phone ? UIColor.ud.bgBody : UIColor.ud.N100

        self.addSubview(videoView)
        self.addSubview(mirrorSegControl)
        self.addSubview(placeHolderView)
        self.addSubview(bottomBgView)
        self.addSubview(landscapeArrowBtn)
        self.addSubview(seperatorLine) // 分割线 本来在bottom里面的，但是横屏和刘海边对齐

        // ========= 底部操作栏部分 =========
        self.bottomBgView.addSubview(effectContainerView) // 中间主显示内容部分
        self.bottomBgView.addSubview(scrollMaskView) // 白色遮罩
        self.bottomBgView.addSubview(scrollView)
        self.bottomBgView.addSubview(indicatorView) // 翻页指示器
        self.bottomBgView.addSubview(tipsView) // 只有横屏有
        self.scrollView.addSubview(titleStackView)   //特效segment标题加在scrollView上
        self.addSubview(mirrorSwitchView)

        // title 部分
        pageButtons = viewModel.pages.map({ (pageDesc) -> (UIView, UIButton) in
            let containerView = UIView()
            let button = UIButton()
            button.setTitle(pageDesc.title, for: .normal)
            button.setTitleColor(UIColor.ud.textCaption, for: .normal)
            button.setTitleColor(UIColor.ud.primaryContentDefault, for: .highlighted)
            button.clipsToBounds = true
            button.titleLabel?.font = UIFont.systemFont(ofSize: Layout.isRegular() ? 17 : 14, weight: .regular)
            button.rx.tap
                .subscribe(onNext: { [weak self] in
                    self?.switchPage(type: pageDesc.pageType, isFromBtn: true)
                }).disposed(by: disposeBag)

            pageDesc.selectedRelay.subscribe(onNext: { [weak self] selected in
                guard let self = self else { return }
                button.setTitleColor(selected ? UIColor.ud.primaryContentDefault : UIColor.ud.textCaption, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: Layout.isRegular() ? 17 : 14, weight: selected ? .medium : .regular)
            }).disposed(by: disposeBag)

            containerView.addSubview(button)
            button.snp.makeConstraints { maker in
                maker.edges.equalTo(containerView)
            }
            titleStackView.addArrangedSubview(containerView)
            return (containerView, button)
        })

        self.addSubview(deleteDoneBtn)

        // 加载占位视图
        placeHolderView.snp.remakeConstraints { maker in
            maker.edges.equalTo(self.videoView)
        }
    }

    func layoutBottomViews() {
        let insets: CGFloat = isLandscapeMode ? 16 : (Layout.isRegular() ? 28 : 24)
        scrollView.contentInset = UIEdgeInsets(top: 0, left: insets, bottom: 0, right: insets)

        if isLandscapeMode {
            bottomBgView.snp.remakeConstraints { maker in
                maker.top.bottom.equalToSuperview()
                maker.width.equalTo(LabVirtualBgView.Layout.viewWidth(isLandscapeMode: true))
                if orientation == .landscapeRight {
                    maker.right.equalToSuperview()
                } else if Display.iPhoneXSeries {
                    maker.right.equalTo(self.safeAreaLayoutGuide).offset(LabVirtualBgView.Layout.landscapeModeCellSpacing)
                } else {
                    maker.right.equalTo(self.safeAreaLayoutGuide)
                }
            }
        } else {
            bottomBgView.snp.remakeConstraints { maker in
                maker.left.right.bottom.equalToSuperview()
                if Layout.isRegular() {
                    maker.top.equalTo(videoView.snp.bottom)
                } else {
                    if Display.phone {
                        maker.top.equalTo(videoView.snp.bottom).offset(8)
                    } else {
                        maker.height.equalTo(VCScene.bounds.height * 0.35)
                    }
                }
            }
        }

        scrollView.snp.remakeConstraints { maker in
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
            maker.top.equalTo(bottomBgView).offset(isLandscapeMode ? 4 : 0)
            maker.height.equalTo(titleStackHeight)
        }

        deleteDoneBtn.snp.remakeConstraints { make in
            make.centerY.equalTo(titleStackView)
            make.right.equalToSuperview().inset(Layout.isRegular() ? 27 : 23)
            make.height.equalTo(24)
        }

        layoutEffectContainerView()

        tipsView.snp.remakeConstraints { make in
            make.left.right.equalTo(effectContainerView)
            make.bottom.equalToSuperview().offset(Display.iPhoneXSeries ? -17 : -8)
            make.height.equalTo(tipsView.isHidden ? 0 : 13)
        }

        titleStackView.snp.remakeConstraints { make in
            make.right.left.centerY.equalTo(self.scrollView)
            make.height.equalTo(24)
        }

        scrollMaskView.snp.remakeConstraints { maker in
            maker.right.equalToSuperview()
            maker.top.equalTo(self.scrollView)
            maker.bottom.equalTo(self.indicatorView)
            maker.width.equalTo(Layout.scrollMaskWidth)
        }

        seperatorLine.snp.remakeConstraints { (maker) in
            maker.left.equalTo(bottomBgView)
            if isLandscapeMode && Display.iPhoneXSeries && orientation == .landscapeLeft {
                maker.right.equalTo(self.snp.right)
            } else {
                maker.right.equalTo(bottomBgView)
            }
            maker.height.equalTo(0.5)
            maker.bottom.equalTo(self.scrollView)
        }
    }

    func layoutEffectContainerView() {
        let model = viewModel.pretendService.currentFilterModel
        var needUpView = false
        if viewModel.currentPageType.value == .filter, let model = model, model.bgType != .none {
            needUpView = true  // 此时effectSliderView在下方
        }

        effectContainerView.snp.remakeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(scrollView.snp.bottom).offset(isLandscapeMode ? 0 : 0)
            if isLandscapeMode {
                if tipsView.isHidden {  // preview的时候没有tipsview
                    maker.bottom.equalTo(self)
                } else if needUpView {
                    maker.bottom.equalTo(effectSliderView.snp.top).offset(36)
                } else {
                    maker.bottom.equalTo(tipsView.snp.top).offset(-8)
                }
            } else if mirrorSwitchView.isHidden {
                maker.bottom.equalTo(self)
            } else {
                maker.bottom.equalTo(self.mirrorSwitchView.snp.top)
            }
        }
    }

    func layoutForLandscapeMode() {
        guard isLandscapeMode && (orientation == .landscapeLeft || orientation == .landscapeRight) else { return }

        isBottomViewHidden = false
        effectSliderView.removeFromSuperview()
        bottomBgView.addSubview(effectSliderView)
        placeHolderView.layer.cornerRadius = 0
        videoView.layer.cornerRadius = 0
        tipsView.isHidden = !viewModel.isFromInMeet
        mirrorSwitchView.updateTitleColor(isLandscapeMode: isLandscapeMode)
        bottomBgView.layer.insertSublayer(bottomBgGradientLayer, at: 0)
        landscapeArrowBtn.isHidden = false

        landscapeArrowBtn.snp.remakeConstraints { make in
            make.right.equalTo(bottomBgView.snp.left).offset(-4)
            make.size.equalTo(24)
            make.centerY.equalToSuperview()
        }

        let videoWidth = ceil(min(VCScene.bounds.height, VCScene.bounds.width) * 16 / 9)
        videoView.snp.remakeConstraints { make in
            make.left.equalTo(self)
            make.top.bottom.equalTo(self)
            make.width.equalTo( videoWidth > max(VCScene.bounds.height, VCScene.bounds.width) ? max(VCScene.bounds.height, VCScene.bounds.width) : videoWidth )  // 一般不存在>
        }

        effectSliderView.snp.remakeConstraints { make in
            make.left.right.equalTo(bottomBgView).inset(24)
            make.bottom.equalTo(tipsView.snp.top).offset(-2)
        }

        mirrorSegControl.snp.remakeConstraints { make in
            if Display.iPhoneXSeries {
                if orientation == .landscapeRight {
                    make.left.bottom.equalTo(self.safeAreaLayoutGuide)
                } else {
                    make.left.equalToSuperview().offset(16)
                    make.bottom.equalTo(self.safeAreaLayoutGuide)
                }
            } else {
                make.left.bottom.equalToSuperview().inset(16)
            }
            make.height.equalTo(36)
        }

        mirrorSwitchView.snp.remakeConstraints { make in
            make.left.equalTo(mirrorSegControl.snp.right).offset(12)
            make.height.equalTo(28)
            make.centerY.equalTo(mirrorSegControl)
            make.right.equalTo(bottomBgView.snp.left).offset(-2)
        }
        mirrorSwitchView.layoutForLandscape(isLandscape: true)
    }

    func setCameraMuted(_ isMuted: Bool) {
        Util.runInMainThread { [weak self] in
            self?.videoView.isHidden = isMuted
            self?.placeHolderView.isHidden = !isMuted
        }
    }

    func layoutTotalViews(isRegular: Bool) {
        if isLandscapeMode {
            self.layoutForLandscapeMode()
        } else {
            self.layouForNormal(isRegular: isRegular)
        }
        layoutBottomViews()
        updateMirrorSegControlLayout()

        // 刷新各个子collectionview
        virtualBgView.layoutForTraitCollection()
        animojiBgView.layoutForTraitCollection()
        filterBgView.layoutForTraitCollection()
        retuschierenBgView.layoutForTraitCollection()
        effectSliderView.layoutForTraitCollection()
    }

    func layouForNormal(isRegular: Bool) {
        let isRegularOrPhone = isRegular || Display.phone
        backgroundColor = isRegularOrPhone ? UIColor.ud.bgBody : UIColor.ud.N100
        effectSliderView.removeFromSuperview()
        addSubview(effectSliderView)
        placeHolderView.layer.cornerRadius = isRegularOrPhone ? 8 : 0
        videoView.layer.cornerRadius = isRegularOrPhone ? 8 : 0
        mirrorSwitchView.updateTitleColor(isLandscapeMode: false)
        bottomBgGradientLayer.removeFromSuperlayer()
        tipsView.isHidden = true
        landscapeArrowBtn.isHidden = true

        titleStackView.spacing = isRegular ? 22 : 18
        let insets: CGFloat = isRegular ? 28 : 24
        scrollView.contentInset = UIEdgeInsets(top: 0, left: insets, bottom: 0, right: insets)
        scrollView.backgroundColor = isRegular ? UIColor.ud.N00 & UIColor.ud.bgBase : UIColor.clear

        bottomBgView.backgroundColor = isRegular ? UIColor.ud.N00 & UIColor.ud.bgBase : UIColor.clear
        deleteDoneBtn.titleLabel?.font = UIFont.systemFont(ofSize: isRegular ? 17 : 14)

        effectSliderView.snp.remakeConstraints { make in
            make.left.right.equalTo(videoView).inset(12)
            if Display.phone {
                make.bottom.equalTo(videoView).offset(-2)
            } else {
                make.bottom.equalTo(bottomBgView.snp.top).offset(isRegular ? -10 : -2)
            }
        }

        mirrorSegControl.snp.remakeConstraints { make in
            make.centerX.equalTo(self)
            make.height.equalTo(36)
            make.bottom.equalTo(videoView).offset(-6)
        }

        mirrorSwitchView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(isRegular ? 52 : 48)
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(Display.iPhoneXSeries ? 10 : 0)
        }
        mirrorSwitchView.layoutForLandscape(isLandscape: false)

        videoView.snp.remakeConstraints { make in
            if Display.phone {
                let sceneWidth = min(VCScene.bounds.width, VCScene.bounds.height) // 修复问题：iOS-16上iPhone横屏弹起特效页面时，在旋转过程中取值不准确
                make.left.right.equalToSuperview().inset(16)
                make.height.equalTo(sceneWidth - 32)
                make.top.equalTo(self.safeAreaLayoutGuide).offset(52)
            } else {
                make.left.right.equalToSuperview().inset(videoViewLeftRightOffset)
                if isRegular {
                    make.top.equalTo(self.safeAreaLayoutGuide).offset(Layout.videoViewTopOffset)
                    make.height.equalTo(LabView.regularHeight4VideoView)
                    make.bottom.equalTo(self.bottomBgView.snp.top).offset(-Layout.videoViewBottomOffset)
                } else {
                    make.top.equalToSuperview()
                    make.bottom.equalTo(self.bottomBgView.snp.top)
                }
            }
        }
    }

    func viewDidLayoutSubviews(width: CGFloat) {
        self.virtualBgView.viewDidLayoutSubviews(width: width)
        self.animojiBgView.viewDidLayoutSubviews(width: width)
        self.filterBgView.viewDidLayoutSubviews(width: width)
        self.retuschierenBgView.viewDidLayoutSubviews(width: width)

        scrollView.contentSize = CGSize(width: titleStackView.frame.width, height: titleStackView.frame.height)
        if scrollView.contentSize.width < scrollView.frame.size.width {
            scrollMaskView.isHidden = true
        }
    }

    /// 切换页面
    private func switchPage(type: EffectType, isFromBtn: Bool) {
        if viewModel.pages.isEmpty {
            return
        }
        viewModel.pages.forEach({ pageDesc in
            pageDesc.selectedRelay.accept(pageDesc.pageType == type)
        })
        updateIndicatorLoc()

        viewModel.currentPageType.accept(type)

        // 先清空
        for view in effectContainerView.subviews {
            view.removeFromSuperview()
        }

        // 添加对应的 View
        var effectView: UIView?
        switch type {
        case .virtualbg:
            effectView = virtualBgView
            effectSliderView.isHidden = true
            if !isFromBtn {
                MeetingTracks.trackLabSelectedTap(param: (viewModel.fromSource, .virtualbg))
                LabTrackV2.trackSelectLabTab(param: (viewModel.fromSource, .virtualbg))
            }
        case .animoji:
            effectView = animojiBgView
            effectSliderView.isHidden = true
            if !isFromBtn {
                MeetingTracks.trackLabSelectedTap(param: (viewModel.fromSource, .animoji))
                LabTrackV2.trackSelectLabTab(param: (viewModel.fromSource, .animoji))
            }
        case .filter:
            effectView = filterBgView
            if let currentModel = viewModel.pretendService.currentFilterModel,
               currentModel.bgType == .set {
                effectSliderView.isHidden = false
                effectSliderView.reloadDate(effectModel: currentModel)
            } else {
                effectSliderView.isHidden = true
            }
            if !isFromBtn {
                MeetingTracks.trackLabSelectedTap(param: (viewModel.fromSource, .filter))
                LabTrackV2.trackSelectLabTab(param: (viewModel.fromSource, .filter))
            }
        case .retuschieren:
            effectView = retuschierenBgView
            if let currentModel = viewModel.pretendService.currentBeautySettingModel,
               currentModel.bgType == .set,
               !viewModel.isBeautySetting {
                effectSliderView.isHidden = false
                effectSliderView.reloadDate(effectModel: currentModel)
            } else {
                effectSliderView.isHidden = true
            }
            if !isFromBtn {
                MeetingTracks.trackLabSelectedTap(param: (viewModel.fromSource, .retuschieren))
                LabTrackV2.trackSelectLabTab(param: (viewModel.fromSource, .retuschieren))
            }
        }

        if let displayedView = effectView {
            self.effectContainerView.addSubview(displayedView)
            displayedView.snp.remakeConstraints { maker in
                maker.left.top.right.bottom.equalToSuperview()
            }
        }

        layoutEffectContainerView()
        updateMirrorSegControlLayout()
    }

    private func updateIndicatorLoc() {
        var pageIndex = viewModel.pages.first(where: { (page) -> Bool in
            page.selectedRelay.value
        }).map({ pageDesc -> Int in
            pageDesc.index
        })
        if pageIndex == nil {
            pageIndex = 0
        }
        indicatorView.snp.remakeConstraints { (maker) in
            maker.height.equalTo(2)
            maker.width.centerX.equalTo(pageButtons![pageIndex!].1)
            maker.bottom.equalTo(self.seperatorLine.snp.bottom)
        }
        indicatorView.layer.ux.setSmoothCorner(radius: 2, corners: [.topLeft, .topRight], smoothness: .none)
    }

    private var currentOrientation = UIInterfaceOrientation.unknown

    private func resetMirrorSegControl() {
        self.mirrorSegControl.setIndex(0)
        self.streamRenderView.isLocalRenderMirrorEnabled = false
    }

    private func updateMirrorSegControlLayout() {
        guard !isLandscapeMode else { return } // 不是横屏模式才更新镜像seg
        mirrorSegControl.snp.updateConstraints { make in
            make.bottom.equalTo(videoView).offset(self.effectSliderView.isHidden ? -6 : Layout.isRegular() ? -66 : -50)
        }
    }
}

extension LabView: EffectVirtualBgCalendarListener {
    func didChangeExtrabgDownloadStatus(status: ExtraBgDownLoadStatus) {
        Util.runInMainThread { [weak self] in
            guard let self = self, status == .done, self.viewModel.virtualBgService.calendarMeetingVirtual?.hasExtraBg == true else { return
            }
            self.showExtraTips()
        }
    }

    func didChangeVirtualBgAllow(allowInfo: AllowVirtualBgRelayInfo) {
        Util.runInMainThread { [weak self] in
            self?.virtualBgView.changeForAllowedStatus(allowInfo: allowInfo)
        }
    }
}

/// delete
extension LabView {
    private func stepViewsForDelete() {
        deleteDoneBtn.isHidden = false
        hidePageButtonsForDelete(isHide: true)
    }

    private func hidePageButtonsForDelete(isHide: Bool) {
        for (index, item) in viewModel.pages.enumerated() {
            if let view = self.pageButtons?[index].0, let btn = self.pageButtons?[index].1 {
                view.isHidden = isHide ? !(item.pageType == .virtualbg) : false
                if item.pageType == .virtualbg {
                    btn.setTitleColor(isHide ? UIColor.ud.textCaption : UIColor.ud.primaryContentDefault, for: .normal)
                    indicatorView.backgroundColor = isHide ? UIColor.clear : UIColor.ud.primaryContentDefault
                    btn.titleLabel?.font = UIFont.systemFont(ofSize: Layout.isRegular() ? 17 : 14, weight: isHide ? .regular : .medium)
                }
            }
        }
    }

    @objc private func deleteDoneAction() {
        hidePageButtonsForDelete(isHide: false)  // 恢复其他effect segment
        deleteDoneBtn.isHidden = true   // 隐藏确定按钮
        viewModel.changeVirtualToDelete(isDelete: false)
        virtualBgView.reloadCollection()

        viewModel.isDeleting = false
    }

    @objc private func landscapeArrowAction() {
        isBottomViewHidden = !isBottomViewHidden
        bottomBgView.snp.remakeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.width.equalTo(LabVirtualBgView.Layout.viewWidth(isLandscapeMode: true))
            if isBottomViewHidden {
                maker.left.equalTo(videoView.snp.right)
            } else {
                if orientation == .landscapeRight {
                    maker.right.equalToSuperview()
                } else {
                    maker.right.equalTo(self.safeAreaLayoutGuide)
                }
            }
        }
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
}

extension LabView: LabEfffectBgViewDelegate {
    func hiddenEffectSlider() {
        effectSliderView.isHidden = true
        updateMirrorSegControlLayout()
    }

    func didTapEffect(effectModel: ByteViewEffectModel) {
        if effectModel.bgType == .set {  // 刷新滑动栏
            if viewModel.currentPageType.value == effectModel.labType {
                effectSliderView.isHidden = false
                effectSliderView.reloadDate(effectModel: effectModel)
            }
        } else {
            effectSliderView.isHidden = true
        }

        if effectModel.labType == .filter {
            layoutEffectContainerView()
        }
        updateMirrorSegControlLayout()
    }
}

extension LabView: UIScrollViewDelegate {
//    以下代码可能不需要了
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        let bounds = scrollView.bounds
        let size = scrollView.contentSize
        let inset = scrollView.contentInset

        let currentOffset = offset.x + bounds.size.width - inset.left
        let maximumOffset = size.width

        if (maximumOffset > 0) && (maximumOffset - currentOffset) < 5 {
            scrollMaskView.isHidden = true
        } else {
            scrollMaskView.isHidden = true
        }
    }
}
