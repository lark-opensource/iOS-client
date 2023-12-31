//
//  Patch.swift
//  LarkOrientation
//
//  Created by 李晨 on 2020/2/27.
//

import UIKit
import Foundation

extension Orientation {
    public typealias PatchOptionSet = [PatchOption]

    public enum PatchOption {
        case shouldAutorotate(Bool)
        case supportedInterfaceOrientations(UIInterfaceOrientationMask)
        case preferredInterfaceOrientationForPresentation(UIInterfaceOrientation)
    }

    public struct PatchOptionInfo {
        var shouldAutorotate: Bool?
        var supportedInterfaceOrientations: UIInterfaceOrientationMask?
        var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation?

        init(_ options: PatchOptionSet) {
            options.forEach { (option) in
                switch option {
                    case .shouldAutorotate(let value):
                        self.shouldAutorotate = value
                    case .supportedInterfaceOrientations(let value):
                        self.supportedInterfaceOrientations = value
                    case .preferredInterfaceOrientationForPresentation(let value):
                        self.preferredInterfaceOrientationForPresentation = value
                }
            }
        }
    }

    public struct Patch {
        public var identifier: String
        public var description: String
        public var optionInfo: PatchOptionInfo
        public var supportDevices: [UIUserInterfaceIdiom]
        public var matcher: (_ vc: UIViewController) -> Bool

        public init(
            identifier: String,
            description: String,
            options: PatchOptionSet,
            supportDevices: [UIUserInterfaceIdiom] = [.phone],
            matcher: @escaping (_ vc: UIViewController) -> Bool) {
            self.identifier = identifier
            self.description = description
            self.optionInfo = PatchOptionInfo(options)
            self.supportDevices = supportDevices
            self.matcher = matcher
        }
    }
}
