//
//  BottomBasketView.swift
//  LarkSuspendable
//
//  Created by bytedance on 2021/1/5.
//

import Foundation
import UIKit
import Homeric
import LKCommonsTracker
import UniverseDesignColor
import FigmaKit
import LarkQuickLaunchInterface
import LarkContainer

struct MockQuickLaunchService {
    // 最小成本屏蔽 QuickLauncher 对多任务浮窗的影响
    var isQuickLauncherEnabled = false
}

/// 右下角扇形篮筐
public final class BottomBasketView: UIView {

    // @InjectedUnsafeLazy var quickLaunchService: QuickLaunchService
    private lazy var quickLaunchService = MockQuickLaunchService()
    
    enum State {
        case disabled
        case enabled
        case exist
    }

    var state: State = .enabled {
        didSet {
            switch state {
            case .enabled:
                backgroundView.transform = .identity
                sectorView.fillColor = Cons.unselectColor
                textLabel.textColor = Cons.unselectTextColor
                iconView.image = Cons.currentIcon.ud.withTintColor(Cons.unselectTextColor)
                textLabel.text = BundleI18n.LarkSuspendable.Lark_Core_PutIntoFloating
            case .disabled:
                backgroundView.transform = .identity
                sectorView.fillColor = Cons.disableColor
                textLabel.textColor = Cons.disableTextColor
                iconView.image = Cons.currentIcon.ud.withTintColor(Cons.disableTextColor)
                textLabel.text = BundleI18n.LarkSuspendable.Lark_Core_FloatingLimit
            case .exist:
                backgroundView.transform = .identity
                sectorView.fillColor = Cons.existColor
                textLabel.textColor = Cons.existTextColor
                iconView.image = Cons.currentIcon.ud.withTintColor(Cons.existTextColor)
                textLabel.text = BundleI18n.LarkSuspendable.Lark_Core_MovedAgain
            }
            // 如果「最近使用」功能打开
            if quickLaunchService.isQuickLauncherEnabled {
                iconView.image = BundleResources.LarkSuspendable.icon_launcher
                textLabel.text = BundleI18n.LarkSuspendable.Lark_Core_AddToMore_Foating_Text
            }
        }
    }

    private lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.font = UIFont.systemFont(ofSize: 12)
        textLabel.textAlignment = .center
        textLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        textLabel.numberOfLines = 0
        return textLabel
    }()

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = self.quickLaunchService.isQuickLauncherEnabled ? BundleResources.LarkSuspendable.icon_launcher :  BundleResources.LarkSuspendable.icon_basket_light
        return view
    }()

    private lazy var backgroundView = UIView()

    private lazy var sectorView: VisualBlurView = {
        let blurView = VisualBlurView()
        blurView.blurRadius = 8
        blurView.fillColor = Cons.unselectColor
        return blurView
    }()

    init(frame: CGRect, state: State) {
        self.state = state
        super.init(frame: frame)
        setupSubviews()
        setupConstraints()
        setupAppearance()
        isUserInteractionEnabled = false
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        // 添加扇形背景
        addSubview(backgroundView)
        backgroundView.addSubview(sectorView)
        // 添加提示图标和文字
        addSubview(iconView)
        addSubview(textLabel)
    }

    private func setupConstraints() {
        backgroundView.snp.makeConstraints { make in
            make.centerX.equalTo(self.snp.right)
            make.centerY.equalTo(self.snp.bottom)
            make.width.height.equalToSuperview().multipliedBy(2)
        }
        sectorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        textLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().offset(10)
            make.width.equalTo(110)
            make.top.equalTo(iconView.snp.bottom).offset(8)
        }
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(58)
            make.width.height.equalTo(40)
            make.centerX.equalTo(textLabel)
        }
    }

    private func setupAppearance() {
        state = .enabled
        backgroundColor = .clear
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.layer.cornerRadius = min(bounds.width, bounds.height)
        backgroundView.layer.masksToBounds = true
    }

    /// 记录手指拖动位置是否在扇形范围内
    private var isInside: Bool = false

    // 埋点使用，记录篮筐展示进度
    private let keyPoints: [CGFloat] = [0.01, 0.25, 0.5, 1.0]
    private let keyPointsName: [String] = ["zero", "quarter", "half", "complete"]
    private var keyPointsRecord: [Bool] = [false, false, false, false]
    private func clearKeyPointsRecord() {
        keyPointsRecord = [false, false, false, false]
    }
}

// MARK: - Public Methods

extension BottomBasketView {

