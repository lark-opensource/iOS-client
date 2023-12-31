//
//  GenericAvatarSettingController.swift
//  LarkChatSetting
//
//  Created by ByteDance on 2023/9/20.
//
import LarkContainer
import Foundation
import LarkSDKInterface
import RxSwift
import RustPB
import LarkMessengerInterface
import UniverseDesignColor
import UniverseDesignToast
import LarkEmotion
import LarkBaseKeyboard

struct GenericAvatarTrackInfo {
    var isImage: Bool
    var isWord: Bool
    var colorType: String
    var isStiching: Bool
    var isCustomize: Bool
    var startColor: Int32
    var endColor: Int32
    var isRecommend: Bool
}

final class GenericAvatarSettingController: AvatarBaseSettingController,
                                          RecommendViewDelegate {

    lazy var avatarEidtView: GenericAvatarView = {
        let avatarView = GenericAvatarView(defaultImage: Resources.newStyle_color_icon)
        avatarView.isUserInteractionEnabled = false
        return avatarView
    }()

    lazy var selectAvatarEntryBar: GenericSelectAvatarEntryBar = GenericSelectAvatarEntryBar(jointAvatarEnable: _jointAvatarEnable)
    lazy var recommendTextLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.LarkChatSetting.Lark_GroupPhoto_Type_Suggestions_Text
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .left
        return label
    }()

    lazy var recommendedAvatarView: RecommendedAvatarView = {
        var recommendView = RecommendedAvatarView()
        recommendView.delegate = self
        return recommendView
    }()
    let chatId: String
    let viewModel: AvatarBaseViewModel
    // 保存头像回调
    var savedCallback: ((UIImage, RustPB.Basic_V1_AvatarMeta, UIViewController, GenericAvatarTrackInfo) -> Void)?
    // 获取meta信息回调
    var fetchDataCallback: ((RustPB.Basic_V1_AvatarMeta) -> Void)?
    // 目前的meta信息
    var avatarMeta: RustPB.Basic_V1_AvatarMeta?
    // 群聊当前设置的头像数据
    var defaultAvatar: VariousAvatarType
    // 拼接头像信息
    var collageData: [Basic_V1_AvatarMeta.CollageData] = []
    // 是否允许拼接
    let jointAvatarEnable: Bool
    lazy var _jointAvatarEnable: Bool = {
        return jointAvatarEnable && viewModel.userResolver.fg.dynamicFeatureGatingValue(with: "im.chat.groupavatar.v3.avatar_stack")
    }()
    // 是否应该展示toast提示。连续点击两次拼接按钮就需要展示
    var shouldReminder: Bool = false
    private var disposeBag = DisposeBag()
    init(chatId: String,
         defaultAvatar: VariousAvatarType,
         viewModel: AvatarBaseViewModel,
         jointAvatarEnable: Bool) {
        self.chatId = chatId
        self.defaultAvatar = defaultAvatar
        self.viewModel = viewModel
        self.jointAvatarEnable = jointAvatarEnable
        super.init(userResolver: viewModel.userResolver)
        self.preferredContentSize = CGSize(width: 480, height: 620)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configBgScrollView()
        self.configSubView()
        self.configSubviewData()
    }

    func configBgScrollView() {
        self.contentView.backgroundColor = UIColor.ud.bgBody
        self.contentView.layer.cornerRadius = 8
        self.contentView.layer.masksToBounds = true

        self.contentView.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(16)
            make.width.equalToSuperview()
        }

        self.scrollView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.top.equalToSuperview()
        }
    }

    func configSubView() {
        self.contentView.addSubview(avatarEidtView)
        let size = avatarEidtView.avatarSize
        // disable-lint-next-line: magic_number
        let leadingSpaceWidth = UIDevice.current.userInterfaceIdiom == .pad ? 32 : 16
        avatarEidtView.snp.makeConstraints { make in
            make.size.equalTo(size)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(40)
        }
        self.contentView.addSubview(selectAvatarEntryBar)
        selectAvatarEntryBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(avatarEidtView.snp.bottom).offset(20)
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        self.contentView.addSubview(recommendTextLabel)
        recommendTextLabel.snp.makeConstraints { make in
            make.top.equalTo(selectAvatarEntryBar.snp.bottom).offset(24)
            make.left.equalToSuperview().offset(leadingSpaceWidth)
            make.right.equalToSuperview().offset(-leadingSpaceWidth)
        }
        self.contentView.addSubview(recommendedAvatarView)
        recommendedAvatarView.snp.makeConstraints { make in
            make.top.equalTo(recommendTextLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(leadingSpaceWidth)
            make.right.equalToSuperview().offset(-leadingSpaceWidth)
            make.bottom.lessThanOrEqualToSuperview().offset(-32)
        }
    }

    func configSubviewData() {
        self.avatarEidtView.setAvatar(defaultAvatar)
        selectAvatarEntryBar.tapImageHandler = { [weak self] in
            self?.onImageViewClick()
        }
        selectAvatarEntryBar.tapTextHandler = { [weak self] in
            self?.onTextViewClick()
        }
        selectAvatarEntryBar.tapJointHandler = { [weak self] in
            self?.onJointViewClick()
        }
        fetchRemoteData { [weak self] (texts, meta) in
            guard let self = self, let meta = meta else { return }
            self.collageData = meta.collageData
            self.avatarMeta = meta
            self.fetchDataCallback?(meta)
            self.generateRecommendAvatar(texts: texts, shouldRecommentJoint: (meta.type != .collage) && self._jointAvatarEnable)
        }
    }

    func fetchRemoteData(completion: @escaping ([String], RustPB.Basic_V1_AvatarMeta?) -> Void) {
        self.viewModel.fetchRemoteData()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (texts, meta) in
                completion(texts, meta)
            })
            .disposed(by: self.disposeBag)
    }

    func generateRecommendAvatar(texts: [String], shouldRecommentJoint: Bool) {
        /// 需要展示的填充头像个数： 4
        let fillItemCount = 4
        // 需要展示的线框个数：4
        let borderedItemCount = shouldRecommentJoint ? 3 : 4
        // 文字推荐的上限
        let wordsItemCount = shouldRecommentJoint ? 5 : 6
        var recommendAvatar: [VariousAvatarType] = []
        var recommendContent: [NSAttributedString] = []
        let config = ColorImageSettingConfig(userResolver: viewModel.userResolver)
        let filledItem: [VariousAvatarType] = config.fillIcons.shuffled().prefix(fillItemCount).map { element in
                .angularGradient(UInt32(element.startColorInt),
                                 UInt32(element.endColorInt),
                                 element.key,
                                 nil,
                                 config.fsUnit)
        }

        let borderedItem: [VariousAvatarType] = config.borderIcons.shuffled().prefix(borderedItemCount).map { element in
                .border(UInt32(element.startColorInt),
                        UInt32(element.endColorInt),
                        nil)
        }
        let textContent: [NSAttributedString] = texts.prefix(wordsItemCount).map { NSAttributedString(string: $0) }
        let emojiContent: [NSAttributedString] = config.emojiKeys.shuffled().prefix(fillItemCount + borderedItemCount - textContent.count).map { emojiKey in
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = EmotionResouce.shared.imageBy(key: emojiKey)
            let randomKeyEmoji = EmotionTransformer.attributeStrValueForKey(emojiKey)
            let attachmentString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: imageAttachment))
            attachmentString.addAttributes([EmotionTransformer.EmojiAttributedKey: randomKeyEmoji], range: NSRange(location: 0, length: 1))
            return attachmentString
        }

        recommendContent.append(contentsOf: textContent)
        recommendContent.append(contentsOf: emojiContent)

        recommendAvatar.append(contentsOf: filledItem)
        recommendAvatar.append(contentsOf: borderedItem)
        recommendAvatar = zip(recommendAvatar.shuffled(), recommendContent).map { (background, content) in
            let fontScale = RecommendLayoutInfo.avatarSize.width / GenericAvatarView.defaultAvatarSize.width
            let textAnalyzer = AvatarAttributedTextAnalyzer(fontScale: fontScale) {
                if case .border(let startColorInt, let endColorInt, _) = background {
                    let startColor = UIColor.ud.rgb(UInt32(startColorInt))
                    let endColor = UIColor.ud.rgb(UInt32(endColorInt))
                    return ColorCalculator.middleColorForm(startColor, to: endColor)
                }
                return UIColor.ud.primaryOnPrimaryFill
            }
            return background.updateText(withText: textAnalyzer.attrbuteStrForText(content))
        }

        if shouldRecommentJoint {
            getJointImage(avatarSize: RecommendLayoutInfo.avatarSize) { [weak self] jointAvatar in
                recommendAvatar.insert(.jointImage(jointAvatar), at: 0)
                self?.recommendedAvatarView.setData(items: recommendAvatar)
            }
        } else {
            recommendedAvatarView.setData(items: recommendAvatar)
        }

    }

    /// 点击保存按钮
    override func saveGroupAvatar() {
        let avatarMeta = self.avatarEidtView.avatarMeta()
        let isImage = avatarMeta.type == .random
        let isWord = avatarMeta.type == .words
        let colorType: String
        if avatarMeta.styleType == .unknownStyle {
            colorType = "others"
        } else {
            colorType = avatarMeta.styleType.rawValue.description
        }
        let isStiching = avatarMeta.type == .collage
        let isCustomize = avatarMeta.type == .upload
        let startColor = avatarMeta.startColor
        let endColor = avatarMeta.endColor
        let isRecommend = self.recommendedAvatarView.whetherInSelectedStaus()
        let genericAvatarTrackInfo = GenericAvatarTrackInfo(isImage: isImage,
                                                            isWord: isWord,
                                                            colorType: colorType,
                                                            isStiching: isStiching,
                                                            isCustomize: isCustomize,
                                                            startColor: startColor,
                                                            endColor: endColor,
                                                            isRecommend: isRecommend)
        self.savedCallback?(self.avatarEidtView.getAvatarImage(),
                            self.avatarEidtView.avatarMeta(),
                            self,
                            genericAvatarTrackInfo)
    }

    /// 点击图片按钮
    private func onImageViewClick() {
        shouldReminder = false
        showSelectActionSheet(arrowDirection: .up, sender: self.selectAvatarEntryBar.imageCircularView, navigator: self.userResolver.navigator, finish: { [weak self] image in
            guard let self = self else { return }
            self.setRightButtonItemEnable(enable: true)
            self.recommendedAvatarView.clearSelectedState()
            // 设置头像为选择的图片，清空颜色和文字
            self.avatarEidtView.setAvatar(.upload(image))
        })
    }

    /// 点击文字按钮
    private func onTextViewClick() {
        shouldReminder = false
        let textAvatarVM = TextAvatarSettingViewModel(resolver: viewModel.userResolver,
                                                      chatId: chatId,
                                                      defaultCenterIcon: viewModel.defaultCenterIcon,
                                                      drawStyle: viewModel.drawStyle,
                                                      avatarMeta: self.getCurrentAvatarMeta())
        let textAvatarVC = TextAvatarSettingController(viewModel: textAvatarVM, fromVC: self)
        textAvatarVC.saveTextAvatarCallBack = { [weak self] textAvatar in
            guard let textAvatar = textAvatar else { return }
            self?.avatarEidtView.setAvatar(textAvatar)
            self?.setRightButtonItemEnable(enable: true)
            self?.recommendedAvatarView.clearSelectedState()
        }
        viewModel.userResolver.navigator.push(textAvatarVC, from: self)
        self.fetchDataCallback = { [weak textAvatarVC] meta in
            textAvatarVC?.refreshView(meta: meta)
        }
    }

    /// 点击拼接按钮
    private func onJointViewClick() {
        if shouldReminder {
            UDToast.showSuccess(with: BundleI18n.LarkChatSetting.Lark_GroupPhoto_AvatarStackSelected_Toast, on: self.view)
        }
        getJointImage(avatarSize: GenericAvatarView.defaultAvatarSize) { [weak self] jointAvatar in
            self?.avatarEidtView.setAvatar(.jointImage(jointAvatar))
            self?.setRightButtonItemEnable(enable: true)
            self?.recommendedAvatarView.clearSelectedState()
            self?.shouldReminder = true
        }
    }

    private func getCurrentAvatarMeta() -> RustPB.Basic_V1_AvatarMeta {
        if self.getRightButtonItemEnableStatus() {
            return avatarEidtView.avatarMeta()
        } else {
            return self.avatarMeta ?? RustPB.Basic_V1_AvatarMeta()
        }
    }

    /// 异步返回拼接好的头像
    func getJointImage(avatarSize: CGSize, completion: @escaping (UIImage) -> Void) {
        var avatarViews: [UIImage] = []
        let defaultJointImage = AvatarJointService.getDefaultImage()
        let dispatchGroup = DispatchGroup()
        if !collageData.isEmpty {
            avatarViews = Array(repeating: defaultJointImage, count: collageData.count)
            for (index, collageInfo) in collageData.enumerated() {
                dispatchGroup.enter()
                let capturedIndex = index
                AvatarJointService.getAvatarImage(frame: CGRect(origin: .zero, size: avatarSize),
                                                  entityID: String(collageInfo.userID),
                                                  avatarKey: collageInfo.avatarKey) { avatarView in
                    avatarViews[capturedIndex] = avatarView
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: .main) {
                completion(AvatarJointService.setupImage(avatars: avatarViews, frameSize: avatarSize) ?? AvatarJointService.getDefaultImage())
            }
        } else {
            fetchRemoteData { [weak self] _, meta in
                guard let self = self, let meta = meta else { return }
                self.collageData = meta.collageData
                self.avatarMeta = meta
                avatarViews = Array(repeating: defaultJointImage, count: collageData.count)
                for (index, collageInfo) in collageData.enumerated() {
                    dispatchGroup.enter()
                    let capturedIndex = index
                    AvatarJointService.getAvatarImage(frame: CGRect(origin: .zero, size: avatarSize),
                                                      entityID: String(collageInfo.userID),
                                                      avatarKey: collageInfo.avatarKey) { avatarView in
                        avatarViews[capturedIndex] = avatarView
                        dispatchGroup.leave()
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    completion(AvatarJointService.setupImage(avatars: avatarViews, frameSize: avatarSize) ?? AvatarJointService.getDefaultImage())
                }
            }
        }
    }

    /// 点击推荐的头像
    func didSelectItem(item: VariousAvatarType) {
        var avatarItem = item

        if case .border(let startColorInt, let endColorInt, let content) = item {
            let textAnalyzer = AvatarAttributedTextAnalyzer {
                let startColor = UIColor.ud.rgb(UInt32(startColorInt))
                let endColor = UIColor.ud.rgb(UInt32(endColorInt))
                return ColorCalculator.middleColorForm(startColor, to: endColor)
            }
            avatarItem = item.updateText(withText: textAnalyzer.attrbuteStrForText(content))
        } else if case .angularGradient(_, _, _, let content, _) = item {
            let textAnalyzer = AvatarAttributedTextAnalyzer {
                return UIColor.ud.primaryOnPrimaryFill
            }
            avatarItem = item.updateText(withText: textAnalyzer.attrbuteStrForText(content))
        } else if case .jointImage(_) = item {
            // 如果是拼接头像，重新绘制更加清晰
            getJointImage(avatarSize: GenericAvatarView.defaultAvatarSize) { [weak self] jointAvatar in
                self?.avatarEidtView.setAvatar(.jointImage(jointAvatar))
                self?.setRightButtonItemEnable(enable: true)
                self?.shouldReminder = false
            }
            return
        }
        self.avatarEidtView.setAvatar(avatarItem)
        self.setRightButtonItemEnable(enable: true)
        self.shouldReminder = false
    }
}
