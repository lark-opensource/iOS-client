//
//  File.swift
//  SKFoundation
//
//  Created by 刘焱龙 on 2023/9/17.
//

import Foundation

protocol BTStatisticLoggerProvider {
    func send(trace: BTStatisticTrace, eventName: String, params: [String: Any])
}
