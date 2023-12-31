//
//  DownloadPercentController.swift
//  WebBrowser
//
//  Created by ByteDance on 2023/3/7.
//

import Foundation
import LarkUIKit
import EENavigator
import LKCommonsLogging
import UniverseDesignToast

class DownloadPercentController: BaseUIViewController {
    public static let logger = Logger.webBrowserLog(DownloadPercentController.self, category: "DownloadPercentController")
    
    let model: WebDownloadModel
    private let downloadQueue = OPDownloadQueue()
    private var downloadView: DownloadContentView?
    private var noSupportView: DownloadNoSupportView?
    private lazy var titleView = BaseTitleView()
    
    var didStartDownload:((_ model: WebDownloadModel) -> Void)?
    var didComplete:((_ error: Error?, _ model: WebDownloadModel) -> Void)?
    var showDrivePreview:((_ model: WebDownloadModel) -> Void)?
    var showActivityVC:((_ model: WebDownloadModel, _ view: UIView?) -> Void)?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    deinit {
        cancelDownload()
        removeObserver()
        Self.logger.info("OPWDownload DownloadPercentController deinit")
    }
    
    init(model: WebDownloadModel) {
        self.model = model
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationTitle()
        downloadQueue.delegate = self
        addObserver()
        createContentView()
        updateConstraintsIfNeed()
    }
    
    override func viewDidLayoutSubviews() {
        guard Display.pad else {
            return
        }
        updateConstraintsIfNeed()
    }
    
    private func setNavigationTitle() {
        // 导航栏标题, 优先显示文件名, 降级显示网页URL
        if let filename = model.response?.suggestedFilename {
            titleView.setTitle(title: filename)
        } else if let url = model.response?.url?.absoluteString {
            titleView.setTitle(title: url)
        }
        titleView.nameLabel.lineBreakMode = .byTruncatingTail
        navigationItem.titleView = titleView
    }
    
    private func createContentView() {
        if model.isSupportPreview == true {
            createSupportView()
            startDownload()
        } else {
            createNoSupportView()
        }
    }
    
    private func createSupportView() {
        let contentView = DownloadContentView(frame: view.bounds, fileExtension: model.fileExtension)
        contentView.delegate = self
        view.addSubview(contentView)
        downloadView = contentView
    }
    
    private func createNoSupportView() {
        let contentView = DownloadNoSupportView(frame: view.bounds)
        contentView.delegate = self
        view.addSubview(contentView)
        noSupportView = contentView
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(opw_didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(opw_didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateConstraintsIfNeed), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    private func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func updateConstraintsIfNeed() {
        if let downloadView = downloadView {
            downloadView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        if let noSupportView = noSupportView {
            noSupportView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    @objc private func opw_didEnterBackground() {
        downloadQueue.pauseAll()
    }
    
    @objc private func opw_didBecomeActive() {
        downloadQueue.resumeAll()
    }
    
    private func startDownload() {
        guard let response = model.response,
              let request = model.request,
              let cookieStore = model.cookieStore else {
            return
        }
        guard let download = OPHTTPDownload(response: response, request: request, cookieStore: cookieStore) else {
            return
        }
        self.downloadQueue.enqueue(download)
    }
    
    private func cancelDownload() {
        if downloadQueue.isEmpty {
            return
        }
        downloadQueue.cancelAll()
    }
}

extension DownloadPercentController: OPDownloadQueueDelegate {
    func downloadQueue(_ queue: OPDownloadQueue, didStartDownload download: OPDownload) {
        downloadView?.totalBytes = download.totalBytes
        noSupportView?.totalBytes = download.totalBytes
        self.didStartDownload?(model)
    }
    
    func downloadQueue(_ queue: OPDownloadQueue, didDownloadBytes bytes: Int64, totalBytes: Int64?) {
//        Self.logger.debug("OPWDownload didDownloadBytes \(bytes) - \(totalBytes ?? -1)")
        downloadView?.downloadedBytes = bytes
        noSupportView?.downloadedBytes = bytes
    }
    
    func downloadQueue(_ queue: OPDownloadQueue, download: OPDownload, didFinishDownloadingTo location: String) {
//        Self.logger.debug("OPWDownload didFinishDownloadingTo \(location)")
        model.localPath = location
        WebDownloadStorage.set(model: model)
    }
    
    func downloadQueue(_ queue: OPDownloadQueue, didComplete error: Error?) {
        DispatchQueue.main.async {
            let isPreview = self.model.isSupportPreview == true
            self.downloadView?.didCompleteWithError(error)
            self.noSupportView?.didCompleteWithError(error)
            self.model.totalBytes = isPreview ? self.downloadView?.totalBytes : self.noSupportView?.totalBytes
            self.didComplete?(error, self.model)
            if error == nil {
                if isPreview {
                    Navigator.shared.pop(from: self, animated: false) { [weak self] in // user:global
                        guard let self = self else {
                            return
                        }
                        self.showDrivePreview?(self.model)
                    }
                } else {
                    self.showActivityVC?(self.model, self.noSupportView)
                }
            }
        }
    }
}

extension DownloadPercentController: DownloadPercentHandleProtocol {
    func didClickOpenDrivePreview() {
        Self.logger.info("OPWDownload didClickOpenDrivePreview")
    }
    
    func didClickCancel() {
        Self.logger.info("OPWDownload didClickCancel support_preview: \(model.isSupportPreview == true), queue.empty: \(downloadQueue.isEmpty)")
        cancelDownload()
    }
    
    func didClickDownload() {
        Self.logger.info("OPWDownload didClickDownload support_preview: \(model.isSupportPreview == true), queue.empty: \(downloadQueue.isEmpty)")
        cancelDownload()
        startDownload()
    }
    
    func didClickOpenInOthersApps(view: UIView?) {
        if OPDownload.isEncryptedEnable() {
            Self.logger.info("OPWDownload didClickOpenInOthersApps encrypt toast")
            UDToast.showFailure(with: BundleI18n.WebBrowser.Mail_FileCantShareOrOpenViaThirdPartyApp_Toast, on: self.view)
        } else {
            Self.logger.info("OPWDownload didClickOpenInOthersApps showActivityVC")
            self.showActivityVC?(model, view ?? noSupportView)
        }
    }
}
