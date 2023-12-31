//
//  MinutesHomeFilterConditionCell.swift
//  Minutes
//
//  Created by sihuahao on 2021/7/14.
//

import Foundation
import MinutesFoundation
import MinutesNetwork

class MinutesHomeFilterCollectionHeader: UICollectionReusableView {
    let label = UILabel()
    var topY: CGFloat = 0.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(label)
        label.textColor = UIColor.ud.N900
        label.font = .systemFont(ofSize: 14)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.frame = CGRect(x: 16, y: topY != 0 ? topY : bounds.size.height / 2.0 - 10, width: bounds.size.width - 16 * 2, height: 20)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MinutesHomeFilterConditionCell: UICollectionViewCell {

    private var isCellEnabled:Bool = true {
        didSet{
            if isCellEnabled {
                self.isUserInteractionEnabled = true
            }else {
                self.isUserInteractionEnabled = false
                self.backgroundColor = UIColor.ud.bgFloatOverlay
                selectorLabel.textColor = UIColor.ud.textDisabled
            }
        }
    }

    private var spaceType: MinutesSpaceType?

    private var isConditionSelected: Bool = false {
        didSet {
            if isConditionSelected {
                self.backgroundColor = UIColor.ud.primaryFillSolid02
                selectorLabel.textColor = UIColor.ud.primaryContentDefault
            } else {
                self.backgroundColor = UIColor.ud.bgFloatOverlay
                selectorLabel.textColor = UIColor.ud.textTitle
            }
        }
    }

    private lazy var selectorLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.numberOfLines = 1
        label.text = ""
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)

        self.layer.cornerRadius = 8

        addSubview(selectorLabel)

        selectorLabel.snp.makeConstraints { maker in
            maker.centerY.centerX.equalToSuperview()
            maker.height.equalTo(20)
            maker.left.equalToSuperview().offset(5)
            maker.right.equalToSuperview().offset(-5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(item: FilterCondition, spaceType: MinutesSpaceType) {
        if spaceType == .my || spaceType == .share {
            selectorLabel.text = item.rankType.title
        } else {
            if item.schedulerType != .none {
                selectorLabel.text = item.schedulerType.title
            }else {
                selectorLabel.text = item.ownerType.title
            }

        }
        isConditionSelected = item.isConditionSelected
        isCellEnabled = item.isEnabled
        self.spaceType = spaceType
    }
}
