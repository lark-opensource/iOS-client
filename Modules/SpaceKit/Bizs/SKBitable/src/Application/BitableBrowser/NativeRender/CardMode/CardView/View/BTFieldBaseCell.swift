//
//  BTFieldBaseCell.swift
//  SKBitable
//
//  Created by zoujie on 2023/10/30.
//  


import Foundation
import SnapKit
import SkeletonView
import UniverseDesignColor

class BTFieldBaseCell: UICollectionViewCell {
    
    struct Const {
        static let valueWidthMutil: CGFloat = 0.6
        static let valueWidthSingleLineNoCover: CGFloat = 0.7
        static let titleViewHeight: CGFloat = 18
        static let titleViewFont = UIFont.systemFont(ofSize: 12)
        static let highlightBorderWidth: CGFloat = 2.0
        static let titleRightInset: CGFloat = 8.0
    }
    
    struct ProfileData {
        var layout: Double = 0
        var draw: Double = 0
        var setData: Double = 0
    }
    
    enum LayoutMode: Equatable {
        case leftRight(hasCover: Bool) // 左右结构
        case topBottom // 上下结构
        static func == (lhs: Self, rhs: Self) -> Bool {
            switch lhs {
            case .topBottom:
                switch rhs {
                case .topBottom:
                    return true
                case .leftRight(_):
                    return false
                }
            case .leftRight(let lhsHasCover):
                switch rhs {
                case .topBottom:
                    return false
                case .leftRight(let rhsHasCover):
                    return lhsHasCover == rhsHasCover
                }
            }
        }
    }
    
    private var model: BTCardFieldCellModel?
    var layoutMode: LayoutMode = .topBottom
    private var containerWidth: CGFloat = 0
    private(set) var profile: ProfileData = ProfileData()
    var context: BTNativeRenderContext?
    
    lazy var titleViewWrapper = UIStackView()
    private lazy var titleLoadingView = BTSkeletonView().construct { it in
        it.isHidden = true
        it.layer.cornerRadius = 7
    }
    
    lazy var titleView = UILabel().construct { it in
        it.font = Const.titleViewFont
        it.textColor = UDColor.textCaption
    }
    
    lazy var valueViewWrapper = UIStackView()
    private lazy var valueLoadingView = BTSkeletonView().construct { it in
        it.isHidden = true
        it.layer.cornerRadius = 7
    }
    
    private var isShowLoading = false
    private lazy var emptyValue = BTCardEmptyValueView()
    
    // constraints
    private var titleLRWidthCons: SnapKit.ConstraintMakerEditable?
    private var titleNoCoverLRWidthCons: SnapKit.ConstraintMakerEditable?
    private var titleTBHeightCons: SnapKit.ConstraintMakerEditable?
    private var titleLRBottomCons: SnapKit.ConstraintMakerEditable?
    private var titleTBRightCons: SnapKit.ConstraintMakerEditable?

    private var valueLRTopCons: SnapKit.ConstraintMakerEditable?
    private var valueTBTopCons: SnapKit.ConstraintMakerEditable?
    private var valueTBLeftCons: SnapKit.ConstraintMakerEditable?
    private var valueLRWidthCons: SnapKit.ConstraintMakerEditable?
    private var valueLRNoCoverWidthCons: SnapKit.ConstraintMakerEditable?

