//
//  SendAttachedFileLocalFileViewController.swift
//  Lark
//
//  Created by ChalrieSu on 02/02/2018.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import Photos
import AVKit
import LarkUIKit
import RxSwift
import LarkModel
import LKCommonsLogging
import LarkExtensions
import UniverseDesignToast
import LarkSDKInterface
import LarkMessengerInterface
import LarkAccountInterface
import WebBrowser
import LarkKeyCommandKit
import SuiteAppConfig
import LarkFeatureGating
import LarkCore
import LarkCache
import LarkFoundation
import EENavigator
import LarkContainer
import LarkSetting
import LarkStorage
import LarkEMM
import LarkSensitivityControl

private typealias Path = LarkSDKInterface.PathWrapper

/// 初始化用的一些参数，避免频繁改动外部调用的初始化方法
struct LocalFileViewControllerConfig {
    /// 文件选择总数限制
    var maxSelectedCount: Int = Int.max
    /// 单个文件大小限制
    var maxAttachedFileSize: Int = 1024 * 1024 * 1024 * 100
    /// 总文件大小限制
    var maxTotalAttachedFileSize: Int = Int.max
    /// 附加额外需要一起读取的文件夹路径（默认只会读取对应User下面的文件）
    var extraFilePaths: [URL]?
    /// 请求发起场景
    var requestFrom: LocalFileBody.RequestFrom = .other
    /// 是否展示系统相册中的视频
    var showSystemAlbumVideo: Bool = true
    /// VC的title
    var title: String?
    /// 底部发送按钮title
    var sendButtonTitle: String?
}

/// 检测某个文件是否可选中的结果
enum AttachFileSelectedableCheckReuslt: Equatable {
    /// 可选中
    case avaliable
    /// 单个文件大小限制
    case exceedSingleFileSizeLimit(Int)
    /// 总文件大小限制
    case exceedTotalFileSizeLimit(Int)
}

