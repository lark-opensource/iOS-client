//
//  ScheduleSendDatePickerController.swift
//  LarkChat
//
//  Created by JackZhao on 2022/8/30.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import LarkUIKit
import LKCommonsLogging
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignDatePicker
import UniverseDesignActionPanel

// 定时消息选择器下面的按钮
public struct ScheduleSendPickerButtonItem {
    var identify: String
    var title: NSAttributedString
    var cornerRadius: CGFloat
    var borderWidth: CGFloat
    var borderColor: CGColor?
    var backgroundColor: UIColor
    var handler: (_ vc: UIViewController) -> Void

    public init(identify: String,
                title: NSAttributedString,
                cornerRadius: CGFloat = 0,
                borderWidth: CGFloat = 0,
                borderColor: CGColor? = nil,
                backgroundColor: UIColor = .clear,
                handler: @escaping (_ vc: UIViewController) -> Void) {
        self.identify = identify
        self.title = title
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.backgroundColor = backgroundColor
        self.handler = handler
    }
}

public struct ScheduleSendPickerConfig {
    // 标题
    var title: String
    var date: Date
    var maximumDate: Date
    var minimumDate: Date
    var timeZone: TimeZone
    // 选择时间组件的配置，透传给 UDDateWheelPickerView
    var dateWheelConfig: UniverseDesignDatePicker.UDWheelsStyleConfig
    // 底部按钮，按顺序排列
    var bottomButtons: [ScheduleSendPickerButtonItem]

    public init(title: String,
                date: Date = Date(),
                maximumDate: Date = UDWheelsStyleConfig.defaultMaxDate,
                minimumDate: Date = UDWheelsStyleConfig.defaultMinDate,
                timeZone: TimeZone = TimeZone.current,
                dateWheelConfig: UniverseDesignDatePicker.UDWheelsStyleConfig = UniverseDesignDatePicker.UDWheelsStyleConfig(),
                bottomButtons: [ScheduleSendPickerButtonItem] = []) {
        self.title = title
        self.date = date
        self.maximumDate = maximumDate
        self.minimumDate = minimumDate
        self.timeZone = timeZone
        self.dateWheelConfig = dateWheelConfig
        self.bottomButtons = bottomButtons
    }
}

// 定时发送时间选择器
public final class ScheduleSendPickerViewController: UIViewController {
    static let logger = Logger.log(ScheduleSendPickerViewController.self, category: "LarkMessageCore")

    private let config: ScheduleSendPickerConfig
    private let disposeBag = DisposeBag()

    private lazy var titleBar = UIView()
    private lazy var divideLine: UIView = {
        let view = UIView()
        view.backgroundColor = UDDatePickerTheme.calendarPickerCurrentMonthBgColor
        return view
    }()
    //  选择时间回调
    public var dateChanged: ((Date) -> Void)?
    // 根据config里的items生成的按钮
    private var buttons: [ScheduleSendPickerButton] = []

    private lazy var dateWheelPicker = UDDateWheelPickerView(date: config.date,
                                                             timeZone: config.timeZone, maximumDate: config.maximumDate,
                                                             minimumDate: config.minimumDate,
                                                             wheelConfig: config.dateWheelConfig)

