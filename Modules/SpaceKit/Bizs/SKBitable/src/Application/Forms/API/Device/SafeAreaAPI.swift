import Foundation
import LarkOpenAPIModel
import SKFoundation

final class FormsSafeAreaResult: OpenAPIBaseResult {

    override func toJSONDict() -> [AnyHashable: Any] {
        [
            "top": "env(safe-area-inset-top)"
        ]
    }
    
}
