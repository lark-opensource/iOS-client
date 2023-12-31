//
//  DriveSelectionView.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/6/3.
//

import UIKit
import SnapKit

/// 拖动位置
enum PanPosition {
    case topLeft
    case topRight
    case bottomRight
    case bottomLeft
    case center
    case unknow
}

protocol DriveSelectionViewDelegate: NSObjectProtocol {
    func selectionView(_ view: DriveSelectionView, panPositon: PanPosition, gesture: UIPanGestureRecognizer)
}

class DriveSelectionView: UIView {
    let panGesture = UIPanGestureRecognizer()
    weak var delegate: DriveSelectionViewDelegate?
    var isEditable = true {
        didSet {
            showResizeViews(isEditable)
        }
    }
    /// 选区框frame
    var selectionFrame: CGRect {
        get {
            return frame.insetBy(dx: resizeViewSize.width / 2,
                                 dy: resizeViewSize.height / 2)
        }
        set {
            frame = newValue.insetBy(dx: -resizeViewSize.width / 2,
                                     dy: -resizeViewSize.height / 2)
            if isEditable {
                let hideResizeBar = newValue.width < minSize.width || newValue.height < minSize.height
                showResizeViews(!hideResizeBar)
            }
        }
    }
    var minSize: CGSize {
        return CGSize(width: resizeViewSize.width, height: resizeViewSize.height)
    }

    private let selectionView: UIView
    private let resizeViewSize = CGSize(width: 36, height: 36)
    private var panPosition = PanPosition.unknow // 拖动的位置
    private let topLeftView = DriveSelectionResizeView(frame: .zero, position: .topLeft)
    private let topRightView = DriveSelectionResizeView(frame: .zero, position: .topRight)
    private let bottomLeftView = DriveSelectionResizeView(frame: .zero, position: .bottomLeft)
    private let bottomRightView = DriveSelectionResizeView(frame: .zero, position: .bottomRight)

    override init(frame: CGRect) {
        selectionView = UIView()
        super.init(frame: frame)
        backgroundColor = .clear
        setupResizeViews()
        setupGestures()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateBorderWidth(_ width: CGFloat, animateTimeIntervale: CGFloat = 0) {
        let widthAnimation = CABasicAnimation(keyPath: "borderWidth")
        widthAnimation.fromValue = selectionView.layer.borderWidth
        widthAnimation.duration = CFTimeInterval(animateTimeIntervale)
        selectionView.layer.borderWidth = width
        selectionView.layer.add(widthAnimation, forKey: "borderWidth")
    }

    private func setupResizeViews() {
        selectionView.backgroundColor = .clear
        selectionView.layer.borderWidth = 2.0
        selectionView.layer.borderColor = UIColor.ud.colorfulYellow.cgColor
        self.addSubview(selectionView)
        self.addSubview(topLeftView)
        self.addSubview(topRightView)
        self.addSubview(bottomLeftView)
        self.addSubview(bottomRightView)
        topLeftView.backgroundColor = .clear
        topRightView.backgroundColor = .clear
        bottomLeftView.backgroundColor = .clear
        bottomRightView.backgroundColor = .clear
        topLeftView.snp.updateConstraints { (make) in
            make.top.left.equalToSuperview()
            make.width.height.equalTo(resizeViewSize.height)
        }
        topRightView.snp.updateConstraints { (make) in
            make.top.right.equalToSuperview()
            make.width.height.equalTo(resizeViewSize.height)
        }
        bottomLeftView.snp.updateConstraints { (make) in
            make.bottom.left.equalToSuperview()
            make.width.height.equalTo(resizeViewSize.height)
        }
        bottomRightView.snp.updateConstraints { (make) in
            make.bottom.right.equalToSuperview()
            make.width.height.equalTo(resizeViewSize.height)
        }
        selectionView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.height.equalToSuperview().offset(-resizeViewSize.height)
        }
    }

    private func setupGestures() {
        panGesture.addTarget(self, action: #selector(handlePanGesture(gesture:)))
        self.addGestureRecognizer(panGesture)
    }
    private func showResizeViews(_ show: Bool) {
        topLeftView.isHidden = !show
        topRightView.isHidden = !show
        bottomLeftView.isHidden = !show
        bottomRightView.isHidden = !show
    }
    @objc
    private func handlePanGesture(gesture: UIPanGestureRecognizer) {
        guard isEditable else {
            return
        }
        let location = gesture.location(in: self)
        switch gesture.state {
        case .began:
            panPosition = panPositon(of: location)
        case .cancelled, .ended, .failed:
            panPosition = PanPosition.unknow
        case .changed, .possible:
            delegate?.selectionView(self, panPositon: panPosition, gesture: gesture)
        default:
            break
        }
    }
    private func panPositon(of location: CGPoint) -> PanPosition {
        if topLeftView.frame.contains(location) {
            return .topLeft
        } else if topRightView.frame.contains(location) {
            return .topRight
        } else if bottomLeftView.frame.contains(location) {
            return .bottomLeft
        } else if bottomRightView.frame.contains(location) {
            return .bottomRight
        }
        return .center
    }
}

class DriveSelectionResizeView: UIView {
    let position: PanPosition
    let shapeLayer = CAShapeLayer()
    init(frame: CGRect, position: PanPosition) {
        self.position = position
        super.init(frame: frame)
        layer.addSublayer(shapeLayer)
        updateLayers()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        shapeLayer.frame = bounds
        updateLayers()
    }
    private func updateLayers() {
        shapeLayer.frame = bounds
        shapeLayer.strokeColor = UIColor.ud.colorfulYellow.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 5.0
        let path = UIBezierPath()
        switch position {
        case .topLeft:
            path.move(to: CGPoint(x: frame.width / 2, y: frame.height))
            path.addLine(to: CGPoint(x: frame.width / 2, y: frame.height / 2))
            path.addLine(to: CGPoint(x: frame.width, y: frame.height / 2))
        case .topRight:
            path.move(to: CGPoint(x: 0, y: frame.height / 2))
            path.addLine(to: CGPoint(x: frame.width / 2, y: frame.height / 2))
            path.addLine(to: CGPoint(x: frame.width / 2, y: frame.height))
        case .bottomLeft:
            path.move(to: CGPoint(x: frame.width / 2, y: 0))
            path.addLine(to: CGPoint(x: frame.width / 2, y: frame.height / 2))
            path.addLine(to: CGPoint(x: frame.width, y: frame.height / 2))
        case .bottomRight:
            path.move(to: CGPoint(x: 0, y: frame.height / 2))
            path.addLine(to: CGPoint(x: frame.width / 2, y: frame.height / 2))
            path.addLine(to: CGPoint(x: frame.width / 2, y: 0))
        default:
            break
        }
        shapeLayer.path = path.cgPath
    }
}
