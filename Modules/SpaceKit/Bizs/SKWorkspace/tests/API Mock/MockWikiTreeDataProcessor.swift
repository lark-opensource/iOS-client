//
//  MockWikiTreeDataProcessor.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/8/10.
//

import Foundation
@testable import SKWorkspace

class MockWikiTreeDataProcessor: WikiTreeDataProcessorType {

    var result: Result<WikiTreeState, Error>?

    func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
        guard let result = result else {
            return .empty
        }
        return try result.get()
    }
}
