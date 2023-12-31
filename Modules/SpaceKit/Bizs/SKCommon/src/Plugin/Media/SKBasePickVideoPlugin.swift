//
//  SKBasePickVideoPlugin.swift
//  SKCommon
//
//  Created by chenhuaguan on 2020/11/26.
//

import SKFoundation
import Photos
import RxSwift
import SKUIKit
import SKResource
import SpaceInterface


public struct SKBasePickVideoPluginConfig {
    let cache: SKCacheService
    public init(_ cache: SKCacheService) {
        self.cache = cache
    }
}

public protocol SKBasePickVideoPluginProtocol: SKExecJSFuncService {
    func pickVideoPluginFinishJsInsert(plugin: SKBasePickVideoPlugin)
    func callBackAfterPickVideo(params: [String: Any])
    func showFailedTips(_ text: String)
}

public final class SKBasePickVideoPlugin: JSServiceHandler {
    public static let videoInfoKey = "videoInfoKey"
    public var config: SKBasePickVideoPluginConfig
    public weak var pluginProtocol: SKBasePickVideoPluginProtocol?
    public var objToken: String?
    private var pickVideoMethod: String = ""
    private var parser: SKVideoParser!
    private let disposeBag = DisposeBag()
    private var videoInfo: [SKVideoParser.Info] = []
    #if DEBUG
    private var uploadAdapt = UploadFileAdapter()
    #endif


    public init(_ config: SKBasePickVideoPluginConfig) {
        self.config = config
        self.parser = SKVideoParser()

    }

    public var handleServices: [DocsJSService] = [.simulatePickVideo]

    public func handle(params: [String: Any], serviceName: String) {
        let service = DocsJSService(rawValue: serviceName)
        switch service {
        case .simulatePickVideo:
            videoInfo.removeAll()
            if let content = params[SKBasePickVideoPlugin.videoInfoKey] as? SKPickContent {
                DocsLogger.info("SKBasePickVideoPlugin, ", component: LogComponents.pickFile)
                switch content {
                case let .asset(assets, _):
                    DocsLogger.info("SKBasePickVideoPlugin, assets.count=\(assets.count)", component: LogComponents.pickFile)
                    self.handleAsset(assets: assets)
                case .takeVideo(let videoUrl):
                    DocsLogger.info("SKBasePickVideoPlugin, takeVideo", component: LogComponents.pickFile)
                    self.handleTakeVideo(videlUrl: videoUrl)
                default:
                    break
                }
            } else {
                DocsLogger.info("SKBasePickVideoPlugin, data err", component: LogComponents.pickFile)
            }
        default:
            ()
        }

    }

    func handleAsset(assets: [PHAsset]) {
        var allCount = assets.count
        assets.forEach { (asset) in
            self.parserVideo(asset: asset) { suc in
                if suc {
                    allCount -= 1
                    if allCount == 0 {
                        self.handleAfterParser()
                    }
                }
            }
        }
    }

    func handleTakeVideo(videlUrl: URL) {
        self.parserVideo(videlUrl: videlUrl) { _ in
            self.handleAfterParser()
        }
    }

    func handleAfterParser() {
        var transformArray: [String] = []
        self.videoInfo.forEach { (info) in
            let transformsStr = self.makeCallBackInfoParas(info)
            transformsStr.map { transformArray.append($0) }
        }
        if let callBackParams = self.makeResJson(images: transformArray, code: 0) {
            DocsLogger.info("pickFile: call Back, transformCount=\(transformArray.count)", component: LogComponents.pickFile)
            self.pluginProtocol?.callBackAfterPickVideo(params: callBackParams)
        }
        self.pluginProtocol?.pickVideoPluginFinishJsInsert(plugin: self)
    }

    func parserVideo(videlUrl: URL? = nil, asset: PHAsset? = nil, complete: @escaping (Bool) -> Void) {
        var ob: Observable<SKVideoParser.Info>?
        if let videlUrl = videlUrl {
            ob = self.parser.parserVideo(with: videlUrl)
        } else if let asset = asset {
            ob = self.parser.parserVideo(with: asset)
        }
        ob?.subscribe(onNext: { [weak self] (info) in
            var suc = false
            switch info.status {
            case .fillBaseInfo:
                DocsLogger.info("pick video: end task, status=\(info.status), info=\(info)", component: LogComponents.pickFile)
                self?.videoInfo.append(info)
                self?.saveAssetInfo(info)
                suc = true
            case .reachMaxSize:
                DocsLogger.info("pick video: reach limit, status=\(info.status)", component: LogComponents.pickFile)
                self?.pluginProtocol?.showFailedTips(BundleI18n.SKResource.CreationMobile_Upload_Error_File_TooLarge_Tips)
            default:
                DocsLogger.error("pick video: Error! parse video get 'default' case", component: LogComponents.pickFile)
            }
            complete(suc)
        }, onError: { [weak self] (error) in
            DocsLogger.error("pick video: parse video error 1", error: error, component: LogComponents.pickFile)
            if let pickErr = error as? SKVideoParser.PError {
                switch pickErr {
                case .loadAVAssetIsInCloudError:
                    self?.pluginProtocol?.showFailedTips(BundleI18n.SKResource.CreationMobile_Docs_CantUpload_iCloudVideo_Tips)
                default :
                    self?.pluginProtocol?.showFailedTips(BundleI18n.SKResource.LarkCCM_Docs_CantUploadFileBlock_Mob)
                }
            }
            complete(false)
        }).disposed(by: disposeBag)
    }

    private func saveAssetInfo(_ info: SKVideoParser.Info) {
        let fileUrl = URL(string: info.docSourcePath)
        let lastCompoment: String = fileUrl?.lastPathComponent ?? ""
        let assetInfo = SKAssetInfo(objToken: self.objToken, uuid: info.uuid, cacheKey: lastCompoment, fileSize: Int(info.filesize), assetType: SKPickContentType.video.rawValue)
        self.config.cache.updateAsset(assetInfo)
        #if DEBUG
        //self.simulateUploadWithInfo(info)
        #endif
    }

    private func makeCallBackInfoParas(_ info: SKVideoParser.Info) -> String? {
        let res = ["uuid": info.uuid,
                   "contentType": "video",
                   "src": info.docSourcePath,
                   "duration": Int(info.duration),
                   "fileSize": info.filesize,
                   "fileName": info.name,
                   "width": info.width,
                   "height": info.height
                   ] as [String: Any]
        return res.jsonString
    }


    private func makeResJson(images imageArr: [String], code: Int) -> [String: Any]? {
        return ["code": code,
                "thumbs": imageArr] as [String: Any]
    }

}
