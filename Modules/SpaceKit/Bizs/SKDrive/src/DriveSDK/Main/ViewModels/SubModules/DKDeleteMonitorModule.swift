//
//  DKDeleteMonitorModule.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/10/17.
//

import Foundation
import SKCommon
import SKResource
import SKFoundation
import RxSwift
import RxCocoa
import EENavigator
import SpaceInterface

class DKDeleteMonitorModule: DKBaseSubModule {
    /// 删除推送监听
    private var deletedMonitor: FileDeletedPushManager?
    private let disposeBag = DisposeBag()
    
    deinit {
        DocsLogger.driveInfo("DKMultiVersionModule - deinit")
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        setupDeletedMonitor()
        return self
    }
    
    override func unBind() {
        super.unBind()
        deletedMonitor = nil
    }
    
    private func setupDeletedMonitor() {
        let newDeletedMonitor = FileDeletedPushManager(fileToken: fileInfo.fileToken, type: .file)
        deletedMonitor = newDeletedMonitor
        newDeletedMonitor.start(with: self)
    }
}

extension DKDeleteMonitorModule: FileDeletedPushDelegate {
    func fileDidDeleted() {
        guard let host = hostModule else {
            spaceAssertionFailure("hostModule not found")
            return
        }
        host.subModuleActionsCenter.accept(.fileDidDeleted)
    }
}
