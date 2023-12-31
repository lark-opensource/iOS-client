//
//  DetailCommentHeaderView.swift
//  Todo
//
//  Created by 张威 on 2021/2/27.
//

import LarkUIKit
import CTFoundation
import LarkActivityIndicatorView
import Foundation
import RichLabel
import UniverseDesignFont

/// Detail - Comment - Header

enum DetailCommentLoadStatus: Int {
    /// 加载首屏（静默，无 loading）
    case loadingFirstSilently
    /// 加载首屏
    case loadingFirst
    /// 正在加载更多
    case loadingMore
    /// 还有更多
    case hasMore
    /// 没有更多（已全部加载）
    case noMore
    /// 没数据
    case emptyData
    /// 加载失败（没有数据）
    case loadFailed
}

struct DetailCommentHeaderViewData {

    enum Action {
        // 标题点击
        case title(guid: String)
        // 用户
        case user(chatterId: String)
    }

    var linkActions: [NSRange: Action]?

    var richContent: RichLabelContent?

    var status: DetailCommentLoadStatus = .emptyData

    func hasContent() -> Bool {
        return richContent != nil
    }

    var displayContent: Bool {
        guard hasContent() else {
            return false
        }
        guard ![.loadingFirst, .loadingMore, .hasMore, .loadFailed].contains(status) else {
            return false
        }
        return true
    }

}

class DetailCommentHeaderView: UITableViewHeaderFooterView {

    static let componentsHeights = (
        title: CGFloat(24),
        hasMore: CGFloat(36),
        loadingMore: CGFloat(36),
        loadingSketch: CGFloat(64 * 4),
        loadFaield: CGFloat(208)
    )

    static func heightForStatus(_ status: DetailCommentLoadStatus) -> CGFloat {
        switch status {
        case .loadingFirstSilently:
            return CGFloat.leastNormalMagnitude
        case .loadingFirst:
            return componentsHeights.title + componentsHeights.loadingSketch
        case .loadingMore:
            return componentsHeights.title + componentsHeights.loadingMore
        case .hasMore:
            return componentsHeights.title + componentsHeights.hasMore
        case .noMore:
            return componentsHeights.title
        case .loadFailed:
            return componentsHeights.title + componentsHeights.loadFaield
        case .emptyData:
            return componentsHeights.title
        }
    }

    static func heightForRichContent(_ richContent: RichLabelContent, displayWidth: CGFloat) -> CGFloat {
        let richView = RichContentView()
        richView.richContent = richContent
        richView.preferredMaxLayoutWidth = displayWidth
        return richView.sizeThatFits(CGSize(width: displayWidth, height: .greatestFiniteMagnitude)).height
    }

    var viewData: DetailCommentHeaderViewData? {
        didSet {
            guard let viewData = viewData else {
                return
            }

            // status
            titleComponents.container.isHidden = viewData.status == .loadingFirstSilently
            loadingSketchComponents.container.isHidden = viewData.status != .loadingFirst
            loadingMoreComponents.container.isHidden = viewData.status != .loadingMore
            hasMoreComponents.container.isHidden = viewData.status != .hasMore
            loadFailedComponents.container.isHidden = viewData.status != .loadFailed
            if loadingMoreComponents.container.isHidden {
                loadingMoreComponents.indicator.stopAnimating()
            } else {
                loadingMoreComponents.indicator.startAnimating()
            }
            if !loadingSketchComponents.container.isHidden {
                let cells = [
                    loadingSketchComponents.firstItem,
                    loadingSketchComponents.secondItem,
                    loadingSketchComponents.thirdItem,
                    loadingSketchComponents.forthItem
                ]
                cells.forEach { $0.startAnimationIfNeeded() }
            }

            // rich content
            richContentComponent.richContent = viewData.richContent
            richContentComponent.isHidden = !viewData.displayContent
            // actions
            if let linkActions = viewData.linkActions {
                richContentComponent.linkRanges = Array(linkActions.keys)
            }

        }
    }

    /// 加载更多被点击
    var onLoadMore: (() -> Void)?

    /// 失败重试被点击
    var onRetry: (() -> Void)?

    /// 点击内容
    var onTapContent: ((NSRange) -> Void)? {
        didSet {
            richContentComponent.onTapContent = onTapContent
        }
    }

    /// 标题区域
    private let titleComponents = (container: UIView(), label: UILabel())

    /// 「显示更早」区域
    private let hasMoreComponents = (container: UIView(), button: UIButton())

