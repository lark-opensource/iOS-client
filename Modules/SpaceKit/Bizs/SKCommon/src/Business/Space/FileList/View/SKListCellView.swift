//
//  ListTagView.swift
//  SKCommon
//
//  Created by majie.7 on 2022/11/21.
//

import Foundation
import SKResource
import SKFoundation
import UniverseDesignTag
import UniverseDesignIcon
import UniverseDesignColor

public enum SKListCellElementType {
    case richLabel(attributedString: NSAttributedString)              //标题
    case template(visable: Bool)                                      //模版标签
    case external(visable: Bool)                                      //对外标签
    case singleContainer(visable: Bool)                               //单容器标签
    case star(visable: Bool)                                          //收藏图标
    case owner(visable: Bool)                                         //所有者标签
    case count(number: String, visable: Bool)                         //计数标签（协作者搜索列表）
    case customTag(text: String, visable: Bool)                       //自定义标签（关联组织）
    case app(visable: Bool)                                           //应用

    public static func titleLabel(text: String) -> Self {
        .richLabel(attributedString: NSAttributedString(string: text))
    }

    public var text: NSAttributedString {
        switch self {
        case let .richLabel(text):
            return text
        default:
            return NSAttributedString(string: plainText)
        }
    }

    fileprivate var plainText: String {
        switch self {
        case let .richLabel(text):
            spaceAssertionFailure("should not get plainText from richText")
            return text.string
        case .template:
            return BundleI18n.SKResource.Doc_Create_File_ByTemplate
        case .external:
            return BundleI18n.SKResource.Doc_Widget_External
        case .singleContainer:
            return BundleI18n.SKResource.CreationMobile_ECM_FileMigration_gen2_tag
        case .star:
            spaceAssertionFailure("star icon has't string")
            return ""
        case .owner:
            return BundleI18n.SKResource.Doc_Share_ShareOwner
        case let .count(number, _):
            return number
        case let .customTag(text, _):
            return text
        case .app:
            return BundleI18n.SKResource.CreationMobile_Common_Tag_App
        }
    }
    
    public var textColor: UIColor {
        switch self {
        case .richLabel:
            return UDColor.textTitle
        case .template:
            return UDColor.udtokenTagTextSIndigo
        case .external:
            return UDColor.udtokenTagTextSBlue
        case .singleContainer:
            return UDColor.udtokenTagNeutralTextNormal
        case .star:
            spaceAssertionFailure("star icon has't text color")
            return .clear
        case .owner:
            return UDColor.B600
        case .count:
            return UDColor.N900
        case .customTag:
            return UDColor.udtokenTagTextSBlue
        case .app:
            return UDColor.O700
        }
    }
    
    public var backgroundColor: UIColor {
        switch self {
        case .richLabel, .count:
            return .clear
        case .template:
            return UDColor.udtokenTagBgIndigo
        case .external:
            return UDColor.udtokenTagBgBlue
        case .singleContainer:
            return UDColor.udtokenTagNeutralBgNormal
        case .star:
            return UDColor.colorfulYellow
        case .owner:
            return UDColor.B100
        case .customTag:
            return UDColor.udtokenTagBgBlue
        case .app:
            return UDColor.O200
        }
    }
    
    public var shouldShow: Bool {
        switch self {
        case let .richLabel:
            return true
        case let .template(visable):
            return visable
        case let .external(visable):
            return visable
        case let .singleContainer(visable):
            return visable
        case let .star(visable):
            return visable
        case let .owner(visable):
            return visable
        case let .count(_, visable):
            return visable
        case let .customTag(_, visable):
            return visable
        case let .app(visable):
            return visable
        }
    }
}

// 提供集成化的 标题 + [Tag] 布局, 不支持(不建议)加入可交互的view
public final class SKListCellView: UIView {
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.axis = .horizontal
        view.distribution = .fill
        view.spacing = 6
        return view
    }()

    // 维护当前列表cell有可能出现的所有tag
    private var views: [SKListCellElementType] = []
    
    private var shouldAddCompressionConsistance: Bool {
        var should: Bool = false
        views.forEach { view in
            if case let .customTag(text, _) = view {
                let width = text.estimatedSingleLineUILabelWidth(in: UIFont.systemFont(ofSize: 14))
                if width > 60 { should = true }
                return
            }
        }
        return should
    }
    
    public init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func updateView(disable: Bool = false) {
        removeAllSubViewFromStackView()
        let shouldAdd = shouldAddCompressionConsistance
        views.forEach { view in
            if !view.shouldShow { return }
            switch view {
            case let .richLabel(text):
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: 17, weight: .regular)
                label.textColor = UDColor.textTitle
                label.backgroundColor = .clear
                label.numberOfLines = 1
                label.lineBreakMode = .byTruncatingTail
                label.alpha = disable ? 0.3 : 1
                label.attributedText = text
                label.setContentCompressionResistancePriority(shouldAdd ? .required + 20 : .required, for: .horizontal)
                stackView.addArrangedSubview(label)
                label.snp.makeConstraints { make in
                    make.centerY.equalToSuperview()
                }
            case .count:
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: 16)
                label.textColor = UIColor.ud.N900
                label.alpha = disable ? 0.3 : 1
                label.text = view.plainText
                label.setContentCompressionResistancePriority(.required + 30, for: .horizontal)
                stackView.addArrangedSubview(label)
                label.snp.makeConstraints { make in
                    make.centerY.equalToSuperview()
                }
            case .star:
                let view = UIImageView()
                view.image = UDIcon.collectFilled.ud.withTintColor(UDColor.colorfulYellow)
                view.setContentCompressionResistancePriority(.required, for: .horizontal)
                stackView.addArrangedSubview(view)
                view.snp.makeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.width.height.equalTo(16)
                }
            case .customTag:
                let config = UDTagConfig.TextConfig(cornerRadius: 4,
                                                    textColor: view.textColor,
                                                    backgroundColor: view.backgroundColor)
                let tag = UDTag(text: view.plainText, textConfig: config)
                tag.alpha = disable ? 0.3 : 1
                
                stackView.addArrangedSubview(tag)
                let maxWidth = view.plainText.estimatedSingleLineUILabelWidth(in: UIFont.systemFont(ofSize: 14))
                // 自定义Admin标签规则: 宽度大于60根据布局情况进行压缩，不得小于60
                if maxWidth > 60 {
                    tag.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                    tag.snp.makeConstraints { make in
                        make.centerY.equalToSuperview()
                        make.width.greaterThanOrEqualTo(60)
                    }
                } else {
                    tag.setContentCompressionResistancePriority(.required + 50, for: .horizontal)
                    tag.snp.makeConstraints { make in
                        make.centerY.equalToSuperview()
                    }
                }
            default:
                let config = UDTagConfig.TextConfig(cornerRadius: 4,
                                                    textColor: view.textColor,
                                                    backgroundColor: view.backgroundColor)
                let tag = UDTag(text: view.plainText, textConfig: config)
                tag.alpha = disable ? 0.3 : 1
                tag.setContentCompressionResistancePriority(.required, for: .horizontal)
                stackView.addArrangedSubview(tag)
                tag.snp.makeConstraints { make in
                    make.centerY.equalToSuperview()
                }
            }
        }
    }
    
    private func removeAllSubViewFromStackView() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
    
    public func update(views: [SKListCellElementType], disable: Bool = false) {
        self.views = views
        updateView(disable: disable)
    }

    public func update(disable: Bool) {
        updateView(disable: disable)
    }
}
