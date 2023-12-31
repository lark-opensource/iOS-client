//
//  DriveAutoPerformanceTest.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/12/4.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKCommon
import SKFoundation
import SKUIKit
import UniverseDesignToast
import SpaceInterface
import SKInfra
import LarkDocsIcon

class DriveAutoPerformanceTest: DriveAutoPerformanceTestBase {
    private var fileList: [SpaceEntry] = []
    private weak var navigator: UIViewController?
    private let bag = DisposeBag()
    private var endFlag = false
    private weak var targetDriveVC: UIViewController?
    private var request: DocsRequest<JSON>?
    private var count = 1
    private var circleCount = 1

    override init(navigator: UIViewController?) {
        super.init(navigator: navigator)
        self.navigator = navigator
    }

    override func start() {
        endFlag = false
        let path = OpenAPI.APIPath.getPersonFileListInHome
        let params: [String: Any] = [
        "need_path": 1,
        "need_total": 1,
        "length": 100,
        "rank": "0",
        "asc": false]

        request = DocsRequest<JSON>(path: path, params: params)
            .set(method: .GET)
            .start(result: {[unowned self] (files, _) in
                guard let fileData = files else { return }
                let data = fileData["data"]["entities"]["nodes"].dictionaryValue.values.map({ (jsonData) -> SpaceEntry in
                    let type = DocsType(rawValue: jsonData["type"].intValue) 
                    let fileEntry = SpaceEntryFactory.createEntry(type: type, nodeToken: jsonData["token"].stringValue, objToken: jsonData["obj_token"].stringValue)
                    fileEntry.updateName(jsonData["name"].stringValue)
                    fileEntry.updateCreateUid(jsonData["create_uid"].stringValue)
                    fileEntry.updateEditUid(jsonData["edit_uid"].stringValue)
                    fileEntry.updateEditTime(jsonData["edit_time"].doubleValue)
                    fileEntry.updateAddTime(jsonData["add_time"].doubleValue)
                    fileEntry.updateOwnerID(jsonData["owner_id"].stringValue)
                    fileEntry.updateShareURL(jsonData["url"].stringValue)
                    return fileEntry
                }).filter({ (fileEntry) -> Bool in
                    return fileEntry.type == .file
                })
                self.fileList = data
                if let file = self.fileList.first {
                    self.start(file: file)
                }
        })
    }
    override func stop() {
        endFlag = true
    }

    private func start(file: SpaceEntry) {
        guard !endFlag else { return }
        let fileConxt = self.getFileInfo(by: file)
        let docsInfo = file.transform()
        // space的更多选项不需要外部配置
        let moreVisable: Observable<Bool> = .never()
        let actions: [DriveSDKMoreAction] = []
        let more = DKAttachDefaultMoreDependencyImpl(actions: actions, moreMenueVisable: moreVisable, moreMenuEnable: .never())
        let action = DKAttachDefaultActionDependencyImpl()
        let dependency = DKAttachDefaultDependency(actionDependency: action, moreDependency: more)
        let driveFile = DriveSDKAttachmentFile(fileToken: file.objToken,
                                               mountNodePoint: file.parent,
                                               mountPoint: DriveConstants.driveMountPoint,
                                               fileType: file.fileType,
                                               name: file.name,
                                               version: nil,
                                               dataVersion: nil,
                                               authExtra: nil,
                                               urlForSuspendable: docsInfo.urlForSuspendable(),
                                               dependency: dependency)
        let context = [DKContextKey.from.rawValue: DrivePreviewFrom.docsList.rawValue]
        let vc = DocsContainer.shared.resolve(DriveSDK.self)!
            .createSpaceFileController(files: [driveFile],
                                       index: 0,
                                       appID: DKSupportedApp.space.rawValue,
                                       isInVCFollow: false,
                                       context: context,
                                       statisticInfo: nil)
        self.targetDriveVC = vc
        if let vc = vc as? DKMainViewController {
            vc.viewModel.readyToStart.drive(onNext: {[unowned vc, unowned self] _ in
                vc.viewModel.performanceRecorder.finishedCallback = {[unowned self] in
                    self.end()
                }
            }).disposed(by: bag)
            navigator?.navigationController?.pushViewController(vc, animated: true)
            if let window = navigator?.view.window {
                UDToast.showSuccess(with: "第\(count)次打开，当前循环列表\(circleCount)/\(fileList.count)", on: window)
            }
        }
    }

    private func end() {
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) {
            let item = self.fileList.removeFirst()
            self.fileList.append(item)
            self.navigator?.navigationController?.popViewController(animated: true)
            self.count += 1
            self.circleCount = self.circleCount >= self.fileList.count ? 1 : self.circleCount + 1
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_2500) {
                if let file = self.fileList.first {
                    self.start(file: file)
                }
            }
        }
    }

    private func getFileInfo(by file: SpaceEntry) -> DriveFileContext {
        let fileType = DriveFileType(fileExtension: file.fileType)
        let fileInfo = file.transform()
        fileInfo.fileType = fileType.rawValue

        let meta = makeDriveFileMeta(file: file)
        return DriveFileContext(fileMeta: meta,
                                docsInfo: fileInfo)
    }

    private func makeDriveFileMeta(file: SpaceEntry) -> DriveFileMeta {
        return DriveFileMeta(size: 0,
                             name: file.name ?? "",
                             type: file.fileType ?? "",
                             fileToken: file.objToken,
                             mountNodeToken: file.parent ?? "",
                             mountPoint: DriveConstants.driveMountPoint,
                             version: nil,
                             dataVersion: nil,
                             source: .other,
                             tenantID: file.ownerTenantID,
                             authExtra: nil)
    }
}
