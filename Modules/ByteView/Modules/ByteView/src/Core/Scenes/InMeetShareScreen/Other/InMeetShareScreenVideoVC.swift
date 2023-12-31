//
// Created by liujianlong on 2022/9/2.
//

import UIKit
import RxSwift
import SnapKit
import RxCocoa
import ByteViewCommon
import ByteViewNetwork
import ByteViewRtcBridge

// NOTE: 先抽一个不显示 工具栏 的共享屏幕视图, 后续再考虑复用集成
class InMeetShareScreenVideoVC: UIViewController {
    private lazy var videoView = {
        let videoView = ShareScreenVideoView(meeting: viewModel.meeting, showHighDefinitionIndicator: self.showHighDefinitionIndicator)
        videoView.zoomDelegate = self
        return videoView
    }()
    private var watermarkView: UIView?
    private let showHighDefinitionIndicator: Bool
    let viewModel: InMeetShareScreenVM
    let disposeBag = DisposeBag()

    // 共享标注
    var sketchViewModel: SketchViewModel?
    var sketchView: SketchView?
    var selfNeedAdjustAnnotate: Bool = true {
        didSet {
            guard oldValue != selfNeedAdjustAnnotate else { return }
            self.sketchViewModel?.selfNeedAdjustAnnotate = selfNeedAdjustAnnotate
        }
    }
    var sharerNeedAdjustAnnotate: Bool = true {
        didSet {
            guard oldValue != sharerNeedAdjustAnnotate else { return }
            self.sketchViewModel?.sharerNeedAdjustAnnotate = sharerNeedAdjustAnnotate
        }
    }

    var streamRenderView: StreamRenderView {
        videoView.streamRenderView
    }

    var isCellVisible: Bool {
        get {
            videoView.streamRenderView.isCellVisible
        }

        set {
            videoView.streamRenderView.isCellVisible = newValue
        }
    }

    init(viewModel: InMeetShareScreenVM, showHighDefinitionIndicator: Bool = true) {
        self.viewModel = viewModel
        self.showHighDefinitionIndicator = showHighDefinitionIndicator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(videoView)
        self.videoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        bindViewModel()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    private func bindViewModel() {
        viewModel.addListener(self)
        let sessionId = viewModel.meeting.sessionId
        viewModel.shareScreenGridInfo
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] gridInfo in
                    guard let self = self else {
                        return
                    }
                    let isSipOrRoom = gridInfo?.user.isSipOrRoom ?? false
                    self.videoView.setStreamKey(gridInfo?.rtcUid.map({ .screen(uid: $0, sessionId: sessionId) }), isSipOrRoom: isSipOrRoom)
                })
                .disposed(by: self.disposeBag)
        // 设置共享桌面水印
        Observable.combineLatest(viewModel.meeting.service.larkUtil.getVCShareZoneWatermarkView(),
                                 viewModel.shareWatermark.showWatermarkRelay.asObservable().distinctUntilChanged())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (view, show) in
                self?.configWatermarkView(showWatermark: show, view: view)
            }).disposed(by: self.disposeBag)
    }

    func configWatermarkView(showWatermark: Bool, view: UIView?) {
        watermarkView?.removeFromSuperview()
        guard showWatermark, let view = view else {
            watermarkView = nil
            return
        }
        view.frame = self.videoView.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.videoView.addSubview(view)
        view.layer.zPosition = .greatestFiniteMagnitude
        self.watermarkView = view
    }
}

extension InMeetShareScreenVideoVC: InMeetShareScreenViewModelListener {

    func didChangeCursorInfo(newCursorInfo: CursorInfo) {
        Util.runInMainThread {
            self.videoView.sketchVideoWrapperView.updateCursor(info: newCursorInfo)
        }
    }

    func didChangeAdjustAnnotate(selfNeedAdjust: Bool, sharerNeedAdjust: Bool) {
        selfNeedAdjustAnnotate = selfNeedAdjust
        sharerNeedAdjustAnnotate = sharerNeedAdjust
    }

    func didChangeSketchSettings(newSetting: SketchSettings) {
        adaptSketchEventOrSettingChange(newSettings: newSetting)
    }

    func didChangeSketchEvent(newEvent: SketchEvent) {
        adaptSketchEventOrSettingChange(newEvent: newEvent)
    }

