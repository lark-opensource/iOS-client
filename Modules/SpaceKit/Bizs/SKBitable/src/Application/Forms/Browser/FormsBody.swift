import EENavigator
import Foundation

public struct FormsBody: CodablePlainBody {
    
    public static let pattern: String = "//client/base/forms"

    public let url: URL

    /// 是否每次push新页面
    public var forcePush: Bool?

    public init(url: URL) {
        self.url = url
        self.forcePush = true
    }
    
}
