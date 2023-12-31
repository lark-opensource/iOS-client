//
//  DetailGanttView.swift
//  Todo
//
//  Created by wangwanxin on 2023/6/12.
//

import CTFoundation
import UniverseDesignIcon
import UniverseDesignFont

struct DetailGanttViewData {
    var isMilestone: Bool = false
    var preTaskCount: Int?
    var nextTaskCount: Int?
    var isCompleted: Bool = false
}

final class DetailGanttView: UIView, ViewDataConvertible {

    var onTapPreItem: (() -> Void)? {
        didSet { preView.onTapItem = onTapPreItem }
    }

    var onTapNextItem: (() -> Void)? {
        didSet { nextView.onTapItem = onTapNextItem }
    }

    var viewData: DetailGanttViewData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            if viewData.isMilestone {
                milestoneView.isHidden = false
                milestoneView.backgroundColor = UIColor.ud.R50
                milestoneView.viewData = {
                    var data = DetailGanttContentItemViewData()
                    let icon = UDIcon.getIconByKey(
                        .taskMilestoneFilled,
                        renderingMode: .automatic,
                        iconColor: UIColor.ud.udtokenTagTextSRed,
                        size: Config.iconSize
                    )
                    data.icon = icon
                    data.text = I18N.Todo_GanttView_Milestone_Button
                    data.textColor = UIColor.ud.udtokenTagTextSRed
                    return data
                }()
            } else {
                milestoneView.isHidden = true
            }
            if let preCount = viewData.preTaskCount, preCount > 0 {
                preView.isHidden = false
                preView.backgroundColor = UIColor.ud.udtokenTagBgGreen
                preView.viewData = {
                    var data = DetailGanttContentItemViewData()
                    let icon = UDIcon.getIconByKey(
                        .taskPreliminaryOutlined,
                        renderingMode: .automatic,
                        iconColor: UIColor.ud.G500,
                        size: Config.iconSize
                    )
                    data.icon = icon
                    data.text = I18N.Todo_GanttView_BlockedByNum_Button(preCount)
                    data.textColor = UIColor.ud.G500
                    return data
                }()
            } else {
                preView.isHidden = true
            }

            let nextBgColor: UIColor ,nextContentColor: UIColor
            if viewData.isCompleted {
                nextBgColor = UIColor.ud.udtokenTagBgGreen
                nextContentColor = UIColor.ud.G500
            } else {
                nextBgColor = UIColor.ud.udtokenTagBgOrange
                nextContentColor = UIColor.ud.O600
            }

            if let nextCount = viewData.nextTaskCount, nextCount > 0 {
                nextView.isHidden = false
                nextView.backgroundColor = nextBgColor
                nextView.viewData = {
                    var data = DetailGanttContentItemViewData()
                    let icon = UDIcon.getIconByKey(
                        .taskFollowUpOutlined,
                        renderingMode: .automatic,
                        iconColor: nextContentColor,
                        size: Config.iconSize
                    )
                    data.icon = icon
                    data.text = viewData.isCompleted ?
                    I18N.Todo_Tasks_BlockingNum_AfterCompletetion_Button(nextCount) :
                    I18N.Todo_GanttView_BlockingNum_Button(nextCount)
                    data.textColor = nextContentColor
                    return data
                }()
            } else {
                nextView.isHidden = true
            }
        }
    }

    private lazy var scrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private lazy var stackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Config.ItemSpace
        stackView.alignment = .center
        return stackView
    }()

    private lazy var milestoneView = DetailGanttContentItemView()
    private lazy var preView = DetailGanttContentItemView()
    private lazy var nextView = DetailGanttContentItemView()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(scrollView)
        scrollView.addSubview(stackView)

        stackView.addArrangedSubview(milestoneView)
        stackView.addArrangedSubview(preView)
        stackView.addArrangedSubview(nextView)

        scrollView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Config.hSpace)
            make.right.equalToSuperview().offset(-Config.hSpace)
            make.top.bottom.equalToSuperview()
        }
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


}

extension DetailGanttView {

    struct Config {
        static let ItemSpace = 11.0
        static let hSpace = 16.0
        static let iconSize = CGSize(width: 12, height: 12)
    }

}

struct DetailGanttContentItemViewData {
    var icon: UIImage?
    var text: String?
    var textColor: UIColor = UIColor.ud.textTitle
}

final class DetailGanttContentItemView: UIView {

    var onTapItem: (() -> Void)?

    var viewData: DetailGanttContentItemViewData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            iconView.image = viewData.icon
            label.text = viewData.text
            label.textColor = viewData.textColor
        }
    }

    private lazy var iconView = UIImageView()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 12.0, weight: .regular)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        isHidden = true
        layer.cornerRadius = Config.radius
        layer.masksToBounds = true
        addSubview(iconView)
        addSubview(label)
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Config.leftPadding)
            make.size.equalTo(Config.iconSize)
            make.centerY.equalToSuperview()
        }
        label.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(Config.iconTextSpace)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-Config.rightPadding)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapContent))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        var width = Config.leftPadding + Config.iconSize.width + Config.rightPadding
        width += Config.iconTextSpace + label.systemLayoutSizeFitting(.zero).width
        return CGSize(width: width, height: Config.height)
    }

    @objc
    private func tapContent() {
        onTapItem?()
    }

    struct Config {
        static let leftPadding = 4.0
        static let rightPadding = 4.0
        static let iconTextSpace = 4.0
        static let iconSize = CGSize(width: 12.0, height: 12.0)
        static let height = 26.0
        static let radius = 4.0
    }
}
