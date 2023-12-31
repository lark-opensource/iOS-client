//
//  PSTNOpenInviteViewController.swift
//  ByteView
//
//  Created by helijian on 2022/5/30.
//

import UIKit
import SnapKit
import LarkIllustrationResource
import ByteViewCommon
import ByteViewSetting

class PSTNOpenInviteViewController: BaseViewController {

    struct Layout {
        static let heightOfNav: CGFloat = 56
        static let leftAndRightInset: CGFloat = 16
        static let insertOfLabels: CGFloat = 20
        static let insertOfImageAndButton: CGFloat = 24
        static let insertOfLabelAndImage: CGFloat = 8
        static let buttnHeight: CGFloat = 48
    }

    private let containerView: UIView = {
        let view = UIView()
        return view
    }()

    private let meesageContainerView: UIView = {
        let view = UIView()
        return view
    }()

    private let openServiceLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.attributedText = .init(string: I18n.View_G_PhoneSystemSlogan, config: .h1)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private let detaildescLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.attributedText = .init(string: I18n.View_G_PhoneSystemExplain(), config: VCFontConfig(fontSize: 14, lineHeight: 22, fontWeight: .regular))
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    private lazy var moreInfoButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 6.0
        button.layer.masksToBounds = true
        button.setTitle(I18n.View_G_LearnMore_Button, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.setTitleColor(UIColor.ud.udtokenBtnPriTextDisabled, for: .disabled)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.primaryContentPressed, for: .highlighted)
        button.vc.setBackgroundColor(UIColor.ud.fillDisabled, for: .disabled)
        button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 0,
                                              left: 16,
                                              bottom: 0,
                                              right: 16)
        return button
    }()

    private let telephoneImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = LarkIllustrationResource.Resources.initializationFunctionTelephoneconference
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    let meeting: InMeetMeeting
    init(meeting: InMeetMeeting) {
        self.meeting = meeting
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarBgColor(.ud.bgFloat)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = I18n.View_M_InviteByPhone
        view.backgroundColor = UIColor.ud.bgFloat
        view.addSubview(containerView)
        containerView.addSubview(telephoneImageView)
        updateLayout()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        MeetingTracksV2.trackInviteAggClickClose(
            location: "tab_phone",
            fromCard: false
        )
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .allButUpsideDown
    }

    @objc func tapped(_ sender: Any) {
        guard let url = URL(string: meeting.setting.pstnInviteConfig.url) else { return }
        let router = meeting.router
        let larkRouter = meeting.larkRouter
        router.dismissTopMost(animated: false) {
            router.setWindowFloating(true)
            larkRouter.push(url, context: ["from": "byteView"], forcePush: true)
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if oldContext.layoutType != newContext.layoutType {
            updateLayout()
        }
    }

    private func updateLayout() {
        let naviHeight: CGFloat = self.currentLayoutContext.layoutType.isPhoneLandscape ? 32 : 56
        containerView.snp.remakeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.centerY.equalToSuperview().offset(-naviHeight/2)
            if self.currentLayoutContext.layoutType != .phoneLandscape {
                maker.left.right.equalToSuperview().inset(Display.phone ? 16 : 99)
            }
        }

        openServiceLabel.removeFromSuperview()
        detaildescLabel.removeFromSuperview()
        moreInfoButton.removeFromSuperview()
        meesageContainerView.removeFromSuperview()

        if self.currentLayoutContext.layoutType.isPhoneLandscape {
            telephoneImageView.snp.remakeConstraints {
                $0.left.equalToSuperview()
                $0.size.equalTo(CGSize(width: 232, height: 232))
                $0.centerY.equalToSuperview()
            }
            containerView.addSubview(meesageContainerView)
            meesageContainerView.snp.remakeConstraints {
                $0.right.equalToSuperview()
                $0.left.equalTo(telephoneImageView.snp.right).offset(48)
                $0.width.equalTo(300)
                $0.centerY.equalToSuperview()
            }
            meesageContainerView.addSubview(openServiceLabel)
            meesageContainerView.addSubview(detaildescLabel)
            meesageContainerView.addSubview(moreInfoButton)

            openServiceLabel.snp.remakeConstraints {
                $0.left.right.top.equalToSuperview()
            }

            detaildescLabel.snp.remakeConstraints {
                $0.left.right.equalToSuperview()
                $0.top.equalTo(openServiceLabel.snp.bottom).offset(16)
            }

            moreInfoButton.snp.remakeConstraints {
                $0.left.bottom.equalToSuperview()
                $0.right.lessThanOrEqualToSuperview()
                $0.top.equalTo(detaildescLabel.snp.bottom).offset(16)
                $0.height.equalTo(36)
            }
        } else {
            containerView.addSubview(openServiceLabel)
            containerView.addSubview(detaildescLabel)
            containerView.addSubview(moreInfoButton)

            openServiceLabel.snp.remakeConstraints { maker in
                maker.top.equalToSuperview()
                maker.left.right.equalToSuperview().inset(10)
            }
            detaildescLabel.snp.remakeConstraints { maker in
                maker.left.right.equalToSuperview().inset(10)
                maker.top.equalTo(openServiceLabel.snp.bottom).offset(Layout.insertOfLabels)
            }
            telephoneImageView.snp.remakeConstraints { maker in
                maker.top.equalTo(detaildescLabel.snp.bottom).offset(Layout.insertOfLabelAndImage)
                maker.size.equalTo(CGSize(width: 250, height: 250))
                maker.centerX.equalToSuperview()
            }
            moreInfoButton.snp.remakeConstraints { maker in
                maker.left.right.equalToSuperview()
                maker.top.equalTo(telephoneImageView.snp.bottom).offset(Layout.insertOfImageAndButton)
                maker.height.equalTo(Layout.buttnHeight)
                maker.bottom.equalToSuperview()
            }
        }
    }
}
