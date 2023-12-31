//
//  InlineAIConfig+Ext.swift
//  LarkAIInfra
//
//  Created by huayufan on 2023/11/2.
//  


import Foundation

extension InlineAIConfig.ScenarioType {
    
    /// 用于发送请求时作为参数
    var requestKey: String {
        switch self {
        case .im:
            return "IM"
        case .docX:
            return "Doc"
        case .sheet:
            return "Sheet"
        case .base:
            return "Base"
        case .vc:
            return "VC"
        case .calendar:
            return "Calendar"
        case .email:
            return "Email"
        case .meego:
            return "Meego"
        case .openWebContainer:
            return "OpenWebContainer"
        case .search:
            return "Search"
        case .slides:
            return "Slides"
        case .groupChat:
            return "GroupChat"
        case .p2pChat:
            return "P2PChat"
        case .board:
            return "Board"
        case .pdfView:
            return "PDFView" // TODO.chensi 注意check下是否正确
        case .wikiSpace:
            return "WikiSpace"
        case .voiceInput:
            return "VoiceInput"
        default:
            return "unknown"
        }
    }
}
