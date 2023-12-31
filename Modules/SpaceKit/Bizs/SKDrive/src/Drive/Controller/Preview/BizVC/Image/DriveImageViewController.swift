//
//  DriveImagePreviewController.swift
//  SpaceKit
//
//  Created by Da Lei on 2019/5/14.
//

import Foundation
import SnapKit
import RxSwift
import RxCocoa
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignToast

class DriveImageViewController: UIViewController, UIGestureRecognizerDelegate {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    var showComment: Bool = true {
        didSet {
            if let isfullScreen = screenModeDelegate?.isInFullScreenMode() {
                picView.showComment = showComment && !isfullScreen
            } else {
                picView.showComment = showComment
            }
        }
    }
    var canComment: Bool = true {
        didSet {
            picView.canComment = canComment
        }
    }
    weak var areaCommentDelegate: DriveAreaCommentDelegate?
    weak var screenModeDelegate: DrivePreviewScreenModeDelegate?
    weak var bizDelegate: DriveBizViewControllerDelegate?
    private var picView: ImagePreviewViewProtocol
    private lazy var progressView: DriveProgressView = {
        let view = DriveProgressView(frame: .zero)
        return view
    }()
    private lazy var loadingView = createLoadingView()
    private var viewModel: DriveImageViewModelType
    private var displayMode: DrivePreviewMode
    private var canCommentRelay: BehaviorRelay<Bool>
    private let bag = DisposeBag()
    private let _panGesture = UIPanGestureRecognizer()

    init(viewModel: DriveImageViewModelType, canComment: BehaviorRelay<Bool>, displayMode: DrivePreviewMode) {
        self.viewModel = viewModel
        self.canCommentRelay = canComment
        self.displayMode = displayMode
        picView = DriveImagePreviewView(frame: .zero)
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doInitUI()
        navigationController?.interactivePopGestureRecognizer?.addTarget(self, action: #selector(popGestureRecognizer(_:)))
        bindViewModel()
        view.addGestureRecognizer(_panGesture)
        _panGesture.maximumNumberOfTouches = 1
        _panGesture.delegate = self
    }
    
    private func bindViewModel() {
        viewModel.hostContainer = self
        viewModel.imageSource.drive(onNext: {[weak self] (source) in
            guard let self = self else { return }
            switch source {
            case .local(let filePath):
                self.picView.setupImageView(path: filePath)
            case .linearized(let image):
                self.update(image)
            case .thumb(let image):
                self.update(image)
            case .failed:
                self.bizDelegate?.previewFailed(self, needRetry: true, type: self.openType, extraInfo: nil)
            }
        }).disposed(by: bag)
        viewModel.forbidDownload.drive(onNext: {[weak self] (_) in
            guard let self = self else { return }
            self.bizDelegate?.exitPreview(result: .cancelOnCellularNetwork, type: self.openType)
        }).disposed(by: bag)
        canCommentRelay.subscribe(onNext: { [weak self] value in
            self?.picView.canComment = value
        }).disposed(by: bag)
        
        viewModel.followContentManager.imageFollowStateUpdated.drive(onNext: { [weak self] state in
            guard let self = self else { return }
            self.picView.setZoomScale(state.scale, animated: true)
        })
        .disposed(by: bag)
        
        viewModel.downloadState.drive(onNext: { [weak self] state in
            guard let self = self else { return }
            self.configProgressView(state)
        }).disposed(by: bag)
        
        viewModel.progressTouchable.drive(onNext: { [weak self] touchable in
            guard let self = self else { return }
            self.progressView.touchable = touchable
        }).disposed(by: bag)
        
        picView.currentZoomScale?
            .map { DriveImageFollowState(scale: Double($0)) }
            .bind(to: viewModel.followContentManager.imageStateRelay)
            .disposed(by: bag)
    }
    @objc
    func popGestureRecognizer(_ ges: UIGestureRecognizer) {
        // 侧滑返回手势时停止加载image
        // 侧滑居然不在UITrackingRunLoopMode，这个手动停止加载数据
        if ges.state == .began {
            viewModel.suspend()
        }
        if ges.state == .ended {
            viewModel.resume()
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        areaCommentDelegate?.commentViewDisplay(controller: self)
        if let isFullScreen = screenModeDelegate?.isInFullScreenMode() {
            picView.showAreaDisplayView(!isFullScreen && showComment)
        }
    }
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil {
            self.areaCommentDelegate?.areaComment(controller: self, enter: .normal)
        }
    }

    func update(_ image: UIImage?) {
        self.perform(#selector(_update(_:)), with: image, afterDelay: 0, inModes: [.default])
    }

    @objc
    private func _update(_ image: UIImage?) {
        picView.setupImageView(image: image)
    }
    private func doInitUI() {
        view.backgroundColor = .clear
        view.accessibilityIdentifier = "drive.image.view"
        setupPicView()
        setupLoadingView()
        setupProgressView()
    }
    
    private func setupProgressView() {
        progressView.isHidden = true
        view.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(32)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-16)
            make.width.greaterThanOrEqualTo(120)
        }
        progressView.layer.cornerRadius = 16.0
        progressView.layer.masksToBounds = true
        progressView.clickBlock = { [weak self] in
            self?.viewModel.resume()
        }
    }
    
