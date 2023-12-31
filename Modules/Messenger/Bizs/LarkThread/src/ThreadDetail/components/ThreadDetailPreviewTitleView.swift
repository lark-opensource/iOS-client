//
//  ThreadDetailPreviewTitleView.swift
//  LarkThread
//
//  Created by ByteDance on 2023/1/6.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkModel
import LarkCore
import LarkInteraction
import UIKit

final class ThreadDetailPreviewTitleView: UIView, ThreadDisplayTitleView {
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
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.textAlignment = .center
        return titleLabel
    }()

    var chatName: String = "" {
        didSet {
            updateView()
        }
    }

    private let disposeBag = DisposeBag()

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
    }
}