final class LocalFileViewController: BaseUIViewController,
                               UITableViewDelegate,
                               UITableViewDataSource,
                               SendAttachedFilePreviewViewControllerDelegate,
                               NavigationTitleViewDelagate,
                               FileMenuDelegate,
                               TableViewKeyboardHandlerDelegate {
    private static let logger = Logger.log(LocalFileViewController.self, category: "Module.IM.Message")
    private let configuration: LocalFileViewControllerConfig
    private let trackUtils: FileTrackUtil
    /// 所有可选择的文件，一个AggregateAttachedFiles表示一个section
    private var aggregateAttachedFiles: [AggregateAttachedFiles] = []
    /// 记录展开的section下标，默认展开第一个
    private var expandIndexes: IndexSet = [0]
    private var selectedFiles: [AttachedFile] = [] {
        didSet {
            panel.selectedTotalSize = selectedFiles.reduce(0, { (res, file) -> Int64 in
                return res + file.size
            })
            panel.selectedCount = selectedFiles.count
        }
    }
    private var selectedFileIDs: [String] { return selectedFiles.map { $0.id } }
    private var selectedFileSize: Int {
        return selectedFiles.reduce(0, { (res, file) -> Int in
            return res + Int(file.size)
        })
    }
    private let localFileTableView = UITableView()
    private let panel = BottomConfirmPanel()
    let fileMenuView: FileMenuView
    let titleView = NavigationTitleView()
    private let disposeBag = DisposeBag()
    private let appConfigService: AppConfigService

    // keyboard
    private var keyboardHandler: TableViewKeyboardHandler?
    override func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + (keyboardHandler?.baseSelectiveKeyBindings ?? []) + confirmKeyBinding
    }

    private var confirmKeyBinding: [KeyBindingWraper] {
        return !selectedFiles.isEmpty ? [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputReturn,
                modifierFlags: .command,
                discoverabilityTitle: BundleI18n.LarkFile.Lark_Legacy_Send
            )
            .binding { [weak self] in
                self?.sendSelectedAttachedFile()
            }
            .wraper
        ] : []
    }

    /// 文件选择完毕回调
    var finishChoosingLocalFileBlock: (([LocalAttachFile]) -> Void)?

    /// 文件选中回调
    var choosingLocalFileBlock: (([String]) -> Void)?

    private let userResolver: UserResolver
    init(config: LocalFileViewControllerConfig,
         appConfigService: AppConfigService,
         userResolver: UserResolver) {
        self.trackUtils = FileTrackUtil()
        self.configuration = config
        self.appConfigService = appConfigService
        self.userResolver = userResolver

        if let title = configuration.title {
            titleView.titleText = title
        } else {
            titleView.titleText = BundleI18n.LarkFile.Lark_Message_File_defTitle()
        }
        fileMenuView = .init(fileMenu: [titleView.titleText, BundleI18n.LarkFile.Lark_Message_File_PhoneStorage])

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.ud.bgBody
        titleView.delegate = self
        self.navigationItem.titleView = titleView
        addCancelItem()

        // 搜索沙盒中的文件
        var paths: [URL] = []

        let downloadPath = URL(fileURLWithPath: fileDownloadCache(userResolver.userID).rootPath)
        paths.append(downloadPath)

        // 允许搜寻指定目录
        if let extraPaths = configuration.extraFilePaths, !extraPaths.isEmpty {
            paths.append(contentsOf: extraPaths)
        }
        aggregateAttachedFiles = SendAttachedFileDataCenter.fetchFilesFromSandBox(directorys: paths)

        if configuration.showSystemAlbumVideo {
            // 搜索相册中的视频
            let fetchVideos = {
                DispatchQueue.global().async {
                    let options = PHFetchOptions()
                    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                    if let fetchResult = try? AlbumEntry.fetchAssets(forToken: FileToken.fetchAssets.token, withMediaType: .video, options: options) {
                        let albumAggregateFiles = AlbumAggregateFiles(fetchResult: fetchResult)
                        DispatchQueue.main.async {
                            if albumAggregateFiles.filesCount > 0 {
                                self.aggregateAttachedFiles.insert(albumAggregateFiles, at: 0)
                                self.localFileTableView.reloadData()
                            }
                        }
                    }
                }
            }

            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized:
                fetchVideos()
            #if canImport(WidgetKit)
            case .limited:
                fetchVideos()
            #endif
            case .denied, .restricted:
                break
            case .notDetermined:
                try? AlbumEntry.requestAuthorization(forToken: FileToken.requestAuthorization.token) { (status) in
                    if status == .authorized {
                        fetchVideos()
                    }
                }
            @unknown default:
                break
            }
        }

        view.addSubview(panel)
        view.addSubview(localFileTableView)
        view.addSubview(fileMenuView)

        fileMenuView.isHidden = true
        fileMenuView.delegate = self

        fileMenuView.snp.makeConstraints { (make) in
            make.top.equalTo(self.viewTopConstraint)
            make.leading.bottom.trailing.equalToSuperview()
        }

        localFileTableView.delegate = self
        localFileTableView.dataSource = self
        localFileTableView.lu.register(cellSelf: SendAttachedFileTableViewCell.self)
        localFileTableView.separatorStyle = .none
        localFileTableView.backgroundColor = UIColor.ud.bgBody
        localFileTableView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.bottom.equalTo(panel.snp.top)
        }

        // tableview keyboard
        keyboardHandler = TableViewKeyboardHandler()
        keyboardHandler?.delegate = self

        panel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(viewBottomConstraint).offset(-48)
        }
        // 显示选中的文件
        panel.leftButtonClickedBlock = { [weak self] _ in
            self?.showSendAttachedFilePreviewViewController()
        }
        // 发送选中的文件
        panel.rightButtonClickedBlock = { [weak self] _ in
            self?.sendSelectedAttachedFile()
        }
        configuration.sendButtonTitle.flatMap { panel.sendTitle = $0 }
    }

    /// 预览选中的文件
    private func showSendAttachedFilePreviewViewController() {
        let previewVC = SendAttachedFilePreviewViewController(selectedAttachedFiles: selectedFiles)
        previewVC.delegate = self
        navigationController?.pushViewController(previewVC, animated: true)
    }

    //选中文件,对选中的文件进行秒传接口预处理
    private func selectedAttachedFile() {
        guard !selectedFiles.isEmpty else { return }
        let filePath = selectedFiles.compactMap { (file) -> String? in
            if let albumFile = file as? AlbumFile {
                if Path.useLarkStorage {
                    let currentUserDirectory = fileDownloadCache(userResolver.userID).iso.rootPath
                    let outputPath = currentUserDirectory + "\(file.id.kf.md5)-\(file.name)"
                    return outputPath.absoluteString
                } else {
                    let currentUserDirectory = fileDownloadCache(userResolver.userID).rootPath
                    let outPutURL = URL(fileURLWithPath: currentUserDirectory + "/" + file.id.kf.md5 + "-" + file.name, isDirectory: false)
                    return outPutURL.path
                }
            } else if let file = file as? LocalFile {
                let outPutURL = URL(fileURLWithPath: file.filePath)
                return outPutURL.path
            }
            return nil
        }
        self.choosingLocalFileBlock?(filePath)
    }

    /// 发送选中的文件
    private func sendSelectedAttachedFile() {
        guard !selectedFiles.isEmpty else { return }

        trackUtils.trackAttachedFileSendButtonClicked(numberOfFiles: selectedFiles.count,
                                                      localNumberOfFiles: selectedFiles.count,
                                                      cloudDiskNumberOfFiles: 0,
                                                      totalFileSize: selectedFileSize)
        let observables = selectedFiles.compactMap { (file) -> Observable<LocalAttachFile>? in
            // 如果是相册视频，则需要导出到沙盒
            if let albumFile = file as? AlbumFile {
                let outPutURL: URL
                if Path.useLarkStorage {
                    let currentUserDirectory = fileDownloadCache(userResolver.userID).iso.rootPath
                    let outputPath = currentUserDirectory + "\(file.id.kf.md5)-\(file.name)"
                    outPutURL = outputPath.url
                } else {
                    let currentUserDirectory = fileDownloadCache(userResolver.userID).rootPath
                    outPutURL = URL(fileURLWithPath: currentUserDirectory + "/" + file.id.kf.md5 + "-" + file.name, isDirectory: false)
                }
                if Path(outPutURL.path).exists {
                    return Observable.create({ (observer) -> Disposable in
                        observer.onNext(LocalAttachFile(name: albumFile.name, fileURL: outPutURL, size: UInt(albumFile.size)))
                        return Disposables.create()
                    })
                } else {
                    return albumFile.export(to: outPutURL)
                        .do(onError: { (error) in
                            LocalFileViewController.logger.error("导出相册视频文件失败", additionalData: [albumFile.id: albumFile.asset.description], error: error)
                        })
                        .map { LocalAttachFile(name: albumFile.name, fileURL: $0, size: UInt(albumFile.size)) }
                        .catchErrorJustReturn(LocalAttachFile(name: "", fileURL: URL(fileURLWithPath: "")))
                }
            } else if let file = file as? LocalFile {
                return Observable.create { (observer) -> Disposable in
                    observer.onNext(LocalAttachFile(name: file.name, fileURL: URL(fileURLWithPath: file.filePath), size: UInt(file.size)))
                    observer.onCompleted()
                    return Disposables.create()
                }
            }
            return nil
        }
        let hud = UDToast.showLoading(with: BundleI18n.LarkFile.Lark_Legacy_Loading, on: view, disableUserInteraction: true)
        Observable.combineLatest(observables)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (attachedFiles) in
                self?.finishChoosingLocalFileBlock?(attachedFiles.filter { !$0.name.isEmpty })
                self?.navigationController?.dismiss(animated: true)
            }, onCompleted: {
                hud.remove()
            })
            .disposed(by: disposeBag)
    }

    /// 预览文件
    private func previewAttachFile(_ attachFile: AttachedFile) {
        let localFilePreviewController = LocalFilePreviewController(attachFile,
                                                                    appConfigService: self.appConfigService,
                                                                    userResolver: userResolver)
        self.navigationController?.pushViewController(localFilePreviewController, animated: true)
    }

    /// 检测该文件是否可被选中
    private func checkAttachFileSelectedable(_ attachFile: AttachedFile) -> AttachFileSelectedableCheckReuslt {

        let totalFileSize = selectedFileSize + Int(attachFile.size)
        // 总文件大小超出限制
        if totalFileSize >= configuration.maxTotalAttachedFileSize {
            return selectedFiles.isEmpty ? .exceedSingleFileSizeLimit(Int(attachFile.size)) : .exceedTotalFileSizeLimit(totalFileSize)
        }

        // 单个文件大小超出限制
        if attachFile.size >= configuration.maxAttachedFileSize {
            return .exceedSingleFileSizeLimit(Int(attachFile.size))
        }

        return .avaliable
    }

    /// 弹窗提示该文件不可被选中的原因
    private func showUnSelectedableAlert(reason: AttachFileSelectedableCheckReuslt, attachFile: AttachedFile) {
        switch reason {
        case .avaliable: break
        case .exceedSingleFileSizeLimit(let fileSize):
            let message = BundleI18n.LarkFile.Lark_File_ToastSingleFileSizeLimit(fileSizeToString(configuration.maxAttachedFileSize))
            self.showAlert(title: BundleI18n.LarkFile.Lark_Legacy_Hint, message: message)
            if self.configuration.requestFrom == .im {
                trackUtils.trackAttachedFileExceedLimit(fileSize: fileSize)
            }
        case .exceedTotalFileSizeLimit(let fileSize):
            let message = BundleI18n.LarkFile.Lark_File_ToastTotalFileSizeLimit(fileSizeToString(configuration.maxTotalAttachedFileSize))
            self.showAlert(title: BundleI18n.LarkFile.Lark_Legacy_Hint, message: message)
            if self.configuration.requestFrom == .im {
                trackUtils.trackAttachedFileExceedLimit(fileSize: fileSize)
            }
        }
    }

    /// 将文件大小转换为字符串
    /// 当限制小于1GB时，以MB为单位表示，否则以GB为单位表示
    private func fileSizeToString(_ fileSize: Int) -> String {
        let megaByte: Int = 1024 * 1024
        let gigaByte = 1024 * megaByte
        if fileSize < gigaByte {
            let fileSizeInMB = Double(fileSize) / Double(megaByte)
            return String(format: "%.2fMB", fileSizeInMB)
        } else {
            let fileSizeInGB = Double(fileSize) / Double(gigaByte)
            return String(format: "%.2fGB", fileSizeInGB)
        }
    }

    // MARK: - SendAttachedFilePreviewViewControllerDelegate
    func previewVC(_ vc: SendAttachedFilePreviewViewController, didTapSaveWith selectedAttachedFiles: [AttachedFile]) {
        selectedFiles = selectedAttachedFiles
        localFileTableView.reloadData()
        navigationController?.popViewController(animated: true)
    }

    // MARK: - TableViewKeyboardHandlerDelegate
    func tableViewKeyboardHandler(handlerToGetTable: TableViewKeyboardHandler) -> UITableView {
        return localFileTableView
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 52
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let aggregateFiles = aggregateAttachedFiles[section]

        let headerView = SendAggregatedAttachedFileHeaderView()
        headerView.setContent(name: aggregateFiles.displayName,
                              count: aggregateFiles.filesCount,
                              expand: expandIndexes.contains(section),
                              tapBlock: { [weak self, weak tableView] (_) in
                                guard let `self` = self else { return }
                                if self.expandIndexes.contains(section) {
                                    self.expandIndexes.remove(section)
                                } else {
                                    self.expandIndexes.insert(section)
                                }
                                UIView.performWithoutAnimation {
                                    tableView?.reloadSections([section], with: .none)
                                }
                              })
        return headerView
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard let cell = tableView.cellForRow(at: indexPath) as? SendAttachedFileTableViewCell else { return }

        tableView.deselectRow(at: indexPath, animated: false)
        let aggregateFile = aggregateAttachedFiles[indexPath.section]
        let attachFile = aggregateFile.fileAtIndex(indexPath.row)

        if selectedFileIDs.contains(attachFile.id) {
            selectedFiles.removeAttachedFile(attachFile)
        } else {
            let check = checkAttachFileSelectedable(attachFile)
            if check != .avaliable {
                showUnSelectedableAlert(reason: check, attachFile: attachFile)
                return
            }
            // 选择总数是否超出限制
            if selectedFiles.count + 1 > configuration.maxSelectedCount {
                self.showAlert(title: BundleI18n.LarkFile.Lark_Legacy_Hint, message: BundleI18n.LarkFile.Lark_Legacy_SendAttachedFileSelectedExceedMaxLimit(configuration.maxSelectedCount))
                return
            }
            selectedFiles.append(attachFile)
        }
        self.selectedAttachedFile()
        trackUtils.trackAttachedFileSelected(type: aggregateFile.displayName,
                                             isSelected: selectedFileIDs.contains(attachFile.id),
                                             isFromLocal: true)
        cell.setSelected(selectedFileIDs.contains(attachFile.id))
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID = String(describing: SendAttachedFileTableViewCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as? SendAttachedFileTableViewCell else { return UITableViewCell() }

        let aggregateFile = aggregateAttachedFiles[indexPath.section]
        let attachFile = aggregateFile.fileAtIndex(indexPath.row)
        cell.setContent(fileId: attachFile.id,
                        name: attachFile.name,
                        size: attachFile.size,
                        duration: attachFile.videoDuration,
                        isVideo: (attachFile.type == .albumVideo || attachFile.type == .localVideo),
                        isSelected: selectedFileIDs.contains(attachFile.id),
                        isLastRow: (aggregateFile.filesCount - 1) == indexPath.row,
                        iconButtonDidClick: { [weak self] (_) in
                            self?.previewAttachFile(attachFile)
                        })
        // 相册视频，需要获取首帧图
        if let albumFile = attachFile as? AlbumFile {
            try? AlbumEntry.requestImage(forToken: FileToken.requestImage.token,
                                         manager: PHCachingImageManager.default(),
                                         forAsset: albumFile.asset,
                                         targetSize: CGSize(width: 40, height: 40) * UIScreen.main.scale,
                                         contentMode: .aspectFill,
                                         options: nil,
                                         resultHandler: { (image, _) in
                if cell.fileId ?? "" == albumFile.asset.localIdentifier {
                    cell.setImage(image)
                    }
                })
        } else if let file = attachFile as? LocalFile {
            cell.setImage(file.previewImage())
        }
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return aggregateAttachedFiles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let aggregateFile = aggregateAttachedFiles[section]
        if expandIndexes.contains(section) {
            return aggregateFile.filesCount
        } else {
            return 0
        }
    }

    func onReturningFromFileMenu(selectedMenu: String?) {
        titleView.setArrowPresentation()
        fileMenuView.hideAnimation()

        if let menu = selectedMenu {
            if menu == BundleI18n.LarkFile.Lark_Message_File_PhoneStorage {
                /// 根据苹果官方对于UTI（Uniform Type Identifier）给出的定义，针对物理性质（public.item - 物理层次结构的基类型）和功能属性（public.content - 所有文档内容的基本类型）
                let documentTypes = ["public.item", "public.content"]
                let documentPicker = FileDocumentPickerViewController(documentTypes: documentTypes,
                                                                      in: .import,
                                                                      userResolver: userResolver)
                documentPicker.sendFileBlock = self.finishChoosingLocalFileBlock
                documentPicker.allowsMultipleSelection = false
                let from = WindowTopMostFrom(vc: self)
                dismiss(animated: false) {
                    self.userResolver.navigator.present(documentPicker, from: from, animated: true)
                }
            } else {
                titleView.titleText = menu
            }
        }
    }

    func onTitleViewClick() {
        if !titleView.isFolded {
            fileMenuView.showAnimation()
        } else {
            fileMenuView.hideAnimation()
        }
    }
}
