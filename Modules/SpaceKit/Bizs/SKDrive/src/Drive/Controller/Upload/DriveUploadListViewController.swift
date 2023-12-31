//
//  DriveUploadListViewController.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/29.
//
// swiftlint:disable file_length init_color_with_token

import UIKit
import EENavigator
import SKCommon
import SKFoundation
import SKResource
import SKUIKit
import UniverseDesignToast
import UniverseDesignColor
import RxSwift
import UniverseDesignEmpty
import UniverseDesignIcon
import UniverseDesignDialog
import SpaceInterface

/// 上传错误码
/// 注意：后端错误码经 Rust 回调会加 2000;后端接口错误码定义 - https://bytedance.feishu.cn/docs/tSrvZGGj5N8WUT08s0vLlg#gDu7lo
enum FileUploaderErrorCode: Int {
    case pathError = 1001
    case mountPointIsDeleted = 90_003_041  // 挂载点（父文件夹、父节点）被删除(90001041)
    case mountPointCountLimited = 90_003_042  // 节点数量达到5000个（需要和后端确认），主要是explorer使用(90001042)
    case fileSizeLimited = 90_003_043  // 文件大小超过上限(90001043)
    case mountPointNotExist = 90_003_044 // 挂载点不存在（90001044，包括文件夹不存在，doc、sheet 不存在）
    case uploadStorageLimited = 13_001 // 上传存储空间不足(11001)
    case userStorageLimited = 90_003_061 // 用户存储空间不足(90001061)
    case mountNodeOutOfSiblingNum = 233_527_007 // 云空间目录下挂载数量超过限制(233525007)
    case forbidden = 2004

    /// 失败是否可重试
    var canRetry: Bool {
        switch self {
        case .pathError, .mountPointIsDeleted, .mountPointNotExist,
             .uploadStorageLimited, .fileSizeLimited,
             .mountNodeOutOfSiblingNum, .forbidden:
            return false
        case .mountPointCountLimited, .userStorageLimited:
            return true
        }
    }
}

/// 文件上传列表

class DriveUploadListViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: - data
    @ThreadSafe private var datas: [DriveUploadFile] = [] {
        didSet {
            DispatchQueue.main.async {
                self.setCancelItemEnabled(!self.datas.isEmpty)
                if self.datas.isEmpty {
                    self.showUploadCompletedPlaceholder()
                }
            }
        }
    }
    private var folderToken: String
    private let scene: DriveUploadScene
    private let params: [String: Any]
    // wiki的上传列表使用wiki的图标
    private var isInWiki: Bool {
        return scene == .wiki
    }
    private var bag = DisposeBag()

    // MARK: - UI
    private var cancelItem: SKBarButtonItem!
    private var closeItem: SKBarButtonItem!
    private let uploadCompletedView: UDEmpty = {
        let empty = UDEmpty(config: .init(title: .init(titleText: ""),
                                          description: .init(descriptionText: BundleI18n.SKResource.Drive_Drive_AllUploadCompleted),
                                          imageSize: 100,
                                          type: .noContent,
                                          labelHandler: nil,
                                          primaryButtonConfig: nil,
                                          secondaryButtonConfig: nil))
        return empty
    }()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let bottomSperator: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.lineDividerDefault
        return view
    }()

    init(folderToken: String, scene: DriveUploadScene, params: [String: Any] = [:]) {
        self.folderToken = folderToken
        self.scene = scene
        self.params = params
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()

        doInitUI()
        setupTableView()
        doInitData()

        // Drive数据埋点：进入上传状态列表页
        DriveStatistic.clientFileUpload(fileId: "", subFileType: "", action: DriveStatisticAction.showUploadLayer)
        DriveStatistic.reportEvent(DocsTracker.EventType.driveFileUploadProgressView, fileId: nil, fileType: nil, params: params)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        // Drive数据埋点：退出上传状态列表页
        DriveStatistic.clientFileUpload(fileId: "", subFileType: "", action: DriveStatisticAction.hideUploadLayer)
    }
    // MARK: - 初始化
    func doInitUI() {
        title = BundleI18n.SKResource.Drive_Drive_UploadList
        view.backgroundColor = UDColor.bgBody
        self.tableView.separatorStyle = .none
        setupNavigatonBar()
    }

    func setupNavigatonBar() {
        cancelItem = SKBarButtonItem(title: BundleI18n.SKResource.Drive_Drive_CancelUpload,
                                     style: .plain,
                                     target: self,
                                     action: #selector(rightItemClicked))
        cancelItem.id = .cancel
        cancelItem.foregroundColorMapping = SKBarButton.primaryColorMapping
        cancelItem.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 16)], for: .normal)
        closeItem = SKBarButtonItem(image: UDIcon.closeSmallOutlined, style: .plain, target: self, action: #selector(closeItemClicked))
        closeItem.id = .close
        navigationBar.leadingBarButtonItem = closeItem
        navigationBar.trailingBarButtonItem = cancelItem
    }

    func doInitData() {
        DriveUploadCallbackService.shared.addObserver(self)
        SpaceRustRouter.shared.uploadList(mountNodePoint: self.folderToken, scene: scene)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] datas in
                guard let self = self else { return }
                self.datas = datas
                DocsLogger.driveInfo("doInitData", extraInfo: ["count": self.datas.count,
                                                          "folderToken": DocsTracker.encrypt(id: self.folderToken)])
                self.tableView.reloadData()
            }).disposed(by: self.bag)
    }

    func setupTableView() {
        tableView.backgroundColor = UDColor.bgBody
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(DriveUploadTableCell.self)

        view.addSubview(bottomSperator)
        bottomSperator.snp.makeConstraints { (make) in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.equalTo(navigationBar.snp.left)
            make.right.equalTo(navigationBar.snp.right)
            make.height.equalTo(0.5)
        }
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(bottomSperator.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }
    }

    // MARK: - Action handler
    @objc
    func rightItemClicked() {
        /// Drive数据埋点：批量取消
        DriveStatistic.clientFileUpload(fileId: "", subFileType: "", action: DriveStatisticAction.cancelUploadBatch)
        DriveStatistic.reportClickEvent(DocsTracker.EventType.driveFileUploadProgressClick,
                                        clickEventType: DriveStatistic.DriveFileUploadViewClickEventType.cancel,
                                        fileId: nil,
                                        fileType: nil,
                                        params: params)
        showConfirmAlert()
    }

    @objc
    func closeItemClicked() {
        self.dismiss(animated: true)
    }

    func cancelAllUploading() {
        DocsLogger.driveInfo("cancelAllUploading")

        var indexs: [Int] = []
        for index in 0..<datas.count {
            indexs.append(index)
        }
        DispatchQueue.global(qos: .userInteractive).async {
            self.cancelUploading(indexs: indexs)
        }
    }

    // MARK: 需要在子线程调用Rust 同步接口
    func cancelUploading(indexs: [Int]) {
        // 先把需要删除的 Key 和 文件路径保存
        let keysToDelete = indexs.compactMap { index -> String? in
            guard index >= 0, index < datas.count else { return nil }
            return datas[index].key
        }
        let pathsToDelete = getDeleteFilePath(at: indexs)

        // 删除 tableview 的 row 同时会把 datas 数据删除
        deleteRows(at: indexs)

        // 通知 Rust 取消任务
        Observable.from(keysToDelete).flatMap { key -> Observable<(Int, Int)> in
            let cancleOb = SpaceRustRouter.shared.cancelUpload(key: key)
            let deleteOb = SpaceRustRouter.shared.deleteUploadResource(key: key)
            return Observable.zip(cancleOb, deleteOb)
        }.subscribe(onCompleted: { [weak self] in
            // 取消任务结束后才能删除去删除本地文件，否则可能会遇到上传中本地文件被删情况
            guard let self = self else { return }
            self.deleteCancelUploadCache(paths: pathsToDelete)
        }).disposed(by: bag)
    }

    func removeFile(key: String, delay: Double) {
        DocsLogger.driveInfo("removeFile", extraInfo: ["key": key,
                                                  "delay": delay])

        DispatchQueue.main.asyncAfter(deadline: (.now() + delay), execute: {
            guard let index = self.indexOfFile(key: key) else {
                DocsLogger.driveInfo("indexOfFile(\(key)) is nil")
                return
            }
            self.deleteRows(at: [index])
        })
    }

    func deleteCancelUploadCache(paths: [String]) {
        for path in paths {
            do {
                let path = try SKFilePath.parse(path: path)
                try path.removeItem()
                DocsLogger.driveInfo("This file was deleted! --- path: \(path)")
            } catch {
                DocsLogger.error("remove path from rust failed", error: error)
            }
        }
    }

    private func getDeleteFilePath(at indexs: [Int]) -> [String] {
        var paths: [String] = []
        for index in indexs {
            if index < 0 || index >= datas.count {
                DocsLogger.driveInfo("deleteRows: index out of bounds!")
                return paths
            }
            let path = datas[index].path
            if !path.isEmpty {
                paths.append(path)
            } else {
                DocsLogger.driveInfo("path is empty, path: \(path)")
                continue
            }
        }
        return paths
    }
    // MARK: - UI handler
    func reloadCell(data: DriveUploadFile, at index: Int) {
        guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? DriveUploadTableCell else {
            DocsLogger.error("cell is not DriveUploadTableCell")
            return
        }
        DocsLogger.driveInfo("reloadCell", extraInfo: ["index": index, "key": data.key, "status": data.status])
        cell.render(presenter: data, isInWiki: isInWiki)
    }

    func reloadCell(data: DriveUploadFile, of key: String) {
        guard let index = indexOfFile(key: key) else {
            DocsLogger.driveInfo("index is nil")
            return
        }
        guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? DriveUploadTableCell else {
            DocsLogger.driveInfo("cell is not DriveUploadTableCell")
            return
        }
        DocsLogger.driveInfo("reloadCell", extraInfo: ["key": key, "status": data.status])
        cell.render(presenter: data, isInWiki: isInWiki)
    }

    func showConfirmAlert() {
        DocsLogger.driveInfo("showConfirmAlert")
        DriveStatistic.reportEvent(DocsTracker.EventType.driveStopUploadConfirmView, fileId: nil, fileType: nil)
        let dialog = UDDialog()
        dialog.setContent(text: BundleI18n.SKResource.Drive_Drive_StopAllNonUploadProcesses)
        dialog.addSecondaryButton(text: BundleI18n.SKResource.Drive_Drive_Cancel, dismissCompletion: {
            // Drive数据埋点：取消上传的取消
            DriveStatistic.clientFileUpload(fileId: "",
                                            subFileType: "",
                                            action: DriveStatisticAction.cancelUploadCancel)
            DriveStatistic.reportClickEvent(DocsTracker.EventType.driveStopUploadConfirmClick,
                                            clickEventType: DriveStatistic.DriveFileUploadViewClickEventType.cancel,
                                            fileId: nil, fileType: nil)
            DocsLogger.driveInfo("user cancelled")
        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.Drive_Drive_Confirm, dismissCompletion: { [weak self] in
            self?.cancelAllUploading()
            // Drive数据埋点：取消上传的确认
            DriveStatistic.clientFileUpload(fileId: "",
                                            subFileType: "",
                                            action: DriveStatisticAction.cancelUploadConfirm)
            DriveStatistic.reportClickEvent(DocsTracker.EventType.driveStopUploadConfirmClick,
                                            clickEventType: DriveStatistic.DriveFileUploadViewClickEventType.confirm,
                                            fileId: nil, fileType: nil)
        })
        Navigator.shared.present(dialog, from: self)
    }

    func showUploadCompletedPlaceholder() {
        view.addSubview(uploadCompletedView)
        view.bringSubviewToFront(uploadCompletedView)
        uploadCompletedView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
    }

    func setCancelItemEnabled(_ isEnabled: Bool) {
        cancelItem.isEnabled = isEnabled
        navigationBar.trailingBarButtonItems = [cancelItem]
    }

    func deleteRows(at indexs: [Int], with rowAnimation: UITableView.RowAnimation = .automatic) {
        DispatchQueue.main.async {
            // array的remove需从后至前，因此对原有indexs进行降序排序
            let tempIndexs = indexs.sorted(by: { $0 > $1 })

            var indexPaths: [IndexPath] = []
            for index in tempIndexs {
                guard index >= 0, index < self.datas.count else {
                    DocsLogger.error("deleteRows: index out of bounds!")
                    return
                }
                self.datas.remove(at: index)
                indexPaths.append(IndexPath(row: index, section: 0))
            }
            self.tableView.setEditing(false, animated: true)
            self.tableView.deleteRows(at: indexPaths, with: rowAnimation)
        }
    }

    // MARK: - Helper
    func indexOfFile(key: String) -> Int? {
        for index in 0..<datas.count where datas[index].key == key {
            return index
        }
        return nil
    }
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: DriveUploadTableCell = tableView.dequeueReusableCell(for: indexPath)
        cell.render(presenter: datas[indexPath.row], isInWiki: isInWiki)
        cell.delegate = self
        return cell
    }
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return DriveUploadTableCell.cellHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: false)
    }

    // ref: https://stackoverflow.com/questions/27740884/uitableviewrowaction-title-as-image-icon-instead-of-text/32735211
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let frame = tableView.rectForRow(at: indexPath)
        let bgViewWidth: CGFloat = 100
        let imageWidth: CGFloat = 30

        let bgView = UIView(frame: CGRect(x: 0, y: 0, width: bgViewWidth, height: frame.height))
        bgView.backgroundColor = UDColor.functionDangerContentDefault

        let deleteImageView = UIImageView(frame: CGRect(x: 20,
                                                        y: (frame.size.height - imageWidth) / 2,
                                                        width: imageWidth,
                                                        height: imageWidth))
        deleteImageView.image = BundleResources.SKResource.Space.FileList.listcell_delete
        bgView.addSubview(deleteImageView)

        var imgSize: CGSize = frame.size
        if imgSize.width == 0 { imgSize.width = 1 }
        if imgSize.height == 0 { imgSize.height = 1 }
        UIGraphicsBeginImageContextWithOptions(imgSize, false, 0.0)
        let context = UIGraphicsGetCurrentContext()
        bgView.layer.render(in: context!)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()

        let deleteAction = UITableViewRowAction(style: .destructive, title: "   ") {(_, indexPath) in
            // Drive数据埋点：取消上传-单个取消
            DriveStatistic.clientFileUpload(fileId: "",
                                            subFileType: "",
                                            action: DriveStatisticAction.cancelUpload)
            DispatchQueue.global(qos: .userInteractive).async {
                self.cancelUploading(indexs: [indexPath.row])
            }
        }
        deleteAction.backgroundColor = UIColor(patternImage: newImage)

        return [deleteAction]
    }
}

