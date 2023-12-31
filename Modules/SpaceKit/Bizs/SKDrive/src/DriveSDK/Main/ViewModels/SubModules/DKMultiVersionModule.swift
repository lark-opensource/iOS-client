//
//  DKMultiVersion.swift
//  SKDrive
//
//  Created by majie on 2021/8/23.
//

import Foundation
import SKCommon
import SKResource
import SKFoundation
import RxSwift
import RxCocoa
import EENavigator
import SpaceInterface
import SKInfra

class DKMultiVersionModule: DKBaseSubModule {
    private var versionDataMgr: VersionDataMananger?
    private let _versionUpdated = PublishSubject<String>()
    private let _versionDeleted = PublishSubject<String>()
    private let disposeBag = DisposeBag()
    
    public var versionUpdated: Observable<String> {
        return _versionUpdated.asObservable().catchErrorJustReturn("")
    }
    public var versionDeleted: Observable<String> {
        return _versionDeleted.asObservable().catchErrorJustReturn("")
    }
    
    var navigator: DKNavigatorProtocol
    
    init(hostModule: DKHostModuleType,
         navigator: DKNavigatorProtocol = Navigator.shared) {
        self.navigator = navigator
        super.init(hostModule: hostModule)
    }
    
    deinit {
        DocsLogger.driveInfo("DKMultiVersionModule - deinit")
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        versionDataMgr = VersionDataMananger(fileToken: fileInfo.fileToken, type: docsInfo.type)
        versionDataMgr?.delegate = self
        bindVersionEvent()
        return self
    }
    
    override func unBind() {
        super.unBind()
        versionDataMgr = nil
    }
    
    func bindVersionEvent() {
        versionDeleted.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] version in
            guard let self = self else { return }
            self.handleVersionDeleted(version)
        }).disposed(by: disposeBag)
        versionUpdated.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] version in
            guard let self = self else { return }
            self.handleVersionUpdated(version)
        }).disposed(by: disposeBag)
    }
    
    private func handleVersionUpdated(_ version: String, completion: (() -> Void)? = nil) {
        guard let host = hostModule, let hostVC = host.hostController else {
            spaceAssertionFailure("hostModule not found")
            return
        }
        guard version != fileInfo.version else {
            DocsLogger.driveInfo("handleVersionDelete", extraInfo: ["version": version, "currentVersion": fileInfo.version ?? ""])
            return
        }
        if hostVC.navigationController?.topViewController != hostVC {
            self.refreshVersion(version)
            return
        }
        let alert = UIAlertController(title: BundleI18n.SKResource.Drive_Drive_VersionUpdateTitle,
                                      message: BundleI18n.SKResource.Drive_Drive_VersionUpdateMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: BundleI18n.SKResource.Drive_Drive_Cancel,
                                      style: .default) { (_) in
            self.reserveCurrentVersion()
            self.refreshVersion(version)
            completion?()
        })
        alert.addAction(UIAlertAction(title: BundleI18n.SKResource.Drive_Drive_VersionUpdateRefresh,
                                      style: .default) { (_) in
            self.refreshVersion(version)
            completion?()
        })
        navigator.present(vc: alert, from: hostVC, animated: true)
    }
    
    private func handleVersionDeleted(_ version: String) {
        guard let host = hostModule, let hostVC = host.hostController else {
            spaceAssertionFailure("hostModule not found")
            return
        }
        guard version == fileInfo.version else {
            DocsLogger.driveInfo("handleVersionDelete", extraInfo: ["version": version, "currentVersion": fileInfo.version ?? ""])
            return
        }
        let alert = UIAlertController(title: BundleI18n.SKResource.Drive_Drive_VersionHistoryDeletedTitle,
                                      message: BundleI18n.SKResource.Drive_Drive_VersionHistoryDeletedMessage,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: BundleI18n.SKResource.Drive_Drive_Confirm,
                                      style: .default) { (_) in
            hostVC.navigationController?.popViewController(animated: true)
        })
        navigator.present(vc: alert, from: hostVC, animated: true)
    }
    
    func historyVersionController() -> UIViewController {
        // space的更多选项不需要外部配置
        let moreVisable: Observable<Bool> = .never()
        let actions: [DriveSDKMoreAction] = []
        let more = DKAttachDefaultMoreDependencyImpl(actions: actions, moreMenueVisable: moreVisable, moreMenuEnable: .never())
        let action = DKAttachDefaultActionDependencyImpl()
        let dependency = DKAttachDefaultDependency(actionDependency: action, moreDependency: more)
        let file = DriveSDKAttachmentFile(fileToken: fileInfo.fileToken,
                                          mountNodePoint: fileInfo.mountNodeToken,
                                          mountPoint: fileInfo.mountPoint,
                                          fileType: fileInfo.type,
                                          name: fileInfo.name,
                                          version: fileInfo.version,
                                          dataVersion: fileInfo.dataVersion,
                                          authExtra: nil,
                                          urlForSuspendable: nil,
                                          dependency: dependency)
        let context = [DKContextKey.from.rawValue: DrivePreviewFrom.history.rawValue,
                       DKContextKey.editTimeStamp.rawValue: docsInfo.editTime ?? ""] as [String: Any]
        return DocsContainer.shared.resolve(DriveSDK.self)!
             .createSpaceFileController(files: [file],
                                        index: 0,
                                        appID: DKSupportedApp.space.rawValue,
                                        isInVCFollow: false,
                                        context: context,
                                        statisticInfo: nil)
    }
    
    func refreshVersion(_ version: String?) {
        hostModule?.subModuleActionsCenter.accept(.refreshVersion(version: version))
    }
    
    func reserveCurrentVersion() {
        guard let host = hostModule, let hostVC = host.hostController else {
            spaceAssertionFailure("hostModule not found")
            return
        }
       let controller = historyVersionController()
       navigator.push(vc: controller, from: hostVC, animated: false)    }
    
}

extension DKMultiVersionModule: VersionDataDelegate {
    func didReceiveVersion(version: String, type: VersionDataMananger.VersionReceiveOperation) {
        switch type {
        case .versionDidUpdate:
            //WPS 在线预览无需提示版本更新
            if hostModule?.openFileSuccessType == .wps { return }
            _versionUpdated.onNext(version)
        case .versionDidDelete:
            _versionDeleted.onNext(version)
        default:
            break
        }
    }
}
