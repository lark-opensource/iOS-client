//
//  DriveLocalFileTestController.swift
//  SKCommon
//
//  Created by bupozhuang on 2021/6/16.
//
#if BETA || ALPHA || DEBUG
import UIKit
import SpaceInterface
import EENavigator
import Foundation
import SKResource
import RxSwift
import RxRelay
import SKFoundation
import UniverseDesignToast
import UniverseDesignNotice

class DriveLocalFileTestController: UITableViewController {
    var fileList: [DriveSDKLocalFileV2] = []
    var filePathList: [SKFilePath] = []
    
    /// iCloud文件缓存目录
    static var iCloudFileCachePath: SKFilePath {
        let path = SKFilePath.driveLibraryDir
                                    .appendingRelativePath("drive")
                                    .appendingRelativePath("local")
                                    .appendingRelativePath("test")
        path.createDirectoryIfNeeded()
        return path
    }
    private static let uploadQueue = DispatchQueue(label: "drive.local")

    override func viewDidLoad() {
        super.viewDidLoad()
        loadDatas()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    func setupUI() {
        self.title = "本地文件列表"
        let addbtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addFile))
        let clearbtn = UIBarButtonItem(title: "clear", style: .plain, target: self, action: #selector(clear))

        self.navigationItem.rightBarButtonItems = [clearbtn, addbtn]
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "cancel", style: .plain, target: self, action: #selector(cancel))
    }

    func loadDatas() {
        var files: [DriveSDKLocalFileV2] = []
        var filePaths: [SKFilePath] = []
        do {
            let allFileURLs = try Self.iCloudFileCachePath.contentsOfDirectory().compactMap({ path in
                let path = Self.iCloudFileCachePath.appendingRelativePath(path)
                return (path.pathURL, path)
            })
            for (fileURL, path) in allFileURLs {
                let fileName = fileURL.lastPathComponent
                let filetype = SKFilePath.getFileExtension(from: fileName)
                let fileID = fileURL.absoluteString
                let file = DriveSDKLocalFileV2(fileName: fileName, fileType: filetype, fileURL: fileURL, fileId: fileID, dependency: TestLocalDependencyImpl())
                files.append(file)
                filePaths.append(path)
            }
            fileList = files
            filePathList = filePaths
        } catch {
            DocsLogger.error("falield")
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fileList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "filecell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "filecell")
        }
        let file = fileList[indexPath.row]
        let filename = file.fileName ?? file.fileURL.lastPathComponent
        cell?.textLabel?.text = file.fileType ?? getFileExtension(name: filename)
        cell?.detailTextLabel?.text = filename
        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = fileList[indexPath.row]
        let dependency = file.dependency as? TestLocalDependencyImpl
        dependency?.test()
        let config = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: false)
        let body = DriveSDKLocalFileBody(files: fileList, index: indexPath.row, appID: "9999", thirdPartyAppID: nil, naviBarConfig: config)
        Navigator.shared.push(body: body, from: self)
    }

    func getFileExtension(name: String) -> String {
        if let index = name.range(of: ".", options: .backwards)?.upperBound {
            let ext = String(name[index...])
            return ext
        } else {
            return ""
        }
    }
    
    @objc
    func addFile() {
        let documentPicker = DriveDocumentPickerViewController(sourceViewController: self) { (succ) in
            if succ {
                DispatchQueue.main.async {
                    self.loadDatas()
                    self.tableView.reloadData()
                }
            }
        }
        self.present(documentPicker, animated: false, completion: nil)
    }
    
    @objc
    func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc
    func clear() {
        for path in filePathList {
            try? path.removeItem()
        }
        loadDatas()
        self.tableView.reloadData()
    }
    
    /// 保存iCloud文件到本地沙盒
    static func saveICouldFileToLocal(urls: [URL], complete: @escaping () -> Void) -> Bool {
        let isValid = !urls.contains { (url) -> Bool in
            let path = SKFilePath(absUrl: url)
            guard path.isFile() else {
                // 含有文件夹
                return true
            }
            guard let size = path.sizeExt() else {
                // 含有取不到大小（通常为文件夹）的文件
                return true
            }
            // 含有大小为0的文件
            return size == 0
        }
        uploadQueue.async {
            guard urls.isEmpty == false else {
                DocsLogger.error("[SKFilePath] 传入的URL数组为空")
                complete()
                return
            }
            for url in urls {
                let filePath = SKFilePath(absUrl: url)
                guard let fileSize = filePath.sizeExt(),
                    fileSize > 0 else {
                        DocsLogger.info("[SKFilePath] 无法选择 iCloud 文件夹或 Bundle 文件进行上传")
                        continue
                }
                DocsLogger.info("[SKFilePath] 源文件路径: \(filePath.pathString)")
                var fileName = (filePath.pathString as NSString).lastPathComponent
                /// 如果含有转义字符，则解码
                if let tempName = fileName.removingPercentEncoding {
                    fileName = tempName
                }
                let pathExtention = (fileName as NSString).pathExtension
                let savedURL = iCloudFileCachePath.appendingRelativePath(fileName)
                do {
                    if savedURL.exists {
                        try savedURL.removeItem()
                    }
                    DocsLogger.info("[SKFilePath] 本地沙盒文件删除成功")
                } catch {
                    DocsLogger.error("[SKFilePath] 本地沙盒文件删除失败, path: \(savedURL.pathString) error: \(error.localizedDescription)")
                }
                do {
                    try filePath.copyItem(to: savedURL)
                    DocsLogger.info("[SKFilePath] iCloud文件保存到本地沙盒成功")
                } catch {
                    DocsLogger.error("[SKFilePath] iCloud文件保存到本地沙盒失败, error: \(error.localizedDescription)")
                }
            }
            complete()
        }
        return isValid
    }
}