    private func configProgressView(_ state: DriveImageDownloadState) {
        progressView.updateState(state)
        switch state {
        case .done:
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) {
                self.progressView.isHidden = true
            }
        case .failed:
            UDToast.docs.showMessage(BundleI18n.SKResource.CreationMobile_ECM_DownloadUnableToast, on: view, msgType: .failure)
        default:
            break
        }

    }
    private func createLoadingView() -> UIView {
        let view = UIView()
        view.backgroundColor = .white
        view.isHidden = true
        let iconView = UIImageView(image: BundleResources.SKResource.Common.Thumbnail.thumbnail_file_image)
        view.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        return view
    }
    private func setupPicView() {
        UIView.performWithoutAnimation {
            view.addSubview(picView)
            picView.updatePreviewStratery(DriveImagePreviewStrategy.defaultStrategy(for: self.view.bounds.size))
            picView.snp.makeConstraints { (make) in
                make.left.bottom.right.top.equalToSuperview()
            }
            view.layoutIfNeeded()
        }
        picView.delegate = self
    }
    private func setupLoadingView() {
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loadingView.isHidden = true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

extension DriveImageViewController: DriveImagePreviewViewDelegate {
    func imagePreviewViewFailed() {
        bizDelegate?.previewFailed(self, needRetry: false, type: self.openType, extraInfo: nil)
    }

    func imagePreviewViewDeselected(_ view: DriveImagePreviewView) {
        areaCommentDelegate?.dismissCommentViewController()
    }
    func imagePreviewView(_ view: DriveImagePreviewView, enter mode: DriveImagePreviewMode) {
        switch mode {
        case .normal:
            self.screenModeDelegate?.changePreview(situation: .exitFullScreen)
            self.areaCommentDelegate?.areaComment(controller: self,
                                                  enter: .normal)
        case .selection:
            self.screenModeDelegate?.changePreview(situation: .imageFullScreen)
            self.areaCommentDelegate?.areaComment(controller: self,
                                                  enter: .edit)
        }
    }
    func imagePreviewViewBlankDidTap(_ view: DriveImagePreviewView) {
        // 如果当前有评论框展示，dismiss评论框
        let isVisible = areaCommentDelegate?.getCommentVisible() ?? false
        if !isVisible { // 切换全屏模式
            if screenModeDelegate?.isInFullScreenMode() == true {
                screenModeDelegate?.changePreview(situation: .exitFullScreen)
                picView.showAreaDisplayView(showComment)
            } else {
                screenModeDelegate?.changePreview(situation: .imageFullScreen)
                picView.showAreaDisplayView(false)
            }
        } else {
            areaCommentDelegate?.dismissCommentViewController()
        }
    }
    func imagePreviewView(_ view: DriveImagePreviewView, commentAt area: DriveAreaComment.Area) {
        areaCommentDelegate?.commentAt(area, commentSource: .image)
    }
    func imagePreviewView(_ view: DriveImagePreviewView, didSelectedAt area: DriveAreaComment) {
        areaCommentDelegate?.didSelectAt(area, commentSource: .image)
    }

    func imagePreviewViewImageDidUpdated(_ view: DriveImagePreviewView) {
        bizDelegate?.openSuccess(type: self.openType)
        viewModel.followContentManager.imagePreviewReadyRelay.accept(true)
    }
}

extension DriveImageViewController: DriveSupportAreaCommentProtocol {
    var defaultCommentArea: DriveAreaComment.Area {
        return DriveAreaComment.Area.blankArea
    }

    var areaCommentEnabled: Bool {
        return true
    }

    var commentSource: DriveCommentSource {
        return .image
    }

    func selectArea(at commentId: String) {
        picView.selectArea(at: commentId)
    }
    func selectArea(at index: Int) {
        picView.selectArea(at: index)
    }
    func deselectArea() {
        picView.deselectArea()
    }
    func showAreaEditView(_ show: Bool) {
        picView.showAreaEditView(show)
    }
    func updateAreas(_ areas: [DriveAreaComment]) {
        DocsLogger.debug("areas count: \(areas.count), picViewFrame: \(picView.frame)")
        picView.updateAreas(areas)
    }
    func areaDisplayView() -> UIView? {
        return picView.commentDisplayView
    }
    
    func didTapBlank(_ callback: @escaping (() -> Void)) {
        picView.didTapBlank(callback)
    }
}

extension DriveImageViewController: DriveBizeControllerProtocol {
    var openType: DriveOpenType {
        return viewModel.isLineImage ? .lineImageView : .imageView
    }
    
    var panGesture: UIPanGestureRecognizer? {
        _panGesture
    }

    var mainBackgroundColor: UIColor {
        if let delegate = screenModeDelegate, delegate.isInFullScreenMode() {
            return UDColor.staticBlack
        }
        return UDColor.bgBase
    }

    func willUpdateDisplayMode(_ mode: DrivePreviewMode) {
        if mode == .card, screenModeDelegate?.isInFullScreenMode() == true {
            screenModeDelegate?.changePreview(situation: .exitFullScreen)
        }
    }
    
    func changingDisplayMode(_ mode: DrivePreviewMode) {
    }
    
    func updateDisplayMode(_ mode: DrivePreviewMode) {
        self.displayMode = mode
    }
}

// MARK: - DriveFollowContentProvider
extension DriveImageViewController: DriveFollowContentProvider {
    
    var vcFollowAvailable: Bool {
        return true
    }
    
    var followScrollView: UIScrollView? {
        return nil
    }
    
    func setup(followDelegate: DriveFollowAPIDelegate, mountToken: String?) {
        viewModel.followContentManager.setup(follwDelegate: followDelegate, mountToken: mountToken)
    }
    
    func registerFollowableContent() {
        viewModel.followContentManager.registerFollowableContent()
    }
}

// MARK: - DriveAutoRotateAdjustable
extension DriveImageViewController: DriveAutoRotateAdjustable {
    func orientationDidChange(orientation: UIDeviceOrientation) {
        if orientation.isLandscape {
            // 图片横屏下隐藏局部评论框
            picView.showAreaDisplayView(false)
        }
        if orientation.isPortrait {
            screenModeDelegate?.changePreview(situation: .exitFullScreen)
        }
    }
}

class DriveProgressView: UIView {
    var clickBlock: (() -> Void)?
    var touchable: Bool = true {
        didSet {
            statusLabel.textColor = touchable ? UDColor.primaryOnPrimaryFill : UDColor.primaryOnPrimaryFill.withAlphaComponent(0.5)
        }
    }
    func updateState(_ state: DriveImageDownloadState) {
        self.state = state
        switch state {
        case let .done(tips):
            self.isHidden = false
            statusLabel.text = tips
        case let .progress(tips):
            self.isHidden = false
            statusLabel.text = tips
        case .none:
            self.isHidden = true
            statusLabel.text = nil
        case let .failed(tips):
            self.isHidden = false
            statusLabel.text = tips
        }
    }
    private var state: DriveImageDownloadState = .none
    private(set) lazy var statusLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = UIFont.systemFont(ofSize: 14)
        view.textColor = UDColor.primaryOnPrimaryFill
        view.textAlignment = .center
        self.addSubview(view)
        return view
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgMask
        setupSubviews()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        statusLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }
    }
    
    private func setupGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tap)
    }
    
    @objc
    private func tapped() {
        guard touchable else {
            return
        }
        if case DriveImageDownloadState.failed = state {
            clickBlock?()
        }
    }
}
