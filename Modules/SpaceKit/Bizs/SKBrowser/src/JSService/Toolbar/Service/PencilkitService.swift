//
//  PencilkitService.swift
//  SKBrowser
//
//  Created by zoujie on 2021/3/18.
//  

import SwiftyJSON
import SKCommon
import RxSwift
import Homeric
import LarkUIKit
import SKResource
import LarkCanvas
import EENavigator
import SKFoundation
import LKCommonsTracker
import SpaceInterface
import UniverseDesignToast
import UniverseDesignDialog
import SKInfra

public final class PencilkitService: BaseJSService {
    private(set) var callback: String?
    private var canvasVC: UIViewController?
    private var pencilKitCallback: String?
    private var needNotifyFEShowToolbar: Bool = false
    private var currentDataToken: String = ""
    //埋点上报打开画板来源
    private var isFrom: String = "doc"

    private lazy var newCacheAPI = DocsContainer.shared.resolve(NewCacheAPI.self)!
    private lazy var downloadCacheServive: SpaceDownloadCacheProtocol = DocsContainer.shared.resolve(SpaceDownloadCacheProtocol.self)!
    private lazy var downloader: DocCommonDownloadProtocol = DocsContainer.shared.resolve(DocCommonDownloadProtocol.self)!
    private let disposeBag = DisposeBag()
    // loading
    private lazy var indicator: ActivityIndicatorView = {
        return ActivityIndicatorView()
    }()

    lazy var loadingView: UIView = UIView()

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
        model.browserViewLifeCycleEvent.addObserver(self)
    }
}

extension PencilkitService: DocsJSServiceHandler {
    public var handleServices: [DocsJSService] {
        return [.changePencilKit,
                .alertDeletePencilKit,
                .alertUpdatePencilKit]
    }

