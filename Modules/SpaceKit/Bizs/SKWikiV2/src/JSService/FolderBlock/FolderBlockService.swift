//
//  FolderBlockService.swift
//  SKDoc
//
//  Created by majie.7 on 2023/6/15.
//

import Foundation
import SKFoundation
import SKCommon
import SpaceInterface
import SKResource
import SKInfra
import LarkAssetsBrowser
import SKWorkspace
import RxSwift
import RxRelay
import SKUIKit

class FolderBlockService: BaseJSService {
    // key: spaceID
    var pushManagers: [String: WikiTreePushManager] = [:]
    // key: spaceID
    var pushBlockInfos: [String: [WikiTreePushBlockInfo]] = [:]
    
    private(set) var newCacheAPI: NewCacheAPI = DocsContainer.shared.resolve(NewCacheAPI.self)!
    var imagePickerManager: CommonPickMediaManager?
    let compressLibraryDir = "drive/drive_upload_caches/media"
    let uploadQueue = DispatchQueue(label: "folder.block.upload")
    
    let interactionHandler: WikiInteractionHandler
    let moreProvider: WikiMainTreeMoreProvider
    // 维护当前block中节点的父节点token
    var parentTokenMap: [String: String] = [:]
    // more面板上的部分操作在ipad上会接着弹一个popover样式的面板，需要一个准确的point来弹出面板
    var morePanelSourceReact: CGRect?
    let disposeBag = DisposeBag()
    
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        interactionHandler = WikiInteractionHandler()
        moreProvider = WikiMainTreeMoreProvider(interactionHelper: interactionHandler)
        super.init(ui: ui, model: model, navigator: navigator)
        setupWikiTreeMorePorviderAction()
        setupLocalNotifyEvent()
    }
}


extension FolderBlockService: JSServiceHandler {
    
    var handleServices: [DocsJSService] {
        return [
            .showCreationPanel,
            .selectFileBlockMedia,
            .showSelectionPanel,
            .wikiRegisterPush,
            .folderBlockMore,
            .getThumbnail
        ]
    }
    
    func handle(params: [String : Any], serviceName: String) {
        let service = DocsJSService(serviceName)
        switch service {
        case .showCreationPanel:
            showCreateionPanel(params: params)
        case .showSelectionPanel:
            return
        case .wikiRegisterPush:
            handleWikiPush(params: params)
        case .selectFileBlockMedia:
            showMediaPicker(params: params)
        case .folderBlockMore:
            handleShowMorePanel(params: params)
        case .getThumbnail:
            getThumbnial(params: params)
        default:
            return
        }
    }
    
    private func showCreateionPanel(params: [String: Any]) {
        guard let callBack = params["callback"] as? String,
              let spaceId = params["spaceId"] as? String,
              let pointX = params["x"] as? CGFloat,
              let pointY = params["y"] as? CGFloat,
              let parentToken = params["parentWikiToken"] as? String,
              let parentView = ui?.editorView else {
            DocsLogger.error("folder block service: show create panel brige params invalid")
            return
        }
        
        let trackParameters = DocsCreateDirectorV2.TrackParameters(source: .docCreate,
                                                                   module: .docx,
                                                                   ccmOpenSource: .wiki)
        let reachableRelay = BehaviorRelay(value: true)
        let helper = SpaceCreatePanelHelper(trackParameters: trackParameters,
                                            mountLocation: .wiki(location: (spaceID: spaceId, parentWikiToken: parentToken)),
                                            createDelegate: nil,
                                            createRouter: self,
                                            createButtonLocation: .blankPage)
        let items = helper.generateItemsForFolderBlock(reachable: reachableRelay.asObservable()) { [weak self] subId in
            self?.uploadCallback(callback: callBack, subId: subId)
        }
        let viewModel = helper.generateTemplateViewModel()
        let createPanelVC = SpaceCreatePanelController(items: items, templateViewModel: viewModel)
        DocsNetStateMonitor.shared.addObserver(createPanelVC) { (_, isReachable) in
            reachableRelay.accept(isReachable)
        }
        createPanelVC.cancelHandler = helper.createCancelHandler()
        createPanelVC.dismissalStrategy = [.larkSizeClassChanged]
        createPanelVC.setupPopover(sourceView: parentView, direction: .any)
        if SKDisplay.pad, ui?.hostView.isMyWindowRegularSize() ?? false {
            createPanelVC.popoverPresentationController?.sourceRect = CGRect(origin: CGPoint(x: pointX, y: pointY), size: .zero)
            self.navigator?.presentViewController(createPanelVC, animated: true, completion: nil)
        } else {
            LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) { [weak self] in
                let isInVCFollow = self?.model?.browserInfo.docsInfo?.isInVideoConference ?? false
                if isInVCFollow {
                    createPanelVC.modalPresentationStyle = .overFullScreen
                }
                self?.navigator?.presentViewController(createPanelVC, animated: true, completion: nil)
            }
        }
    }

}



extension FolderBlockService: DocsCreateViewControllerRouter {
    func routerPresent(vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        navigator?.presentViewController(vc, animated: animated, completion: completion)
    }
    
    func routerPush(vc: UIViewController, animated: Bool) {
        navigator?.pushViewController(vc)
    }
    
    var routerImpl: UIViewController? {
        navigator?.currentBrowserVC
    }
}
