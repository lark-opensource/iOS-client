//
//  InlineAIRustModel.swift
//  LarkAIInfra
//
//  Created by huangzhikai on 2023/7/27.
//

import Foundation

// success：明确成功
// processing： ack、处理中
// time_out： 链路某一处超时
// failed：明确失败
// tns_block：tns 管控
// off_line： rust层的处理，网络中断
enum RustTaskStatus: String {
    case success    //明确成功
    case processing // ack、处理中
    case time_out   //链路某一处超时
    case failed     //明确失败
    case tns_block  //tns 管控
    case off_line   //rust层的处理，网络中断
    case unknow
}

enum PromptActionType: String {
    case userPrompt = "user_prompt"
    case quickAction = "quick_action"
}

// 错误码定义可查看
// https://bytedance.feishu.cn/docx/A17FdyaogoqZfBxihvYcPMB3nmf#NOttdGAn0o3VClxsOH9cjznXnYd
enum AIRustErrorCode: Int {
    case disable = -1 // My AI不可用
    case failed = 1
    case paramError = 2
    case notFound = 3
    case forbidden = 4
    case RPCFailed = 5
    case internalError = 500
    case TNSReginoOrIPBlock = 13020
    case TNSBrandBlock = 13021
    case QPMLimit = 666900001
    case TPMLimit = 666900002
    case streamCallBackTimeOut = 666900003
    case stopServer = 666900005
    case userQPMLimit = 666900010
    
}

extension AIRustErrorCode {
    
    func errMsg(nickName: String, aiBrandName: String) -> String? {
        switch self {
        case .failed, .paramError, .notFound, .forbidden, .RPCFailed, .internalError, .QPMLimit, .TPMLimit, .streamCallBackTimeOut, .userQPMLimit:
            return BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_Custom_NotAvail_Toast(nickName)
        case .stopServer:
            return BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAi_AdminDeactivated_aiName_Toast(aiBrandName)
        case .TNSReginoOrIPBlock:
            return BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAI_UnavailRegion_aiName_Text(aiBrandName)
        case .TNSBrandBlock:
            return BundleI18n.LarkAIInfra.LarkCCM_Docs_MyAI_LogInToUse_aiName_Text(aiBrandName)
        default:
            return nil
        }
    }
}
