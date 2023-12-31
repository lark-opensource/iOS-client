//
//  MinutesEditSpeakerAlertController.swift
//  Minutes
//
//  Created by chenlehui on 2021/6/17.
//

import UIKit
import MinutesFoundation
import MinutesNetwork
import UniverseDesignColor
import Kingfisher
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTag
import UniverseDesignCheckBox
import UniverseDesignButton
import RustPB
import LarkTag
import LarkLocalizations
import LarkContainer
import LarkSetting
import LarkUIKit

class MinutesEditSpeakerAlertController: UIViewController, UserResolverWrapper {
    let userResolver: UserResolver
    @ScopedProvider var featureGatingService: FeatureGatingService?

    private var isNewExternalTagEnabled: Bool {
        return featureGatingService?.staticFeatureGatingValue(with: .archUserOrganizationName) == true
    }
    private let presentationManager: SlidePresentationManager = {
        let p = SlidePresentationManager()
        p.autoSize = {
            let size = ScreenUtils.sceneScreenSize
            return CGSize(width: size.width, height: size.height - 132)
        }
        return p
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        l.textColor = UIColor.ud.textTitle
        l.text = BundleI18n.Minutes.MMWeb_G_EditSpeaker_Menu
        return l
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitle(BundleI18n.Minutes.MMWeb_G_Cancel, for: .normal)
        button.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        return button
    }()

    private lazy var textField: MinutesEditSpeakerTextField = {
        let tf = MinutesEditSpeakerTextField()
        tf.addTarget(self, action: #selector(textFieldDidChanged(_:)), for: .editingChanged)
        tf.delegate = self
        tf.returnKeyType = .search
        return tf
    }()

    private lazy var  topView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.ud.bgBody
        v.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.top.equalTo(14)
            maker.height.equalTo(24)
            maker.centerX.equalToSuperview()
        }

        v.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { (maker) in
            maker.left.top.equalToSuperview()
            maker.size.equalTo(CGSize(width: 64, height: 54))
        }

