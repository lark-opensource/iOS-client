//
//  RVCSetupBootTask.swift
//  ByteViewMod
//
//  Created by zhouyongnan on 2021/10/22.
//

import Foundation
import BootManager
import LarkPerf
import LarkRVC
import LarkAccountInterface
import LKCommonsLogging
import LarkRustClient
import RustPB
import RxSwift
import LarkUIKit
import EENavigator
import LarkEMM
import LarkSensitivityControl
import LarkContainer
#if MessengerMod
import LarkMessengerInterface
import ByteViewMessenger
#endif

class RVCSetupBootTask: FlowBootTask, Identifiable { // Global
    static var identify: TaskIdentify = "RVCSetupTask"
    private static let token = "LARK-PSDA-rvc_copy_meeting_content"
    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        LarkRoomWebViewManager.registerRouter()
        LarkRoomWebViewManager.setupGetDeviceIdHandler(handler: {
            (try? Container.shared.resolve(assert: PassportService.self).deviceID) ?? ""
        })
        LarkRoomWebViewManager.registerSettingsObserve()
        LarkRoomWebViewManager.setupGetWatermarkInfoHandler(handler: WhiteBoardShareAndSavePic.getUsernameAndPhone)
        LarkRoomWebViewManager.setupShareImageToChatHandler(handler: WhiteBoardShareAndSavePic.shareImages)
        LarkRoomWebViewManager.setupCopyMessageWithSecurity(handler: { message, shouldImmunity in
            let config = PasteboardConfig(token: Token(withIdentifier: Self.token), shouldImmunity: shouldImmunity)
            SCPasteboard.general(config).string = message
        })
    }
}


enum WhiteBoardShareAndSavePic {

    static func getUsernameAndPhone(userID: String) -> Observable<(String, String)> {
        guard let userResolver = try? Container.shared.getUserResolver(userID: userID),
              let user = try? userResolver.resolve(assert: PassportUserService.self).user,
              let rustService = try? userResolver.resolve(assert: RustService.self) else { return .empty() }
        var request = Contact_V1_GetChatterMobileRequest()
        let userName = user.localizedName
        request.chatterID = user.userID
        return rustService.sendAsyncRequest(request, transform: { (response: Contact_V1_GetChatterMobileResponse) -> (String, String) in
            (userName, response.mobile)
        })
    }

    static func shareImages(userID: String, from: UIViewController, paths: [String]) {
        #if MessengerMod
        let userResolver = try? Container.shared.getUserResolver(userID: userID)
        let body = WhiteBoardShareBody(imagePaths: paths, nav: from.navigationController)
        userResolver?.navigator.present(
            body: body,
            from: from,
            prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen }
        )
        #endif
    }
}
