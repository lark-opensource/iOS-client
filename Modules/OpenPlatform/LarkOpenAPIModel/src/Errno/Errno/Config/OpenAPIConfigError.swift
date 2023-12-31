import Foundation
public enum OpenAPIConfigError {
    case invalidDataFormat
    case networkError
    case bizError(code: Int, msg: String)
    case invalidParam

    // 错误码文档：https://open.feishu.cn/document/uYjL24iN/uEzM4YjLxMDO24SMzgjN
    public var errorInfo: [String: Any] {
        var errCode: Int
        var errorMessage: String
        switch self {
        case let .bizError(code: code, msg: msg):
            // 根据后端返回的error code对错误码进行处理，取code的后三位，再加上333作为错误码返回，例如：后端返回的code为100033，那么处理后的错误码为333033
            errCode = Int("333\(String(String(format: "%03d", UInt(abs(code))).suffix(3)))") ?? 1003
            errorMessage = msg
        case .invalidDataFormat:
            errorMessage = "wrong data format"
            errCode = 10002
        case .networkError:
            errorMessage = "request error"
            errCode = 10001
        case .invalidParam:
            errorMessage = "invalid parameter"
            errCode = 1012
        }
        return ["errorCode": errCode,
                "errorMessage": errorMessage]
    }
}