        v.addSubview(textField)
        textField.snp.makeConstraints { (maker) in
            maker.left.equalTo(16)
            maker.bottom.equalTo(-8)
            maker.right.equalTo(-16)
            maker.height.equalTo(32)
        }

        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        v.addSubview(line)
        line.snp.makeConstraints { (maker) in
            maker.left.bottom.right.equalToSuperview()
            maker.height.equalTo(0.5)
        }
        return v
    }()

    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.dataSource = self
        tv.delegate = self
        tv.separatorInset = UIEdgeInsets(top: 0, left: 76, bottom: 0, right: 0)
        tv.separatorColor = UIColor.ud.lineDividerDefault
        tv.separatorStyle = .singleLine
        tv.sectionHeaderHeight = 8
        tv.sectionFooterHeight = 0
        tv.showsVerticalScrollIndicator = false
        tv.estimatedRowHeight = 66
        tv.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 8))
        tv.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 0.001))
        tv.backgroundColor = UIColor.ud.bgBase
        tv.allowsSelection = true
        if #available(iOS 11.0, *) {
            tv.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        } else {
            self.automaticallyAdjustsScrollViewInsets = false
        }
        return tv
    }()

    private lazy var emptyLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.ud.textPlaceholder
        l.font = UIFont.systemFont(ofSize: 18)
        l.text = BundleI18n.Minutes.MMWeb_G_NoResultsFound
        return l
    }()

    lazy var bottomBar: UIView =  {
        let bottomBar = UIView()
        bottomBar.backgroundColor = UIColor.ud.bgBody

        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        bottomBar.addSubview(line)
        line.snp.makeConstraints { (maker) in
            maker.height.width.equalTo(0.5)
            maker.top.left.right.equalToSuperview()
        }

        bottomBar.addSubview(bottomBarCheckBox)
        bottomBarCheckBox.snp.makeConstraints { (maker) in
            maker.height.width.equalTo(20)
            maker.left.equalTo(16)
            maker.centerY.equalToSuperview()
        }

        bottomBar.addSubview(bottomButton)
        bottomButton.snp.makeConstraints { (maker) in
            maker.height.equalTo(28)
            maker.right.equalTo(-16)
            maker.centerY.equalToSuperview()
        }

        bottomBar.addSubview(bottomBarPromptLabel)

        bottomBarPromptLabel.snp.makeConstraints { (maker) in
            maker.left.equalTo(bottomBarCheckBox.snp.right).offset(12)
            maker.right.equalTo(bottomButton.snp.left).offset(-20)
            maker.top.equalToSuperview().offset(14)
            maker.bottom.equalToSuperview().offset(-14)
            maker.centerY.equalToSuperview()
        }

        return bottomBar
    }()

    private lazy var bottomBarCheckBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .multiple) {[weak self] box in
            self?.checkboxClicked()
        }
        checkBox.isSelected = isBatchUpdated
        checkBox.isEnabled = true
        return checkBox
    }()

    private lazy var bottomBarPromptLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    private lazy var bottomButton: UIButton = {
        let button = UDButton()
        var config = UDButton.primaryBlue.config
        config.type = UDButtonUIConifg.ButtonType.small
        button.setTitle(BundleI18n.Minutes.MMWeb_G_Done, for: .normal)
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.config = config
        button.addTarget(self, action: #selector(doneAction), for: .touchUpInside)
        return button
    }()

    private lazy var maskLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height), byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 12, height: 12))
        layer.path = path.cgPath
        return layer
    }()

    lazy var isKeyboardShown = false

    let viewModel: MinutesEditSpeakerViewModel

    private lazy var tracker: MinutesTracker = {
        return MinutesTracker(minutes: viewModel.session.minutes)
    }()

    private var searchWorkItem: DispatchWorkItem?
    var userType: UserType? = .unknow

    var isBatchUpdated: Bool = false

    var didFinishedEditBlock: ((Participant?, String?) -> Void)?
    var endBlock: (() -> Void)?

    init(resolver: UserResolver, session: MinutesEditSession, paragraph: Paragraph) {
        userResolver = resolver
        viewModel = MinutesEditSpeakerViewModel(session: session, paragraphId: paragraph.id, userType: paragraph.speaker?.userType ?? .lark)

        userType = paragraph.speaker?.userType
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .custom
        transitioningDelegate = presentationManager
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        MinutesLogger.detail.info("MinutesEditSpeakerAlertController deinit")
        NotificationCenter.default.removeObserver(self)
        endBlock?()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if Display.phone {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowAction) , name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideAction) , name: UIResponder.keyboardWillHideNotification, object: nil)
        }

        view.backgroundColor = UIColor.ud.bgBase
        view.layer.mask = maskLayer

        view.addSubview(topView)
        topView.snp.makeConstraints { (maker) in
            maker.height.equalTo(98)
            maker.left.top.right.equalToSuperview()
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(topView.snp.bottom)
            maker.bottom.equalToSuperview()
        }

        tableView.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }

        addBottomBar()

        viewModel.fetchUserChoiceStatus { [weak self] batched in
            self?.isBatchUpdated = (batched == 1)
            self?.bottomBarCheckBox.isSelected = (batched == 1)

        }

        viewModel.fetchSpeakerSuggestion { [weak self] (result) in
            guard let self = self else { return }

            switch result {
            case .success(let suggestion):
                self.showBottomBar(number: suggestion.paragraphNum ?? 0, showName: suggestion.speakerShowName ?? "")
                self.reloadData()
            case .failure(let error):
                break
            }
        }

        MinutesLogger.detail.info("viewDidLoad")
    }

    private func addBottomBar() {
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        let bottomView = UIView()
        bottomView.backgroundColor = UIColor.ud.bgBody
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            maker.bottom.equalTo(view.snp.bottom)
        }
        tableView.snp.remakeConstraints{ (maker) in
            maker.left.right.equalTo(view.safeAreaLayoutGuide)
            maker.top.equalTo(topView.snp.bottom)
            maker.bottom.equalTo(bottomBar.snp.top)
        }
        bottomBar.isHidden = true
    }

    private func showBottomBar(number: Int, showName: String) {
        bottomBar.isHidden = false
        bottomBarPromptLabel.text = BundleI18n.Minutes.MMWeb_G_EditSpeakerName(String(number), showName)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let size = presentationManager.autoSize?() ?? view.frame.size
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: size.width, height: size.height), byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 6, height: 6))
        maskLayer.path = path.cgPath
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

    }

    private func reloadData() {
        tableView.reloadData()
        emptyLabel.isHidden = !viewModel.cellItems.isEmpty
    }

}

