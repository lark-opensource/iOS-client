//  Created by weidong fu on 23/11/2017.

import Foundation
import LarkTag

// 说明 https://docs.bytedance.net/doc/7jfmZdvpvaQPRVJtzhVKsb

// 设置页面需要访问
final class MailNavigationBar: UIView {
    struct Config {
        var largeHeight: CGFloat = 60
        var buttonSize: CGFloat = 24
        var edgeCenterDistance: CGFloat = 28
        var additionalRightPadding: CGFloat = 0
        var isDocsApp: Bool = false
        init() {}
    }
    var config = Config()
    var isNeedHideArrow: Bool?
    var isNeedShowRedDot: Bool = false {
        didSet {
            if isNeedShowRedDot {
                addRedDot()
            } else {
                removeRedDot()
            }
        }
    }

    private lazy var redDot: UIView = {
        let redDot = UIView()
        redDot.backgroundColor = UIColor.ud.functionDangerContentDefault
        redDot.layer.cornerRadius = 4
        return redDot
    }()

    enum SizeType: Int {
        case normal
        case large
        case subTitle
    }
    var sizeType: SizeType = .normal {
        didSet {
            self.snp.updateConstraints({ (make) in
                make.height.equalTo(self.preferedHeight)
            })
            addArrowView()
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    var needLine: Bool = false {
        willSet {
            if newValue {
                let line = UIView()
                line.backgroundColor = UIColor.ud.lineDividerDefault
                self.addSubview(line)
                line.snp.makeConstraints { (make) in
                    make.left.bottom.right.equalToSuperview()
                    make.height.equalTo(0.5)
                }
            }
        }
    }
    var leftButtons: [UIButton] = []
    var rightButtons: [UIButton] = []

    private let defaultTitleFont = UIFont.systemFont(ofSize: 24, weight: .medium)
    private let littleTitleFont = UIFont.systemFont(ofSize: 17, weight: .medium)

    var titleDidSelect: ((_ sender: UITapGestureRecognizer) -> Void)?
    lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.backgroundColor = .clear
        label.font = defaultTitleFont
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapTitleAction(_:)))
        label.addGestureRecognizer(tap)
        return label
    }()

//    lazy var avatarImageView: MailAvatarImageView = self.makeAvatarImageView()
    lazy var menuButton: UIButton = {
        let button = UIButton(type: .custom)
        button.frame = CGRect(x: 16, y: 0, width: 24, height: 24)
        button.setImage(Resources.navigation_drawer_menu, for: .normal)
        return button
    }()

    lazy var menuButtonNew: UIButton = {
        let button = UIButton.init()
        return button
    }()

    lazy var tagView: PaddingUILabel = {
        let label = MailNavigationBar.createTagView(text: "", fontColor: UIColor.ud.primaryContentDefault, bgColor: UIColor.ud.primaryFillSolid02)
        label.isHidden = true
        return label
    }()

    func hideTitle(_ hide: Bool) {
        titleLabel.isHidden = hide
        arrowImageView.isHidden = hide
    }

    private var arrowImageView: UIImageView = UIImageView(image: I18n.image(named: "dropMenu_title_downarrow"))

    lazy var blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: nil)
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(blurView)
        self.addSubview(titleLabel)
        self.addSubview(tagView)
