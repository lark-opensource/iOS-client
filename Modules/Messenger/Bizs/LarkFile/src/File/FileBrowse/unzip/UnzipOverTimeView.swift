//
//  UnzipOverTimeView.swift
//  LarkFile
//
//  Created by bytedance on 2021/11/10.
//

import Foundation
import UIKit
import UniverseDesignEmpty

final class UnzipOverTimeView: UIView {
    private lazy var emptyView: UDEmpty = {
        let view = UDEmpty(config: .init(type: .defaultPage))
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.top.equalTo(126)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(248)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setConfig(description: String, clickBlock: @escaping (UIButton) -> Void) {
        let primaryButtonConfig: (String?, (UIButton) -> Void) =
            (BundleI18n.LarkFile.Lark_IMPreviewCompress_Retry_Button, clickBlock)
        emptyView.update(config: .init(description: .init(descriptionText: description),
                                       imageSize: 60,
                                       spaceBelowImage: 8,
                                       spaceBelowDescription: 16,
                                       type: .custom(Resources.fileZip),
                                       primaryButtonConfig: primaryButtonConfig))
    }
}
