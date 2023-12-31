//
//  SubscribeButton.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/9.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import RxSwift
import LarkActivityIndicatorView
import UniverseDesignIcon
enum SubscribeStatus {
    case none // 隐藏
    case noSubscribe // 未订阅
    case subscribed // 已订阅
    case privated // 私密
    case subscribing // 订阅中
    case unSubscribing // 退订中

    func nextStatus() -> SubscribeStatus {
        switch self {
        case .noSubscribe:
            return .subscribing
        case .subscribing:
            return .subscribed
        case .subscribed:
            return .unSubscribing
        case .unSubscribing:
            return .noSubscribe
        default:
            return self
        }
    }

    func preStatus() -> SubscribeStatus {
        switch self {
        case .subscribing:
            return .noSubscribe
        case .unSubscribing:
            return .subscribed
        default:
            return self
        }
    }
}

extension SubscribeButton {
    struct Colors {
        var noSubscribeLayerColor: UIColor
        var noSubscribeTitleColor: UIColor
        var subscribedLayerColor: UIColor
        var subscribedTitleColor: UIColor
        var privatedLayerColor: UIColor
        var subscribingBorderColor: UIColor
        var subscribingIndicatorColor: UIColor
        var unsubscribingBorderColor: UIColor
        var unsubscribingIndicatorColor: UIColor
        var backgroundColor: UIColor

        static func from(mode: Mode) -> Colors {
            switch mode {
            case .light:
                return  Colors(noSubscribeLayerColor: UIColor.ud.primaryContentDefault,
                               noSubscribeTitleColor: UIColor.ud.primaryContentDefault,
                               subscribedLayerColor: UIColor.ud.lineBorderCard,
                               subscribedTitleColor: UIColor.ud.textTitle,
                               privatedLayerColor: UIColor.clear,
                               subscribingBorderColor: UIColor.ud.primaryContentDefault,
                               subscribingIndicatorColor: UIColor.ud.primaryContentDefault,
                               unsubscribingBorderColor: UIColor.ud.primaryFillDefault,
                               unsubscribingIndicatorColor: UIColor.ud.primaryContentDefault,
                               backgroundColor: UIColor.ud.bgBody)
            case .dark:
                return Colors(noSubscribeLayerColor: UIColor.ud.primaryContentDefault,
                              noSubscribeTitleColor: UIColor.ud.primaryContentDefault,
                              subscribedLayerColor: UIColor.clear,
                              subscribedTitleColor: UIColor.white,
                              privatedLayerColor: UIColor.clear,
                              subscribingBorderColor: UIColor.clear,
                              subscribingIndicatorColor: UIColor.white,
                              unsubscribingBorderColor: UIColor.ud.primaryFillDefault,
                              unsubscribingIndicatorColor: UIColor.white,
                              backgroundColor: UIColor.ud.primaryContentDefault)
            }
        }
    }

    enum Mode {
        case light
        case dark
    }
}

final class SubscribeButton: UIButton {
    static var maximunLabelWidth: CGFloat {
        let font = UIFont.cd.font(ofSize: 14)
        let width = max(BundleI18n.Calendar.Calendar_SubscribeCalendar_Subscribe.width(with: font),
                        BundleI18n.Calendar.Calendar_SubscribeCalendar_UnsubscribeCalendars.width(with: font))
        return max(width + 24, 60) // 最小宽度为60
    }

    private let indicator = ActivityIndicatorView(color: UIColor.ud.primaryContentDefault)
    private var currentColors = Colors.from(mode: .light)
    private var highlightedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.textTitle.withAlphaComponent(0.05)
        view.isHidden = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        snp.makeConstraints { (make) in
            make.width.greaterThanOrEqualTo(SubscribeButton.maximunLabelWidth)
        }
        titleLabel?.text = BundleI18n.Calendar.Calendar_SubscribeCalendar_UnsubscribeCalendars
        titleLabel?.backgroundColor = UIColor.clear
        isHidden = true
        layer.borderWidth = 1
        layer.cornerRadius = 6
        titleLabel?.font = UIFont.cd.font(ofSize: 14)
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        setSubMode(.light)
        layout(indicator: indicator, in: self)
        highlightedView.layout(equalTo: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout(indicator: UIView, in superView: UIView) {
        superView.addSubview(indicator)
        indicator.isHidden = true
        indicator.isUserInteractionEnabled = false
        indicator.snp.makeConstraints({ (make) in
            make.centerY.centerX.equalToSuperview()
            make.height.width.equalTo(16)
        })
    }

    override public var isUserInteractionEnabled: Bool {
        didSet {
            if isUserInteractionEnabled {
                highlightedView.backgroundColor = UIColor.ud.textTitle.withAlphaComponent(0.05)
                highlightedView.isHidden = true
            } else {
                highlightedView.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.5)
                highlightedView.isHidden = false
            }
        }
    }

    private func showLoadding(_ isShow: Bool, color: UIColor = UIColor.ud.primaryContentDefault) {
        if isShow {
            indicator.color = color
            indicator.startAnimating()
            indicator.isHidden = false
            isUserInteractionEnabled = false
        } else {
            indicator.stopAnimating()
            indicator.isHidden = true
            isUserInteractionEnabled = true
        }
    }

    public func setSubMode(_ mode: Mode) {

        currentColors = Colors.from(mode: mode)
        backgroundColor = currentColors.backgroundColor
    }

    public func setSubStatus(_ status: SubscribeStatus) {
        isHidden = false
        isUserInteractionEnabled = true
        setImage(nil, for: .normal)
        showLoadding(false)
        switch status {
        case .noSubscribe:
            layer.ud.setBorderColor(currentColors.noSubscribeLayerColor)
            setTitleColor(currentColors.noSubscribeTitleColor, for: .normal)
            setTitle(BundleI18n.Calendar.Calendar_SubscribeCalendar_Subscribe, for: .normal)
        case .subscribed:
            layer.ud.setBorderColor(currentColors.subscribedLayerColor)
            setTitleColor(currentColors.subscribedTitleColor, for: .normal)
            setTitle(BundleI18n.Calendar.Calendar_SubscribeCalendar_UnsubscribeCalendars, for: .normal)
        case .privated:
            layer.ud.setBorderColor(currentColors.privatedLayerColor)
            setImage(UDIcon.getIconByKeyNoLimitSize(.lockOutlined).scaleInfoSize().renderColor(with: .n3), for: .normal)
            setTitleColor(UIColor.ud.textDisable, for: .normal)
            setTitle(BundleI18n.Calendar.Calendar_SubscribeCalendar_Private, for: .normal)
            isUserInteractionEnabled = false
            highlightedView.isHidden = true
        case .subscribing:
            layer.ud.setBorderColor(currentColors.subscribingBorderColor)
            setTitle("", for: .normal)
            showLoadding(true, color: currentColors.subscribingIndicatorColor)
        case .unSubscribing:
            layer.ud.setBorderColor(currentColors.unsubscribingBorderColor)
            setTitle("", for: .normal)
            showLoadding(true, color: currentColors.unsubscribingIndicatorColor)
        case .none:
            isHidden = true
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        highlightedView.isHidden = false
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        highlightedView.isHidden = true
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        highlightedView.isHidden = true
    }
}
