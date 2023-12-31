//
//  MeetingDetailTimeHeaderComponent.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/24.
//

import Foundation
import UniverseDesignIcon
import ByteViewCommon
import ByteViewNetwork
import ByteViewUI

class MeetingDetailTimeHeaderComponent: MeetingDetailHeaderComponent {

    var timeInfoView: UIView?

    var timer: Timer?

    lazy var timeContainerView: AttachmentLabel = {
        let timeContainer = AttachmentLabel()
        timeContainer.textVerticalAlignment = .middle
        timeContainer.numberOfLines = 2
        timeContainer.lineBreakMode = .byWordWrapping
        timeContainer.lineSpacing = 0
        timeContainer.contentFont = VCFontConfig.bodyAssist.font
        timeContainer.contentParagraphStyle = {
            let lineHeight: CGFloat = VCFontConfig.bodyAssist.lineHeight
            let style = NSMutableParagraphStyle()
            style.minimumLineHeight = lineHeight
            style.maximumLineHeight = lineHeight
            return style
        }()
        timeContainer.addAttributedString(timeAttributedString)
        let size = CGSize(width: 1, height: 12)
        let line = UIView(frame: .init(origin: .zero, size: size))
        line.backgroundColor = UIColor.ud.lineDividerDefault
        timeContainer.addArrangedSubview(line) {
            $0.size = size
            $0.margin = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        }
        timeContainer.addAttributedString(durationAttributedString)
        return timeContainer
    }()

    var timeAttributedString = NSMutableAttributedString(attributedString: .init(string: "1", config: .bodyAssist, textColor: .ud.textTitle))
    var durationAttributedString = NSMutableAttributedString(attributedString: .init(string: "1", config: .bodyAssist, textColor: .ud.textTitle))

    override func setupViews() {
        super.setupViews()

        let timeView = UIStackView()
        timeView.axis = .horizontal
        timeView.spacing = 12
        timeView.alignment = .center
        timeInfoView = timeView
        addSubview(timeView)
        timeView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.height.greaterThanOrEqualTo(20)
        }

        let timeIcon = UIImageView()
        timeIcon.image = UDIcon.getIconByKey(.timeOutlined, iconColor: .ud.iconN3.dynamicColor, size: CGSize(width: 16, height: 16))
        timeView.addArrangedSubview(timeIcon)
        timeIcon.snp.makeConstraints {
            $0.width.height.equalTo(16)
        }

        timeView.addArrangedSubview(timeContainerView)
        timeContainerView.snp.makeConstraints {
            $0.height.greaterThanOrEqualTo(20)
        }

        timeContainerView.reload()
    }

    override func updateLayout() {
        super.updateLayout()
        if timeContainerView.preferredMaxLayoutWidth != timeContainerView.frame.width {
            timeContainerView.preferredMaxLayoutWidth = timeContainerView.frame.width
        }
    }

    override var shouldShow: Bool {
        guard let viewModel = viewModel else { return false }
        return !viewModel.isCall || viewModel.isValid1v1Call
    }

    override func updateViews() {
        super.updateViews()

        guard let commonInfo = viewModel?.commonInfo.value else { return }
        updateTime(commonInfo)
    }

    func updateTime(_ model: TabHistoryCommonInfo) {
        timer?.invalidate()
        if model.meetingStatus == .meetingEnd {
            let time = DateUtil.formatCalendarDateTimeRange(startTime: TimeInterval(model.startTime), endTime: TimeInterval(model.endTime))
            timeAttributedString.set(string: time)
            viewModel?.viewContext.meetingTime = time
            let duration = DateUtil.formatDuration(TimeInterval(model.endTime - model.startTime), concise: false)
            durationAttributedString.set(string: duration)
        } else {
            let time = DateUtil.formatFullDateTime(TimeInterval(model.startTime))
            timeAttributedString.set(string: time)
            viewModel?.viewContext.meetingTime = time

            let duration = DateUtil.formatDuration(Date().timeIntervalSince1970 - TimeInterval(model.startTime), concise: true)
            durationAttributedString.set(string: duration)
            timer = Timer(timeInterval: 1, repeats: true, block: { [weak self] _ in
                guard let self = self else { return }
                let duration = DateUtil.formatDuration(Date().timeIntervalSince1970 - TimeInterval(model.startTime), concise: true)
                self.durationAttributedString.set(string: duration)
                self.timeContainerView.reload()
            })
            if let timer = timer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
        timeContainerView.reload()
    }
}
