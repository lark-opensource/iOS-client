//
// Created by liujianlong on 2022/9/2.
//

import UIKit
import RxSwift
import ByteViewUI

// Pad 宫格视图模式下，需要在 Cell 中显示共享内容
class InMeetGalleryShareContentCell: UICollectionViewCell {
    private(set) var shareContentVC: UIViewController?
    let userInfoView = InMeetUserInfoView()
    private(set) var disposeBag = DisposeBag()

    private lazy var moreSelectionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(InMeetingParticipantView.moreSelectionNormalImg, for: .normal)
        button.setImage(InMeetingParticipantView.moreSelectionHighlightImg, for: .highlighted)
        button.layer.ud.setShadowColor(UIColor.ud.staticBlack.withAlphaComponent(0.5))
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 0.5
        button.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        button.addTarget(self, action: #selector(didTapMoreButton(sender:)), for: .touchUpInside)
        return button
    }()

    required init?(coder: NSCoder) {
        return nil
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        guard let attr = layoutAttributes as? InMeetingCollectionViewLayoutAttributes else {
            return
        }
        self.styleConfig = attr.styleConfig
    }

    var doubleTapAction: ((BackToShareLocation) -> Void)?
    var changeOrderEnabled: (() -> Bool)?
    var changeOrderAction: (() -> Void)?
    weak var fullScreenDetector: InMeetFullScreenDetector?

    @objc
    func handleSingleTap() {
        fullScreenDetector?.postSwitchFullScreenEvent()
    }

    @objc
    func handleDoubleTap() {
        doubleTapAction?(.doubleClickSharing)
    }

    var styleConfig: ParticipantViewStyleConfig? {
        didSet {
            if styleConfig?.topBarInset != oldValue?.topBarInset || styleConfig?.isSingleRow != oldValue?.isSingleRow {
                updateMoreSelectionButtonConstraints()
            }

            if styleConfig?.bottomBarInset != oldValue?.bottomBarInset {
                updateUserInfoViewConstraints()
            }

            if styleConfig?.meetingLayoutStyle != oldValue?.meetingLayoutStyle {
                userInfoView.alpha = (styleConfig?.meetingLayoutStyle ?? .tiled) == .fullscreen ? 0.8 : 1.0
            }

            moreSelectionButton.isHidden = styleConfig?.meetingLayoutStyle == .fullscreen
        }
    }

    var displayText: String {
        get {
            self.userInfoView.userInfoStatus.name
        }
        set {
            var userInfo = self.userInfoView.userInfoStatus
            userInfo.name = newValue
            self.userInfoView.userInfoStatus = userInfo
        }
    }

    private func setupSubviews() {
        self.contentView.layer.cornerRadius = 8.0
        self.contentView.clipsToBounds = true
        let doubleTapGesture = UIShortTapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        self.contentView.addGestureRecognizer(doubleTapGesture)
        let singleTapGesture = UIFullScreenGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTapGesture.numberOfTapsRequired = 1
        contentView.addGestureRecognizer(singleTapGesture)
        singleTapGesture.require(toFail: doubleTapGesture)


        var params = InMeetUserInfoView.UserInfoDisplayStyle.inMeetingGrid
        params.components = .nameAndMic
        self.userInfoView.displayParams = params
        self.userInfoView.userInfoStatus = ParticipantUserInfoStatus(hasRoleTag: false,
                                                                     meetingRole: .participant,
                                                                     isSharing: false,
                                                                     isFocusing: false,
                                                                     isMute: false,
                                                                     isLarkGuest: false,
                                                                     name: "",
                                                                     isRinging: false,
                                                                     isMe: false,
//                                                                     showNameAndMicOnly: true,
                                                                     rtcNetworkStatus: nil,
                                                                     audioMode: .unknown,
                                                                     is1v1: false,
                                                                     meetingSource: nil,
                                                                     isRoomConnected: false,
                                                                     isLocalRecord: false)
        self.contentView.addSubview(userInfoView)
        self.contentView.addSubview(moreSelectionButton)

        updateMoreSelectionButtonConstraints()
        updateUserInfoViewConstraints()
    }

