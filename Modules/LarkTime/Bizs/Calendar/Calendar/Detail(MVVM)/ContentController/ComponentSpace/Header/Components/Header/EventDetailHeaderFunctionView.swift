//
//  EventDetailHeaderView.swift
//  Calendar
//
//  Created by Rico on 2021/3/19.
//

import UIKit
import CalendarFoundation
import LarkUIKit
import RxCocoa
import RxSwift
import LarkTag
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignTag

struct DetailHeaderTextTagConfig {
    var showTag: Bool
    var text: String
    var backgroundColor: UIColor = UDColor.primaryOnPrimaryFill.withAlphaComponent(0.2)
    var textColor: UIColor = UIColor.ud.primaryOnPrimaryFill
}

protocol EventDetailHeaderViewDataType: EventHeaderButtonViewDataType {
    var titleColor: UIColor { get }
    var markerColor: UIColor { get }
    var relationTagColor: (UIColor, UIColor) { get } // backgroundColor, textColor
    var relationTagStr: String? { get }
    var title: String { get }
    var startTime: Date { get }
    var endTime: Date { get }
    var isAllDay: Bool { get }
    var rruleText: String? { get }
    var isShowChat: Bool { get }
    var isShowDocs: Bool { get }
    var is12HourStyle: Bool { get }
    var webinarTag: DetailHeaderTextTagConfig? { get }
}

extension EventDetailHeaderViewDataType {
    func isShowButtons() -> Bool {
        return isShowChat || isShowDocs
    }
}

protocol EventDetailHeaderFunctionViewDelegate: AnyObject {
    func headerView(_ headerview: EventDetailHeaderView, didTappedButton buttonType: EventDetailHeaderView.TappedButtonType)
    func headerView(_ headerView: EventDetailHeaderView, didTappedText text: String)
}

final class EventDetailHeaderView: UIView, ViewDataConvertible {

    enum TappedButtonType {
        case chat
        case doc
    }

    var didLayout: ((CGFloat) -> Void)?
    weak var delegate: EventDetailHeaderFunctionViewDelegate?

    private let topMargin = 14  // 为了满足距离顶部导航栏 24
    private let bottomMargin = 26  // 为了满足 detailTable 上方 view 的距离：header 展开时 30，header 收起时距 navbar 24

    init(isPushStyle: Bool = true) {
        super.init(frame: .zero)
        layoutUI()
    }

    @objc
    private func titleTaped() {
        guard let text = self.titleLabel.text, self.titleLabel.isTruncated else {
            return
        }
        self.delegate?.headerView(self, didTappedText: text)
        CalendarTracer.shareInstance.calDetailMore(elementType: .title)
    }

    @objc
    private func rrlueTaped() {
        guard let text = self.rruleLabel.text, self.rruleLabel.isTruncated else {
            return
        }
        self.delegate?.headerView(self, didTappedText: text)
        CalendarTracer.shareInstance.calDetailMore(elementType: ._repeat)
    }

    func transfromToOpaque(with progress: CGFloat) {
        let _titleAlpha = 1 - progress
        let titleAlpha = _titleAlpha < 0 ? 0 : _titleAlpha
        self.titleLabel.alpha = titleAlpha

        let _timeAlpha = 1.0 - progress / 3.5
        let timeAlpha = _timeAlpha < 0 ? 0 : _timeAlpha
        self.timeLabel.alpha = timeAlpha
        self.rruleLabel.alpha = timeAlpha
    }

