//
//  OpenPluginFile.swift
//  OPPlugin
//
//  Created by yinyuan on 2021/5/21.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import LKCommonsLogging
import OPSDK
import OPPluginManagerAdapter
import OPPluginBiz
import OPFoundation
import LarkContainer

final class OpenPluginFile: OpenBasePlugin {
    
    private enum APIName: String {
        case filePicker
    }
    
    func filePicker(params: OpenAPIFilePickerParams, context: OpenAPIContext, gadgetContext: OPAPIContextProtocol, callback: @escaping (OpenAPIBaseResponse<OpenAPIFilePickerResult>) -> Void) {
        var maxSelectedCount = params.maxNum
        if maxSelectedCount == -1 {
            maxSelectedCount = NSIntegerMax
        }
        context.apiTrace.info("filePicker start. isSystem:\(params.isSystem), maxSelectedCount:\(maxSelectedCount)")
        if params.isSystem {
            EMADocumentPicker.show(callback: { (isCancel, url) in
                if isCancel {
                    context.apiTrace.info("url:\(NSString.safeURL(url) ?? "")")
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage("user cancel")
                        .setErrno(OpenAPIFilePickerErrno.userCanceled)
                    callback(.failure(error: error))
                } else {
                    var resultArray: [[AnyHashable: Any]] = []
                    if let resultDic = OPPluginFileCopy.copyFile(from: url, uniqueID: gadgetContext.uniqueID), !BDPIsEmptyDictionary(resultDic) {
                        resultArray.append(resultDic)
                    }
                    context.apiTrace.info("filePicker success with resultArray:\(resultArray)")
                    callback(.success(data: OpenAPIFilePickerResult(list: resultArray)))
                }
            }, window: gadgetContext.controller?.view.window)
        } else {
            guard let delegate = EMAProtocolProvider.getEMADelegate(),
                  delegate.responds(to: #selector(EMAProtocol.filePicker(_:pickerTitle:pickerComfirm:uniqueID:from:block:))) else {
                let error = OpenAPIError(code: OpenAPICommonErrorCode.unable)
                          .setMonitorMessage("filePicker no implementation")
                          .setErrno(OpenAPICommonErrno.unable)
                callback(.failure(error: error))
                return
            }
            delegate.filePicker(
                maxSelectedCount,
                pickerTitle: params.pickerTitle,
                pickerComfirm: params.pickerConfirm,
                uniqueID: gadgetContext.uniqueID,
                from: gadgetContext.controller
            ) { (isCancel, selectedArray) in
                if isCancel {
                    let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setOuterMessage("user cancel")
                        .setErrno(OpenAPIFilePickerErrno.userCanceled)
                    callback(.failure(error: error))
                } else {
                    let resultArray = selectedArray?.compactMap { (rsDic) -> [AnyHashable: Any]? in
                        guard let pathStr = rsDic[kEMASDKFilePickerPath] as? String,
                              !BDPIsEmptyString(pathStr) else {
                            return nil
                        }
                        guard let tmpPath = OPPluginFileCopy.copyFile(fromPath: pathStr, uniqueID: gadgetContext.uniqueID),
                           !BDPIsEmptyString(tmpPath) else {
                            return nil
                        }
                        let nameStr = rsDic[kEMASDKFilePickerName] as? String
                        
                        var resultDic: [AnyHashable: Any] = [:]
                        resultDic[kEMASDKFilePickerPath] = tmpPath
                        resultDic[kEMASDKFilePickerName] = nameStr
                        resultDic[kEMASDKFilePickerSize] = rsDic[kEMASDKFilePickerSize] ?? "0";
                        return resultDic
                    } ?? []
                    context.apiTrace.info("filePicker success with resultArray:\(resultArray)")
                    callback(.success(data: OpenAPIFilePickerResult(list: resultArray)))
                }
            }
        }
    }
    
    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        
        registerInstanceAsyncHandlerGadget(for: APIName.filePicker.rawValue, pluginType: Self.self, paramsType: OpenAPIFilePickerParams.self, resultType: OpenAPIFilePickerResult.self) { (this, params, context, gadgetContext, callback) in
            
            this.filePicker(params: params, context: context, gadgetContext: gadgetContext, callback: callback)
        }
        
    }

}
