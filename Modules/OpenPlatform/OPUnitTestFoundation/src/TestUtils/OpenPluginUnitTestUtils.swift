//
//  OpenPluginUnitTestUtils.swift
//  AppHost-OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/2/6.
//


import LarkOpenAPIModel

public extension Dictionary {
    func toJsonString() -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return nil
        }
        guard let str = String(data: data, encoding: .utf8) else {
            return nil
        }
        return str
     }
}

public extension OpenAPIBaseResponse {
    enum OpenAPIBaseResponseTest<Result: OpenAPIBaseResult> {
        case failure(error: OpenAPIError)
        case success(data: Result?)
    }
    func toTestReponse() -> OpenAPIBaseResponseTest<Result> {
        switch self {
        case .success(let data):
            return .success(data: data)
        case .failure(let error):
            return .failure(error: error)
        case .continue(_, _): fallthrough
        @unknown default:
            return .failure(error: .init(errno: OpenAPICommonErrno.unknown))
        }
    }
}

public extension OpenAPIError {
    func isEqualToParamCannotEmpty(jsonKey: String) -> String? {
        guard let errno = errnoInfo["errno"] as? Int,
              let errString = errnoInfo["errString"] as? String else {
            return "error \(self) has no errnoInfo!"
        }
        let paramCannotEmpty = OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: jsonKey))
        guard errno == paramCannotEmpty.rawValue,
            errString == paramCannotEmpty.errString else {
            return "errno: \(errno), errString: \(errString) is not match \(paramCannotEmpty.rawValue), \( paramCannotEmpty.errString)"
        }
        return nil
    }
}

/// EMANetworkCipher解密的逆向操作
public extension EMANetworkCipher {
    func encryptString(content: [String: AnyHashable]) -> String? {
        // 字典 -> Data
        guard let contentData = try? JSONSerialization.data(withJSONObject: content, options: .fragmentsAllowed) else {
            return nil
        }
        
        guard let keydata = key.data(using: .utf8),
              let ivData = iv.data(using: .utf8) else {
            return nil
        }
        
        // Data用key, iv加密
        guard let encryptData = try? (contentData as NSData).tma_aesEncrypt(keydata, iv: ivData) else {
            return nil
        }
        
        // Data -> String
        guard let encryptString = String(data: encryptData.base64EncodedData(), encoding: .utf8) else {
            return nil
        }
        return encryptString
    }
}
