//
//  ReactionTag.swift
//  LarkReactionView
//
//  Created by 李晨 on 2019/6/5.
//

import Foundation
import LarkExtensions
import LarkEmotion
import UIKit

final class ReactionTag: UIImageView, TagItem {
    typealias UserNameId = (name: String, id: String)
    static let height: CGFloat = 20
    static let internalMargin: CGFloat = 7
    static let verticalMargin: CGFloat = 4

    private var _preferMaxLayoutSize: CGSize = CGSize(width: 0, height: ReactionTag.height)
    private var _canShowUserNameCount: Int = 5 {
        didSet {
            if self._canShowUserNameCount < 0 {
                self._canShowUserNameCount = 0
            }
        }
    }
    private let nameMaxShowLength = 20

    private var userNames: [String] = [] {
        didSet {
            if userNames.lk_slice(0, _canShowUserNameCount) == oldValue.lk_slice(0, _canShowUserNameCount) {
                self.userNames = oldValue
            }
        }
    }

    private var userIds: [String] = []
    // 实际上显示人名数量
    private var realShowCount: Int = 0
    private var nameMaxX: CGFloat = 0

    func width(for string: String, availableWidth: CGFloat) -> CGFloat {
        var attributes: [NSAttributedString.Key: Any] = [:]
        if let font = self.namesLabel.font {
            attributes[.font] = font
        }
        return NSString(string: string).boundingRect(
            with: CGSize(width: availableWidth, height: ReactionTag.height),
            options: .usesLineFragmentOrigin,
            attributes: attributes,
            context: nil
            ).size.width
    }

    private func setNameLabel(with string: String, width: CGFloat) {
        var frame = namesLabel.frame
        frame.size.width = width
        namesLabel.frame = frame
        namesLabel.text = string
    }

    // swiftlint:disable function_body_length
    private func setUserNames() {
        if openEntranceReaction {
            setNameLabel(with: "", width: 0)
            return
        }
        let maxAvailableWidth = _preferMaxLayoutSize.width != 0 ?
            _preferMaxLayoutSize.width - namesLabel.frame.minX - ReactionTag.internalMargin :
            CGFloat.greatestFiniteMagnitude

        var userNamesString: String = ""
        var namesStringWidth: CGFloat = 0

        // 只有一个人名则直接显示
        if userNames.count == 1 {
            userNamesString = String(userNames.first!.prefix(nameMaxShowLength))
            namesStringWidth = width(for: userNamesString, availableWidth: maxAvailableWidth)
            realShowCount = 1
            nameMaxX = namesStringWidth
            setNameLabel(with: userNamesString, width: namesStringWidth)
            return
        }

        let names = self.userNames.map { String($0.prefix(nameMaxShowLength)) }

        // 优先判断所有人都显示是否能放开
        if names.count <= _canShowUserNameCount {
            userNamesString = names.joined(separator: BundleI18n.LarkReactionView.Lark_Legacy_Comma)
            let namesWidth = width(for: userNamesString, availableWidth: .greatestFiniteMagnitude)
            if namesWidth <= maxAvailableWidth {
                namesStringWidth = namesWidth
                nameMaxX = namesStringWidth
                realShowCount = _canShowUserNameCount
                setNameLabel(with: userNamesString, width: namesStringWidth)
                return
            }
        }

        // 算出“等N人“的宽度及剩下可以显示的名字宽度
        var moreString = BundleI18n.LarkReactionView.Lark_Legacy_PostReactionAppend(self.userNames.count)

        // 因为Count会根据显示的人数变化，所以这里多加12的偏移量，避免显示异常
        var moreWith: CGFloat = width(for: moreString, availableWidth: .greatestFiniteMagnitude) + 12
        let namesAvailableWidth = maxAvailableWidth - moreWith

        var canShowNameCount = 0

        // 算出要显示多少个名字
        for index in 1..._canShowUserNameCount {

            let tempString = names.prefix(index).joined(separator: BundleI18n.LarkReactionView.Lark_Legacy_Comma)
            let tempWidth = width(for: tempString, availableWidth: .greatestFiniteMagnitude)

            if tempWidth <= namesAvailableWidth {
                userNamesString = tempString
                namesStringWidth = tempWidth
                canShowNameCount = index
                realShowCount = canShowNameCount
            } else {
                break
            }
        }

        // 如果一个人名都显示不开，则尝试截取第一个人名
        if canShowNameCount == 0, let firstName = names.first {
            var left = 0
            var right = min(firstName.count - 1, nameMaxShowLength - 1)
            let ellipsis = "…"

            while left < right {

                let middle = (left + right) / 2
                let tempString: String = firstName.prefix(middle) + ellipsis
                let tempWidth = width(for: tempString, availableWidth: .greatestFiniteMagnitude)

                if tempWidth <= namesAvailableWidth {
                    userNamesString = tempString
                    namesStringWidth = tempWidth
                    left = middle + 1
                } else {
                    right = middle - 1
                }
            }
            realShowCount = 1
        }

        nameMaxX = namesStringWidth
        // 拼接“等N人“
        moreString = BundleI18n.LarkReactionView.Lark_Legacy_PostReactionAppend(self.userNames.count - realShowCount)
        let concatedString = userNamesString + moreString
        let concatedWidth = ceil(width(for: concatedString, availableWidth: .greatestFiniteMagnitude))
        setNameLabel(with: concatedString, width: concatedWidth)
    }
    // swiftlint:enable function_body_length

