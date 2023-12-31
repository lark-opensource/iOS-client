//
//  AnnexView.swift
//  Calendar
//
//  Created by sunxiaolei on 2019/10/24.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignTag
import RustPB

public protocol AttachmentUIData {
    var name: String { get }
    var size: UInt64 { get }
    var isLargeAttachments: Bool { get }
    var expireTip: (String?, UIColor) { get }
    var isFileRisk: Bool { get }
    var type: CalendarEventAttachment.TypeEnum { get }
}

final class AttachmentViewStyle {
    static let width: CGFloat = 180
    static let height: CGFloat = 56
    static let itemSpacing: CGFloat = 12
}

// TODO: - Replace with EventEditAttachmentView
final class AttachmentView: UIView {
    var uiData: AttachmentUIData
    let titleLb = UILabel.cd.textLabel()
    let sizeLb = UILabel.cd.subTitleLabel(fontSize: 12)
    let tipsLb = UILabel.cd.subTitleLabel(fontSize: 12)
    let riskTag = UDTag(withText: I18n.Lark_FileSecurity_Tag_Risky)
    let imageView = UIImageView()
    let badgeView = UIView()
    let verticalBar = UIView()
    var source: Rust.CalendarEventSource?

    init(_ data: AttachmentUIData, source: Rust.CalendarEventSource?) {
        self.uiData = data
        self.source = source
        super.init(frame: .zero)
        initView()
    }

    func initView() {
        self.snp.makeConstraints({make in
            make.width.equalTo(AttachmentViewStyle.width)
            make.height.equalTo(AttachmentViewStyle.height)
        })
        
        titleLb.textColor = UIColor.ud.textTitle
        titleLb.numberOfLines = 1
        self.addSubview(titleLb)
        titleLb.snp.makeConstraints({make in
            make.left.equalToSuperview().offset(60)
            make.right.lessThanOrEqualToSuperview()
            make.top.equalToSuperview().offset(8)
        })

        riskTag.sizeClass = .mini
        riskTag.colorScheme = .red
        self.addSubview(riskTag)
        riskTag.snp.makeConstraints { make in
            make.centerY.equalTo(titleLb)
            make.left.equalTo(titleLb.snp.right).offset(4)
            make.right.lessThanOrEqualToSuperview().offset(-12).priority(.required)
        }

        sizeLb.textColor = UIColor.ud.textPlaceholder
        sizeLb.numberOfLines = 1
        self.addSubview(sizeLb)
        sizeLb.snp.makeConstraints({make in
            make.left.equalTo(titleLb)
            make.bottom.equalToSuperview().offset(-8)
        })

        verticalBar.backgroundColor = UIColor.ud.lineDividerDefault
        self.addSubview(verticalBar)
        verticalBar.snp.makeConstraints {
            $0.leading.equalTo(sizeLb.snp.trailing).offset(8)
            $0.centerY.equalTo(sizeLb)
            $0.size.equalTo(CGSize(width: 1, height: 8))
        }

        tipsLb.numberOfLines = 1
        self.addSubview(tipsLb)
        tipsLb.snp.makeConstraints {
            $0.leading.equalTo(verticalBar.snp.trailing).offset(8)
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(sizeLb)
        }

        self.addSubview(imageView)
        imageView.snp.makeConstraints({make in
            make.left.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(8)
            make.height.width.equalTo(40)
        })

        let innerImageView = UIImageView()
        innerImageView.image = UDIcon.getIconByKey(.cloudOutlined,
                                                   renderingMode: .automatic,
                                                   iconColor: UIColor.ud.primaryContentDefault)
             .ud.resized(to: CGSize(width: 8, height: 8))

        self.addSubview(badgeView)
        badgeView.addSubview(innerImageView)
        innerImageView.snp.makeConstraints {
            $0.top.equalTo(1)
            $0.bottom.equalTo(-3)
            $0.leading.equalTo(2)
            $0.trailing.equalTo(-2)
        }

        badgeView.backgroundColor = UIColor.ud.bgBody
        badgeView.layer.cornerRadius = 6
        badgeView.snp.makeConstraints {
            $0.bottom.equalTo(imageView).offset(3)
            $0.trailing.equalTo(imageView)
            $0.size.equalTo(CGSize(width: 12, height: 12))
        }

        self.layer.borderWidth = 1
        self.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        self.layer.cornerRadius = 8
        updateView()
    }

    func updateData(uiData: AttachmentUIData, source: Rust.CalendarEventSource?) {
        self.uiData = uiData
        self.source = source
        updateView()
    }

    func updateView() {
        let fileType = ((uiData.name as NSString?)?.pathExtension ?? "").lowercased()
        let commonFileType = CommonFileType(fileExtension: fileType)
        imageView.image = commonFileType.iconImage

        titleLb.text = uiData.name
        sizeLb.text = CalendarEventAttachmentEntity.sizeString(for: uiData.size)

        riskTag.isHidden = !uiData.isFileRisk

        let (tip, color) = uiData.expireTip
        tipsLb.text = tip ?? ""
        tipsLb.textColor = color

        badgeView.isHidden = !(uiData.type == .largeAttachment || uiData.type == .url)
        verticalBar.isHidden = (badgeView.isHidden || uiData.type == .url)
        
        if let source = source, source == .google {
            layoutGoogleAttachmentStyle()
        }
    }
    
    func layoutGoogleAttachmentStyle() {
        imageView.image = UDIcon.getIconByKey(.fileLinkBlueColorful, size: CGSize(width: 36, height: 36)).withRenderingMode(.alwaysOriginal)
        sizeLb.isHidden = true
        titleLb.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(60)
            make.right.lessThanOrEqualToSuperview()
            make.centerY.equalTo(imageView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
