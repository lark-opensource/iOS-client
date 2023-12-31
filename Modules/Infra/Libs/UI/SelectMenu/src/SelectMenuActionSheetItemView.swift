//
//  SelectMenuActionSheetItemView.swift
//  LarkDynamic
//
//  Created by Songwen Ding on 2019/7/22.
//

import Foundation
import UIKit

public final class SelectMenuActionSheetItemView: UIView {
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private var accessoryImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = BundleResources.SelectMenu.accessory_select
        return imageView
    }()

    public var title: String? {
        set { self.titleLabel.text = newValue }
        get { return self.titleLabel.text }
    }

    public var isSelected: Bool = false {
        didSet {
            self.accessoryImageView.isHidden = !self.isSelected
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.titleLabel)
        self.addSubview(self.accessoryImageView)
        self.titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-54)
        }
        self.accessoryImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-15)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SelectMenuActionSheetItemView {
    public convenience init(title: String, isSelected: Bool) {
        self.init(frame: .zero)
        DispatchQueue.main.async {
            self.title = title
            self.isSelected = isSelected
        }
    }
}
