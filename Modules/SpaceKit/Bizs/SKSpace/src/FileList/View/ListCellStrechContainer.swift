//
//  ListCellStrechContainer.swift
//  SKECM
//
//  Created by bupozhuang on 2020/7/31.
//

import UIKit
import SnapKit
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignTag

class ListCellStrechContainer: UIView {

    var showTemplateTag: Bool = false {
        didSet {
            templateTag.isHidden = !showTemplateTag
            if oldValue != showTemplateTag {
                updateContainer()
            }
        }
    }

    var showExternal: Bool = false {
        didSet {
            externalLabel.isHidden = !showExternal
            if oldValue != showExternal {
                updateContainer()
            }
        }
    }

    var showStar: Bool = false {
        didSet {
            starImageView.isHidden = !showStar
            if oldValue != showStar {
                updateContainer()
            }
        }
    }

    private lazy var templateTag: UILabel = {
        let l = UILabel()
        l.textColor = UDColor.udtokenTagTextSIndigo
        l.text = BundleI18n.SKResource.Doc_Create_File_ByTemplate
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 12)
        l.backgroundColor = UDColor.udtokenTagBgIndigo
        l.layer.cornerRadius = 4
        l.layer.masksToBounds = true
        return l
    }()
    
    lazy var externalLabel: UILabel = {
        let l = UILabel()
        l.textColor = UDColor.udtokenTagTextSBlue
        l.text = BundleI18n.SKResource.Doc_Widget_External
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 12)
        l.backgroundColor = UDColor.udtokenTagBgBlue
        l.layer.cornerRadius = 4
        l.layer.masksToBounds = true
        return l
    }()
    lazy var starImageView: UIImageView = {
        let star = UIImageView()
        star.image = BundleResources.SKResource.Common.Other.star
        return star
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(templateTag)
        addSubview(externalLabel)
        addSubview(starImageView)

        templateTag.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(0)
            make.height.equalTo(15)
            make.left.equalToSuperview()
        }

        externalLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(0)
            make.height.equalTo(15)
            make.left.equalTo(templateTag.snp.right).offset(0)
        }

        starImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
            make.width.height.equalTo(16)
            make.left.equalTo(externalLabel.snp.right).offset(0)

        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateContainer() {
        let templateTagWidth = showTemplateTag ? NSString.templateTagW : 0
        let templateExternalOffset = showTemplateTag ? 5 : 0

        let externalWidth = showExternal ? NSString.externalLabelW : 0
        let externalStarTagOffset = showExternal ? 5 : 0

        templateTag.snp.updateConstraints { make in
            make.width.equalTo(templateTagWidth)
        }
        externalLabel.snp.updateConstraints { (make) in
            make.width.equalTo(externalWidth)
            make.left.equalTo(templateTag.snp.right).offset(templateExternalOffset)
        }

        starImageView.snp.updateConstraints { (make) in
            make.width.equalTo(showStar ? 16 : 0)
            make.left.equalTo(externalLabel.snp.right).offset(externalStarTagOffset)
        }
    }
}

private extension NSString {
    static var templateTagW: CGFloat {
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]
        let option = NSStringDrawingOptions.usesLineFragmentOrigin
        let r = BundleI18n.SKResource.Doc_Create_File_ByTemplate.boundingRect(with: CGSize(width: 300, height: 18), options: option, attributes: attributes, context: nil)
        return ceil(r.width + 8)
    }

    static var externalLabelW: CGFloat {
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)]
        let option = NSStringDrawingOptions.usesLineFragmentOrigin
        let r = BundleI18n.SKResource.Doc_Widget_External.boundingRect(with: CGSize(width: 300, height: 18), options: option, attributes: attributes, context: nil)
        return ceil(r.width + 8)
    }
}
