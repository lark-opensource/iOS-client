//
//  BaseFlagTableCellViewModel.swift
//  LarkFeed
//
//  Created by phoenix on 2022/5/10.
//

import Foundation
import LarkModel
import LarkCore
import LarkExtensions
import RustPB
import RxSwift
import LarkFeatureGating
import LarkSetting
import LarkContainer

public protocol FlagContent {
    var source: String { get }
    var detailLocation: String { get }
    var detailTime: String { get }
}

public class BaseFlagTableCellViewModel: UserResolverWrapper {
    public var userResolver: UserResolver { dataDependency.userResolver }
    public class var identifier: String {
        assertionFailure("need override in subclass")
        return String(describing: BaseFlagTableCellViewModel.self)
    }
    public var identifier: String {
        assertionFailure("need override in subclass")
        return BaseFlagTableCellViewModel.identifier
    }

    public var content: FlagContent
    public var dataDependency: FlagDataDependency
    public var flag: RustPB.Feed_V1_FlagItem

    // For iPad: 选中态，标示 Cell 是否被选中
    public var selected: Bool = false

    public let disposeBag: DisposeBag = DisposeBag()

    public var source: String {
        content.source
    }

    public private(set) lazy var shortTime: String = {
        TimeInterval(self.flag.updateTime)
            .lf.cacheFormat("pin_s", formater: { $0.lf.formatedDate(onlyShowDay: false) })
    }()

    public var detailLocation: String {
        return content.detailLocation
    }
    public var detailTime: String {
        return content.detailTime
    }

    public var isRisk: Bool {
        guard userResolver.fg.staticFeatureGatingValue(with: "messenger.file.detect") else { return false }
        if let content = content as? MessageFlagContent {
            return !content.message.riskObjectKeys.isEmpty
        }
        return false
    }

    public init(flag: RustPB.Feed_V1_FlagItem, content: FlagContent, dataDependency: FlagDataDependency) {
        self.flag = flag
        self.content = content
        self.dataDependency = dataDependency
    }

    public func willDisplay() {
    }

    public func didEndDisplay() {
    }
}
