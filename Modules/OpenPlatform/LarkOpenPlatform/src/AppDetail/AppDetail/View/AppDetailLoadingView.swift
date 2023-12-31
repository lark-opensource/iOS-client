//
//  AppDetailLoadingView.swift
//  LarkAppCenter
//
//  Created by dengbo on 2021/9/7.
//

import Foundation
import UniverseDesignLoading
import UniverseDesignColor
import FigmaKit

class AppDetailSkeletonView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isSkeletonable = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AppDetailLoadingView: UIView {
    struct Const {
        let spacing: CGFloat = 16
        let iconSideLen: CGFloat = 80
        let iconRightSpacing: CGFloat = 12
        let iconBottomSpacing: CGFloat = 24
        let rectangleHeight: CGFloat = 14
        let cellHeight: CGFloat = 60
    }
    
    private lazy var iconView: AppDetailSkeletonView = {
        let view = AppDetailSkeletonView(frame: CGRect(x: 0, y: 0, width: const.iconSideLen, height: const.iconSideLen))
        view.layer.ux.setSmoothCorner(radius: 20)
        return view
    }()
    
    private lazy var topContainer: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()
    
    private lazy var bottomContainer: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()
    
    private lazy var btnContainer: UIStackView = {
        let view = UIStackView()
        view.backgroundColor = .clear
        view.axis = .horizontal
        view.alignment = .fill
        view.distribution = .fillEqually
        view.spacing = 10
        return view
    }()
    
    private let const = Const()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBase
        setupViews()
    }
    
    private func setupViews() {
        addSubview(topContainer)
        topContainer.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }
        
        topContainer.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(const.spacing)
            make.top.equalToSuperview()
            make.size.equalTo(CGSize(width: const.iconSideLen, height: const.iconSideLen))
        }
        
        let iconRightTopView = self.createCornerView(radius: 4)
        topContainer.addSubview(iconRightTopView)
        iconRightTopView.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(const.iconRightSpacing)
            make.top.equalTo(iconView.snp.top).offset(7)
            make.height.equalTo(const.rectangleHeight)
            make.width.equalTo(140)
        }
        
        let iconRightMidView = self.createCornerView(radius: 4)
        topContainer.addSubview(iconRightMidView)
        iconRightMidView.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(const.iconRightSpacing)
            make.centerY.equalTo(iconView.snp.centerY)
            make.height.equalTo(const.rectangleHeight)
            make.width.equalTo(180)
        }
        
        let iconRightBotView = self.createCornerView(radius: 4)
        topContainer.addSubview(iconRightBotView)
        iconRightBotView.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(const.iconRightSpacing)
            make.bottom.equalTo(iconView.snp.bottom).offset(-7)
            make.height.equalTo(const.rectangleHeight)
            make.width.equalTo(100)
        }
        
        topContainer.addSubview(btnContainer)
        btnContainer.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(const.iconBottomSpacing)
            make.leading.trailing.equalToSuperview().inset(const.spacing)
            make.height.equalTo(48)
            make.bottom.equalToSuperview().offset(-const.spacing)
        }
        
        for i in 0..<3 {
            let btn = self.createCornerView(radius: 10)
            btn.frame = CGRect(x: 0, y: 0, width: 200, height: 48)
            btnContainer.addArrangedSubview(btn)
        }
        
        let widths: [CGFloat] = [177, 112, 139]
        addSubview(bottomContainer)
        bottomContainer.snp.makeConstraints { make in
            make.top.equalTo(topContainer.snp.bottom).offset(const.spacing / 2)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(const.cellHeight * CGFloat(widths.count))
        }
        
        let cells = widths.map { width in
            return self.createLoadingCell(width: width)
        }
        for (idx, cell) in cells.enumerated() {
            bottomContainer.addSubview(cell)
            cell.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(const.cellHeight)
                make.top.equalToSuperview().offset(CGFloat(idx) * const.cellHeight)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var isHidden: Bool {
        didSet {
            walkLoading(root: self, show: !isHidden)
        }
    }
    
    private func walkLoading(root: UIView, show: Bool) {
        root.subviews.forEach { subview in
            if let view = subview as? AppDetailSkeletonView {
                if show {
                    view.showUDSkeleton()
                } else {
                    view.hideUDSkeleton()
                }
            } else {
                walkLoading(root: subview, show: show)
            }
        }
    }
    
    private func createCornerView(radius: CGFloat) -> AppDetailSkeletonView {
        let view = AppDetailSkeletonView(frame: .zero)
        view.layer.cornerRadius = radius
        view.layer.masksToBounds = true
        return view
    }
    
    private func createLoadingCell(width: CGFloat) -> UIView {
        let view = UIView(frame: .zero)
        let leftPart = self.createCornerView(radius: 4)
        let rightPart = self.createCornerView(radius: 4)
        view.addSubview(leftPart)
        view.addSubview(rightPart)
        leftPart.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(const.spacing)
            make.size.equalTo(CGSize(width: 40, height: const.rectangleHeight))
            make.centerY.equalToSuperview()
        }
        rightPart.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-const.spacing)
            make.size.equalTo(CGSize(width: width, height: const.rectangleHeight))
            make.centerY.equalToSuperview()
        }
        let splitLine = UIView(frame: .zero)
        splitLine.backgroundColor = UIColor.ud.lineDividerDefault
        view.addSubview(splitLine)
        splitLine.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(const.spacing)
            make.bottom.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
        return view
    }
}
