//
//  WikiCreateViewCell.swift
//  SKWiki
//
//  Created by 邱沛 on 2021/3/9.
//

import SnapKit
import UniverseDesignColor
import UniverseDesignTag
import SKCommon
import SKResource
import SKFoundation

class WikiCreateViewCell: UICollectionViewCell {

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var titleLabel: UITextView = {
        let label = UITextView()
        label.isScrollEnabled = false
        label.isSelectable = false
        label.isEditable = false
        label.isOpaque = true
        label.backgroundColor = .clear
        label.textContainerInset = .zero
        label.textContainer.lineFragmentPadding = 0
        label.textContainer.lineBreakMode = .byWordWrapping
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textAlignment = .center
        label.textColor = UDColor.textTitle
        label.textContainer.maximumNumberOfLines = 2
        return label
    }()
    
    private lazy var versionTag: UDTag = {
        let config = UDTagConfig.TextConfig(font: UIFont.systemFont(ofSize: 10),
                                            cornerRadius: 4,
                                            textColor: UDColor.udtokenTagNeutralTextNormal,
                                            backgroundColor: UDColor.udtokenTagNeutralBgNormal,
                                            height: 13)
        let tag = UDTag(text: BundleI18n.SKResource.CreationMobile_Common_Tag_DocGen1, textConfig: config)
        return tag
    }()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                contentView.backgroundColor = UIColor.ud.N200
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_250) { [weak self] in
                    self?.contentView.backgroundColor = .clear
                }
            }
        }
    }

    private(set) var itemEnabled: Bool = true {
        didSet {
            if itemEnabled {
                contentView.alpha = 1
            } else {
                contentView.alpha = 0.5
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.layer.cornerRadius = 4
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.left.right.equalToSuperview()
            make.height.equalTo(28)
        }
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
        }
        contentView.docs.addStandardHighlight()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        itemEnabled = true
        imageView.image = nil
        titleLabel.text = nil
    }

    func update(_ item: WikiCreateItem) {
        imageView.image = item.icon
        titleLabel.text = item.title
        itemEnabled = item.enable
        setupVersionTag(item: item)
    }
    
    private func setupVersionTag(item: WikiCreateItem) {
        guard item.itemType == .doc, LKFeatureGating.createDocXEnable else { return }
        setupVersionTagLayout()
        //设置字体格式
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        let attributeString = NSMutableAttributedString(string: item.title + " ", attributes: [.paragraphStyle: style, .foregroundColor: UDColor.textTitle])
        //设置标签image
        versionTag.isHidden = false
        let tag = NSTextAttachment()
        tag.image = versionTag.transformImage()
        tag.bounds = CGRect(x: 0, y: -(titleLabel.frame.height - 13) * 2, width: versionTag.frame.width, height: 13)
        let imageAttr = NSMutableAttributedString(attachment: tag)
    
        versionTag.isHidden = true
        attributeString.append(imageAttr)
        titleLabel.attributedText = attributeString
    }
    
    private func setupVersionTagLayout() {
        contentView.insertSubview(versionTag, belowSubview: titleLabel)
        versionTag.snp.makeConstraints { make in
            make.top.left.equalTo(titleLabel)
        }
        contentView.layoutIfNeeded()
    }
}
