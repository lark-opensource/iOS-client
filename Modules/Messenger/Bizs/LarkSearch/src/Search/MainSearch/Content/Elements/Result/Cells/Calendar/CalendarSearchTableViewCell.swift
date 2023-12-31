//
//  CalendarSearchTableViewCell.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/9/5.
//

import Foundation
import UIKit
import RustPB
import LarkModel
import LarkCore
import SnapKit
import LarkUIKit
import LarkSearchCore
import LarkAccountInterface
import LarkMessengerInterface
import ByteWebImage
import LKCommonsLogging
import LarkSDKInterface
import LarkListItem
import LarkTimeFormatUtils
import LarkContainer

final class CalendarSearchDayTitleTableViewCell: UITableViewCell, SearchTableViewCellProtocol {
    var viewModel: SearchCellViewModel?

    let containerGuide = UILayoutGuide()

    let dayBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    let dayLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
        label.textAlignment = .center
        return label
    }()

    let yearAndMonthLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    let weekdayLebel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    let bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        isUserInteractionEnabled = false
        contentView.addLayoutGuide(containerGuide)
        contentView.addSubview(bgView)
        bgView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        bgView.addSubview(dayBackgroundView)
        bgView.addSubview(dayLabel)
        bgView.addSubview(yearAndMonthLabel)
        bgView.addSubview(weekdayLebel)
        containerGuide.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(42)
        }
        dayLabel.snp.remakeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.height.equalTo(28)
            make.top.equalToSuperview().offset(8)
        }
        dayBackgroundView.snp.remakeConstraints { make in
            make.center.equalTo(dayLabel.snp.center)
            make.size.equalTo(CGSize(width: 30, height: 30))
        }
        weekdayLebel.snp.makeConstraints { make in
            make.centerY.equalTo(dayLabel.snp.centerY)
            make.trailing.equalToSuperview().offset(-16)
        }
        yearAndMonthLabel.snp.makeConstraints { make in
            make.centerY.equalTo(dayLabel.snp.centerY)
            make.leading.equalTo(dayLabel.snp.trailing).offset(12)
            make.trailing.lessThanOrEqualTo(weekdayLebel.snp.leading).offset(-7)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupTextColor(isToday: Bool) {
        dayBackgroundView.backgroundColor = isToday ? UIColor.ud.B500 : nil
        dayBackgroundView.layer.cornerRadius = 30.0 / 2
        dayLabel.textColor = isToday ? UIColor.ud.staticWhite : UIColor.ud.textTitle
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        dayLabel.text = nil
        yearAndMonthLabel.text = nil
        weekdayLebel.text = nil
    }

    func set(viewModel: SearchCellViewModel, currentAccount: LarkAccountInterface.User?, searchText: String?) {
        guard let dayTitleModel = viewModel as? CalendarSearchDayTitleViewModel else {
            return
        }
        self.viewModel = viewModel
        let renderDataModel = dayTitleModel.renderDataModel

        setupTextColor(isToday: renderDataModel.crossDayStartIsToday ?? false)
        if let crossDayStartDate = renderDataModel.crossDayStartDate {
            dayLabel.text = "\(crossDayStartDate.day)"
            yearAndMonthLabel.text = crossDayStartDate.lf.formatedOnlyDateWithoutDay()
            weekdayLebel.text = TimeFormatUtils.weekdayShortString(weekday: crossDayStartDate.weekday)
        }
        dayLabel.sizeToFit()
        yearAndMonthLabel.sizeToFit()
        weekdayLebel.sizeToFit()
        if needShowDividerStyle() {
            updateToPadStyle()
        } else {
            updateToMobobileStyle()
        }
    }

    private func updateToPadStyle() {
        self.backgroundColor = UIColor.ud.bgBase
        bgView.backgroundColor = UIColor.ud.bgBody
    }

    private func updateToMobobileStyle() {
        self.backgroundColor = UIColor.ud.bgBody
        bgView.backgroundColor = UIColor.clear
    }

    private func needShowDividerStyle() -> Bool {
        if let support = viewModel?.supprtPadStyle() {
            return support
        }
        return false
    }
}

final class CalendarSearchDividingLineTableViewCell: UITableViewCell, SearchTableViewCellProtocol {
    var viewModel: SearchCellViewModel?

    let containerGuide = UILayoutGuide()

