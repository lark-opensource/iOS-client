//
//  UrgentConfirmCollectionHeader.swift
//  LarkUrgent
//
//  Created by JackZhao on 2022/1/11.
//

import Foundation
import UIKit
import RustPB
import LarkMessengerInterface
import LarkFeatureGating
import SnapKit
import LKCommonsLogging

final class UrgentConfirmCollectionHeader: UIView {

    static let logger = Logger.log(UrgentConfirmCollectionHeader.self, category: "LarkUrgent.Confirm")

    private let enableTurnOffReadReceipt: Bool
    private var showReceiptHeader: Bool {
        Self.logger.info("showReceiptHeader: enableTurnOffReadReceipt: \(self.enableTurnOffReadReceipt); isP2P: \(self.isP2p)")
        return self.enableTurnOffReadReceipt && !self.isP2p
    }
    static var notifyBarHeight: CGFloat = 55

    // 单聊群聊需要区分样式
    public var isP2p: Bool

    var urgentTypeChanged: ((_ urgentType: RustPB.Basic_V1_Urgent.TypeEnum) -> Bool)? {
        didSet {
            self.notifySelectView.urgentTypeChanged = urgentTypeChanged
        }
    }

    // 加急是否通知选项发生改变
    var receiptSwitched: ((Bool) -> Void)? {
        didSet {
            if showReceiptHeader {
                self.readReceiptsSwitchView.receiptSwitched = receiptSwitched
            }
        }
    }

    var supportAllType: Bool = true {
        didSet {
            self.notifySelectView.supportAllType = supportAllType
        }
    }

    var modelService: ModelService!

    var headerHeight: CGFloat {
        var height: CGFloat = self.urgentViewHeight
        if showNotifyBar {
            height += Self.notifyBarHeight
        }
        if showReceiptHeader {
            self.readReceiptsSwitchView.layoutIfNeeded()
            height += self.readReceiptsSwitchView.bounds.size.height
        }
        Self.logger.info("Get UrgentConfirmCollectionHeader's headerHeight: \(height)")
        return height
    }

    private var urgentViewHeight: CGFloat = 0
    private var urgentView: UIView?
    var urgentConfirmMessage: UrgentConfirmMessageViewProtocol?

    private var showNotifyBar: Bool = false

    private var notifySelectView = UrgentSendNotifyTypeSelectView()

    private var readReceiptsSwitchView = UrgentReadReceiptsSwitchView()

    func set(messageView: UIView, heightOfView: CGFloat) {
        self.urgentView?.removeFromSuperview()
        self.urgentViewHeight = heightOfView
        self.urgentView = messageView
        self.addSubview(messageView)
        messageView.snp.makeConstraints({ (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(heightOfView)
        })
    }

    init(isP2p: Bool, enableTurnOffReadReceipt: Bool) {
        self.isP2p = isP2p
        self.enableTurnOffReadReceipt = enableTurnOffReadReceipt
        super.init(frame: .zero)
        self.initNotifyBar()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateNotifyBar(show: Bool) {
        self.showNotifyBar = show
        self.notifySelectView.isHidden = !show
        notifySelectView.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            if showReceiptHeader {
                make.bottom.equalTo(readReceiptsSwitchView.snp.top)
            } else {
                make.bottom.equalToSuperview()
            }
            make.height.equalTo(showNotifyBar ? Self.notifyBarHeight : 0)
        }
    }

    private func initNotifyBar() {
        if self.enableTurnOffReadReceipt && !self.isP2p {
            self.addSubview(readReceiptsSwitchView)
            readReceiptsSwitchView.receiptSwitched = self.receiptSwitched
            readReceiptsSwitchView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            self.addSubview(notifySelectView)
            notifySelectView.urgentTypeChanged = self.urgentTypeChanged
            notifySelectView.supportAllType = self.supportAllType
            notifySelectView.isHidden = true
            notifySelectView.snp.makeConstraints { (make) in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.bottom.equalTo(readReceiptsSwitchView.snp.top)
                make.height.equalTo(0)
            }
        } else {
            self.addSubview(notifySelectView)
            notifySelectView.urgentTypeChanged = self.urgentTypeChanged
            notifySelectView.supportAllType = self.supportAllType
            notifySelectView.isHidden = true
            notifySelectView.snp.makeConstraints { (make) in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(0)
            }
        }
    }

    //这里需要适配iPad屏幕旋转以及iPad应用分屏的情况下 label展示的内容不受影响
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let contentView = self.urgentView, contentView.bounds.size.width > 0 else {
            return
        }
        guard let urgentConfirmMessage = urgentConfirmMessage else {
            return
        }
        if urgentConfirmMessage.needUpdateRichLabelMaxLayoutWidth() {
            let width = self.bounds.size.width - urgentConfirmMessage.invalidSpaceWidth()
            urgentConfirmMessage.updateRichLabelMaxLayoutWidth(maxLayoutWidth: width)
        }
    }

}

final class LKSegmentedControl: UISegmentedControl {
    // For iOS13 and later
    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 4
    }
}

private final class UrgentSendNotifyTypeSelectView: UIView {
    var urgentTypeChanged: ((_ urgentType: RustPB.Basic_V1_Urgent.TypeEnum) -> Bool)?
    private var segmentControl: UISegmentedControl!
    private var borderView: UIView = {
        let view = UIView()
        view.layer.borderWidth = 1
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.clear
        return view
    }()
    private var lineView: UIView = UIView()

