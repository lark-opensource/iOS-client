//
//  ScheduleCardView.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/7.
//

import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon
import CalendarFoundation
import UniverseDesignTag
import RxSwift
import RichLabel

class ScheduleCardView: UIView {

    private let containerInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    private let disposeBag: DisposeBag

    private lazy var titleLabel: LKLabel = {
        let label = LKLabel()
        label.backgroundColor = .clear
        label.numberOfLines = 3
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.body2
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textColor = UDColor.textTitle
        return label
    }()

    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.body2
        label.textColor = UDColor.textTitle
        return label
    }()

    private lazy var calendarCapsule = CalendarCapsule()

    private lazy var countdownView = CalendarCountdownView()

    private lazy var vcBtnContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 6
        view.backgroundColor = .clear
        return view
    }()

    init() {
        self.disposeBag = DisposeBag()
        super.init(frame: .zero)
        self.backgroundColor = .clear
        setupView()
    }

    private func setupView() {
        self.addSubview(titleLabel)
        self.addSubview(timeLabel)
        self.addSubview(locationLabel)
        self.addSubview(calendarCapsule)
        self.addSubview(countdownView)
        self.addSubview(vcBtnContainer)

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(containerInsets)
            make.height.lessThanOrEqualTo(72)
            make.top.equalTo(calendarCapsule.snp.bottom).offset(12)
        }
        timeLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(containerInsets)
            make.top.equalTo(titleLabel.snp.bottom).offset(6)
        }
        locationLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(containerInsets)
            make.top.equalTo(timeLabel.snp.bottom)
        }
        calendarCapsule.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().inset(containerInsets)
        }
        countdownView.snp.makeConstraints { make in
            make.trailing.top.equalToSuperview().inset(containerInsets)
            make.height.equalTo(18)
        }
        vcBtnContainer.snp.makeConstraints { make in
            make.top.equalTo(locationLabel.snp.bottom).offset(12)
            make.leading.bottom.equalToSuperview().inset(containerInsets)
            make.height.equalTo(36)
            make.trailing.lessThanOrEqualToSuperview().inset(containerInsets)
        }
    }

    func setModel(viewModel: ScheduleCardViewModel, vc: UIViewController, width: CGFloat) {
        let model = viewModel.model
        self.titleLabel.preferredMaxLayoutWidth = width
        self.titleLabel.attributedText = generateTitle(title: model.baseModel.summary, tagString: model.tag)
        self.titleLabel.outOfRangeText = generateOutOfRangeText(tagString: model.tag)
        self.timeLabel.text = model.baseModel.rangeTime
        self.locationLabel.text = model.baseModel.location
        createVCBtn(viewModel: viewModel)
        if model.remainingTime <= 0 {
            self.countdownView.backgroundColor = UDColor.udtokenTagBgGreen
            self.countdownView.setText(text: BundleI18n.Calendar.Lark_Event_EventInProgress_Status,
                                       color: UDColor.udtokenTagTextSGreen)
        } else {
            self.countdownView.backgroundColor = UDColor.udtokenTagBgBlue
            self.countdownView.setText(text: BundleI18n.Calendar.Lark_Event_NumMinLater_Text(number: Int(ceil(Double(model.remainingTime) / 60.0))),
                                       color: UDColor.udtokenTagTextSBlue)
        }
    }

    private func createVCBtn(viewModel: ScheduleCardViewModel) {
        self.vcBtnContainer.btd_removeAllSubviews()
        switch viewModel.model.btnModel {
        case .vcBtn(let model):
            let vcBtn = viewModel.todayEventDependency.createEventCardVCButton(model)
            self.vcBtnContainer.addSubview(vcBtn)
            vcBtn.snp.makeConstraints { $0.edges.equalToSuperview() }
            vcBtnContainer.snp.updateConstraints { make in
                make.bottom.equalToSuperview().inset(containerInsets)
                make.height.equalTo(36)
            }
        case .otherBtn(let btnManager):
            if btnManager.rxShowOtherVCBtn.value {
                let vcBtn = OtherVideoMeetingBtn(summary: btnManager.btnSummary,
                                                 isLinkAvaliable: btnManager.isLinkAvaliable)
                self.vcBtnContainer.addSubview(vcBtn)
                vcBtn.snp.makeConstraints {
                    $0.edges.equalToSuperview()
                }
                vcBtn.rx.tap
                    .subscribeOn(MainScheduler.instance)
                    .subscribe(onNext: { (_) in
                        btnManager.tapVideoMeetingBtn()
                    }).disposed(by: disposeBag)
                self.vcBtnContainer.snp.updateConstraints { make in
                    make.top.equalTo(self.locationLabel.snp.bottom).offset(12)
                    make.bottom.equalToSuperview().inset(self.containerInsets)
                    make.height.equalTo(36)
                }
            } else {
                self.vcBtnContainer.snp.updateConstraints { make in
                    make.top.equalTo(self.locationLabel.snp.bottom).offset(self.containerInsets.bottom)
                    make.bottom.equalToSuperview()
                    make.height.equalTo(0)
                }
            }
        }
    }

    private func generateTitle(title: String, tagString: String?) -> NSAttributedString {
        var attributes: [NSAttributedString.Key : Any] = [:]
        attributes[NSAttributedString.Key.font] = UDFont.headline
        attributes[NSAttributedString.Key.foregroundColor] = UDColor.textTitle
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 24
        attributes[NSAttributedString.Key.paragraphStyle] = style

        let attributedString = NSMutableAttributedString(string: title, attributes: attributes)
        if let tagString = tagString {
            attributedString.append(generateAttachment(tagString: tagString))
        }
        return attributedString
    }

    private func generateOutOfRangeText(tagString: String?) -> NSAttributedString {
        var attributes: [NSAttributedString.Key : Any] = [:]
        attributes[NSAttributedString.Key.font] = UDFont.headline
        attributes[NSAttributedString.Key.foregroundColor] = UDColor.textTitle
        let attributedString = NSMutableAttributedString(string: "...", attributes: attributes)
        if let tagString = tagString {
            attributedString.append(generateAttachment(tagString: tagString))
        }
        return attributedString
    }

    private func generateAttachment(tagString: String) -> NSAttributedString {
        let tagAttributes = [NSAttributedString.Key.font: UDFont.caption0]
        var size = NSAttributedString(string: tagString, attributes: tagAttributes)
            .boundingRect(with: CGSize(width: 1000, height: 18), context: nil).size
        size.width += 10
        size.height = 18
        let attachment = LKAsyncAttachment(viewProvider: {
            let tag = UDTag()
            tag.sizeClass = .mini
            tag.colorScheme = .blue
            tag.text = tagString
            return tag
        }, size: size)
        attachment.margin = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 0)
        attachment.fontAscent = UDFont.caption0.ascender
        attachment.fontDescent = UDFont.caption0.descender
        attachment.size = size
        return NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                  attributes: [LKAttachmentAttributeName: attachment])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
