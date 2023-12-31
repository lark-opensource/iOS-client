// swiftlint:disable line_length
import Foundation
import SKResource
public struct ErrorInfoStruct {
    public let type: EmptyListPlaceholderView.EmptyType
    public let title: String?
    public let domainAndCode: (String, String)?
    //DocumentLoadError
    public static let documentLoadDefaultCode = ErrorInfoStruct(type: .openFileOverTime, title: BundleI18n.SKResource.LarkCCM_Docs_Error_LoadOT_Mob, domainAndCode: (ErrorInfoDomain.A.rawValue, DocumentLoadErrorCode.defaultCode.rawValue))
    public static let documentLoadStartCode = ErrorInfoStruct(type: .openFileOverTime, title: BundleI18n.SKResource.LarkCCM_Docs_Error_LoadOT_Mob, domainAndCode: (ErrorInfoDomain.A.rawValue, DocumentLoadErrorCode.start.rawValue))
    public static let documentLoadPreloadOK = ErrorInfoStruct(type: .openFileOverTime, title: BundleI18n.SKResource.LarkCCM_Docs_Error_LoadOT_Mob, domainAndCode: (ErrorInfoDomain.A.rawValue, DocumentLoadErrorCode.preloadOk.rawValue))
    public static let documentLoadaRenderCachStart = ErrorInfoStruct(type: .openFileOverTime, title: BundleI18n.SKResource.LarkCCM_Docs_Error_LoadOT_Mob, domainAndCode: (ErrorInfoDomain.A.rawValue, DocumentLoadErrorCode.renderCachStart.rawValue))
    public static let documentLoadaRenderCacheSuccess = ErrorInfoStruct(type: .openFileOverTime, title: BundleI18n.SKResource.LarkCCM_Docs_Error_LoadOT_Mob, domainAndCode: (ErrorInfoDomain.A.rawValue, DocumentLoadErrorCode.renderCacheSuccess.rawValue))
    public static let documentLoadaRenderCalled = ErrorInfoStruct(type: .openFileOverTime, title: BundleI18n.SKResource.LarkCCM_Docs_Error_LoadOT_Mob, domainAndCode: (ErrorInfoDomain.A.rawValue, DocumentLoadErrorCode.renderCalled.rawValue))
    public static let documentLoadaAfterReadLocalClientVar = ErrorInfoStruct(type: .openFileOverTime, title: BundleI18n.SKResource.LarkCCM_Docs_Error_LoadOT_Mob, domainAndCode: (ErrorInfoDomain.A.rawValue, DocumentLoadErrorCode.afterReadLocalClientVar.rawValue))
    public static let documentLoadaBeforeReadLocalHtmlCache = ErrorInfoStruct(type: .openFileOverTime, title: BundleI18n.SKResource.LarkCCM_Docs_Error_LoadOT_Mob, domainAndCode: (ErrorInfoDomain.A.rawValue, DocumentLoadErrorCode.beforeReadLocalHtmlCache.rawValue))
    //WebViewErrorDomain
    public static let terminateCode = ErrorInfoStruct(type: .openFileOverTime, title: BundleI18n.SKResource.LarkCCM_Docs_NoStorage_LoadingKillApp_Toast(), domainAndCode: (ErrorInfoDomain.B.rawValue, WebViewErrorCode.terminate.rawValue))
    public static let nonResponsiveCode = ErrorInfoStruct(type: .openFileOverTime, title: BundleI18n.SKResource.LarkCCM_Docs_LoadError_Mob(), domainAndCode: (ErrorInfoDomain.B.rawValue, WebViewErrorCode.nonResponsive.rawValue))
    public init(type: EmptyListPlaceholderView.EmptyType, title: String?, domainAndCode: (String, String)?) {
        self.type = type
        self.title = title
        self.domainAndCode = domainAndCode
    }
}
//domain和code的定义请参考 https://bytedance.feishu.cn/wiki/wikcn1xc87t3oKy40TtTLBiiqJe?table=tblYIXmRUDn9T7Kj&view=vewk0SXXDm
//domain定在这里
enum ErrorInfoDomain: String {//domain规则：按照业务划分定义domain，如果原先有则复用，展示错误域从A开始递增
    case A //DocumentLoadErrorDomain
    case B //WebViewErrorDomain
}
//下边按照不同domain定义好code部分
enum DocumentLoadErrorCode: String {//code规则：按照从1开始的递增规律增加code，如果现在已经有的code不需要修改，之需要登记，如果对端已经有的code则对齐对端
    case defaultCode = "999"//此类非递增错误码是因为安卓已经有了，不需要在生造一个出来，负责上述「如果对端已经有的code则对齐对端」规则
    case start = "2"
    case preloadOk = "3"
    case renderCachStart = "300"
    case renderCacheSuccess = "5"
    case renderCalled = "6"
    case afterReadLocalClientVar = "7"
    case beforeReadLocalHtmlCache = "8"
}
enum WebViewErrorCode: String {
    case terminate = "1"        //WebView被回收
    case nonResponsive = "2"     //WebView没有响应
}
