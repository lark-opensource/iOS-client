//
//  ChatSettingDSL.swift
//  LarkOpenChat
//
//  Created by JackZhao on 2021/8/29.
//

import UIKit
import Foundation

@resultBuilder
internal struct ChatSettingItemBuilder {
    static func buildBlock<T>(_ tasks: T...) -> [T] {
        tasks
    }
}

@resultBuilder
internal struct ChatSettingSectionBuilder {
    static func buildBlock<T>(_ tasks: T...) -> [T] {
        tasks
    }
}

@resultBuilder
internal struct ChatSettingRowBuilder {
    static func buildBlock<T>(_ tasks: T...) -> [T] {
        tasks
    }
}

public struct ChatSettingTable {
    public var sections: [ChatSettingSection] = []

    func configSections(@ChatSettingSectionBuilder _ builder: () -> [ChatSettingSection]) -> Self {
        var config = self
        config.sections = builder()
        return config
    }
}

public struct ChatSettingFunctionItems {
    public var items: [String] = []

    func configItems(@ChatSettingItemBuilder _ builder: () -> [String]) -> Self {
        var config = self
        config.items = builder()
        return config
    }
}

public struct ChatSettingSearchItems {
    public var items: [String] = []

    func configItems(@ChatSettingItemBuilder _ builder: () -> [String]) -> Self {
        var config = self
        config.items = builder()
        return config
    }
}

public struct ChatSettingSection {
    public var headerTitle: String?
    public var footerTitle: String?
    public var rows: [String] = []
    public var headerHeight: CGFloat = 0
    public var footerHeight: CGFloat = 0

    func configHeaderTitle(_ title: String) -> Self {
        var config = self
        config.headerTitle = title
        return config
    }

    func configFooterTitle(_ title: String) -> Self {
        var config = self
        config.footerTitle = title
        return config
    }

    func configRows(@ChatSettingRowBuilder _ builder: () -> [String]) -> Self {
        var config = self
        config.rows = builder()
        return config
    }

    func configHeaderHeight(_ height: CGFloat) -> Self {
        var config = self
        config.headerHeight = height
        return config
    }

    func configFooterHeight(_ height: CGFloat) -> Self {
        var config = self
        config.footerHeight = height
        return config
    }
}
