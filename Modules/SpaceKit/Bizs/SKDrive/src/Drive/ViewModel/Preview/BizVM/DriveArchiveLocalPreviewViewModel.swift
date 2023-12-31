//
//  DriveArchiveLocalPreviewViewModel.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2021/10/4.
//  


import Foundation
import SKCommon
import SKFoundation
import LibArchiveKit
import SpaceInterface
import RxSwift
import SKResource

class DriveArchiveLocalPreviewViewModel: DriveArchiveViewModelType {
    
    var fileUrl: SKFilePath
    var additionalStatisticParameters: [String: String]?
    var actionHandler: ((Action) -> Void)?
    var rootNodeName: String {
        return fileName
    }
    
    private let fileName: String
    private let previewFrom: DrivePreviewFrom
    private var archiveFile: LibArchiveFile?
    private var archiveEntries = [LibArchiveEntry]()
    private var unarchiveFolderName: String?
    private var unarchiveFolderUrl: URL?
    private var loadingTimer: Timer?
    private let renderQueue: DispatchQueue = DispatchQueue(label: "Drive.LocalPreview.Archive.ViewModel")
    private static let aboutToShowLoadingSecond = 0.5
    
    init(url: SKFilePath, fileName: String, previewFrom: DrivePreviewFrom?, additionalStatisticParameters: [String: String]?) {
        self.fileUrl = url
        self.fileName = SKFilePath.getFileNamePrefix(name: fileName)
        self.previewFrom = previewFrom ?? .unknown
        self.additionalStatisticParameters = additionalStatisticParameters
    }
    
    deinit {
        DocsLogger.driveInfo("DriveArchiveLocalPreviewViewModel Deinit")
    }
    
    func startPreview() {
        actionHandler?(.startLoading)
        renderQueue.async { [weak self] in
            guard let self = self else { return }
            do {
                try self.checkArchiveFileSize()
                self.archiveFile = try LibArchiveFile(path: self.fileUrl.pathString)
                self.archiveEntries = try self.archiveFile?.parseFileList() ?? []
                self.parseData()
            } catch {
                DispatchQueue.main.async {
                    self.actionHandler?(.endLoading)
                    self.actionHandler?(.failure(error))
                }
            }
        }
    }
    
    func didClick(node: DriveArchiveNode) {
        switch node.fileType {
        case .folder:
            guard let folderNode = node as? DriveArchiveFolderNode else {
                DocsLogger.error("Drive.Preview.Archive --- Failed to convert node to folderNode")
                return
            }
            actionHandler?(.pushFolderNode(folderNode))
        case .regularFile:
            guard let fileNode = node as? DriveArchiveFileNode else {
                DocsLogger.error("Drive.Preview.Archive --- Failed to convert node to fileNode")
                return
            }
            guard archiveFile?.isEncrypted == false else {
                showToast(message: BundleI18n.SKResource.CreationMobile_Docs_decompress_encrypted)
                return
            }
            startShowLoadingTimer()
            renderQueue.async {
                self.extractFile(node: fileNode)
            }
        }
        ///TODO: @zhangyuanping
        let bizParam = SpaceBizParameter(module: .drive,
                                         fileID: "",
                                         fileType: .file,
                                         driveType: "")
        var parmas: [String: Any] = ["click": "list_item", "target": "ccm_drive_page_view"]
        parmas.merge(other: bizParam.params)
        DocsTracker.newLog(event: DocsTracker.EventType.driveFileOpenClick.stringValue, parameters: parmas)
    }
    
    // 检查文件大小是否在支持范围内
    private func checkArchiveFileSize() throws {
        let currentSize = fileUrl.fileSize ?? 0
        if currentSize > DriveFeatureGate.localArchivePreviewMaxSize {
            throw DriveError.previewLocalArchiveTooLarge
        }
    }
    
