//
//  BTItemViewCatalogueCell.swift
//  SKBitable
//
//  Created by yinyuan on 2023/11/8.
//

import SKFoundation
import UniverseDesignColor
import SKResource

final class BTItemViewCatalogueCell: UICollectionViewCell {
    
    weak var delegate: BTFieldDelegate?
    
    lazy var leftLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.SKResource.Bitable_QuickAdd_AddTo_Text
        label.numberOfLines = 1
        label.textColor = UDColor.textCaption
        label.font = .systemFont(ofSize: 12)
        return label
    }()
    
    lazy var catalogueBannerView: BTCatalogueBannerView = {
        let view = BTCatalogueBannerView()
        view.delegate = self
        return view
    }()
    
    private lazy var bottomLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineBorderCard
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = UDColor.bgBody
        addSubview(leftLabel)
        addSubview(catalogueBannerView)
        addSubview(bottomLine)
        
        leftLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.equalToSuperview()
            make.height.equalTo(28)
        }
        
        catalogueBannerView.snp.makeConstraints { make in
            make.left.equalTo(leftLabel.snp.right).offset(6)
            make.right.equalToSuperview().inset(16)
            make.top.equalToSuperview()
            make.height.equalTo(28)
        }
        
        bottomLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    func setData(firstLevelTitle: String, secondLevelTitle: String, showBottomLine: Bool, showLeftLabel: Bool) {
        catalogueBannerView.setData(firstLevelTitle: firstLevelTitle, secondLevelTitle: secondLevelTitle)
        if !UserScopeNoChangeFG.YY.bitableRecordShareCatalogueDisable {
            bottomLine.isHidden = !showBottomLine
            
            leftLabel.isHidden = !showLeftLabel
            
            catalogueBannerView.snp.remakeConstraints { make in
                if showLeftLabel {
                    make.left.equalTo(leftLabel.snp.right).offset(6)
                } else {
                    make.left.equalToSuperview().inset(12)
                }
                make.right.equalToSuperview().inset(16)
                make.top.equalToSuperview()
                make.height.equalTo(28)
            }
        }
    }
}

extension BTItemViewCatalogueCell: BTCatalogueBannerViewDelegate {
    func didFirstLevelLabelClick() {
        delegate?.didClickCatalogueBaseName()
    }
    
    func didSecondLevelLabelClick() {
        delegate?.didClickCatalogueTableName()
    }
}
