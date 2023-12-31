//
//  File.swift
//  SKCommon
//
//  Created by zhysan on 2022/7/18.
//

import UIKit
import SnapKit
import SKResource
import UniverseDesignColor
import UniverseDesignTag
import UniverseDesignFont

class BitableAdPermTempCell: BitableAdPermBaseCell {
    static let defaultReuseID = "BitableAdPermTempCell"
    
    var model: BitableAdPermUnitDataTemp?
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.headline
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body2
        label.textColor = UDColor.textCaption
        label.numberOfLines = 1
        return label
    }()

    private lazy var tagView: UDTag = {
        UDTag(withText: "")
    }()

    private lazy var firstSplitView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var tipLabel: UILabel = {
        let vi = UILabel()
        vi.font = UIFont.ud.body2
        vi.textColor = UDColor.textCaption
        vi.numberOfLines = 1
        vi.text = BundleI18n.SKResource.Bitable_AdvancedPermission_UseTemplateToAddMember
        return vi
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(tagView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(firstSplitView)
        contentView.addSubview(tipLabel)

        let paddingH: CGFloat = 16.0
        let paddingV: CGFloat = 15.0

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(paddingH)
            make.top.equalToSuperview().offset(paddingV)
            make.height.equalTo(22)
        }

        tagView.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(8)
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.right.lessThanOrEqualToSuperview().offset(-paddingH)
        }

        descriptionLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(paddingH)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.bottom.equalTo(tipLabel.snp.top).offset(-paddingV)
        }

        firstSplitView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.left)
            make.bottom.equalTo(tipLabel.snp.top)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        tipLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(paddingH)
            make.bottom.equalToSuperview()
            make.height.equalTo(50)
        }
    }
    
    public func setModel(_ model: BitableAdPermUnitDataTemp) {
        self.model = model
        titleLabel.text = model.title
        
        switch model.tagType {
        case .none:
            tagView.isHidden = true
        case .origin:
            tagView.isHidden = false
            let configure = UDTag.Configuration.text(
                BundleI18n.SKResource.Bitable_AdvancedPermission_DefaultPermission,
                tagSize: .mini,
                colorScheme: UDTag.Configuration.ColorScheme.normal,
                isOpaque: false
            )
            tagView.updateConfiguration(configure)
        case .advance:
            tagView.isHidden = false
            let configure = UDTag.Configuration.text(
                BundleI18n.SKResource.Bitable_AdvancedPermission_PremiumFeatureIncludedTag,
                tagSize: .mini,
                colorScheme: UDTag.Configuration.ColorScheme.orange,
                isOpaque: false
            )
            tagView.updateConfiguration(configure)
        }
        descriptionLabel.text = model.subTitle
    }
}
