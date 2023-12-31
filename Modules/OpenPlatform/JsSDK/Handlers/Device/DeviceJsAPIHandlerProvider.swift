import Foundation
import Swinject

public struct DeviceJsAPIHandlerProvider: JsAPIHandlerProvider {

    public let handlers: JsAPIHandlerDict

    public init() {
        self.handlers = [
            "device.base.getSystemInfo": { GetSystemInfoHandler() }
        ]
    }
}
