//
//  DeviceStatusTableCell.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/12.
//

import UIKit
import LarkUIKit
import UniverseDesignColor
import SnapKit
import UniverseDesignButton
import UniverseDesignIcon
import LarkSensitivityControl
import LarkSecurityComplianceInfra

protocol DeviceStatusViewDelegate: AnyObject {
    func didTapApplyEntryButton(_ from: UIButton)
    func didTapRefreshButton(_ from: UIButton)
}

final class DeviceStatusView: UIView {
    
    var deviceStatusViewDidUpdate: ((CGFloat) -> Void)?

    var model: DeviceStatusCellModel? {
        didSet {
            guard let aModel = model else { return }
            let status = aModel.deviceInfo?.applyStatus ?? .unknown
            refreshButton.isHidden = status != .processing
            let ownership = model?.deviceInfo?.ownership ?? .unknown
            let title: String = {
                switch ownership {
                case .unknown:
                    return  I18N.Lark_Conditions_UnknownUnknown
                case .company:
                    return I18N.Lark_Conditions_OrgData
                case .personal:
                    return I18N.Lark_Conditions_Person
                }
            }()
            updateDeviceBelongingLabelIfNeeded(text: I18N.Lark_Conditions_DeviceBelonging + title)
            switch status {
            case .reject, .noApply:
                applyButton.setTitle(I18N.Lark_Conditions_Apply, for: .normal)
                applyButton.isHidden = !(aModel.checkResult?.isOpen).isTrue
            default:
                applyButton.setTitle(nil, for: .normal)
                applyButton.isHidden = true
            }
            statusView.status = status

            updateRejectReasonLabel(text: aModel.deviceInfo?.rejectReason, 
                                    shouldShow: aModel.isRejectReasonEnabled && status == .reject)
            updateActionContainer(shouldShow: !refreshButton.isHidden || !applyButton.isHidden)
            superview?.setNeedsLayout()
            superview?.layoutIfNeeded()
            deviceStatusViewDidUpdate?(scrollView.contentSize.height)
        }
    }
    
    private func updateActionContainer(shouldShow: Bool) {
        actionContainer.isHidden = !shouldShow
        container.layer.maskedCorners = shouldShow ? [.layerMinXMinYCorner, .layerMaxXMinYCorner] :
                [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
        actionContainer.snp.updateConstraints { make in
            make.height.equalTo(shouldShow ? 38 : 0)
        }
    }
    
    private func updateRejectReasonLabel(text: String?, shouldShow: Bool) {
        guard shouldShow else {
            rejectReasonLabel.isHidden = true
            deviceBelongingLabel.snp.remakeConstraints { make in
                make.left.equalTo(titleLabel)
                make.top.equalTo(systemLabel.snp.bottom).offset(4)
                make.right.lessThanOrEqualTo(-16)
                make.height.greaterThanOrEqualTo(20)
                make.bottom.equalToSuperview().offset(-12)
            }
            return
        }
        rejectReasonLabel.isHidden = false
        // 调整文案
        if let reason = validateText(text), !reason.isEmpty {
            rejectReasonLabel.text = I18N.Lark_SelfDeclareDevice_Title_ReasonforRejection + reason
        } else {
            rejectReasonLabel.text = I18N.Lark_SelfDeclareDevice_Title_ReasonforRejection + "-"
        }
        
        deviceBelongingLabel.snp.remakeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(systemLabel.snp.bottom).offset(4)
            make.right.lessThanOrEqualTo(-16)
            make.height.greaterThanOrEqualTo(20)
        }
    
        rejectReasonLabel.snp.remakeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(deviceBelongingLabel.snp.bottom).offset(4)
            make.right.lessThanOrEqualTo(-16)
            make.height.greaterThanOrEqualTo(20)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
    
    // replace multiple newlines to one
    private func validateText(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        guard let re = try? NSRegularExpression(pattern: "\\n+", options: []) else { return text }
        return re.stringByReplacingMatches(in: trimmed, range: NSRange(location: 0, length: trimmed.count), withTemplate: "\n")
    }
    
    private func updateDeviceBelongingLabelIfNeeded(text: String) {
        let attrStr = NSMutableAttributedString(string: text)
        if let range = text.range(of: ":") ?? text.range(of: "：") {
            let nsRange = NSRange(range, in: text)
            attrStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: NSParagraphStyle.default, range: nsRange)
        }
        deviceBelongingLabel.attributedText = attrStr
    }

