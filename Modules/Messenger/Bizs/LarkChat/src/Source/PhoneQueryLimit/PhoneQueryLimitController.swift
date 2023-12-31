//
//  PhoneQueryLimitController.swift
//  LarkMine
//
//  Created by 李勇 on 2019/4/28.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import LarkButton
import UniverseDesignToast
import UniverseDesignColor
import EENavigator
import LarkCore
import LarkAlertController
import LarkMessengerInterface
import LarkFeatureGating
import LarkFeatureSwitch

/// 手机查询限制界面
final class PhoneQueryLimitController: BaseUIViewController {
    private let viewModel: PhoneQueryLimitViewModel
    private let disposeBag = DisposeBag()
    /// 用来布局的
    private var lastView: UIView = .init()

    init(viewModel: PhoneQueryLimitViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.targetVc = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody
        self.isNavigationBarHidden = true

        // 创建导航栏
        addNavigationBar()
        // 创建限制内容
        addLimitView()
        // 创建各种限制下不同的视图
        if let queryQuotaStatus = QueryQuotaStatus(rawValue: self.viewModel.queryQuota.status) {
            // 限制拨打
            if queryQuotaStatus == .completeLimit {
                // 需要判断是否可以拨打语音电话
                Feature.on(.voip).apply(on: { [self] in
                    if viewModel.userResolver.fg.staticFeatureGatingValue(with: .init(key: .byteViewEncryptedCall)) {
                        // 紧急业务建议拨打
                        self.addRecommendView()
                        // 语音电话
                        self.addCallButton()
                    }
                }, off: {})

                // 了解管控详情
                addLimitDetailView()
            }
            // 达到单日上限
            if queryQuotaStatus == .todayLimit {
                // 立即申请查询次数
                addCallButton()
                // 了解管控详情
                addLimitDetailView()
            }
            // 还剩两次
            if queryQuotaStatus == .todayLaveTwo {
                // 拨打电话
                addCallButton()
                // 立即申请查询次数
                addApplyAmountBuutotn()
                // 了解管控详情
                addLimitDetailView()
            }
            // 第161次获取
            if queryQuotaStatus == .maxNumber {
                // 我知道了
                addCallButton()
                // 了解管控详情
                addLimitDetailView()
            }
        }
    }

