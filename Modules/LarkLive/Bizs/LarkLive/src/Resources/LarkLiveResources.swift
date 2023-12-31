import Foundation

extension Bundle {

    static let current = BundleConfig.SelfBundle

    static let localResources = Bundle(url: current.url(forResource: "LarkLive", withExtension: "bundle")!)!
    
}
