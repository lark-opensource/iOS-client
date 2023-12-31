//
//  ThreadDetailOnboarding.swift
//  LarkThread
//
//  Created by shane on 2019/5/23.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import LarkCore
import LarkModel
import RustPB

final class ThreadDetailOnboarding: UIView {
    private static let sizeOfView = CGSize(width: 210, height: 265)

    var didTapped: (() -> Void)?

    override var intrinsicContentSize: CGSize {
        return ThreadDetailOnboarding.sizeOfView
    }

    private let disposeBag = DisposeBag()

    init(threadObserver: BehaviorRelay<RustPB.Basic_V1_Thread>) {
        super.init(frame: .zero)

        let promatLabel = UILabel()
        promatLabel.numberOfLines = 0
        promatLabel.isUserInteractionEnabled = true
        /// "快来进行回复吧"
        promatLabel.text = BundleI18n.LarkThread.Lark_Chat_TopicReplyOnboardingTipTwo
        promatLabel.textAlignment = .center
        promatLabel.textColor = UIColor.ud.N400
        promatLabel.font = UIFont.ud.body2
        addSubview(promatLabel)
        promatLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.top.equalToSuperview().offset(50)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        self.addGestureRecognizer(tap)

        threadObserver.asDriver().distinctUntilChanged({ (thread1, thread2) -> Bool in
            return thread1.stateInfo.state == thread2.stateInfo.state
        }).drive(onNext: { (thread) in
            if thread.stateInfo.state == .closed {
                promatLabel.text = BundleI18n.LarkThread.Lark_Chat_TopicClosedReplyOnboardingTip
                tap.isEnabled = false
            } else {
                promatLabel.text = BundleI18n.LarkThread.Lark_Chat_TopicReplyOnboardingTipTwo
                tap.isEnabled = true
            }
        }).disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func tapped() {
        self.didTapped?()
    }
}
