import EENavigator
import WebBrowser

public struct WebOfflineBody: CodablePlainBody {

    public static let pattern: String = "//client/weboffline"

    public let url: URL
    
    public let webAppInfo: WebAppInfo
    
    public var forcePush: Bool?
    
    public let webBrowserID: String
    
    public var fromScene: H5AppFromScene?
    
    public var appLinkTrackId: String?

    public init(url: URL, webAppInfo: WebAppInfo, webBrowserID: String, fromScene: H5AppFromScene? = nil, appLinkTrackId: String? = nil) {
        self.url = url
        self.webAppInfo = webAppInfo
        self.forcePush = true
        self.webBrowserID = webBrowserID
        self.fromScene = fromScene
        self.appLinkTrackId = appLinkTrackId
    }
}
