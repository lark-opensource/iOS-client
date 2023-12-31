//
//  OPError+ECONetworkError.swift
//  ECOInfra
//
//  Created by MJXin on 2021/10/24.
//

import Foundation

extension OPError {
    public static func cancelError(identifier: String) -> Error {
        return OPError.error(monitorCode: ECONetworkMonitorCode.client_request_cancel, userInfo: [
            NSLocalizedDescriptionKey: "request:\(identifier) cancelled",
        ])
    }
    
    public static func createLocalFileError(url: URL) -> Error {
        return OPError.error(
            monitorCode: ECONetworkMonitorCode.create_local_file_error,
            message: "create file at \(url.absoluteString) fail"
        )
    }
    
    public static func createFileStreamError(url: URL) -> Error {
        return OPError.error(
            monitorCode: ECONetworkMonitorCode.create_local_file_stream_error,
            message: "create stream for file at \(url.absoluteString) fail"
        )
    }
    
    public static func mockClientDataTransferError(message: String) -> Error {
        return OPError.error(
            monitorCode: ECONetworkMonitorCode.mock_client_transfer_error,
            message: message
        )
    }
    
    public static func responseDataReceiveError(message: String) -> Error {
        return OPError.error(
            monitorCode: ECONetworkMonitorCode.response_data_receive_error,
            message: message
        )
    }
}
