//
//  MinutesDataListener.swift
//  MinutesFoundation
//
//  Created by ByteDance on 2023/9/25.
//

import Foundation

public protocol MinutesDataChangedListener {
    func onMinutesDataStatusUpdate(_ data: MinutesData)
    func onMinutesSpeakerDataUpdate(_ data: SpeakerData?)
    func onMinutesReactionInfosUpdate(_ data:  [ReactionInfo]?)
    func onMinutesCommentsUpdate(_ data: ([String], Bool)?)
    func onMinutesCommentsUpdateCCM(_ data: ([String], Bool)?)
}

extension MinutesDataChangedListener {
    public func onMinutesDataStatusUpdate(_ data: MinutesData) {
        
    }
    
    public func onMinutesSpeakerDataUpdate(_ data: SpeakerData?) {
        
    }
    
    public func onMinutesReactionInfosUpdate(_ data:  [ReactionInfo]?) {
        
    }
    
    public func onMinutesCommentsUpdate(_ data: ([String], Bool)?) {
        
    }
    
    public func onMinutesCommentsUpdateCCM(_ data: ([String], Bool)?) {
        
    }
}
