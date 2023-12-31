//
//  DrivePreviewVCManager.swift
//  SKDrive
//
//  Created by bupozhuang on 2021/9/7.
//

import Foundation
import RxSwift
import RxCocoa
import SpaceInterface
import SKCommon
import SKFoundation
import SKInfra

class DKPreviewVCManager: NSObject, DKPreviewVCManagerProtocol {
    class DKNativeComponentState {
        var identifier: String
        var isInScreen: Bool // 当前是否在屏幕可视区域内
        var moveOutTimeStamp: Double? // 预览组件移出可视区域的时间，当isInScreen为false才有效
        var previewInfo: [String: AnyObject]? // 预览状态，用于恢复预览进度，目前只有视频/音频使用
        var initailParams: DriveFileBlockParams // 初始化参数
        var previewVC: DriveFileBlockVCProtocol? // 当前的预览VC
        init(isInScreen: Bool,
             initailParams: DriveFileBlockParams,
             identifier: String,
             moveOutTimeStamp: Double? = nil,
             previewInfo: [String: AnyObject]? = nil) {
            self.identifier = identifier
            self.isInScreen = isInScreen
            self.initailParams = initailParams
            self.previewInfo = previewInfo
            self.moveOutTimeStamp = moveOutTimeStamp
        }
    }
    private var previewStats = [String: DKNativeComponentState]()
    // 可视区域内的vc状态
    private var inScreenStats: [DKNativeComponentState] {
        return previewStats.values.filter { state in
            return state.isInScreen
        }
    }
    // 被移出可视区域vc状态，按照移出时间排序
    private var outScreenStats: [DKNativeComponentState] {
        return previewStats.values.filter { state in
            return !state.isInScreen && (state.previewVC != nil)
        }.sorted { state1, state2 in
            guard let time1 = state1.moveOutTimeStamp, let time2 = state2.moveOutTimeStamp else {
                spaceAssertionFailure("DriveFileBlockComponent --  has no move out timestamp")
                return true
            }
            return time1 < time2
        }
    }
    private let maxVCCount = 5
    
    func makeAnimatedContainer(vc: BaseViewController) -> DriveAnimatedContainer {
        return DriveContainerViewController(vc: vc)
    }
    
    func getPreviewVC(with identifier: String, params: DriveFileBlockParams?) -> DriveFileBlockVCProtocol? {
        if let state = previewStats[identifier], let vc = state.previewVC {
            state.isInScreen = true
            previewStats[identifier] = state
            return vc
        }
        guard let params = params else {
            DocsLogger.info("DriveFileBlockComponent -- getPreviewVC, params is nil return nil")
            return nil
        }
        // 如果缓存VC个数超过最大个数，释放移出可视区域最久并且没有在全屏展示的vc
        checkAndRemoveOutScreenVC()
        let vc = createVC(with: params)
        // 更新保存预览状态信息
        var state: DKNativeComponentState
        if let curState = previewStats[identifier] {
            curState.isInScreen = true
            curState.moveOutTimeStamp = nil
            curState.previewVC = vc
            state = curState
        } else {
            state = DKNativeComponentState(isInScreen: true, initailParams: params, identifier: identifier)
            state.previewVC = vc
        }
        previewStats[identifier] = state
        DocsLogger.info("DriveFileBlockComponent -- DKPreviewVCManager VC count after create: \(inScreenStats.count + outScreenStats.count)")

        return vc
    }
    
    private func checkAndRemoveOutScreenVC() {
        // 如果缓存VC个数超过最大个数，释放移出可视区域最久并且没有在全屏展示的vc
        let curVCCount = inScreenStats.count + outScreenStats.count
        DocsLogger.info("DriveFileBlockComponent -- DKPreviewVCManager VC count: \(curVCCount)")
        if curVCCount >= maxVCCount {
            if let oldState = outScreenStats.first {
                // 当前vc非全屏状态，可以回收
                if oldState.previewVC?.parent == nil ||
                    oldState.previewVC?.parent?.isKind(of: DriveContainerViewController.self) == false {
                    DocsLogger.info("DriveFileBlockComponent -- DKPreviewVCManager remove outScreen VC identifier: \(oldState.identifier) - \(oldState.initailParams.fileName)")
                    oldState.previewVC?.willMove(toParent: nil)
                    oldState.previewVC?.removeFromParent()
                    oldState.previewVC?.view.removeFromSuperview()
                    oldState.previewVC?.didMove(toParent: nil)
                    oldState.previewVC = nil
                }
            }
        }

    }
    
