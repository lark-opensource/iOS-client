//
//  InlineAIVoiceViewModel.swift
//  LarkAIInfra
//
//  Created by ByteDance on 2023/10/16.
//

import Foundation
import RxSwift
import RxCocoa

final class InlineAIVoiceViewModel {
    
    /// 生成完成的指令结果缓存
    private var panelModelCache = [String: InlineAIPanelModel]()
}

extension InlineAIVoiceViewModel {
    
    func resetCache() {
        panelModelCache = [:]
    }
    
    func saveResult(model: InlineAIPanelModel, for key: String) {
        panelModelCache[key] = model
    }
    
    func getModelCache(key: String) -> InlineAIPanelModel? {
        let model = panelModelCache[key]
        return model
    }
}
