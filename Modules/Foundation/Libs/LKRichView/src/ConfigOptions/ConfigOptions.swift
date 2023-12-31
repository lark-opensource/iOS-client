//
//  ConfigOptions.swift
//  LKRichView
//
//  Created by qihongye on 2021/8/30.
//

import UIKit
import Foundation

infix operator <==

public struct ConfigOptions {
    fileprivate var storage: [Int8: ConfigOption]!

    public init(_ options: [ConfigOption] = []) {
        storage = buildDefaultStorage()
        for option in options {
            storage[option.rawValue] = option
        }
    }

    @inline(__always)
    func buildDefaultStorage() -> [Int8: ConfigOption] {
        let logger: ConfigOption = .logger(Logger())
        #if DEBUG
        let debug: ConfigOption = .debug(true)
        #else
        let debug: ConfigOption = .debug(false)
        #endif
        let magnifier: ConfigOption = .magnifier {
            let magnifier = TextMagnifier(configuration: .default)
//            if #available(iOS 15, *) {
//                magnifier = TextMagnifierForIOS15()
//            } else {
//                magnifier = TextMagnifier(configuration: .default)
//            }
            return magnifier
        }
        let startCursor: ConfigOption = .startCursor {
            SelectionCursor(type: .start)
        }
        let endCursor: ConfigOption = .endCursor {
            SelectionCursor(type: .end)
        }
        return [
            logger.rawValue: logger,
            debug.rawValue: debug,
            magnifier.rawValue: magnifier,
            startCursor.rawValue: startCursor,
            endCursor.rawValue: endCursor
        ]
    }

    @discardableResult
    static func <== (_ lhs: inout ConfigOptions, _ rhs: ConfigOption) -> ConfigOptions {
        lhs.storage[rhs.rawValue] = rhs
        return lhs
    }

    public var log: Log? {
        if let option = storage[ConfigOption.logger], case .logger(let logger) = option {
            return logger
        }
        return nil
    }

    public var debug: Bool {
        if let option = storage[ConfigOption.debug], case .debug(let debug) = option {
            return debug
        }
        return false
    }

    /// DEBUG模式下，都开启此优化，能尽可能发现问题
    public var fixSplitForTextRunBox: Bool {
        #if DEBUG
        return true
        #else
        if let option = storage[ConfigOption.fixSplitForTextRunBox], case .fixSplitForTextRunBox(let fix) = option {
            return fix
        }
        return false
        #endif
    }

    private var _magnifier: Magnifier?
    @inline(__always)
    public var hasMagnifier: Bool { _magnifier != nil }
    public var magnifier: Magnifier {
        mutating get {
            if let magnifier = _magnifier {
                return magnifier
            }
            if let option = storage[ConfigOption.magnifier], case .magnifier(let factory) = option {
                let magnifier = factory()
                self._magnifier = magnifier
                return magnifier
            }

            let magnifier = TextMagnifier(configuration: .default)
//            if #available(iOS 15, *) {
//                magnifier = TextMagnifierForIOS15()
//            } else {
//                magnifier = TextMagnifier(configuration: .default)
//            }
            self._magnifier = magnifier
            return magnifier
        }
    }

    private var _startCursor: Cursor?
    public var startCursor: Cursor {
        mutating get {
            if let cursor = _startCursor {
                return cursor
            }
            if let option = storage[ConfigOption.startCursor], case .startCursor(let factory) = option {
                let cursor = factory()
                self._startCursor = cursor
                return cursor
            }
            let cursor = SelectionCursor(type: .start)
            self._startCursor = cursor
            return cursor
        }
    }

    private var _endCursor: Cursor?
    public var endCursor: Cursor {
        mutating get {
            if let cursor = _endCursor {
                return cursor
            }
            if let option = storage[ConfigOption.endCursor], case .endCursor(let factory) = option {
                let cursor = factory()
                self._endCursor = cursor
                return cursor
            }
            let cursor = SelectionCursor(type: .end)
            self._endCursor = cursor
            return cursor
        }
    }

    public var touchesInsects: UIEdgeInsets {
        if let option = storage[ConfigOption.touchesInsets], case .touchesInsets(let insets) = option {
            return insets
        }
        return .zero
    }

    public var visualConfig: VisualConfig? {
        if let option = storage[ConfigOption.visualConfig], case .visualConfig(let config) = option {
            return config
        }
        return nil
    }

    public var maxHeightBuffer: CGFloat {
        if let option = storage[ConfigOption.maxHeightBuffer], case .maxHeightBuffer(let buffer) = option {
            return buffer
        }
        return 0
    }

    mutating func bindVisulConfigToCuosor() {
        guard let visualConfig = self.visualConfig else {
            return
        }
        startCursor.fillColor = visualConfig.cursorColor
        startCursor.hitTestInsects = visualConfig.cursorHitTestInsets
        endCursor.fillColor = visualConfig.cursorColor
        endCursor.hitTestInsects = visualConfig.cursorHitTestInsets
    }
}

public struct VisualConfig {
    public let selectionColor: UIColor
    public let cursorColor: UIColor
    public let cursorHitTestInsets: UIEdgeInsets

    public init(selectionColor: UIColor, cursorColor: UIColor, cursorHitTestInsets: UIEdgeInsets) {
        self.selectionColor = selectionColor
        self.cursorColor = cursorColor
        self.cursorHitTestInsets = cursorHitTestInsets
    }
}

public enum ConfigOption {
    typealias RawValue = Int8

    static let logger: RawValue = 0
    static let debug: RawValue = 1
    static let magnifier: RawValue = 2
    static let startCursor: RawValue = 3
    static let endCursor: RawValue = 4
    static let touchesInsets: RawValue = 5
    static let visualConfig: RawValue = 6
    static let maxHeightBuffer: RawValue = 7
    static let fixSplitForTextRunBox: RawValue = 8

    /// 日志打印
    case logger(Log)
    case debug(Bool)
    /// selection放大镜
    case magnifier(() -> Magnifier)
    /// selection开始、结束光标
    case startCursor(() -> Cursor)
    case endCursor(() -> Cursor)
    /// 热区扩大（目前没实现）
    case touchesInsets(UIEdgeInsets)
    /// selection配置：颜色、热区
    case visualConfig(VisualConfig)
    /// 假如超出100会展示show more、buffer为20，那么100-120内会把所有内容都展示出来，不展示show more，因为展开20用户可能也无感知
    /// 只应该对最外层的ContainerRunBox生效，目前的逻辑所有ContainerRunBox都会生效，需要修正
    case maxHeightBuffer(CGFloat)
    /// TextRunBox中的split逻辑，在ByWord模式会出现word被截断的情况
    case fixSplitForTextRunBox(Bool)

    var rawValue: RawValue {
        switch self {
        case .logger:
            return Self.logger
        case .debug:
            return Self.debug
        case .magnifier:
            return Self.magnifier
        case .startCursor:
            return Self.startCursor
        case .endCursor:
            return Self.endCursor
        case .touchesInsets:
            return Self.touchesInsets
        case .visualConfig:
            return Self.visualConfig
        case .maxHeightBuffer:
            return Self.maxHeightBuffer
        case .fixSplitForTextRunBox:
            return Self.fixSplitForTextRunBox
        }
    }

    static func + (_ lhs: ConfigOption, _ rhs: ConfigOption) -> ConfigOptions {
        return ConfigOptions([lhs, rhs])
    }
}

func + (_ lhs: ConfigOptions, _ rhs: ConfigOption) -> ConfigOptions {
    var result = lhs
    return result <== rhs
}
