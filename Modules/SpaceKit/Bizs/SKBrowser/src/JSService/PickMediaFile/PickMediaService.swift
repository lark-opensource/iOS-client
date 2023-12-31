//
//  PickMediaService.swift
//  SpaceKit
//
//  Created by weidong fu on 2018/11/20.
//

import SKFoundation
import LarkUIKit
import Photos
import Kingfisher
import SKCommon
import UniverseDesignToast
import ByteWebImage
import SKResource
import SKInfra

final class PickMediaService: NSObject {
    weak var model: BrowserModelConfig?
    weak var ui: BrowserUIConfig?
    weak var tool: BrowserToolConfig?
    private var cameraCallback: ((UIImage) -> Void)?
    private weak var resolver: DocsResolver?
    private let picMaxSize: Int = 20 * 1024 * 1024
    lazy private var newCacheAPI: NewCacheAPI = resolver!.resolve(NewCacheAPI.self)!
    private var pickMediaCallBack: String = ""

    private lazy var pickImagePlugin: SkBasePickImagePlugin = {
        let config = SkBasePickImagePluginConfig(newCacheAPI)
        let plugin = SkBasePickImagePlugin(config)
        plugin.objToken = self.model?.browserInfo.docsInfo?.objToken
        plugin.pluginProtocol = self
        return plugin
    }()

    private lazy var pickVideoPlugin: SKBasePickVideoPlugin = {
        let config = SKBasePickVideoPluginConfig(newCacheAPI)
        let plugin = SKBasePickVideoPlugin(config)
        plugin.objToken = self.model?.browserInfo.docsInfo?.objToken
        plugin.pluginProtocol = self
        return plugin
    }()

    init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?, tool: BrowserToolConfig, _ resolver: DocsResolver = DocsContainer.shared) {
        self.ui = ui
        self.model = model
        self.tool = tool
        self.resolver = resolver
    }
}

