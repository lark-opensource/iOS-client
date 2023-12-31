//
//  DKSecretMonitorModule.swift
//  SKDrive
//
//

import Foundation
import SKCommon
import SKResource
import SKFoundation
import RxSwift
import RxCocoa
import EENavigator
import SpaceInterface

class DKSecretMonitorModule: DKBaseSubModule {
    private var secretMonitor: FileSecretPushManager?
    private let disposeBag = DisposeBag()
    
    deinit {
        DocsLogger.driveInfo("DKMultiVersionModule - deinit")
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        setupSecretMonitor()
        return self
    }
    
    override func unBind() {
        super.unBind()
        secretMonitor = nil
    }
    
    private func setupSecretMonitor() {
        let newSecretMonitor = FileSecretPushManager(fileToken: fileInfo.fileToken, type: .file)
        secretMonitor = newSecretMonitor
        newSecretMonitor.start(with: self)
    }
}

extension DKSecretMonitorModule: FileSecretPushDelegate {
    func secretDidChanged(token: String, type: Int) {
        DocsLogger.driveInfo("secretDidChanged token \((DocsTracker.encrypt(id: token))), \(type)")
        guard let host = hostModule else {
            spaceAssertionFailure("hostModule not found")
            return
        }
        host.subModuleActionsCenter.accept(.updateDocsInfo)
    }
}