    public init(config: ScheduleSendPickerConfig) {
        self.config = config
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 实际高度
    public var intrinsicHeight: CGFloat {
        let buttonHeight: CGFloat = CGFloat(config.bottomButtons.count) * Cons.buttonHeight +
        CGFloat(config.bottomButtons.count - 1) * Cons.buttonVerticalMargin
        return Cons.titleBarHeight + dateWheelPicker.intrinsicHeight + Cons.datePickerBottom + buttonHeight
    }

    /// 选中参数 date 所对应时刻
    public func select(date: Date = Date(), animated: Bool = false) {
        dateWheelPicker.select(date: date, animated: animated)
    }

    public func updateBottomButtonWith(identify: String,
                                       title: NSAttributedString? = nil,
                                       cornerRadius: CGFloat? = nil,
                                       borderWidth: CGFloat? = nil,
                                       borderColor: CGColor? = nil,
                                       backgroundColor: UIColor? = nil) {
        guard let button = self.buttons.first(where: { $0.identify == identify }) else {
            assertionFailure("can`t found button identify is \(identify)")
            Self.logger.info("can`t found button identify is \(identify)")
            return
        }
        if let title = title {
            button.updateTitle(title)
        }
        if let cornerRadius = cornerRadius {
            button.layer.cornerRadius = cornerRadius
        }
        if let borderWidth = borderWidth {
            button.layer.borderWidth = borderWidth
        }
        if let borderColor = borderColor {
            button.layer.borderColor = borderColor
        }
        if let backgroundColor = backgroundColor {
            button.backgroundColor = backgroundColor
        }
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        layoutTitleBar()
    }

    private func layoutTitleBar() {
        let titleLabel = UILabel()
        titleLabel.text = config.title
        titleLabel.font = UDFont.body0
        titleLabel.textColor = UDDatePickerTheme.wheelPickerTitlePrimaryNormalColor

        titleBar.addSubview(titleLabel)
        titleBar.addSubview(divideLine)
        view.addSubview(dateWheelPicker)
        view.addSubview(titleBar)

        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        divideLine.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        titleBar.snp.makeConstraints { (make) in
            make.height.equalTo(Cons.titleBarHeight)
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(dateWheelPicker.snp.top)
        }
        var dateWheelPickerBottom: SnapKit.Constraint?
        dateWheelPicker.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            dateWheelPickerBottom = make.bottom.equalTo(-Cons.datePickerBottom).constraint
        }
        dateWheelPicker.dateChanged = { [weak self] date in
            self?.dateChanged?(date)
        }

        var previewButtonTop = dateWheelPicker.snp.bottom
        var index = 0
        // 初始化底部按钮
        config.bottomButtons.forEach { item in
            index += 1
            let button = ScheduleSendPickerButton(identify: item.identify, title: item.title)
            button.backgroundColor = item.backgroundColor
            button.layer.cornerRadius = item.cornerRadius
            button.layer.masksToBounds = true
            button.layer.borderWidth = item.borderWidth
            button.layer.borderColor = item.borderColor

            view.addSubview(button)
            button.snp.makeConstraints { make in
                make.top.equalTo(previewButtonTop).offset(Cons.buttonVerticalMargin)
                make.left.equalTo(Cons.buttonHirizontalPadding)
                make.right.equalTo(-Cons.buttonHirizontalPadding).constraint
                if index == config.bottomButtons.count {
                    dateWheelPickerBottom?.deactivate()
                    make.bottom.equalTo(-Cons.datePickerBottom)
                }
            }
            button.rx.tap.asDriver()
                .drive(onNext: { [weak self, weak button] (_) in
                    guard let `self` = self, let btn = button else { return }
                    item.handler(self)
                })
                .disposed(by: disposeBag)
            self.buttons.append(button)
            previewButtonTop = button.snp.bottom
        }
    }

    private enum Cons {
        static let titleBarHeight: CGFloat = 54
        static let datePickerBottom: CGFloat = Display.iPhoneXSeries ? 43 : 13
        static let buttonVerticalMargin: CGFloat = 12
        static let buttonHirizontalPadding: CGFloat = 16
        static let buttonHeight: CGFloat = 40
    }
}

class ScheduleSendPickerButton: UIButton {
    var identify: String

    private lazy var desc: UILabel = {
        let label = UILabel()
        return label
    }()

    init(identify: String, title: NSAttributedString) {
        self.identify = identify

        super.init(frame: .zero)
        self.addSubview(desc)
        desc.attributedText = title
        desc.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(20)
            make.top.equalTo(10)
        }
    }

    func updateTitle(_ title: NSAttributedString) {
        desc.attributedText = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