    private func reactionTapEvent() {
        tagBeginTap?(self, .icon)
        let duration = ReactionView.iconAnimationDuration
        self.reactionView.layer.lu.bounceAnimation(frames: [1, 1, 1, 0.8, 1], duration: duration, key: nil) { [weak self] in
            guard let `self` = self else { return }
            self.tagDidTap?(self, .icon)
        }
    }

    func tapOpenEntranceReaction() {
        tagDidOpenEntrance?()
    }

    typealias TagItemModel = ReactionInfo

    var reactionImageFetcher: ((TagItemModel, @escaping (UIImage) -> Void) -> Void)?

    var model: TagItemModel? {
        didSet {
            setViewFrame()
            self._canShowUserNameCount = 5
            if let model = self.model {
                self.userNames = model.users.map { $0.name }
                self.userIds = model.users.map { $0.id }
                setUserNames()
            } else {
                self.namesLabel.text = nil
            }
            let placeholder = EmotionResouce.placeholder
            let scale = ReactionTag.height / placeholder.size.height
            let scaledPlaceholder = placeholder.ud.scaled(by: scale)
            self.reactionView.image = scaledPlaceholder.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: ReactionTag.height/2, bottom: 0, right: ReactionTag.height/2), resizingMode: .stretch)
            self.reactionView.contentMode = .scaleToFill
            self.reactionView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.06)
            self.reactionView.layer.cornerRadius = ReactionTag.height / 2
            if openEntranceReaction {
                setReactionViewImage(ReactionOpenEntrance.reactionImage)
                return
            }
            if let model = model,
                let reactionImageFetcher = self.reactionImageFetcher {
                let reactionKey = model.reactionKey
                reactionImageFetcher(model) { [weak self] image in
                    if self?.model?.reactionKey != reactionKey { return }
                    self?.setReactionViewImage(image)
                }
            }
        }
    }

    func setReactionViewImage(_ image: UIImage) {
        excuteInMain { [weak self] in
            guard let self = self else { return }
            self.reactionView.contentMode = .scaleAspectFit
            self.reactionView.image = image
            self.reactionView.backgroundColor = UIColor.clear
            self.reactionView.layer.cornerRadius = 0
        }
    }

    var openEntranceReaction: Bool {
        return self.model?.reactionKey == ReactionOpenEntrance.reactionKey
    }

    private var reactionView: UIImageView = UIImageView()
    private var separator: UIView = UIView()
    private var namesLabel: UILabel = UILabel()

    var textColor: UIColor! = UIColor.ud.N500 {
        didSet {
            self.namesLabel.textColor = self.textColor
        }
    }

    var origin: CGPoint {
        get {
            return self.frame.origin
        }
        set {
            self.frame.origin = newValue
        }
    }

    // 每个Tag的外边距
    var margin: UIEdgeInsets = UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 6)

    var contentSize: CGSize {
        return intrinsicContentSize
    }

    var preferMaxLayoutWidth: CGFloat = 0 {
        didSet {
            self._preferMaxLayoutSize.width = preferMaxLayoutWidth
        }
    }

    var tagBeginTap: ((ReactionTag, ReactionTapType) -> Void)?
    var tagDidTap: ((ReactionTag, ReactionTapType) -> Void)?
    var tagDidOpenEntrance: (() -> Void)?

    func featWidth(_ width: CGFloat) -> CGSize {
        self.preferMaxLayoutWidth = width

        if self.intrinsicContentSize.width > width {
            self.setUserNames()
        }

        return self.intrinsicContentSize
    }

    func resetReactionView(_ image: UIImage) {
        setReactionViewImage(image)
    }

    override var intrinsicContentSize: CGSize {
        let contentWidth = openEntranceReaction ? reactionView.frame.maxX : namesLabel.frame.maxX
        return CGSize(width: contentWidth + ReactionTag.internalMargin,
                      height: ReactionTag.height + ReactionTag.verticalMargin)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.isUserInteractionEnabled = true

        self.layer.cornerRadius = (ReactionTag.height + ReactionTag.verticalMargin) / 2
        self.backgroundColor = UIColor.ud.udtokenReactionBgGrey
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.ud.setShadowColor(UIColor.ud.staticBlack.withAlphaComponent(0.1))
        self.layer.shadowRadius = 2.5

        // icon
        self.reactionView.contentMode = .scaleAspectFit
        self.reactionView.layer.masksToBounds = true
        self.addSubview(self.reactionView)

        self.separator.backgroundColor = UIColor.ud.N400
        addSubview(self.separator)

        // name label
        self.namesLabel.font = UIFont.systemFont(ofSize: 12)
        self.namesLabel.textColor = self.textColor
        self.addSubview(self.namesLabel)
        self.setViewFrame()

        self.reactionView.accessibilityIdentifier = "reaction.view.tag.reaction"
        self.separator.accessibilityIdentifier = "reaction.view.tag.separator"
        self.namesLabel.accessibilityIdentifier = "reaction.view.tag.namesLabel"
    }

    func setViewFrame() {
        let width: CGFloat
        var height: CGFloat = ReactionTag.height
        // 由于容器高度是定值, 因此需要根据当前容器高度和给定图片的尺寸得到宽度
        if let modelWidth = model?.reactionSize?.width, let modelHeight = model?.reactionSize?.height {
            if openEntranceReaction {
                width = modelWidth
                height = modelHeight
            } else {
                width = modelWidth * ReactionTag.height / modelHeight
            }
        } else {
            width = ReactionTag.height
        }
        let y = (ReactionTag.height + ReactionTag.verticalMargin - height) / 2
        var iconRect = CGRect(
            x: ReactionTag.internalMargin,
            y: y, width: width, height: height
        )
        self.reactionView.frame = iconRect
        let separatorWidth: CGFloat = openEntranceReaction ? 0 : 0.5
        self.separator.frame = CGRect(x: self.reactionView.frame.maxX + 7, y: 5.5, width: separatorWidth, height: 13)
        let labelRect = CGRect(
            x: self.separator.frame.maxX + ReactionTag.internalMargin,
            y: 2, width: 0, height: ReactionTag.height
        )
        self.namesLabel.frame = labelRect
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let point = touches.first?.location(in: self) else { return }

        if self.openEntranceReaction {
            tapOpenEntranceReaction()
            return
        }
        // tap icon
        if reactionView.frame.contains(point) {
            self.reactionTapEvent()
            return
        }

        let offset = point.x - namesLabel.frame.minX

        // tap more
        if offset > nameMaxX, offset < namesLabel.frame.width {
            tagDidTap?(self, .more)
            return
        }

        let names = userNames.prefix(realShowCount).map { String($0.prefix(nameMaxShowLength)) }
        // tap name
        for index in 1...names.count {
            let width = self.width(for: names.prefix(index)
                .joined(
                    separator: BundleI18n.LarkReactionView.Lark_Legacy_Comma),
                    availableWidth: .greatestFiniteMagnitude
                )
            if width > offset, index - 1 < realShowCount {
                tagDidTap?(self, .name(userIds[index - 1]))
                return
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
}

extension Array {
    func lk_slice(_ from: Int, _ to: Int) -> [Element] {
        let from = Swift.max(Swift.min(from, self.count), 0)
        let to = Swift.min(to, self.count)

        if from >= to {
            return []
        }

        return Array(self[from..<to])
    }
}

func excuteInMain(_ callback: () -> Void) {
    if Thread.isMainThread {
        callback()
    } else {
        DispatchQueue.main.sync {
            callback()
        }
    }
}
