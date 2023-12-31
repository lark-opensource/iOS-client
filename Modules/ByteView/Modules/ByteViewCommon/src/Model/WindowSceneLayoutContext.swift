//
//  WindowSceneLayoutContext.swift
//  ByteViewCommon
//
//  Created by kiri on 2023/11/1.
//

import Foundation
import UIKit

public struct WindowSceneLayoutContext: Equatable {
    public var interfaceOrientation: UIInterfaceOrientation
    public var traitCollection: UITraitCollection
    public var coordinateSpace: UICoordinateSpace
    public init(interfaceOrientation: UIInterfaceOrientation, traitCollection: UITraitCollection, coordinateSpace: UICoordinateSpace) {
        self.interfaceOrientation = interfaceOrientation
        self.traitCollection = traitCollection
        self.coordinateSpace = coordinateSpace
    }

    public static func == (lhs: WindowSceneLayoutContext, rhs: WindowSceneLayoutContext) -> Bool {
        lhs.interfaceOrientation == rhs.interfaceOrientation
        && lhs.traitCollection == rhs.traitCollection
        && lhs.coordinateSpace.bounds == rhs.coordinateSpace.bounds
    }
}
