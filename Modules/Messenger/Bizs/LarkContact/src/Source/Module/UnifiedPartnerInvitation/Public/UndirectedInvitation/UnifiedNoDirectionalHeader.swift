//
//  UnifiedNoDirectionalHeader.swift
//  LarkContact
//
//  Created by shizhengyu on 2019/12/15.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import SnapKit
import LarkModel
import LarkCompatible
import LarkLocalizations
import LarkMessengerInterface
import LarkContainer

enum UnifiedNoDirectionalScenes {
    case parent  // edu家长
    case external  // 外部联系人
}

typealias CardSwitchState = MemberNoDirectionalDisplayPriority

protocol UnifiedNoDirectionalHeaderDelegate: AnyObject {
    func whichCardDisplayFirst() -> CardSwitchState
    func shareQRCode()
    func saveQRCodeImage()
    func shareLink()
    func copyLink()
    func switchToCard(targetCardState: CardSwitchState)
}

final class UnifiedNoDirectionalHeader: UIView, CardBindable {
    var headerHeight: CGFloat {
        switch scenes {
        case .external:
            return 480
        case .parent:
            return 400
        }
    }
    private let scenes: UnifiedNoDirectionalScenes
    weak var delegate: UnifiedNoDirectionalHeaderDelegate!
    private var cardInfo: InviteAggregationInfo?
    private let userResolver: UserResolver
    var shareSourceView: UIView {
        return switchView.shareSourceView
    }

    init(frame: CGRect,
         scenes: UnifiedNoDirectionalScenes,
         delegate: UnifiedNoDirectionalHeaderDelegate, resolver: UserResolver) {
        self.scenes = scenes
        self.delegate = delegate
        self.userResolver = resolver
        super.init(frame: frame)
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindWithModel(cardInfo: InviteAggregationInfo) {
        switchView.bindWithModel(cardInfo: cardInfo)
        self.cardInfo = cardInfo
    }

    private func layoutPageSubviews() {
        addSubview(wrapperView)
        wrapperView.addSubview(switchView)

        wrapperView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(headerHeight)
        }

        switchView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private lazy var wrapperView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.layer.shadowRadius = 6
        view.layer.shadowOpacity = 1
        view.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
        view.ud.setValue(forKeyPath: \.layer.shadowOffset,
                         light: CGSize(width: 0, height: 4),
                         dark: CGSize(width: 0, height: 6))
        return view
    }()

    lazy var switchView: SwitchAnimatedView = {
        var qrCodeCard: QRCodeCard?
        var linkCard: InviteLinkCard?
        linkCard = InviteLinkCard(scenes: scenes, resolver: self.userResolver)
        qrCodeCard = QRCodeCard(scenes: scenes, resolver: self.userResolver)
        let view = SwitchAnimatedView(
            qrCodeCard: qrCodeCard,
            inviteLinkCard: linkCard,
            scenes: scenes,
            switchState: delegate.whichCardDisplayFirst(),
            switchHandler: { [weak self] (state) in
                guard let `self` = self else { return }
                self.delegate?.switchToCard(targetCardState: state)
            },
            leftClickHandler: { [weak self] (state) in
                self?.otherClickHandle(state: state)
            },
            rightClickHandler: { [weak self] (state) in
                self?.shareClickHandle(state: state)
            })
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.cornerRadius = 4.0
        view.layer.masksToBounds = true
        view.switchState = delegate.whichCardDisplayFirst()
        view.updateOperationPanel(self.delegate.whichCardDisplayFirst())
        return view
    }()

    private func shareClickHandle(state: CardSwitchState) {
        if state == .qrCode {
            delegate?.shareQRCode()
        } else if state == .inviteLink {
            delegate?.shareLink()
        }
    }

    private func otherClickHandle(state: CardSwitchState) {
        if state == .qrCode {
            delegate?.saveQRCodeImage()
        } else if state == .inviteLink {
            delegate?.copyLink()
        }
    }
}
