//
//  DKPreviewHintView.swift
//  SpaceKit
//
//  Created by bupozhuang on 2020/6/29.
//

import UIKit
import RxSwift
import RxCocoa
import SKCommon
import SKFoundation
import SKResource
import SpaceInterface
import SKInfra
import LarkDocsIcon

struct DKUnSupportViewInfo {
    let type: DriveUnsupportPreviewType
    let fileName: String
    let fileSize: UInt64
    let fileType: String
    let buttonVisable: Observable<Bool> // 是否显示使用第三方应用打开按钮
    let buttonEnable: Observable<Bool> // 按钮是否置灰
    let showDocTips: Bool // 文档附件不支持预览不支持导出说明
}

class DKPreviewHintView: UIView, DKViewModeChangable {
    private var displayMode: DrivePreviewMode = .normal {
        didSet {
            // 如果有card状态，则来自cardmode预览
            if displayMode == .card {
                isFromCardMode = true
            }
        }
    }
    private var isFromCardMode: Bool = false
    // 卡片态点击空白处进入全屏态
    var tapEnterFull: (() -> Void)?
    // 卡片模式下通知外部HintView自己处理全屏切换事件
    var didShowHintView: ((Bool) -> Void)?
    private lazy var tapGuesture: DriveCardModeTap =  {
        let guesture = DriveCardModeTap(target: self, action: #selector(didClickBlank(tap:)))
        return guesture
    }()
    var didClickRetryButtonAction: (() -> Void)?
    var isDisplaying: Bool {
        return showingView != nil
    }
    private var unSupportViewActionHandler: ((UIView, CGRect?) -> Void)? // 不支持界面第三方打开回调函数
    private weak var showingView: UIView? {// 记录当前展示的view，用于展示其他view时移除当前展示的view
        didSet {
            if displayMode == .card {
                didShowHintView?(showingView != nil)
            }
        }
    }
    private var showingBag = DisposeBag() // 用于绑定 showingView 的相关事件，每次替换showingView的时候都应该重置一下
    private lazy var loadingView: DocsLoadingViewProtocol = {
        return DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)!
    }()
    // 全屏模式下使用这个loading，避免切换时展示全屏白色loading
    private let circleLoadingView: DriveCircleLoadingView = DriveCircleLoadingView()
    
    private lazy var unsupportView: DriveUnSupportFileView = {
        let unsupportView = DriveUnSupportFileView(fileName: "",
                                                   mode: displayMode,
                                                   delegate: self)
        return unsupportView
    }()
    
    private lazy var cardModeUnsupportView: DKCardModeUnsupportView = {
        let unsupportView = DKCardModeUnsupportView(fileName: "",
                                                   mode: displayMode,
                                                   delegate: self)
        return unsupportView
    }()
    
    private lazy var driveTranscodingView: DriveTransCodingView = {
        let driveTranscodingView = DriveTransCodingView(mode: displayMode)
        driveTranscodingView.delegate = self
        return driveTranscodingView
    }()
    /// 下载页
    private lazy var downloadingView: DriveDownloadView = DriveDownloadView(mode: displayMode)

    /// 停止预览提示页
    private lazy var forbiddenView: DriveFetchFailedView = {
        let view = DriveFetchFailedView(frame: .zero)
        return view
    }()
    
    // 加载失败: 无权限、接口失败、下载失败、文件不存在、文件被删除等提示
    private lazy var failedView: DKPreviewFailedView = {
        let failedView = DKPreviewFailedView()
        return failedView
    }()
    
    private lazy var cardModeFailedView: DKCardModeFailedView = {
        let view = DKCardModeFailedView(mode: displayMode)
        return view
    }()
    
    private lazy var cardModeLoadingView: DriveFileBlockLoadingView = {
        let view = DriveFileBlockLoadingView()
        return view
    }()
    
