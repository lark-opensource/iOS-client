//
//  ReplyThreadSourceHeader.swift
//  LarkThread
//
//  Created by liluobin on 2022/4/12.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkContainer
import LarkModel
import UIKit
import LarkSearchFilter
import LarkSDKInterface

final class ReplyThreadSourceTitleView: UIView, ThreadDisplayTitleView, UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedInjectedLazy private var chatterManager: ChatterManagerProtocol?
    var rootMessageFromId: String = ""
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UILayoutPriority.defaultHigh.rawValue - 1), for: .horizontal)
        return titleLabel
    }()

    private lazy var expandBtn: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = UIColor.clear
        btn.addTarget(self, action: #selector(tapSource), for: .touchUpInside)
        return btn
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 10)
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(UILayoutPriority(rawValue: UILayoutPriority.defaultHigh.rawValue - 1), for: .horizontal)
        return label
    }()

    private var fromSource = "" {
        didSet {
            updateUI()
        }
    }
    private let disposeBag = DisposeBag()
    var tapSourceBlock: (() -> Void)?

    init(userResolver: UserResolver, frame: CGRect = .zero) {
        self.userResolver = userResolver
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        addSubview(titleLabel)
        addSubview(subTitleLabel)
        addSubview(expandBtn)
        subTitleLabel.isUserInteractionEnabled = true
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.left.right.lessThanOrEqualToSuperview()
        }
        subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.left.right.lessThanOrEqualToSuperview()
        }
        expandBtn.snp.makeConstraints { make in
            make.bottom.equalTo(subTitleLabel.snp.top)
            make.left.right.equalTo(subTitleLabel)
            make.height.equalTo(12)
        }
        let ges = UITapGestureRecognizer(target: self, action: #selector(tapSource))
        subTitleLabel.addGestureRecognizer(ges)
        titleLabel.text = BundleI18n.LarkThread.Lark_IM_Thread_ThreadDetail_Title
    }

    func setObserveData(chatObservable: BehaviorRelay<Chat>) {
        chatObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (chat) in
                guard let self = self else { return }
                self.updateFromSourceForChat(chat, chatter: chat.chatter)
            }).disposed(by: self.disposeBag)
    }

    private func updateFromSourceForChat(_ chat: Chat, chatter: Chatter?) {
        guard let chatterManager = chatterManager else { return }
        if chat.type == .p2P,
           let name = chatter?.displayName(chatId: chat.id, chatType: chat.type, scene: .head),
           !name.isEmpty,
            (self.rootMessageFromId == chatterManager.currentChatter.id ||
             self.rootMessageFromId == chat.chatterId) {
            /// 来自自己的单聊
            if chatterManager.currentChatter.id == chat.chatterId {
                self.fromSource = chatterManager.currentChatter.name
            } else if self.rootMessageFromId == chat.chatterId {
                self.fromSource = BundleI18n.LarkThread.Lark_IM_Thread_FromUser1AndUser2Chat_Text2("\(name)",
                                                                                                   "\(chatterManager.currentChatter.name)")
            } else {
                self.fromSource = BundleI18n.LarkThread.Lark_IM_Thread_FromUser1AndUser2Chat_Text2("\(chatterManager.currentChatter.name)",
                                                                                    "\(name)")
            }
        } else {
            self.fromSource = chat.name
        }
    }

    func updateUI() {
        let text = BundleI18n.LarkThread.Lark_Chat_Thread_FromChat(self.fromSource)
        let attributedText = NSMutableAttributedString(string: text, attributes: [.foregroundColor: UIColor.ud.textLinkNormal, .font: UIFont.systemFont(ofSize: 10)])
        let range = (text as NSString).range(of: BundleI18n.LarkThread.Lark_Chat_Thread_FromChat(""))
        if range.location != NSNotFound {
            attributedText.setAttributes([.foregroundColor: UIColor.ud.textCaption], range: range)
        }
        subTitleLabel.attributedText = attributedText
    }

    @objc
    func tapSource() {
        self.tapSourceBlock?()
    }
}
