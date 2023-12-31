//
//  MailThreadListCellCustomLabelWrapper.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/11/18.
//

import Foundation
import LarkTag
import RxSwift
import UniverseDesignTag
import UniverseDesignIcon

protocol CustomTagElement {
    var view: UIView { get }
}

class CommonCustomTagView: UIView {
    static func createTagView(text: String, fontColor: UIColor, bgColor: UIColor, omitTag: Bool = false) -> CommonCustomTagView {
        var tagView: UDTag?
        if omitTag {
            let tagConfig: UDTagConfig.IconConfig = .init(cornerRadius: 4.0, iconColor: UIColor.ud.udtokenTagNeutralTextNormal,
                                                          backgroundColor: UIColor.ud.udtokenTagNeutralBgNormal,
                                                          height: 18, iconSize: CGSize(width: 12, height: 12))
            tagView = UDTag(icon: UDIcon.moreOutlined.withRenderingMode(.alwaysTemplate), iconConfig: tagConfig)
        } else {
            let tagConfig: UDTagConfig.TextConfig = .init(textColor: fontColor, backgroundColor: bgColor)
            tagView = UDTag(text: text, textConfig: tagConfig)
        }
        tagView?.layer.cornerRadius = 4.0
        tagView?.layer.masksToBounds = true
        let commonView = CommonCustomTagView()
        if let tagView = tagView {
            commonView.addSubview(tagView)
            tagView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
        if omitTag {
            commonView.snp.makeConstraints { (maker) in
                maker.width.equalTo(18)
            }
        } else {
            commonView.snp.makeConstraints { (maker) in
                maker.width.lessThanOrEqualTo(86)
            }
        }
        return commonView
    }
}

extension CommonCustomTagView: CustomTagElement {
    var view: UIView {
        return self
    }
}

/// 多Tag的包装View，可以通过设置一组TagElement来显示一组Tag
class MailThreadCustomTagWrapper: UIStackView {

    /// 最多显示Tag数量，默认为2
    var maxTagCount: Int = 2 {
        didSet { reloadTag() }
    }

    /// 当前Tags，因为maxTagCount未显示出来的也算
    private(set) var tags: [CustomTagElement]?

    override init(frame: CGRect) {
        super.init(frame: .zero)

        self.axis = .horizontal
        self.alignment = .center
        self.spacing = 6

        self.setContentHuggingPriority(.required, for: .horizontal)
        self.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: set view info
extension MailThreadCustomTagWrapper {
    /// rmove all old view
    private func clearOldTag() {
        let views = arrangedSubviews
        views.forEach { (view) in
            view.removeFromSuperview()
        }
    }

    /// reload tags
    private func reloadTag() {
        clearOldTag()

        let count = min(tags?.count ?? 0, maxTagCount)
        for index in 0..<count {
            if let tag = tags?[index] {
                addArrangedSubview(tag.view)
            }
        }
    }

    /// 删除所有Tag
    ///
    /// - Parameter isHidden: 是否隐藏TagView
    func clean(_ isHidden: Bool = false) {
        self.tags = []
        reloadTag()
        self.isHidden = isHidden
    }

    func setElements(_ elements: [CustomTagElement]) {
        self.tags = elements
        reloadTag()
    }
}
