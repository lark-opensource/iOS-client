//
//  BTFilterValueChatterViewModel.swift
//  SKBitable
//
//  Created by X-MAN on 2023/1/29.
//

import Foundation
import SKCommon
import SKFoundation
import SKBrowser

final class BTFilterValueChatterViewModel {
    
    private var fieldId: String
    
    private var dataService: BTFilterDataServiceType?
    
    private(set) var selectedMembers: [MemberItem]
    
    private(set) var isAllowMultipleSelect: Bool
    
    private(set) var chatterType: BTChatterType
    
    init(fieldId: String,
         selectedMembers: [MemberItem],
         isAllowMultipleSelect: Bool,
         chatterType: BTChatterType,
         btDataService: BTFilterDataServiceType?) {
        self.fieldId = fieldId
        self.dataService = btDataService
        self.selectedMembers = selectedMembers
        self.isAllowMultipleSelect = isAllowMultipleSelect
        self.chatterType = chatterType
    }
    
    /// 根据keywords获取关联记录数据
    func getFilterValueDataTypeChatter(keywords: String?,
                                      responseHandler: @escaping (Result<[MemberItem], BTAsyncRequestError>) -> Void,
                                      resultHandler: ((Result<Any?, Error>) -> Void)?) {
        dataService?.getFieldOptions(by: fieldId,
                                     with: keywords,
                                     router: chatterType == .group ? .getFieldGroupOptions : .getFieldUserOptions,
                                     responseHandler: { [weak self] result in
                                         self?.handleAsyncResponse(result: result, responseHandler: responseHandler)
                                     }, resultHandler: resultHandler)
    }
    
    private func handleAsyncResponse(result: Result<BTAsyncResponseModel, BTAsyncRequestError>,
                                     responseHandler: @escaping(Result<[MemberItem], BTAsyncRequestError>) -> Void) {
        //前端异步请求回调
        switch result {
        case .success(let data):
            guard data.result == 0 else {
                let error = BTAsyncRequestError(code: .requestFailed, domain: "bitable", description: "request failed")
                DocsLogger.error("[BTFilterValueMemberViewModel] handleAsyncResponse request failed")
                responseHandler(.failure(error))
                return
            }
            guard let chatterData = data.data["data"] as? [[String: Any]] else {
                DocsLogger.btError("[BTAsyncRequest] BTFilterValueLinksController failed optionData isEmpty data:\(data.toJSONString() ?? "")")
                let error = BTAsyncRequestError(code: .dataFormatError, domain: "bitable", description: "dataFormatError")
                responseHandler(.failure(error))
                return
            }
            let chatters = chatterData.compactMap { obj -> BTFilterChatterOptionProtocol? in
                do {
                    let modelType: BTFilterChatterOptionProtocol.Type = (chatterType == .group) ? BTFilterGroupOption.self : BTFilterUserOption.self
                    let chatter = try CodableUtility.decode(modelType, withJSONObject: obj)
                    return chatter
                } catch {
                    DocsLogger.btError("[BTFilterValueMemberViewModel] handleAsyncResponse data format error \(error)")
                    return nil
                }
            }
            
            let selectedIs = selectedMembers.compactMap { $0.identifier }
            let selectedIdsSet: Set<String> = Set(selectedIs)
            
            let members = chatters.map {
                MemberItem(identifier: $0.chatterId,
                           selectType: selectedIdsSet.contains($0.chatterId) ? .blue : .gray,
                           imageURL: $0.avatarUrl,
                           title: $0.name,
                           detail: "",
                           token: "", // 筛选排序这块群组不跳转，不需要
                           isExternal: false,
                           displayTag: nil,
                           isCrossTenanet: false)
            }
            
            responseHandler(.success(members))
        case .failure(let error):
            responseHandler(.failure(error))
        }
    }
    
    ///更新和拼接已选中的记录
    func joinAndUpdate(_ members: [MemberItem]) -> [MemberItem] {
        //已选中的user更新状态
        let selectedUpdateMembers = selectedMembers.compactMap { model -> MemberItem? in
            //接口请求的结果会有是否选中
            return members.first(where: { $0.identifier == model.identifier }) ?? model
        }
        
        let selectedUpdateMemberIds = selectedUpdateMembers.compactMap({ $0.identifier })
        
        //请求回来的records，去掉跟已选项一样的member
        let notSelectedMembers = members.filter({ !selectedUpdateMemberIds.contains($0.identifier) })
        
        return selectedUpdateMembers + notSelectedMembers
    }
    
    func updateSelectedMembers(_ members: [MemberItem]) {
        self.selectedMembers = members
    }
}