    /// 「加载更多」区域
    private let loadingMoreComponents = (
        container: UIView(),
        centerX: UIView(),
        indicator: ActivityIndicatorView(color: UIColor.ud.primaryContentDefault),
        label: UILabel()
    )

    /// 富文本区域（创建信息）
    private let richContentComponent = RichContentView()

    /// 「加载首页」区域
    private let loadingSketchComponents = (
        container: UIView(),
        firstItem: DetailCommentSkeletonCell(),
        secondItem: DetailCommentSkeletonCell(),
        thirdItem: DetailCommentSkeletonCell(),
        forthItem: DetailCommentSkeletonCell()
    )

    /// 「加载失败」区域
    private let loadFailedComponents = (container: UIView(), imageView: UIImageView(), label: UILabel())

    private let stackView = UIStackView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        tintColor = UIColor.ud.bgBody

        stackView.axis = .vertical
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // title components: container
        stackView.addArrangedSubview(titleComponents.container)
        titleComponents.container.snp.makeConstraints { make in
            make.height.equalTo(Self.componentsHeights.title)
        }
        titleComponents.container.isHidden = true
        // title components: label
        titleComponents.label.textColor = UIColor.ud.textTitle
        titleComponents.label.text = I18N.Todo_Task_Comment
        titleComponents.label.font = UDFont.systemFont(ofSize: 17, weight: .medium)
        titleComponents.label.textAlignment = .left
        titleComponents.container.addSubview(titleComponents.label)
        titleComponents.label.snp.makeConstraints { make in
            make.left.lessThanOrEqualTo(titleComponents.container.snp.left).offset(16)
            make.right.greaterThanOrEqualTo(titleComponents.container.snp.right).offset(-16)
            make.top.equalToSuperview()
            make.height.equalTo(24)
        }

        // hasMore components: container
        stackView.addArrangedSubview(hasMoreComponents.container)
        hasMoreComponents.container.snp.makeConstraints { make in
            make.height.equalTo(Self.componentsHeights.hasMore)
        }
        hasMoreComponents.container.isHidden = true
        // hasMore components: button
        hasMoreComponents.button.addTarget(self, action: #selector(handleLoadMore), for: .touchUpInside)
        hasMoreComponents.button.setTitle(I18N.Todo_Task_ShowEarlierComment, for: .normal)
        hasMoreComponents.button.setTitleColor(UIColor.ud.primaryPri700, for: .normal)
        hasMoreComponents.button.titleLabel?.font = UDFont.systemFont(ofSize: 14)
        hasMoreComponents.button.titleEdgeInsets = .zero
        hasMoreComponents.container.addSubview(hasMoreComponents.button)
        hasMoreComponents.button.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(20)
            make.left.equalToSuperview().offset(16)
        }

