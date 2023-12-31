//
//  DKHistoryRecordModule.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/8/22.
//

import Foundation
import SKCommon
import SKFoundation
import RxSwift
import RxCocoa
import EENavigator
import SpaceInterface
import SKInfra

public protocol DKNavigatorProtocol {
    func push(vc: UIViewController, from: UIViewController, animated: Bool, completion:(() -> Void)?)
    func present(vc: UIViewController, from: UIViewController, animated: Bool, completion:(() -> Void)?)
}

extension DKNavigatorProtocol {
    func present(vc: UIViewController, from: UIViewController, animated: Bool) {
        present(vc: vc, from: from, animated: animated, completion: nil)
    }
    
    func push(vc: UIViewController, from: UIViewController, animated: Bool) {
        push(vc: vc, from: from, animated: animated, completion: nil)
    }
}

extension Navigator: DKNavigatorProtocol {
    public func push(vc: UIViewController, from: UIViewController, animated: Bool, completion:(() -> Void)?) {
        push(vc, from: from, animated: animated, completion: completion)
    }
    public func present(vc: UIViewController, from: UIViewController, animated: Bool, completion:(() -> Void)?) {
        present(vc, from: from, animated: animated, completion: completion)
    }
}

class DKHistoryRecordModule: DKBaseSubModule {
    
    var navigator: DKNavigatorProtocol
    
    init(hostModule: DKHostModuleType, navigator: DKNavigatorProtocol = Navigator.shared) {
        self.navigator = navigator
        super.init(hostModule: hostModule)
    }
    
    deinit {
        DocsLogger.driveInfo("DKHistoryRecordModule -- deinit")
    }
    override func bindHostModule() -> DKSubModuleType {
        super.bindHostModule()
        guard let host = hostModule else { return self }
        host.subModuleActionsCenter.observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] action in
            guard let self = self else {
                return
            }

            if case .openHistory = action {
                self.openHistroyVersion()
            }
        }).disposed(by: bag)
        return self
    }
    
    func openHistroyVersion() {
        guard let host = hostModule, let hostVC = host.hostController else {
            spaceAssertionFailure("hostModule not found")
            return
        }
        // Drive业务埋点：历史版本
        DriveStatistic.clickEnterHistoryWithin(fileId: fileInfo.fileToken,
                                               fileType: fileInfo.type,
                                               previewFrom: host.commonContext.previewFrom.stasticsValue,
                                               additionalParameters: host.additionalStatisticParameters)
        let fileMeta = fileInfo.getFileMeta()
        let vm = DriveActivityViewModel(fileMeta: fileMeta,
                                        docsInfo: docsInfo,
                                        isGuest: host.commonContext.isGuest)
        let activityVC = DriveActivityViewController(viewModel: vm)
        activityVC.loadingView = DocsContainer.shared.resolve(DocsLoadingViewProtocol.self)
        vm.hostController = activityVC
        navigator.push(vc: activityVC, from: hostVC, animated: true)
    }
}
