//
//  SyncBlockReferenceItemCell.swift
//  SKDoc
//
//  Created by lijuyou on 2023/8/6.
//

import Foundation
import SKFoundation
import SKUIKit
import SKResource
import SKCommon
import SKInfra
import SpaceInterface
import UniverseDesignColor
import LarkDocsIcon
import LarkContainer
import UniverseDesignTag


class SyncBlockReferenceItemCell: UITableViewCell {
    
    struct Layout {
        static let titleHorzMargin = CGFloat(12)
    }
    private lazy var iconView = UIImageView(frame: .zero).construct { it in
        it.layer.cornerRadius = 12
        it.layer.masksToBounds = true
    }

    private lazy var titleLabel = UILabel(frame: .zero).construct { it in
        it.font = .systemFont(ofSize: 17)
        it.textColor = UDColor.textTitle
        it.textAlignment = .left
        it.numberOfLines = 1
        it.lineBreakMode = .byTruncatingTail
        it.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    private lazy var sourceTag = UDTag(withText:  BundleI18n.SKResource.LarkCCM_Docs_SyncBlock_Origin_Tag).construct { it in
        it.sizeClass = .mini
        it.isHidden = true
    }
    
    private lazy var currentTag = UDTag(withText: BundleI18n.SKResource.LarkCCM_Docs_SyncBlock_Current_Tag).construct { it in
        it.sizeClass = .mini
        it.isHidden = true
    }
    
    private lazy var tagStackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.axis = .horizontal
//        view.distribution = .fillProportionally
        view.spacing = 6
        return view
    }()
    
    private lazy var bgView = UIView().construct { it in
        it.backgroundColor = UDColor.fillPressed
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectedBackgroundView = bgView
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(17)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(37)
        }
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(iconView.snp.trailing).offset(Layout.titleHorzMargin)
            make.trailing.equalToSuperview().offset(-Layout.titleHorzMargin)
            make.centerY.equalToSuperview()
        }
        contentView.docs.addStandardHover()
        contentView.addSubview(tagStackView)
        tagStackView.snp.makeConstraints { (make) in
            make.leading.equalTo(iconView.snp.trailing).offset(Layout.titleHorzMargin)
            make.trailing.lessThanOrEqualTo(contentView).offset(-Layout.titleHorzMargin)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
            make.height.equalTo(18)
        }
        tagStackView.addArrangedSubview(self.sourceTag)
        tagStackView.addArrangedSubview(self.currentTag)
    }

    func update(_ info: SyncBlockReferenceItem) {
        
        if !info.permitted {
            titleLabel.textColor = UDColor.textDisabled
            iconView.alpha = 0.5
        } else {
            titleLabel.textColor = UDColor.textTitle
            iconView.alpha = 1
        }

        iconView.di.setDocsImage(iconInfo: "", url: info.url, userResolver: Container.shared.getCurrentUserResolver())
        titleLabel.text = info.title.isEmpty ? DocsType.docX.untitledString : info.title
        
        if info.isSource || info.isCurrent {
            tagStackView.isHidden = false
            self.sourceTag.isHidden = true
            self.currentTag.isHidden = true
            
            titleLabel.snp.remakeConstraints { (make) in
                make.leading.equalTo(iconView.snp.trailing).offset(Layout.titleHorzMargin)
                make.trailing.equalToSuperview().offset(-Layout.titleHorzMargin)
                make.top.equalToSuperview().inset(11)
            }
            if info.isSource {
                self.sourceTag.isHidden = false
            }
            if info.isCurrent {
                self.currentTag.isHidden = false
            }
        } else {
            tagStackView.isHidden = true
            titleLabel.snp.remakeConstraints { (make) in
                make.leading.equalTo(iconView.snp.trailing).offset(Layout.titleHorzMargin)
                make.trailing.equalToSuperview().offset(-Layout.titleHorzMargin)
                make.centerY.equalToSuperview()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class SyncBlockReferenceListFooterView: UIView {
    
    private lazy var titleLabel = UILabel(frame: .zero).construct { it in
        it.font = .systemFont(ofSize: 14)
        it.textAlignment = .left
        it.textColor = UDColor.textPlaceholder
        it.numberOfLines = 2
        it.lineBreakMode = .byWordWrapping
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.trailing.equalToSuperview().offset(-18)
            make.top.equalToSuperview().inset(14)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(title: String) {
        self.titleLabel.text = title
    }
}
