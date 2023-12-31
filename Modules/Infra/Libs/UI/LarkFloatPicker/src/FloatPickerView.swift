//
//  FloatPickerView.swift
//
//  Created by liluobin on 2022/1/5.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignShadow

public protocol FloatPickerViewDelegate: AnyObject {
    func didClickItemViewAtIdx(_ idx: Int)
}

public protocol FloatPickerViewDataSource: AnyObject {
    func numberOfRowsInSection() -> Int
    func itemViewForIndex(_ index: Int) -> FloatPickerBaseItemView
}

public final class FloatPickerView: UIView {

    private lazy var contentView: UIView = {
        let view = UIView()
        view.layer.ud.setShadowColor(UDShadowColorTheme.s3DownColor)
        view.layer.shadowOpacity = 0.03
        view.layer.shadowRadius = 6
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 8
        /// 这里如果clipsToBounds = true, 就没有阴影了
        view.clipsToBounds = false
        view.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
        view.layer.borderWidth = 1
        return view
    }()

    private var itemViews: [FloatPickerBaseItemView] = []

    private var isTopArrow = false {
        didSet {
            updateTopArrowDirection()
        }
    }

    private lazy var bottomArrowImageView: FloatArrowView = {
        let arrowView = FloatArrowView(arrowDirection: .bottom,
                                       size: CGSize(width: layout.arrowWidth,
                                                    height: layout.arrowHeight))
        arrowView.layer.ud.setShadowColor(UDShadowColorTheme.s3DownColor)
        arrowView.layer.shadowOpacity = 0.03
        arrowView.layer.shadowOffset = CGSize(width: 0, height: 6)
        return arrowView
    }()

    private lazy var topArrowImageView: FloatArrowView = {
        let arrowView = FloatArrowView(arrowDirection: .top,
                                       size: CGSize(width: layout.arrowWidth,
                                                    height: layout.arrowHeight))
        arrowView.layer.ud.setShadowColor(UDShadowColorTheme.s3DownColor)
        arrowView.layer.shadowOpacity = 0.03
        arrowView.layer.shadowOffset = CGSize(width: 0, height: -6)
        return arrowView
    }()

    public weak var delegate: FloatPickerViewDelegate?
    private weak var dataSource: FloatPickerViewDataSource?

    /// 布局
    let layout: FloatPickerViewLayout

    public init(layout: FloatPickerViewLayout,
                dataSource: FloatPickerViewDataSource?,
                delegate: FloatPickerViewDelegate? = nil) {
        self.layout = layout
        self.delegate = delegate
        self.dataSource = dataSource
        super.init(frame: .zero)
        setupView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.backgroundColor = UIColor.clear
        self.addSubview(contentView)
        self.addSubview(bottomArrowImageView)
        bottomArrowImageView.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.width.equalTo(layout.arrowWidth)
            make.height.equalTo(0)
            make.centerX.equalToSuperview()
        }
        
