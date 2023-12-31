//
//  PreviewFooterView.swift
//  ByteView
//
//  Created by kiri on 2022/5/20.
//

import Foundation
import UIKit
import ByteViewMeeting
import ByteViewSetting
import SnapKit
import UniverseDesignColor
import ByteViewUI

/// 底部区域，device | commit | replaceJoin
final class PreviewFooterView: PreviewChildView {
    struct Layout {
        static let deviceHeight: CGFloat = 56
        static let commitBtnHeight: CGFloat = 48
        static let verticalPadding: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let commitBottomPadding: CGFloat = Display.iPhoneXSeries ? 8 : 16

        struct Phone {
            static let replaceJoinLeftPadding: CGFloat = 16
            static let replaceJoinTopPadding: CGFloat = 16
            static let replaceJoinBottomPadding: CGFloat = Display.iPhoneXSeries ? 0 : 16
        }

        struct Pad {
            static let replaceJoinTopBottomPadding: CGFloat = VCScene.isLandscape ? 24 : 32
        }
    }
    let deviceView: PreviewDeviceView
    let isJoinMeeting: Bool
    let isPrelobby: Bool

    private var commitBtnBottomCst: Constraint?
    var updateLayoutClosure: (() -> Void)?

    /// commitBtn上方显示deviceBtn及callMeTip所需最小高度
    var deviceMinHeight: CGFloat {
        var height = Layout.verticalPadding + Layout.deviceHeight
        if callMeTip.isHidden {
            height += 24 // 24是deviceBtn的bottom padding
        } else {
            // callMeTip's magic number
            // 12:callMeTip top padding，28:callMeTip的高度，12:callMeTip bottom padding
            height += (12 + 18 + 12)
        }
        return height
    }

