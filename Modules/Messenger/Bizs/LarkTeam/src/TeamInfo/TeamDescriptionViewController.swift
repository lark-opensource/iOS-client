//
//  TeamDescriptionViewController.swift
//  LarkTeam
//
//  Created by JackZhao on 2021/8/19.
//

import UIKit
import Foundation
import RxSwift
import LarkUIKit
import LarkModel
import RichLabel
import EENavigator
import EditTextView
import LarkContainer
import LarkKeyboardKit
import LKCommonsLogging
import LarkSDKInterface
import UniverseDesignToast
import UniverseDesignInput
import UniverseDesignEmpty
import UniverseDesignDialog
import LarkMessengerInterface

final class TeamDescriptionViewController: BaseUIViewController, EditTextViewTextDelegate {

    private let disposeBag = DisposeBag()
    private let team: Team
    private let groupDescription: String
    private let teamAPI: TeamAPI
    private var hasAccess: Bool {
        return team.isTeamManagerForMe
    }

    private(set) var rightItem: LKBarButtonItem?
    private(set) var displayView: TeamDescriptionDisplayView?
    private(set) var editView: TeamDescriptionEditView?

    private lazy var emptyView: UDEmptyView = {
        let desc = UDEmptyConfig.Description(descriptionText: BundleI18n.LarkTeam.Project_MV_SubtitleNoTeamDesc)
        let emptyView = UDEmptyView(config: UDEmptyConfig(description: desc, type: .noGroup))
        emptyView.backgroundColor = UIColor.ud.N00
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
        return emptyView
    }()

    private(set) var rightItemStyle: RightItemStyle = .display {
        didSet {
            switch rightItemStyle {
            case .display:
                self.updateRightItem(title: BundleI18n.LarkTeam.Lark_Legacy_Edit, color: UIColor.ud.N900)
                self.displayView?.isHidden = false
                self.editView?.isHidden = true
            case .edit:
                self.updateRightItem(title: BundleI18n.LarkTeam.Lark_Legacy_Save, color: UIColor.ud.colorfulBlue)
                self.displayView?.isHidden = true
                self.editView?.isHidden = false
            }
        }
    }
    let navigator: EENavigator.Navigatable
    init(team: Team,
         teamAPI: TeamAPI,
         navigator: EENavigator.Navigatable) {
        self.team = team
        self.teamAPI = teamAPI
        self.groupDescription = team.description_p
        self.navigator = navigator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    func setupSubviews() {
        self.view.backgroundColor = UIColor.ud.bgBase
        self.title = BundleI18n.LarkTeam.Project_MV_TeamDescriptionHere

        // edit view
        let editView = TeamDescriptionEditView()
        editView.backgroundColor = UIColor.clear
        self.view.addSubview(editView)
        editView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        editView.inputTextView.textDelegate = self
        self.editView = editView
        self.editView?.set(content: groupDescription)
        let attr = NSAttributedString(string: "\(groupDescription.count)/\(TeamConfig.descriptionInputMaxLength)",
                                      attributes: [.foregroundColor: UIColor.ud.N500])
        self.editView?.set(textCount: attr)

        // display view
        let displayView = TeamDescriptionDisplayView()
        displayView.delegate = self
        displayView.backgroundColor = UIColor.clear
        self.view.addSubview(displayView)
        displayView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.displayView = displayView
        self.displayView?.set(content: groupDescription)
        self.setupNavigationBar()
        self.setupRightItemStyle()
    }

    func setupNavigationBar() {
        let item = LKBarButtonItem()
        item.setProperty(alignment: .right)
        item.button.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        self.navigationItem.rightBarButtonItem = item
        item.button.isHidden = !self.hasAccess
        item.button.setTitleColor(UIColor.ud.N400, for: .disabled)
        self.rightItem = item
    }

    func setupRightItemStyle() {
        if self.hasAccess && self.groupDescription.isEmpty {
            self.rightItemStyle = .edit
            emptyView.isHidden = true
            self.editView?.inputTextView.becomeFirstResponder()
        } else {
            emptyView.isHidden = !groupDescription.isEmpty
            self.rightItemStyle = .display
        }
    }

    func updateRightItem(title: String, color: UIColor) {
        self.rightItem?.resetTitle(title: title)
        self.rightItem?.button.setTitleColor(color, for: .normal)
    }

    @objc
    fileprivate func navigationBarRightItemTapped() {
        switch self.rightItemStyle {
        case .display:
            self.rightItemStyle = .edit
            self.emptyView.isHidden = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.editView?.inputTextView.becomeFirstResponder()
            }
        case .edit:
            self.editView?.inputTextView.resignFirstResponder()
            self.patchTeamDescriptionRequest()
        }
    }

