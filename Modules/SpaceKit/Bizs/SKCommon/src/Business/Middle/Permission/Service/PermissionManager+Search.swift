//
//  PermissionManager+Search.swift
//  SKCommon
//
//  Created by CJ on 2021/2/18.
//

import Foundation
import SKFoundation
import SKResource
import RxSwift
import SwiftyJSON
import SKInfra

public struct CollaboratorCandidatesRequestContext {
    public let query: String
    public let offset: Int
    public let count: Int
    public let docsTypeValue: Int?
    public let objToken: String?
    public let shouldSearchOrganization: Bool
    public let shouldSearchUserGroup: Bool
}

extension PermissionManager {
    /// 搜索可添加的协作者列表
    /// 接口文档：https://bytedance.feishu.cn/docs/doccny7C3VMSTEPBxZLL8p#
    /// - Parameters:
    ///   - query: 搜索字串
    ///   - offset: 从第几条开始往后拉取新的数据
    ///   - count: 拉取数据条数
    ///   - docsType: 文件类型
    ///   - objToken: 文件的 objToken
    ///   - departmentType: 搜索部门
    ///   - shouldSearchOrganization: 是否搜索部门
    ///   - shouldSearchPhoneOrEmail: 搜索手机号和邮箱
    ///   - complete: 请求回来调用的 completion block
    static func searchCollaboratorCandidatesRequest(context: CollaboratorCandidatesRequestContext) -> Single<CollaboratorSearchResponse> {
        let q = getURLQueryString(origin: context.query)
        let searchContext = SearchCandidatesPath(query: q, offset: context.offset, count: context.count, docsTypeValue: context.docsTypeValue, objToken: context.objToken, departmentType: context.shouldSearchOrganization ? 1 : nil, userGroupType: context.shouldSearchUserGroup ? 1 : nil, logincpType: nil)
        let requestPath = getSearchCandidatesPath(context: searchContext)
        let request = DocsRequest<JSON>(path: requestPath, params: nil)
            .set(method: .GET)
            .set(timeout: 20)

        return request.rxStart()
            .map { json in
                guard let dict = json?.dictionaryObject,
                      let data = dict["data"] as? [String: Any],
                      let collaboratorsDict = data["candidates"] as? [[String: Any]],
                      let hasMore = data["has_more"] as? Bool
                else {
                    throw DocsNetworkError.invalidData
                }
                var items = Collaborator.collaborators(collaboratorsDict, isOldShareFolder: false)
                if let entities = data["entities"] as? [String: Any], let users = entities["users"] as? [String: Any] {
                    Collaborator.localizeCollaboratorName(collaborators: &items, users: users)
                    Collaborator.permissionStatistics(collaborators: &items, users: users)
                }
                if hasMore {
                    return CollaboratorSearchResponse(collaborators: items,
                                                      pagingInfo: .hasMore(pageToken: context.offset + context.count))
                } else {
                    return CollaboratorSearchResponse(collaborators: items, pagingInfo: .noMore)
                }
            }
    }
    
    public struct SearchCandidatesPath {
        public let query: String
        public let offset: Int
        public let count: Int
        public let docsTypeValue: Int?
        public let objToken: String?
        public let departmentType: Int?
        public let userGroupType: Int?
        public let logincpType: Int?
    }
    
    private static func getURLQueryString(origin: String) -> String {
        var q = origin.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? origin
        q = q.replacingOccurrences(of: "+", with: "%2B")
        return q
    }
    
    private static func getSearchCandidatesPath(context: SearchCandidatesPath) -> String {
        /// 小B账户且query为空，userType = 1，后台会去获取拉最近联系人接口
        let userType = (User.current.info?.isToNewC ?? false) && context.query.isEmpty ? 1 : 0
        var path = OpenAPI.APIPath.searchPermissionCandidates  + "?query=\(context.query)&offset=\(context.offset)&count=\(context.count)&user_type=\(userType)"
        if let docsTypeValue = context.docsTypeValue, let objToken = context.objToken {
            path += "&token=\(objToken)&type=\(docsTypeValue)"
        }
        if let departmentType = context.departmentType {
            path += "&department_type=\(departmentType)"
        }
        if let userGroupType = context.userGroupType {
            path += "&group_type=\(userGroupType)"
        }
        if let logincpType = context.logincpType {
            path += "&logincp_type=\(logincpType)"
        }
        return path
    }
    
    static func generateEmailInfo(type: Int,
                                  token: String,
                                  email: String) -> Single<String?> {
        let parameters = [
            "obj_type": type,
            "token": token,
            "emails": [email]
        ] as [String : Any]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.generateEmailInfo, params: parameters)
            .set(encodeType: .jsonEncodeDefault)
            .rxStart()
            .flatMap({ json in
                guard let json = json,
                      let dict = json.dictionaryObject,
                      let data = dict["data"] as? [String: Any],
                      let emailsDict = data["email_info"] as? [String: Any],
                let email = emailsDict[email] as? String else {
                    return .error(CollaboratorsError.parseError)
                }
                return .just(email)
            })
            .catchError { error in
                DocsLogger.error("generateEmailInfo failed!", extraInfo: nil, error: error, component: nil)
                throw CollaboratorsError.networkError
            }
    }
    
    static func emailInviteRelation(type: Int,
                                    token: String,
                                    inviteToken: String) -> Single<Bool> {
        let parameters = [
            "obj_type": type,
            "token": token,
            "invite_token": inviteToken
        ] as [String : Any]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.emailInviteRelation, params: parameters)
            .set(encodeType: .jsonEncodeDefault)
            .rxStart()
            .flatMap({ json in
                guard let code = json?["code"].int, code == 0 else {
                    return .error(CollaboratorsError.parseError)
                }
                return .just(true)
            })
            .catchError { error in
                DocsLogger.error("emailInviteRelation failed!", extraInfo: nil, error: error, component: nil)
                throw CollaboratorsError.networkError
            }
    }
}
