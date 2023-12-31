//
//  ChatterProviderProcessor.swift
//  LarkIMMention
//
//  Created by Yuri on 2022/12/8.
//

import Foundation
import RustPB

class ChatterProviderProcessor: IMMentionChatterConvertable {
    
    var currentTenantId: String
    
    typealias Response = RustPB.Im_V1_GetMentionChatChattersResponse
    typealias Chatter = Basic_V1_Chatter
    
    private var context: IMMentionContext
    
    
    init(context: IMMentionContext) {
        self.context = context
        self.currentTenantId = context.currentTenantId
    }
    
    // MARK: - Recommend
    private var recommendReuslt: ProviderResult?
    func processRecommendResult(_ res: Response, isRemote: Bool) -> ProviderResult {
        if isRemote, let localResult = recommendReuslt {
            return processRecommendRemoteResult(res, localResult: localResult)
        } else {
            let result = processRecommendLocalResult(res)
            recommendReuslt = result
            return result
        }
    }
    
    func processRecommendLocalResult(_ res: Response) -> ProviderResult {
        var result = [[IMMentionOptionType]]()
        result.append(getWantedChatChatters(res: res))
        result.append(getInChatChatters(res: res))
        result.append([])
        return ProviderResult(result: result, hasMore: false)
    }
    
    func processRecommendRemoteResult(_ res: Response, localResult: ProviderResult) -> ProviderResult {
        var result = localResult.result
        assert(result.count == 3, "Chatter Data must has wanted, inChat, outChat")
        let newInChatters = getInChatChatters(res: res)
        if result.count > 1 {
            let inChatters = result[1]
            result[1] = updateItems(oldItems: inChatters, newItems: newInChatters)
        }
        return ProviderResult(result: result, hasMore: false)
    }
    
    // MARK: - Search
    private var searchReuslt: ProviderResult?
    func processSearchResult(_ res: Response, isRemote: Bool) -> ProviderResult {
        if isRemote, let localResult = searchReuslt {
            return processSearchRemoteResult(res, localResult: localResult)
        } else {
            let result = processSearchLocalResult(res)
            searchReuslt = result
            return result
        }
    }
    
    private func processSearchLocalResult(_ res: Response) -> ProviderResult {
        var result = [[IMMentionOptionType]]()
        result.append([])
        result.append(getInChatChatters(res: res))
        let outChatters = getOutChatChatters(res: res)
        result.append(outChatters)
        return ProviderResult(result: result, hasMore: false)
    }
    
    private func processSearchRemoteResult(_ res: Response, localResult: ProviderResult) -> ProviderResult {
        var result = localResult.result
        if result.count > 1 {
            let inChatters = result[1]
            let newInChatters = getInChatChatters(res: res)
            result[1] = updateItems(oldItems: inChatters, newItems: newInChatters)
        }
        if result.count > 2 {
            let outChatters = result[2]
            let newOutChatters = getOutChatChatters(res: res)
            result[2] = updateItems(oldItems: outChatters, newItems: newOutChatters)
        }
        return ProviderResult(result: result, hasMore: false)
    }
    
    // MARK: - Private
    func updateItems(oldItems: [IMMentionOptionType], newItems: [IMMentionOptionType]) -> [IMMentionOptionType] {
        let newIds = newItems.compactMap { $0.id }
        let oldIds = oldItems.compactMap { $0.id }
        var items = [IMMentionOptionType]()
        items.append(contentsOf: oldItems.filter { newIds.contains($0.id ?? "") })
        items.append(contentsOf: newItems.filter { !oldIds.contains($0.id ?? "") })
        return items
    }
    
    private func getInChatChatters(res: Response) -> [IMMentionOptionType] {
        return getChatters(res: res, in: res.inChatChatterIds)
            .map { convert(chatter: $0, isInChat: true) }
    }
    private func getOutChatChatters(res: Response) -> [IMMentionOptionType] {
        return getChatters(res: res, in: res.outChatChatterIds)
            .map { convert(chatter: $0, isInChat: false) }
    }
    private func getWantedChatChatters(res: Response) -> [IMMentionOptionType] {
        return getChatters(res: res, in: res.wantedMentionIds)
            .map { convert(chatter: $0, isInChat: true) }
    }
    
    private func getChatters(res: Response, in ids: [String]) -> [Chatter]{
        let inChatChatters = res.entity.chatChatters[context.currentChatId]
        let allChatters = res.entity.chatters
        return ids.compactMap {
            let inChatChatter = inChatChatters?.chatters[$0]
            // 先从群内成员查找, 再从所有人员里查找
            return inChatChatter ?? allChatters[$0]
        }
    }
}