    private func updateMoreSelectionButtonConstraints() {
        self.moreSelectionButton.snp.remakeConstraints { make in
            let isSingleRow = styleConfig?.isSingleRow ?? false
            make.right.equalToSuperview().offset(isSingleRow ? -10 : -14)
            make.size.equalTo(CGSize(width: 24.0, height: 24.0))
            let topBarInset = styleConfig?.topBarInset ?? 0
            let topInset = isSingleRow ? 6.0 : topBarInset + 10.0
            make.top.equalToSuperview().offset(topInset).priority(.high)
        }
    }

    private func updateUserInfoViewConstraints() {
        self.userInfoView.snp.remakeConstraints { make in
            make.bottom.left.equalToSuperview().inset(2)
            make.right.lessThanOrEqualToSuperview().inset(2)
            let bottomBarInset = styleConfig?.bottomBarInset ?? 0
            make.bottom.lessThanOrEqualToSuperview().offset(-bottomBarInset - 2)
        }
    }

    func setShareContentVC(_ vc: UIViewController?) {
        guard vc !== self.shareContentVC else {
            return
        }
        self.cleanShareContentVC()
        if let vc = vc {
            self.contentView.insertSubview(vc.view, belowSubview: self.userInfoView)
            self.shareContentVC = vc
            vc.view.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
    }

    private func cleanShareContentVC() {
        guard let vc = self.shareContentVC else {
            return
        }
        vc.view.removeFromSuperview()
        self.shareContentVC = nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag()
        cleanShareContentVC()
    }
}

extension InMeetGalleryShareContentCell {
   @objc func didTapMoreButton(sender: UIButton) {
       let appearance = ActionSheetAppearance(style: .pan,
                                              backgroundColor: UIColor.clear,
                                              separatorColor: UIColor.clear,
                                              customTextHeight: 50,
                                              showBarView: true,
                                              tableViewCornerRadius: 0,
                                              tableViewScrollable: true)
       let actionSheet = ActionSheetController(title: "", appearance: appearance)
       actionSheet.titleLabel.numberOfLines = 2
       actionSheet.titleLabel.lineBreakMode = .byTruncatingTail
       actionSheet.modalPresentation = .popover
       actionSheet.shouldHideTitle = true
       let action = SheetAction(
               title: I18n.View_M_BackToSharedContent,
               sheetStyle: .iconAndLabel,
               handler: { [weak self] _ in
                   self?.doubleTapAction?(.userMenu)
               })
       actionSheet.addAction(action)

       if self.changeOrderEnabled?() == true {
           actionSheet.addAction(SheetAction(
                title: I18n.View_G_AdjustParticipantInThisPosition,
                sheetStyle: .iconAndLabel,
                handler: { [weak self] _ in
                    self?.changeOrderAction?()
                }))
       }

       actionSheet.modifyUniqueActionIfNeeded()
       let verticalEdgeInset: CGFloat = actionSheet.defaultActions.count > 1 ? 4.0 : 0
       let verticalPositionOffset: CGFloat = 2.0 + (actionSheet.defaultActions.count > 1 ? 4.0 : 2.0)
       let anchor = AlignPopoverAnchor(sourceView: sender,
                                       alignmentType: .auto,
                                       contentWidth: .fixed(actionSheet.maxIntrinsicWidth),
                                       contentHeight: actionSheet.intrinsicHeight,
                                       contentInsets: UIEdgeInsets(top: verticalEdgeInset, left: 0, bottom: verticalEdgeInset, right: 0),
                                       positionOffset: CGPoint(x: 0, y: verticalPositionOffset),
                                       minPadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
                                       cornerRadius: 8.0,
                                       borderColor: UIColor.ud.lineBorderCard,
                                       dimmingColor: UIColor.clear,
                                       shadowColor: nil,
                                       containerColor: UIColor.ud.bgFloat,
                                       shadowType: .s3Down)
       let popover = AlignPopoverManager.shared.present(viewController: actionSheet, anchor: anchor)
       popover.fullScreenDetector = self.fullScreenDetector
   }
}
