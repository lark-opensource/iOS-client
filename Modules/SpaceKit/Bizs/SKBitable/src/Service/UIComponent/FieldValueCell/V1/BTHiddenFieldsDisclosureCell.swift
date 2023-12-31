//
// Created by duanxiaochen.7 on 2021/12/28.
// Affiliated with SKBitable.
//
// Description:

import SKFoundation
import UIKit
import SnapKit
import SKCommon
import SKFoundation
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

/// 点击后可以折叠展开下方的隐藏字段
final class BTHiddenFieldsDisclosureCell: UICollectionViewCell, BTFieldModelLoadable {

    var fieldModel = BTFieldModel(recordID: "")

    weak var delegate: BTFieldDelegate?


    private lazy var containerView = UIView().construct { it in
        if UserScopeNoChangeFG.ZJ.btCardReform {
            it.backgroundColor = UDColor.bgBody
        } else {
            it.layer.cornerRadius = 6
            it.backgroundColor = UDColor.bgFloatOverlay
        }
    }
    
    private lazy var bottomLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }

    private lazy var disclosureIndicator = UIImageView()

    private lazy var contentLabel = UILabel().construct { it in
        it.font = UIFont.systemFont(ofSize: 14)
        it.textColor = UDColor.textTitle
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(disclosureIndicator)
        containerView.addSubview(contentLabel)

        var leftRightInset = BTFieldLayout.Const.containerLeftRightMargin
        if UserScopeNoChangeFG.ZJ.btCardReform  {
            leftRightInset = 0
            contentView.addSubview(bottomLine)
            bottomLine.snp.makeConstraints { make in
                make.height.equalTo(0.5)
                make.leading.trailing.equalToSuperview().inset(16)
                make.bottom.equalToSuperview()
            }
        }
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(leftRightInset)
            make.top.bottom.equalToSuperview().inset(BTFieldLayout.Const.fieldVerticalInset)
        }
        disclosureIndicator.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
            make.leading.equalTo(16)
        }
        contentLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(disclosureIndicator.snp.trailing).offset(8)
            make.trailing.lessThanOrEqualToSuperview().inset(16)
        }
    }

    func loadModel(_ model: BTFieldModel, layout: BTFieldLayout) {
        let imageKey: UDIconType = model.isHiddenFieldsDisclosed ? .expandDownFilled : .expandRightFilled
        disclosureIndicator.image = UDIcon.getIconByKey(imageKey, iconColor: UDColor.iconN1)
        contentLabel.text = BundleI18n.SKResource.Bitable_Field_NumHiddenField(model.hiddenFieldsCount)
    }

}
