//
//  MailOOOSettingCell.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/2/25.
//

import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import UniverseDesignSwitch
import UniverseDesignCheckBox
import UniverseDesignFont

protocol MailOOOSettingCellDelegate: AnyObject {
    func enableSwitchChange(_ enable: Bool)
}

protocol MailOOOSettingDateCellDelegate: AnyObject {
    var calendarProvider: CalendarProxy? { get }
    func didClickedStartTime()
    func didClickedEndTime()
}

class MailOOOSettingSwitchCell: UITableViewCell {

    weak var delegate: MailOOOSettingCellDelegate?
    /// 标题
    private let titleLabel = UILabel()
    /// 开关
//    lazy var switchButton: UISwitch = UISwitch()
    private lazy var switchButton: UDSwitch = UDSwitch()
    var switchBtnObserver: Observable<Bool> {
        return switchBtnSubject
    }
    private var switchBtnSubject: PublishSubject<Bool> = PublishSubject<Bool>()

    var disposeBag = DisposeBag()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        switchButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(switchButton)
        switchButton.valueChanged = { [weak self] value in
            self?.switchButtonClicked(value: value)
        }
        switchButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }

        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .left
        contentView.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.left.equalToSuperview().offset(16)
            make.right.lessThanOrEqualTo(switchButton.snp.left).offset(-16)
            make.bottom.equalToSuperview().offset(-16)
        }
//        observer = switchButton.rx.isSelected
        contentView.backgroundColor = UIColor.ud.bgFloat
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCellInfo(title: String, status: Bool) {
        titleLabel.text = title
        switchButton.setOn(status, animated: true, ignoreValueChanged: true)
    }

//    func setCellInfo(title: String) {
//        titleLabel.text = title
//    }
//
//    func setCellInfo(title: String, selected: BehaviorRelay<Bool>) {
//        titleLabel.text = title
////        _ = switchButton.rx.value <-> selected
//    }

    func switchButtonClicked(value: Bool) {
        delegate?.enableSwitchChange(value)
        switchBtnSubject.onNext(value)
    }
}

class MailOOOSettingDateCell: UITableViewCell {

    var disposeBag = DisposeBag()
//    private var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: nil, action: nil)

    lazy var rangeView: MailOOOTimeView = {
        let timeView = MailOOOTimeView(startTime: Date(), endTime: Date(), calendarProvider: delegate?.calendarProvider)
        return timeView
    }()

    private let beginTimeControl = MailOOOTimeItemView()
    private let endTimeControl = MailOOOTimeItemView()
    private let slashView = MailSlashView()
    private lazy var icon = UIImageView()

    weak var delegate: MailOOOSettingDateCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        contentView.addSubview(slashView)
        slashView.snp.makeConstraints { (make) in
            make.centerX.centerY.equalToSuperview()
            make.height.equalTo(24)
            make.width.equalTo(8)
        }

        contentView.addSubview(beginTimeControl)
        beginTimeControl.addTarget(self, action: #selector(beginTimeControlTaped), for: .touchUpInside)
        beginTimeControl.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.right.equalTo(slashView.snp.left)
        }

        contentView.addSubview(endTimeControl)
        endTimeControl.addTarget(self, action: #selector(endTimeControlTaped), for: .touchUpInside)
        endTimeControl.snp.makeConstraints { (make) in
            make.right.top.bottom.equalToSuperview()
            make.left.equalTo(slashView.snp.right)
        }

        contentView.backgroundColor = UIColor.ud.bgFloat
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        let bgColor = highlighted ? UIColor.ud.udtokenBtnSeBgNeutralPressed : UIColor.ud.bgFloat
        contentView.backgroundColor = bgColor
        beginTimeControl.backgroundColor = bgColor
        endTimeControl.backgroundColor = bgColor
    }

    @objc
    func beginTimeControlTaped() {
        delegate?.didClickedStartTime()
    }

    @objc
    func endTimeControlTaped() {
        delegate?.didClickedEndTime()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCellInfo(startTime: Date, endTime: Date) {
        beginTimeControl.setDate(startTime, calendarProvider: delegate?.calendarProvider)
        endTimeControl.setDate(endTime, calendarProvider: delegate?.calendarProvider)
    }
}

class MailOOOSettingIconCell: UITableViewCell {

    private let titleLabel = UILabel()
    private lazy var icon = UIImageView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        contentView.tintColor = UIColor.ud.iconN2
        contentView.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
            make.right.equalTo(-16)
        }

        titleLabel.numberOfLines = 0
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .left
        contentView.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(16)
            make.left.equalTo(16)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
        }

        contentView.backgroundColor = UIColor.ud.bgFloat
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCellInfo(title: String, image: UIImage) {
        titleLabel.text = title
        icon.image = image
    }
}

