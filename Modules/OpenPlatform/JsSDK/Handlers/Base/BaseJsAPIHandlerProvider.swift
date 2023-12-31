import Foundation
import Swinject
import EENavigator
import WebBrowser
import LarkContainer

public struct BaseJsAPIHandlerProvider: JsAPIHandlerProvider {

    public let handlers: JsAPIHandlerDict

    public init(api: WebBrowser, resolver: UserResolver) {
        let hud = PreloaderHud()
        let captureScreenObserver = CaptureScreenObserver()
        let scanBluetoothHandler = ScanBluetoothDeviceHandler(api: api)
        let connectHandler = ConnectBluetoothDeviceHandler(api: api)
        connectHandler.scanHandler = scanBluetoothHandler
        let locationHandler = GeoLocationHandler()

        let hdlrs: JsAPIHandlerDict = [
            "biz.navigation.setTitle": { SetTitleHandler() },
            "biz.navigation.setRight": { SetRightHandler() },
            "biz.navigation.setLeft": { SetLeftHandler() },
            "biz.navigation.setMenu": { SetMenuHandler() },
            "biz.navigation.goBack": { GoBackHandler() },
            "biz.navigation.close": { CloseHandler() },
            "biz.util.copyText": { CopyTextHandler() },
            "biz.util.getClipboardInfo": { GetClipboardInfoHandler() },
            "biz.util.openLink": {
                return OpenLinkHandler { (url, vc, from) in
                    resolver.navigator.push(
                        url,
                        context: [
                            "from": from?.absoluteString ?? "",
                            "forcePush": true,
                            // 显示传入openType是因为EEnavigator里getNaviParams里的decode现在有问题，这里先兜底处理
                            "openType": OpenType.push],
                        from: vc
                    )
                }
            },
            "biz.util.page.openLink": { [unowned api] in OpenLinkJSAPIHandler(api: api, resolver: resolver) },
            "biz.util.page.openLinkWithSystem": { OpenLinkWithSystemJSAPIHandler() },
            "biz.util.nativeLog": { NativeLoggerHandler(resolver: resolver) },
            "biz.reporter.sendEvent": { SendEventHandler() },
            "device.base.onUserCaptureScreen": { [unowned api] in
                CaptureScreenOnHandler(captureScreenOb: captureScreenObserver, api: api)
            },
            "device.base.offUserCaptureScreen": { CaptureScreenOffHandler(captureScreenOb: captureScreenObserver) },
            "device.base.getInterface": { GetInterfaceHandler() },
            "device.base.getWifiStatus": { GetWifiStatusHandler() },
            "device.base.getDeviceInfo": { GetDeviceInfoHandler() },
            "device.connection.getConnectedWifi": {
                GetConnectedWifiHandler()
            },
            "device.connection.getGatewayIP": { GetGatewayIPHandler() },
            "device.connection.getNetworkType": { GetNetworkTypeHandler() },
            "device.notification.alert": { AlertHandler() },
            "device.notification.confirm": { ConfirmHandler() },
            "device.notification.prompt": { PromptHandler() },
            "device.notification.toast": { ToastHandler() },
            "device.notification.showPreloader": { ShowPreloaderHandler(hud: hud) },
            "device.notification.hidePreloader": { HidePreloaderHandler(hud: hud) },
            "device.notification.vibrate": { VibrateHandler() },
            "device.screen.lockViewOrientation": { RotateViewHandler() },
            "device.screen.unlockViewOrientation": { ResetViewHandler() },
            "device.connection.scanBluetoothDevice": { scanBluetoothHandler },
            "device.connection.getBluetoothDeviceState": { [unowned api] in
                GetBluetoothDeviceStateHandler(api: api)
            },
            "device.geolocation.get": { [unowned api] in
                GeoLocationGetHandler(resolver: resolver, locationHandler: locationHandler, api: api)
            },
            "device.geolocation.start": { [unowned api] in
                GeoLocationStartHandler(resolver: resolver, locationHandler: locationHandler, api: api)
            },
            "device.geolocation.stop": { [unowned api] in
                GeoLocationStopHandler(resolver: resolver, locationHandler: locationHandler, api: api)
            },
            "device.health.getStepCount": { GetStepCountHandler() },
            "sys.memoryStore.get": { MemoryStoreGetHandler() },
            "sys.memoryStore.multiGet": { MemoryStoreGetHandler() },
            "sys.memoryStore.set": { MemoryStoreSetHandler() },
            "sys.memoryStore.multiSet": { MemoryStoreSetHandler() },
            "sys.memoryStore.remove": { MemoryStoreRemoveHandler() },
            "sys.memoryStore.multiRemove": { MemoryStoreRemoveHandler() },
            "biz.util.base.event.track": { TrackEventHandler() },
            "biz.util.base.metric.track": { TrackMetricHandler() },
            "biz.util.sys.image.save": { SaveImageHandler() },
            "biz.util.page.popTo": { PopVCToIndexHandler() },
            "biz.util.page.pop": { PopVCAtIndexHandler() },
            "sys.event.keyboard.heightChange": { KeyboardEventHandler() }
        ]

        self.handlers = hdlrs
    }

    public static func makeOpenWebLinkHandler(openLinkBlock: (@escaping (URL, _ vc: UIViewController, _ from: URL?) -> Void)) -> LarkWebJSAPIHandler {
        return OpenLinkHandler(openlink: openLinkBlock)
    }
}
