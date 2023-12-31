//
//  SearchIntentionCapsuleCell.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/7/5.
//

import LarkUIKit
import LarkBizAvatar
import LarkSearchFilter
import UniverseDesignColor
import UniverseDesignIcon

// iconImage + leftLabel + avatarImage + rightLablel + expandView
public final class SearchIntentionCapsuleCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    static var identifier: String = "SearchIntentionCapsuleCell"
    public static let viewHeight: CGFloat = 32
    public static let viewDefaultWidth: CGFloat = 80
    private static let imageSize: CGSize = CGSize(width: 16, height: 16)
    private static let expandCancelSize: CGSize = CGSize(width: 14, height: 10)
    private static let expandShowMoreSize: CGSize = CGSize(width: 10, height: 10)
    public var onClickExpandView: ((SearchIntentionCapsuleModel) -> Void)?
    public var onLongPressCell: ((SearchIntentionCapsuleModel, UIView) -> Void)?

    var capsuleModel: SearchIntentionCapsuleModel?
    let containerStackView: SearchIntentionCapsuleStackView = {
        let containerStackView = SearchIntentionCapsuleStackView()
        containerStackView.axis = .horizontal
        containerStackView.alignment = .center
        containerStackView.spacing = SearchIntentionCapsuleStackView.dynamicSpacing
        return containerStackView
    }()
    let iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 2
        return iconImageView
    }()
    let leftLabel: UILabel = {
        let leftLabel = UILabel()
        leftLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        return leftLabel
    }()
    let avatarContainer: RoundAvatarStackView = RoundAvatarStackView(avatarViews: [],
                                                                     avatarWidth: SearchIntentionCapsuleCell.imageSize.width,
                                                                     overlappingWidth: 0,
                                                                     showBgColor: false,
                                                                     blueCircleWidth: 0)
    let rightLabel: UILabel = {
        let rightLabel = UILabel()
        rightLabel.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
        return rightLabel
    }()
    let expandButton: SearchIntentionCapsuleExpandButton = SearchIntentionCapsuleExpandButton(frame: CGRect.zero)

    let longPressGesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer()
    public override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = Self.viewHeight / 2
        contentView.addSubview(containerStackView)
        containerStackView.addArrangedSubview(iconImageView)
        containerStackView.addArrangedSubview(leftLabel)
        containerStackView.addArrangedSubview(avatarContainer)
        containerStackView.addArrangedSubview(rightLabel)
        containerStackView.addArrangedSubview(expandButton)
        containerStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.equalToSuperview().offset(SearchIntentionCapsuleStackView.leftRightSpacing)
            make.trailing.equalToSuperview().offset(-SearchIntentionCapsuleStackView.leftRightSpacing)
            make.height.equalTo(Self.viewHeight)
            make.top.bottom.equalToSuperview()
        }
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(Self.imageSize)
        }
        expandButton.snp.makeConstraints { make in
            make.size.equalTo(Self.expandCancelSize)
        }

        // 手势会截断cell的selected 和 highlight状态，影响UI
        longPressGesture.isEnabled = false
        longPressGesture.addTarget(self, action: #selector(longPressAction(gesture:)))
        addGestureRecognizer(longPressGesture)

        expandButton.addTarget(self, action: #selector(expandButtonClick), for: UIControl.Event.touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func resetViews() {
        iconImageView.isHidden = true
        iconImageView.image = nil
        iconImageView.backgroundColor = nil
        iconImageView.contentMode = .scaleAspectFit
        leftLabel.isHidden = true
        leftLabel.text = nil
        avatarContainer.isHidden = true
        avatarContainer.set([])
        rightLabel.isHidden = true
        rightLabel.text = nil
        expandButton.isHidden = true
        expandButton.isUserInteractionEnabled = true
        layer.borderColor = nil
        layer.borderWidth = 0
        isUserInteractionEnabled = true
        longPressGesture.isEnabled = false
    }

    public func updateCapsuleModel(model: SearchIntentionCapsuleModel) {
        self.capsuleModel = model
        resetViews()
        backgroundColor = model.isSelected ? UIColor.ud.primaryPri100 : UIColor.ud.bgFiller
        leftLabel.textColor = model.isSelected ? UIColor.ud.primaryPri500 : UIColor.ud.textTitle
        rightLabel.textColor = model.isSelected ? UIColor.ud.primaryPri500 : UIColor.ud.textTitle
        leftLabel.font = UIFont.systemFont(ofSize: 14, weight: model.isSelected ? .medium : .regular)
        rightLabel.font = UIFont.systemFont(ofSize: 14, weight: model.isSelected ? .medium : .regular)
        switch model.type {
        case .tab(let tab, let recommend):
            if recommend != nil, !model.isSelected {
                longPressGesture.isEnabled = true
            }
            leftLabel.text = tab.title
            leftLabel.isHidden = false
            expandButton.isUserInteractionEnabled = model.isSelected
            //网图设置为圆形
            if model.isSelected {
                if case .open(let openSearch) = tab, let iconURLStr = openSearch.icon, !iconURLStr.isEmpty, let iconURL = URL(string: iconURLStr) {
                    iconImageView.bt.setImage(with: iconURL, completionHandler: { [weak self] imageResult in
                        guard let self = self else { return }
                        switch imageResult {
                        case .success(let data):
                            self.iconImageView.image = data.image
                        case .failure:
                            self.iconImageViewSetDefault()
                        }
                    })
                } else if let image = tab.icon {
                    iconImageView.image = image
                } else {
                    self.iconImageViewSetDefault()
                }
                iconImageView.isHidden = false

                updateExpandButton(state: .cancel)
                expandButton.isHidden = false
            }
        case .filter(let filter, let recommend):
            if recommend != nil, !model.isSelected {
                longPressGesture.isEnabled = true
            }
            // 筛选项 本质上是没有选中态的，其选中态是转化为对应的筛选器被选中
            if case .specificFilterValue = filter {
                if model.isSelected {
                    assertionFailure("should not have selected status")
                }
                leftLabel.text = filter.title
                leftLabel.isHidden = false
            } else {
                switch filter.displayType {
                case .avatars:
                    let leftPartTitle = filter.title
                    let avatarViews = filter.getAvatarViews(blueCircleWidth: 0) ?? []
                    leftLabel.text = leftPartTitle
                    leftLabel.isHidden = false
                    if !avatarViews.isEmpty {
                        avatarContainer.set(avatarViews)
                        avatarContainer.isHidden = false
                    }
                    let remianNumber = filter.avatarInfos.count - 1
                    if remianNumber > 0 {
                        rightLabel.text = "+\(remianNumber)"
                        rightLabel.isHidden = false
                    }
                case .text:
                    leftLabel.text = filter.title
                    leftLabel.isHidden = false
                case .textAvatar, .unknown:
                    assertionFailure("error case")
                }
                if model.isSelected {
                    updateExpandButton(state: .cancel)
                    expandButton.isHidden = false
                    expandButton.isUserInteractionEnabled = true
                } else {
                    expandButton.isUserInteractionEnabled = false
                    if case .docOwnedByMe = filter {
                        expandButton.isHidden = true
                    } else {
                        updateExpandButton(state: .showMore)
                        expandButton.isHidden = false
                    }
                }
            }
        case .advancedSearch(let count):
            let countStr = count >= 1 ? " \(count) " : ""
            leftLabel.text = BundleI18n.LarkSearch.Lark_NewSearch_SecondarySearch_AdvancedSearchFilters_Title + countStr
            leftLabel.isHidden = false
            backgroundColor = UIColor.ud.bgFloat
            layer.borderColor = UIColor.ud.bgFiller.cgColor
            layer.borderWidth = 1
        }
    }

    private func iconImageViewSetDefault() {
        let image = UDIcon.getIconByKey(.appDefaultOutlined, iconColor: UIColor.ud.staticWhite, size: CGSize(width: 9, height: 9))
        iconImageView.backgroundColor = UIColor.ud.N350
        iconImageView.image = image
        iconImageView.contentMode = .center
    }

    @objc
    private func longPressAction(gesture: UILongPressGestureRecognizer) {
        guard let block = onLongPressCell, let model = capsuleModel else { return }
        block(model, self.contentView)
    }

    @objc
    private func expandButtonClick() {
        guard let block = self.onClickExpandView, let model = capsuleModel else { return }
        block(model)
    }

    private func updateExpandButton(state: SearchIntentionCapsuleExpandButton.State) {
        var image: UIImage?
        var size: CGSize = Self.expandShowMoreSize
        var imageEdgeInsets: UIEdgeInsets = .zero
        switch state {
        case .showMore:
            image = UDIcon.downBoldOutlined.withRenderingMode(.alwaysOriginal).ud.withTintColor(UIColor.ud.iconN2)
        case .cancel:
            image = UDIcon.closeBoldOutlined.withRenderingMode(.alwaysOriginal).ud.withTintColor(UIColor.ud.primaryPri500)
            size = Self.expandCancelSize
            imageEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        }
        expandButton.imageEdgeInsets = imageEdgeInsets
        expandButton.setImage(image, for: UIControl.State.normal)
        expandButton.snp.remakeConstraints { make in
            make.size.equalTo(size)
        }
    }

    override public var isHighlighted: Bool {
        didSet { updateCellStyle() }
    }

    private func updateCellStyle() {
        guard let model = capsuleModel else { return }
        var color: UIColor
        if isHighlighted && !model.isSelected {
            switch model.type {
            case .filter, .tab:
                color = UIColor.ud.N300
            default:
                color = UIColor.ud.udtokenBtnSeBgNeutralHover
            }
        } else if model.isSelected {
            color = UIColor.ud.primaryPri100
        } else {
            switch model.type {
            case .advancedSearch:
                color = UIColor.ud.bgFloat
            default:
                color = UIColor.ud.bgFiller
            }
        }
        backgroundColor = color
    }
}