        self.addSubview(topArrowImageView)
        topArrowImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.width.equalTo(layout.arrowWidth)
            make.height.equalTo(0)
            make.centerX.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(topArrowImageView.snp.bottom)
            make.bottom.equalTo(bottomArrowImageView.snp.top)
       }

       guard let dataSource = self.dataSource else {
           return
       }

       for idx in 0..<dataSource.numberOfRowsInSection() {
           let itemView = dataSource.itemViewForIndex(idx)
           self.contentView.addSubview(itemView)
           self.itemViews.append(itemView)
           itemView.tapCallBack = { [weak self] in
               self?.delegate?.didClickItemViewAtIdx(idx)
           }
       }
    }

    public func updateLayout(){
        let result = self.layout.layoutForFlowView()
        self.updateWithLayoutResult(result)
    }

    public func updateWithLayoutResult(_ result: FloatPickerLayoutResult) {
        self.frame = result.frame
        updateArrowCenterOffset(result.arrowCenterOffset)
        isTopArrow = result.isTopArrow
        let frames = self.layout.layoutItemsFrames()
        self.updateItemsFrame(frames)
    }

    private func updateTopArrowDirection() {
        if self.isTopArrow {
            /// 调整阴影向上
            self.contentView.layer.shadowOffset = CGSize(width: 0, height: -6)
            self.bottomArrowImageView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            self.topArrowImageView.snp.updateConstraints { make in
                make.height.equalTo(layout.arrowHeight)
            }
            self.contentView.snp.updateConstraints { make in
                make.top.equalTo(topArrowImageView.snp.bottom).offset(-2)
                make.bottom.equalTo(bottomArrowImageView.snp.top).offset(-2)
            }
        } else {
            /// 调整阴影向下
            self.contentView.layer.shadowOffset = CGSize(width: 0, height: 6)
            self.bottomArrowImageView.snp.updateConstraints { make in
                make.height.equalTo(layout.arrowHeight)
            }
            self.topArrowImageView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            self.contentView.snp.updateConstraints { make in
                make.top.equalTo(topArrowImageView.snp.bottom).offset(2)
                make.bottom.equalTo(bottomArrowImageView.snp.top).offset(2)
            }
        }
    }

    private func updateArrowCenterOffset(_ offset: CGFloat) {
        self.bottomArrowImageView.snp.updateConstraints { make in
            make.centerX.equalToSuperview().offset(offset)
        }
        self.topArrowImageView.snp.updateConstraints { make in
            make.centerX.equalToSuperview().offset(offset)
        }
    }

    private func updateItemsFrame(_ frames: [CGRect]) {
        guard frames.count == itemViews.count else {
            assertionFailure("保留现场")
            return
        }
        for idx in 0..<itemViews.count {
            itemViews[idx].frame = frames[idx]
        }
    }

    public func getSubViewFrame() -> [CGRect] {
        return itemViews.map { return $0.frame }
    }

    public func reloadDataItemAtIndex(_ index: Int) {
        if index < self.itemViews.count {
            self.itemViews[index].reloadData()
        }
    }
    
    public func reloadData() {
        self.itemViews.forEach { view in
            view.reloadData()
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        contentView.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
    }
}

final class FloatArrowView: UIView {
    enum ArrowDirection {
        case top
        case bottom
    }
    let arrowDirection: ArrowDirection
    let size: CGSize
    let contentView = UIView()
    let botttomView = UIView()
    var shapeLayer: CAShapeLayer?
    init(arrowDirection: ArrowDirection, size: CGSize) {
        self.arrowDirection = arrowDirection
        self.size = size
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        self.backgroundColor = .clear
        self.addSubview(contentView)
        botttomView.backgroundColor = UIColor.ud.bgFloat
        self.addSubview(botttomView)
        contentView.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        contentView.backgroundColor = UIColor.clear
        contentView.clipsToBounds = true
        let targetFrame = contentView.frame
        let path = UIBezierPath()
        switch self.arrowDirection {
        case .top:
            path.move(to: CGPoint(x: targetFrame.minX, y: targetFrame.maxY))
            path.addLine(to: CGPoint(x: targetFrame.midX, y: targetFrame.minY))
            path.addLine(to: CGPoint(x: targetFrame.maxX, y: targetFrame.maxY))
            botttomView.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(1)
                make.bottom.equalToSuperview()
            }
        case .bottom:
            path.move(to: CGPoint(x: targetFrame.minX, y: targetFrame.minY))
            path.addLine(to: CGPoint(x: targetFrame.midX, y: targetFrame.maxY))
            path.addLine(to: CGPoint(x: targetFrame.maxX, y: targetFrame.minY))
            botttomView.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.height.equalTo(1)
                make.top.equalToSuperview()
            }
        }
        path.close()
        let triangleLayer = CAShapeLayer()
        triangleLayer.path = path.cgPath
        triangleLayer.fillColor = UIColor.ud.bgFloat.cgColor
        triangleLayer.lineWidth = 1
        triangleLayer.strokeColor = UIColor.ud.lineBorderCard.cgColor
        contentView.layer.addSublayer(triangleLayer)
        shapeLayer = triangleLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.isHidden = !(self.frame.width > 0 && self.frame.height > 0)
        self.botttomView.isHidden = self.contentView.isHidden
        self.shapeLayer?.fillColor = UIColor.ud.bgFloat.cgColor
        self.shapeLayer?.strokeColor = UIColor.ud.lineBorderCard.cgColor
    }
}