    init(mode: DrivePreviewMode) {
        super.init(frame: .zero)
        self.displayMode = mode
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tapGuesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubView(_ subView: UIView) {
        UIView.performWithoutAnimation {
            addSubview(subView)
            makeConstraints(for: subView)
            self.layoutIfNeeded()
        }
    }
    private func makeConstraints(for view: UIView) {
        view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func prepareToShow() {
        showingBag = DisposeBag()
        showingView?.removeFromSuperview()
        isHidden = false
    }

    private func prepareToUpdate() {
        showingBag = DisposeBag()
        isHidden = false
    }

    private func prepareToHide() {
        showingView?.removeFromSuperview()
        showingBag = DisposeBag()
        showingView = nil
        isHidden = true
    }
    
    // 隐藏HintView
    func hide() {
        prepareToHide()
    }
    
    func showCardModeLoading() {
        guard cardModeLoadingView != showingView else {
            DocsLogger.driveInfo("is already loading")
            return
        }
        prepareToShow()
        setupSubView(cardModeLoadingView)
        cardModeLoadingView.startAnimate()
        showingView = cardModeLoadingView
    }
    
    func hideCardModeLoading() {
        guard cardModeLoadingView == showingView else {
            DocsLogger.driveInfo("is not loading")
            return
        }
        prepareToHide()
    }

    // MARK: - loading view
    func showLoading() {
        if isFromCardMode {
            showCardModeLoading()
        } else {
            showNormalLoading()
        }
    }
    
    func showNormalLoading() {
        guard loadingView.displayContent != showingView else {
            DocsLogger.driveInfo("is already loading")
            return
        }
        prepareToShow()
        setupSubView(loadingView.displayContent)
        loadingView.startAnimation()
        showingView = loadingView.displayContent
    }
    
    func hideLoading() {
        hideNormalLoading()
        hideCardModeLoading()
    }
    
    func hideNormalLoading() {
        guard loadingView.displayContent == showingView else {
            DocsLogger.driveInfo("is not loading")
            return
        }
        prepareToHide()
    }
    
    // MARK: - 全屏loading
    func showCircleLoading() {
        if showingView != circleLoadingView {
            prepareToShow()
            circleLoadingView.showLoading(on: self)
        }
        showingView = circleLoadingView
    }
    
    func hideCircleLoading() {
        prepareToHide()
        circleLoadingView.dismiss()
    }

    // MARK: - 请求失败提示界面
    func showFetchFailed(data: DKPreviewFailedViewData) {
        if isFromCardMode {
            showCardFailed(data: data)
        } else {
            showNormalFailed(data: data)
        }
    }
    
    private func showNormalFailed(data: DKPreviewFailedViewData) {
        if showingView != failedView {
            prepareToShow()
            setupSubView(failedView)
        } else {
            prepareToUpdate()
        }
        failedView.didClickRetryAction = { [weak self] in
            self?.didClickRetryButtonAction?()
        }
        failedView.render(data: data)
        showingView = failedView
    }
    
    private func showCardFailed(data: DKPreviewFailedViewData) {
        if showingView != cardModeFailedView {
            prepareToShow()
            setupSubView(cardModeFailedView)
        } else {
            prepareToUpdate()
        }
        cardModeFailedView.didClickRetryAction = { [weak self] in
            self?.didClickRetryButtonAction?()
        }
        cardModeFailedView.render(data: data)
        showingView = cardModeFailedView
    }
    
    func showDeleteRestore(type: RestoreType, completion: @escaping (() -> Void)) {
        let restoreView = DocsRestoreEmptyView(type: type)
        setupSubView(restoreView)
        prepareToShow()
        restoreView.restoreCompeletion = {
            completion()
        }
    }

    // MARK: - 转码中界面
    func showTranscoding(fileType: String, handler: ((UIView, CGRect?) -> Void)?, downloadForPreviewHandler: (() -> Void)?) {
        prepareToShow()
        driveTranscodingView.fileType = DriveFileType(fileExtension: fileType)
        driveTranscodingView.downloadForPreviewHandler = downloadForPreviewHandler
        setupSubView(driveTranscodingView)
        showingView = driveTranscodingView
        self.unSupportViewActionHandler = handler
    }
    
    
    func hideTranscoding() {
        guard driveTranscodingView == showingView else {
            DocsLogger.error("transcodingView is not showing")
            return
        }
        prepareToHide()
    }
    
    // MARK: - 不支持界面
    func showUnSupportView(info: DKUnSupportViewInfo, handler: ((UIView, CGRect?) -> Void)?) {
        if isFromCardMode {
            showCardUnSupportView(info: info, handler: handler)
        } else {
            showNormalUnSupportView(info: info, handler: handler)
        }
    }
    
    func showNormalUnSupportView(info: DKUnSupportViewInfo, handler: ((UIView, CGRect?) -> Void)?) {
        if showingView != unsupportView {
            prepareToShow()
            setupSubView(unsupportView)
        } else {
            prepareToUpdate()
        }
        let config = DriveUnSupportConfig(fileName: info.fileName,
                                          fileType: info.fileType,
                                          fileSize: info.fileSize,
                                          buttonVisiable: true,
                                          buttonEnable: true)
        unsupportView.setUnsupportType(type: info.type, config: config)
        
        info.buttonVisable.asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak unsupportView] visable in
                let showExportTips = !visable && info.showDocTips
                unsupportView?.showExportTips(showExportTips)
                unsupportView?.setPreviewButton(visiable: visable)
            })
            .disposed(by: showingBag)
        info.buttonEnable.asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak unsupportView] enable in
                unsupportView?.setPreviewButton(enable: enable)
            })
            .disposed(by: showingBag)
        showingView = unsupportView
        self.unSupportViewActionHandler = handler
    }
    
    private func showCardUnSupportView(info: DKUnSupportViewInfo, handler: ((UIView, CGRect?) -> Void)?) {
        if showingView != cardModeUnsupportView {
            prepareToShow()
            setupSubView(cardModeUnsupportView)
        } else {
            prepareToUpdate()
        }
        let config = DriveUnSupportConfig(fileName: info.fileName,
                                          fileType: info.fileType,
                                          fileSize: info.fileSize,
                                          buttonVisiable: true,
                                          buttonEnable: true)
        cardModeUnsupportView.setUnsupportType(type: info.type, config: config)
        
        info.buttonVisable.asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak cardModeUnsupportView] visable in
                let showExportTips = !visable && info.showDocTips
                cardModeUnsupportView?.showExportTips(showExportTips)
                cardModeUnsupportView?.setPreviewButton(visiable: visable)
            })
            .disposed(by: showingBag)
        info.buttonEnable.asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak cardModeUnsupportView] enable in
                cardModeUnsupportView?.setPreviewButton(enable: enable)
            })
            .disposed(by: showingBag)
        showingView = cardModeUnsupportView
        self.unSupportViewActionHandler = handler
    }
    
    // MARK: - 显示下载页面
    func showDownloadingView(status: DriveDownloadView.LoadStatus, isFullScreen: Bool) {
        prepareToShow()
        setupSubView(downloadingView)
        showingView = downloadingView
        if isFullScreen {
            downloadingView.fullscreenRender(status: status)
        } else {
            downloadingView.render(status: status)
        }
    }
    
    func updateDownloadingView(status: DriveDownloadView.LoadStatus, isFullScreen: Bool, handler: (() -> Void)? = nil) {
        guard showingView == downloadingView else {
            DocsLogger.error("downloading view not show")
            return
        }
        prepareToUpdate()
        downloadingView.retryAction = handler
        if isFullScreen {
            downloadingView.fullscreenRender(status: status)
        } else {
            downloadingView.render(status: status)
        }
    }
    
    func hideDownloadingView() {
        guard downloadingView == showingView else {
            DocsLogger.error("downloadingView is not showing")
            return
        }
        prepareToHide()
    }

    // MARK: - 禁止预览界面提示
    func showForbiddenView(reason: String, image: UIImage?) {
        if showingView != forbiddenView {
            prepareToShow()
            setupSubView(forbiddenView)
        } else {
            prepareToUpdate()
        }

        forbiddenView.retryAction = nil
        forbiddenView.render(reason: reason, image: image)
        showingView = forbiddenView
    }
    
    func changeMode(_ mode: DrivePreviewMode, animate: Bool) {
        guard displayMode != mode else { return }
        displayMode = mode
        guard let view = showingView as? DKViewModeChangable else { return }
        view.changeMode(mode, animate: animate)
    }
    
    @objc
    func didClickBlank(tap: DriveCardModeTap) {
        DocsLogger.driveInfo("DKPreviewHintView: tap gesture state: \(tap.state.rawValue)")
        if displayMode == .card {
            tapEnterFull?()
        }
    }
}

extension DKPreviewHintView: DriveUnSupportFileViewDelegate {
    func didClickOpenWith3rdApp(button: UIButton) {
        DocsLogger.driveInfo("click open with 3rd App")
        self.unSupportViewActionHandler?(button, button.bounds)
    }
}