extension SearchIntentionCapsuleCell {
    // iOS 11.4.1 使用自动布局动态计算cell宽度会卡死
    static public func cellSize(withViewModel model: SearchIntentionCapsuleModel) -> CGSize {
        func labelWidth(str: String, font: UIFont) -> CGFloat {
            let rect = (str as NSString).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: Self.viewHeight),
                                                      options: .usesLineFragmentOrigin,
                                                      attributes: [NSAttributedString.Key.font: font],
                                                      context: nil)
            return CGFloat(ceilf(Float(rect.width)))
        }
        var width: CGFloat = SearchIntentionCapsuleStackView.leftRightSpacing * 2
        let titleFont = UIFont.systemFont(ofSize: 14, weight: model.isSelected ? .medium : .regular)
        switch model.type {
        case .tab(let tab, _):
            let leftLabelWidth = labelWidth(str: tab.title, font: titleFont)
            width += leftLabelWidth
            if model.isSelected {
                width += Self.imageSize.width + Self.expandCancelSize.width
                width += 2 * SearchIntentionCapsuleStackView.dynamicSpacing
            }
        case .filter(let filter, _):
            if case .specificFilterValue = filter {
                width += labelWidth(str: filter.title, font: titleFont)
            } else {
                switch filter.displayType {
                case .avatars:
                    let avatarViews = filter.getAvatarViews(blueCircleWidth: 0) ?? []
                    width += labelWidth(str: filter.title, font: titleFont)
                    if !avatarViews.isEmpty {
                        width += Self.imageSize.width + SearchIntentionCapsuleStackView.dynamicSpacing
                    }
                    let remianNumber = filter.avatarInfos.count - 1
                    if remianNumber > 0 {
                        width += labelWidth(str: "+\(remianNumber)", font: titleFont) + SearchIntentionCapsuleStackView.dynamicSpacing
                    }
                case .text:
                    width += labelWidth(str: filter.title, font: titleFont)
                case .textAvatar, .unknown:
                    assertionFailure("error case")
                }
                if model.isSelected {
                    width += Self.expandCancelSize.width + SearchIntentionCapsuleStackView.dynamicSpacing
                } else {
                    if case .docOwnedByMe = filter {
                        //
                    } else {
                        width += Self.expandShowMoreSize.width + SearchIntentionCapsuleStackView.dynamicSpacing
                    }
                }
            }
        case .advancedSearch(let count):
            var title = count >= 1 ? " \(count) " : ""
            title = BundleI18n.LarkSearch.Lark_NewSearch_SecondarySearch_AdvancedSearchFilters_Title + title
            width += labelWidth(str: title, font: titleFont)
        }
        return CGSize(width: width, height: Self.viewHeight)
    }
}

// 增大点击的热区
final class SearchIntentionCapsuleStackView: UIStackView {
    static let leftRightSpacing: CGFloat = 12
    static let dynamicSpacing: CGFloat = 4

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let insets = UIEdgeInsets(top: 0, left: -Self.leftRightSpacing, bottom: 0, right: -Self.leftRightSpacing)
        if bounds.inset(by: insets).contains(point) {
            for subview in subviews.reversed() {
                let insidePoint = convert(point, to: subview)
                if let hitView = subview.hitTest(insidePoint, with: event) {
                    return hitView
                }
            }
            return self
        }
        return super.hitTest(point, with: event)
    }
}

// 增大点击的热区
final class SearchIntentionCapsuleExpandButton: UIButton {
    enum State {
        case showMore
        case cancel
    }
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let insets = UIEdgeInsets(top: -11, left: -6, bottom: -11, right: -12)
        if bounds.inset(by: insets).contains(point) {
            return self
        }
        return super.hitTest(point, with: event)
    }
}
