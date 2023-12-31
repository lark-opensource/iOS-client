//
//  UserAvatarListView.swift
//  UDDemo
//
//  Created by houjihu on 2021/4/8.
//

import Foundation
import UIKit
import SnapKit
import LarkExtensions
import LarkInteraction
import LarkBizAvatar

public extension UserAvatarListView {
    static var defaultSize: CGFloat { 24.auto() }
    static let defaultOverSize: CGFloat = 4
    static let defaultEdgeSize: CGFloat = 2
    static var defaultFont: UIFont { UIFont.ud.caption1 }
    static var defaultTextColor: UIColor { UIColor.ud.textCaption }
    static var defaultBackgroundColor: UIColor { UIColor.ud.bgFiller }
}

/// 用户头像列表
/// 最多展示5个头像，其余只显示一个剩余个数
public final class UserAvatarListView: UIView {
    public typealias AvatarListTapped = () -> Void
    public typealias SetAvatarTask = (BizAvatar) -> Void

    var setAvatarTasks: [SetAvatarTask] = []

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
    var onTap: AvatarListTapped?
    private var tapGesture: UITapGestureRecognizer?

    /// 初始化方法
    /// - Parameters:
    ///   - avatarViews: 头像视图集合
    ///   - restCount: 剩余个数
    public init(setAvatarTasks: [SetAvatarTask],
                restCount: Int = 0,
                avatarSize: CGFloat = UserAvatarListView.defaultSize,
                avatarOverSize: CGFloat = UserAvatarListView.defaultOverSize,
                avatarEdgeSize: CGFloat = UserAvatarListView.defaultEdgeSize,
                restTextFont: UIFont = UserAvatarListView.defaultFont,
                restTextColor: UIColor = UserAvatarListView.defaultTextColor,
                restBackgroundColor: UIColor = UserAvatarListView.defaultBackgroundColor,
                onTap: AvatarListTapped? = nil) {
        self.setAvatarTasks = setAvatarTasks
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
        addPointerInteraction()
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
        let count = setAvatarTasks.count
        for index in 0..<count {
            let task = setAvatarTasks[index]
            let avatar = BizAvatar(frame: .zero)
            // 最后一个视图不需要切圆孔
            if !Self.shouldShowRestView(restCount) && index == (count - 1) {
                horizontalSpacing = nil
            }
            let overlayView = TransparentCircleHoleOnOverlayView(horizontalSpacing: horizontalSpacing)
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
            let overlayView = TransparentCircleHoleOnOverlayView()
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

    func addPointerInteraction() {
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .highlight,
                             shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                                guard let view = interaction.view else {
                                    return (.zero, 0)
                                }
                                return (CGSize(width: view.bounds.width + 16, height: view.bounds.height + 16), 8)
                             })
                )
            )
            self.addLKInteraction(pointer)
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

    public func setTapEvent(_ onTap: AvatarListTapped?) {
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
    public func update(setAvatarTasks: [SetAvatarTask]? = nil,
                       restCount: Int? = nil) {
        // 如果仅更新restCount且上一次restView已展示，则不触发全量更新
        if setAvatarTasks == nil, Self.shouldShowRestView(self.restCount),
           let count = restCount, Self.shouldShowRestView(count), restView.superview != nil {
            restLabel.text = fix(restCount: count)
        } else {
            self.setAvatarTasks = setAvatarTasks ?? self.setAvatarTasks
            self.restCount = restCount ?? self.restCount
            setupViews()
        }
    }

    public static func sizeToFit(avatarCount: Int,
                                 restCount: Int = 0,
                                 avatarSize: CGFloat = 24,
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