    let lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    let bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        view.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        isUserInteractionEnabled = false
        contentView.addLayoutGuide(containerGuide)
        contentView.addSubview(lineView)
        containerGuide.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(10)
        }
        lineView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo((UIScreen.main.scale >= 3 ? 0.75 : 0.5))
        }
        contentView.addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.height.equalTo(10)
            make.leading.trailing.top.equalToSuperview()
        }
        bgView.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(viewModel: SearchCellViewModel, currentAccount: LarkAccountInterface.User?, searchText: String?) {
        self.viewModel = viewModel
        if needShowDividerStyle() {
            updateToPadStyle()
        } else {
            updateToMobobileStyle()
        }
    }

    private func updateToPadStyle() {
        self.backgroundColor = UIColor.ud.bgBase
        bgView.isHidden = false
        lineView.isHidden = true
        containerGuide.snp.updateConstraints { make in
            make.height.equalTo(22)
        }
    }

    private func updateToMobobileStyle() {
        self.backgroundColor = UIColor.ud.bgBody
        bgView.isHidden = true
        lineView.isHidden = false
        containerGuide.snp.updateConstraints { make in
            make.height.equalTo(10)
        }
    }

    private func needShowDividerStyle() -> Bool {
        if let support = viewModel?.supprtPadStyle() {
            return support
        }
        return false
    }

}

final class CalendarSearchTableViewCell: UITableViewCell, SearchTableViewCellProtocol {
    static let logger = Logger.log(CalendarSearchTableViewCell.self, category: "Module.IM.Search")
    var viewModel: SearchCellViewModel?
    let containerGuide = UILayoutGuide()

