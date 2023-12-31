import Foundation
import LarkAssembler
import LarkContainer
import LarkQRCode
import LKQRCodeExternal

public class LKQRCodeExternalAssembly: LarkAssemblyInterface {
    public init() {
    }

    public func registContainer(container: Container) {
        container.register(LKKAQRCodeApiProtocol.self) { _ in
            KAQRCodeApiExternal.shared
        }
    }

    public func registLauncherDelegate(container: Container) {
    }
}

extension KAQRCodeApiExternal: LKKAQRCodeApiProtocol {
    public func interceptHandle(result: String) -> Bool {
        var ret = false
        print("KA---Watch: start find intercept handler")
        delegates.forEach { delegate in
            if delegate.interceptHandle(result: result) {
                print("KA---Watch: find a intercept handler")
                ret = true
            }
        }
        print("KA---Watch: stop find a intercept handler")
        return ret
    }

    public func handle(result: String) -> Bool {
        var ret = false
        print("KA---Watch: start find handler")
        delegates.forEach { delegate in
            if delegate.handle(result: result) {
                print("KA---Watch: find a handler")
                ret = true
            }
        }
        print("KA---Watch: stop find a handler")
        return ret
    }

}
