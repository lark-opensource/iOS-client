//
//  WebExtensionController.swift
//  Lark
//
//  Created by lichen on 2017/4/26.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

public final class WebExtensionCell: UICollectionViewCell {
    private lazy var container: UIView = UIView()
    private lazy var imageView: UIImageView = UIImageView()
    private lazy var titleLabel: UILabel = UILabel()
    private lazy var titleLabelContainer: UIView = UIView()

    var item: WebExtensionItem? {
        didSet {
            titleLabel.text = item?.name
            titleLabel.sizeToFit()  // 顶部对齐
            imageView.image = item?.image
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(imageView)
        contentView.addSubview(titleLabelContainer)
        titleLabelContainer.addSubview(titleLabel)
        
        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(6)
            make.right.equalToSuperview().offset(-6)
            make.width.height.equalTo(52)
        }
        
        titleLabelContainer.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(24)
            make.top.equalTo(imageView.snp.bottom).offset(8)
        }
        
        titleLabelContainer.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(24)
            make.top.equalTo(imageView.snp.bottom).offset(8)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }
        
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 10)
        titleLabel.textColor = UIColor.ud.textCaption
        titleLabel.numberOfLines = 2
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
