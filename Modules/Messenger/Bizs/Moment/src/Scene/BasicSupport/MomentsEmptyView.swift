//
//  NoticeEmptyView.swift
//  Moment
//
//  Created by bytedance on 2021/2/26.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignEmpty

final class MomentsEmptyView: UIView {
    lazy var emptyView: UDEmpty = {
        let view = UDEmpty(config: .init(type: .defaultPage))
        return view
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        self.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview()
        }
    }
    convenience init(frame: CGRect, description: String, type: UDEmptyType, primaryButtonConfig: (String?, (UIButton) -> Void)? = nil) {
        self.init(frame: frame)
        update(description: description, type: type, primaryButtonConfig: primaryButtonConfig)
    }
    convenience init(frame: CGRect, description: NSAttributedString, type: UDEmptyType, primaryButtonConfig: (String?, (UIButton) -> Void)? = nil,
                     operableRange: NSRange? = nil, labelHandler: (() -> Void)? = nil) {
        self.init(frame: frame)
        update(description: description, type: type, primaryButtonConfig: primaryButtonConfig, operableRange: operableRange, labelHandler: labelHandler)
    }

    func update(description: String, type: UDEmptyType, primaryButtonConfig: (String?, (UIButton) -> Void)? = nil) {
        emptyView.update(config: .init(description: .init(descriptionText: description),
                                       imageSize: 100,
                                       spaceBelowImage: 12,
                                       spaceBelowDescription: 24,
                                       type: type,
                                       primaryButtonConfig: primaryButtonConfig))
    }
    func update(description: NSAttributedString, type: UDEmptyType, primaryButtonConfig: (String?, (UIButton) -> Void)? = nil,
                operableRange: NSRange? = nil, labelHandler: (() -> Void)? = nil) {
        emptyView.update(config: .init(description: .init(descriptionText: description, operableRange: operableRange),
                                       imageSize: 100,
                                       spaceBelowImage: 12,
                                       spaceBelowDescription: 24,
                                       type: type,
                                       labelHandler: labelHandler,
                                       primaryButtonConfig: primaryButtonConfig))
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
