//
//  LocalFileUnzipTestController.swift
//  SKCommon
//
//  Created by chensi(陈思) on 2021/11/17.
//
#if BETA || ALPHA || DEBUG
import UIKit
import SnapKit
import SKResource
import Foundation
import SKFoundation
import EENavigator
import UniverseDesignToast
import SpaceInterface
import LibArchiveKit
import SKInfra

extension DriveSDKLocalFileV2 {
    fileprivate var unzipPath: SKFilePath {
        return SKFilePath.driveLibraryDir
            .appendingRelativePath("localtest")
            .appendingRelativePath("archive")
            .appendingRelativePath("output")
            .appendingRelativePath("\(fileName)")
    }
}

private class _Item {
    enum State {
        case ready, unzipped, failed
        var title: String {
            switch self {
            case .ready: return "待解压"
            case .unzipped: return "已解压"
            case .failed: return "解压失败"
            }
        }
    }
    let file: DriveSDKLocalFileV2
    var state = State.ready
    /// 统一存储文件路径
    let filePath: SKFilePath
    init(_ file: DriveSDKLocalFileV2, filePath: SKFilePath) {
        self.file = file
        self.filePath = filePath
        let isExist = file.unzipPath.exists
        state = isExist ? .unzipped : .ready
    }
}

/// 本地压缩文件解压测试界面
class LocalFileUnzipTestController: UIViewController {
    
    private var fileList: [_Item] = []
    
    /// 文件导入沙盒的缓存目录
    private static var iCloudFileCachePath: SKFilePath {
        let path = SKFilePath.driveLibraryDir
                                    .appendingRelativePath("localtest")
                                    .appendingRelativePath("archive")
                                    .appendingRelativePath("source")
        path.createDirectoryIfNeeded()
        return path
    }
    
    private static let uploadQueue = DispatchQueue(label: "drive.localtest")
    
    private lazy var tableview: UITableView = {
        let tbv = UITableView(frame: .zero, style: .plain)
        tbv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tbv.delegate = self
        tbv.dataSource = self
        return tbv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateData()
        setupUI()
    }
    
    private func setupUI() {
        title = "本地文件解压测试"
        navigationItem.leftBarButtonItem = .init(title: "back", style: .plain, target: self, action: #selector(onBackTap))
        let rbbi = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAddTap))
        navigationItem.rightBarButtonItem = rbbi
        view.backgroundColor = .white
        
        view.addSubview(tableview)
        tableview.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    @objc
    private func onBackTap() {
        dismiss(animated: true)
    }
    
    @objc
    private func onAddTap() {
        let pickerVc = _PickerController(sourceViewController: self) { [weak self] succ in
            if succ {
                DispatchQueue.main.async {
                    self?.updateData()
                    self?.tableview.reloadData()
                }
            }
        }
        present(pickerVc, animated: false)
    }
    
    private func updateData() {
        var files: [_Item] = []
        do {
            let path = Self.iCloudFileCachePath
            let allFileURLs = try path.contentsOfDirectory().compactMap({ pa in
                let path = Self.iCloudFileCachePath.appendingRelativePath(pa)
                return (path.pathURL, path)
            })
            for (fileURL, path) in allFileURLs {
                let fileName = fileURL.lastPathComponent
                let fileType = SKFilePath.getFileExtension(from: fileName)
                let fileID = fileURL.absoluteString
                let file = DriveSDKLocalFileV2(fileName: fileName,
                                               fileType: fileType,
                                               fileURL: fileURL,
                                               fileId: fileID,
                                               dependency: TestLocalDependencyImpl())
                files.append(_Item(file, filePath: path))
            }
            fileList = files
            DocsLogger.debug("[SKFilePath] fileList: \(fileList)")
        } catch {
            DocsLogger.error("[SKFilePath] failed: \(error)")
        }
    }
    
    /// 保存iCloud文件到本地沙盒
    fileprivate static func saveICouldFileToLocal(urls: [URL], complete: @escaping () -> Void) -> Bool {
        let urlsPath = urls.map { url in
            SKFilePath(absPath: url.path)
        }
        let isValid = !urlsPath.contains { (url) -> Bool in
            guard url.isFile() else {
                // 含有文件夹
                return true
            }
            guard let size = url.sizeExt() else {
                // 含有取不到大小（通常为文件夹）的文件
                return true
            }
            // 含有大小为0的文件
            return size == 0
        }
        uploadQueue.async {
            guard urlsPath.isEmpty == false else {
                DocsLogger.error("传入的URL数组为空")
                complete()
                return
            }
            for filePath in urlsPath {
                guard let fileSize = filePath.sizeExt(),
                    fileSize > 0 else {
                        DocsLogger.info("无法选择 iCloud 文件夹或 Bundle 文件进行上传")
                        continue
                }
                DocsLogger.info("源文件路径: \(filePath.pathString)")
                var fileName = filePath.lastPathComponent
                /// 如果含有转义字符，则解码
                if let tempName = fileName.removingPercentEncoding {
                    fileName = tempName
                }
                let savedURL = iCloudFileCachePath.appendingRelativePath(fileName)
                if savedURL.exists {
                    try? savedURL.removeItem()
                }
                do {
                    //因为filePath是absPath，没有copy方法，所以用 copyItemFromUrl
                    try savedURL.copyItemFromUrl(from: filePath.pathURL)
                    DocsLogger.info("iCloud文件保存到本地沙盒成功")
                } catch {
                    DocsLogger.error("iCloud文件保存到本地沙盒失败, error: \(error.localizedDescription)")
                }
            }
            complete()
        }
        return isValid
    }
    
