//
//  BTSecureController.swift
//  SKBitable
//
//  Created by chensi(陈思) on 2022/6/14.
//  


import Foundation
import SKCommon
import SKFoundation
import UIKit
import LarkEMM
import LarkContainer
import SpaceInterface

final class BTSecureController: BTController {
    
    @Provider private var screenProtectionService: ScreenProtectionService
    
    private lazy var screenProtectionObserver: ScreenProtectionObserver = {
        let obj = ScreenProtectionObserver(identifier: "\(ObjectIdentifier(self))")
        obj.onChange = { [weak self] in
            self?.updatePreventStatus()
        }
        return obj
    }()
    
    // https://bytedance.feishu.cn/sheets/shtcnq0JKLPi8z3C5IM4WvgRMOe
    // 实验结论: 系统在loadview中给vc的view设定的初始size，是代码所在的window的size
    let viewInitialSize: CGSize
    
    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = [.superView, .windowOrVC, .thisView]
        preventer.setAnalyticsFileInfoGetter(block: { [weak self] () -> (String?, String?) in
            if UserScopeNoChangeFG.YY.bitableReferPermission, let permissionObj = self?.viewModel.baseContext.permissionObj {
                let fileId = DocsTracker.encrypt(id: permissionObj.objToken)
                let fileType = permissionObj.objType.name
                return (fileId, fileType)
            }
            let fileId = DocsTracker.encrypt(id: self?.viewModel.hostDocsInfo?.token ?? "")
            let fileType = DocsType.bitable.name
            return (fileId, fileType)
        })
        return preventer
    }()
    
    init(actionTask: BTCardActionTask,
         viewMode: BTViewMode? = nil,
         recordIDs: [String] = [],
         stageFieldId: String = "",
         delegate: BTControllerDelegate?,
         uploader: BTUploadObservingDelegate?,
         geoFetcher: BTGeoLocationFetcher?,
         baseContext: BaseContext,
         dataService: BTDataService?,
         initialSize: CGSize) {

        self.viewInitialSize = initialSize

        super.init(actionTask: actionTask,
                   viewMode: viewMode,
                   recordIDs: recordIDs,
                   stageFieldId: stageFieldId,
                   delegate: delegate,
                   uploader: uploader,
                   geoFetcher: geoFetcher,
                   baseContext: baseContext,
                   dataService: dataService)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        viewCapturePreventer.contentView.frame = .init(origin: .zero, size: viewInitialSize)
        view = viewCapturePreventer.contentView
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        DocsLogger.info("BTSecureController loadView:\(String(describing: view))")
    }
    
    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        // 表单不是被present,而是作为childvc被addSubview,需要手动刷新
        if isViewLoaded {
            updateVisibleCellsCaptureAllowedState()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        screenProtectionService.register(screenProtectionObserver)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        screenProtectionService.unRegister(screenProtectionObserver)
    }
    
    override func updateVisibleCellsCaptureAllowedState() {
        updatePreventStatus()
    }
    
    private func updatePreventStatus() {
        let larkAllow = !(screenProtectionService.isSecureProtection) // 主端开关
        if larkAllow {
            let ccmAllow = allowCapture
            viewCapturePreventer.isCaptureAllowed = ccmAllow
            DocsLogger.btInfo("[ACTION] BTSecureController setCaptureAllowed -> \(ccmAllow)")
        } else {
            viewCapturePreventer.isCaptureAllowed = false
            DocsLogger.btInfo("[ACTION] BTSecureController setCaptureAllowed -> false")
        }
    }
}

extension BTSecureController {
    // 为了避免 identifier 重名而创建个单独的类
    private final class ScreenProtectionObserver: ScreenProtectionChangeAction {
        
        var onChange: (() -> Void)?
        
        let identifier: String
        
        init(identifier: String) {
            self.identifier = identifier
        }
        
        func onScreenProtectionChange() {
            onChange?()
        }
    }
}