/// 参考文档：https://docs.bytedance.net/doc/doccnqBxBdV5FJdImdxWoP
private let documentTypes = [
    "public.item"    //范围太广
//    "public.content",
//    "public.data",
//    "public.database",
//    "public.calendar-event",
//    "public.message",
//    "public.contact",
//    "public.archive",
]

class DriveDocumentPickerViewController: UIDocumentPickerViewController {

    weak var sourceViewController: UIViewController?
    private var completion: ((Bool) -> Void)?

    init(sourceViewController: UIViewController?, completion: ((Bool) -> Void)?) {
        self.sourceViewController = sourceViewController
        self.completion = completion
        super.init(documentTypes: documentTypes, in: .import)
        delegate = self
        modalPresentationStyle = .fullScreen
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension DriveDocumentPickerViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let isValid = DriveLocalFileTestController.saveICouldFileToLocal(urls: urls, complete: {
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
        let isValid = DriveLocalFileTestController.saveICouldFileToLocal(urls: [url]) {
            self.completion?(true)
        }
        if !isValid {
            showInvalidFileAlert()
        }
    }
}

extension DriveDocumentPickerViewController {
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
}

struct TestLocalDependencyImpl: DriveSDKDependency {
    let more = LocalMoreDependencyImpl()
    let action = ActionDependencyImpl()
    var actionDependency: DriveSDKActionDependency {
        return action
    }
    var moreDependency: DriveSDKMoreDependency {
        return more
    }
    
    func test() {
        action.test()
    }
}

struct LocalMoreDependencyImpl: DriveSDKMoreDependency {
    var moreMenuVisable: Observable<Bool> {
        return .just(true)
    }
    var moreMenuEnable: Observable<Bool> {
        return .just(true)
    }
    var actions: [DriveSDKMoreAction] {
        return [.customOpenWithOtherApp(customAction: nil, callback: nil)]
    }
}

struct ActionDependencyImpl: DriveSDKActionDependency {
    private var uiActionSubject = PublishSubject<DriveSDKUIAction>()
    
    private var closeSubject = PublishSubject<Void>()
    private var stopSubject = PublishSubject<Reason>()
    var closePreviewSignal: Observable<Void> {
        return closeSubject.asObserver().debug("xxxxxxxxx1")
    }
    
    var stopPreviewSignal: Observable<Reason> {
        return stopSubject.asObserver().debug("xxxxxxxxxx1")
    }
    
    var uiActionSignal: Observable<DriveSDKUIAction> {
        return uiActionSubject.asObserver().debug("xxxxxxxx")
    }
    
    func test() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
            self.stopSubject.onNext(Reason(reason: "测试", image: nil))
            DispatchQueue.global().asyncAfter(deadline: .now() + 15) {
                self.closeSubject.onNext(())
            }
        }
    }
}
#endif
