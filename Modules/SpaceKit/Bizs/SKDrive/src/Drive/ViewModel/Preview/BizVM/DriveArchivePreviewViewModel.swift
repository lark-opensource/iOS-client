//
//  DriveArchivePreviewViewModel.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/5.
//  

import UIKit
import SwiftyJSON
import SKCommon
import SKFoundation
import SKResource
import LarkDocsIcon

struct DriveArchiveDataParser {
    func parse(content: String) -> DriveArchiveFolderNode? {
        let json = JSON(parseJSON: content)
        return DriveArchiveNode.parse(data: json, parentNode: nil) as? DriveArchiveFolderNode
    }
}

class DriveArchivePreviewViewModel: DriveArchiveViewModelType {

    private var rootFolderNode: DriveArchiveFolderNode?
    private let renderQueue: DispatchQueue = DispatchQueue(label: "Drive.Preview.Archive.ViewModel")

    private let fileID: String
    private let fileName: String
    var rootNodeName: String {
        return fileName
    }

    private let archiveContent: String?
    private let previewFrom: DrivePreviewFrom

    var actionHandler: ((Action) -> Void)?
    var additionalStatisticParameters: [String: String]?

    init(fileID: String, fileName: String,
         archiveContent: String?,
         previewFrom: DrivePreviewFrom?,
         additionalStatisticParameters: [String: String]?) {
        self.fileID = fileID
        self.fileName = fileName
        self.archiveContent = archiveContent
        self.previewFrom = previewFrom ?? .unknown
        self.additionalStatisticParameters = additionalStatisticParameters
    }

    func startPreview() {
        actionHandler?(.startLoading)
        renderQueue.async { [weak self] in
            self?.parseExtraData()
        }
    }

    func parseExtraData() {
        guard let content = archiveContent else {
            DocsLogger.error("Drive.Preview.Archive.ViewModel --- archive content is nil")
            DispatchQueue.main.async {
                self.actionHandler?(.endLoading)
                self.actionHandler?(.failure(DriveError.previewArchiveDataError))
            }
            return
        }

        let parser = DriveArchiveDataParser()
        guard let rootNode = parser.parse(content: content) else {
            DocsLogger.error("Drive.Preview.Archive.ViewModel --- Failed to convert json to rootFolderNode")
            DispatchQueue.main.async {
                self.actionHandler?(.endLoading)
                self.actionHandler?(.failure(DriveError.previewArchiveDataError))
            }
            return
        }
        let newRootNode = DriveArchiveFolderNode(name: SKFilePath.getFileNamePrefix(name: fileName),
                                                 parentNode: nil,
                                                 childNodes: rootNode.childNodes)
        self.rootFolderNode = newRootNode
        DispatchQueue.main.async {
            self.actionHandler?(.updateRootNode(newRootNode))
            self.actionHandler?(.endLoading)
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
            DocsLogger.debug("Drive.Preview.Archive --- Select file in archive", extraInfo: ["name": fileNode.name])
            let toast = BundleI18n.SKResource.Drive_Drive_PreviewUnsupportInArchive(fileNode.fileExtension ?? fileNode.name)
            actionHandler?(.showToast(toast))
        }
        
        let fileExtension = SKFilePath.getFileExtension(from: fileName)
        let fileType = DriveFileType(fileExtension: fileExtension)
        DriveStatistic.clickArchiveNode(fileId: fileID,
                                        nodeType: node.fileType,
                                        archiveFileType: fileType,
                                        previewFrom: previewFrom,
                                        additionalParameters: additionalStatisticParameters)
    }
}