extension MinutesEditSpeakerAlertController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = viewModel.cellItem(from: indexPath) {
            switch item {
            case .new(let speaker):
                return tableView.mins.dequeueReusableCell(with: MinutesEditSpeakerNewCell.self) { (cell) in
                    cell.config(with: speaker)
                }
            case .normal(let speaker):
                return tableView.mins.dequeueReusableCell(with: MinutesEditSpeakerCell.self) { (cell) in
                    cell.config(with: speaker, isNewExternalTagEnabled: isNewExternalTagEnabled)
                }
            }
        }
        return UITableViewCell()
    }

}

extension MinutesEditSpeakerAlertController: UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.cellItems.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let items = viewModel.cellItems[section]
        return items.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = viewModel.cellItem(from: indexPath)
        return item?.height ?? 0.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        textField.endEditing(true)
    }

}

// MARK: - action
extension MinutesEditSpeakerAlertController {

    private func checkboxClicked() {
        bottomBarCheckBox.isSelected = !bottomBarCheckBox.isSelected
    }

    @objc private func cancelAction() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func doneAction() {
        if let selectedIndexPath = tableView.indexPathForSelectedRow, let speaker = viewModel.cellItem(from: selectedIndexPath)?.rawValue {
            var editType = "change_speaker"
            if speaker.userID.isEmpty ?? true {
                editType = "add_speaker"
            }
            MinutesSearchLoadingView.showLoad()
            let batch: Bool = bottomBarCheckBox.isSelected
            viewModel.updateSpeaker(catchError: true, speaker, batch) { [weak self] (p, toast, needDissmiss) in
                MinutesSearchLoadingView.dissmissLoad()
                if !needDissmiss {
                    self?.view.endEditing(true)
                    self?.tracker.tracker(name: .popupView, params: ["popup_name": "violative_speaker_name"])
                    return
                }

                self?.tracker.tracker(name: .detailClick, params: ["click": "speaker_edit", "bulk_editing": batch ? "true" : "false", "target": "none", "edit_type": editType])

                self?.dismiss(animated: true, completion: {
                    self?.didFinishedEditBlock?(p, toast)
                })
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @objc private func textFieldDidChanged(_ textField: UITextField) {
        guard textField.text?.isEmpty == true else { return }
        searchWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.viewModel.searchParticipants(with: "") { (_, _, _) in
                self?.reloadData()
            }
        }
        // disable-lint: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
        // enable-lint: magic number
        searchWorkItem = workItem
    }
}

extension MinutesEditSpeakerAlertController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text, let textRange = Range(range, in: text) else {
            return true
        }
        searchWorkItem?.cancel()
        let query = text.replacingCharacters(in: textRange, with: string)
        let workItem = DispatchWorkItem { [weak self] in
            self?.viewModel.searchParticipants(with: query) { query, parti, error in
                let curQuery = text.replacingCharacters(in: textRange, with: string)
                if let curText = textField.text, curText == curQuery {
                    // 避免发出去的数据不是最后的文字
                    self?.viewModel.processSearchSpeakers(parti?.list ?? [], query: curText)
                    self?.reloadData()
                }
            }
        }
        // disable-lint: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
        // enable-lint: magic number
        searchWorkItem = workItem
        return true
    }
}

// MARK: -
class MinutesEditSpeakerTextField: UITextField {

    lazy var right: UIButton = {
        let b = UIButton(type: .custom)
        b.setImage(UDIcon.getIconByKey(.closeFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: 18, height: 18)), for: .normal)
        b.addTarget(self, action: #selector(clearText), for: .touchUpInside)
        b.isHidden = true
        return b
    }()

    lazy var left: UIImageView = {
        let iv = UIImageView(image: UDIcon.getIconByKey(.searchOutlineOutlined, iconColor: UIColor.ud.textPlaceholder, size: CGSize(width: 16, height: 16)))
        iv.contentMode = .center
        return iv
    }()