    private func patchTeamDescriptionRequest() {
        guard hasAccess else {
            let dialog = UDDialog()
            let content = BundleI18n.LarkTeam.Lark_Legacy_OnlyGOGAEditGroupInfo
            dialog.setContent(text: content)
            dialog.addPrimaryButton(text: BundleI18n.LarkTeam.Lark_Legacy_Sure)
            navigator.present(dialog, from: self)
            return
        }

        let new = self.editView?.inputTextView.text ?? ""
        guard new != groupDescription else {
            self.dismissSelf()
            return
        }

        let hud = UDToast.showLoading(on: self.view.window ?? self.view)

        teamAPI.patchTeamDescriptionRequest(teamId: self.team.id,
                                            description: new.removeCharSpace)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak hud] _ in
                if let window = self?.view.window {
                    hud?.showSuccess(with: BundleI18n.LarkTeam.Lark_Legacy_SaveSuccess, on: window)
                    self?.popSelf()
                }
            }, onError: { [weak self] (error) in
                if let window = self?.view.window {
                    hud.showFailure(
                        with: BundleI18n.LarkTeam.Lark_Legacy_ChatGroupInfoModifyGroupDescriptionFailed,
                        on: window,
                        error: error
                    )
                }
            }).disposed(by: disposeBag)
    }

    private func dismissSelf() {
        if self.presentingViewController != nil {
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }

    func textChange(text: String, textView: LarkEditTextView) {
        let count = text.count
        self.rightItem?.button.isEnabled = text.checked(maxChatLength: TeamConfig.descriptionInputMaxLength)
        if count <= TeamConfig.descriptionInputMaxLength {
            let attr = NSAttributedString(string: "\(count)/\(TeamConfig.descriptionInputMaxLength)",
                                          attributes: [.foregroundColor: UIColor.ud.N500])
            editView?.set(textCount: attr)
        } else {
            let attr = NSMutableAttributedString(string: "\(count)",
                                                 attributes: [.foregroundColor: UIColor.ud.colorfulRed])
            attr.append(NSAttributedString(string: "/\(TeamConfig.descriptionInputMaxLength)",
                                           attributes: [.foregroundColor: UIColor.ud.N500]))
            editView?.set(textCount: attr)
        }
    }
}

extension TeamDescriptionViewController: LKLabelDelegate {
    func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        navigator.push(url, context: [
            "from": "lark",
            "scene": "messenger",
            "location": "team_description"
        ], from: self)
    }

    func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {
        navigator.open(body: OpenTelBody(number: phoneNumber), from: self)
    }
}

final class TeamDescriptionDisplayView: UIView, LKLabelDelegate {
    private(set) var contentLabel: LKLabel = .init()

    weak var delegate: LKLabelDelegate? {
        didSet {
            self.contentLabel.delegate = delegate
        }
    }

    override var bounds: CGRect {
        didSet {
            contentLabel.preferredMaxLayoutWidth = self.bounds.width - 31
            contentLabel.invalidateIntrinsicContentSize()
        }
    }

    init() {
        super.init(frame: .zero)

        let contentLabel = LKLabel().lu.setProps(fontSize: 16, numberOfLine: 0, textColor: UIColor.ud.N900)
        contentLabel.textCheckingDetecotor = DataCheckDetector
        contentLabel.textAlignment = .left
        contentLabel.delegate = delegate
        let blueLink: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(rawValue: kCTForegroundColorAttributeName as String): UIColor.ud.colorfulBlue.cgColor,
            NSAttributedString.Key(rawValue: kCTUnderlineStyleAttributeName as String): 0
        ]
        contentLabel.linkAttributes = blueLink
        self.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.left.top.equalTo(15)
            make.right.equalTo(-15)
        }
        self.contentLabel = contentLabel
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(content: String) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        let attribute = LKLabel.lu.basicAttribute(
            foregroundColor: UIColor.ud.N900,
            atMeBackground: nil,
            lineSpacing: 3,
            font: UIFont.systemFont(ofSize: 16),
            lineBreakMode: NSLineBreakMode.byWordWrapping
        )
        self.contentLabel.attributedText = NSAttributedString(string: content, attributes: attribute)
    }
}

