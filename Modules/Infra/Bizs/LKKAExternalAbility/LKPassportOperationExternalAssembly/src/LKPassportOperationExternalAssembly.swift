import Foundation
import LarkAssembler
import LarkAccountInterface
import LKPassportOperationExternal
import LKCommonsLogging

public class LKPassportOperationExternalAssembly: LarkAssemblyInterface {
    public init() {
        KAPassportOperationExternal.shared.passportOperator = KAPassportOperatorImpl()
    }
}

final class KAPassportOperatorImpl {
    let logger = Logger.log(KAPassportOperatorImpl.self, category: "Module.KAPassportOperatorImpl")
}

extension KAPassportOperatorImpl: KAPassportOperationProtocol {
    func logoutFeiShu() {
        AccountServiceAdapter.shared.relogin(
            conf: .default, onError: { [weak self] errorMessage in
                self?.logger.error("KAPassportOperatorImpl: Feishu logout Failed", additionalData: ["error": errorMessage])
            }, onSuccess: { [weak self] in
                self?.logger.info("KAPassportOperatorImpl: Feishu logout Success")
            }, onInterrupt: { [weak self] in
                self?.logger.error("KAPassportOperatorImpl: Feishu logout Interrupt")
            })
    }
}