class MailOOOSettingLongTextCell: UITableViewCell {

    /// 标题
    private let titleLabel = UILabel()
    /// 开关
    private lazy var icon = UIImageView()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

//        contentView.addSubview(icon)
//        icon.tintColor = UIColor.ud.textPlaceholder
//        icon.backgroundColor = .clear
//        icon.snp.makeConstraints { (make) in
//            make.top.width.height.equalTo(16)
//            make.right.equalTo(-16)
//        }
        self.titleLabel.numberOfLines = 9
        self.titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        self.titleLabel.textColor = UIColor.ud.textPlaceholder
        self.titleLabel.textAlignment = .left
        self.contentView.addSubview(self.titleLabel)

        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(12)
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.bottom.equalToSuperview().offset(-34)
        }

        contentView.backgroundColor = UIColor.ud.bgFloat
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.ud.udtokenBtnSeBgNeutralPressed : UIColor.ud.bgFloat
    }

    func setCellInfo(title: String, image: UIImage) {
        // titleLabel.textColor = title.isEmpty ? UIColor.ud.N500 : UIColor.ud.N900

        if regexPattern(str: title).isEmpty {
            titleLabel.text = BundleI18n.MailSDK.Mail_OOO_Content_Empty
        } else {
            var str: NSMutableAttributedString?
            do {
                // 拼接上默认字体和字号
                let titleWithDefaultFont = UDFontAppearance.isCustomFont ? title.appending("<style>body{font-family: Lark Circular; font-size: 16px;}</style>") : title
                if let data = titleWithDefaultFont.data(using: .unicode) {
                    let attstr = try NSMutableAttributedString(data: data,
                                                               options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html],
                                                               documentAttributes: nil)
                    attstr.addAttributes([.foregroundColor: UIColor.ud.textTitle], range: NSRange(location: 0, length: attstr.length))
                    str = attstr
                }
            } catch {
            }
            self.titleLabel.attributedText = title.isEmpty ? NSAttributedString(string: BundleI18n.MailSDK.Mail_OOO_Content_Empty) : str
        }
        icon.image = image
    }

    func regexPattern(str: String) -> String {

        var finalStr = str

        do {
            let regex = try NSRegularExpression(pattern: "(?s)<[^>]*>(\\s*<[^>]*>)*", options: NSRegularExpression.Options.caseInsensitive)
            finalStr = regex.stringByReplacingMatches(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: str.count), withTemplate: "")
        } catch {
            print(error)
        }
        return finalStr
    }

}

class MailOOOSettingCheckboxCell: UITableViewCell {

    var disposeBag = DisposeBag()
    private var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: nil, action: nil)

    private lazy var checkBox = UDCheckBox(boxType: .multiple, config: UDCheckBoxUIConfig(), tapCallBack: nil)
//    private lazy var checkBox = LKCheckbox(boxType: .single)
    private lazy var titleLabel: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let bgView = BaseCellSelectView()
        bgView.backgroundColor = UIColor.ud.bgFiller
        selectedBackgroundView = bgView

        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(44)
            make.top.equalTo(16)
            make.right.lessThanOrEqualTo(-16)
            make.centerY.equalToSuperview()
        }

        /// 左边的单选按钮
        checkBox.isUserInteractionEnabled = false
        contentView.addSubview(checkBox)
        checkBox.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(16)
            make.size.equalTo(CGSize(width: 20.0, height: 20.0))
        }
//        contentView.addGestureRecognizer(tapGesture)
        contentView.backgroundColor = UIColor.ud.bgFloat
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.ud.udtokenBtnSeBgNeutralPressed : UIColor.ud.bgFloat
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        contentView.backgroundColor = selected ? UIColor.ud.udtokenBtnSeBgNeutralPressed : UIColor.ud.bgFloat
    }

    func setCellInfo(title: String, isSelected: Bool) {
        let font = UIFont.systemFont(ofSize: 16)
        let lineHeight = font.figmaHeight
        let baselineOffset = (lineHeight - font.lineHeight) / 2.0 / 2.0

        // Paragraph style.
        let mutableParagraphStyle = NSMutableParagraphStyle()
        mutableParagraphStyle.minimumLineHeight = lineHeight
        mutableParagraphStyle.maximumLineHeight = lineHeight

        // Set.
        let attributedText = NSAttributedString(
          string: title,
          attributes: [.baselineOffset: baselineOffset, .paragraphStyle: mutableParagraphStyle]
        )
        titleLabel.attributedText = attributedText
        checkBox.isSelected = isSelected
        checkBox.isEnabled = true
    }
}
