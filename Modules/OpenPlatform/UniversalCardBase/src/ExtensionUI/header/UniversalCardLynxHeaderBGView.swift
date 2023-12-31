//
//  UniversalCardLynxHeaderBGView.swift
//  LarkMessageCard
//
//  Created by majiaxin.jx on 2023/07/14.
//

import Foundation
import Lynx
import LKCommonsLogging
import UniverseDesignCardHeader
import UniverseDesignColor

public final class UniversalCardHeaderBG: UDCardHeader {
    private lazy var gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        gradient.isHidden = true
        layer.insertSublayer(gradient, at: 0)
        return gradient
    }()
    
    public func setLineLayerBG(hidden: Bool) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.0)
        CATransaction.setDisableActions(true)
        gradientLayer.isHidden = hidden
        CATransaction.commit()
    }

    public func setBackground(colors: [UIColor]) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setAnimationDuration(0.0)
        gradientLayer.isHidden = colors.count < 2
        switch colors.count {
        case 1:
            backgroundColor = colors.first
        case 2...:
            backgroundColor = nil
            gradientLayer.ud.setColors(colors)
            gradientLayer.locations = colors.enumerated().map { (offset: Int, _: UIColor) -> NSNumber in
                return NSNumber(value: Float(offset) / Float(colors.count - 1))
            }
        default:
            backgroundColor = nil
        }
        CATransaction.commit()
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setAnimationDuration(0.0)
        gradientLayer.frame = bounds
        CATransaction.commit()
    }
}

public final class UniversalCardLynxHeaderBGView: LynxUIView {
    public static let name: String = "msg-card-header-bg"
    private static let logger = Logger.log(UniversalCardLynxHeaderBGView.self, category: "UniversalCardLynxHeaderBGView")
    private lazy var bgView: UniversalCardHeaderBG = {
        return UniversalCardHeaderBG()
    }()

    private lazy var bgViewContainer: UIView = {
          let view = UIView()
          view.addSubview(self.bgView)
          self.bgView.snp.makeConstraints { make in
              make.left.right.bottom.top.equalToSuperview()
          }
          return view
      }()

    @objc
    public static func propSetterLookUp() -> [[String]] {
        return [
            ["props", NSStringFromSelector(#selector(setProps))],
        ]
    }

    @objc public override func createView() -> UIView? {
        bgViewContainer.isUserInteractionEnabled = false
        bgView.isUserInteractionEnabled = false
        return bgViewContainer
    }
    
    @objc func setProps(props: Any?, requestReset _: Bool) {
        guard let props = props as? [String: Any] else {
            assertionFailure("UniversalCardLynxHeaderBGView receive wrong props type: \(String(describing: props.self))")
            Self.logger.error("UniversalCardLynxHeaderBGView receive wrong props type: \(String(describing: props.self))")
            return
        }
        
        var bgProps: HeaderBGProps
        
        do {
            bgProps = try HeaderBGProps.from(dict: props)
        } catch let error {
            Self.logger.error("UniversalCardLynxHeaderBGView props serilize fail: \(error.localizedDescription)")
            return
        }
        if let bgColorToken = bgProps.bgColorToken,
           let bgColor = UDColor.getValueByBizToken(token: bgColorToken) {
            bgView.colorHue = UDCardHeaderHue(color: bgColor)
            bgView.setLineLayerBG(hidden: true)
        } else if let colors = bgProps.gradientColors {
            bgView.setBackground(colors: colors.map { UIColor.btd_color(withARGBHexString: $0) })
        }
        
    }

    public override func shouldHitTest(_ point: CGPoint, with event: UIEvent?) -> Bool {
        // 禁用交互, 否则点击后会 crash, 由 UDLayer 和 Lynx 冲突导致
        return false
    }
}
