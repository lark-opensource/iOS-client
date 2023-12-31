import Foundation
public extension URL {
    var safeURLString: String {
        (self as NSURL).safeURLString() ?? ""
    }
}
public extension String {
    var safeURLString: String {
        (self as NSString).safeURL() ?? ""
    }
}
