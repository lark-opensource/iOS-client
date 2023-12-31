//
//  DriveQLPreviewController.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/17.
//

import UIKit
import QuickLook
import SKCommon
import SKFoundation
import LarkDocsIcon

class DriveQLPreviewController: QLPreviewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    private var isLoaded = false
    private(set) var fileURL: SKFilePath
    weak var bizVCDelegate: DriveBizViewControllerDelegate?

    init(fileURL: SKFilePath) {
        self.fileURL = fileURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        dataSource = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isLoaded { return }
        isLoaded = true
        // QuickLook 无法得知准确的打开完成时机，以及打开是否成功，暂时统一上报打开成功
        bizVCDelegate?.openSuccess(type: openType)
        view.accessibilityIdentifier = "drive.ql.view"
    }

    class func canPreview(_ item: URL) -> Bool {
        #if DEBUG // iOS 16 模拟器这个方法会crash, 系统bug，debug环境mock
        if let ext = SKFilePath.getFileExtension(from: item.absoluteString) {
            let type = DriveFileType(fileExtension: ext)
            return type.isIWork
        } else {
            return false
        }
        #else
            return canPreview(item as QLPreviewItem)
        #endif
    }

    deinit {
        DocsLogger.debug("DriveQLPreviewController-----deinit")
    }
}

// MARK: - QLPreviewControllerDataSource
extension DriveQLPreviewController: QLPreviewControllerDataSource {

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let url = SKFilePath.convertFileEncodingType(fileURL: fileURL)
        return url.pathURL as QLPreviewItem
    }
}

extension DriveQLPreviewController: DriveBizeControllerProtocol {
    var openType: DriveOpenType {
        return .quicklook
    }
    var panGesture: UIPanGestureRecognizer? {
        return nil
    }
    func willUpdateDisplayMode(_ mode: DrivePreviewMode) { }
    func changingDisplayMode(_ mode: DrivePreviewMode) { }
    func updateDisplayMode(_ mode: DrivePreviewMode) { }
}

extension SKFilePath {
    static func convertFileEncodingType(fileURL: SKFilePath) -> SKFilePath {
        let fileType = SKFilePath.getFileExtension(from: fileURL.pathString)
        let size = fileURL.fileSize
        let maxSizeLimit: UInt64 = 20 * 1024 * 1024
        guard fileType == "csv", let size = size, size < maxSizeLimit else {
            DocsLogger.driveInfo("drive.quickLook.LoaclFile: the file is not csv!")
            return fileURL
        }
        
        do {
            let string = try String.read(from: fileURL, encoding: .utf8)
            DocsLogger.driveInfo("drive.quickLook.LoaclFile: read csv file successed with UTF-8!")
            return fileURL
        } catch {
            // 非UTF-8编码格式使用GKB格式编解码
            do {
                let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
                let string = try String.read(from: fileURL, encoding: encoding)
                DocsLogger.driveInfo("drive.quickLook.LoaclFile: read csv file successed with GKB!")
                do {
                    let path = Self.getDocumentsDirectory(fileURL.getFileName())
                    try string.write(to: path, atomically: false, encoding: .utf8)
                    DocsLogger.driveInfo("drive.quickLook.LoaclFile: convert csv file successed with UTF-8!")
                    return path
                } catch {
                    DocsLogger.error("drive.quickLook.LoaclFile: convert csv file failed with UTF-8! error: \(error.localizedDescription)")
                    return fileURL
                }
            } catch {
                DocsLogger.error("drive.quickLook.LoaclFile: read csv file failed with GKB! error: \(error.localizedDescription)")
                return fileURL
            }
        }
    }
    
    static func getDocumentsDirectory(_ fileName: String) -> SKFilePath {
        SKFilePath.globalSandboxWithTemporary.createDirectoryIfNeeded()
        let path = SKFilePath.globalSandboxWithTemporary.appendingRelativePath("uft8_\(fileName)")
        return path
    }
    
    static func convertFileEncodingTypeAsync(fileURL: SKFilePath, compeletion: @escaping (SKFilePath) -> Void) {
        DispatchQueue.global().async {
            let url = Self.convertFileEncodingType(fileURL: fileURL)
            compeletion(url)
        }
    }
}