extension PickMediaService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.pickImage, .selectMedia, .simulateFinishPickFile]
    }

    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("handle, serviceName=\(serviceName)", component: LogComponents.pickFile)
        let service = DocsJSService(serviceName)
        switch service {
        case .pickImage, .selectMedia:
            if let method = params["callback"] as? String {
                pickMediaCallBack = method
            } else {
                DocsLogger.info("pickMedia: lost js call back method", component: LogComponents.pickFile)
            }
        case .simulateFinishPickFile:
            guard let content = params[SKPickContent.pickContent] as? SKPickContent else {
                DocsLogger.info("simulateFinishPickFile, content=nil", component: LogComponents.pickFile)
                return
            }
            if let method = params["callback"] as? String {
                pickMediaCallBack = method
            } else {
                DocsLogger.info("pickMedia: lost js call back method", component: LogComponents.pickFile)
            }
            handleSimulatePickFile(content: content)
        default:
            break
        }
    }

    func handleSimulatePickFile(content: SKPickContent) {
        switch content {
        case let .asset(assets, original):
            self.handleAsset(assets: assets, original: original)
        case .takePhoto(let photo):
            self.handleTakePhoto(photo: photo)
        case .takeVideo(let videoUrl):
            self.handleTakeVideo(video: videoUrl)
        case let .uploadCanvas(image, pencilKitToken):
            self.handleUploadCanvasData(image: image, pencilKitToken: pencilKitToken)
        default: break
        }
    }

    func handleAsset(assets: [PHAsset], original: Bool) {
        let videoAssets = assets.filter { (asset) -> Bool in
            return asset.mediaType == .video
        }
        let imageAssets = assets.filter { (asset) -> Bool in
            return asset.mediaType == .image
        }
        DispatchQueue.global().async {
            if imageAssets.count > 0 {
                self.handleImageAsset(imageAssets: imageAssets, original: original)
            }
            if videoAssets.count > 0 {
                self.handleVideoAssets(videoAssets: videoAssets)
            }
        }
    }

    func handleUploadCanvasData(image: UIImage, pencilKitToken: String) {
        let image = image.sk.fixOrientation()
        let imageInfo = SkPickImagePreInfo(image: image, oriData: nil, picFormat: ImageFormat.unknown)
        let params = [SkBasePickImagePlugin.imagesInfoKey: [imageInfo],
                      SkBasePickImagePlugin.OriginalInfoKey: false,
                      "pencilKitToken": pencilKitToken] as [String: Any]
        pickImagePlugin.handle(params: params, serviceName: DocsJSService.simulateFinishPickingImage.rawValue)
    }

    func handleImageAsset(imageAssets: [PHAsset], original: Bool) {
        SKPickImageUtil.handleImageAsset(assets: imageAssets, original: original, token: PSDATokens.DocX.docx_insert_image_click_upload) { [weak self] info in
            if let info {
                let params = [SkBasePickImagePlugin.imagesInfoKey: info,
                             SkBasePickImagePlugin.OriginalInfoKey: original] as [String: Any]
                self?.pickImagePlugin.handle(params: params, serviceName: DocsJSService.simulateFinishPickingImage.rawValue)
            } else {
                DocsLogger.info("pickMedia: pic, reachMaxSize", component: LogComponents.pickFile)
                self?.showFailedTips(BundleI18n.SKResource.CreationMobile_Docs_DocCover_ExceedFileSize_Toast)
            }
        }
    }

    func handleTakePhoto(photo: UIImage) {
        let image = photo.sk.fixOrientation()
        let imageInfo = SkPickImagePreInfo(image: image, oriData: nil, picFormat: ImageFormat.unknown)
        let params = [SkBasePickImagePlugin.imagesInfoKey: [imageInfo],
                      SkBasePickImagePlugin.OriginalInfoKey: false] as [String: Any]
        pickImagePlugin.handle(params: params, serviceName: DocsJSService.simulateFinishPickingImage.rawValue)
    }

    func handleVideoAssets(videoAssets: [PHAsset]) {
        let params = [SKBasePickVideoPlugin.videoInfoKey: SKPickContent.asset(assets: videoAssets, original: false)]
        pickVideoPlugin.handle(params: params, serviceName: DocsJSService.simulatePickVideo.rawValue)
    }

    func handleTakeVideo(video: URL) {
        let params = [SKBasePickVideoPlugin.videoInfoKey: SKPickContent.takeVideo(videoUrl: video)]
        pickVideoPlugin.handle(params: params, serviceName: DocsJSService.simulatePickVideo.rawValue)
    }

    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((_ info: Any?, _ error: Error?) -> Void)?) {

        self.model?.jsEngine.callFunction(function, params: params, completion: completion)
    }
}

extension PickMediaService: SkBasePickImagePluginProtocol {

    func callBackAfterPickImage(params: [String: Any]) {
        self.callFunction(DocsJSCallBack(pickMediaCallBack), params: params, completion: nil)
    }

    func pickImagePluginFinishJsInsert(plugin: SkBasePickImagePlugin) {
        //图片选中后改为保留工具栏，键盘状态，不自动隐藏 v4.4又重新改为自动隐藏
//         self.tool?.toolBar.requestHideToolBar(item: nil)
    }
}

extension PickMediaService: SKBasePickVideoPluginProtocol {

    func pickVideoPluginFinishJsInsert(plugin: SKBasePickVideoPlugin) {
    }

    func callBackAfterPickVideo(params: [String: Any]) {
        self.callFunction(DocsJSCallBack(pickMediaCallBack), params: params, completion: nil)
    }

    func showFailedTips(_ text: String) {
        DispatchQueue.main.async {
            guard let showOnVc = self.ui?.hostView.affiliatedViewController as? BrowserViewController else {
                return
            }
            UDToast.showFailure(with: text, on: showOnVc.view)
        }
    }
}
