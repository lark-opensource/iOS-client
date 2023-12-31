import LarkAssembler
import LKJsApiExternal

public class LKJsApiAssembly: LarkAssemblyInterface {
    public init() {
        print("KA---Watch: KANativeAppAPIExternal.shared 开始注册了")
        KANativeAppAPIExternal.shared.wrapper = NativeAppApiConfigWrapper()
    }
}
