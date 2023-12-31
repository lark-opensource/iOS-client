//
//  MyAIToolsAvatarListView.swift
//  LarkIMMention
//
//  Created by ByteDance on 2023/6/2.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor
import LarkBizAvatar

public extension MyAIToolsAvatarListView {
    static var defaultSize: CGFloat { 20.auto() }
    static let defaultOverSize: CGFloat = 4
    static let defaultEdgeSize: CGFloat = 2
    static var defaultFont: UIFont { UIFont.ud.caption1 }
    static var defaultTextColor: UIColor { UIColor.ud.textCaption }
    static var defaultBackgroundColor: UIColor { UIColor.ud.bgFiller }
}

public class MyAIToolsAvatarListView: UIView {
    public typealias ToolAvatarListTapped = () -> Void
    public typealias SetToolAvatarTask = (BizAvatar) -> Void

    var setToolAvatarTasks: [SetToolAvatarTask] = []

    lazy var restLabel: UILabel = {
        let label = UILabel()
        label.font = self.restTextFont
        label.textColor = self.restTextColor
        label.text = fix(restCount: restCount)
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        return label
    }()

    /// 剩余个数视图
    lazy var restView: UIView = {
        let view = UIView()
        view.backgroundColor = self.restBackgroundColor
        view.layer.borderColor = UIColor.clear.cgColor
        view.layer.cornerRadius = self.avatarSize / 2.0
        view.clipsToBounds = true
        let label = self.restLabel
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.right.equalToSuperview()
        }
        return view
    }()

    /// 剩余个数
    var restCount: Int
    /// 剩余个数视图文字尺寸
    let restTextFont: UIFont
    /// 剩余个数视图文字颜色
    let restTextColor: UIColor
    /// 剩余个数视图背景颜色
    let restBackgroundColor: UIColor
    /// 头像大小：width & height
    let avatarSize: CGFloat
    /// 头像重叠大小
    let avatarOverSize: CGFloat
    /// 头像边缘透明大小
    let avatarEdgeSize: CGFloat
    var onTap: ToolAvatarListTapped?
    private var tapGesture: UITapGestureRecognizer?

    /// 初始化方法
    /// - Parameters:
    ///   - avatarViews: 头像视图集合
    ///   - restCount: 剩余个数
    public init(setToolAvatarTasks: [SetToolAvatarTask],
                restCount: Int = 0,
                avatarSize: CGFloat = MyAIToolsAvatarListView.defaultSize,
                avatarOverSize: CGFloat = MyAIToolsAvatarListView.defaultOverSize,
                avatarEdgeSize: CGFloat = MyAIToolsAvatarListView.defaultEdgeSize,
                restTextFont: UIFont = MyAIToolsAvatarListView.defaultFont,
                restTextColor: UIColor = MyAIToolsAvatarListView.defaultTextColor,
                restBackgroundColor: UIColor = MyAIToolsAvatarListView.defaultBackgroundColor,
                onTap: ToolAvatarListTapped? = nil) {
        self.setToolAvatarTasks = setToolAvatarTasks
        self.restCount = restCount
        self.restTextFont = restTextFont
        self.restTextColor = restTextColor
        self.restBackgroundColor = restBackgroundColor
        self.avatarSize = avatarSize
        self.avatarOverSize = avatarOverSize
        self.avatarEdgeSize = avatarEdgeSize
        self.onTap = onTap
        super.init(frame: .zero)
        setupViews()
        addTapGestureIfNeed()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        self.subviews.forEach { $0.removeFromSuperview() }
        var horizontalSpacing: CGFloat? = self.avatarEdgeSize
        var overlayViewX: CGFloat = 0.0
        let step = avatarSize - avatarOverSize
        let count = setToolAvatarTasks.count
        for index in 0..<count {
            let task = setToolAvatarTasks[index]
            let avatar = BizAvatar(frame: .zero)
            avatar.backgroundColor = UIColor.ud.bgBase
            // 最后一个视图不需要切圆孔
            if !Self.shouldShowRestView(restCount) && index == (count - 1) {
                horizontalSpacing = nil
            }
            let overlayView = MyAIToolTransparentCircleHoleOnOverlayView(horizontalSpacing: horizontalSpacing)
            addSubview(overlayView)
            overlayView.snp.makeConstraints { make in
                make.width.height.equalTo(self.avatarSize)
                make.centerY.equalToSuperview()
                make.left.equalTo(overlayViewX)
            }
            overlayViewX += step

            avatar.layer.borderColor = UIColor.clear.cgColor
            avatar.layer.cornerRadius = self.avatarSize / 2.0
            avatar.clipsToBounds = true
            overlayView.addSubview(avatar)
            avatar.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(self.avatarSize)
            }
            task(avatar)
        }
        if Self.shouldShowRestView(restCount) {
            let overlayView = MyAIToolTransparentCircleHoleOnOverlayView()
            addSubview(overlayView)
            overlayView.snp.makeConstraints { make in
                make.width.height.equalTo(self.avatarSize)
                make.centerY.equalToSuperview()
                make.left.equalTo(overlayViewX)
            }

            overlayView.addSubview(restView)
            restView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(self.avatarSize)
            }
            restLabel.text = fix(restCount: restCount)
        }
    }

    private func fix(restCount: Int) -> String {
        /// 最多显示99+
        let maxShowCount = 99
        let description = (restCount <= maxShowCount) ? "+\(restCount)" : "\(maxShowCount)+"
        return description
    }

    private func addTapGestureIfNeed() {
        guard tapGesture == nil else { return }
        tapGesture = self.lu.addTapGestureRecognizer(action: #selector(tapped), target: self)
    }

    @objc
    private func tapped() {
        onTap?()
    }

    public func setTapEvent(_ onTap: ToolAvatarListTapped?) {
        if onTap == nil {
            self.onTap = nil
            tapGesture = nil
        } else {
            self.onTap = onTap
            addTapGestureIfNeed()
        }
    }

    /// 暂时只支持update avatarViews，restCount属性
    ///
    /// - Parameters:
    ///     - avatarViews: use old values if nil
    ///     - restCount: use old values if nil
    public func update(setToolAvatarTasks: [SetToolAvatarTask]? = nil,
                       restCount: Int? = nil) {
        // 如果仅更新restCount且上一次restView已展示，则不触发全量更新
        if setToolAvatarTasks == nil, Self.shouldShowRestView(self.restCount),
           let count = restCount, Self.shouldShowRestView(count), restView.superview != nil {
            restLabel.text = fix(restCount: count)
        } else {
            self.setToolAvatarTasks = setToolAvatarTasks ?? self.setToolAvatarTasks
            self.restCount = restCount ?? self.restCount
            setupViews()
        }
    }

    public static func sizeToFit(avatarCount: Int,
                                 restCount: Int = 0,
                                 avatarSize: CGFloat = MyAIToolsAvatarListView.defaultSize,
                                 avatarOverSize: CGFloat = 4) -> CGSize {
        let count = shouldShowRestView(restCount) ? avatarCount + 1 : avatarCount
        let width = CGFloat(count) * avatarSize - CGFloat(max(0, count - 1)) * avatarOverSize
        return .init(width: width, height: avatarSize)
    }

    /// 是否需要展示剩余个数视图
    private static func shouldShowRestView(_ restCount: Int) -> Bool {
        return restCount > 0
    }
}