    private var emptyLRWidthCons: SnapKit.ConstraintMakerEditable?
    private var emptyLRNoCoverWidthCons: SnapKit.ConstraintMakerEditable?
    private var emptyLRTopCons: SnapKit.ConstraintMakerEditable?
    private var emptyLRLeftCons: SnapKit.ConstraintMakerEditable?
    private var emptyTBTopCons: SnapKit.ConstraintMakerEditable?
    private var emptyTBLeftCons: SnapKit.ConstraintMakerEditable?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        let start = CACurrentMediaTime() * 1000
        super.layoutSubviews()
        let cost = (CACurrentMediaTime() * 1000 - start)
        profile.layout = cost
    }
    
    override func draw(_ rect: CGRect) {
        let start = CACurrentMediaTime() * 1000
        super.draw(rect)
        let cost = (CACurrentMediaTime() * 1000 - start)
        profile.draw = cost
    }
    
    func setupUI() {
        contentView.addSubview(titleViewWrapper)
        contentView.addSubview(valueViewWrapper)
        contentView.addSubview(titleLoadingView)
        contentView.addSubview(valueLoadingView)
        
        titleViewWrapper.addSubview(titleView)
        contentView.addSubview(emptyValue)
        
        titleView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.equalToSuperview().inset(Const.titleRightInset)
        }
        titleViewWrapper.snp.makeConstraints { make in
            titleLRWidthCons = make.width.equalToSuperview().multipliedBy(1 - Const.valueWidthMutil)
            titleNoCoverLRWidthCons = make.width.equalToSuperview().multipliedBy(1 - Const.valueWidthSingleLineNoCover)
            make.top.left.equalToSuperview()
            titleLRBottomCons = make.bottom.equalToSuperview()
            titleTBRightCons = make.right.equalToSuperview()
            titleTBHeightCons = make.height.equalTo(Const.titleViewHeight)
        }
        valueViewWrapper.snp.makeConstraints { make in
            valueLRWidthCons = make.width.equalToSuperview().multipliedBy(Const.valueWidthMutil)
            valueLRNoCoverWidthCons = make.width.equalToSuperview().multipliedBy(Const.valueWidthSingleLineNoCover)
            valueLRTopCons = make.top.equalToSuperview()
            valueTBLeftCons = make.left.equalToSuperview()
            make.bottom.right.equalToSuperview()
            valueTBTopCons = make.top.equalTo(titleViewWrapper.snp.bottom)
        }
        emptyValue.snp.makeConstraints { make in
            emptyLRWidthCons = make.width.equalToSuperview().multipliedBy(Const.valueWidthMutil)
            emptyLRNoCoverWidthCons = make.width.equalToSuperview().multipliedBy(Const.valueWidthSingleLineNoCover)
            emptyTBTopCons = make.top.equalTo(titleViewWrapper.snp.bottom)
            make.bottom.right.equalToSuperview()
            emptyTBLeftCons = make.left.equalToSuperview()
            emptyLRTopCons = make.top.equalToSuperview()
        }
        // 默认上下结构
        activeTBConstraint()
        
        titleLoadingView.snp.makeConstraints { make in
            make.height.equalTo(12)
            make.width.equalTo(titleViewWrapper).multipliedBy(0.8)
            make.left.centerY.equalTo(titleViewWrapper)
        }
        
        valueLoadingView.snp.makeConstraints { make in
            make.height.equalTo(12)
            make.width.equalTo(valueViewWrapper).multipliedBy(0.95)
            make.left.centerY.equalTo(valueViewWrapper)
        }
        
        emptyValue.isHidden = true
        emptyValue.layer.zPosition = 1
        self.layer.borderWidth = Const.highlightBorderWidth
        self.layer.borderColor = nil
        self.backgroundColor = nil
        valueViewWrapper.isHidden = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.layer.borderColor = nil
        self.backgroundColor = nil
        valueViewWrapper.isHidden = true
        emptyValue.isHidden = false
    }
    
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 后续接字段直接编辑后这里需要根据权限判断
        return nil
    }
    
    // 激活上下结构约束
    private func activeTBConstraint() {
        titleLRWidthCons?.constraint.isActive = false
        titleNoCoverLRWidthCons?.constraint.isActive = false
        titleLRBottomCons?.constraint.isActive = false
        titleTBRightCons?.constraint.isActive = true
        titleTBHeightCons?.constraint.isActive = true
        
        valueLRTopCons?.constraint.isActive = false
        valueLRWidthCons?.constraint.isActive = false
        valueLRNoCoverWidthCons?.constraint.isActive = false
        valueTBTopCons?.constraint.isActive = true
        valueTBLeftCons?.constraint.isActive = true
        
        emptyLRTopCons?.constraint.isActive = false
        emptyLRWidthCons?.constraint.isActive = false
        emptyLRNoCoverWidthCons?.constraint.isActive = false
        emptyTBTopCons?.constraint.isActive = true
        emptyTBLeftCons?.constraint.isActive = true
    }
    // 激活左右结构约束
    private func activeLRConstraint(hasCover: Bool) {
        titleLRWidthCons?.constraint.isActive = hasCover
        titleNoCoverLRWidthCons?.constraint.isActive = !hasCover
        titleLRBottomCons?.constraint.isActive = true
        titleTBRightCons?.constraint.isActive = false
        titleTBHeightCons?.constraint.isActive = false
        
        valueLRTopCons?.constraint.isActive = true
        valueLRWidthCons?.constraint.isActive = hasCover
        valueLRNoCoverWidthCons?.constraint.isActive = !hasCover
        valueTBTopCons?.constraint.isActive = false
        valueTBLeftCons?.constraint.isActive = false
        
        emptyLRWidthCons?.constraint.isActive = hasCover
        emptyLRNoCoverWidthCons?.constraint.isActive = !hasCover
        emptyLRTopCons?.constraint.isActive = true
        emptyTBTopCons?.constraint.isActive = false
        emptyTBLeftCons?.constraint.isActive = false
    }
    
    func updateUI(with mode: LayoutMode) {
        switch mode {
        case .leftRight(let hasCover):
            activeLRConstraint(hasCover: hasCover)
        case .topBottom:
            activeTBConstraint()
            
        }
    }
    
    private func updateHighlight(with model: BTCardFieldCellModel?) {
        if let colorString = model?.highlightColor {
            let color = UIColor.docs.rgb(colorString)
            self.backgroundColor = color
        } else {
            self.backgroundColor = .clear
        }
        if let colorString = model?.borderHighlightColor {
            let color = UIColor.docs.rgb(colorString)
            self.layer.borderColor = color.cgColor
        } else {
            self.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    final func updateModel(_ model: BTCardFieldCellModel?, layoutMode: LayoutMode, containerWidth: CGFloat) {
        let setDataStart = CACurrentMediaTime() * 1000
        titleView.text = model?.fieldName
        let layoutChanged = layoutMode != self.layoutMode
        if layoutChanged {
            updateUI(with: layoutMode)
        }
        updateHighlight(with: model)
        // 根据type获取对应的valueView
        let dataChanged = model?.data != self.model?.data
        let containerChanged = self.containerWidth != containerWidth
        // 比较完成后要立刻赋予新数据
        self.containerWidth = containerWidth
        self.layoutMode = layoutMode
        self.model = model
        if let model = model {
            hideLoading()
            let dataIsNotEmpty = !model.isEmpty
            emptyValue.isHidden = dataIsNotEmpty
            valueViewWrapper.isHidden = !dataIsNotEmpty
            if dataIsNotEmpty {
                if dataChanged ||
                    containerChanged ||
                    layoutChanged {
                    renderValue(with: model,
                                layoutMode: layoutMode,
                                containerWidth: valueWidth())
                }
            }
        } else {
            showLoading()
            emptyValue.isHidden = true
            valueViewWrapper.isHidden = true
        }
        let cost = (CACurrentMediaTime() * 1000 - setDataStart)
        profile.setData = cost
    }
    
    // 子类在这个方法里处理Value数据
    func renderValue(with model: BTCardFieldCellModel, layoutMode: LayoutMode, containerWidth: CGFloat) {
        
    }
    
    private func showLoading() {
        guard !isShowLoading else {
            return
        }
        
        isShowLoading = true
        titleLoadingView.isHidden = false
        valueLoadingView.isHidden = false
        
        let skeletonGradient = SkeletonGradient(baseColor: UIColor.ud.N900.withAlphaComponent(0.05), secondaryColor: UIColor.ud.N900.withAlphaComponent(0.1))
        titleLoadingView.isSkeletonable = true
        titleLoadingView.showAnimatedGradientSkeleton(usingGradient: skeletonGradient)
        titleLoadingView.startSkeletonAnimation()
        
        valueLoadingView.isSkeletonable = true
        valueLoadingView.showAnimatedGradientSkeleton(usingGradient: skeletonGradient)
        valueLoadingView.startSkeletonAnimation()
    }
    
    private func hideLoading() {
        guard isShowLoading else {
            return
        }
        
        isShowLoading = false
        titleLoadingView.isHidden = true
        valueLoadingView.isHidden = true
        
        titleLoadingView.hideSkeleton()
        valueLoadingView.hideSkeleton()
    }
}

extension BTFieldBaseCell {
    private func valueWidth() -> CGFloat {
        switch layoutMode {
        case .topBottom:
            return containerWidth
        case .leftRight(let hasCover):
            return containerWidth * (hasCover ? Const.valueWidthMutil : Const.valueWidthSingleLineNoCover)
        }
    }
}

extension BTFieldBaseCell: BTNativeRenderFieldStatisticProtocol {
    var setData: TimeInterval {
        profile.setData
    }
    
    var layout: TimeInterval {
        profile.layout
    }
    
    var draw: TimeInterval {
        profile.draw
    }
    
    var type: BTFieldUIType {
        model?.fieldUIType ?? .notSupport
    }
}
