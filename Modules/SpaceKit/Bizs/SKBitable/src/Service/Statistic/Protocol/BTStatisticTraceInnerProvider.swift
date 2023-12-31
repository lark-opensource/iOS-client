//
//  BTStatisticTraceInnerProvider.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/9/9.
//

import Foundation

protocol BTStatisticTraceInnerProvider: AnyObject {
    func getLogger() -> BTStatisticLoggerProvider

    func getUUId() -> String

    func getTrace(traceId: String, includeStop: Bool) -> BTStatisticTrace?

    func removeTrace(traceId: String, includeChild: Bool)
}