/// 带有右侧透明圆孔的视图
final class MyAIToolTransparentCircleHoleOnOverlayView: UIView {
    /// 元素水平间距
    let horizontalSpacing: CGFloat?

    /// 初始化
    /// - Parameter horizontalSpacing: 元素水平间距。可选参数，如果为nil则不显示圆角，用于处理最后一个视图
    init(horizontalSpacing: CGFloat? = nil) {
        self.horizontalSpacing = horizontalSpacing
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// eclipse mask
    private lazy var eclipsePath: UIBezierPath? = {
        // 从右下角的交点开始，先顺时针画左侧长弧线，再逆时针补充右侧短弧线
        // 相关计算请参考：https://bytedance.feishu.cn/docs/doccnbZDNj9cyn0C5szZ2jznotd
        guard let horizontalSpacing = horizontalSpacing else {
            return nil
        }
        let spacing = horizontalSpacing
        let radius = bounds.width / 2.0

        let footPointToLeftCircleCenter: CGFloat = (4 * radius * radius + 3 * spacing * spacing - 10 * radius * spacing) / (4 * radius - 4 * spacing)
        let alphaCornerRadian: CGFloat = CGFloat(acos(footPointToLeftCircleCenter / radius))
        let leftCircleCenter: CGPoint = CGPoint(x: radius, y: radius)
        let leftCircleStartRadian: CGFloat = alphaCornerRadian
        let leftCircleEndRadian: CGFloat = CGFloat.pi * 2 - alphaCornerRadian

        let footPointToRightCircleCenter: CGFloat = 2 * radius - 2 * spacing - footPointToLeftCircleCenter
        let betaCornerRadian: CGFloat = CGFloat(acos(footPointToRightCircleCenter / (radius + spacing)))
        let rightCircleCenter: CGPoint = CGPoint(x: radius * 3 - spacing * 2, y: radius)
        let rightCircleStartRadian: CGFloat = CGFloat.pi + betaCornerRadian
        let rightCircleEndRadian: CGFloat = CGFloat.pi - betaCornerRadian

        let path = UIBezierPath(arcCenter: leftCircleCenter,
                                radius: radius,
                                startAngle: leftCircleStartRadian,
                                endAngle: leftCircleEndRadian,
                                clockwise: true)
        path.addArc(withCenter: rightCircleCenter,
                    radius: radius + spacing,
                    startAngle: rightCircleStartRadian,
                    endAngle: rightCircleEndRadian,
                    clockwise: false)
        path.close()
        return path
    }()

    // MARK: - Drawing
    override func layoutSubviews() {
        superview?.layoutSubviews()

        guard let eclipsePath = self.eclipsePath else {
            return
        }

        let layer = CAShapeLayer()
        layer.path = eclipsePath.cgPath
        self.layer.mask = layer
    }
}