    private func adaptSketchEventOrSettingChange(newEvent: SketchEvent? = nil, newSettings: SketchSettings? = nil) {
        Util.runInMainThread {
            guard let settings = newSettings ?? self.viewModel.sketchSettings else { return }
            let event = newEvent ?? self.viewModel.sketchEvent
            switch event {
            case .start(let data):
                self.startSketch(shareScreenData: data,
                                  settings: settings)
            case .end(let data):
                self.endSketch(shareScreenData: data)
            case .update(old: let oldData, new: let newData):
                // update处于标注开启阶段，如果当前真实状态没有开启，则需要补充开启逻辑
                if self.sketchViewModel == nil {
                    self.startSketch(shareScreenData: newData,
                                      settings: settings)
                } else {
                    self.updateSketch(oldData: oldData, newData: newData)
                }
            case .change(old: let oldData, new: let newData):
                self.endSketch(shareScreenData: oldData)
                self.startSketch(shareScreenData: newData,
                                  settings: settings)
            case .pause(let data):
                if self.sketchViewModel == nil, data.isSketch {
                    self.startSketch(shareScreenData: data,
                                      settings: settings)
                }
            default:
                break
            }
        }
    }

    private func startSketch(shareScreenData: ScreenSharedData,
                             settings: SketchSettings) {
        ByteViewSketch.logger.info("startSketch(id: \(shareScreenData.shareScreenID))")
        self.viewModel.startSketch()
        if self.sketchViewModel == nil {
            let canvasSize = CGSize(width: CGFloat(shareScreenData.width),
                                    height: CGFloat(shareScreenData.height))
            let currentAcount = viewModel.meeting.account
            let sketch = RustSketch(deviceID: currentAcount.deviceId,
                                    userID: currentAcount.id,
                                    userType: .larkUser,
                                    logInstance: RustSketch.defaultLogInstance,
                                    settings: settings,
                                    currentStep: 0)
            let sketchService = SketchService(meeting: viewModel.meeting,
                                                  shareScreenID: shareScreenData.shareScreenID)
            let sketchViewModel = SketchViewModel(sketch: sketch,
                                                  sketchService: sketchService,
                                                  meeting: viewModel.meeting,
                                                  selfNeedAdjustAnnotate: selfNeedAdjustAnnotate,
                                                  sharerNeedAdjustAnnotate: sharerNeedAdjustAnnotate,
                                                  canvasSize: canvasSize)
            self.sketchViewModel = sketchViewModel
            sketchView = SketchView()
            sketchView?.clipsToBounds = true
            sketchView?.bindViewModel(sketch: sketchViewModel)
            self.videoView.sketchVideoWrapperView.sketchView = sketchView
            sketchViewModel.startSketch(isActive: false, shouldShowMenu: false, shareScreenData: shareScreenData)
        }
    }

    private func endSketch(shareScreenData: ScreenSharedData) {
        ByteViewSketch.logger.info("endSketch")
        viewModel.stopSketch()
        cleanupSketch()
    }

    private func cleanupSketch() {
        ByteViewSketch.logger.info("cleanupSketch")
//        if hasSharedScreenGridCell {
//            sharedScreenGridCell?.gridViews.first?.sketchVideoWrapperView.sketchView = nil
//        }
        videoView.sketchVideoWrapperView.sketchView = nil
        sketchView = nil
        sketchViewModel = nil
    }

    private func updateSketch(oldData: ScreenSharedData,
                              newData: ScreenSharedData) {
        guard let sketchVM = sketchViewModel else {
            return
        }
        _ = sketchVM.updateSketch(oldData: oldData, newData: newData)
    }
}


extension InMeetShareScreenVideoVC: ZoomViewZoomscaleObserver {
    func zoomScaleChangeEvent(_ scale: CGFloat, oldValue: CGFloat, type: ZoomView.ZoomScaleChangeType) {
        Logger.ui.info("zoomScaleChangeEvent: \(scale) old: \(oldValue): type: \(type)")
        guard let shareScreenID = viewModel.meeting.data.inMeetingInfo?.shareScreen?.shareScreenID else {
            return
        }
        let isZoomIn = scale > oldValue
        MeetingTracksV2.trackShareScreenZoom(shareID: shareScreenID, isZoomIn: isZoomIn, isClick: type == .doubleTap)
    }
}
