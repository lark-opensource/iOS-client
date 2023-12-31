import Foundation

public protocol ProjectService {
    func cachedProjectKey(by simpleName: String) -> String?
}
