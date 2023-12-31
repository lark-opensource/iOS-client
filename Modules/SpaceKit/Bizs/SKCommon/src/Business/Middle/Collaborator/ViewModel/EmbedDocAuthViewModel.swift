//
//  EmbedDocAuthViewModel.swift
//  SKCommon
//
//  Created by guoqp on 2022/3/1.
//

import Foundation
import SwiftyJSON
import HandyJSON
import SKFoundation
import RxSwift
import UniverseDesignIcon
import SKInfra

class EmbedDocAuthViewModel {
    
    enum EnabledAction {
        case grant
        case revoke
        case none
    }

    let body: EmbedDocAuthControllerBody
    private(set) var embedDocAuthListModel: EmbedDocAuthListResponse
    let permissonMgr = DocsContainer.shared.resolve(PermissionManager.self)!
    let disposeBag = DisposeBag()

    var hasPermissionCount: Int { embedDocAuthListModel.hasPermissionCount }
    var noPermissonCount: Int { embedDocAuthListModel.noPermissonCount }
    /// 可授权的文档数量
    var grantDocCount: Int { embedDocAuthListModel.embedDocs.filter { !$0.chatHasPermission && $0.senderHasSharePermission }.count }
    /// 可取消授权的文档数量
    var revokeDocCount: Int { embedDocAuthListModel.embedDocs.filter { $0.chatHasPermission && $0.senderHasSharePermission }.count }
    /// 可用的授权操作
    var enabledAction: EnabledAction {
        if grantDocCount > 0 {
            return .grant
        } else if revokeDocCount > 0 {
            return .revoke
        } else {
            return .none
        }
    }
    var embedDocs: [EmbedDoc] { embedDocAuthListModel.embedDocs }


    public init(body: EmbedDocAuthControllerBody) {
        self.body = body
        self.embedDocAuthListModel = EmbedDocAuthListResponse()
    }

    /// 获取内嵌文档列表
    public func embededDocAuthList(complete: @escaping ((EmbedAuthResult) -> Void)) {
        permissonMgr.embededDocAuthList(token: body.objToken, type: body.docsType,
                                        taskId: body.taskId, cursor: nil) { response, error in
            if let response = response {
                self.embedDocAuthListModel = response
            }
            complete(error != nil ? .AllFail : .Success([]))
        }
    }

    /// 对内嵌文档进行批量授权
    public func embededDocAuth(embedAuthModels: [EmbedAuthModel],
                               complete: @escaping ((EmbedAuthResult) -> Void)) {
        permissonMgr.embededDocAuth(token: body.objToken, embedAuthModels: embedAuthModels) { [weak self] data, error in
            guard let self = self else { return }
            guard error == nil, let data = data else {
                complete(.AllFail)
                return
            }
            complete(self.authResult(data))
        }
    }

    private func authResult(_ data: JSON) -> EmbedAuthResult {
        guard let authResLists = data["auth_res_lists"].array, !authResLists.isEmpty else {
            DocsLogger.error("auth_res_lists is nil")
            return EmbedAuthResult.AllFail
        }
        var updatedDocsToken: [String] = []
        var noPermissionDocsToken: [String] = []
        var failCount: Int = 0
        var successCount: Int = 0
        var noPermissonCount: Int = 0
        var collaboratorLimitCount: Int = 0
        var cacBlockedCount = 0

        authResLists.forEach { json in
            let authorizationResponse = json["authorization_response"]
            let authDataCode = authorizationResponse["auth_data_code"].intValue
            let errCode = authorizationResponse["err_code"].intValue
//            let errMsg = authorizationResponse["err_msg"].stringValue
            if authDataCode == 2002 {
                /// cac 管控
                cacBlockedCount += 1
            } else if authDataCode == 1, errCode == 0 {
                ///成功
                successCount += 1
                let token = json["token"].stringValue
                if !token.isEmpty {
                    updatedDocsToken.append(token)
                }
            } else {
                if errCode == 10014 {
                    ///协作者达到上限
                    collaboratorLimitCount += 1
                } else if errCode == 4 {
                    ///无权限
                    noPermissonCount += 1
                    if let token = json["token"].string, !token.isEmpty {
                        noPermissionDocsToken.append(token)
                    }
                } else {
                    ///其它错误
                    failCount += 1
                }
            }
            DocsLogger.info("authDataCode \(authDataCode) errCode \(errCode) ")
        }
        let updatedDocs: [EmbedDoc] = updateEmbedDocsPermission(updatedDocsToken, hasPermission: true, noSharePermissionTokens: noPermissionDocsToken)
        if cacBlockedCount == 1, authResLists.count == cacBlockedCount {
            /// 只针对单个授权的cac管控
            return .cacBlocked
        } else if failCount > 0, successCount > 0 {
            return .PartFail(updatedDocs)
        } else if failCount > 0 {
            return .AllFail
        } else if successCount > 0 {
            return .Success(updatedDocs)
        } else if noPermissonCount > 0 {
            return .NoPermisson
        } else if collaboratorLimitCount > 0 {
            return .CollaboratorLimit
        } else {
            return .AllFail
        }
    }

