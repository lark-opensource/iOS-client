//
//  DKBaseSubModule.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/20.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import SKUIKit
import EENavigator

class DKBaseSubModule: NSObject, DKSubModuleType {
    weak var hostModule: DKHostModuleType?
    public var bag = DisposeBag()
    public var docsInfo: DocsInfo
    public var fileInfo: DriveFileInfo
    @available(*, deprecated, message: "Will be remove after PermissionSDK Refactor")
    public var permissionInfo: DrivePermissionInfo
    
    init(hostModule: DKHostModuleType) {
        self.hostModule = hostModule
        self.docsInfo = hostModule.docsInfoRelay.value
        self.fileInfo = hostModule.fileInfoRelay.value
        self.permissionInfo = hostModule.permissionRelay.value
    }
    
    @discardableResult
    func bindHostModule() -> DKSubModuleType {
        guard let host = hostModule else {
            spaceAssertionFailure("host module not found")
            return self
        }
        host.docsInfoRelay.subscribe(onNext: {[weak self] docsInfo in
            self?.docsInfo = docsInfo
        }).disposed(by: bag)
        host.fileInfoRelay.subscribe(onNext: {[weak self] fileInfo in
            self?.fileInfo = fileInfo
        }).disposed(by: bag)
        host.permissionRelay.subscribe(onNext: {[weak self] permissionInfo in
            self?.permissionInfo = permissionInfo
        }).disposed(by: bag)
        return self
    }
    
    func unBind() {
        bag = DisposeBag()
    }
}
