//
//  InMeetSystemCallingStatusView.swift
//  ByteView
//
//  Created by ShuaiZipei on 2022/11/7.
//

import ByteViewCommon
import Foundation
import UniverseDesignIcon
import ByteViewNetwork

class InMeetSystemCallingStatusView: UIView {
    private lazy var systemCallingStatusView: UIView = {
        let view = UIView()
        let viewColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)
        view.backgroundColor = viewColor
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var systemCallView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var systemIcon: UIImageView = {
        let image = UDIcon.getIconByKey(.callSystemFilled, iconColor: UIColor.ud.primaryOnPrimaryFill)
        let view = UIImageView(image: image)
        return view
    }()

    private lazy var systemCallingLabel: UILabel = {
        let callingLabel = UILabel()
        callingLabel.numberOfLines = 0
        callingLabel.lineBreakMode = .byWordWrapping
        callingLabel.text = I18n.View_G_ReceiveIncomingCall
        callingLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        callingLabel.textAlignment = .center
        callingLabel.isHidden = true
        return callingLabel
    }()

    // bool: 是否显示label
    var displayParams: InMeetSystemCallingStatusDisplayStyle = .systemCallingBigPhone {
        didSet {
            guard oldValue != displayParams else {
                return
            }
            updateUI()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // add views
        addSubview(systemCallingStatusView)
        systemCallingStatusView.addSubview(systemCallView)
        systemCallView.addSubview(systemIcon)
        systemCallView.addSubview(systemCallingLabel)

        // layout
        updateUI()
    }

    var userInfoStatus: ParticipantSettings.MobileCallingStatus = .unknown {
        didSet {
            guard self.userInfoStatus != oldValue else {
                return
            }
            updateUI()
        }
    }

    private func updateUI() {
        let style = displayParams
        var isShowLabel = true
        if style == .systemCallingSmallPhone || style == .systemCallingSinglePad {
            isShowLabel = false
        }
        systemCallingLabel.isHidden = !isShowLabel
        refreshAllConstraints(isShowLabel: isShowLabel)
    }

    private func refreshAllConstraints(isShowLabel: Bool) {
        let style = displayParams
        // defines
        let fontSize = style.params.fontSize
        let iconSideLength = style.params.iconSideLength
        let gap = style.params.gap
        let contentWidth = style.params.contentWidth
        let contentHeight = style.params.contentHeight

        // configs
        systemCallingLabel.font = UIFont.systemFont(ofSize: fontSize)
        if isShowLabel {
            systemCallingStatusView.snp.remakeConstraints {
                $0.size.equalToSuperview()
            }
            systemIcon.snp.remakeConstraints {
                $0.size.equalTo(CGSize(width: iconSideLength, height: iconSideLength))
                $0.top.equalToSuperview()
                $0.centerX.equalToSuperview()
            }
            systemCallingLabel.snp.remakeConstraints {
                $0.centerX.equalToSuperview()
                $0.left.right.equalTo(systemCallingStatusView)
                $0.top.equalTo(systemIcon.snp.bottom).offset(gap)
            }
            systemCallView.snp.remakeConstraints {
                $0.center.equalToSuperview()
                $0.size.equalTo(CGSize(width: contentWidth, height: contentHeight))
            }
        } else {
            systemCallingStatusView.snp.remakeConstraints {
                $0.size.equalToSuperview()
            }
            systemIcon.snp.remakeConstraints {
                $0.size.equalTo(CGSize(width: iconSideLength, height: iconSideLength))
                $0.center.equalToSuperview()
            }
            systemCallView.snp.remakeConstraints {
                $0.center.equalToSuperview()
                $0.size.equalTo(CGSize(width: contentWidth, height: contentHeight))
            }
        }
    }
}
