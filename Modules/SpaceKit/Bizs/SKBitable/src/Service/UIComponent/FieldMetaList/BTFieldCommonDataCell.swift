//
//  BTFieldCommonDataCell.swift
//  SKBitable
//
//  Created by zoujie on 2021/12/10.
//  



import UIKit
import SKResource
import UniverseDesignColor
import UniverseDesignIcon

final class BTFieldCommonDataCell: UITableViewCell {

    //当前cell的位置，用来判断是否加圆角和圆角的位置加在哪
    enum Position {
        case solo
        case first
        case middle
        case last
    }

    var position: Position = .middle

    private var icon = BTLightingIconView()

    private var rightIcon = UIImageView()
    
    private var rightSubtitleLabel = UILabel().construct { it in
        it.textColor = UDColor.textPlaceholder
        it.font = .systemFont(ofSize: 14)
    }

    private var isEnabled: Bool = true

    private var label = UILabel().construct { it in
        it.textColor = UDColor.textTitle
        it.font = .systemFont(ofSize: 16)
    }

    private var selectedImg = UIImageView().construct { it in
        it.image = UDIcon.getIconByKey(.listCheckOutlined, iconColor: UDColor.primaryContentDefault, size: CGSize(width: 20, height: 20))
    }

    private lazy var separator = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }
    
    private lazy var selectedCellBackgroundView = UIView().construct { it in
        it.backgroundColor = UDColor.fillPressed
    }
    /// 引导view
    private lazy var onboardingView = UIButton().construct { it in
        it.setTitle("New",
                    withFontSize: 12,
                    fontWeight: .regular,
                    singleColor: UDColor.primaryOnPrimaryFill,
                    forAllStates: [.normal, .highlighted, .selected, [.highlighted, .selected]])
        it.isUserInteractionEnabled = false
        it.backgroundColor = UDColor.colorfulRed
        it.isHidden = true
        it.layer.cornerRadius = 8
        it.contentEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
    }
    
    var isLastCell: Bool = false {
        didSet {
            separator.isHidden = isLastCell
        }
    }
    
    override var frame: CGRect {
        get {
            return super.frame
        }
        set {
            var frame = newValue
            frame.origin.x += 16
            frame.size.width -= 2 * 16
            super.frame = frame
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UDColor.bgFloat

        contentView.addSubview(icon)
        contentView.addSubview(label)
        contentView.addSubview(selectedImg)
        contentView.addSubview(separator)
        contentView.addSubview(rightIcon)
        contentView.addSubview(rightSubtitleLabel)
        contentView.addSubview(onboardingView)

        selectedImg.isHidden = true
        
        selectedBackgroundView = selectedCellBackgroundView

        icon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        
        setOnboardingViewHide(true)

        selectedImg.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }

        separator.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        rightIcon.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(48)
            make.right.equalTo(rightIcon.snp.right).offset(-12)
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
        }
        
        rightSubtitleLabel.snp.makeConstraints { make in
            make.right.equalTo(rightIcon.snp.left).offset(-12)
            make.centerY.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setCorners()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 设置新的引导标签
    private func setOnboardingViewHide(_ isHidden: Bool) {
        onboardingView.isHidden = isHidden
        onboardingView.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(16)
            make.right.equalTo(selectedImg.snp.left)
        }
    }

    private func setCorners() {
        let cornerRadius: CGFloat = 10
        switch position {
        case .solo:
            roundCorners(corners: .allCorners, radius: cornerRadius)
        case .first:
            roundCorners(corners: [.topLeft, .topRight], radius: cornerRadius)
        case .last:
            roundCorners(corners: [.bottomLeft, .bottomRight], radius: cornerRadius)
        default:
            noCornerMask()
        }
    }

    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }

    func noCornerMask() {
        layer.mask = nil
    }
    
    func getRightIconIfShow() -> UIImageView? {
        return  rightIcon.isHidden ? nil : rightIcon
    }

    func config(model: BTFieldCommonData, isSelected: Bool, isLast: Bool) {
        if let leftImag = model.icon {
            icon.isHidden = false
            icon.update(leftImag, showLighting: model.showLighting, tintColor: UDColor.iconN1)
            label.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(48)
            }
        } else {
            icon.isHidden = true
            label.snp.updateConstraints { make in
                make.left.equalToSuperview().offset(16)
            }
        }

        switch model.rightIocnType {
        case .none:
            rightIcon.isHidden = true
        case .arraw:
            rightIcon.isHidden = false
            rightIcon.image = UDIcon.getIconByKey(.rightBoldOutlined, iconColor: UDColor.primaryContentDefault, size: CGSize(width: 16, height: 16)).ud.withTintColor(UDColor.iconN3)
        }

        label.text = model.name
        isEnabled = model.enable
        rightSubtitleLabel.text = model.rightSubtitle
        setSelected(selected: isSelected, selectedType: model.selectedType)
        isLastCell = isLast
        setOnboardingViewHide(!model.isShowNew)
    }

    func setSelected(selected: Bool, selectedType: BTFieldCommonData.SelectedType) {
        switch selectedType {
        case .none:
            selectedImg.isHidden = true
            label.textColor = isEnabled ? UDColor.textTitle : UDColor.textDisabled
            icon.updateTintColor(isEnabled ? UDColor.iconN1 : UDColor.iconDisabled)
        case .textHighlight:
            selectedImg.isHidden = true
            if isEnabled {
                label.textColor = selected ? UDColor.primaryContentDefault : UDColor.textTitle
                icon.updateTintColor(selected ? UDColor.functionInfoContentDefault : UDColor.iconN1)
            } else {
                label.textColor = selected ? UDColor.textLinkLoading : UDColor.iconDisabled
                icon.updateTintColor(selected ? UDColor.textLinkLoading : UDColor.iconDisabled)
            }
        case .selectedIcon:
            selectedImg.isHidden = !selected
            selectedImg.snp.updateConstraints { make in
                make.width.equalTo(selected ? 20 : 0)
            }
            selectedImg.image = selectedImg.image?.ud.withTintColor(isEnabled ? UDColor.primaryContentDefault : UDColor.textLinkLoading)
            label.textColor = isEnabled ? UDColor.textTitle : UDColor.textDisabled
            icon.updateTintColor(isEnabled ? UDColor.iconN1 : UDColor.iconDisabled)
        case .all:
            selectedImg.isHidden = !selected
            if isEnabled {
                label.textColor = selected ? UDColor.primaryContentDefault : UDColor.textTitle
                icon.updateTintColor(selected ? UDColor.functionInfoContentDefault : UDColor.iconN1)
                selectedImg.image = selectedImg.image?.ud.withTintColor(UDColor.primaryContentDefault)
            } else {
                label.textColor = selected ? UDColor.textLinkLoading : UDColor.iconDisabled
                icon.updateTintColor(selected ? UDColor.textLinkLoading : UDColor.iconDisabled)
                selectedImg.image = selectedImg.image?.ud.withTintColor(UDColor.textLinkLoading)
            }
        }
    }
}
