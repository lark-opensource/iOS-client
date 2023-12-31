// 
// Created by duanxiaochen.7 on 2020/6/16.
// Affiliated with SKCommon.
// 
// Description:

import Foundation
import SwiftyJSON
import ThreadSafeDataStructure
import SKFoundation

public typealias CollaboratorResponse = (totalCollaboratorCount: Int, isFileOwnerFromAnotherTenant: Bool, pageLabel: String?)

public enum CollaboratorSource: Int {
    case defaultType = 0 //默认的
    case container = 1  //容器
    case singlePage  //单页面
}

extension PermissionManager {
    public final class CollaboratorStore {
        /// Collaborators for a file. Keys are file's token, values are `[Collaborator]`
        private var _collaborators: SafeDictionary<String, [Collaborator]> = [:] + .semaphore
        private var _containerCollaborators: SafeDictionary<String, [Collaborator]> = [:] + .semaphore
        private var _singlePageCollaborators: SafeDictionary<String, [Collaborator]> = [:] + .semaphore


        /// Returns collaborators for the designated augmented token.
        func collaborators(for augToken: String) -> [Collaborator] {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            return _collaborators[augToken] ?? []
        }

        /// Update collaborators for the designated augmented token.
        func updateCollaborators(for augToken: String, _ collaborators: [Collaborator]) {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            if _collaborators[augToken] == nil {
                _collaborators[augToken] = collaborators
            } else {
                var existCollaborators = _collaborators[augToken] ?? []
                for collaborator in collaborators {
                    // 如果该协作者已经存在，就先删除
                    if let index = existCollaborators.firstIndex(where: { $0.userID == collaborator.userID }) {
                        existCollaborators.remove(at: index)
                    }
                    // 添加新的协作者数据
                    existCollaborators.append(collaborator)
                }
                _collaborators[augToken] = existCollaborators
            }
        }

        /// Remove collaborators for the designated augmented token.
        func removeCollaborators(for augToken: String, _ collaborators: [Collaborator]) {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            for c in collaborators {
                _collaborators[augToken]?.removeAll(where: { c.userID == $0.userID })
            }
        }
        
        /// Remove all collaborators for the designated augmented token.
        func removeAllCollaborators(for augToken: String) {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            _collaborators[augToken] = nil
        }


        /// Returns collaborators for the designated augmented token.
        func containerCollaborators(for augToken: String) -> [Collaborator] {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            return _containerCollaborators[augToken] ?? []
        }

        /// Update collaborators for the designated augmented token.
        func updateContainerCollaborators(for augToken: String, _ collaborators: [Collaborator]) {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            if _containerCollaborators[augToken] == nil {
                _containerCollaborators[augToken] = collaborators
            } else {
                var existCollaborators = _containerCollaborators[augToken] ?? []
                for collaborator in collaborators {
                    // 如果该协作者已经存在，就先删除
                    if let index = existCollaborators.firstIndex(where: { $0.userID == collaborator.userID }) {
                        existCollaborators.remove(at: index)
                    }
                    // 添加新的协作者数据
                    existCollaborators.append(collaborator)
                }
                _containerCollaborators[augToken] = existCollaborators
            }
        }

        /// Remove collaborators for the designated augmented token.
        func removeContainerCollaborators(for augToken: String, _ collaborators: [Collaborator]) {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            for c in collaborators {
                _containerCollaborators[augToken]?.removeAll(where: { c.userID == $0.userID })
            }
        }

        /// Returns collaborators for the designated augmented token.
        func singlePageCollaborators(for augToken: String) -> [Collaborator] {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            return _singlePageCollaborators[augToken] ?? []
        }

        /// Update collaborators for the designated augmented token.
        func updateSinglePageCollaborators(for augToken: String, _ collaborators: [Collaborator]) {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            if _singlePageCollaborators[augToken] == nil {
                _singlePageCollaborators[augToken] = collaborators
            } else {
                var existCollaborators = _singlePageCollaborators[augToken] ?? []
                for collaborator in collaborators {
                    // 如果该协作者已经存在，就先删除
                    if let index = existCollaborators.firstIndex(where: { $0.userID == collaborator.userID }) {
                        existCollaborators.remove(at: index)
                    }
                    // 添加新的协作者数据
                    existCollaborators.append(collaborator)
                }
                _singlePageCollaborators[augToken] = existCollaborators
            }
        }

        /// Remove collaborators for the designated augmented token.
        func removeSinglePageCollaborators(for augToken: String, _ collaborators: [Collaborator]) {
            spaceAssert(augToken.contains("_"), "You have to augment the objToken with the user's UserID to prevent data leakage between tenants!")
            for c in collaborators {
                _singlePageCollaborators[augToken]?.removeAll(where: { c.userID == $0.userID })
            }
        }

        /// Clear stores when exiting a docs/sheets
        public func clear() {
            _collaborators.removeAll()
            _containerCollaborators.removeAll()
            _singlePageCollaborators.removeAll()
        }
    }

    /// Find in local store the collaborators for a designated file
    /// - Parameters:
    ///   - token: file's `objToken`
    ///   - type: file's `DocsType.rawValue`
    public func getCollaborators(for token: String, collaboratorSource: CollaboratorSource) -> [Collaborator]? {
        switch collaboratorSource {
        case .defaultType:
            return collaboratorStore.collaborators(for: augmentedToken(of: token))
        case .container:
            return collaboratorStore.containerCollaborators(for: augmentedToken(of: token))
        case .singlePage:
            return collaboratorStore.singlePageCollaborators(for: augmentedToken(of: token))
        }
    }

    /// Use this method to update collaborators for files instead of using directly `collaboratorStore.updateCollaborators(for:_:)`.
    /// - Parameter permissions: `[token: [Collaborator]]`
    public func updateCollaborators(_ collaborators: [String: [Collaborator]], collaboratorSource: CollaboratorSource) {
        collaborators.forEach { token, cos in
            switch collaboratorSource {
            case .defaultType:
                collaboratorStore.updateCollaborators(for: augmentedToken(of: token), cos)
            case .container:
                collaboratorStore.updateContainerCollaborators(for: augmentedToken(of: token), cos)
            case .singlePage:
                collaboratorStore.updateSinglePageCollaborators(for: augmentedToken(of: token), cos)
            }
        }
    }

    /// Use this method to remove collaborators for files instead of using directly `collaboratorStore.removeCollaborators(for:_:)`.
    /// - Parameter permissions: `[token: [Collaborator]]`
    public func removeCollaborators(_ collaborators: [String: [Collaborator]], collaboratorSource: CollaboratorSource) {
        collaborators.forEach { token, cos in
            switch collaboratorSource {
            case .defaultType:
                collaboratorStore.removeCollaborators(for: augmentedToken(of: token), cos)
            case .container:
                collaboratorStore.removeContainerCollaborators(for: augmentedToken(of: token), cos)
            case .singlePage:
                collaboratorStore.removeSinglePageCollaborators(for: augmentedToken(of: token), cos)
            }
        }

    }

}