    private func parseData() {
        let rootFolderNode = DriveArchiveFolderNode(name: fileName, parentNode: nil, childNodes: [])
        for entry in archiveEntries {
            // "a/b/c/" 会得出 ["a", "b", "c", ""]，需过滤掉空串的情况
            let pathArray = entry.path.components(separatedBy: "/").filter { !$0.isEmpty }
            var currentParent = rootFolderNode
            
            for (index, name) in pathArray.enumerated() {
                let entryType = (index == pathArray.count - 1) ? entry.type : .directory
                var node: DriveArchiveNode
                switch entryType {
                case .file:
                    node = DriveArchiveFileNode(name: name, parentNode: currentParent, fileSize: entry.size)
                case .directory:
                    node = DriveArchiveFolderNode(name: name, parentNode: currentParent, childNodes: [])
                }

                if !currentParent.childNodes.contains(node) {
                    // 当前节点不在父节点的子节点中，则添加进去
                    currentParent.childNodes.append(node)
                    if let node = node as? DriveArchiveFolderNode {
                        currentParent = node
                    }
                } else {
                    // 如果当前节点已经存在，取出作为下一次循环的父节点
                    if let node = currentParent.childNodes.first(where: { $0 == node }) as? DriveArchiveFolderNode {
                        currentParent = node
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.actionHandler?(.updateRootNode(rootFolderNode))
            self.actionHandler?(.endLoading)
        }
    }
    
    private func extractFile(node: DriveArchiveFileNode) {
        guard let folderUrl = unarchiveFolder else {
            showToast(message: BundleI18n.SKResource.Drive_Drive_LoadingFail)
            DocsLogger.error("获取解压目录失败")
            return
        }
        var entryPath = node.path
        // 移除路径前的斜杠
        if entryPath.hasPrefix("/") {
            entryPath.removeFirst()
        }
        let nodeFileUrl = folderUrl.appendingRelativePath(entryPath)
        guard checkIfShouldExtractFile(url: nodeFileUrl, fileSize: node.fileSize) else {
            previewFile(url: nodeFileUrl.pathURL)
            return
        }
        do {
            try archiveFile?.extract(entryPath: entryPath, toDir: folderUrl.pathURL)
            previewFile(url: nodeFileUrl.pathURL)
        } catch {
            if archiveFile?.format == .rar5 {
                // 目前无法知道 rar5 是否加密，解压会失败，此处针对 rar5 场景提供特殊文案: 暂不支持预览查看
                showToast(message: BundleI18n.SKResource.CreationMobile_Docs_PreviewFailedGeneral)
            } else {
                showToast(message: BundleI18n.SKResource.Drive_Drive_LoadingFail)
            }
            extractStatistic(isSuccess: false, url: nodeFileUrl.pathURL, errorMessage: "\(error.localizedDescription)")
        }
    }
    
    // 检查文件是否需要解压
    private func checkIfShouldExtractFile(url: SKFilePath, fileSize: UInt64) -> Bool {
        if url.exists {
            let currentSize = url.fileSize ?? 0
            DocsLogger.driveInfo("Exist file size is not correct")
            // 本地已有文件大小与实际不一致，则需要重新解压文件
            return currentSize != fileSize
        } else {
            return true
        }
    }
    
    // 解压目录，以文件的 md5 值作为目录名
    private lazy var unarchiveFolder: SKFilePath? = {
        let folderName = SKFilePath.md5(at: fileUrl.pathURL) ?? fileUrl.pathURL.lastPathComponent
        return tempDirectory?.appendingRelativePath(folderName)
    }()
    
    // 本地预览临时目录
    private lazy var tempDirectory: SKFilePath? = {
        let tempDirectory = DriveCacheService.archiveTmpURL
        if tempDirectory.createDirectoryIfNeeded() {
            return tempDirectory
        }
        return nil
    }()
    
    // 跳转预览压缩文件内的文件
    private func previewFile(url: URL) {
        DispatchQueue.main.async {
            self.stopLoadingTimer()
            let fileName = url.lastPathComponent
            let filetype = SKFilePath.getFileExtension(from: fileName)
            let fileId = url.absoluteString
            let file = DriveSDKLocalFileV2(fileName: fileName, fileType: filetype, fileURL: url, fileId: fileId, dependency: ArchiveFileLocalDependencyImpl())
            self.actionHandler?(.openFile([file]))
            self.actionHandler?(.endLoading)
            self.extractStatistic(isSuccess: true, url: url, errorMessage: "")
        }
    }
    
    private func showToast(message: String) {
        DispatchQueue.main.async {
            self.stopLoadingTimer()
            self.actionHandler?(.endLoading)
            self.actionHandler?(.showToast(message))
        }
    }
    
    private func stopLoadingTimer() {
        loadingTimer?.invalidate()
        loadingTimer = nil
    }

    // 延时展示 loading 页面，若在 500ms 内跳转预览压缩文件内容成功，则不会展示 loading 画面。
    private func startShowLoadingTimer() {
        let timer = Timer(timeInterval: Self.aboutToShowLoadingSecond, repeats: false) { [weak self] _ in
            self?.actionHandler?(.startLoading)
        }
        RunLoop.main.add(timer, forMode: .common)
        loadingTimer = timer
    }
    
    // 解压技术埋点
    private func extractStatistic(isSuccess: Bool, url: URL, errorMessage: String) {
        let archiveType = archiveFile?.format.description ?? "unknown"
        let fileName = url.lastPathComponent
        let fileType = SKFilePath.getFileExtension(from: fileName) ?? "unknown"
        let isEncrypted = archiveFile?.isEncrypted ?? false
        DriveStatistic.extractArchive(isSuccess: isSuccess, archiveType: archiveType, fileType: fileType,
                                      isEncrypted: isEncrypted, errorMessage: errorMessage)
    }
}


// MARK: - 压缩文件内，跳转本地文件预览 ArchiveFileLocalDependencyImpl

struct ArchiveFileLocalDependencyImpl: DriveSDKDependency {
    let more = LocalMoreDependencyImpl()
    let action = ActionDependencyImpl()
    var actionDependency: DriveSDKActionDependency {
        return action
    }
    var moreDependency: DriveSDKMoreDependency {
        return more
    }
}

struct LocalMoreDependencyImpl: DriveSDKMoreDependency {
    var moreMenuVisable: Observable<Bool> {
        return .just(false)
    }
    var moreMenuEnable: Observable<Bool> {
        return .just(false)
    }
    var actions: [DriveSDKMoreAction] {
        return []
    }
}

struct ActionDependencyImpl: DriveSDKActionDependency {
    var uiActionSignal: RxSwift.Observable<SpaceInterface.DriveSDKUIAction> {
        return .never()
    }
    private var closeSubject = PublishSubject<Void>()
    private var stopSubject = PublishSubject<Reason>()
    var closePreviewSignal: Observable<Void> {
        return .never()
    }
    var stopPreviewSignal: Observable<Reason> {
        return .never()
    }
}

extension ArchiveFormat {
    var description: String {
        switch self {
        case .zip: return "zip"
        case .rar4: return "rar4"
        case .rar5: return "rar5"
        case .tar, .tar_ustar: return "tar"
        case .archive_7z: return "7z"
        case .xar: return "xar"
        case .unknown: return "unknown"
        @unknown default: return "unknown"
        }
    }
}