final class TeamDescriptionEditView: UIView {
    private(set) var inputTextView: LarkEditTextView = .init()
    private(set) var wrapperView: UIView = .init()
    private(set) var textCountLabel: UILabel = .init()
    private let disposeBag = DisposeBag()
    private var inputTextViewMaxH: CGFloat = 124 {
        didSet {
            guard inputTextViewMaxH > 0 else { return }
            inputTextView.maxHeight = inputTextViewMaxH
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        let wrapperView = UIView()
        wrapperView.backgroundColor = UIColor.ud.bgBody
        self.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(Layout.wrapperTopMargin)
        }
        self.wrapperView = wrapperView

        self.wrapperView.lu.addTopBorder()
        self.wrapperView.lu.addBottomBorder()

        let inputTextView = LarkEditTextView()
        let font = UIFont.systemFont(ofSize: 16)
        let defaultTypingAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.ud.N900
        ]
        inputTextView.defaultTypingAttributes = defaultTypingAttributes
        inputTextView.isScrollEnabled = false
        inputTextView.font = font
        inputTextView.textAlignment = .left
        inputTextView.textContainerInset = .zero
        inputTextView.placeholder = BundleI18n.LarkTeam.Lark_Legacy_SetADescription
        inputTextView.placeholderTextColor = UIColor.ud.N500
        inputTextView.maxHeight = inputTextViewMaxH
        inputTextView.backgroundColor = UIColor.clear
        self.wrapperView.addSubview(inputTextView)
        inputTextView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(Layout.inputTextViewTopMargin)
            make.height.greaterThanOrEqualTo(124)
        }
        self.inputTextView = inputTextView

        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        wrapperView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.top.equalTo(inputTextView.snp.bottom).offset(Layout.labelTopMargin)
            make.trailing.equalTo(inputTextView)
            make.bottom.equalToSuperview().offset(-Layout.labelBottomMargin)
        }
        textCountLabel = label

        KeyboardKit.shared.keyboardHeightChange.distinctUntilChanged().drive(onNext: { [weak self] height in
            self?.updateEditView(by: height)
        }).disposed(by: disposeBag)

        DispatchQueue.main.async {
            let maxH = self.bounds.height - self.textCountLabel.bounds.height - Layout.totalMargin
            self.inputTextViewMaxH = maxH
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateEditView(by keyboardH: CGFloat) {
        let maxH = self.bounds.height - self.textCountLabel.bounds.height - Layout.totalMargin - keyboardH
        if keyboardH > 0, maxH > 0 {
            self.inputTextViewMaxH = maxH
            self.inputTextView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(10)
                make.right.equalToSuperview().offset(-10)
                make.top.equalToSuperview().offset(Layout.inputTextViewTopMargin)
                make.height.greaterThanOrEqualTo(124)
                make.height.lessThanOrEqualTo(maxH)
            }
        }
        self.superview?.layoutIfNeeded()
    }

    func set(content: String) {
        self.inputTextView.text = content
    }

    func set(textCount: NSAttributedString) {
        textCountLabel.attributedText = textCount
    }
}

extension TeamDescriptionEditView {
    enum Layout {
        static let wrapperTopMargin: CGFloat = 16
        static let labelTopMargin: CGFloat = 4
        static let labelBottomMargin: CGFloat = 8
        static let inputTextViewTopMargin: CGFloat = 14
        static let inputTextViewBottomMargin: CGFloat = 16
        static var totalMargin: CGFloat {
            return wrapperTopMargin + labelTopMargin + labelBottomMargin + inputTextViewBottomMargin + inputTextViewTopMargin
        }
    }
}

enum RightItemStyle {
    case display, edit
}
