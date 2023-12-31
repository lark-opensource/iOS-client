//
//  GeneralModules.swift
//  LarkOpenSetting
//
//  Created by panbinghua on 2022/6/16.
//

import Foundation
import UIKit
import EENavigator
import LarkContainer
import LarkSettingUI
import LarkNavigator

public final class GeneralBlockModule: BaseModule {
    let onClickBlock: (UserResolver, UIViewController) -> Void
    let title: String
    let headerStr: String?
    let footerStr: String?

    public init(
        userResolver: UserResolver,
        title: String,
         headerStr: String? = nil,
         footerStr: String? = nil,
        onClickBlock: @escaping ((UserResolver, UIViewController) -> Void) ) {
        self.onClickBlock = onClickBlock
        self.title = title
        self.headerStr = headerStr
        self.footerStr = footerStr
        super.init(userResolver: userResolver)
    }

    public override func createCellProps(_ key: String) -> [CellProp]? {
        let item = NormalCellProp(title: title, showArrow: true, onClick: { [weak self] _ in
            if let self = self, let vc = self.context?.vc {
                self.onClickBlock(self.userResolver, vc)
            }
        })
        return [item]
    }

    public override func createSectionProp(_ key: String) -> SectionProp? {
        guard let items = createCellProps("") else { return nil }
        let header: HeaderFooterType
        let footer: HeaderFooterType
        if let str = headerStr {
            header = .title(str)
        } else {
            header = .normal
        }
        if let str = footerStr {
            footer = .title(str)
        } else {
            footer = .normal
        }
        let section = SectionProp(items: items, header: header, footer: footer)
        return section
    }
}

public final class GeneralURLModule: BaseModule {
    let title: String
    let detail: String?
    let url: URL
    public var onClick: (() -> Void)? // 埋点使用

    public init(userResolver: UserResolver, title: String, detail: String? = nil, url: URL) {
        self.url = url
        self.title = title
        self.detail = detail
        super.init(userResolver: userResolver)
    }

    public override func createCellProps(_ key: String) -> [CellProp]? {
        let item = NormalCellProp(title: title,
                                         detail: detail,
                                         accessories: [.arrow()],
                                         onClick: { [weak self] _ in
            guard let self = self, let vc = self.context?.vc else { return }
            self.onClick?()
            self.userResolver.navigator.push(self.url, from: vc)
        })
        return [item]
    }

    public override func createSectionProp(_ key: String) -> SectionProp? {
        guard let items = createCellProps("") else { return nil }
        let section = SectionProp(items: items)
        return section
    }
}
