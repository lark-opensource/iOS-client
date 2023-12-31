//
//  MeetingRecordTableViewCell.swift
//  Pods
//
//  Created by LUNNER on 2019/8/23.
//

import UIKit
import RxSwift
import RxCocoa
import Action
import ReplayKit
import UniverseDesignTheme
import UniverseDesignIcon

class LiveSettingTableViewCell: UITableViewCell {

    enum SettingAccessoryType {
        case none
        case `switch`(isOn: Driver<Bool>, isEnabled: Driver<Bool>, action: CompletableAction<Bool>)
        case more(String?)
        case detailMore
        case rightArrow
    }

    private lazy var newBadge: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = 7
        view.backgroundColor = UIColor.ud.colorfulRed
        view.isHidden = true

        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 10)
        label.text = "New"
        view.addSubview(label)

        label.snp.makeConstraints { (maker) in
            maker.height.equalTo(14)
            maker.top.bottom.equalToSuperview()
            maker.left.equalToSuperview().offset(2.5)
            maker.right.equalToSuperview().offset(-2.5)
        }

        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 2 // 最多两行
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byWordWrapping
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var titleView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 4

        view.addArrangedSubview(nameLabel)
        view.addArrangedSubview(subtitleLabel)
        return view
    }()

    private var reuseDisposeBag: DisposeBag = DisposeBag()
    private weak var settingAccessoryView: UIView?
    fileprivate var pickerView: UIView?
    private var detailLabel: UILabel?

    lazy var badgeView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8))
        view.backgroundColor = UIColor.ud.colorfulRed
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    lazy var betaView: UIView = {
        let label = PaddingLabel()
        label.font = .systemFont(ofSize: 12.0)
        label.textColor = UIColor.ud.textCaption
        label.attributedText = NSAttributedString(string: "Beta", config: .tinyAssist)
        label.backgroundColor = UIColor.ud.udtokenTagNeutralBgNormal
        label.textInsets = UIEdgeInsets(top: 0.0, left: 4.0, bottom: 0.0, right: 4.0)
        label.layer.cornerRadius = 2.0
        label.clipsToBounds = true
        label.isHidden = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    var showsLine: Bool {
        get {
            return !line.isHidden
        }
        set {
            line.isHidden = !newValue
        }
    }

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(titleView)
        stackView.addArrangedSubview(betaView)
        stackView.addSubview(badgeView)

        iconImageView.snp.makeConstraints { (maker) in
            maker.size.equalTo(20)
        }

        badgeView.snp.makeConstraints { (make) in
            make.width.height.equalTo(8)
            make.left.equalTo(iconImageView.snp.right).offset(-4)
            make.top.equalTo(iconImageView.snp.top).offset(-4)
        }
        return stackView
    }()

    private lazy var line: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    private lazy var topLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        view.isHidden = true
        return view
    }()

    private lazy var bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        view.isHidden = true
        return view
    }()

    private lazy var cellContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    var cellHeight: CGFloat? {
        didSet {
            if let height = cellHeight {
                stackView.snp.updateConstraints { (make) in
                    make.height.greaterThanOrEqualTo(height)
                }
            }
        }
    }

    private static func buildAutoManageStatusTag(_ text: String) -> NSTextAttachment {
        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        label.textColor = UIColor.ud.udtokenTagTextSBlue
        label.backgroundColor = UIColor.ud.udtokenTagBgBlue
        label.layer.cornerRadius = 4.0
        label.clipsToBounds = true
        label.attributedText = NSAttributedString(string: text, config: .assist)
        label.sizeToFit()
        label.frame = label.frame.insetBy(dx: -4, dy: 0)

        let imageSize = label.frame.size
        let render = UIGraphicsImageRenderer(bounds: .init(origin: .zero, size: imageSize))
        let image = render.image { context in
            label.layer.render(in: context.cgContext)
        }

        let nameLabelFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        let imageOffset = (nameLabelFont.capHeight - imageSize.height) / 2
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(origin: CGPoint(x: 0, y: imageOffset), size: imageSize)
        return attachment
    }

    struct AutoManageStatusTagKey: Hashable {
        let text: String
        let theme: Int

        init(text: String) {
            self.text = text
            if #available(iOS 13.0, *) {
                self.theme = UDThemeManager.getRealUserInterfaceStyle().rawValue
            } else {
                self.theme = 0
            }
        }
    }

    private static var _autoManageStatusTags: [AutoManageStatusTagKey: NSTextAttachment] = [:]

    private static func autoManageStatusTag(text: String) -> NSTextAttachment {
        let key = AutoManageStatusTagKey(text: text)
        if let tag = _autoManageStatusTags[key] { return tag }
        let tag = buildAutoManageStatusTag(text)
        _autoManageStatusTags[key] = tag
        return tag
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // Initialization code
        self.backgroundColor = .clear
        contentView.addSubview(cellContainerView)
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = UIColor.ud.fillHover
        self.selectedBackgroundView = selectedBackgroundView


        cellContainerView.addSubview(stackView)
        cellContainerView.addSubview(newBadge)
        cellContainerView.addSubview(line)
        cellContainerView.addSubview(topLine)
        cellContainerView.addSubview(bottomLine)

        cellContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(48)
        }
        titleView.snp.makeConstraints { (make) in
            make.top.greaterThanOrEqualToSuperview().inset(13.0)
            make.bottom.lessThanOrEqualToSuperview().inset(13.0)
        }
        newBadge.snp.makeConstraints { (make) in
            make.centerY.equalTo(iconImageView.snp.top)
            make.centerX.equalTo(iconImageView.snp.right)
        }
        line.snp.makeConstraints { make in
            make.left.equalTo(titleView.snp.left)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        topLine.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(0.5)
        }
        bottomLine.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }

        showsLine = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        reuseDisposeBag = DisposeBag()
        isUserInteractionEnabled = true
        set(nil, title: nil)
        nameLabel.textColor = UIColor.ud.textTitle
        setAccessoryType(.none)
        isUserInteractionEnabled = true
        showsLine = false
        super.prepareForReuse()
    }

    func bindIsUserInteractionEnabledObservable(_ enabledObservable: Driver<Bool>) {
        enabledObservable
            .drive(rx.isUserInteractionEnabled)
            .disposed(by: reuseDisposeBag)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    func set(_ image: UIImage?,
             title: String?,
             height: CGFloat? = nil,
             showBadge: Bool = false) {
        iconImageView.image = image
        iconImageView.isHidden = image == nil
        nameLabel.text = title
        badgeView.isHidden = !showBadge
        cellHeight = height
    }

    func set(_ image: UIImage?,
             richTitle: NSAttributedString?,
             height: CGFloat? = nil,
             showBadge: Bool = false) {
        iconImageView.image = image
        iconImageView.isHidden = image == nil
        nameLabel.attributedText = richTitle
        badgeView.isHidden = !showBadge
        cellHeight = height
    }

    func bind(with image: Driver<UIImage?>,
              title: Driver<NSAttributedString>,
              detailTitle: Driver<NSAttributedString>? = nil) {
        image.drive(iconImageView.rx.image)
            .disposed(by: reuseDisposeBag)

        title.drive(nameLabel.rx.attributedText)
            .disposed(by: reuseDisposeBag)

        if let detailTitle = detailTitle {
            detailTitle.asObservable()
                .subscribe(onNext: { [weak self] detail in
                    self?.detailLabel?.attributedText = detail
                    self?.setNeedsLayout()
                    self?.layoutIfNeeded()
                })
                .disposed(by: reuseDisposeBag)
        }
        badgeView.isHidden = true
    }

    func bindSwitch(with image: UIImage? = nil,
                    title: String,
                    subtitle: String? = nil,
                    height: CGFloat? = nil,
                    isOn: Driver<Bool>,
                    isEnabled: Driver<Bool> = Observable<Bool>.just(true).asDriver(onErrorJustReturn: false),
                    action: CompletableAction<Bool>) {
        iconImageView.image = image
        iconImageView.isHidden = image == nil
        setAccessoryType(.switch(isOn: isOn, isEnabled: isEnabled, action: action))
        nameLabel.attributedText = NSAttributedString(string: title, config: .body)
        subtitleLabel.isHidden = subtitle == nil
        subtitleLabel.attributedText = NSAttributedString(string: subtitle ?? "", config: .bodyAssist)
        badgeView.isHidden = true
        cellHeight = height
    }

    weak var tableView: UITableView?

    func setAccessoryType(_ type: SettingAccessoryType) {
        settingAccessoryView?.removeFromSuperview()
        showTopLine(false)
        showBottomLine(false)
        switch type {
        case .none:
            stackView.spacing = 8
            stackView.insertArrangedSubview(iconImageView, at: 0)
            iconImageView.isHidden = false
            subtitleLabel.isHidden = true
        case let .switch(isOn, isEnabled, action):
            let switchView = VCSwitch()
            isOn.drive(switchView.rx.isOn)
                .disposed(by: reuseDisposeBag)
            switchView.rx.isOn
                .skip(1)
                .distinctUntilChanged()
                .subscribe(onNext: {
                    action.execute($0)
                })
                .disposed(by: reuseDisposeBag)
            isEnabled.drive(switchView.rx.isEnabled)
                .disposed(by: reuseDisposeBag)

            stackView.spacing = 8
            stackView.addArrangedSubview(switchView)
            switchView.setContentHuggingPriority(.required, for: .horizontal)
            switchView.setContentCompressionResistancePriority(.required, for: .horizontal)
            settingAccessoryView = switchView
        case let .more(title):
            var view: UIView
            view = UIView(frame: .zero)
            let label = UILabel(frame: .zero)
            label.text = title
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = UIColor.ud.textPlaceholder
            label.textAlignment = .right
            let img = UDIcon.getIconByKey(.rightOutlined, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16))
            let imageView = UIImageView(image: img)
            imageView.setContentHuggingPriority(.required, for: .horizontal)

            view.addSubview(label)
            label.snp.makeConstraints { (make) in
                make.top.bottom.left.equalToSuperview()
            }

            view.addSubview(imageView)
            imageView.snp.makeConstraints { (make) in
                make.left.equalTo(label.snp.right).offset(8)
                make.top.right.bottom.equalToSuperview()
            }
            stackView.spacing = 8
            stackView.addArrangedSubview(view)
            settingAccessoryView = view
        case .detailMore:
            stackView.removeArrangedSubview(iconImageView)
            iconImageView.isHidden = true
            let view = UIStackView()
            view.alignment = .center
            view.distribution = .equalSpacing
            let label = UILabel(frame: .zero)
            label.numberOfLines = 2
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = UIColor.ud.textPlaceholder
            label.setContentCompressionResistancePriority(.required, for: .vertical)
            label.setContentCompressionResistancePriority(.required, for: .horizontal)
            view.addArrangedSubview(label)
            detailLabel = label
            stackView.spacing = 12
            stackView.addArrangedSubview(view)
            let img = UDIcon.getIconByKey(.rightOutlined, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16))
            let arrowView = UIImageView(image: img)
            view.addArrangedSubview(arrowView)
            view.setContentHuggingPriority(.required, for: .horizontal)
            settingAccessoryView = view
            view.snp.makeConstraints { (make) in
                make.top.greaterThanOrEqualToSuperview()
                make.bottom.lessThanOrEqualToSuperview()
            }
            arrowView.snp.makeConstraints { (make) in
                make.right.equalToSuperview()
                make.width.height.equalTo(16)
            }
            detailLabel?.snp.makeConstraints { (make) in
                make.left.equalToSuperview()
                make.right.equalTo(arrowView.snp.left).offset(-8)
                make.top.bottom.equalToSuperview()
            }
        case .rightArrow:
            stackView.spacing = 8
            stackView.removeArrangedSubview(iconImageView)
            iconImageView.isHidden = true
            let view: UIView = UIView(frame: .zero)
            let img = UDIcon.getIconByKey(.rightOutlined, iconColor: .ud.iconN3, size: CGSize(width: 16, height: 16))
            let arrowView = UIImageView(image: img)
            view.addSubview(arrowView)
            stackView.addArrangedSubview(view)
            view.setContentHuggingPriority(.required, for: .horizontal)
            settingAccessoryView = view
            arrowView.snp.makeConstraints { (make) in
                make.right.equalToSuperview()
                make.width.height.equalTo(16)
                make.centerY.equalToSuperview()
            }
        }

    }

    func showTopLine(_ showLine: Bool) {
        topLine.isHidden = !showLine
    }

    func showBottomLine(_ showLine: Bool) {
        bottomLine.isHidden = !showLine
    }

    func setRadiusStyle() {
        cellContainerView.layer.cornerRadius = 10
        cellContainerView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
    }

    func setRadiusStyleBg(bgColor: UIColor) {
        cellContainerView.backgroundColor = bgColor
    }

    func hideTopBottomLine(_ hide: Bool) {
        showTopLine(!hide)
        showBottomLine(!hide)
    }
}
