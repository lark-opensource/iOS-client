//
//  FeedAIHeaderViewModel.swift
//  LarkFeed
//
//  Created by Hayden on 2023/6/2.
//

import UIKit
import FigmaKit
import LarkContainer
import UniverseDesignFont
import LarkMessengerInterface

class FeedAIHeaderViewModel: NSObject {

    var resolver: UserResolver

    weak var fromVC: UIViewController?

    var myAIService: MyAIService? {
        try? resolver.resolve(assert: MyAIService.self)
    }

    init(resolver: UserResolver, fromVC: UIViewController) {
        self.resolver = resolver
        self.fromVC = fromVC
    }

    func startMyAIInitialization() {
        guard let fromVC = fromVC else { return }
        myAIService?.openMyAIChat(from: fromVC)
    }
}

class FeedAIHeaderView: UIView {

    lazy var aiAvatarView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    lazy var nameLabel: LinearGradientLabel = {
        let nameLabel = LinearGradientLabel()
        nameLabel.direction = .diagonal135
        // swiftlint:disable init_color_with_token
        nameLabel.colors = [UIColor(red: 91.0 / 255, green: 101.0 / 255, blue: 245.0 / 255, alpha: 1),
                            UIColor(red: 222.0 / 255, green: 129.0 / 255, blue: 222.0 / 255, alpha: 1)]
        // swiftlint:enable init_color_with_token
        nameLabel.font = Cons.nameFont
        return nameLabel
    }()

    lazy var lastMessageLabel: UILabel = {
        let lastMessageLabel = UILabel()
        lastMessageLabel.lineBreakMode = .byTruncatingTail
        lastMessageLabel.textColor = UIColor.ud.textPlaceholder
        lastMessageLabel.font = Cons.lastMessageFont
        return lastMessageLabel
    }()

    var viewModel: FeedAIHeaderViewModel

    init(viewModel: FeedAIHeaderViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        addSubview(aiAvatarView)
        addSubview(nameLabel)
        addSubview(lastMessageLabel)
        // 布局参照 BaseFeedTableCell
        aiAvatarView.snp.makeConstraints { make in
            make.left.equalTo(Cons.hMargin)
            make.bottom.equalToSuperview().inset(Cons.avatarBottomDistance)
            make.width.height.equalTo(Cons.avatarSize)
        }
        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(aiAvatarView.snp.right).offset(Cons.avatarNamePadding)
            make.right.equalToSuperview().offset(-Cons.hMargin)
            make.bottom.equalTo(lastMessageLabel.snp.top)
            make.height.equalTo(Cons.nameFont.figmaHeight)
        }
        lastMessageLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().inset(Cons.vMargin)
            make.left.equalTo(aiAvatarView.snp.right).offset(Cons.avatarNamePadding)
            make.right.equalToSuperview().offset(-Cons.hMargin)
            make.height.equalTo(Cons.lastMessageFont.figmaHeight)
        }
        if let defaultResource = viewModel.myAIService?.defaultResource {
            nameLabel.text = defaultResource.name
            aiAvatarView.image = defaultResource.iconLarge
        }
        lastMessageLabel.text = BundleI18n.LarkFeed.MyAI_IM_SetupYourAI_Text
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapAIHeader)))
    }

    var headerHeight: CGFloat {
        Cons.cellHeight
    }

    @objc
    private func didTapAIHeader() {
        viewModel.startMyAIInitialization()
    }
}

private enum Cons {
    static let vMargin: CGFloat = 10.0
    static let hMargin: CGFloat = 16.0
    static var avatarBorderSize: CGFloat { avatarSize + 6.auto() }
    static let avatarBottomDistance: CGFloat = 8.0
    static let avatarNamePadding: CGFloat = 12.0
    static var nameFont: UIFont { UIFont.ud.title3 }
    static var lastMessageFont: UIFont { UIFont.ud.body2 }

    static var contentHeight: CGFloat {
        nameFont.figmaHeight + lastMessageFont.figmaHeight
    }

    static var avatarSize: CGFloat {
        contentHeight + 4
    }

    static var cellHeight: CGFloat {
        contentHeight + vMargin * 2
    }
}
