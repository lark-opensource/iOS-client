//
//  InternalDocAPI.swift
//  SpaceKit
//
//  Created by bytedance on 2019/11/27.
//

import Foundation
import RustPB
import LarkRustClient
import RxSwift
import SKUIKit
import SKFoundation
import SwiftyJSON
import SpaceInterface
import SKCommon
import SKInfra

//private typealias Doc = RustPB.Basic_V1_Doc

private var rustClient = DocsContainer.shared.resolve(RustService.self)!

private struct MetaDocInfo {
    var type: DocsType
    var token: String
    var title: String
    var url: String?
    var iconType: Int?
    var iconKey: String?
    var iconFsunit: String?
    var inherentType: DocsType?
    var iconInfo: String?
    //源文档的token和type
    var pageType: DocsType?
    var pageTitle: String?
}

public enum LinkToTitleError: Error {
    case requestErr
    case transformFailure
}

public struct InternalDocAPI {

    private let disposeBag = DisposeBag()
    public init() {}

    public func getAtInfoByURL(_ url: String) -> Observable<Result<AtInfo, Error>> {
        Observable.create { (observer) -> Disposable in
            let observable: Observable<Result<MetaDocInfo, Error>>
            if UserScopeNoChangeFG.LJW.batchMetaEnabled {
                observable = self.requestDocsInfoV2(url)
            } else {
                observable = self.requestDocsInfo(url)
            }
            observable.subscribe(onNext: { result in
                    switch result {
                        case .success(let metaInfo):
                            if let atInfo = self.transformDocToAtInfo(metaInfo) {
                                observer.onNext(.success(atInfo))
                            } else {
                                observer.onNext(.failure(LinkToTitleError.transformFailure))
                            }
                        case .failure(let error):
                            observer.onNext(.failure(error))
                    }
                    observer.onCompleted()

                }, onError: { error in
                    observer.onNext(.failure(error))
                    observer.onCompleted()
                }).disposed(by: self.disposeBag)
            return Disposables.create()
        }
    }
}

private struct RequestInfo {
    let params: [String: Any]
    let docInfo: (token: String, type: DocsType)
    let blockInfo: (token: String, type: DocsType)?
}

extension InternalDocAPI {

