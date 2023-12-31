//
//  MinutesInfoListener.swift
//  MinutesFoundation
//
//  Created by ByteDance on 2023/9/25.
//

import Foundation

public protocol MinutesInfoChangedListener {
    func onMinutesInfoStatusUpdate(_ info: MinutesInfo)
    func onMinutesInfoObjectStatusUpdate(newStatus: ObjectStatus, oldStatus: ObjectStatus)
    func onMinutesInfoSummaryStatusUpdate(newStatus: NewSummaryStatus, oldStatus: NewSummaryStatus)
    func onMinutesInfoAgendaStatusUpdate(newStatus: NewSummaryStatus, oldStatus: NewSummaryStatus)
    func onMinutesInfoSpeakerStatusUpdate(newStatus: NewSummaryStatus, oldStatus: NewSummaryStatus)
    func onMinutesInfoVersionUpdate(newVersion: Int, oldVersion: Int)
}

extension MinutesInfoChangedListener {
    public func onMinutesInfoStatusUpdate(_ info: MinutesInfo) {
        
    }

    public func onMinutesInfoObjectStatusUpdate(newStatus: ObjectStatus, oldStatus: ObjectStatus) {

    }

    public func onMinutesInfoSummaryStatusUpdate(newStatus: NewSummaryStatus, oldStatus: NewSummaryStatus) {

    }

    public func onMinutesInfoVersionUpdate(newVersion: Int, oldVersion: Int) {

    }

    public func onMinutesInfoAgendaStatusUpdate(newStatus: NewSummaryStatus, oldStatus: NewSummaryStatus){

    }

    public func onMinutesInfoSpeakerStatusUpdate(newStatus: NewSummaryStatus, oldStatus: NewSummaryStatus){

    }

}
