//
//  IsolateSandbox+Path.swift
//  LarkStorage
//
//  Created by 7Up on 2022/5/20.
//

import Foundation

extension IsolateSandbox {

    // MARK: Core Root

    public func rootPath(forType type: RootPathType.Normal) -> IsoPath {
        let base = Self.rootPath(withSpace: space, domain: domain, type: type)
        let wrapped = SandboxIsoCommonCryptoProxy(wrapped: wrapped)
        let ret = IsoPath(base: base, sandbox: wrapped)
        log.info("rootPath: \(ret.debugDescription)")
        return ret
    }

    func sharedRootPath(forType type: RootPathType.Shared) -> IsoPath? {
        guard let base = Self.rootPath(withSpace: space, domain: domain, type: type) else {
            return nil
        }
        let wrapped = SandboxIsoCommonCryptoProxy(wrapped: wrapped)
        let ret = IsoPath(base: base, sandbox: wrapped)
        log.debug("rootPath: \(ret.debugDescription)")
        return ret
    }

    // MARK: Convenience

    // TODO: 考虑类似于"../xxx"的relativePart
    func path(forType type: RootPathType.Normal, relativePart: String) -> IsoPath {
        return rootPath(forType: type).appendingRelativePath(relativePart)
    }

    func sharedPath(forType type: RootPathType.Shared, relativePart: String) -> IsoPath? {
        guard let rootPath = sharedRootPath(forType: type) else {
            return nil
        }
        return rootPath.appendingRelativePath(relativePart)
    }

}
