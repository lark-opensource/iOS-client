//
//  DriveDownloadView.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/22.
//

import UIKit
import SKCommon
import SKResource
import SKFoundation
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignProgressView
import UniverseDesignButton
import LarkDocsIcon

class DriveDownloadView: UIView, DKViewModeChangable {
    enum LoadStatus {
        case prepare(fileType: DriveFileType)
        case loading(progress: Float)
        case failed
    }
    
    weak var screenModeDelegate: DrivePreviewScreenModeDelegate?

    var retryAction: (() -> Void)?
    var retryButtonEnable: Bool = true {
        didSet {
            let buttonThemeColor = retryButtonEnable ? UDEmpty.primaryColor : UDEmpty.primaryDisableColor
            failedView.primaryButtonConfig = UDButtonUIConifg(normalColor: buttonThemeColor, type: .middle)
        }
    }
    private var displayMode: DrivePreviewMode = .normal
    private var curStatus: LoadStatus?
    private let tapHandler = DriveTapEnterFullModeHandler()
    private(set) lazy var downloadingContainer: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        addSubview(view)
        return view
    }()

    private(set) lazy var failedContainer: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.isHidden = true
        addSubview(view)
        return view
    }()

    // 全屏模式下使用这个loading，避免切换时展示全屏白色loading
    private lazy var circleLoadingView: DriveCircleLoadingView = {
        let view = DriveCircleLoadingView()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private func showCircleLoading() {
        guard circleLoadingView.superview == nil else {
            return
        }
        circleLoadingView.showLoading(on: self)
    }
    private func stopCircleLoading() {
        circleLoadingView.dismiss()
    }

    private(set) lazy var progressBar: UDProgressView = {
        let config = UDProgressViewUIConfig(type: .linear, barMetrics: .default, layoutDirection: .horizontal, showValue: false)
        let view = UDProgressView(config: config)
        downloadingContainer.addSubview(view)
        return view
    }()

    private(set) lazy var iconView: UIImageView = {
        let view = UIImageView(frame: .zero)
        downloadingContainer.addSubview(view)
        return view
    }()

    private(set) lazy var statusLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.font = UIFont.systemFont(ofSize: 14)
        view.textColor = UDColor.textCaption
        view.text = BundleI18n.SKResource.Drive_Drive_LoadingIn
        view.textAlignment = .center
        downloadingContainer.addSubview(view)
        return view
    }()
    
    private(set) lazy var failedView: UDEmpty = {
        let failedView = UDEmpty(config: .init(title: .init(titleText: ""),
                                               description: .init(descriptionText: BundleI18n.SKResource.Drive_Drive_LoadingFail),
                                               imageSize: 100,
                                               type: .loadingFailure,
                                               labelHandler: nil,
                                               primaryButtonConfig: (BundleI18n.SKResource.Drive_Drive_Retry, { [weak self] button in
                                                    guard let self = self else { return }
                                                    guard self.retryButtonEnable else { return }
                                                    self.retryButtonClick(button)
                                               }),
                                               secondaryButtonConfig: nil))
        failedContainer.addSubview(failedView)
        return failedView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgBase
        setupSubviews()
        setupGesture()
    }
    
    init(mode: DrivePreviewMode) {
        super.init(frame: .zero)
        self.displayMode = mode
        backgroundColor = UDColor.bgBase
        setupSubviews()
        setupGesture()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func retryButtonClick(_ button: UIButton) {
        retryAction?()
    }

    deinit {
        DocsLogger.driveInfo("DriveDownloadView-----deinit")
    }
    
    func changeMode(_ mode: DrivePreviewMode, animate: Bool) {
        guard displayMode != mode else { return }
        displayMode = mode
        let iconSize = (displayMode == .normal ? 64 : 42)
        let iconLabelSpace = (displayMode == .normal ? -14 : -12)
        let labelBarSpace = (displayMode == .normal ? 17 : 8)
        iconView.snp.updateConstraints { make in
            make.width.height.equalTo(iconSize)
            make.bottom.equalTo(statusLabel.snp.top).offset(iconLabelSpace)
        }
        progressBar.snp.updateConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(labelBarSpace)
        }
        
        if animate {
            UIView.animate(withDuration: 0.25) {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        }
    }
}

extension DriveDownloadView {

    private func setupSubviews() {
        let iconSize = (displayMode == .normal ? 64 : 42)
        let iconLabelSpace = (displayMode == .normal ? -14 : -12)
        let labelBarSpace = (displayMode == .normal ? 17 : 8)
        downloadingContainer.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        failedContainer.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        statusLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(((iconSize - iconLabelSpace) - (4 + labelBarSpace)) / 2)
            make.height.equalTo(20)
        }
        
        progressBar.snp.makeConstraints { (make) in
            make.top.equalTo(statusLabel.snp.bottom).offset(labelBarSpace)
            make.left.equalToSuperview().offset(68)
            make.right.equalToSuperview().offset(-68)
            make.height.equalTo(4)
        }

        iconView.snp.makeConstraints { (make) in
            make.bottom.equalTo(statusLabel.snp.top).offset(iconLabelSpace)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(iconSize)
        }
        
        failedView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }
    
    private func setupGesture() {
        tapHandler.addTapGestureRecognizer(targetView: self) { [weak self] in
            guard let self = self else { return }
            if self.screenModeDelegate?.isInFullScreenMode() ?? false {
                self.screenModeDelegate?.changePreview(situation: .exitFullScreen)
                self.stopCircleLoading()
                if let status = self.curStatus {
                    self.render(status: status)
                }
            }
        }
    }
}

// MARK: - Public
extension DriveDownloadView {

    func updateProgress(_ progress: Float) {
        progressBar.setProgress(CGFloat(progress), animated: true)
    }
    func reset() {
        stopCircleLoading()
        updateProgress(0.0)
    }

    func render(status: LoadStatus) {
        stopCircleLoading()
        downloadingContainer.isHidden = true
        failedContainer.isHidden = true
        backgroundColor = UDColor.bgBase
        curStatus = status
        switch status {
        case let .prepare(fileType):
            iconView.image = fileType.roundImage
            downloadingContainer.isHidden = false
        case let .loading(progress):
            updateProgress(progress)
            downloadingContainer.isHidden = false
        case .failed:
            failedContainer.isHidden = false
        }
    }
    func fullscreenRender(status: LoadStatus) {
        downloadingContainer.isHidden = true
        failedContainer.isHidden = true
        backgroundColor = .clear
        curStatus = status
        switch status {
        case let .prepare(fileType):
            iconView.image = fileType.roundImage
            showCircleLoading()
        case .loading:
            showCircleLoading()
        case .failed:
            backgroundColor = UDColor.bgBase
            stopCircleLoading()
            failedContainer.isHidden = false
        }

    }
}