    private func unzipFile(_ file: DriveSDKLocalFileV2, index: Int) {
        UDToast.showLoading(with: "开始解压: \(file.fileName) ...", on: view)
        DispatchQueue.global().async {
            self._doUnzip(source: file.fileURL.path, target: file.unzipPath, completion: { [weak self] in
                let result = $0
                DispatchQueue.main.async {
                    self?.notifyUnzipResult(result, index: index)
                }
            })
        }
    }
    
    private func _doUnzip(source: String, target: SKFilePath, completion: (Swift.Result<String, Error>) -> Void) {
        let start = CACurrentMediaTime()
        // 简单起见，这里直接用精简包的解压方法了
        let result = BundlePackageExtractor.unzipBundlePkg(zipFilePath: SKFilePath(absPath: source), to: target)
        let end = CACurrentMediaTime()
        let duration = (end - start) * 1000
        let targetAbs = target.pathString
        let fileName = targetAbs.components(separatedBy: "/").last ?? targetAbs
        let text = "解压成功, fileName: \(fileName), 耗时: \(duration) ms"
        completion(result.map { text })
    }
    
    private func notifyUnzipResult(_ result: Swift.Result<String, Error>, index: Int) {
        UDToast.removeToast(on: view)
        switch result {
        case .success(let text):
            UDToast.showSuccess(with: text, on: view)
            fileList[index].state = .unzipped
        case .failure(let error):
            UDToast.showFailure(with: "解压失败, error: \(error.localizedDescription)", on: view)
            fileList[index].state = .failed
        }
        tableview.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
}

extension LocalFileUnzipTestController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = fileList[indexPath.row]
        switch item.state {
        case .ready, .failed:
            unzipFile(item.file, index: indexPath.row)
        case .unzipped:
            let path = item.file.unzipPath.deletingLastPathComponent
            let svc = SandboxFileTreeController(initPath: path)
            navigationController?.pushViewController(svc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}

extension LocalFileUnzipTestController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fileList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let item = fileList[indexPath.row]
        cell.textLabel?.text = item.file.fileName + " (\(item.state.title))"
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let item = fileList[indexPath.row]
        try? item.filePath.removeItem()
        try? item.file.unzipPath.removeItem()
        fileList.remove(at: indexPath.row)
        tableView.reloadData()
    }
}

private class _PickerController: UIDocumentPickerViewController, UIDocumentPickerDelegate {

    private weak var sourceViewController: UIViewController?
    
    private var completion: ((Bool) -> Void)?

    init(sourceViewController: UIViewController?, completion: ((Bool) -> Void)?) {
        self.sourceViewController = sourceViewController
        self.completion = completion
        super.init(documentTypes: ["public.item"], in: .import)
        delegate = self
        modalPresentationStyle = .fullScreen
    }
    
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func showInvalidFileAlert() {
        guard let sourceViewController = sourceViewController else {
            DocsLogger.error("Failed to get source view controller")
            return
        }
        let alert = UIAlertController(title: BundleI18n.SKResource.Drive_Drive_UploadUnsupportFileErrorTitle,
                                      message: BundleI18n.SKResource.Drive_Drive_UploadUnsupportFileErrorMessage,
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: BundleI18n.SKResource.Drive_Drive_Confirm, style: .default, handler: nil)
        alert.addAction(action)
        sourceViewController.present(alert, animated: true, completion: nil)
    }
    
    // MARK: UIDocumentPickerDelegate
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let isValid = LocalFileUnzipTestController.saveICouldFileToLocal(urls: urls, complete: {
            self.completion?(true)
        })
        if !isValid {
            showInvalidFileAlert()
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completion?(false)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let isValid = LocalFileUnzipTestController.saveICouldFileToLocal(urls: [url]) {
            self.completion?(true)
        }
        if !isValid {
            showInvalidFileAlert()
        }
    }
}
#endif
