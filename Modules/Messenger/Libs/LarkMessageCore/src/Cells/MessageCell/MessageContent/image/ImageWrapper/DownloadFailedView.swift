//
//  DownloadFailedView.swift
//  LarkChat
//
//  Created by chengzhipeng-bytedance on 2018/3/22.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkMessengerInterface
import LarkContainer

final public class NoPermissonPreviewLayerView: UIView {
    public private(set) var dynamicAuthorityEnum: DynamicAuthorityEnum?
    public private(set) var previewType: SecurityControlResourceType?
    struct Style {
        static let backgroundColor: UIColor = UIColor.ud.bgFloatOverlay
        static let textFontSize: CGFloat = 14
        static let fontWeight: UIFont.Weight = .regular
        static let textColor: UIColor = UIColor.ud.textPlaceholder
        static let numberOfLines: Int = 2
        static let titleAlignment: NSTextAlignment = .center
    }

    private let label = UILabel()

    public init() {
        super.init(frame: .zero)
        self.backgroundColor = Style.backgroundColor
        label.font = UIFont.systemFont(ofSize: Style.textFontSize, weight: Style.fontWeight)
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.textColor = Style.textColor
        label.numberOfLines = Style.numberOfLines
        label.textAlignment = Style.titleAlignment

        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }
    }

    public func setLayerType(dynamicAuthorityEnum: DynamicAuthorityEnum, previewType: SecurityControlResourceType) {
        self.dynamicAuthorityEnum = dynamicAuthorityEnum
        self.previewType = previewType
        label.text = ChatSecurityControlServiceImpl.getNoPermissionSummaryText(permissionPreview: false,
                                                                               dynamicAuthorityEnum: dynamicAuthorityEnum,
                                                                               sourceType: previewType)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class CustomFailedLayerView: UIView {
    struct Style {
        static let backgroundColor: UIColor = UIColor.ud.bgFloatOverlay
        static let textFontSize: CGFloat = 14
        static let fontWeight: UIFont.Weight = .regular
        static let textColor: UIColor = UIColor.ud.textPlaceholder
        static let numberOfLines: Int = 2
        static let titleAlignment: NSTextAlignment = .center
    }

    public init(string: String) {
        super.init(frame: .zero)
        self.backgroundColor = Style.backgroundColor
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: Style.textFontSize, weight: Style.fontWeight)
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.textColor = Style.textColor
        label.numberOfLines = Style.numberOfLines
        label.text = string
        label.textAlignment = Style.titleAlignment

        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