    var supportAllType: Bool = true {
        didSet {
            self.updateSegmentControl()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        let label = UILabel()
        label.text = BundleI18n.LarkUrgent.Lark_Legacy_DingStyleLabel
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(15)
        }

        let segmentControl = LKSegmentedControl(
            items: [
                BundleI18n.LarkUrgent.Lark_IM_Buzz_BuzzType_InApp(),
                BundleI18n.LarkUrgent.Lark_IM_Buzz_BuzzType_InAppPlusSMS(),
                BundleI18n.LarkUrgent.Lark_IM_Buzz_BuzzType_InAppPlusPhone()
            ]
        )
        segmentControl.selectedSegmentIndex = 0
        segmentControl.setDividerImage(UIImage.ud.fromPureColor(UIColor.ud.lineDividerDefault), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
        segmentControl.setBackgroundImage(self.genImage(color: UIColor.ud.colorfulBlue), for: .selected, barMetrics: .default)
        segmentControl.setBackgroundImage(self.genImage(color: UIColor.clear), for: .normal, barMetrics: .default)
        segmentControl.layer.masksToBounds = true

        self.addSubview(segmentControl)
        segmentControl.addTarget(self, action: #selector(handleValueChange(segment:)), for: .valueChanged)
        segmentControl.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(209.5)
            make.left.greaterThanOrEqualTo(label.snp.right)
            make.height.equalTo(30)
            make.right.equalToSuperview().offset(-15)
        }
        self.segmentControl = segmentControl

        self.addSubview(self.borderView)
        borderView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(segmentControl)
        }
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        self.addSubview(lineView)
        lineView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        self.updateSegmentControl()
    }

    typealias SelectInfo = (type: RustPB.Basic_V1_Urgent.TypeEnum, index: Int)
    private var originSelectInfo: SelectInfo = (.app, 0)

    @objc
    private func handleValueChange(segment: UISegmentedControl) {
        let agentType: RustPB.Basic_V1_Urgent.TypeEnum
        switch segment.selectedSegmentIndex {
        case 1:
            agentType = .sms
        case 2:
            agentType = .phone
        default:
            agentType = .app
        }
        if agentType != self.originSelectInfo.type {
            if self.urgentTypeChanged?(agentType) ?? true {
                self.originSelectInfo = (agentType, segment.selectedSegmentIndex)
            } else {
                segment.selectedSegmentIndex = self.originSelectInfo.index
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateSegmentControl() {
        segmentControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.ud.primaryOnPrimaryFill
        ], for: .selected)

        segmentControl.setTitleTextAttributes([
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.ud.primaryOnPrimaryFill
        ], for: .highlighted)

        if self.supportAllType {
            segmentControl.tintColor = UIColor.ud.colorfulBlue
            segmentControl.setTitleTextAttributes([
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.ud.colorfulBlue
            ], for: .normal)

            borderView.layer.borderColor = UIColor.ud.colorfulBlue.cgColor
        } else {
            segmentControl.tintColor = UIColor.ud.N400
            segmentControl.setTitleTextAttributes([
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.ud.N400
            ], for: .normal)

            borderView.layer.borderColor = UIColor.ud.N400.cgColor
        }
    }

    private func genImage(color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

private final class UrgentReadReceiptsSwitchView: UIView {
    private var titleLabel = UILabel()
    private var subTitleLabel = UILabel()
    fileprivate var receiptSwitched: ((Bool) -> Void)?

    private lazy var switchBtn: UISwitch = {
        let btn = UISwitch()
        btn.onTintColor = UIColor.ud.primaryContentDefault
        btn.isOn = true
        return btn
    }()
    private var lineView: UIView = UIView()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        self.addSubview(lineView)
        lineView.backgroundColor = UIColor.ud.lineDividerDefault
        lineView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        setSwitchLayout()
        setTitleLayout()
    }

    private func setTitleLayout() {
        self.addSubview(titleLabel)
        self.addSubview(subTitleLabel)

        titleLabel.text = BundleI18n.LarkUrgent.Lark_IM_Buzz_ReadReceipts_Mobile
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.font = UIFont.systemFont(ofSize: 16)

        subTitleLabel.text = BundleI18n.LarkUrgent.Lark_IM_Buzz_ReadReceipts_Desc_Mobile
        subTitleLabel.textColor = UIColor.ud.textPlaceholder
        subTitleLabel.numberOfLines = 2
        subTitleLabel.lineBreakMode = .byTruncatingTail
        subTitleLabel.font = UIFont.systemFont(ofSize: 14)

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(22)
        }
        // 抗压缩优先级设置为比switchBtn低，避免subTitleLabel过宽把switchBtn挤的很窄
        subTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.left)
            make.top.equalTo(titleLabel.snp.bottom)
            make.height.greaterThanOrEqualTo(20)
            make.bottom.equalToSuperview().offset(-12)
            make.right.equalTo(switchBtn.snp.left).offset(-16)
        }
    }

    private func setSwitchLayout() {
        self.addSubview(switchBtn)
        switchBtn.addTarget(self, action: #selector(switchBtnDidTap), for: .valueChanged)
        // 抗压缩优先级设置为比subTitleLabel高，避免subTitleLabel过宽把switchBtn挤的很窄
        switchBtn.setContentCompressionResistancePriority(.defaultLow + 1, for: .horizontal)
        switchBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }

    @objc
    private func switchBtnDidTap() {
        self.receiptSwitched?(switchBtn.isOn)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