//        self.addSubview(avatarImageView)
        self.addSubview(menuButton)
        self.addSubview(menuButtonNew)
        self.blurView.snp.makeConstraints { (make) in
            make.top.leading.trailing.bottom.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
// MARK: NavBar 左右两边需要填充一样的 Item 保证 Title 在中间
extension MailNavigationBar {
    private func rebalanceNavigationItems() {
        if sizeType == .large {
            return
        }
        if rightButtons.count != leftButtons.count {
            var buttons: [UIBarButtonItem] = []
            for _ in (0 ..< abs(rightButtons.count - leftButtons.count)).reversed() {
                let spaceBarButtonItem = UIBarButtonItem(image: I18n.image(named: "navigation_blank"), style: .plain, target: nil, action: nil)
                buttons.append(spaceBarButtonItem)
            }
            if rightButtons.count > leftButtons.count {
                self.addBarButtons(buttons: &self.leftButtons, items: buttons)
            } else {
                self.addBarButtons(buttons: &self.rightButtons, items: buttons)
            }
        }
    }
}

extension MailNavigationBar {
    var title: String? {
        get { return self.titleLabel.text }
        set {
            self.titleLabel.text = newValue
            self.updateLayout()
        }
    }

    private func addArrowView() {
        if !subviews.contains(arrowImageView) {
            addSubview(arrowImageView)
            arrowImageView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        }
        if isNeedHideArrow == true {
            arrowImageView.isHidden = true
        } else {
            arrowImageView.isHidden = sizeType != .large
        }
    }

    private func addRedDot() {
        if !subviews.contains(redDot) {
            addSubview(redDot)
            redDot.transform = CGAffineTransform(rotationAngle: .pi / 2)
            redDot.snp.makeConstraints { (make) in
                make.right.equalTo(menuButton.snp.right)
                make.top.equalTo(menuButton.snp.top)
                make.width.height.equalTo(8)
            }
        }
        redDot.isHidden = false
    }

    private func removeRedDot() {
        redDot.removeFromSuperview()
        redDot.isHidden = true
    }

    private func updateLayout() {
        self.updateTitleLayout()
        self.updateTagViewLayout()
        self.updateArrowsLayout()
    }

    /// 更新title
    private func updateTitleLayout() {
        let padding: CGFloat = 16
        let leftOffset: CGFloat = 40
        let dist: CGFloat = 20
        self.titleLabel.frame.origin.x = self.leftButtons.last?.frame.maxX ?? self.bounds.minX + padding + leftOffset
        var width = (self.rightButtons.last?.frame.minX ?? self.bounds.maxX - dist) - self.titleLabel.frame.minX
        if !arrowImageView.isHidden && tagView.isHidden {
            width = width - 38
        } else if !tagView.isHidden {
            width = width - 85
        }
        let size = (titleLabel.text as NSString?)?.size(withAttributes: [NSAttributedString.Key.font: titleLabel.font as Any])
        let sizeWidth = (size?.width ?? 0) + 6
        width = min(sizeWidth, width)
        self.titleLabel.frame.size.width = width
        titleLabel.frame.size.height = size?.height ?? 0
        titleLabel.frame.origin.y = (bounds.height - titleLabel.frame.size.height) / 2
    }

    /// 更新tag的位置
    private func updateTagViewLayout() {
        let menuTitleFrame = titleLabel.frame
        let size = (titleLabel.text as NSString?)?.size(withAttributes: [NSAttributedString.Key.font: titleLabel.font as Any])
        tagView.frame.center.y = menuTitleFrame.center.y
        let width = min(titleLabel.frame.width, size?.width ?? 0)
        tagView.frame.origin.x = menuTitleFrame.minX + width + 5
    }

    /// 更新小箭头位置
    private func updateArrowsLayout() {
        if tagView.isHidden {
            let menuTitleFrame = titleLabel.frame
            arrowImageView.frame.size = CGSize(width: 12, height: 12)
            arrowImageView.frame.center.y = menuTitleFrame.center.y - 0.5
            arrowImageView.frame.origin.x = titleLabel.frame.maxX - 2
        } else {
            arrowImageView.frame.center.y = tagView.center.y
            arrowImageView.frame.origin.x = tagView.frame.maxX + 5
        }
        let menuButtonFrame = menuButton.frame
        let width = arrowImageView.frame.maxX - menuButtonFrame.right
        var menuButtonNewFrame = CGRect(x: menuButtonFrame.right, y: menuButtonFrame.minY, width: width, height: titleLabel.bounds.height)
        menuButtonNewFrame.centerY = titleLabel.frame.centerY
        menuButtonNew.frame = menuButtonNewFrame
    }

    private func makeButton(from barBtnItem: UIBarButtonItem) -> UIButton {
        let button = UIButton(frame: .zero)
        button.setTitle(barBtnItem.title, for: .normal)
        button.setTitleColor(barBtnItem.tintColor, for: .normal)
        if let font = barBtnItem.titleTextAttributes(for: .normal)?[.font] as? UIFont {
            button.titleLabel?.font = font
        }
        button.setImage(barBtnItem.image, for: .normal)
        if let image = barBtnItem.highlightImage {
            button.setImage(image, for: .highlighted)
            button.setImage(image, for: .selected)
        } else {
            button.setImage(barBtnItem.image?.mail.alpha(0.8)?.withRenderingMode(.alwaysTemplate), for: .highlighted)
        }
        button.setImage(barBtnItem.image?.mail.alpha(0.5)?.withRenderingMode(.alwaysTemplate), for: .disabled)
        button.setTitleColor(barBtnItem.tintColor, for: .normal)
        button.setTitleColor(barBtnItem.tintColor?.withAlphaComponent(0.8), for: .highlighted)
        button.setTitleColor(barBtnItem.tintColor?.withAlphaComponent(0.5), for: .disabled)
        button.isEnabled = barBtnItem.isEnabled
        button.tag = barBtnItem.tag
        if let action = barBtnItem.action {
            button.addTarget(barBtnItem.target, action: action, for: .touchUpInside)
        }
        button.sizeToFit()
        return button
    }

    private func addBarButtons(buttons: inout [UIButton], items: [UIBarButtonItem]) {
        items.forEach { (item) in
            let button = makeButton(from: item)
            buttons.append(button)
        }
        buttons.forEach { (button) in
            self.addSubview(button)
        }
    }

    private func setBarButtons(buttons: inout [UIButton], items: [UIBarButtonItem]) {
        buttons.forEach { (button) in
            button.removeFromSuperview()
        }
        buttons.removeAll()
        buttons = items.map {
            return makeButton(from: $0)
        }
        buttons.forEach { (button) in
            self.addSubview(button)
        }
    }

    func setLefthtBarButtons(items: [UIBarButtonItem]) {
        self.setBarButtons(buttons: &self.leftButtons, items: items)
        leftButtons.enumerated().forEach { (index, button) in
            button.accessibilityIdentifier = "docs.nav.left.button\(index)"
        }
        // 有item代表在文件夹里面，所以字体要变小... 无语
        if !items.isEmpty {
            titleLabel.font = littleTitleFont
        } else {
            titleLabel.font = defaultTitleFont
        }

        self.titleLabel.textAlignment = !items.isEmpty ? .center : .left
        self.rebalanceNavigationItems()
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    func setRightBarButtons(items: [UIBarButtonItem]) {
        self.setBarButtons(buttons: &self.rightButtons, items: items)
        rightButtons.enumerated().forEach { (index, button) in
            button.accessibilityIdentifier = "docs.nav.right.button\(index)"
        }
        self.rebalanceNavigationItems()
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    var preferedHeight: CGFloat {
        guard self.isHidden == false else {
            return 0
        }
        if self.sizeType == .normal {
            return 44
        } else if self.sizeType == .subTitle {
            return 57
        } else {
            return self.config.largeHeight
        }
    }

//    func makeAvatarImageView() -> MailAvatarImageView {
//        let imageview = MailAvatarImageView()
//
//        imageview.frame = CGRect(x: 16, y: 16.5, width: 30, height: 30)
//        imageview.layer.cornerRadius = 30 / 2
//        imageview.layer.masksToBounds = true
//
//        return imageview
//    }

//    func setAvatar(_ key: String) {
//        avatarImageView.set(avatarKey: key, placeholder: nil, image: nil)
//    }
}

extension MailNavigationBar {
    override func layoutSubviews() {
        super.layoutSubviews()
        let buttonMidDist: CGFloat = 48 // 48 是按钮中心距离
        let normalBtnSize: CGFloat = 24
        let buttonSize = min(self.sizeType == .normal ? normalBtnSize : self.config.buttonSize, self.bounds.size.height)
        let halfButtonSize: CGFloat =  buttonSize * 0.5
        let offset: CGFloat = (self.sizeType == .normal ? normalBtnSize : self.config.edgeCenterDistance) - halfButtonSize + config.additionalRightPadding
        let spase: CGFloat = buttonMidDist - buttonSize
        let halfHeight: CGFloat = self.bounds.size.height * 0.5
        let midY = self.bounds.origin.y + halfHeight
        var x = self.bounds.minX + offset
        for button in self.leftButtons {
            button.frame.size.height = buttonSize
            button.center.y = midY
            if button.title(for: .normal) == nil {
                button.frame.size.width = buttonSize
            }
            button.frame.origin.x = x
            // 上下热区过大不影响，左右会影响其他按钮响应
            button.hitTestEdgeInsets = UIEdgeInsets(top: -90, left: -(spase / 2), bottom: -90, right: -(spase / 2))
            x += button.bounds.size.width
            x += spase
        }
        x = self.bounds.maxX - offset
        for button in self.rightButtons {
            button.frame.size.height = buttonSize
            button.center.y = midY
            if button.title(for: .normal) == nil {
                button.frame.size.width = buttonSize
            }
            x -= button.bounds.size.width
            button.frame.origin.x = x
            // 上下热区过大不影响，左右会影响其他按钮响应
            button.hitTestEdgeInsets = UIEdgeInsets(top: -90, left: -(spase / 2), bottom: -90, right: -(spase / 2))
            x -= spase - 4
        }
        updateTitleLayout()
        let titleFrame = self.titleLabel.frame
        self.tagView.frame = CGRect(x: titleFrame.right + 5,
                                    y: titleFrame.midY - tagView.bounds.height / 2,
                                    width: tagView.bounds.width,
                                    height: tagView.bounds.height)
        var menuButtonFrame = menuButton.frame
        menuButtonFrame.centerY = self.titleLabel.frame.centerY
        menuButton.frame = menuButtonFrame
        updateTagViewLayout()
        updateArrowsLayout()
    }
}

extension MailNavigationBar {
    @objc
    func tapTitleAction(_ sender: UITapGestureRecognizer) {
        if sizeType == .large {
            titleDidSelect?(sender)
        }
    }
    func updateArrowsDirection(for showing: Bool) {
        if showing {
            arrowImageView.transform = CGAffineTransform(rotationAngle: .pi / 2)
            UIView.animate(withDuration: timeIntvl.uiAnimateNormal) {
                self.arrowImageView.transform = CGAffineTransform(rotationAngle: -.pi / 2)
            }
        } else {
            arrowImageView.transform = CGAffineTransform(rotationAngle: -.pi / 2)
            UIView.animate(withDuration: timeIntvl.uiAnimateNormal) {
                self.arrowImageView.transform = CGAffineTransform(rotationAngle: .pi / 2)
            }
        }
    }
}

// MARK: Tag
extension MailNavigationBar {
    static func createTagView(text: String, fontColor: UIColor, bgColor: UIColor) -> PaddingUILabel {
        let label = PaddingUILabel()
        label.paddingLeft = 5
        label.paddingRight = 5
        label.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.textAlignment = .center
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.snp.makeConstraints { (maker) in
            maker.height.equalTo(16)
            maker.width.lessThanOrEqualTo(86)
        }
        // label
        label.textColor = fontColor
        label.color = bgColor
        label.text = text
        return label
    }
}
