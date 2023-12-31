import ECOProbe
import Foundation
import WebKit
@objcMembers final public class WKWebViewMonitor: NSObject {
    public class func webviewInitMonitor(className: String) {
        OPMonitor("wb_wkwebview_init")
            .addCategoryValue("class_name", className)
            .flush()
    }
    public class func webviewLoadRequestMonitor(className: String, host: String) {
        OPMonitor("wb_wkwebview_first_load")
            .addCategoryValue("class_name", className)
            .addCategoryValue("host", host)
            .flush()
    }
}
