//
//  BTFilterValueLinkViewModel.swift
//  SKBitable
//
//  Created by ByteDance on 2022/9/2.
//

import SKFoundation

final class BTFilterValueLinkViewModel {
    
    private var fieldId: String
    private var dataService: BTFilterDataServiceType?
    
    private(set) var selectedRecordModel: [BTLinkRecordModel] = []
    
    var selectedRecordIds: [String]
    
    var isAllowMultipleSelect: Bool
    
    init(fieldId: String,
         selectedRecordIds: [String],
         isAllowMultipleSelect: Bool,
         btDataService: BTFilterDataServiceType?) {
        self.isAllowMultipleSelect = isAllowMultipleSelect
        self.dataService = btDataService
        self.fieldId = fieldId
        self.selectedRecordIds = selectedRecordIds
    }
    
    /// 根据ID获取关联记录数据
    func getFieldLinkOptionsByIds(recordIds: [String],
                                  responseHandler: @escaping(Result<[BTLinkRecordModel], BTAsyncRequestError>) -> Void,
                                  resultHandler: ((Result<Any?, Error>) -> Void)?) {
        dataService?.getFieldLinkOptionsByIds(byFieldId: fieldId,
                                              recordIds: recordIds,
                                              responseHandler: { [weak self] result in
            self?.handleAsyncResponse(result: result, responseHandler: responseHandler)
        },
                                              resultHandler: resultHandler)
    }
    
    /// 根据keywords获取关联记录数据
    func getFilterValueDataTypeLinks(keywords: String?,
                                     responseHandler: @escaping(Result<[BTLinkRecordModel], BTAsyncRequestError>) -> Void,
                                     resultHandler: ((Result<Any?, Error>) -> Void)?) {
        dataService?.getFieldOptions(by: fieldId,
                                     with: keywords,
                                     router: BTAsyncRequestRouter.getFieldLinkOptions,
                                     responseHandler: { [weak self] result in
                                         self?.handleAsyncResponse(result: result, responseHandler: responseHandler)
                                     },
                                     resultHandler: resultHandler)
    }
    
    private func handleAsyncResponse(result: Result<BTAsyncResponseModel, BTAsyncRequestError>,
                                     responseHandler: @escaping(Result<[BTLinkRecordModel], BTAsyncRequestError>) -> Void) {
        //前端异步请求回调
        switch result {
        case .success(let data):
            guard data.result == 0 else {
                let error = BTAsyncRequestError(code: .requestFailed, domain: "bitable", description: "request failed")
                responseHandler(.failure(error))
                return
            }
            
            guard let linkOptionsData = data.data["options"] as? [[String: Any]],
                  let linkOptions = [BTLinkRecordModel].deserialize(from: linkOptionsData)?.compactMap({ $0 }) else {
                DocsLogger.btError("[BTAsyncRequest] BTFilterValueLinkViewModel failed optionData isEmpty data:\(data.toJSONString() ?? "")")
                let error = BTAsyncRequestError(code: .dataFormatError, domain: "bitable", description: "dataFormatError")
                responseHandler(.failure(error))
                return
            }
            
            responseHandler(.success(linkOptions))
        case .failure(let error):
            responseHandler(.failure(error))
        }
    }
    
    ///更新和拼接已选中的记录
    func joinAndUpdate(_ linkOptions: [BTLinkRecordModel]) -> [BTLinkRecordModel] {
        //已选中的record更新状态
        let selectedUpdateLinkOptions = selectedRecordModel.compactMap { model -> BTLinkRecordModel? in
            //接口返回不会包含是否选中
            if var newModel = linkOptions.first(where: { $0.id == model.id }) {
                newModel.isSelected = true
                return newModel
            }
            
            return model
        }
        
        let selectedUpdateLinkOptionIds = selectedUpdateLinkOptions.compactMap({ $0.id })
        
        //请求回来的records，去掉跟已选项一样的record
        let notSelectedLinkOptions = linkOptions.filter({ !selectedUpdateLinkOptionIds.contains($0.id) })
        
        return selectedUpdateLinkOptions + notSelectedLinkOptions
    }
    
    func updateSelectedRecordModel(_ models: [BTLinkRecordModel]) {
        self.selectedRecordModel = models
    }
}
