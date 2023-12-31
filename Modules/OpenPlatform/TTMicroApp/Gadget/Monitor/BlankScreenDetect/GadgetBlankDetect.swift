import LarkWebViewContainer
import ECOInfra
import Swinject
import LarkContainer


// 因为小程序老代码用的OC，套件统一WebView提供的方法支持Swift，所以这里需要转一下。
@objcMembers public final class GadgetBlankDetect: NSObject {
    public class func detectBlank(webview: BDPAppPage?, complete: ((BDPBlankDetectModel?, Error?) -> Void)?) {
        ///如果是settings配置有纯色检测，则使用纯色检测，稳定后与checkBlankRate 合并
        let configService = Injected<ECOConfigService>().wrappedValue
        let config = configService.getDictionaryValue(for: "ecosystem_pure_color_detect")
        if let enablePureRateDetect = config?["enable"] as? Bool, enablePureRateDetect {
            webview?.checkPureRate(backgroundColor: webview?.backgroundColor ?? .clear, { result in
                switch result {
                case .success(let rate):
                    let model = BDPBlankDetectModel()
                    model.blankPixelsRate = CGFloat(rate.blankPixelsRate)
                    model.lucencyPixelsRate = CGFloat(rate.lucencyPixelsRate)
                    model.maxPureColor = rate.maxPureColor
                    model.maxPureColorRate = CGFloat(rate.maxPureColorRate)
                    complete?(model, nil)
                case .failure(let error):
                    complete?(nil, error)
                }
            })
        }
    }
}
