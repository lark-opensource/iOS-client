//
//  PickFileService.swift
//  SKBrowser
//
//  Created by chenhuaguan on 2020/12/4.
//

import SKFoundation
import SKCommon
import RxSwift
import SKUIKit
import SKResource
import UniverseDesignToast
import SpaceInterface
import SKInfra

final class PickFileService: BaseJSService {
    private var parser: SKFileParser!
    private let disposeBag = DisposeBag()
    private var fileInfos: [URL: SKFileParser.Info] = [:]
    private var fileUrls: [URL] = []
    lazy private var newCacheAPI: NewCacheAPI = DocsContainer.shared.resolve(NewCacheAPI.self)!
    private var callBackMethod: String = ""


    #if DEBUG
    private var uploadAdapt = UploadFileAdapter()
    #endif

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        self.parser = SKFileParser()
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension PickFileService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.selectFile]
    }

    func handle(params: [String: Any], serviceName: String) {
        DocsLogger.info("handle, serviceName=\(serviceName)", component: LogComponents.pickFile)
        let service = DocsJSService(serviceName)
        switch service {
        case .selectFile:
            if let method = params["callback"] as? String {
                callBackMethod = method
            } else {
                DocsLogger.info("pickFile: lost js call back method", component: LogComponents.pickFile)
            }
            self.showDocumentPickerViewController()
        default:
            break
        }
    }

    private func showDocumentPickerViewController() {
        let documentPicker = DocsDocumentPickerViewController(deletage: self)
        if SKDisplay.pad {
            documentPicker.modalPresentationStyle = .formSheet
            self.navigator?.presentViewController(documentPicker, animated: false, completion: nil)
        } else {
            self.navigator?.presentClearViewController(documentPicker, animated: false)
        }
    }

    private func makeCallBackInfoParas(_ info: SKFileParser.Info) -> String? {
        let res = ["uuid": info.uuid,
                   "contentType": info.fileType,
                   "src": info.docSourcePath,
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

extension PickFileService: DocsDocumentPickerDelegate {
    func pickDocumentFinishSelect(urls: [URL]) {
        fileInfos.removeAll()
        fileUrls = urls
        DocsLogger.info("pickDocumentFinishSelect, file.count=\(urls.count)", component: LogComponents.pickFile)
        handleDocumentUrls(urls)
    }

}

extension PickFileService {
    func handleDocumentUrls(_ urls: [URL]) {
        var allCount = urls.count
        urls.forEach { (url) in
            self.parserUrl(url: url) { suc in
                if suc {
                    allCount -= 1
                    if allCount == 0 {
                        self.handleAfterParser()
                    }
                }
            }
        }
    }


    func handleAfterParser() {
        var transformArray: [String] = []
        self.fileUrls.forEach { (url) in
            let info = self.fileInfos[url]
            if let info = info {
                let transformsStr = self.makeCallBackInfoParas(info)
                transformsStr.map { transformArray.append($0) }
            }
        }
        if let callBackParams = self.makeResJson(images: transformArray, code: 0) {
            DocsLogger.info("pickFile: call Back, transformCount=\(transformArray.count)", component: LogComponents.pickFile)
            self.model?.jsEngine.callFunction(DocsJSCallBack(callBackMethod), params: callBackParams, completion: nil)
        }
    }

    func parserUrl(url: URL, complete: @escaping (Bool) -> Void) {
        self.parser.parserFile(with: url).subscribe(onNext: { [weak self] (info) in
            var suc = false
            switch info.status {
            case .fillBaseInfo:
                DocsLogger.info("pick file: end task, status=\(info.status), info=\(info)", component: LogComponents.pickFile)
                self?.fileInfos.updateValue(info, forKey: url)
                self?.saveAssetInfo(info)
                suc = true
            case .reachMaxSize:
                DocsLogger.info("pick file: reach limit, status=\(info.status)", component: LogComponents.pickFile)
                self?.showTips(BundleI18n.SKResource.CreationMobile_Upload_Error_File_TooLarge_Tips)
            default:
                DocsLogger.error("pick file: Error! parse file get 'default' case", component: LogComponents.pickFile)
            }
            complete(suc)
        }, onError: { [weak self] (error) in
            DocsLogger.error("pick file: parse video error 1", error: error, component: LogComponents.pickFile)
            self?.showTips(BundleI18n.SKResource.LarkCCM_Docs_CantUploadFileBlock_Mob)
            complete(false)
        }).disposed(by: disposeBag)
    }

    private func showTips(_ text: String) {
        DispatchQueue.main.async {
            guard let showOnVc = self.registeredVC as? BrowserViewController else {
                return
            }
            UDToast.showFailure(with: text, on: showOnVc.view)
        }
    }

    private func saveAssetInfo(_ info: SKFileParser.Info) {
        let objToken = self.model?.browserInfo.docsInfo?.objToken
        let fileUrl = URL(string: info.docSourcePath)
        let lastCompoment: String = fileUrl?.lastPathComponent ?? ""
        let assetInfo = SKAssetInfo(objToken: objToken, uuid: info.uuid, cacheKey: lastCompoment, fileSize: Int(info.filesize), assetType: SKPickContentType.file.rawValue)
        self.newCacheAPI.updateAsset(assetInfo)
    }
}