    override var text: String? {
        didSet {
            right.isHidden = text?.isEmpty == true
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBodyOverlay
        layer.cornerRadius = 6
        leftView = left
        leftViewMode = .always
        rightView = right
        rightViewMode = .whileEditing
        textColor = UIColor.ud.textTitle
        font = UIFont.systemFont(ofSize: 14)
        attributedPlaceholder = NSAttributedString(string: BundleI18n.Minutes.MMWeb_G_Search, attributes: [NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder])
        addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 0, y: 0, width: 36, height: bounds.height)
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: bounds.width - 36, y: 0, width: 36, height: bounds.height)
    }

    @objc private func clearText() {
        text = nil
        sendActions(for: .editingChanged)
    }

    @objc private func textChanged() {
        right.isHidden = text?.isEmpty == true
    }
}

class MinutesEditSpeakerCell: UITableViewCell {

    private lazy var avatarView: UIImageView = {
        let iv = UIImageView()
        iv.layer.cornerRadius = 24
        iv.clipsToBounds = true
        return iv
    }()

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16)
        l.textColor = UIColor.ud.textTitle
        return l
    }()

    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = UIColor.ud.N500
        return l
    }()

    private lazy var selectedIcon: UIImageView = {
        let iv = UIImageView(image: UDIcon.getIconByKey(.doneOutlined, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 24, height: 24)))
        iv.isHidden = true
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        return iv
    }()

    lazy var newSpeakerTag: TagWrapperView = {
        let tagView = TagWrapperView()
        let speaker = Tag(title: BundleI18n.Minutes.MMWeb_G_Speaking_Label, style: .blue, type: .organization, size: .mini)
        tagView.setElements([speaker])
        return tagView
    }()

    lazy var languageIdentifier: String = {
        return LanguageManager.currentLanguage.languageIdentifier
    }()

    lazy var newExternalTag: TagWrapperView = {
        let tagView = TagWrapperView()
        return tagView
    }()

    private lazy var titleStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.addArrangedSubview(titleLabel)
        stackView.setCustomSpacing(4, after: titleLabel)

        stackView.addArrangedSubview(newSpeakerTag)
        newSpeakerTag.snp.makeConstraints { make in
            make.height.equalTo(18)
        }
        stackView.setCustomSpacing(4, after: newSpeakerTag)
        stackView.addArrangedSubview(newExternalTag)
        newExternalTag.snp.makeConstraints { make in
            make.height.equalTo(18)
            make.width.equalTo(100)
        }
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.addArrangedSubview(titleStackView)
        stackView.setCustomSpacing(4, after: titleStackView)

        stackView.addArrangedSubview(subtitleLabel)

        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { (maker) in
            maker.width.height.equalTo(48)
            maker.left.equalTo(16)
            maker.centerY.equalToSuperview()

        }

        contentView.addSubview(selectedIcon)
        selectedIcon.snp.makeConstraints { (maker) in
            maker.right.equalTo(-21)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(24)
        }

        contentView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { (maker) in
            maker.height.equalTo(48)
            maker.left.equalTo(avatarView.snp.right).offset(12)
            maker.centerY.equalTo(avatarView)
            maker.right.equalTo(selectedIcon.snp.left)
        }

        titleLabel.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 1001), for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selectedIcon.isHidden = !selected
    }

    func config(with item: Participant, isNewExternalTagEnabled: Bool) {
        titleLabel.text = item.userName
        subtitleLabel.text = item.departmentName
        avatarView.setAvatarImage(with: item.avatarURL, placeholder: UIImage.dynamicIcon(.adsMobileAvatarCircle, dimension: 48, color: UIColor.ud.N300))

        newExternalTag.isHidden = true
        newSpeakerTag.isHidden = true

        if let isParagraphSpeaker = item.isParagraphSpeaker {
            newSpeakerTag.isHidden = !isParagraphSpeaker
            newExternalTag.isHidden = !(item.displayTag?.tagType == 2 || item.displayTag?.tagType == 1)

            var tags: [Tag] = []
            if item.displayTag?.tagType == 2 {
                var i18nValue = DisplayTagPicker.GetTagValue(item.displayTag)
                if i18nValue?.isEmpty == true {
                    i18nValue = item.displayTag?.tagValue?.value
                }
                let customTag = Tag(title: i18nValue, style: .blue, type: .organization, size: .mini)
                tags.append(customTag)
            } else if item.displayTag?.tagType == 1 {
                var externalTag = Tag(type: .organization, style: .blue, size: .mini)
                if isNewExternalTagEnabled {
                    let tenantName = item.tenantName
                    if tenantName?.isEmpty == false {
                        externalTag = Tag(title: tenantName, style: .blue, type: .organization, size: .mini)
                    }
                }
                tags.append(externalTag)
            }
            newExternalTag.setElements(tags)

            // 左边距：16  右边距：21  头像：48
            // 头像和title间距：12
            // title和打勾间距：6  打勾大小：24
            var tagMaxWidth = ScreenUtils.sceneScreenSize.width - 16 - 21 - 48 - 12 - 6 - 24
            newExternalTag.snp.remakeConstraints { make in
                make.height.equalTo(18)
                make.width.lessThanOrEqualTo(tagMaxWidth)
            }
            var tagMinWidth: CGFloat = 60.0

            let newTagSpace: CGFloat = 6
            let count: Int = newExternalTag.tags?.count ?? 0
            let part1: CGFloat = 72.0 * CGFloat(count)
            var part2: CGFloat = newTagSpace * CGFloat(count - 1)
            if count < 1 {
                part2 = 0
            }
            let newTagMinWidth: CGFloat = part1 + part2
            tagMinWidth = newTagMinWidth
            let curSpeakerWidth: CGFloat = 95.0
            if isParagraphSpeaker {
                tagMinWidth += (newTagSpace + curSpeakerWidth)
            }
            // 左边距：16  右边距：21  头像：48
            // 头像和title间距：12
            // tag最小宽度: 60
            // title和打勾间距：6  打勾大小：24
            var titleMaxWidth = ScreenUtils.sceneScreenSize.width - 16 - 21 - 48 - 12 - 6 - 24 - tagMinWidth
            titleLabel.snp.remakeConstraints { make in
                make.width.lessThanOrEqualTo(titleMaxWidth)
            }

            if isNewExternalTagEnabled {
                subtitleLabel.text = item.departmentName
            } else {
                subtitleLabel.text = item.tenantName
            }
        }
    }
}

