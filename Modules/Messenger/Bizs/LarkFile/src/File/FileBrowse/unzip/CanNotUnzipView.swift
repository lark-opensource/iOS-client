//
//  CannotUnzipView.swift
//  LarkFile
//
//  Created by bytedance on 2021/11/10.
//

import Foundation
import UIKit
import UniverseDesignEmpty

final class CanNotUnzipView: UIView {
    private lazy var emptyView: UDEmpty = {
        let view = UDEmpty(config: .init(type: .defaultPage))
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(112)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(248)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setConfig(description: String, clickBlock: @escaping (UIButton) -> Void) {
        let primaryButtonConfig: (String?, (UIButton) -> Void) =
            (BundleI18n.LarkFile.Lark_Legacy_OpenInAnotherApp, clickBlock)
        emptyView.update(config: .init(description: .init(descriptionText: description),
                                       imageSize: 100,
                                       spaceBelowImage: 16,
                                       spaceBelowDescription: 16,
                                       type: .noPreview,
                                       primaryButtonConfig: primaryButtonConfig))
    }
}
