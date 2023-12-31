//
//  BTFormUnreadableCell.swift
//  SKBitable
//
//  Created by X-MAN on 2022/10/25.
//

import Foundation
import UniverseDesignEmpty
import SKResource

final class BTFormUnreadableCell: UICollectionViewCell {
    private lazy var emptyView: UDEmptyView = {
        let attr = NSAttributedString(string: BundleI18n.SKResource.Bitable_AdvancedPermission_NoPermissionToView_Form)
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.12
        attr.lk_setAttributes([NSAttributedString.Key.foregroundColor: UIColor.ud.textDisabled,
                               NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
                               NSAttributedString.Key.paragraphStyle: paragraphStyle.copy()])
        let config = UDEmptyConfig( description: UniverseDesignEmpty.UDEmptyConfig.Description(descriptionText: attr), type: .noAuthority)
        let empty = UDEmptyView(config: config)
        return empty
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(270)
            make.height.equalTo(200)
        }
    }
}