    func component(with identifier: String, moveInScreen: Bool) {
        DocsLogger.info("DriveFileBlockComponent -- DKPreviewVCManager component \(identifier), moveInScreen: \(moveInScreen)")
        guard let state = previewStats[identifier] else {
            DocsLogger.info("DriveFileBlockComponent -- DKPreviewVCManager component not rendered: \(identifier), moveInScreen: \(moveInScreen)")
            return
        }
        state.isInScreen = moveInScreen
        if moveInScreen {
            state.moveOutTimeStamp = nil
        } else {
            state.moveOutTimeStamp = Date().timeIntervalSince1970
        }
        previewStats[identifier] = state
        checkAndRemoveOutScreenVC() 
    }
    
    func clear() {
        for state in previewStats.values {
            state.previewVC?.dismiss(animated: false, completion: nil)
            state.previewVC?.view.removeFromSuperview()
            state.previewVC = nil
        }
        previewStats = [:]
    }
    
    func delete(with identifier: String) {
        let state = previewStats.removeValue(forKey: identifier)
        state?.previewVC = nil
        DocsLogger.info("DriveFileBlockComponent -- DKPreviewVCManager VC count after delete: \(identifier) count: \(previewStats.count)")
    }
    
    private func createVC(with params: DriveFileBlockParams) -> DriveFileBlockVCProtocol? {
        let moreVisable: Observable<Bool> = .just(true)
        let actions: [DriveSDKMoreAction] = [.saveToLocal(handler: { _, _  in }),
                                             .customOpenWithOtherApp(customAction: nil, callback: nil),
                                             .saveToSpace(handler: { _ in })]
        let more = FileBlockAttachMoreDependencyImpl(actions: actions, moreMenueVisable: moreVisable, moreMenuEnable: .just(true))
        let action = FileBlockActionDependencyImpl()
        let dependency = FileBlockDependency(actionDependency: action, moreDependency: more)
        let file = DriveSDKAttachmentFile(fileToken: params.fileID,
                                          hostToken: params.hostToken,
                                          mountNodePoint: params.mountNodePoint,
                                          mountPoint: params.mountPoint,
                                          fileType: params.fileType,
                                          name: params.fileName,
                                          authExtra: params.authExtra,
                                          urlForSuspendable: nil,
                                          dependency: dependency)
        let naviBarConfig = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: true)
        let vc = DocsContainer.shared.resolve(DriveSDK.self)!.createAttachmentFileController(attachFiles: [file],
                                                                                             index: 0,
                                                                                             appID: params.appID,
                                                                                             isCCMPermission: false,
                                                                                             tenantID: params.tenantID,
                                                                                             isInVCFollow: params.isInVCFollow,
                                                                                             attachmentDelegate: nil,
                                                                                             naviBarConfig: naviBarConfig)
        guard let fileBlockVC = vc as? DriveFileBlockVCProtocol else {
            spaceAssertionFailure("DriveFileBlockComponent -- DKPreviewVCManager vc is not DriveFileBlockVCProtocol")
            return nil
        }
        (fileBlockVC as? DKMainViewController)?.displayMode = .card
        return fileBlockVC
    }
}


struct FileBlockAttachMoreDependencyImpl: DriveSDKMoreDependency {
    var moreMenuVisable: Observable<Bool>
    
    var moreMenuEnable: Observable<Bool>
    
    var actions: [DriveSDKMoreAction]
    
    init(actions: [DriveSDKMoreAction], moreMenueVisable: Observable<Bool>, moreMenuEnable: Observable<Bool> = .just(true)) {
        self.actions = actions
        self.moreMenuVisable = moreMenueVisable
        self.moreMenuEnable = moreMenuEnable
    }
}

struct FileBlockActionDependencyImpl: DriveSDKActionDependency {
    var uiActionSignal: RxSwift.Observable<SpaceInterface.DriveSDKUIAction> {
        return .never()
    }
    var closePreviewSignal: Observable<Void>
    var stopPreviewSignal: Observable<Reason>
    init(closePreviewSignal: Observable<Void> = .never(), stopPreviewSignal: Observable<Reason> = .never()) {
        self.closePreviewSignal = closePreviewSignal
        self.stopPreviewSignal = stopPreviewSignal
    }
}

struct FileBlockDependency: DriveSDKDependency {
    var actionDependency: DriveSDKActionDependency
    
    var moreDependency: DriveSDKMoreDependency
    
    init(actionDependency: DriveSDKActionDependency, moreDependency: DriveSDKMoreDependency) {
        self.actionDependency = actionDependency
        self.moreDependency = moreDependency
    }
}
