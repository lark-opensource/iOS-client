//
//  WPCommonAreaTipCell.swift
//  LarkWorkplace
//
//  Created by Jiayun Huang on 2022/1/5.
//

import LarkUIKit
import LarkSetting

final class WPCommonAreaTipCell: UICollectionViewCell {
    private lazy var tipsLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(tipsLabel)
        tipsLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(favoriteTipsTopPadding)
            make.bottom.equalToSuperview().inset(favoriteTipsBottomPadding)
        }
    }

    func updateTips(isEditable: Bool, enableRecentlyUsedApp: Bool) {
        if isEditable {
            tipsLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_BaseBlock_DragToRearrangeOnlyAppsOnMobile
        } else {
            tipsLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_NoFavPrompt
        }
    }
}