    func show(percent: CGFloat) {
        let beginP: CGFloat = 0.25
        let finishP: CGFloat = 0.5
        let factor = max(0, min(1, (percent - beginP) / (finishP - beginP)))
        transform = CGAffineTransform(
            translationX: -bounds.width * 0.71 * factor,
            y: -bounds.height * 0.71 * factor)
        // Analytics
        for (index, keyPoint) in keyPoints.enumerated() {
            if factor < keyPoint { continue }
            if keyPointsRecord[index] == true { continue }
            Tracker.post(TeaEvent(Homeric.TASKLIST_BASKET_VIEW, params: [
                "percentage": keyPointsName[index]
            ]))
            keyPointsRecord[index] = true
        }
    }

    func show(animated: Bool = true) {
        let transform = CGAffineTransform(
            translationX: -bounds.width * 0.71,
            y: -bounds.height * 0.71)
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.transform = transform
            }
        } else {
            self.transform = transform
        }
    }

    func hide(animated: Bool = true) {
        isInside = false
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.transform = .identity
            }, completion: { _ in
                SuspendManager.shared.changeBasketStateIfNeeded()
            })
        } else {
            self.transform = .identity
            SuspendManager.shared.changeBasketStateIfNeeded()
        }
        clearKeyPointsRecord()
    }

    func touchDidMove(toPoint point: CGPoint) {
        isInsideBasket(point: point)
    }

    @discardableResult
    func isInsideBasket(point: CGPoint) -> Bool {
        let center = CGPoint(x: frame.maxX, y: frame.maxY)
        let distance = pointDistance(from: point, to: center)
        let isInsideBasket = isInside ? distance <= bounds.width * Cons.scaleFactor : distance <= bounds.width
        if isInside != isInsideBasket {
            generateHapticFeedback()
            if state == .enabled {
                if isInsideBasket {
                    sectorView.fillColor = Cons.selectColor
                    backgroundView.transform = CGAffineTransform(scaleX: Cons.scaleFactor, y: Cons.scaleFactor)
                    textLabel.text = quickLaunchService.isQuickLauncherEnabled ? BundleI18n.LarkSuspendable.Lark_Core_Added_Foating_Text : BundleI18n.LarkSuspendable.Lark_Core_FloatedSuccessfully
                } else {
                    sectorView.fillColor = Cons.unselectColor
                    backgroundView.transform = .identity
                    textLabel.text = quickLaunchService.isQuickLauncherEnabled ? BundleI18n.LarkSuspendable.Lark_Core_AddToMore_Foating_Text :  BundleI18n.LarkSuspendable.Lark_Core_PutIntoFloating
                }
            }
            isInside = isInsideBasket
        }
        return isInsideBasket
    }

    private func pointDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(pow((from.x - to.x), 2) + pow((from.y - to.y), 2))
    }

    private func generateHapticFeedback() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

extension BottomBasketView {

    enum Cons {
        static let scaleFactor: CGFloat = SuspendConfig.basketScale

        // Basket background color
        static var unselectColor: UIColor { UIColor.ud.N900.withAlphaComponent(0.8) }
        static var disableColor: UIColor { UIColor.ud.N400.withAlphaComponent(0.9) }
        static var existColor: UIColor { UIColor.ud.N400.withAlphaComponent(0.9) }
        static var selectColor: UIColor {
            selectColor(for: SuspendManager.shared.count + 1)
        }

        // Basket tint color (text & icon)
        static var unselectTextColor: UIColor { UIColor.ud.primaryOnPrimaryFill }
        static var disableTextColor: UIColor { UIColor.ud.N600.nonDynamic }
        static var existTextColor: UIColor { UIColor.ud.N600.nonDynamic }
        static var selectTextColor: UIColor { UIColor.ud.primaryOnPrimaryFill }

        static var currentIcon: UIImage {
            selectIcon(for: SuspendManager.shared.count + 1)
        }

        private static func selectColor(for index: Int) -> UIColor {
            return colorCandidates[(index - 1) % colorCandidates.count]
        }

        private static func selectIcon(for num: Int) -> UIImage {
            let index = max(0, min(iconCandidates.count, num) - 1)
            return iconCandidates[index]
        }

        private static var colorCandidates: [UIColor] = [
            UIColor.ud.wathet,
            UIColor.ud.turquoise,
            UIColor.ud.purple,
            UIColor.ud.blue,
            UIColor.ud.indigo
        ].map { $0.withAlphaComponent(0.85) }

        private static var iconCandidates: [UIImage] = [
            BundleResources.LarkSuspendable.icon_task_1,
            BundleResources.LarkSuspendable.icon_task_2,
            BundleResources.LarkSuspendable.icon_task_3,
            BundleResources.LarkSuspendable.icon_task_4,
            BundleResources.LarkSuspendable.icon_task_5,
            BundleResources.LarkSuspendable.icon_task_6,
            BundleResources.LarkSuspendable.icon_task_7,
            BundleResources.LarkSuspendable.icon_task_8,
            BundleResources.LarkSuspendable.icon_task_9
        ]
    }
}
