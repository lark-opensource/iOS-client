//
//  SpaceHistoryFolderView.swift
//  SKECM
//
//  Created by guoqp on 2021/5/15.
//

import Foundation
import SKFoundation
import SKResource

public protocol SpaceHistoryFolderViewDelegate: AnyObject {
    func shouldOpenHistoryFolder(_ historyFolderView: SpaceHistoryFolderView)
}


private let titleLabelFont = UIFont.docs.pfsc(14)
public final class SpaceHistoryFolderView: UIView {
    public weak var delegate: SpaceHistoryFolderViewDelegate?

    private var iconView: UIImageView = {
        let v = UIImageView(frame: CGRect.zero)
        v.image = BundleResources.SKResource.Space.FileList.icon_permisson_isv_tip.withRenderingMode(.alwaysTemplate)
        return v
    }()
    public var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = titleLabelFont
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.textAlignment = .left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textColor = UIColor.ud.N900
        return label
    }()
    public var linkLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = titleLabelFont
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.textAlignment = .left
        label.textColor = UIColor.ud.colorfulBlue
        label.isUserInteractionEnabled = true
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        return label
    }()

    var tap: (() -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.B100
        self.addSubview(self.iconView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.linkLabel)

        iconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
//            make.centerY.equalToSuperview()
            make.top.equalToSuperview().offset(14)
            make.height.width.equalTo(16)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalTo(iconView.snp.centerY)
            make.left.equalTo(iconView.snp.right).offset(8)
            make.right.equalToSuperview().offset(-16)
        }

        linkLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-12)
            make.left.equalTo(titleLabel.snp.left)
        }

        titleLabel.text = BundleI18n.SKResource.CreationMobile_ECM_FileMigration_Banner_notice
        linkLabel.text = BundleI18n.SKResource.CreationMobile_ECM_FileMigration_Banner_notice_redirect
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapTitleLable(_:)))
        self.linkLabel.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func tapTitleLable(_ ges: UITapGestureRecognizer) {
        self.delegate?.shouldOpenHistoryFolder(self)
    }
}
