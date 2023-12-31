//
//  SkeletonLoadingView.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/6/15.
//

import UIKit

private enum Const {
    enum SkeletonCell {
        static let id = "SkeletonLoadingUnitCell"
        static let animKey = "shimmerAnimKey"
    }

    enum SkeletonLine {
        static let maxLineNum: Int = 4
        static let height: CGFloat = 14.0
        static let paddingH: CGFloat = 16.0
        static let paddingV: CGFloat = 16.0
        static let lineSpace: CGFloat = 12.0
        static let cornerRadius: CGFloat = 4.0
        static let lastLineScale: CGFloat = 1 / 3.0

        static var normalCellH: CGFloat {
            height + lineSpace
        }

        static var lastCellH: CGFloat {
            height
        }
    }

    enum Spin {
        static let animKey = "spinAnimKey"
        static let lineRatio: CGFloat = 1.0 / 10.0
        static let sizeRatio: CGFloat = 8.0 / 10.0
    }
}

final class SpinLoadingView: UIView {
    private var spinLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.lineCap = .round
        layer.strokeStart = 0
        layer.strokeEnd = 1
        return layer
    }()

    var stokeColor: UIColor = UIColor.ud.primaryContentDefault {
        didSet {
            updateAnimation()
        }
    }

    /// spin circle degree, (0.0, 1.0)
    var degree: CGFloat = 0.6 {
        willSet {
            if newValue <= 0.0 || newValue >= 1.0 {
                assertionFailure("invalid degree!")
            }
        }
        didSet {
            updateAnimation()
        }
    }

    var animationDuration: TimeInterval = 1.0 {
        willSet {
            if newValue <= 0 {
                assertionFailure("invalid animationDuration")
            }
        }
        didSet {
            updateAnimation()
        }
    }

    var animating: Bool = false {
        didSet {
            updateAnimation()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.addSublayer(spinLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let dx = bounds.width * (1 - Const.Spin.sizeRatio) * 0.5
        let dy = bounds.height * (1 - Const.Spin.sizeRatio) * 0.5
        let spinFrame = bounds.insetBy(dx: dx, dy: dy)
        spinLayer.frame = spinFrame
        spinLayer.path = UIBezierPath(ovalIn: spinLayer.bounds).cgPath
        spinLayer.lineWidth = bounds.width * Const.Spin.lineRatio
        spinLayer.ud.setStrokeColor(stokeColor)

        updateAnimation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateAnimation() {
        if animating {
            spinLayer.removeAnimation(forKey: Const.Spin.animKey)

            let start = CABasicAnimation(keyPath: "strokeStart")
            start.fromValue = -log2(1 / (1 - degree))
            start.toValue = 1

            let end = CABasicAnimation(keyPath: "strokeEnd")
            end.fromValue = 0
            end.toValue = 1

            let group = CAAnimationGroup()
            group.animations = [start, end]
            group.duration = animationDuration
            group.repeatCount = .infinity
            group.isRemovedOnCompletion = false

            spinLayer.add(group, forKey: Const.Spin.animKey)
        } else {
            spinLayer.removeAnimation(forKey: Const.Spin.animKey)
        }
    }
}

final class SkeletonLoadingView: UIView {
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: bounds, style: .plain)
        table.backgroundColor = UIColor.clear
        table.dataSource = self
        table.delegate = self
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = false
        table.isUserInteractionEnabled = false
        table.allowsSelection = false
        table.register(SkeletonLoadingUnitCell.self, forCellReuseIdentifier: Const.SkeletonCell.id)
        return table
    }()

    var animating: Bool = false {
        didSet {
            updateAnimation()
        }
    }

    private var numberOfLines: Int {
        let totalH = bounds.size.height
        let padding = Const.SkeletonLine.paddingV
        let lineSpace = Const.SkeletonLine.lineSpace
        let height = Const.SkeletonLine.height
        let num = Int((totalH - 2 * padding + lineSpace) / (height + lineSpace))
        return min(max(1, num), Const.SkeletonLine.maxLineNum)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.clear
        addSubview(tableView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        tableView.frame = CGRect(origin: .zero, size: bounds.size)

        if numberOfLines >= 2 {
            tableView.contentInset = UIEdgeInsets(horizontal: 0, vertical: 16)
        } else {
            tableView.contentInset = .zero
        }

        tableView.reloadData()

        updateAnimation()
    }

    private func updateAnimation() {
        for cell in tableView.visibleCells {
            if let loadingCell = cell as? SkeletonLoadingUnitCell {
                loadingCell.animating = animating
            }
        }
    }
}

extension SkeletonLoadingView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let totalLinesNum = numberOfLines
        if totalLinesNum <= 1 {
            return tableView.bounds.size.height
        } else if indexPath.row == totalLinesNum - 1 {
            return Const.SkeletonLine.height
        } else {
            return Const.SkeletonLine.height + Const.SkeletonLine.lineSpace
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        numberOfLines
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Const.SkeletonCell.id, for: indexPath)
        if let loadingCell = cell as? SkeletonLoadingUnitCell {
            let totalLinesNum = numberOfLines
            if totalLinesNum <= 1 {
                // 只展示一行
                loadingCell.lineScale = 1.0
                loadingCell.linePosition = .middle
            } else if indexPath.row == totalLinesNum - 1 {
                // 多行的 尾行
                loadingCell.lineScale = 0.33
                loadingCell.linePosition = .top
            } else {
                // 多行的 非尾行
                loadingCell.lineScale = 1.0
                loadingCell.linePosition = .top
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let loadingCell = cell as? SkeletonLoadingUnitCell else {
            return
        }
        loadingCell.animating = animating
    }
}

final class SkeletonLoadingUnitCell: UITableViewCell {

    enum LinePosition {
        case middle
        case top
    }

    var lineScale: CGFloat = 1.0 {
        didSet {
            setNeedsLayout()
        }
    }

    var linePosition: LinePosition = .middle {
        didSet {
            setNeedsLayout()
        }
    }

    private lazy var lineView: UIView = {
        let vi = UIView(frame: bounds)
        vi.backgroundColor = UIColor.clear
        vi.layer.cornerRadius = Const.SkeletonLine.cornerRadius
        vi.layer.masksToBounds = true
        return vi
    }()

    private lazy var lineLayer: CALayer = {
        CALayer()
    }()

    private lazy var maskLayer: CAGradientLayer = {
        CAGradientLayer()
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear
        selectionStyle = .none

        addSubview(lineView)
        lineView.layer.addSublayer(lineLayer)
        lineView.layer.addSublayer(maskLayer)

        lineLayer.ud.setBackgroundColor(UIColor.ud.udtokenSkeletonBg)

        let c0 = UIColor.clear
        let c1 = UIColor.ud.udtokenSkeletonFg
        maskLayer.ud.setColors([c0, c1, c0])
        maskLayer.locations = [0.0, 0.5, 1.0]
        maskLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let xPosition = Const.SkeletonLine.paddingH
        let yPosition: CGFloat
        switch linePosition {
        case .middle:
            yPosition = (bounds.size.height - Const.SkeletonLine.height) * 0.5
        case .top:
            yPosition = 0
        }
        let width = bounds.size.width - Const.SkeletonLine.paddingH * 2
        let height = Const.SkeletonLine.height

        lineView.frame = CGRect(x: xPosition, y: yPosition, width: width * lineScale, height: height)

        lineLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        maskLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var animating: Bool = false {
        didSet {
            updateAnimation()
        }
    }

    private func updateAnimation() {
        if animating {
            maskLayer.removeAnimation(forKey: Const.SkeletonCell.animKey)

            let animation = CABasicAnimation(keyPath: "locations")
            animation.fromValue = [-1.0, -0.5, 0.0]
            animation.toValue = [1.0, 1.5, 2.0]
            animation.duration = 0.8
            animation.repeatCount = .infinity
            animation.isRemovedOnCompletion = false
            maskLayer.add(animation, forKey: Const.SkeletonCell.animKey)
        } else {
            maskLayer.removeAnimation(forKey: Const.SkeletonCell.animKey)
        }
    }
}