    private func cancelAuthResult(_ data: JSON) -> EmbedAuthResult {
        guard let authResLists = data["auth_res_lists"].array, !authResLists.isEmpty else {
            DocsLogger.error("auth_res_lists is nil")
            return EmbedAuthResult.AllFail
        }
        var updatedDocsToken: [String] = []
        var noPermissionDocsToken: [String] = []
        var failCount: Int = 0
        var successCount: Int = 0
        var noPermissonCount: Int = 0

        authResLists.forEach { json in
            let authorizationResponse = json["authorization_response"]
            let authDataCode = authorizationResponse["auth_data_code"].intValue
            let errCode = authorizationResponse["err_code"].intValue
//            let errMsg = authorizationResponse["err_msg"].stringValue
            if authDataCode == 1, errCode == 0 {
                ///成功
                successCount += 1
                let token = json["token"].stringValue
                if !token.isEmpty {
                    updatedDocsToken.append(token)
                }
            } else {
                if errCode == 10014 {
                    ///协作者达到上限
                    failCount += 1
                } else if errCode == 4 {
                    ///无权限
                    noPermissonCount += 1
                    if let token = json["token"].string, !token.isEmpty {
                        noPermissionDocsToken.append(token)
                    }
                } else {
                    ///其它错误
                    failCount += 1
                }
            }
            DocsLogger.info("authDataCode \(authDataCode) errCode \(errCode) ")
        }

        let updatedDocs: [EmbedDoc] = updateEmbedDocsPermission(updatedDocsToken, hasPermission: false, noSharePermissionTokens: noPermissionDocsToken)
        if failCount > 0, successCount > 0 {
            return .PartFail(updatedDocs)
        } else if failCount > 0 {
            return .AllFail
        } else if successCount > 0 {
            return .Success(updatedDocs)
        } else if noPermissonCount > 0 {
            return .NoPermisson
        } else {
            return .AllFail
        }
    }

    ///本地更新数据源权限
    private func updateEmbedDocsPermission(_ tokens: [String], hasPermission: Bool, noSharePermissionTokens: [String]) -> [EmbedDoc] {
        let tempEmbedDocs = embedDocs
        var updatedDocs: [EmbedDoc] = []
        var hasPermissionCount: Int = 0
        var noPermissonCount: Int = 0
        tempEmbedDocs.forEach { doc in
            if tokens.contains(doc.objectToken) {
                doc.chatHasPermission = hasPermission ? true : false
                updatedDocs.append(doc)
            }
            if noSharePermissionTokens.contains(doc.objectToken) {
                doc.senderHasSharePermission = false
            }
            if doc.chatHasPermission {
                hasPermissionCount += 1
            } else {
                noPermissonCount += 1
            }
        }

        self.embedDocAuthListModel.clear()
        self.embedDocAuthListModel.hasPermissionCount = hasPermissionCount
        self.embedDocAuthListModel.noPermissonCount = noPermissonCount
        self.embedDocAuthListModel.addEmbedDocs(nodes: tempEmbedDocs)
        return updatedDocs
    }