    private func requestDocsInfo(_ urlStr: String) -> Observable<Result<MetaDocInfo, Error>> {
        guard let url = URL(string: urlStr),
            let fileType = DocsUrlUtil.getFileType(from: url),
            let token = DocsUrlUtil.getFileToken(from: url) else {
            DocsLogger.error("requestDocsInfo，getInfo err")
            return Observable.create { (observer) -> Disposable in
                observer.onNext(.failure(LinkToTitleError.requestErr))
                observer.onCompleted()
                return Disposables.create()
            }
        }
        let params: [String: Any] = ["type": fileType.rawValue,
                                     "token": token]

        return Observable<Result<MetaDocInfo, Error>>.create { (observer) -> Disposable in
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.findMeta, params: params)
               .set(method: .GET)
               .start { (info, err) in
                   if let err = err {
                       observer.onNext(.failure(err))
                       observer.onCompleted()
                       DocsLogger.info("Request DocsInfo error \(err)")
                   } else {
                        let code = info?["code"].int ?? 0
                        DocsLogger.info("requestDocsInfo, code=\(code)")
                        if code == 0 {
                            let metaDocsInfo = self.transformToMetaInfo(info, type: fileType, token: token)
                            observer.onNext(.success(metaDocsInfo))
                            observer.onCompleted()
                        } else {
                            observer.onNext(.failure(LinkToTitleError.requestErr))
                            observer.onCompleted()
                        }
                  }
               }
            request.makeSelfReferenced()
            return Disposables.create()
        }
    }

    private func transformToMetaInfo(_ metaJson: JSON?, type: DocsType, token: String) -> MetaDocInfo {
        let title = metaJson?["data"]["title"].string ?? ""
        let url = metaJson?["data"]["url"].string
        let iconType = metaJson?["data"]["icon_type"].int
        let iconKey = metaJson?["data"]["icon_key"].string
        let iconFsunit = metaJson?["data"]["icon_fsunit"].string
        var inherentType: DocsType?
        if let typeValue = metaJson?["data"]["type"].int {
            inherentType = DocsType(rawValue: typeValue)
        }
        var metaInfo = MetaDocInfo(type: type, token: token, title: title, url: url, inherentType: inherentType)
        metaInfo.iconKey = iconKey
        metaInfo.iconType = iconType
        metaInfo.iconFsunit = iconFsunit
        return metaInfo
    }

    private func requestDocsInfoV2(_ urlStr: String) -> Observable<Result<MetaDocInfo, Error>> {
        
        guard let requestInfo = transformToRequestInfo(urlStr) else {
            return Observable.create { (observer) -> Disposable in
                observer.onNext(.failure(LinkToTitleError.requestErr))
                observer.onCompleted()
                return Disposables.create()
            }
        }
        return Observable<Result<MetaDocInfo, Error>>.create { (observer) -> Disposable in
            //meta请求改为批量接口
            let request = DocsRequest<JSON>(path: OpenAPI.APIPath.batchMeta, params: requestInfo.params)
               .set(method: .POST)
               .set(headers: ["Content-Type": "application/json"])
               .set(encodeType: .jsonEncodeDefault)
               .start(result: { (info, err) in
                   if let err = err {
                       observer.onNext(.failure(err))
                       observer.onCompleted()
                       DocsLogger.info("Request DocsInfo error \(err)")
                   } else {
                        let code = info?["code"].int ?? 0
                        DocsLogger.info("requestDocsInfo, code=\(code)")
                        if code == 0 {
                            var metaDocsInfo: MetaDocInfo
                            let docInfo = self.transformToMetaInfoV2(info,
                                                                   type: requestInfo.docInfo.type,
                                                                   token: requestInfo.docInfo.token)
                            metaDocsInfo = docInfo
                            if let blockInfo = requestInfo.blockInfo {
                                let blockInfo = self.transformToMetaInfoV2(info,
                                                                         type: blockInfo.type,
                                                                         token: blockInfo.token)
                                metaDocsInfo = blockInfo
                                //内部的block链接（如画板）需要记录源文档的token和type
                                metaDocsInfo.pageTitle = docInfo.title
                                metaDocsInfo.pageType = docInfo.type
                            }
                            observer.onNext(.success(metaDocsInfo))
                            observer.onCompleted()
                        } else {
                            observer.onNext(.failure(LinkToTitleError.requestErr))
                            observer.onCompleted()
                        }
                  }
               })
            request.makeSelfReferenced()
            return Disposables.create()
        }
    }

    private func transformToMetaInfoV2(_ metaJson: JSON?, type: DocsType, token: String) -> MetaDocInfo {
        let title = metaJson?["data"][token]["title"].string ?? ""
        let url = metaJson?["data"][token]["url"].string
        let iconType = metaJson?["data"][token]["icon_type"].int
        let iconKey = metaJson?["data"][token]["icon_key"].string
        let iconFsunit = metaJson?["data"][token]["icon_fsunit"].string
        var inherentType: DocsType?
        if let typeValue = metaJson?[token]["data"]["type"].int {
            inherentType = DocsType(rawValue: typeValue)
        }
        let iconInfo = metaJson?["data"]["icon_info"].string
        var metaInfo = MetaDocInfo(type: type, token: token, title: title, url: url, inherentType: inherentType)
        metaInfo.iconKey = iconKey
        metaInfo.iconType = iconType
        metaInfo.iconFsunit = iconFsunit
        metaInfo.iconInfo = iconInfo
        return metaInfo
    }

    private func transformToRequestInfo(_ urlStr: String) -> RequestInfo? {
        var encodeUrlStr = urlStr
        if !UserScopeNoChangeFG.LJW.urlEncodeDisabled {
            encodeUrlStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlStr
        }
        guard let url = URL(string: encodeUrlStr) else {
            DocsLogger.error("requestDocsInfo，get url err")
            return nil
        }
        let (token, fileType) = DocsUrlUtil.getFileInfoNewFrom(url)
        guard let fileType, let token else {
            DocsLogger.error("requestDocsInfo，get docInfo err")
            return nil
        }
        var tokens: [String: [String]] = [String(fileType.rawValue): [token]]
        var blockInfo: (String, DocsType)? = nil
        if let query = url.docs.queryParams,
           let blockType = DocsType(name: query["blockType"] ?? ""),
           let blockToken = query["blockToken"] {
            let typeStr = String(blockType.rawValue)
            tokens[typeStr] = tokens[typeStr] ?? []
            tokens[typeStr]?.append(blockToken)
            blockInfo = (blockToken, blockType)
        }
        let params: [String: Any] = ["tokens": tokens]
        return RequestInfo(params: params, docInfo: (token, fileType), blockInfo: blockInfo)
    }

    private func transformDocToAtInfo(_ metaInfo: MetaDocInfo) -> AtInfo? {
        let iconInfo: RecommendData.IconInfo? = {
            let fileEntryIconType = SpaceEntry.IconType(rawValue: metaInfo.iconType ?? 0) ?? SpaceEntry.IconType.unknow
            return RecommendData.IconInfo(type: fileEntryIconType, key: metaInfo.iconKey ?? "", fsunit: metaInfo.iconFsunit ?? "")
        }()
        var docName = metaInfo.title.isEmpty ? metaInfo.type.untitledString : metaInfo.title
        if var pageTitle = metaInfo.pageTitle, let pageType = metaInfo.pageType {
            //有pageTitle说明是源文档的子block
            pageTitle = pageTitle.isEmpty ? pageType.untitledString : pageTitle
            docName = pageTitle + " > " + docName
        }
        let atInfo = AtInfo(
            type: docTypeToAtType(metaInfo.type),
            href: metaInfo.url ?? "",
            token: metaInfo.token,
            at: docName,
            icon: iconInfo
        )
        atInfo.iconInfoMeta = metaInfo.iconInfo
        atInfo.subType = metaInfo.inherentType?.toAtType
        return atInfo
    }

    private func docTypeToAtType(_ docType: DocsType) -> AtType {
        var res: AtType = .unknown
        switch docType {
            case .doc:
                res = .doc
            case .sheet:
                res = .sheet
            case .bitable:
                res = .bitable
            case .mindnote:
                res = .mindnote
            case .file:
                res = .file
            case .slides:
                res = .slides
            case .wiki:
                res = .wiki
            case .unknown:
                res = .unknown
            case .docX:
                res = .docx
            case .whiteboard:
                res = .whiteboard
            default:
                res = .unknown
        }
        return res
    }
}
