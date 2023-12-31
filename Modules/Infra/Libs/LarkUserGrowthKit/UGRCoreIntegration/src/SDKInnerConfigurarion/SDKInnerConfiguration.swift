//
//  SDKInnerConfiguration.swift
//  UGRCoreIntegration
//
//  Created by shizhengyu on 2021/3/3.
//

import Foundation

struct SDKInnerConfiguration {
    private(set) var solveConflictUseGraph: Bool
    private(set) var requestTimeoutDuration: Double
    private(set) var uploadStatusUseLoop: Bool

    init(
        solveConflictUseGraph: Bool,
        requestTimeoutDuration: Double,
        uploadStatusUseLoop: Bool
    ) {
        self.solveConflictUseGraph = solveConflictUseGraph
        self.requestTimeoutDuration = requestTimeoutDuration
        self.uploadStatusUseLoop = uploadStatusUseLoop
    }

    static func `default`() -> SDKInnerConfiguration {
        return SDKInnerConfiguration(
            solveConflictUseGraph: false,
            requestTimeoutDuration: 60,
            uploadStatusUseLoop: false
        )
    }
}