    ///对文档进行批量取消授权
    public func embededDocCancelAuth(embedAuthModels: [EmbedAuthModel],
                                     complete: @escaping ((EmbedAuthResult) -> Void)) {
        permissonMgr.embededDocCancelAuth(token: body.objToken, embedAuthModels: embedAuthModels) { [weak self] data, error in
            guard let self = self else { return }
            guard error == nil, let data = data else {
                complete(.AllFail)
                return
            }
            complete(self.cancelAuthResult(data))
        }
    }
    /// 记录内嵌文档授权状态
    public func embedDocRecord(status: [EmbedAuthRecodeStatus],
                               complete: @escaping ((Bool) -> Void)) {
        permissonMgr.embedDocRecord(token: body.objToken, type: body.docsType,
                                    taskId: body.taskId, status: status) { ret, _ in
            complete(ret)
        }
    }
    ///更新内嵌文档卡片状态
    public func embededDocUpdateCard(complete: @escaping ((Bool) -> Void)) {
        permissonMgr.embededDocUpdateCard(token: body.objToken, type: body.docsType,
                                          taskId: body.taskId) { ret, _ in
            complete(ret)
        }
    }
    
    // 修改全部内嵌文档的授权
    private func modifyAllAccess(isGrant: Bool,
                      embedAuthModels: [EmbedAuthModel],
                      complete: @escaping ((EmbedAuthResult) -> Void)) {
        // 因为接口最多只能一次授权或取消50篇文档，当操作文档数量超过50篇时，需要连续调用多次接口
        // 1.先对操作文档进行分组，每组最大50篇
        // 2.对每组models进行转换，每组各转成一次网络请求
        // 3.对所有网络请求进行zip
        // 4.将多个请求返回的results聚合成一个result
        Observable<EmbedAuthModel>.from(embedAuthModels)
            .buffer(timeSpan: .never, count: 50, scheduler: MainScheduler.asyncInstance)
            .toArray()
            .flatMap { group -> Single<EmbedAuthResult> in
                return .zip(group.map({ docs -> Single<EmbedAuthResult> in
                        return .create { [weak self] observer in
                            if isGrant {
                                self?.embededDocAuth(embedAuthModels: docs) { result in
                                    observer(.success(result))
                                }
                            } else {
                                self?.embededDocCancelAuth(embedAuthModels: docs) { result in
                                    observer(.success(result))
                                }
                            }
                            return Disposables.create()
                        }
                    })).map { results -> EmbedAuthResult in
                    // 将多个请求返回的result聚合成一个result
                    // 1.先将多个result中返回的成功doc都放入到successfulDocs中
                    // 2.通过successfulDocs的数量和最初请求时的embedAuthModels的数量做对比判断出最终的result
                    var successfulDocs: [EmbedDoc] = []
                    results.forEach { result in
                        switch result {
                        case let .Success(docs):
                            successfulDocs.append(contentsOf: docs)
                        case let .PartFail(docs):
                            successfulDocs.append(contentsOf: docs)
                        case .NoPermisson:
                            DocsLogger.error("modifyAllAccess noPermisson")
                        case .CollaboratorLimit:
                            DocsLogger.error("modifyAllAccess collaboratorLimit")
                        case .AllFail:
                            DocsLogger.error("modifyAllAccess allFail")
                        case .cacBlocked:
                            DocsLogger.error("modifyAllAccess cacBlocked")
                        }
                    }
                    
                    if successfulDocs.count == 0 {
                        return .AllFail
                    } else if successfulDocs.count == embedAuthModels.count {
                        return .Success(successfulDocs)
                    } else {
                        return .PartFail(successfulDocs)
                    }
                }
            }.subscribe { result in
                complete(result)
            }.disposed(by: disposeBag)
    }
    
    // 全部授权
    func grantAllAccess(embedAuthModels: [EmbedAuthModel],
                        complete: @escaping ((EmbedAuthResult) -> Void)) {
        modifyAllAccess(isGrant: true, embedAuthModels: embedAuthModels, complete: complete)
    }
    
    // 全部撤销授权
    func revokeAllAccess(embedAuthModels: [EmbedAuthModel],
                        complete: @escaping ((EmbedAuthResult) -> Void)) {
        modifyAllAccess(isGrant: false, embedAuthModels: embedAuthModels, complete: complete)
    }
}
