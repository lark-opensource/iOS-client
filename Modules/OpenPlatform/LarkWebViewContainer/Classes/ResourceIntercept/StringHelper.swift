import Foundation
extension String {
    func base64ByJSToData() -> Data? {
        //  前端的JS代码对二进制数据转换成base64字符串不符合RFC规范，需要额外兼容
        let components = components(separatedBy: ",") as [NSString]
        let splitBase64: NSString
        if components.count == 2 {
            splitBase64 = components.last ?? ""
        } else {
            splitBase64 = self as NSString
        }
        let paddedLength = splitBase64.length + (splitBase64.length % 4)
        let fixBase64 = splitBase64.padding(toLength: paddedLength, withPad: "=", startingAt: 0)
        return Data(base64Encoded: fixBase64)
    }
}
