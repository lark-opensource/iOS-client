//
//  EventEditViewController+InlineAI.swift
//  Calendar
//
//  Created by pluto on 2023/9/24.
//

import Foundation
import EventKit

extension EventEditViewController: InlineAIViewControllerDelegate {
    /// 更新编辑页EventInfo. For Full Block
    func updateFullEventInfoFromAI(data: InlineAIEventFullInfo) {
        viewModel.updateFullEventInfoFromAI(data: data)
    }
    
    /// 更新编辑页EventInfo. 每次只更新一个Block， For Single Block
    func updateEventInfoFromAI(data: InlineAIEventInfo) {
        viewModel.updateEventInfoFromAI(data: data)
        
        DispatchQueue.main.async {
            self.checkIfNeedScrollToCenter(type: data.type)
        }
    }
    
    // 每次更新数据后，滚动到特定区域
    func checkIfNeedScrollToCenter(type: AIGenerateEventInfoType) {
        let rect: CGRect = getCurrentRectOfView(type: type)
        rootView.isScrollEnabled = true
        var realOffset = 0.0
        if rect.minY > self.view.bounds.height/2 {
            realOffset = rect.minY - self.view.bounds.height/2
            realOffset += type == .meetingNotes ? 150 : 0
        }
        rootView.setContentOffset(CGPoint(x: 0, y: realOffset), animated: true)
    }
    
    func getShowPanelViewController() -> UIViewController {
        return self
    }
    
    /// 触发已有创建纪要逻辑：同手动点击创建
    func meetingNotesCreateHandler() {
        onCreateAIDoc(getMeetingNotesView())
    }
    
    /// 获取当前完整日程信息
    func getCurrentEventInfo() -> InlineAIEventFullInfo {
        let info = viewModel.getCurrentEventInfo()
        return info
    }
}
