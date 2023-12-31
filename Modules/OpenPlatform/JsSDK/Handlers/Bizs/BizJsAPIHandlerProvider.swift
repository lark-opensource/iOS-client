import Foundation
import Swinject
import LarkAccountInterface
import LarkSDKInterface
import EENavigator
import LarkContainer
import LKCommonsLogging
import ECOInfra

public struct BizJsAPIHandlerProvider: JsAPIHandlerProvider {
    
    private static let logger = Logger.oplog(BizJsAPIHandlerProvider.self, category: "BizJsAPIHandlerProvider")
    
    public let handlers: JsAPIHandlerDict

    public init(resolver: UserResolver) {
        let hdlrs: JsAPIHandlerDict = [
            "biz.chat.openSingleChat": { OpenSingleChatHandler(resolver: resolver) },
            "biz.chat.toConversation": { ToConversationHandler(resolver: resolver) },
            "biz.chat.selectMessages": { SelectMessagesHandler(resolver: resolver) },
            "biz.contact.open": { OpenContactHandler() },
            "biz.user.getUserInfoEx": {
                GetUserInfoExHandler(resolver: resolver)
            },
            "biz.user.getUserInfo": {
                let userId = resolver.userID
                let chatter = try? resolver.resolve(assert: ChatterAPI.self)
                if chatter == nil {
                    Self.logger.error("resolve ChatterAPI failed")
                }
                return GetUserInfoHandler(userID: userId, userAPI: chatter)
            },
            "biz.user.openDetail": {
                OpenDetailHandler(resolver: resolver)
            },
            "biz.user.switchUser": { SwitchUserHandler(resolver: resolver) },
            "biz.util.cancelDownloadFile": {
                CancelDownloadFileHandler()
            },
            "biz.util.downloadFile": { DownloadFileHandler() },
            "biz.util.getAppLanguage": { GetAppLanguage() },
            "biz.util.openDocument": { OpenDocumentHandler() },
            "biz.util.previewImage": { PreviewImageHandler() },
            "biz.util.routerChange": { RouterChangeHandler() },
            "biz.util.scan": { ScanHandler() },
            "biz.util.setAuthenticationInfo": { SetAuthenticationInfo(resolver: resolver) },
            "biz.util.share": { ShareHandler(resolver: resolver) },
            "biz.util.startBiometrics": { StartBiometrics(resolver: resolver) },
            "biz.util.uploadImage": { UploadImageHandler(resolver: resolver) }
        ]

        self.handlers = hdlrs
    }
}