    /// 申请额度
    private func alertApplyAmount() {
        let alertController = LarkAlertController()
        alertController.setTitle(text: BundleI18n.LarkChat.Lark_Legacy_ApplicationPhoneCallTimeCardTitle)
        alertController.setContent(text: BundleI18n.LarkChat.Lark_Legacy_ApplicationPhoneCallTimeWindow(self.viewModel.leaderName),
                                   alignment: .left)
        alertController.addSecondaryButton(text: BundleI18n.LarkChat.Lark_Legacy_ApplicationPhoneCallTimeWindowN)
        let navigator = viewModel.navigator
        alertController.addPrimaryButton(text: BundleI18n.LarkChat.Lark_Legacy_ApplicationPhoneCallTimeWindowY, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            self.viewModel.applyAmount().observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (chatId) in
                    guard let `self` = self else { return }
                    let body = ChatControllerByIdBody(chatId: chatId)
                    let topMost = WindowTopMostFrom(vc: self)
                    self.dismiss(animated: false, completion: {
                        navigator.push(body: body, from: topMost)
                    })
                }, onError: { [weak self] error in
                    if let view = self?.view {
                        UDToast.showFailure(
                            with: BundleI18n.LarkChat.Lark_Legacy_ApplicationPhoneCallTimeCardErrorToast,
                            on: view,
                            error: error
                        )
                    }
                }).disposed(by: self.disposeBag)
        })
        navigator.present(alertController, from: self)
    }

    /// 添加限制详情
    private func addLimitDetailView() {
        let bottomButton: MarkButton = MarkButton(type: .custom)
        bottomButton.clipsToBounds = true
        bottomButton.layer.cornerRadius = 4
        bottomButton.backgroundColor = UIColor.clear
        self.view.addSubview(bottomButton)
        bottomButton.snp.makeConstraints { (make) in
            make.bottom.equalTo(-36)
            make.centerX.equalToSuperview()
        }
        let titleLabel: UILabel = UILabel()
        titleLabel.textColor = UIColor.ud.textPlaceholder
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.text = BundleI18n.LarkChat.Lark_Legacy_PhoneCallManageDetail
        bottomButton.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
        }
        // 图片
        let imageView: UIImageView = UIImageView()
        imageView.image = Resources.detail_arrow_right_icon.ud.withTintColor(UIColor.ud.iconN3)
        bottomButton.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel.snp.right).offset(2)
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        bottomButton.addMarkView()

        // 跳转到管控详情界面
        bottomButton.rx.tap.subscribe(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.viewModel.jumpToDetail(from: self)
        }).disposed(by: self.disposeBag)
    }

    /// 添加立即申请按钮
    private func addApplyAmountBuutotn() {
        let applyButton: MarkButton = MarkButton(type: .custom)
        applyButton.clipsToBounds = true
        applyButton.layer.cornerRadius = 4
        applyButton.backgroundColor = UIColor.clear
        self.view.addSubview(applyButton)
        applyButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.lastView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
        }
        let label: UILabel = UILabel()
        label.text = BundleI18n.LarkChat.Lark_Legacy_ApplicationPhoneCallTimeTwoTimeApp
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.primaryContentDefault
        applyButton.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
        }
        let imageView: UIImageView = UIImageView()
        imageView.image = Resources.apply_arrow_right_icon
        applyButton.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.left.equalTo(label.snp.right).offset(4)
        }
        applyButton.addMarkView()

        // 添加点击事件
        applyButton.rx.tap.subscribe(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.alertApplyAmount()
        }).disposed(by: self.disposeBag)
    }

    /// 添加拨打电话按钮
    private func addCallButton() {
        guard let queryQuotaStatus = QueryQuotaStatus(rawValue: self.viewModel.queryQuota.status) else {
                return
        }

        // 因为这个按钮有图标，所以不能使用TypeButton，TypeButton没有处理图标的颜色变化
        let callButton: MarkButton = MarkButton(type: .custom)
        callButton.clipsToBounds = true
        callButton.layer.cornerRadius = 4
        callButton.backgroundColor = UIColor.ud.primaryContentDefault
        self.view.addSubview(callButton)
        callButton.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(48)
            make.top.equalTo(self.lastView.snp.bottom).offset(40)
        }
        func getTitleLabel(title: String) -> UILabel {
            let titleLabel: UILabel = UILabel()
            titleLabel.font = UIFont.systemFont(ofSize: 17)
            titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill
            titleLabel.text = title
            return titleLabel
        }

        switch queryQuotaStatus {
        // 限制拨号
        case .completeLimit:
            //  包装icon、title，让它们一起剧中显示
            let centerView: UIView = UIView()
            callButton.addSubview(centerView)
            centerView.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
            }
            let titleLabel: UILabel = getTitleLabel(title: BundleI18n.LarkChat.Lark_Legacy_PhoneCallManageVoIP)
            centerView.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.right.equalToSuperview()
                make.centerY.equalToSuperview()
            }
            let imageView: UIImageView = UIImageView()
            imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
            imageView.image = Resources.call_phone_icon
            centerView.addSubview(imageView)
            imageView.snp.makeConstraints { (make) in
                make.left.equalToSuperview()
                make.centerY.equalToSuperview()
                make.right.equalTo(titleLabel.snp.left).offset(-8)
            }
        // 达到单日上限
        case .todayLimit:
            let titleLabel: UILabel = getTitleLabel(title: BundleI18n.LarkChat.Lark_Legacy_ApplicationPhoneCallTimeTwoTimeApp)
            callButton.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
            }
        // 还剩两次
        case .todayLaveTwo:
            let titleLabel: UILabel = getTitleLabel(title: BundleI18n.LarkChat.Lark_Legacy_ApplicationPhoneCallTimeTwoTimeContinue)
            callButton.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
            }
        // 第161次获取
        case .maxNumber:
            let titleLabel: UILabel = getTitleLabel(title: BundleI18n.LarkChat.Lark_Legacy_ApplicationPhoneCallTimeButtonKnow)
            callButton.addSubview(titleLabel)
            titleLabel.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
            }
        default:
            break
        }
        callButton.addMarkView()

        // 添加点击事件
        switch queryQuotaStatus {
        // 限制拨号
        case .completeLimit:
            // 点击拨打语音电话
            callButton.rx.tap.subscribe(onNext: { [weak self] () in
                guard let `self` = self else { return }
                self.viewModel.callVoipPhone(on: self.view)
            }).disposed(by: self.disposeBag)
        // 达到单日上限
        case .todayLimit:
            // 申请额度
            callButton.rx.tap.subscribe(onNext: { [weak self] () in
                guard let `self` = self else { return }
                self.alertApplyAmount()
            }).disposed(by: self.disposeBag)
        // 还剩两次
        case .todayLaveTwo:
            // 拨打电话
            callButton.rx.tap.subscribe(onNext: { [weak self] () in
                guard let `self` = self else { return }
                self.viewModel.callPhone()
            }).disposed(by: self.disposeBag)
        // 第161次获取
        case .maxNumber:
            // 关闭此窗口
            callButton.rx.tap.subscribe(onNext: { [weak self] () in
                guard let `self` = self else { return }
                self.dismiss(animated: true, completion: nil)
            }).disposed(by: self.disposeBag)
        default:
            break
        }

        self.lastView = callButton
    }

    /// 创建紧急业务建议拨打
    private func addRecommendView() {
        let centerLabel: UILabel = UILabel()
        centerLabel.textColor = UIColor.ud.textTitle
        centerLabel.font = UIFont.systemFont(ofSize: 16)
        centerLabel.text = BundleI18n.LarkChat.Lark_Legacy_PhoneCallManageUrgentAdvice
        self.view.addSubview(centerLabel)
        centerLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.lastView.snp.bottom).offset(50)
            make.centerX.equalToSuperview()
        }

        // 两边的图标
        let icon = Resources.limit_call_near_icon
        let leftIcon: UIImageView = UIImageView()
        leftIcon.image = icon
        self.view.addSubview(leftIcon)
        leftIcon.snp.makeConstraints { (make) in
            make.right.equalTo(centerLabel.snp.left).offset(-6)
            make.centerY.equalTo(centerLabel)
        }
        let rightIcon: UIImageView = UIImageView()
        rightIcon.image = icon
        self.view.addSubview(rightIcon)
        rightIcon.snp.makeConstraints { (make) in
            make.left.equalTo(centerLabel.snp.right).offset(6)
            make.centerY.equalTo(centerLabel)
        }

        self.lastView = centerLabel
    }

    /// 创建限制内容
    private func addLimitView() {
        let currView: UIView = UIView()
        currView.backgroundColor = UIColor.ud.N100
        currView.layer.cornerRadius = 4
        currView.clipsToBounds = true
        self.view.addSubview(currView)
        currView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(self.lastView.snp.bottom).offset(20.5)
        }
        // 提示title
        let titleFont: UIFont = UIFont.boldSystemFont(ofSize: 16)
        let titleLabel: UILabel = UILabel()
        titleLabel.text = BundleI18n.LarkChat.Lark_Legacy_ApplicationPhoneCallTimePagSubTitle
        titleLabel.font = titleFont
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 0
        currView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(38)
            make.top.equalTo(19)
            make.right.lessThanOrEqualTo(-16)
        }
        // 图标 和title顶部对齐
        let iconTopOffset = (titleFont.lineHeight - titleFont.pointSize) / 2
        let iconImageView: UIImageView = UIImageView()
        iconImageView.image = Resources.limit_alert_icon.ud.withTintColor(UIColor.ud.functionWarningContentDefault)
        currView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(titleLabel.snp.top).offset(iconTopOffset)
        }
        let detailLabel: UILabel = UILabel()
        detailLabel.textColor = UIColor.ud.N700
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.text = self.viewModel.queryQuota.announcement
        detailLabel.numberOfLines = 0
        currView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(titleLabel.snp.bottom).offset(13)
            make.bottom.equalTo(-20)
        }

        self.lastView = currView
    }

    /// 创建导航栏
    private func addNavigationBar() {
        let naviBar = UIView()
        view.addSubview(naviBar)
        naviBar.snp.makeConstraints { (make) in
            make.top.equalTo(viewTopConstraint)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }
        // 关闭按钮
        let closeButton = UIButton(type: .custom)
        let closeIcon = Resources.navigation_close_light.ud.withTintColor(UIColor.ud.iconN1)
        closeButton.setImage(closeIcon, for: .normal)
        naviBar.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 24, height: 24))
            make.left.equalTo(12)
            make.centerY.equalToSuperview()
        }
        closeButton.rx.tap.subscribe(onNext: { [weak self] () in
            guard let `self` = self else { return }
            self.dismiss(animated: true, completion: nil)
        }).disposed(by: self.disposeBag)
        // 标题
        let titleLabel = UILabel()
        naviBar.addSubview(titleLabel)
        titleLabel.text = BundleI18n.LarkChat.Lark_Legacy_PhoneCallManageTitle
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        self.lastView = naviBar
    }
}

/// 自己做一个带点击效果的按钮，盖一层view
final class MarkButton: UIButton {
    private var topMarkView: UIView = UIView()

    func addMarkView() {
        self.topMarkView.backgroundColor = UIColor.clear
        self.topMarkView.isUserInteractionEnabled = false
        self.addSubview(self.topMarkView)
        self.topMarkView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.topMarkView.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.05)
            } else {
                self.topMarkView.backgroundColor = UIColor.clear
            }
        }
    }
}
