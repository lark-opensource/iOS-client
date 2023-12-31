
import Foundation
import LarkOpenAPIModel


final class PreviewImageModel: OpenAPIBaseParams {
    
    /// description: 默认显示的图片的地址
    @OpenAPIOptionalParam(
            jsonKey: "current")
    public var current: String?
    
    /// description: 请求 Header，仅为网络url时有效。
    @OpenAPIOptionalParam(
            jsonKey: "header")
    public var header: [String: Any]?
    
    /// description: 图片地址列表，支持本地和网络url
    @OpenAPIOptionalParam(
            jsonKey: "urls")
    public var urls: [String]?
    
    /// description: 原图列表
    @OpenAPIOptionalParam(
            jsonKey: "originUrls")
    public var originUrls: [String]?
    
    /// description: 请求request
    @OpenAPIOptionalParam(
            jsonKey: "requests")
    public var requests: [PreviewRequestsItem]?
    
    /// description: 预览页长按后，是否显示“保存图片”选项
    /// true：显示
    /// false：不显示
    @OpenAPIRequiredParam(
            userOptionWithJsonKey: "shouldShowSaveOption",
            defaultValue: true)
    var shouldShowSaveOption: Bool

    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_current, _urls, _requests, _shouldShowSaveOption]
    }
    
    required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        header = params["header"] as? [String:Any]
        originUrls = params["originUrls"] as? [String]
    }
    
    public override var description: String {
        return "PreviewImageModel<url:\(urls), header:\(header), current:\(current), originUrls:\(originUrls), requests:\(requests)>"
    }
    
}

// MARK: RequestsItem
final class PreviewRequestsItem: OpenAPIBaseParams {

    /// description: 请求url
    @OpenAPIRequiredParam(
        userRequiredWithJsonKey: "url")
    public var url: String

    /// description: 请求header
    @OpenAPIOptionalParam(
        jsonKey: "header")
    public var header: [String: Any]?

    /// description: 请求method
    @OpenAPIOptionalParam(
        jsonKey: "method", validChecker: { $0.uppercased() == "GET" || $0.uppercased() == "POST" })
    public var method: String?

    /// description: 请求body
    @OpenAPIOptionalParam(
        jsonKey: "body")
    public var body: [AnyHashable: Any]?
    
    required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        guard let urlStr = params["url"] else{
            throw OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setOuterMessage("url is empty.")
            .setErrno(OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: "url")))
        }
        guard let urlStr = urlStr as? String else{
            throw OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setOuterMessage("url is empty.")
            .setErrno(OpenAPICommonErrno.invalidParam(.paramWrongType(param: "url")))
        }
        guard !urlStr.isEmpty else{
            throw OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setOuterMessage("url is empty.")
            .setErrno(OpenAPICommonErrno.invalidParam(.paramCannotEmpty(param: "url")))
        }
        url = urlStr
        header = params["header"] as? [String:Any]
        body = params["body"] as? [AnyHashable:Any]
    }
    
    public override var description: String {
        return "PreviewRequestsItem<url:\(url), header:\(header), method:\(method), body:\(body)>"
    }
    
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_method]
    }
}
