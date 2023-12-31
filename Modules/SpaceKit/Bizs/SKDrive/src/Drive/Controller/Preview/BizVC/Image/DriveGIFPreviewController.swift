//
//  DriveGIFPreviewController.swift
//  DoscSDK
//
//  Created by Wenjian Wu on 2019/3/6.
//

import UIKit
import SKCommon
import SKFoundation
import UniverseDesignColor
import UniverseDesignLoading
import ByteWebImage

class DriveGIFPreviewController: UIViewController, UIGestureRecognizerDelegate {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    private var loadingIndicatorView: UDSpin = {
        let view = UDLoading.spin(config: UDSpinConfig(indicatorConfig: UDSpinIndicatorConfig(size: 20, color: UDColor.N400), textLabelConfig: nil))
        return view
    }()

    private var imageView: UIImageView = {
        let view: UIImageView
        if UserScopeNoChangeFG.TYP.DriveWebpEable {
            view = ByteImageView()
            view.contentMode = .scaleAspectFit
        } else {
            view = UIImageView()
            view.contentMode = .scaleAspectFit
        }
        return view
    }()

    private let viewModel: DriveGIFPreviewViewModel
    private var displayMode: DrivePreviewMode
    private var isLoaded = false

    private let tapHandler = DriveTapEnterFullModeHandler()
    private let _panGesture = UIPanGestureRecognizer()

    weak var bizVCDelegate: DriveBizViewControllerDelegate?
    weak var screenModeDelegate: DrivePreviewScreenModeDelegate?

    init(viewModel: DriveGIFPreviewViewModel, displayMode: DrivePreviewMode) {
        self.viewModel = viewModel
        self.displayMode = displayMode
        super.init(nibName: nil, bundle: nil)
        viewModel.renderDelegate = self
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        viewModel.stop()
        DocsLogger.debug("DriveGIFPreviewController-----deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        viewModel.loadContent()
    }

    private func setupUI() {
        view.backgroundColor = .clear
        view.accessibilityIdentifier = "drive.gif.view"
        view.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.left.right.top.bottom.equalToSuperview()
        }

        view.addSubview(loadingIndicatorView)
        loadingIndicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        loadingIndicatorView.isHidden = false
        loadingIndicatorView.reset()
        _panGesture.maximumNumberOfTouches = 1
        view.addGestureRecognizer(_panGesture)
        _panGesture.delegate = self
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

extension DriveGIFPreviewController: DriveGIFRenderDelegate {
    func updateFrame(newFrame: UIImage) {
        if !isLoaded {
            isLoaded = true
            loadingIndicatorView.isHidden = true
            tapHandler.addTapGestureRecognizer(targetView: view) { [weak self] in
                self?.screenModeDelegate?.changeScreenMode()
            }
            bizVCDelegate?.openSuccess(type: openType)
        }
        imageView.image = newFrame
    }

    func renderFailed() {
        bizVCDelegate?.previewFailed(self, needRetry: false, type: openType, extraInfo: nil)
    }

    func fileUnsupport(reason: DriveUnsupportPreviewType) {
        bizVCDelegate?.unSupport(self, reason: reason, type: openType)
    }
}

extension DriveGIFPreviewController: DriveBizeControllerProtocol {
    var openType: DriveOpenType {
        return .gifView
    }
    
    var panGesture: UIPanGestureRecognizer? {
        return _panGesture
    }
    
    var mainBackgroundColor: UIColor {
        if let delegate = screenModeDelegate, delegate.isInFullScreenMode() {
            return UDColor.staticBlack
        }
        return UDColor.bgBase
    }
    
    func willUpdateDisplayMode(_ mode: DrivePreviewMode) {
        
    }
    
    func changingDisplayMode(_ mode: DrivePreviewMode) {
    }
    
    func updateDisplayMode(_ mode: DrivePreviewMode) {
        self.displayMode = mode
    }
}
