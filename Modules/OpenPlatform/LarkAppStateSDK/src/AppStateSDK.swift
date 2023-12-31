import Foundation
import LKCommonsLogging
import LarkAccountInterface
import LarkMessageCore
import LarkMessengerInterface
import LarkOPInterface
import LarkRustClient
import RustPB
import RxSwift
import Swinject
import EEMicroAppSDK
import LarkContainer

public class AppStateSDK {
    static let logger = Logger.log(AppStateSDK.self, category: "AppStateSDK")
    public static let shared = AppStateSDK()
    var microAppLifeCycleListenerV2 = LifeCycleListenerImplV2()
    var resolver: UserResolver?
    var client: RustService?
    var disposeBag = DisposeBag()
    private init() {}

    /// SDK初始化
    public func setupSDKWith(resolver: UserResolver) {
        Self.logger.info("AppStateSDK: register listeners")
        self.resolver = resolver
        self.client = try? resolver.resolve(assert: RustService.self)
        microAppLifeCycleListenerV2.resolver = resolver
        registerMicroAppLifeCycleV2(resolver: resolver)
    }

    /// 更新应用最近使用时间
    func updateLastUsedTimeWith(appID: String) {
        var updateTimeRequest = UpdateOpenAppLastHappenTimeRequest()
        updateTimeRequest.appID = appID
        updateTimeRequest.timestamp = "\(Int(NSTimeIntervalSince1970))"
        Self.logger.info("AppStateSDK: update last used time appID:\(appID)")
        client?.sendAsyncRequest(updateTimeRequest).subscribe().dispose()
    }
}