    weak var delegate: DeviceStatusViewDelegate?
    
    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsVerticalScrollIndicator = false
        view.showsHorizontalScrollIndicator = false
        view.backgroundColor = UIColor.clear
        view.contentSize.width = 0
        view.alwaysBounceHorizontal = false
        view.contentInset = .zero
        if #available(iOS 13.0, *) {
            view.automaticallyAdjustsScrollIndicatorInsets = false
        }
        view.contentInsetAdjustmentBehavior = .never
        return view
    }()

    private let container: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.cornerRadius = 10
        return view
    }()
    
    private let actionContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.cornerRadius = 10
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        view.clipsToBounds = true
        return view
    }()

    private let iconView: UIImageView = {
       let view = UIImageView()
        view.image = UDIcon.getIconByKey(.cellphoneOutlined, iconColor: UIColor.ud.textTitle)
        return view
    }()

    private let titleLabel: UILabel = {
       let label = UILabel()
        do {
            let token = Token("LARK-PSDA-enter_deviceStatus_page_request_deviceName")
            label.text = try DeviceInfoEntry.getDeviceName(forToken: token, device: UIDevice.current)
        } catch {
            label.text = UIDevice.current.lu.modelName()
            Logger.error(error.localizedDescription)
        }
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 17)
        return label
    }()

    private let systemLabel: UILabel = {
        let label = UILabel()
        label.text = I18N.Lark_Conditions_System + " iOS " + UIDevice.current.systemVersion
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    private let deviceBelongingLabel: UILabel = {
        let label = UILabel()
        label.text = I18N.Lark_Conditions_DeviceBelonging + I18N.Lark_Conditions_UnknownUnknown
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()
    
    private let rejectReasonLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    let applyButton: UIButton = {
        let button = UDButton(UDButtonUIConifg.textBlue)
        button.setTitle(I18N.Lark_Conditions_Apply, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        button.contentEdgeInsets = UIEdgeInsets(top: 1, left: 10, bottom: 1, right: 10)
        button.backgroundColor = UIColor.ud.bgBody
        button.isHidden = true
        return button
    }()

    let refreshButton: UIButton = {
        let button = UDButton(UDButtonUIConifg.textBlue)
        button.setTitle(I18N.Lark_Conditions_Refresh, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        button.backgroundColor = UIColor.ud.bgBody
        button.contentEdgeInsets = UIEdgeInsets(top: 1, left: 10, bottom: 1, right: 10)
        button.isHidden = true
        return button
    }()

    private let statusView = StatusView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        applyButton.addTarget(self, action: #selector(applyButtonDidClicked), for: .touchUpInside)
        refreshButton.addTarget(self, action: #selector(refreshButtonDidClicked), for: .touchUpInside)

        addSubview(scrollView)
        scrollView.addSubview(container)
        scrollView.addSubview(actionContainer)
        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(statusView)
        container.addSubview(systemLabel)
        container.addSubview(deviceBelongingLabel)
        container.addSubview(rejectReasonLabel)
        actionContainer.addSubview(applyButton)
        actionContainer.addSubview(refreshButton)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        container.snp.makeConstraints { make in
            make.width.equalToSuperview().offset(-32)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.height.greaterThanOrEqualTo(102)
        }
        
        iconView.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.left.equalTo(16)
            make.size.equalTo(20)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(4)
            make.centerY.equalTo(iconView)
            make.right.lessThanOrEqualTo(-16)
            make.height.greaterThanOrEqualTo(24)
        }
        
        statusView.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.equalTo(titleLabel.snp.right).offset(8)
            make.centerY.equalTo(titleLabel)
        }
        
        systemLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.right.lessThanOrEqualTo(-16)
            make.height.greaterThanOrEqualTo(20)
        }
        
        deviceBelongingLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.top.equalTo(systemLabel.snp.bottom).offset(4)
            make.right.lessThanOrEqualTo(-16)
            make.height.greaterThanOrEqualTo(20)
        }
        
        actionContainer.snp.makeConstraints { make in
            make.width.centerX.equalTo(container)
            make.top.equalTo(container.snp.bottom).offset(1)
            make.height.equalTo(0)
            make.bottom.equalToSuperview()
        }
        
        applyButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        refreshButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        return nil
    }

    @objc
    private func applyButtonDidClicked() {
        Logger.info("apply button clicked")
        delegate?.didTapApplyEntryButton(applyButton)
    }

    @objc
    private func refreshButtonDidClicked() {
        Logger.info("refresh button clicked")
        delegate?.didTapRefreshButton(refreshButton)
    }
}

private final class StatusView: UIButton {

    var status: DeviceApplyStatus = .noApply {
        didSet {
            setTitle(getCurrentTitle(), for: .disabled)
            setTitleColor(getTitleColor(), for: .disabled)
            backgroundColor = getBackgroundColor()
        }
    }

    init() {
        super.init(frame: .zero)
        isEnabled = false
        layer.cornerRadius = 4
        contentEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .regular)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    func getCurrentTitle() -> String {
        switch status {
        case .noApply:
            return I18N.Lark_Conditions_StatusOfThis
        case .reject:
            return I18N.Lark_Conditions_FailedFailed
        case .pass:
            return I18N.Lark_Conditions_OngoingHere
        case .processing:
            return I18N.Lark_Conditions_NotYet
        default:
            return I18N.Lark_Conditions_StatusOfThis
        }
    }

    func getBackgroundColor() -> UIColor {
        switch status {
        case .noApply:
            return UIColor.ud.udtokenTagNeutralBgNormal
        case .reject:
            return UIColor.ud.udtokenTagBgRed
        case .pass:
            return UIColor.ud.udtokenTagBgGreen
        case .processing:
            return UIColor.ud.udtokenTagBgPurple
        default:
            return UIColor.ud.udtokenTagNeutralBgNormal
        }
    }

    func getTitleColor() -> UIColor {
        switch status {
        case .noApply:
            return UIColor.ud.udtokenTagNeutralTextNormal
        case .reject:
            return UIColor.ud.udtokenTagTextSRed
        case .pass:
            return UIColor.ud.udtokenTagTextSGreen
        case .processing:
            return UIColor.ud.udtokenTagTextSPurple
        default:
            return UIColor.ud.udtokenTagNeutralTextNormal
        }
    }
}
