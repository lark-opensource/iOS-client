//
//  NewChatTimezoneView.swift
//  LarkChat
//
//  Created by JackZhao on 2022/7/19.
//

import UIKit
import RxSwift
import RichLabel
import Foundation
import EENavigator
import ByteWebImage
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignDialog
import LarkMessengerInterface
import LarkContainer

protocol TimeZoneViewAbility {
    var targetVC: UIViewController? { get set }
    func updateTipContent(chatTimezoneDesc: String,
                          chatTimezone: String,
                          myTimezone: String,
                          myTimezoneType: ExternalDisplayTimezoneSettingType,
                          preferredMaxLayoutWidth: CGFloat)
}

typealias TimeZoneView = UIView & TimeZoneViewAbility

final class NewChatTimezoneView: TimeZoneView, UserResolverWrapper {
    let userResolver: UserResolver
    private static let logger = Logger.log(NewChatTimezoneView.self, category: "NewChatTimezoneView")

    struct Config {
        static let labelLeftPadding: CGFloat = 36
        static let rightPadding: CGFloat = 12
        static let arrowSize: CGFloat = 16
        static let arrowLeftMargin: CGFloat = 2
        static let viewHeight: CGFloat = 36
    }

    lazy private var tipLabel: LKLabel = {
        let label = LKLabel()
        label.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    lazy private var arrow: TimeZoneImageView = {
        var imageView = TimeZoneImageView()
        imageView.image = UDIcon.downRightOutlined.ud.withTintColor(UIColor.ud.iconN2)
        return imageView
    }()

    // 对方的时区
    private var chatTimezone: String = ""
    // 我的对外展示时区
    private var myTimezone: String = ""
    // 我的对外展示时区的类型
    private var myTimezoneType: ExternalDisplayTimezoneSettingType = .unknown
    private var preferredMaxLayoutWidth: CGFloat = 0
    weak var targetVC: UIViewController?
    private let chatNameObservable: Observable<String>
    private let disposeBag = DisposeBag()
    private var name: String = ""

    init(userResolver: UserResolver, chatNameObservable: Observable<String>) {
        self.userResolver = userResolver
        self.chatNameObservable = chatNameObservable

        super.init(frame: .zero)
        initView()
        observeData()
    }

    private func initView() {
        self.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        let timezoneImageView = UIImageView(image: Resources.timezone)
        self.addSubview(timezoneImageView)
        timezoneImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
        }
        self.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(NewChatTimezoneView.Config.labelLeftPadding)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
        self.addSubview(arrow)
        arrow.snp.makeConstraints { (make) in
            make.left.equalTo(tipLabel.snp.right).offset(NewChatTimezoneView.Config.arrowLeftMargin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(NewChatTimezoneView.Config.arrowSize)
            make.right.lessThanOrEqualTo(-NewChatTimezoneView.Config.rightPadding)
        }
        arrow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(arrowTapped)))
    }

    private func observeData() {
        self.chatNameObservable.distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (name) in
                self?.name = name
                if self?.isHidden == false {
                    self?.update()
                }
            }).disposed(by: self.disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func arrowTapped() {
        let dialog = UDDialog()
        let content = myTimezoneType == .hidden ? BundleI18n.LarkChat.Lark_IM_DisplayMyTimeZone_Hidden_Text :
            BundleI18n.LarkChat.Lark_IM_DisplayMyTimeZone_MobileText(self.myTimezone)
        dialog.setContent(text: content)
        dialog.addCancelButton()
        dialog.addPrimaryButton(text: BundleI18n.LarkChat.Lark_IM_DisplayMyTimeZone_GoToSettings_Button, dismissCompletion: { [weak self] in
            guard let self = self else { return }
            if let vc = self.targetVC {
                // 跳转到时区设置
                self.navigator.push(body: ShowTimeZoneWithOtherBody(), from: vc)
            }
        })
        if let vc = targetVC {
            self.navigator.present(dialog, from: vc)
        }
    }

    private func update() {
        updateTipContent(chatTimezoneDesc: "",
                         chatTimezone: self.chatTimezone,
                         myTimezone: self.myTimezone,
                         myTimezoneType: self.myTimezoneType,
                         preferredMaxLayoutWidth: self.preferredMaxLayoutWidth)
    }

    // chatTimezone: 对方的时区
    // myTimezone: 我的对外展示时区
    func updateTipContent(chatTimezoneDesc: String,
                          chatTimezone: String,
                          myTimezone: String,
                          myTimezoneType: ExternalDisplayTimezoneSettingType,
                          preferredMaxLayoutWidth: CGFloat) {
        guard !name.isEmpty, !chatTimezone.isEmpty else {
            Self.logger.info("panic: name or chatTimezone is empty")
            return
        }

        self.chatTimezone = chatTimezone
        self.myTimezone = myTimezone
        self.myTimezoneType = myTimezoneType
        self.preferredMaxLayoutWidth = preferredMaxLayoutWidth
        let desc = BundleI18n.LarkChat.Lark_Chat_LocalTime(chatTimezone, name)
        let descCount = desc.utf16.count
        let maxWidth = preferredMaxLayoutWidth -
            NewChatTimezoneView.Config.labelLeftPadding -
            NewChatTimezoneView.Config.arrowLeftMargin -
            NewChatTimezoneView.Config.arrowSize -
            NewChatTimezoneView.Config.rightPadding
        let descAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0),
                              NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption]
        let descAttr = NSMutableAttributedString(string: desc,
                                                 attributes: descAttributes)

        // 1. 处理timezone部分加粗
        let timezoneRange = (desc as NSString).range(of: chatTimezone)
        descAttr.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .medium)],
                               range: timezoneRange)

        // 2. 处理超长名字省略
        // 有三种情况：name在前、在中、在后
        // "在前"和"在中"是一种处理方式，"在后"是另一种处理方式
        let nameRange = (desc as NSString).range(of: name)
        let nameMax = nameRange.location + nameRange.length
        let isLastMode = nameMax == descCount
        let tipLabelOutOfRangeText: NSAttributedString
        if isLastMode {
            tipLabelOutOfRangeText = NSAttributedString(string: "...", attributes: descAttributes)
        } else {
            let tailTextRange = NSRange(location: nameMax, length: descCount - nameMax)
            // 兜底检测，locaiton和length异常可能导致crash
            if tailTextRange.location >= 0, tailTextRange.location + tailTextRange.length <= descCount {
                let tailText = (desc as NSString).substring(with: tailTextRange)
                let outOfRangeText = NSMutableAttributedString(string: "..." + tailText, attributes: descAttributes)
                // outOfRangeText可能包含timezone，需要处理加粗
                let timezoneRange = (outOfRangeText.string as NSString).range(of: chatTimezone)
                // 兜底检测，locaiton和length异常可能导致crash
                if timezoneRange.location >= 0, timezoneRange.location + timezoneRange.length <= outOfRangeText.string.utf16.count {
                    outOfRangeText.addAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14.0, weight: .medium)],
                                                 range: timezoneRange)
                } else {
                    Self.logger.info("panic: timezoneRange:\(tailTextRange) error, timezone:\(chatTimezone)")
                }
                tipLabelOutOfRangeText = outOfRangeText
            } else {
                Self.logger.info("panic: tailTextRange:\(tailTextRange) error")
                tipLabelOutOfRangeText = NSAttributedString(string: "...", attributes: descAttributes)
            }
        }

        // data bind to UI
        self.tipLabel.outOfRangeText = tipLabelOutOfRangeText
        self.tipLabel.preferredMaxLayoutWidth = maxWidth
        self.tipLabel.attributedText = descAttr
    }
}

final class TimeZoneImageView: ByteImageView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 四周热区扩大4
        let insets = UIEdgeInsets(top: -4, left: -4, bottom: -4, right: -4)
        if bounds.inset(by: insets).contains(point) {
            return self
        }
        return super.hitTest(point, with: event)
    }
}
