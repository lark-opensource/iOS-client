//
//  MockWikiTreeConverter.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/8/16.
//

import Foundation
@testable import SKWorkspace

class MockWikiTreeConverter: WikiTreeConverterType {
    var result: [NodeSection] = []
    func convert(rootList: [(TreeNodeRootSection, String)]) -> [NodeSection] { result }
}

class MockWikiPickerTreeConverterProvider: WikiPickerTreeConverterProviderType {
    var disabledToken: String?

    weak var clickHandler: WikiTreeConverterClickHandler?
    var converter: WikiTreeConverterType

    init(converter: WikiTreeConverterType) {
        self.converter = converter
    }

    func converter(treeState: WikiTreeState) -> WikiTreeConverterType {
        converter
    }

    func converter(treeState: WikiTreeState, config: WikiTreeConverterConfig) -> WikiTreeConverterType {
        converter
    }

    static var `default`: MockWikiPickerTreeConverterProvider {
        MockWikiPickerTreeConverterProvider(converter: MockWikiTreeConverter())
    }

    static func mock(result: [NodeSection]) -> MockWikiPickerTreeConverterProvider {
        let converter = MockWikiTreeConverter()
        converter.result = result
        return MockWikiPickerTreeConverterProvider(converter: converter)
    }
}

class MockMainTreeConverterProvider: WikiMainTreeConverterProviderType {

    weak var clickHandler: WikiTreeConverterClickHandler?

    var converter: WikiTreeConverterType

    init(converter: WikiTreeConverterType) {
        self.converter = converter
    }

    func converter(treeState: WikiTreeState, isReachable: Bool) -> WikiTreeConverterType {
        converter
    }

    func converter(treeState: WikiTreeState, config: WikiTreeConverterConfig) -> WikiTreeConverterType {
        converter
    }

    static var `default`: WikiMainTreeConverterProviderType {
        MockMainTreeConverterProvider(converter: MockWikiTreeConverter())
    }

    static func mock(result: [NodeSection]) -> WikiMainTreeConverterProviderType {
        let converter = MockWikiTreeConverter()
        converter.result = result
        return MockMainTreeConverterProvider(converter: converter)
    }
}
