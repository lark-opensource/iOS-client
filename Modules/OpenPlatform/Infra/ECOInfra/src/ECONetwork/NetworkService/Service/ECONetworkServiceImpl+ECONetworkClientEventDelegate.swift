//
//  ECONetworkService+ECONetworkClientEventDelegate.swift
//  NetworkClientSwiftTest
//
//  Created by MJXin on 2021/5/24.
//

import Foundation

extension ECONetworkServiceImpl: ECONetworkClientEventDelegate {

    public func didFinishCollecting(
        context: AnyObject?,
        client: ECONetworkClientProtocol,
        task: ECONetworkTaskProtocol,
        metrics: ECONetworkMetrics
    ) {
        guard var eventHandler = context as? ECONetworkEventHandler else {
            Self.logger.error("NetworkClientEvent call with unexpected context")
            assertionFailure("NetworkClientEvent call with unexpected context")
            return
        }
        eventHandler.metrics = metrics
    }
    
    public func didSendBodyData(
        context: AnyObject?,
        client: ECONetworkClientProtocol,
        task: ECONetworkTaskProtocol,
        bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        guard let eventHandler = context as? ECONetworkEventHandler else {
            Self.logger.error("NetworkClientEvent call with unexpected context")
            assertionFailure("NetworkClientEvent call with unexpected context")
            return
        }
        eventHandler.progress.didSendData(
            context: eventHandler.context,
            bytesSent: bytesSent,
            totalBytesSent: totalBytesSent,
            totalBytesExpectedToSend: totalBytesExpectedToSend
        )
    }
    
    public func didWriteData(
        context: AnyObject?,
        client: ECONetworkClientProtocol,
        task: ECONetworkTaskProtocol,
        bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let eventHandler = context as? ECONetworkEventHandler else {
            Self.logger.error("NetworkClientEvent call with unexpected context")
            assertionFailure("NetworkClientEvent call with unexpected context")
            return
        }
        eventHandler.progress.didDownloadData(
            context: eventHandler.context,
            bytesReceive: bytesWritten,
            totalBytesReceive: totalBytesWritten,
            totalBytesExpectedToReceive: totalBytesExpectedToWrite
        )
    }
}