extension DriveUploadListViewController: DriveUploadCallback {

    func updateProgress(context: DriveUploadContext) {
        let key = context.key
        guard let index = indexOfFile(key: key) else {
            DocsLogger.driveInfo("indexOfFile(\(key)) is nil")
            return
        }

        var data = DriveUploadFile()
        data.key = key
        data.fileName = datas[index].fileName
        data.status = Int32(context.status.rawValue)
        data.bytesTransferred = String(context.bytesTransferred)
        data.bytesTotal = String(context.bytesTotal)
        data.path = context.filePath
        data.mountNodePoint = context.mountNodePoint

        datas[index] = data

        DispatchQueue.main.async {
            self.reloadCell(data: data, of: key)

            if data.uploadStatus == .completed {
                self.removeFile(key: key, delay: 1)
            }
        }
    }

    func onFailed(key: String, mountPoint: String, scene: DriveUploadScene, errorCode: Int, fileSize: Int64) {
        guard let index = indexOfFile(key: key) else {
            DocsLogger.driveInfo("indexOfFile(\(key)) is nil")
            return
        }

        let originalData = datas[index]

        var data = DriveUploadFile()
        data.key = originalData.key
        data.fileName = originalData.fileName
        data.status = Int32(DriveUploadCallbackStatus.failed.rawValue)
        data.bytesTransferred = originalData.bytesTransferred
        data.bytesTotal = originalData.bytesTotal
        data.path = originalData.path
        data.mountNodePoint = originalData.mountNodePoint
        data.errorCode = "\(errorCode)"

        datas[index] = data

        DocsLogger.driveInfo("uploadFaield", extraInfo: ["key": key,
                                                    "errorCode": errorCode,
                                                    "index": index])

        DispatchQueue.main.async {
            self.reloadCell(data: data, of: key)
        }

        if errorCode == FileUploaderErrorCode.pathError.rawValue {
            DispatchQueue.main.async {
                UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_FileIsNotExist, on: self.view.window ?? self.view)
            }
        } else if errorCode == DriveFileInfoErrorCode.auditFailureInUploadError.rawValue {
            DispatchQueue.main.async {
                /// 从列表页删除审核违规的文件
                self.removeFile(key: key, delay: 0)
            }
        } else {
            DocsLogger.driveInfo("onFailed, key: \(key), errorCode: \(errorCode)")
        }
    }
}