    var viewData: EventDetailHeaderViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            self.updateTagView(with: viewData)
            self.markerBlock.backgroundColor = viewData.markerColor
            self.titleLabel.textColor = viewData.titleColor
            self.timeLabel.textColor = viewData.titleColor
            self.rruleLabel.textColor = viewData.titleColor
            titleLabel.text = viewData.title
            timeLabel.setTimeString(startTime: viewData.startTime,
                                    endTime: viewData.endTime,
                                    isAllday: viewData.isAllDay,
                                    is12HourStyle: viewData.is12HourStyle)
            titleLabel.tryFitFoFigmaLineHeight()
            timeLabel.tryFitFoFigmaLineHeight()
            headerButtonCombo.isHidden = !viewData.isShowButtons()
            if !headerButtonCombo.isHidden {
                headerButtonCombo.viewData = viewData
            }
            if let rruleText = viewData.rruleText {
                rruleLabel.isHidden = false
                rruleLabel.text = rruleText
                rruleLabel.tryFitFoFigmaLineHeight()
            } else {
                rruleLabel.isHidden = true
            }
            setNeedsLayout()
        }
    }

    private func updateTagView(with viewData: EventDetailHeaderViewDataType) {
        tagWrapper.clearSubviews()
        if let webinarTag = viewData.webinarTag, webinarTag.showTag {
            let tagView = generateTagView(text: webinarTag.text,
                                          textColor: webinarTag.textColor,
                                          backgroundColor: webinarTag.backgroundColor)
            tagWrapper.addArrangedSubview(tagView)
        }

        if let relationTagStr = viewData.relationTagStr {
            let (tagBackgroundColor, tagTextColor) = viewData.relationTagColor
            let tagView = generateTagView(text: relationTagStr,
                                          textColor: tagTextColor,
                                          backgroundColor: tagBackgroundColor)
            tagWrapper.addArrangedSubview(tagView)
        }

        EventDetail.logInfo("show tag count: \(tagWrapper.subviews.count)")

        if tagWrapper.subviews.isEmpty {
            tagWrapper.isHidden = true
            contentView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(topMargin)
            }
        } else {
            tagWrapper.isHidden = false
            contentView.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(topMargin + 28)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.didLayout?(self.bounds.height)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var tagWrapper: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        return stack
    }()

    private let titleLabel: CopyableLabel = {
        let label = CopyableLabel(isCopyable: true) {
            CalendarTracer.shareInstance.calDetailCopy(elementType: .title)
        }
        label.numberOfLines = 2
        label.textColor = UDColor.primaryPri700
        label.font = UDFont.title2(.fixed)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let timeLabel: CATimeFormatterLabel = {
        let label = CATimeFormatterLabel(isOneLine: false, isCopyable: true) {
            CalendarTracer.shareInstance.calDetailCopy(elementType: .time)
        }
        label.font = UDFont.body0(.fixed)
        label.textColor = UDColor.primaryPri700
        return label
    }()

    private let rruleLabel: CopyableLabel = {
        let label = CopyableLabel(isCopyable: true) {
            CalendarTracer.shareInstance.calDetailCopy(elementType: ._repeat)
        }
        label.font = UDFont.body0(.fixed)
        label.textColor = UDColor.primaryPri400
        label.numberOfLines = 2
        return label
    }()

    private lazy var chatAndDocsWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    private lazy var headerButtonCombo: HeaderButtonComboView = {
        let view = HeaderButtonComboView()
        view.delegate = self
        return view
    }()

    private lazy var markerBlock: UIView = {
        let block = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 14))
        block.backgroundColor = UDColor.primaryPri400
        block.layer.cornerRadius = 4
        block.layer.masksToBounds = true
        return block
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .fill
        stack.distribution = .fill
        stack.axis = .vertical
        return stack
    }()

    private lazy var eventInfoStack: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .fill
        stack.distribution = .fill
        stack.axis = .vertical
        return stack
    }()

    // 包含两个子 view ： markerBlock 和 contentStack
    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()
}

// MARK: - Layout
extension EventDetailHeaderView {

    // view: tagWrapper, contentView
    // | - contentView: markerBlock, contentStack
    //   | - contentStack: eventInfoStack, headerButtonCombo

    private func layoutUI() {

        addSubview(tagWrapper)
        tagWrapper.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(topMargin)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.height.equalTo(18)
        }

        tagWrapper.isHidden = true

        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(topMargin) // tag 存在时是 topMargin + 28, 28 是 tag 高度 + 间距
            make.bottom.equalToSuperview().inset(bottomMargin)
        }

        contentView.addSubview(markerBlock)
        markerBlock.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8) // offset 是为了跟 title 第一行竖直居中对齐
            make.left.equalToSuperview()
            make.width.height.equalTo(14)
        }

        contentView.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.top.right.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(32)
        }

        contentStack.spacing = 12
        contentStack.addArrangedSubview(eventInfoStack)
        contentStack.addArrangedSubview(headerButtonCombo)

        eventInfoStack.spacing = 4
        eventInfoStack.addArrangedSubview(titleLabel)
        eventInfoStack.addArrangedSubview(timeLabel)
        eventInfoStack.setCustomSpacing(0, after: timeLabel)
        eventInfoStack.addArrangedSubview(rruleLabel)

        headerButtonCombo.snp.makeConstraints { make in
            make.height.equalTo(28)
        }

        let titleLabelGesture = UITapGestureRecognizer(target: self, action: #selector(titleTaped))
        titleLabel.addGestureRecognizer(titleLabelGesture)

        let rruleLabelGesture = UITapGestureRecognizer(target: self, action: #selector(rrlueTaped))
        rruleLabel.addGestureRecognizer(rruleLabelGesture)
    }
}

extension EventDetailHeaderView: HeaderButtonComboDelegate {
    func chatEntranceTapped(_ gustrue: UITapGestureRecognizer) {
        self.delegate?.headerView(self, didTappedButton: .chat)
    }

    func meetingMinutesTapped() {
        self.delegate?.headerView(self, didTappedButton: .doc)
    }
}

extension EventDetailHeaderView {
    func generateTagView(text: String, textColor: UIColor, backgroundColor: UIColor) -> UIView {
        let style = Style(textColor: textColor, backColor: backgroundColor)
        return TagWrapperView.titleTagView(for: Tag(title: text,
                                                    image: nil,
                                                    style: style,
                                                    type: .customTitleTag))
    }
}
