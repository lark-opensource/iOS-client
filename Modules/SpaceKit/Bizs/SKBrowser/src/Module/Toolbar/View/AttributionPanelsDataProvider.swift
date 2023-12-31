//
//  AttributionPanelsDataProvider.swift
//  SKCommon
//
//  Created by Webster on 2020/6/19.
//

import Foundation

public protocol AdjustPanelDataProviderDelegate: AnyObject {
    func didModifyToNewValue(value: String, provider: AdjustAttributionPanelDataProvider)
}

public final class AdjustAttributionPanelDataProvider: AdjustAttributionPanelDelegate {

    public var fontArrays: [String] = [String]()
    private var fontIndex: Int = -1
    public weak var delegate: AdjustPanelDataProviderDelegate?
    public init() {}
    public func nextBiggerValue(in panel: AdjustAttributionPanel, value: String) -> String {
        let index = fontArrays.firstIndex { (data) -> Bool in
            data.elementsEqual(value)
        }
        if let dstIndex = index, (dstIndex + 1) < fontArrays.count {
            fontIndex = (dstIndex + 1)
            return fontArrays[fontIndex]
        } else {
            return value
        }
    }

    public func nextSmallValue(in panel: AdjustAttributionPanel, value: String) -> String {
        let index = fontArrays.firstIndex { (data) -> Bool in
            data.elementsEqual(value)
        }
        if let dstIndex = index, (dstIndex - 1) >= 0 {
            fontIndex = (dstIndex - 1)
            return fontArrays[fontIndex]
        } else {
            return value
        }
    }

    public func canBiggerNow(in panel: AdjustAttributionPanel, value: String) -> Bool {
        let index = fontArrays.firstIndex { (data) -> Bool in
            data.elementsEqual(value)
        }
        guard let dstIndex = index else { return false }
        return (dstIndex + 1) < fontArrays.count
    }

    public func canSmallNow(in panel: AdjustAttributionPanel, value: String) -> Bool {
        let index = fontArrays.firstIndex { (data) -> Bool in
            data.elementsEqual(value)
        }
        guard let dstIndex = index else { return false }
        return (dstIndex - 1) >= 0
    }

    public func hasUpdateValue(value: String, in panel: AdjustAttributionPanel) {
        delegate?.didModifyToNewValue(value: value, provider: self)
    }
}
