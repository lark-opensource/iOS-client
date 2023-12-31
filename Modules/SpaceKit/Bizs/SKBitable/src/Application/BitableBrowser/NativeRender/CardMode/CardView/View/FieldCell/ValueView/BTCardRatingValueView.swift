//
//  BTCardRatingValueView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/2.
//

import Foundation
import UniverseDesignColor
import UniverseDesignFont
import SnapKit

fileprivate struct Const {
    static let ratingHeight: CGFloat = 20.0
    static let iconSpacing: CGFloat = 8.0
    static let simpleCapsuleCorlor = UDColor.bgBodyOverlay
    static let simpleIconSize: CGFloat = 16.0
    static let simpleLeftPadding: CGFloat = 6.0
    static let simpleRightPadding: CGFloat = 8.0
    static let simpeInnerSpacing: CGFloat = 4.0
    static let simpleTextColor = UDColor.textTitle
    static let simpleTextFont: UIFont = UDFont.caption0
    static let emptyColor: UIColor = UDColor.lineBorderCard
    static let emptyWidth: CGFloat = 12.0
    static let emptyHeight: CGFloat = 2.0
    static let emotyRadius: CGFloat = 1.0
}

fileprivate class SimpleRatingView: UIView {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.textColor = Const.simpleTextColor
        label.font = Const.simpleTextFont
        return label
    }()
    
    private let noRatingView: UIView = {
        let view = UIView()
        view.backgroundColor = Const.emptyColor
        view.layer.cornerRadius = Const.emotyRadius
        return view
    }()
    
    private var noRatingRightCons: SnapKit.ConstraintMakerEditable?
    private var countRrightCons: SnapKit.ConstraintMakerEditable?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        layer.cornerRadius = Const.ratingHeight / 2.0
        backgroundColor = Const.simpleCapsuleCorlor
        addSubview(imageView)
        addSubview(countLabel)
        addSubview(noRatingView)
        imageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Const.simpleLeftPadding)
            make.centerY.equalToSuperview()
            make.size.equalTo(Const.simpleIconSize)
        }
        
        noRatingView.snp.makeConstraints { make in
            self.noRatingRightCons = make.right.equalToSuperview().offset(-Const.simpleRightPadding)
            make.centerY.equalToSuperview()
            make.left.equalTo(imageView.snp.right).offset(Const.simpeInnerSpacing)
            make.width.equalTo(Const.emptyWidth)
            make.height.equalTo(Const.emptyHeight)
        }
        countLabel.snp.makeConstraints { make in
            self.countRrightCons = make.right.equalToSuperview().offset(-Const.simpleRightPadding)
            make.centerY.equalToSuperview()
            make.left.equalTo(imageView.snp.right).offset(Const.simpeInnerSpacing)
        }
        countLabel.isHidden = true
        noRatingView.isHidden = true
    }
    
    func update(icon: UIImage, count: Int, isEmpty: Bool) {
        imageView.image = icon
        if isEmpty {
            self.countRrightCons?.constraint.isActive = false
            self.noRatingRightCons?.constraint.isActive = true
            countLabel.isHidden = true
            noRatingView.isHidden = false
            
        } else {
            self.countRrightCons?.constraint.isActive = true
            self.noRatingRightCons?.constraint.isActive = false
            countLabel.isHidden = false
            noRatingView.isHidden = true
            countLabel.text = "\(count)"
        }
    }
}

final class BTCardRatingValueView: UIView {
    
    private let simpleRatingView = SimpleRatingView()
    
    private let ratingView = BTRatingView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(ratingView)
        addSubview(simpleRatingView)
        ratingView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.height.equalTo(Const.ratingHeight)
            make.centerY.equalToSuperview()
        }
        simpleRatingView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(Const.ratingHeight)
            make.left.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
    }
}

extension BTCardRatingValueView: BTCellValueViewProtocol {
    
    func setData(_ model: BTCardFieldCellModel, containerWidth: CGFloat) {
        if let data = model.getFieldData(type: BTRateData.self).first {
            let count = max(CGFloat(data.maxRate - data.minRate) + 1.0, 1.0)
            let mutilNeedWidth = count * Const.ratingHeight + (count - 1) * Const.iconSpacing
            if mutilNeedWidth > containerWidth {
                ratingView.isHidden = true
                simpleRatingView.isHidden = false
                let icon = BitableCacheProvider.current.simpleIcon(with: data.symbol)
                simpleRatingView.update(icon: icon, count: data.rate, isEmpty: data.rate < data.minRate)
            } else {
                let config = BTRatingView.Config(minValue: data.minRate,
                                                 maxValue: data.maxRate,
                                                 iconWidth: Const.ratingHeight,
                                                 iconSpacing: Const.iconSpacing,
                                                 alignment: .left,
                                                 style: .stable,
                                                 maxWidth: containerWidth,
                                                 iconBuilder: { value in
                    return BitableCacheProvider.current.ratingIcon(symbol: data.symbol, value: value)
                })
                ratingView.isHidden = false
                simpleRatingView.isHidden = true
                ratingView.update(config, data.rate)
            }
        }
    }
}