        // loadingMore components: container
        stackView.addArrangedSubview(loadingMoreComponents.container)
        loadingMoreComponents.container.snp.makeConstraints { make in
            make.height.equalTo(Self.componentsHeights.loadingMore)
        }
        loadingMoreComponents.container.isHidden = true
        // loadingMore components: centerX
        loadingMoreComponents.container.addSubview(loadingMoreComponents.centerX)
        loadingMoreComponents.centerX.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.height.equalTo(20)
            make.left.equalToSuperview().offset(16)
        }
        // loadingMore components: label
        loadingMoreComponents.label.text = I18N.Lark_Legacy_LoadingNow
        loadingMoreComponents.label.font = UDFont.systemFont(ofSize: 14)
        loadingMoreComponents.label.textColor = UIColor.ud.textPlaceholder
        loadingMoreComponents.centerX.addSubview(loadingMoreComponents.label)
        loadingMoreComponents.label.snp.makeConstraints { make in
            make.centerY.right.equalToSuperview()
        }
        // loadingMore components: indicator
        loadingMoreComponents.centerX.addSubview(loadingMoreComponents.indicator)
        loadingMoreComponents.indicator.snp.makeConstraints { make in
            make.centerY.left.equalToSuperview()
            make.right.equalTo(loadingMoreComponents.label.snp.left).offset(-10)
            make.width.height.equalTo(16)
        }

        // loadingSketch components: container
        stackView.addArrangedSubview(loadingSketchComponents.container)
        loadingSketchComponents.container.snp.makeConstraints { make in
            make.height.equalTo(Self.componentsHeights.loadingSketch)
        }
        loadingSketchComponents.container.isHidden = true
        let cells = [
            loadingSketchComponents.firstItem,
            loadingSketchComponents.secondItem,
            loadingSketchComponents.thirdItem,
            loadingSketchComponents.forthItem
        ]
        for i in 0..<cells.count {
            loadingSketchComponents.container.addSubview(cells[i])
            cells[i].snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.top.equalToSuperview().offset(CGFloat(64 * i))
                make.height.equalTo(64)
            }
        }

        // loadFailed components: container
        stackView.addArrangedSubview(loadFailedComponents.container)
        loadFailedComponents.container.snp.makeConstraints { make in
            make.height.equalTo(Self.componentsHeights.loadFaield)
        }
        // loadFailed components: imageView
        loadFailedComponents.imageView.image = LarkUIKit.Resources.load_fail
        loadFailedComponents.imageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleRetry))
        loadFailedComponents.imageView.addGestureRecognizer(tap)
        loadFailedComponents.container.addSubview(loadFailedComponents.imageView)
        loadFailedComponents.imageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.width.height.equalTo(125)
            make.centerX.equalToSuperview()
        }
        // loadFailed components: label
        loadFailedComponents.label.text = I18N.Lark_Legacy_LoadFailedRetryTip
        loadFailedComponents.label.numberOfLines = 0
        loadFailedComponents.label.textColor = UIColor.ud.textPlaceholder
        loadFailedComponents.label.textAlignment = .center
        loadFailedComponents.label.font = UDFont.systemFont(ofSize: 14)
        loadFailedComponents.container.addSubview(loadFailedComponents.label)
        loadFailedComponents.label.snp.makeConstraints { make in
            make.top.equalTo(loadFailedComponents.imageView.snp.bottom)
            make.left.lessThanOrEqualTo(loadFailedComponents.container.snp.left).offset(16)
            make.right.greaterThanOrEqualTo(loadFailedComponents.container.snp.right).offset(-16)
            make.centerX.equalToSuperview()
        }

        stackView.addArrangedSubview(richContentComponent)
        richContentComponent.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func handleLoadMore() {
        onLoadMore?()
    }

    @objc
    private func handleRetry() {
        onRetry?()
    }

}

extension DetailCommentHeaderView {

    class RichContentView: UIView {

        var preferredMaxLayoutWidth: CGFloat = .greatestFiniteMagnitude {
            didSet {
                richLabel.preferredMaxLayoutWidth = preferredMaxLayoutWidth - 54 - 30
            }
        }

        var richContent: RichLabelContent? {
            didSet {
                richLabel.attributedText = richContent?.attrText
                setNeedsLayout()
            }
        }

        var linkRanges: [NSRange]? {
            didSet {
                richLabel.removeLKTextLink()
                guard let linkRanges = linkRanges else {
                    return
                }
                for range in linkRanges {
                    var link = LKTextLink(range: range, type: .link)
                    link.linkTapBlock = { [weak self] (_, _) in
                        guard let self = self else { return }
                        self.onTapContent?(range)
                    }
                    richLabel.addLKTextLink(link: link)
                }
            }
        }

        /// 点击内容
        var onTapContent: ((NSRange) -> Void)?

        private let iconView = UIView()
        private let richLabel = RichContentLabel()
        private let bgColors = (highlighted: UIColor.ud.fillPressed, normal: UIColor.ud.bgBody)

        private let layouts = (topPadding: CGFloat(16), bottomPadding: CGFloat(8))

        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = bgColors.normal

            iconView.isUserInteractionEnabled = true
            iconView.backgroundColor = bgColors.normal
            iconView.layer.cornerRadius = 4
            iconView.layer.borderWidth = 2
            iconView.layer.borderColor = UIColor.ud.lineBorderComponent.cgColor
            addSubview(iconView)

            richLabel.backgroundColor = .clear
            richLabel.lineSpacing = 4
            richLabel.textVerticalAlignment = .top
            richLabel.textAlignment = .left
            richLabel.numberOfLines = 0
            addSubview(richLabel)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            iconView.frame.size = CGSize(width: 8, height: 8)
            iconView.frame.center = CGPoint(x: 30, y: layouts.topPadding + 9)

            let contentMaxWidth = bounds.width - 54 - 30
            let fitsRefSize = CGSize(width: contentMaxWidth, height: .greatestFiniteMagnitude)
            richLabel.frame.top = layouts.topPadding
            richLabel.frame.left = 54
            richLabel.frame.size = richLabel.sizeThatFits(fitsRefSize)
        }

        override func sizeThatFits(_ size: CGSize) -> CGSize {
            let labelHeight = richLabel.sizeThatFits(CGSize(width: size.width - 54 - 30, height: size.height)).height
            return CGSize(width: size.width, height: labelHeight + layouts.topPadding + layouts.bottomPadding)
        }

    }

}
