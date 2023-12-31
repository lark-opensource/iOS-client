//
//  LarkInterface+DynamicResource.swift
//  LarkTourInterface
//
//  Created by Meng on 2019/12/16.
//

import Foundation
import RxSwift
import LarkLocalizations

public struct Status: Codable {
    public let finish: Bool
    public init(finish: Bool) {
        self.finish = finish
    }
}

public enum ResourceTypeKey {
    public static let text: String = "text"
    public static let video: String = "video"
    public static let image: String = "image"
}

public protocol ResourceProtocol {
    var type: String { get }
    var value: [String: String] { get }
    var localizedValue: String? { get }
}

public protocol DynamicResourceService: AnyObject {
    func preload(statusKeys: [String], resourceKeys: [String])

    func dynamicStatus(for statusKey: String, domain: String) -> Status?
    func dynamicResource(for resourceKey: String, domain: String) -> [String: ResourceProtocol]?

    func reportFinishStatus(domain: String)
}
