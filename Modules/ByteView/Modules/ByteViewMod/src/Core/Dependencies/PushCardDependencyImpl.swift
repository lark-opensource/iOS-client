//
//  PushCardDependencyImpl.swift
//  ByteViewMod
//
//  Created by Tobb Huang on 2022/6/16.
//

import Foundation
import ByteViewUI
import LarkPushCard

final class PushCardDependencyImpl: PushCardDependency {
    private typealias LarkPushCardCenter = LarkPushCard.PushCardCenter

    struct VCPushModel: Cardable {
         var icon: UIImage?
         var title: String?
         var buttonConfigs: [LarkPushCard.CardButtonConfig]?
         var duration: TimeInterval?
         var removeHandler: ((LarkPushCard.Cardable) -> Void)?
         var timedDisappearHandler: ((LarkPushCard.Cardable) -> Void)?
         var id: String
         var priority: LarkPushCard.CardPriority
         var extraParams: Any?
         var customView: UIView?
         var bodyTapHandler: ((LarkPushCard.Cardable) -> Void)?
    }

    func postCard(id: String, isHighPriority: Bool, extraParams: [String: Any]?, view: UIView, tap: ((String) -> Void)?) {
        let priority: LarkPushCard.CardPriority = isHighPriority ? .high : .normal
        let model = VCPushModel(id: id, priority: priority, extraParams: extraParams, customView: view) { cardable in
            tap?(cardable.id)
        }
        LarkPushCardCenter.shared.post(model)
    }

    func remove(with id: String, changeToStack: Bool){
        LarkPushCardCenter.shared.remove(with: id, changeToStack: changeToStack)
    }

    func findPushCard(id: String, isBusy: Bool?) -> String? {
        let cards = LarkPushCardCenter.shared.showCards
        for card in cards {
            if isBusy == nil {
                if card.id == id {
                    return card.id
                }
            } else {
                if card.id == id, let extra = card.extraParams as? [String: Any], extra["VCIsBusy"] as? Bool == isBusy {
                    return card.id
                }
            }
        }
        return nil
    }

    func update(with id: String) {
        LarkPushCardCenter.shared.update(with: id)
    }
}