    let pointView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        return view
    }()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        return label
    }()

    let extraInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    let timeRangeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    let creatorNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    let dividerImageView1: UIImageView = UIImageView()
    let dividerImageView2: UIImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectedBackgroundView = SearchCellSelectedView()
        descriptionLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        descriptionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        contentView.addLayoutGuide(containerGuide)
        contentView.addSubview(pointView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(extraInfoStackView)
        let image: UIImage = getVerticalLineImage()
        dividerImageView1.image = image
        dividerImageView2.image = image
        dividerImageView1.isHidden = true
        dividerImageView2.isHidden = true
        extraInfoStackView.addArrangedSubview(timeRangeLabel)
        extraInfoStackView.addArrangedSubview(dividerImageView1)
        extraInfoStackView.addArrangedSubview(creatorNameLabel)
        extraInfoStackView.addArrangedSubview(dividerImageView2)
        extraInfoStackView.addArrangedSubview(descriptionLabel)
        containerGuide.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(40 + 6 * 2)
        }
        pointView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 8, height: 8))
            make.leading.equalToSuperview().offset(36)
            make.top.equalToSuperview().offset(6 + 6)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(pointView.snp.trailing).offset(8)
            make.centerY.equalTo(pointView)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(20)
        }
        extraInfoStackView.snp.makeConstraints { make in
            make.leading.height.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
            make.trailing.lessThanOrEqualTo(titleLabel.snp.trailing)
        }
        dividerImageView1.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 9, height: 10))
        }
        dividerImageView2.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 9, height: 10))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(viewModel: SearchCellViewModel, currentAccount: LarkAccountInterface.User?, searchText: String?) {
        guard let calendarModel = viewModel as? CalendarSearchViewModel else {
            return
        }
        self.viewModel = viewModel

        let renderDataModel = calendarModel.renderDataModel

        pointView.backgroundColor = calendarModel.pointColor

        let isInPast = renderDataModel.crossDayEndDate?.isInPast ?? true
        if let summary = renderDataModel.summary, !summary.isEmpty {
            var titleStr: String = summary
            if let crossDaySum = renderDataModel.crossDaySum,
               let crossDayNo = renderDataModel.crossDayNo,
               crossDaySum > 1, crossDayNo >= 1 {
                titleStr += BundleI18n.LarkSearch.Calendar_View_AlldayInfo(crossDayNo, crossDaySum)
            }
            titleLabel.textColor = isInPast ? UIColor.ud.textPlaceholder : UIColor.ud.textTitle
            let attributedText = SearchAttributeString(searchHighlightedString: titleStr).attributeText
            titleLabel.attributedText = attributedText
        } else {
            let attributedText = SearchAttributeString(searchHighlightedString: BundleI18n.LarkSearch.Calendar_Common_NoTitle).attributeText
            titleLabel.textColor = isInPast ? UIColor.ud.textPlaceholder : UIColor.ud.textTitle
            titleLabel.attributedText = attributedText
        }

        let textColor = isInPast ? UIColor.ud.textPlaceholder : UIColor.ud.textCaption
        if renderDataModel.isAllDay ?? false {
            timeRangeLabel.text = BundleI18n.LarkSearch.Calendar_TimeFormat_Allday
        } else if let startDate = renderDataModel.crossDayStartDate, let endDate = renderDataModel.crossDayEndDate {
            func hourAndMinuteStr(date: Date) -> String {
                let hour: Int = date.hour
                let minute: Int = date.minute
                return (hour >= 10 ? "" : "0") + "\(hour)" + ":" + (minute >= 10 ? "" : "0") + "\(minute)"
            }
            timeRangeLabel.text = hourAndMinuteStr(date: startDate)
                                  + "-" +
                                  hourAndMinuteStr(date: endDate)
        }
        timeRangeLabel.sizeToFit()
        timeRangeLabel.isHidden = timeRangeLabel.text.isEmpty
        timeRangeLabel.textColor = textColor

        var organizerStr: String = ""
        if let organizer = renderDataModel.organizer, !organizer.isEmpty {
            organizerStr = BundleI18n.LarkSearch.Lark_Search_TopResults_EventsSection_EventInfoOrganizer
                        + BundleI18n.LarkSearch.Calendar_Common_colon
                        + organizer
        } else if let creator = renderDataModel.creator, !creator.isEmpty {
            organizerStr = BundleI18n.LarkSearch.Calendar_Detail_Creator
                        + BundleI18n.LarkSearch.Calendar_Common_colon
                        + creator
        }
        if !organizerStr.isEmpty {
            creatorNameLabel.textColor = textColor
            let attributedText = SearchAttributeString(searchHighlightedString: organizerStr).attributeText
            creatorNameLabel.attributedText = attributedText
            creatorNameLabel.isHidden = false
            creatorNameLabel.sizeToFit()
            dividerImageView1.isHidden = false
        }

        var descriptionStr: String = ""
        let chatName = renderDataModel.chatName ?? ""
        let attendee = renderDataModel.attendee ?? ""
        if let resource = renderDataModel.resource, !resource.isEmpty {
            descriptionStr = BundleI18n.LarkSearch.Lark_Search_TopResults_EventsSection_EventInfoMeetingRoom
                             + BundleI18n.LarkSearch.Calendar_Common_colon
                             + resource
        } else if !chatName.isEmpty || !attendee.isEmpty {
            descriptionStr = BundleI18n.LarkSearch.Lark_Search_TopResults_EventsSection_EventInfoParticipants
                             + BundleI18n.LarkSearch.Calendar_Common_colon
            descriptionStr += chatName
            descriptionStr += chatName.isEmpty ? "" : ","
            descriptionStr += attendee
        } else if let description = renderDataModel.description, !descriptionStr.isEmpty {
            descriptionStr = BundleI18n.LarkSearch.Lark_Search_TopResults_EventsSection_EventInfoDescription
                             + BundleI18n.LarkSearch.Calendar_Common_colon
                             + description
        }

        if !descriptionStr.isEmpty {
            descriptionLabel.textColor = textColor
            let attributedText = SearchAttributeString(searchHighlightedString: descriptionStr).attributeText
            descriptionLabel.attributedText = attributedText
            descriptionLabel.isHidden = false
            descriptionLabel.sizeToFit()
            dividerImageView2.isHidden = false
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        titleLabel.attributedText = nil
        timeRangeLabel.text = nil
        timeRangeLabel.isHidden = true
        dividerImageView1.isHidden = true
        creatorNameLabel.text = nil
        creatorNameLabel.attributedText = nil
        creatorNameLabel.isHidden = true
        dividerImageView2.isHidden = true
        descriptionLabel.text = nil
        descriptionLabel.isHidden = true
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateCellStyle(animated: animated)
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        updateCellStyle(animated: animated)
    }

    override func layoutSubviews() {
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6))
        self.selectedBackgroundView?.frame = frame
        self.selectedBackgroundView?.layer.cornerRadius = 8
    }

    private func getVerticalLineImage() -> UIImage {
         let containerView = UIView()
         containerView.frame = CGRect(x: 0, y: 0, width: 9, height: 10)
         let view = UIView()
         view.frame = CGRect(x: 5, y: 0, width: 1, height: 10)
         view.backgroundColor = UIColor.ud.lineDividerDefault
         containerView.addSubview(view)
         UIGraphicsBeginImageContextWithOptions(containerView.frame.size, false, 0)
         guard let context = UIGraphicsGetCurrentContext() else {
             return UIImage()
         }
         containerView.layer.render(in: context)
         let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
         UIGraphicsEndImageContext()
         return image
     }
}
