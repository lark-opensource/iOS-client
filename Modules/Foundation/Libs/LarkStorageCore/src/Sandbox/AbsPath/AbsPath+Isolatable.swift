//
//  AbsPath+Isolatable.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

private let sep = "-"
private let spacePrefix = "Space"
private let domainPrefix = "Domain"

extension Space {
    var pathComponent: String {
        "\(spacePrefix)\(sep)\(self.isolationId)"
    }
}

extension DomainType {
    var pathComponent: String {
        ([domainPrefix] + asComponents().map(\.isolationId)).joined(separator: sep)
    }
}

extension AbsPath {
    static let basePathComponent = "LarkStorage"

    static func rootPath(for type: RootPathType.Normal) -> AbsPath {
        builtInPath(for: type) + basePathComponent
    }

    static func rootPath(for type: RootPathType.Shared, appGroupId: String) -> AbsPath? {
        guard let root = builtInPath(for: type, appGroupId: appGroupId) else {
            return nil
        }
        return root + basePathComponent
    }

    func appendingComponent(with space: Space) -> AbsPath {
        return self + space.pathComponent
    }

    func appendingComponent(with domain: DomainType) -> AbsPath {
        return self + domain.pathComponent
    }

}
