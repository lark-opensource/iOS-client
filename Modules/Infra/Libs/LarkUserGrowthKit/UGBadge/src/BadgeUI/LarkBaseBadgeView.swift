//
//  LarkBaseBadgeView.swift
//  UGBadge
//
//  Created by liuxianyu on 2021/11/30.
//

import Foundation
import UIKit
import RustPB
import RxSwift
import UniverseDesignBadge

public final class LarkBaseBadgeView: UIView {
    private let disposeBag = DisposeBag()
    public weak var delegate: LarkBadgeDelegate?

    public let badgeData: LarkBadgeData
    let contentView = UIControl()
    var badgeWidth: CGFloat

    public init(badgeData: LarkBadgeData, badgeWidth: CGFloat) {
        self.badgeData = badgeData
        self.badgeWidth = badgeWidth
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(contentView)
    }

    func getContentSize() -> CGSize {
        return .zero
    }

    func update(badgeWidth: CGFloat) -> CGFloat {
        self.badgeWidth = badgeWidth
        return self.getContentSize().height
    }
}

public protocol LarkBadgeDelegate: AnyObject {
    func onBadgeShow()
}
