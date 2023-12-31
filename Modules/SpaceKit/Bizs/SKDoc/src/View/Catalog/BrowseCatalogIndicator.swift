//
//  BrowserMenuIndicator.swift
//  SpaceKit
//
//  Created by Webster on 2019/4/22.
//

import SKFoundation
import UIKit
import SKCommon
import SKUIKit
import SKResource
import UniverseDesignIcon
import UniverseDesignColor

protocol BrowseCatalogIndicatorDelegate: AnyObject {
    func indicatorDidClicked(indicator: BrowseCatalogIndicator)
    func indicatorStartMoveVertical(indicator: BrowseCatalogIndicator)
    func indicatorDidMovedVertical(indicator: BrowseCatalogIndicator)
    func indicatorEndMoveVertical(indicator: BrowseCatalogIndicator)
    func indicatorMaxYOffset() -> CGFloat
}

class BrowseCatalogIndicator: UIView {
    weak var delegate: BrowseCatalogIndicatorDelegate?
    var isInPanGesture: Bool = false
    private var beginPoint: CGPoint = CGPoint.zero
    private let cornerRadius: CGFloat = 22.0
    private let iconWidth: CGFloat = 16
    static let circleWidth: CGFloat = 44
    static let indicatorSizeHalf: CGFloat = 46

    class func indicatorX(attachViewWidth: CGFloat) -> CGFloat {
        return attachViewWidth - BrowseCatalogIndicator.indicatorSizeHalf
    }

    private lazy var backImageView: UIImageView = {
        let view = UIImageView()
        view.image = BundleResources.SKResource.Common.SideSeek.icon_catalog_shadow
        return view
    }()

    private lazy var circleView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = cornerRadius
        view.backgroundColor = UDColor.bgFloat
        view.layer.maskedCorners = .left
        view.layer.masksToBounds = true
        view.layer.ud.setBorderColor(UDColor.lineDividerDefault)
        view.layer.borderWidth = 1.0
        return view
    }()

    private lazy var imageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.image = UDIcon.navigationButtonOutlined.ud.withTintColor(UDColor.iconN2)
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        addSubview(backImageView)
        backImageView.snp.makeConstraints { (make) in
            make.left.right.bottom.top.equalToSuperview()
        }

        addSubview(circleView)
        circleView.snp.makeConstraints { (make) in
            make.width.height.equalTo(BrowseCatalogIndicator.circleWidth)
            make.centerX.centerY.equalToSuperview()
        }

        addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(iconWidth)
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().offset(-2)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didReceiveTapGesture(gesture:)))
        tapGesture.delegate = self
        self.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didReceivePanGesture(gesture:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
        //addDebugLine()
    }

    // 测试是否准确的基准线，不要随意调用
    /* 开发关键的测试代码 不要删除
    private func addDebugLine() {
        let line = UIView(frame: .zero)
        line.backgroundColor = UIColor.ud.N1000
        addSubview(line)
        line.snp.makeConstraints { (make) in
            make.width.equalTo(800)
            //因为sideview里面cell中文字距离上边缘12像素
            make.top.equalTo(circleView).offset(12)
            make.height.equalTo(0.5)
            make.left.equalToSuperview().offset(-400)
        }
        self.clipsToBounds = false
    }*/

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func didReceiveTapGesture(gesture: UITapGestureRecognizer) {
        delegate?.indicatorDidClicked(indicator: self)
    }

    @objc
    func didReceivePanGesture(gesture: UIPanGestureRecognizer) {
        let point = gesture.location(in: self)
        if gesture.state == .began {
            beginPoint = point
            isInPanGesture = true
            delegate?.indicatorStartMoveVertical(indicator: self)
        } else if gesture.state == .changed {
            let shadowPadding: CGFloat = 14
            let minY: CGFloat =  -shadowPadding
            let maxY: CGFloat = (delegate?.indicatorMaxYOffset() ?? 100.0) - shadowPadding
            let offsetX = frame.minX
            var offsetY = self.frame.minY + (point.y - beginPoint.y)
            offsetY = min(max(minY, offsetY), maxY)
            let width = self.frame.size.width
            let height = self.frame.size.height
            self.frame = CGRect(x: offsetX, y: offsetY, width: width, height: height)
            delegate?.indicatorDidMovedVertical(indicator: self)
            isInPanGesture = true
        } else {
            isInPanGesture = false
            delegate?.indicatorEndMoveVertical(indicator: self)
        }
    }
}

extension BrowseCatalogIndicator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
