//
//  ReactionDetailViewModel.swift
//  Calendar
//
//  Created by pluto on 2023/5/24.
//

import UIKit
import Foundation
import RustPB
import LKCommonsLogging

final class ReactionDetailViewModel {
    private let logger = Logger.log(ReactionDetailViewModel.self, category: "calendar.ReactionDetailViewModel")
    
    typealias StartIndex = Int
    weak var controller: UIViewController?
    
    let rsvpData: [Basic_V1_AttendeeRSVPInfo]
    
    var reactionTableDataSource: [[Basic_V1_AttendeeRSVPInfo]] = [[], [], [], []]
    
    private(set) var reactions: [ReplyStatus] = []
    private(set) var startIndex: Int = 0
    
    init(rsvpDataSource: [Basic_V1_AttendeeRSVPInfo], type: Int) {
        self.rsvpData = rsvpDataSource
        configReactionTableData(type: type)
        logger.info("ReactionDetailViewModel initial type: \(type), rsvpDataSource Count: \(rsvpDataSource.count)")
    }
    
    private func configReactionTableData(type: Int) {
        var hasAc: Bool = false
        var hasDe: Bool = false
        var hasTe: Bool = false
        var hasNe: Bool = false
        rsvpData.map { item in
            switch item .status {
            case .accept:
                reactionTableDataSource[0].append(item)
                hasAc = true
            case .decline:
                reactionTableDataSource[1].append(item)
                hasDe = true
            case .tentative:
                reactionTableDataSource[2].append(item)
                hasTe = true
            case .needsAction:
                reactionTableDataSource[3].append(item)
                hasNe = true
            @unknown default: break
            }
        }
        configReactionTag(hasAc, hasDe, hasTe, hasNe)
        configStartIndex(type: type)
        reactionTableDataSource = reactionTableDataSource.filter { return !$0.isEmpty }
    }
    
    private func configStartIndex(type: Int) {
        for i in 0..<reactions.count {
            if reactions[i].rawValue == type {
                startIndex = i
                break
            }
        }
    }
    
    private func configReactionTag(_ ac: Bool, _ de: Bool, _ te: Bool, _ ne: Bool) {
        logger.info("data source types, accept: \(ac) decline: \(de) tentative: \(te) needaction \(ne)")
        if ac { reactions.append(.accept) }
        if de { reactions.append(.decline) }
        if te { reactions.append(.tentative) }
        if ne { reactions.append(.needsAction) }
    }
    
    func reaction(at index: Int) -> ReplyStatus? {
        guard index > -1, index < reactions.count else { return nil }
        return reactions[index]
    }
    
    func configDetailTableController(_ controller: ReactionDetailTableController, at index: Int) {
        
        // ignore unsupport case
        guard index > -1, index < reactions.count else {
            return
        }
        
        var viewModel = controller.viewModel
        viewModel = ReactionDetailTableViewModel(data: reactionTableDataSource[safeIndex: index] ?? [])
        
        controller.viewModel = viewModel
    }
}