    public func handle(params: [String: Any], serviceName: String) {
        if #available(iOS 13.0, *) {
            let type: DocsJSService = DocsJSService(rawValue: serviceName)
            switch type {
            case .changePencilKit:
                openPencilCanvas(params: params)
            case .alertUpdatePencilKit:
                changeAlert(params: params)
            case .alertDeletePencilKit:
                deleteAlert()
            default:
                break
            }
        }
    }

    @available(iOS 13.0, *)
    private func openPencilCanvas(params: [String: Any]) {
        guard let callback: String = params["callback"] as? String else { return }

        currentDataToken = params["token"] as? String ?? ""
        isFrom = params["from"] as? String ?? "doc"
        let canvasData: Data? = getCanvasDataFromCache(for: currentDataToken)

        requestOpenPencilCanvas(data: canvasData, callback: callback) { [weak self] in
            guard let self = self else { return }
            if canvasData == nil, !self.currentDataToken.isEmpty {
                //缓存内无数据，去后台请求数据
                self.showLoading(hasData: false)
                self.getCanvasData(token: self.currentDataToken) { [weak self] (data, error) in
                    self?.report(action: .clientPencilkitDataDownload,
                           params: ["action": error == nil ? "success" : "fail"])
                    self?.hideLoading()
                    if error == nil, data != nil {
                        self?.setCanvasData(data: data)
                    } else {
                        self?.networkErrorAlert()
                    }
                }
            }
        }
    }

    // 从自定义的缓存里面找绘图数据Data
    private func getCanvasDataFromCache(for token: String) -> Data? {
        //如果是本地上传的绘图数据，本地可能有缓存，所以先查下本地
        var canvasData: Data? = CacheService.normalCache.object(forKey: token)

        if canvasData == nil {
            DocsLogger.info("PencilkitService get data from download")
            canvasData = self.downloadCacheServive.data(key: token, type: .originFile)
        }

        return canvasData
    }

    ///请求绘图数据
    private func getCanvasData(token: String, completion: @escaping (Data?, Int?) -> Void) {
        report(action: .clientPencilkitDataDownload,
               params: ["action": "start"])
        let driveDataType = DocCommonDownloadType.originFile
        let context = DocCommonDownloadRequestContext(fileToken: token,
                                                      mountNodePoint: "",
                                                      mountPoint: "doc_image_editdata",
                                                      priority: .default,
                                                      downloadType: driveDataType,
                                                      localPath: nil,
                                                      isManualOffline: false,
                                                      dataVersion: nil,
                                                      originFileSize: nil,
                                                      fileName: nil)
        self.downloader.download(with: context)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (context) in
                let status = context.downloadStatus
                if status == .success || status == .failed {
                    if status == .success, let data = self?.downloadCacheServive.data(key: token, type: driveDataType) {
                        DocsLogger.info("downloadCanvasData drive suc, token=\(DocsTracker.encrypt(id: token)), result=success")
                        completion(data, nil)

                    } else {
                        DocsLogger.error("downloadCanvasData drive fail, token=\(DocsTracker.encrypt(id: token)) error:\(context.errorCode)")
                        completion(nil, context.errorCode)
                    }
                }
            })
            .disposed(by: self.disposeBag)
    }

    public func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {
        model?.jsEngine.callFunction(function, params: params, completion: completion)
    }

    ///画板内容更新弹框
    @available(iOS 13.0, *)
    func changeAlert(params: [String: Any]) {
        guard let token: String = params["token"] as? String,
              let presentVC = canvasVC else { return }

        report(action: .clientPencilkitTips,
               params: ["action": "change_tips"])
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.CreationMobile_Docs_iPadWhiteboard_DeletedAlready_Toast)
        dialog.setContent(text: BundleI18n.SKResource.CreationMobile_Docs_iPadWhiteboard_NewVersion_Toast, alignment: .center)

        dialog.addSecondaryButton(text: BundleI18n.SKResource.CreationMobile_Docs_iPadWhiteboard_Cancel_Button,
                        dismissCompletion: { [weak self] in
                            self?.report(action: .clientPencilkitTips,
                                         params: ["action": "change_tips_notupdate"])
                        })

        dialog.addPrimaryButton(text: BundleI18n.SKResource.CreationMobile_Docs_iPadWhiteboard_Update_Button, dismissCompletion: { [weak self] in
            self?.showLoading(hasData: true)
            self?.report(action: .clientPencilkitTips,
                   params: ["action": "change_tips_update"])
            self?.getCanvasData(token: token, completion: { (data, error) in
                self?.hideLoading()
                if error == nil, data != nil {
                    self?.setCanvasData(data: data)
                } else {
                    UDToast.showTips(with: BundleI18n.SKResource.CreationMobile_Docs_iPadWhiteboard_InternetError_Toast, on: presentVC.view)
                }
            })
        })

        model?.userResolver.navigator.present(dialog, from: presentVC, animated: true)
    }

    ///画板图片被删除弹框
    func deleteAlert() {
        guard let presentVC = canvasVC else { return }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.CreationMobile_Docs_iPadWhiteboard_DeletedAlready_Toast)
        dialog.setContent(text: BundleI18n.SKResource.CreationMobile_Docs_iPadWhiteboard_ImageDeleted_Toast, alignment: .center)
        report(action: .clientPencilkitTips,
               params: ["action": "delete_tips"])
        dialog.addPrimaryButton(text: BundleI18n.SKResource.CreationMobile_Docs_iPadWhiteboard_Confirm_Button,
                        dismissCompletion: { [weak self] in
                            self?.canvasVC?.dismiss(animated: true)
                            self?.canvasVC = nil
                            self?.notifyFECanvasViewClosed()
                            self?.report(action: .clientPencilkitTips,
                                         params: ["action": "delete_tips_click"])
                        })
        model?.userResolver.navigator.present(dialog, from: presentVC, animated: true)
    }


    ///网络错误导致绘图数据下拉失败弹框
    @available(iOS 13.0, *)
    func networkErrorAlert() {
        guard let presentVC = canvasVC else { return }
        let dialog = UDDialog()
        dialog.setTitle(text: BundleI18n.SKResource.CreationMobile_Docs_iPadWhiteboard_DeletedAlready_Toast)
        dialog.setContent(text: BundleI18n.SKResource.CreationMobile_Docs_iPadWhiteboard_InternetError_Toast, alignment: .center)
        report(action: .clientPencilkitTips,
               params: ["action": "getdata_fail_tips"])
        dialog.addSecondaryButton(text: BundleI18n.SKResource.CreationMobile_Docs_iPadWhiteboard_Leave_Button,
                        dismissCompletion: { [weak self] in
                            self?.canvasVC?.dismiss(animated: true)
                            self?.canvasVC = nil
                            self?.notifyFECanvasViewClosed()
                            self?.report(action: .clientPencilkitTips,
                                         params: ["action": "getdata_fail_tips_quit"])
                        })
        dialog.addPrimaryButton(text: BundleI18n.SKResource.CreationMobile_Docs_iPadWhiteboard_Refresh_Button, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            self.report(action: .clientPencilkitTips,
                   params: ["action": "getdata_fail_tips_retry"])
            self.showLoading(hasData: true)
            self.getCanvasData(token: self.currentDataToken, completion: { [weak self] (data, error) in
                self?.hideLoading()
                if error == nil, data != nil {
                    self?.setCanvasData(data: data)
                } else {
                    self?.networkErrorAlert()
                }
            })
        })
        model?.userResolver.navigator.present(dialog, from: presentVC, animated: true)
    }

    ///通知前端绘图白板关闭了
    func notifyFECanvasViewClosed() {
        guard let callBack = pencilKitCallback else { return }
        //browserVC进入后台会注销掉键盘监听，会在viewDidAppear重新开启键盘监听，
        //因此要在browserVC的键盘监听开启后再调用biz.toolBar.restoreEditor通知前端唤起工具栏
        needNotifyFEShowToolbar = true
        self.callFunction(DocsJSCallBack(callBack), params: nil, completion: nil)
    }

    ///打开画板
    private func requestOpenPencilCanvas(data: Data?, callback: String, completion: (() -> Void)? = nil) {
        guard #available(iOS 13.0, *) else { return }
        guard let root = ui?.hostView.window?.rootViewController,
              let from = UIViewController.docs.topMost(of: root) else { return }
        guard let token = model?.browserInfo.docsInfo?.objToken else {
            DocsLogger.error("requestOpenPencilCanvas cannot get browserInfo")
            return
        }
        pencilKitCallback = callback
        canvasVC = LKCanvasViewController(identifier: "ccm_\(token)",
                                          data: data,
                                          from: isFrom,
                                          options: [.saveNaviButton(shouldShow: false),
                                                    .clearNaviButton(shouldShow: false),
                                                    .saveOn(mode: .saveOnChanged),
                                                    .cache(provider: nil)],
                                          delegate: self)
        guard let vc = canvasVC else { return }
        model?.userResolver.navigator.present(vc, wrap: LkNavigationController.self, from: from, prepare: {
            $0.modalPresentationStyle = .fullScreen
        }, animated: true) {
            completion?()
        }
        Tracker.post(TeaEvent(Homeric.PUBLIC_WHITEBOARD_CLICK, params: ["windowtype": isFrom]))
    }

    @available(iOS 13.0, *)
    private func setCanvasData(data: Data?) {
        guard let vc = canvasVC as? LKCanvasViewController, let canvasData = data else { return }
        vc.setData(data: canvasData)
    }

    private func makeUniqueId() -> String {
        let rawUUID = UUID().uuidString
        let uuid = rawUUID.replacingOccurrences(of: "-", with: "")
        return uuid.lowercased()
    }

    @available(iOS 13.0, *)
    private func showLoading(hasData: Bool) {
        guard let vc = canvasVC as? LKCanvasViewController else { return }
        if indicator.superview == nil {
            loadingView.addSubview(indicator)
        }

        if loadingView.superview == nil {
            vc.canvas.addSubview(loadingView)
        }

        indicator.color = hasData ? UIColor.ud.colorfulBlue : UIColor.ud.N400
        loadingView.isHidden = false
        indicator.isHidden = false
        indicator.startAnimating()
        indicator.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalTo(15)
        }

        loadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        vc.canvas.canvasView.resignFirstResponder()
    }

    @available(iOS 13.0, *)
    private func hideLoading() {
        guard let vc = canvasVC as? LKCanvasViewController,
              indicator.superview != nil,
              loadingView.superview != nil else {
            return
        }
        vc.canvas.canvasView.becomeFirstResponder()
        indicator.stopAnimating()
        indicator.isHidden = true
        loadingView.isHidden = true
        loadingView.removeFromSuperview()
    }

    ///埋点上报
    private func report(action: DocsTracker.EventType, params: [String: Any]) {
        DocsTracker.log(enumEvent: action, parameters: params)
    }
}

