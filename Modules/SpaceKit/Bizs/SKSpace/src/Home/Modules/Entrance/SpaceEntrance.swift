//
//  SpaceEntrance.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/1.
//

import Foundation
import RxSwift
import RxRelay
import SKResource

public extension SpaceEntrance {
    enum Action {
        case push(viewController: UIViewController)
        case presentOrPush(viewController: UIViewController, popoverConfiguration: ((UIViewController) -> Void)?)
        case showDetail(viewController: UIViewController)
    }
    typealias ClickHandler = (SpaceEntrance) -> Action?
}

// 用于描述金刚位中的一个 item
public struct SpaceEntrance {
    /// 唯一标识
    public let identifier: String
    public let image: UIImage
    // 按钮背景主题色，新首页用
    public let themeColor: UIColor?
    public let title: String
    public let clickHandler: ClickHandler?
    public let redDotVisableRelay: BehaviorRelay<Bool>

    public init(identifier: String, image: UIImage, themeColor: UIColor? = nil, title: String, needRedDot: Bool = false, clickHandler: ClickHandler?) {
        self.identifier = identifier
        self.image = image
        self.themeColor = themeColor
        self.title = title
        self.redDotVisableRelay = BehaviorRelay<Bool>(value: needRedDot)
        self.clickHandler = clickHandler
    }
}

public protocol SpaceEntranceConvertible {
    func asEntrances() -> [SpaceEntrance]
}

extension SpaceEntrance: SpaceEntranceConvertible {
    public func asEntrances() -> [SpaceEntrance] { [self] }
}

extension Array: SpaceEntranceConvertible where Element: SpaceEntranceConvertible {
    public func asEntrances() -> [SpaceEntrance] { flatMap { $0.asEntrances() } }
}

@resultBuilder
public struct SpaceEntranceBuilder {
    public static func buildBlock() -> [SpaceEntrance] { [] }
    public static func buildBlock(_ sections: SpaceEntranceConvertible...) -> [SpaceEntrance] { sections.flatMap { $0.asEntrances() } }
    public static func buildIf(_ value: SpaceEntranceConvertible?) -> SpaceEntranceConvertible { value ?? [SpaceEntrance]() }
    public static func buildEither(first: SpaceEntranceConvertible) -> SpaceEntranceConvertible { first }
    public static func buildEither(second: SpaceEntranceConvertible) -> SpaceEntranceConvertible { second }

}
