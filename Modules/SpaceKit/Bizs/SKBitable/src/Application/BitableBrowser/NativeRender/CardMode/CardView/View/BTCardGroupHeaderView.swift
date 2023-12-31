//
//  BTCardGroupHeaderView.swift
//  SKBitable
//
//  Created by zoujie on 2023/10/30.
//  

import Foundation
import SkeletonView
import UniverseDesignIcon
import UniverseDesignColor

class BTCardGroupHeaderCell: UICollectionViewCell {
    var model: GroupModel?
    private lazy var headerView = BTCardGroupHeaderView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = .clear
        contentView.addSubview(headerView)
        
        headerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func updateModel(model: GroupModel?,
                     cardSetting: CardSettingModel?,
                     shouldShowTopLine: Bool = false,
                     shouldShowBottomLine: Bool = false,
                     onClick: ((String) -> Void)? = nil) {
        self.model = model
        headerView.updateModel(model: model,
                               cardSetting: cardSetting,
                               shouldShowTopLine: shouldShowTopLine,
                               shouldShowBottomLine: shouldShowBottomLine)
        headerView.onClick = onClick
    }
}


class BTCardGroupHeaderView: UIView {
    var onClick: ((String) -> Void)?
    private var model: GroupModel?
    var id: String? {
        model?.id
    }
    
//    private lazy var topLine = UIView().construct { it in
//        it.backgroundColor = UDColor.lineBorderCard
//    }
//    
//    private lazy var bottomLine = UIView().construct { it in
//        it.backgroundColor = UDColor.lineBorderCard
//    }
    
    private lazy var textLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 14, weight: .medium)
    }
    
    private lazy var rightIcon = UIImageView().construct { it in
        it.image = UDIcon.getIconByKey(.downBoldOutlined,
                                       iconColor: UDColor.B700,
                                       size: CGSize(width: 12, height: 12))
    }
    
    // 是否折叠
    private var isCollapsed: Bool {
        model?.isCollapsed ?? false
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        
//        addSubview(topLine)
        addSubview(textLabel)
        addSubview(rightIcon)
//        addSubview(bottomLine)
        
//        topLine.snp.makeConstraints { make in
//            make.height.equalTo(1)
//            make.left.equalToSuperview().offset(16)
//            make.top.right.equalToSuperview()
//        }
        
        textLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualTo(rightIcon.snp.left).offset(-4)
        }
        
        rightIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
            make.right.equalToSuperview().offset(-18)
        }
        
//        bottomLine.snp.makeConstraints { make in
//            make.height.equalTo(1)
//            make.left.equalToSuperview().offset(16)
//            make.bottom.right.equalToSuperview()
//        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didClick))
        self.addGestureRecognizer(tapGesture)
    }
    
    func updateUI(shouldShowTopLine: Bool = false,
                  shouldShowBottomLine: Bool = false) {
        guard let model = self.model else {
            return
        }
        
        textLabel.text = model.name
        if !model.color.isEmpty {
            let color = UIColor.docs.rgb(model.color)
            textLabel.textColor = color
            rightIcon.ud.withTintColor(color)
        }
        
//        topLine.isHidden = !shouldShowTopLine
//        bottomLine.isHidden = !shouldShowBottomLine
        let leftOffset = 16 + (max(model.level - 1, 0)) * 12
        textLabel.snp.updateConstraints { make in
            make.left.equalToSuperview().offset(leftOffset)
        }
        
//        topLine.snp.updateConstraints { make in
//            make.left.equalToSuperview().offset(leftOffset)
//        }
        
//        bottomLine.snp.updateConstraints { make in
//            make.left.equalToSuperview().offset(leftOffset)
//        }
        
        self.handleRightIconAnimation()
    }
    
    func updateModel(model: GroupModel?, 
                     cardSetting: CardSettingModel?,
                     shouldShowTopLine: Bool = false,
                     shouldShowBottomLine: Bool = false) {
        self.model = model
        // 无数据显示骨架图
        if model == nil {
            showLoading()
        } else {
            hideLoading()
            updateUI(shouldShowTopLine: shouldShowTopLine, shouldShowBottomLine: shouldShowBottomLine)
        }
    }
    
    private func showLoading() {
        let skeletonGradient = SkeletonGradient(baseColor: UIColor.ud.N900.withAlphaComponent(0.05), secondaryColor: UIColor.ud.N900.withAlphaComponent(0.1))
        textLabel.isSkeletonable = true
        textLabel.showAnimatedGradientSkeleton(usingGradient: skeletonGradient)
        textLabel.startSkeletonAnimation()
        
        rightIcon.isSkeletonable = true
        rightIcon.showAnimatedGradientSkeleton(usingGradient: skeletonGradient)
        rightIcon.startSkeletonAnimation()
    }
    
    private func hideLoading() {
        textLabel.hideSkeleton()
        rightIcon.hideSkeleton()
    }
    
    private func handleRightIconAnimation() {
        let rotationAngle: CGFloat = isCollapsed ? -CGFloat.pi / 2 : 0 // 旋转 90 度
        let rotationTransform = CGAffineTransform(rotationAngle: rotationAngle)
        UIView.animate(withDuration: 0.25) {
            self.rightIcon.transform = rotationTransform
        }
    }
    
    @objc
    func didClick() {
        guard let id = model?.id else { return }
        onClick?(id)
    }
}