class MinutesEditSpeakerNewCell: UITableViewCell {

    private lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 16)
        l.textColor = UIColor.ud.textTitle
        return l
    }()

    private lazy var icon: UIImageView = {
        let iv = UIImageView(image: UDIcon.getIconByKey(.memberAddOutlined, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 20, height: 20)))
        return iv
    }()

    private lazy var selectedIcon: UIImageView = {
        let iv = UIImageView(image: UDIcon.getIconByKey(.doneOutlined, iconColor: UIColor.ud.primaryContentDefault, size: CGSize(width: 24, height: 24)))
        iv.isHidden = true
        iv.setContentHuggingPriority(.required, for: .horizontal)
        iv.setContentCompressionResistancePriority(.required, for: .horizontal)
        return iv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.backgroundColor = UIColor.ud.bgBody

        contentView.addSubview(icon)
        contentView.addSubview(selectedIcon)
        contentView.addSubview(titleLabel)

        createConstraints()
    }

    func createConstraints() {
        icon.snp.makeConstraints {
            $0.left.equalTo(16)
            $0.width.height.equalTo(20)
            $0.centerY.equalToSuperview()
        }

        selectedIcon.snp.makeConstraints {
            $0.right.equalTo(-16)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(24)
        }

        titleLabel.snp.makeConstraints {
            $0.left.equalTo(icon.snp.right).offset(16)
            $0.right.equalTo(selectedIcon.snp.left)
            $0.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        selectedIcon.isHidden = !selected
    }

    func config(with speaker: Participant) {
        let name = speaker.userName
        if !name.isEmpty {
            var text = BundleI18n.Minutes.MMWeb_G_AddNameAsSpeaker_Desc("\"\(name)\"")
            text.removeAllAt()
            titleLabel.text = text
        }
    }
}