extension PencilkitService: LKCanvasViewControllerDelegate {
    @available(iOS 13.0, *)
    public func canvasWillFinish(in controller: LKCanvasViewController,
                                 drawingImage: UIImage,
                                 canvasData: Data,
                                 canvasShouldDismissCallback: (Bool) -> Void) {
        canvasVC = nil
        canvasShouldDismissCallback(true)
        guard let callBack = pencilKitCallback else { return }

        let uuid = "fakeToken-" + makeUniqueId()

        CacheService.normalCache.set(object: canvasData, forKey: uuid)
        let cachePath = SKPickContentType.getUploadCacheUrl(uuid: uuid, pathExtension: "canvas")
        guard !cachePath.pathString.isEmpty else {
            DocsLogger.error("pencilkit get cache file path error")
            return
        }

        _ = cachePath.createFile(with: canvasData)
        
        let assetInfo = SKAssetInfo(objToken: model?.browserInfo.docsInfo?.objToken ?? "",
                                    uuid: uuid,
                                    cacheKey: uuid + ".canvas",
                                    sourceUrl: cachePath.pathString,
                                    fileSize: canvasData.count,
                                    assetType: SKPickContentType.file.rawValue)
        self.newCacheAPI.updateAsset(assetInfo)
        let simulateParams = [SKPickContent.pickContent:
                                SKPickContent.uploadCanvas(image: drawingImage,
                                                           pencilKitToken: uuid),
                              "callback": callBack] as [String: Any]
        model?.jsEngine.simulateJSMessage(DocsJSService.simulateFinishPickFile.rawValue, params: simulateParams)
    }

    @available(iOS 13.0, *)
    public func canvasDidEnter(lifeCycle: LKCanvasViewController.LifeCycle) {
        switch lifeCycle {
        case .viewDidLayout:
            guard let vc = canvasVC as? LKCanvasViewController else { return }
            vc.canvas.overrideUserInterfaceStyle = .light
            vc.canvas.toolPicker?.colorUserInterfaceStyle = .light
        case .viewDidDisappear:
            canvasVC = nil
            notifyFECanvasViewClosed()
        default:
            break
        }
    }
}

extension PencilkitService: BrowserViewLifeCycleEvent {
    public func browserDidAppear() {
        guard needNotifyFEShowToolbar else { return }
        canvasVC = nil
        needNotifyFEShowToolbar = false
        //关闭画板，通知前端进入编辑态，同时显示工具栏
        model?.jsEngine.callFunction(.setToolBar, params: nil, completion: nil)
    }
}
