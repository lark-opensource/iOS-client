//
//  ThreadTitleView.swift
//  LarkThread
//
//  Created by 姚启灏 on 2019/2/14.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkCore
import LarkInteraction
import UIKit

final class ThreadDetailTitleView: UIView, ThreadDisplayTitleView {
    private lazy var contentStatckView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 9
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.textAlignment = .center
        return titleLabel
    }()

    private lazy var subTitleLabel: UILabel = {
        let subTitleLabel = UILabel()
        subTitleLabel.font = UIFont.systemFont(ofSize: 11)
        subTitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subTitleLabel.textColor = UIColor.ud.N500
        return subTitleLabel
    }()

    private lazy var titleArrowImageView: UIImageView = {
        let imageView = UIImageView(image: LarkCore.Resources.goChatSettingArrow)
        imageView.isHidden = true
        return imageView
    }()

    var chatName: String = "" {
        didSet {
            updateView()
        }
    }

    private let disposeBag = DisposeBag()

    var isShowSubTitle: Bool = false {
        didSet {
            if isShowSubTitle == oldValue { return }
            updateView()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(contentStatckView)
        contentStatckView.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.top.bottom.equalToSuperview()
            make.center.equalToSuperview()
        }

        contentStatckView.addArrangedSubview(titleStackView)
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(titleArrowImageView)
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(
                    effect: .highlight,
                    shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                        guard let view = interaction.view else { return (.zero, 0) }
                        return (CGSize(width: view.bounds.width + 24, height: view.bounds.height + 12), 16)
                    })
                )
            )
            contentStatckView.addLKInteraction(pointer)
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func onlyShowTitle(_ title: String) {
        titleLabel.text = title
        hideTitleArrow()
    }

    func setObserveData(chatObservable: BehaviorRelay<Chat>) {
        chatObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chat) in
                guard let self = self else { return }
                self.chatName = chat.name
            }).disposed(by: self.disposeBag)
    }

    private func updateView() {
        titleLabel.text = chatName
        titleArrowImageView.isHidden = false
    }

    func hideTitleArrow() {
        titleArrowImageView.isHidden = true
        titleArrowImageView.image = nil
    }
}
