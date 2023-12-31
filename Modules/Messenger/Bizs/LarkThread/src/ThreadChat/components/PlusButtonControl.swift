//
//  PlusButtonView.swift
//  LarkThread
//
//  Created by 姚启灏 on 2019/2/14.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import LarkCore
import LarkModel
import LarkSendMessage
import LarkInteraction
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignShadow

final class PlusButtonViewModel {
    init(chatPushWrapper: ChatPushWrapper, postSendService: PostSendService) {
        self.chatPushWrapper = chatPushWrapper
        self.postSendService = postSendService
    }

    fileprivate let chatPushWrapper: ChatPushWrapper
    private let postSendService: PostSendService
}

final class PlusButtonControl: UIControl {
    static let buttonSize: CGFloat = 48
    static let buttonInset: CGFloat = 16

    init(viewModel: PlusButtonViewModel, clickBlock: (() -> Void)?) {
        self.viewModel = viewModel
        self.clickBlock = clickBlock
        super.init(frame: .zero)
        self.configUI()
        addObservers()
        self.addPointer(
            .init(
                effect: .lift,
                shape: { (size) -> PointerInfo.ShapeSizeInfo in
                    return (size, size.height / 2)
                }
            )
        )

        self.addTarget(self, action: #selector(clickPlusButton), for: .touchUpInside)
    }

    private lazy var buttonBackgroundView: UIView = {
        let buttonBackgroundView = UIView()
        buttonBackgroundView.layer.cornerRadius = Self.buttonSize / 2
        buttonBackgroundView.layer.ud.setShadow(type: UDShadowType.s3DownPri)
        buttonBackgroundView.backgroundColor = UIColor.ud.colorfulBlue
        buttonBackgroundView.isUserInteractionEnabled = false
        return buttonBackgroundView
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - private
    private let viewModel: PlusButtonViewModel
    private var disposeBag = DisposeBag()
    private var clickBlock: (() -> Void)?

    private func configUI() {
        self.addSubview(buttonBackgroundView)
        buttonBackgroundView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(Self.buttonSize)
        }

        let plusImageView = UIImageView(image: UDIcon.getIconByKey(.addOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill))
        buttonBackgroundView.addSubview(plusImageView)
        plusImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    private func update(with isAllowPost: Bool) {
        if isAllowPost {
            self.isSelected = false
        } else {
            self.isSelected = true
        }
    }

    override var isHighlighted: Bool {
        didSet {
            guard !self.isSelected else { return }
            self.buttonBackgroundView.backgroundColor = self.isHighlighted ? UIColor.ud.primaryContentPressed : UIColor.ud.colorfulBlue
        }
    }

    override var isSelected: Bool {
        didSet {
            if self.isSelected {
                buttonBackgroundView.backgroundColor = UIColor.ud.iconDisabled
                buttonBackgroundView.layer.ud.setShadow(type: UDShadowType.s3Down)
            } else {
                buttonBackgroundView.backgroundColor = UIColor.ud.colorfulBlue
                buttonBackgroundView.layer.ud.setShadow(type: UDShadowType.s3DownPri)
            }
        }
    }

    @objc
    private func clickPlusButton() {
        self.clickBlock?()
    }

    private func addObservers() {
        disposeBag = DisposeBag()

        viewModel.chatPushWrapper.chat.distinctUntilChanged { (chat1, chat2) -> Bool in
            return chat1.isAllowPost == chat2.isAllowPost && chat1.isFrozen == chat2.isFrozen
        }
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (chat) in
            guard let `self` = self else { return }
            self.update(with: chat.isAllowPost)
            self.isHidden = chat.isFrozen
        })
        .disposed(by: disposeBag)
    }
}