    private(set) lazy var callMeTip: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = .ud.textCaption
        label.font = .systemFont(ofSize: 12)
        label.isHidden = true
        return label
    }()

    private(set) lazy var commitBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.accessibilityIdentifier = "PreviewFooterView.commitBtn.accessibilityIdentifier"
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.setTitleColor(UIColor.ud.functionSuccessOnSuccessFill, for: .normal)
        button.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .disabled)
        button.vc.setBackgroundColor(isJoinMeeting ? UIColor.ud.functionSuccessFillDefault : .ud.primaryFillDefault, for: .normal)
        button.vc.setBackgroundColor(isJoinMeeting ? UIColor.ud.functionSuccessFillPressed : .ud.primaryFillPressed, for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.fillDisabled, for: .disabled)
        button.addInteraction(type: .lift)
        button.contentEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return button
    }()

    private lazy var loading = LoadingView(frame: CGRect(x: 0, y: 0, width: 20, height: 20), style: .white)

    private lazy var deviceContainerView: UIView = {
        let view = UIView()
        view.addSubview(deviceView)
        deviceView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        return view
    }()

    private let contentView = UIView()

    private lazy var visualEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.accessibilityLabel = "visualEffectView"
        effectView.isHidden = true
        return effectView
    }()

    lazy var replaceJoinView: PreviewReplaceJoinView = {
        let view = PreviewReplaceJoinView()
        view.isHidden = true
        return view
    }()

    var isBlurHidden: Bool {
        get { visualEffectView.isHidden }
        set {
            guard Display.phone else { return }
            visualEffectView.isHidden = newValue
            contentView.backgroundColor = newValue ? .clear : UIColor.ud.bgBody.withAlphaComponent(0.94)
            commitBtnBottomCst?.update(offset: newValue ? 0 : -16)
        }
    }

    // commitButton + replaceJoinButton
    var phoneBottomHeight: CGFloat {
        var height = Layout.commitBtnHeight
        if replaceJoinView.isHidden {
            height += Layout.commitBottomPadding
        } else {
            height += Layout.Phone.replaceJoinTopPadding
            height += replaceJoinView.actualPhoneHeight
            height += Layout.Phone.replaceJoinBottomPadding
        }
        return height
    }

    init(deviceView: PreviewDeviceView, isJoinMeeting: Bool, isPrelobby: Bool = false) {
        // webinar 观众 隐藏麦克风/摄像头时，屏蔽其他入会方式
        self.isJoinMeeting = isJoinMeeting
        self.deviceView = deviceView
        self.isPrelobby = isPrelobby
        super.init(frame: .zero)
        addSubview(visualEffectView)
        addSubview(contentView)
        contentView.addSubview(deviceContainerView)
        contentView.addSubview(callMeTip)
        contentView.addSubview(commitBtn)
        contentView.addSubview(replaceJoinView)

        visualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        updateLayout(isRegular: VCScene.isRegular)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        vc.updateKeyboardLayout()
        updateLayoutClosure?()
    }

    private static let clearImage: UIImage = {
        let rect = CGRect(origin: .zero, size: CGSize(width: 24, height: 20))
        let render = UIGraphicsImageRenderer(bounds: rect)
        let resultImage = render.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(UIColor.clear.cgColor)
            cgContext.fill(rect)
        }
        return resultImage
    }()

    func showLoading(_ isLoading: Bool, isFailed: Bool = false) {
        commitBtn.isEnabled = false
        let bgColor: UIColor = isJoinMeeting ? .ud.functionSuccessFillLoading : .ud.primaryFillLoading
        if isLoading {
            commitBtn.vc.setBackgroundColor(bgColor, for: .disabled)
            commitBtn.addSubview(loading)
            commitBtn.setImage(Self.clearImage, for: .disabled)
            if let imageView = commitBtn.imageView {
                loading.snp.remakeConstraints { make in
                    make.centerY.left.equalTo(imageView)
                    make.size.equalTo(20)
                }
            }
            loading.play()
        } else {
            commitBtn.vc.setBackgroundColor(isFailed ? UIColor.ud.fillDisabled : bgColor, for: .disabled)
            if isFailed {
                commitBtn.setImage(nil, for: .disabled)
                loading.stop()
                loading.removeFromSuperview()
            }
        }
    }

    override func updateLayout(isRegular: Bool) {
        deviceView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        deviceView.isHorizontalStyle = isRegular && VCScene.isLandscape
        deviceView.updateLayout()
        replaceJoinView.updateLayout(isRegular: isRegular)

        if Display.phone {
            updatePhoneLayout()
        } else if isRegular {
            updateRegularLayout()
        } else {
            updateCompactLayout()
        }
    }

    private func updatePhoneLayout() {
        deviceContainerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(Layout.verticalPadding)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
            make.height.equalTo(Layout.deviceHeight)
            make.bottom.lessThanOrEqualTo(commitBtn.snp.top).offset(-Layout.verticalPadding)
            if !callMeTip.isHidden {
                make.bottom.lessThanOrEqualTo(callMeTip.snp.top).offset(-12)
            }
        }

        commitBtn.snp.remakeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
            make.height.equalTo(Layout.commitBtnHeight)
            if replaceJoinView.isHidden {
                make.bottom.equalToSuperview().inset(Layout.commitBottomPadding).priority(.high)
            }
            commitBtnBottomCst = make.bottom.lessThanOrEqualTo(vc.keyboardLayoutGuide.snp.top).offset(0).constraint
        }

        replaceJoinView.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(Layout.Phone.replaceJoinLeftPadding)
            make.top.equalTo(commitBtn.snp.bottom).offset(Layout.Phone.replaceJoinTopPadding).priority(.high)
            make.bottom.equalToSuperview().inset(Layout.Phone.replaceJoinBottomPadding)
        }
    }

    private func updateRegularLayout() {
        if VCScene.isLandscape {
            deviceContainerView.snp.remakeConstraints { make in
                make.top.left.bottom.equalToSuperview()
                make.right.lessThanOrEqualTo(commitBtn.snp.left).offset(-12)
            }
            commitBtn.snp.remakeConstraints { make in
                make.top.right.bottom.equalToSuperview()
                make.width.greaterThanOrEqualTo(136)
            }
        } else {
            deviceContainerView.snp.remakeConstraints { make in
                make.top.left.right.equalToSuperview()
                make.height.equalTo(Layout.deviceHeight)
            }
            commitBtn.snp.remakeConstraints { make in
                make.top.equalTo(deviceContainerView.snp.bottom).offset(30)
                make.left.right.equalToSuperview()
                make.height.equalTo(Layout.commitBtnHeight)
            }
        }
    }

    private func updateCompactLayout() {
        deviceContainerView.snp.remakeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(Layout.deviceHeight)
        }
        commitBtn.snp.remakeConstraints { make in
            make.top.equalTo(deviceContainerView.snp.bottom).offset(30)
            make.left.right.equalToSuperview()
            make.height.equalTo(Layout.commitBtnHeight)
        }
    }

    func updateCallMeTip(_ text: String = "") {
        guard Display.phone else { return }
        callMeTip.text = text
        if text.isEmpty {
            callMeTip.isHidden = true
            deviceContainerView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(Layout.verticalPadding)
                make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
                make.height.equalTo(Layout.deviceHeight)
                make.bottom.lessThanOrEqualTo(commitBtn.snp.top).offset(-Layout.verticalPadding)
            }
        } else {
            callMeTip.isHidden = false
            deviceContainerView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(Layout.verticalPadding)
                make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
                make.height.equalTo(Layout.deviceHeight)
                make.bottom.lessThanOrEqualTo(commitBtn.snp.top).offset(-16)
                make.bottom.lessThanOrEqualTo(callMeTip.snp.top).offset(-12)
            }
            callMeTip.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.lessThanOrEqualToSuperview().inset(16)
                make.height.equalTo(18)
                make.bottom.equalTo(commitBtn.snp.top).offset(-12)
            }
        }
        updateLayoutClosure?()
    }

    func updateReplaceJoinLayout(with containerView: UIView) {
        guard Display.pad else { return }
        replaceJoinView.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.bottom.equalTo(containerView.safeAreaLayoutGuide).inset(Layout.Pad.replaceJoinTopBottomPadding)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let subPoint = convert(point, to: replaceJoinView)
        if replaceJoinView.bounds.contains(subPoint) {
            return replaceJoinView.hitTest(subPoint, with: event)
        }
        return super.hitTest(point, with: event)
    }
}