extension DriveUploadListViewController: DriveUploadTableCellDelegate {
    func driveUploadTableCell(_ cell: DriveUploadTableCell, didClick retryButton: UIButton) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            DocsLogger.error("indexPath is nil")
            return
        }

        let index = indexPath.row
        let originalData = datas[index]

        var data = DriveUploadFile()
        data.key = originalData.key
        data.fileName = originalData.fileName
        data.status = Int32(DriveUploadCallbackStatus.inflight.rawValue)
        data.bytesTransferred = originalData.bytesTransferred
        data.bytesTotal = originalData.bytesTotal
        data.path = originalData.path
        data.mountNodePoint = originalData.mountNodePoint

        datas[index] = data

        DocsLogger.driveInfo("driveUploadTableCell retryButton clicked", extraInfo: ["index": index, "key": data.key])

        self.reloadCell(data: data, at: index)

        // Drive数据埋点：重新上传
        DriveStatistic.clientFileUpload(fileId: data.key,
                                        subFileType: (data.fileName as NSString).pathExtension,
                                        action: DriveStatisticAction.reUpload)
        DriveStatistic.reportClickEvent(DocsTracker.EventType.driveFileUploadProgressClick,
                                        clickEventType: DriveStatistic.DriveFileUploadViewClickEventType.retry,
                                        fileId: nil, fileType: nil,
                                        params: params)

        let errorResult: Int = -1
        SpaceRustRouter.shared.resumeUpload(key: data.key)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] result in
            guard let self = self else { return }
                if result == errorResult {
                    UDToast.showFailure(with: BundleI18n.SKResource.Drive_Drive_RetryUploadFailed,
                                           on: self.view.window ?? self.view)
                }
        }).disposed(by: bag)
    }
}
