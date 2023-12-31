//
//  CalendarChatterPicker.swift
//  LarkSearchCore
//
//  Created by SolaWing on 2020/12/21.
//

import UIKit
import Foundation
import RustPB
import LarkModel
import Homeric
import RxSwift
import SnapKit
import LarkSDKInterface
import LarkContainer

public final class CalendarChatterPicker: AddChatterPicker {
    public final class InitParam: AddChatterPicker.InitParam {
        /// 包含邮箱联系人
        public var includeMailContact = false
        /// 包含Meeting群组
        public var includeMeetingGroup = false
    }

    public let includeMailContact: Bool
    public let includeMeetingGroup: Bool

    public init(resolver: LarkContainer.UserResolver, frame: CGRect, params: InitParam) {
        includeMailContact = params.includeMailContact
        includeMeetingGroup = params.includeMeetingGroup
        super.init(resolver: resolver, frame: frame, params: params)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var mailSuggestView = ContactSearchMailSuggestionView()
    // MARK: Bind
    public override var searchLocation: String { "CalendarChatterPicker" }
    override var needShowMail: Bool { includeMailContact }

    override func viewLoaded() {
        super.viewLoaded()

        includeMailContact: if includeMailContact {
            guard let stackView = selectedView.superview as? UIStackView else {
                assertionFailure("should layout in UIStackView")
                break includeMailContact
            }
            // mailSuggestView 高亮会透视，暂时直接加一个白底容器
            let mailSuggestViewContainer = UIView()
            mailSuggestViewContainer.backgroundColor = UIColor.ud.bgBody
            mailSuggestViewContainer.isOpaque = true
            mailSuggestViewContainer.addSubview(mailSuggestView)

            mailSuggestView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            mailSuggestView.frame = mailSuggestViewContainer.bounds

            stackView.addArrangedSubview(mailSuggestViewContainer)

            mailSuggestViewContainer.snp.makeConstraints {
                $0.height.equalTo(54)
            }
            mailSuggestView.rx.observe(Bool.self, "hidden").subscribe(onNext: {
                mailSuggestViewContainer.isHidden = $0 != false
            }).disposed(by: bag)
            mailSuggestView.isHidden = true

            mailSuggestView.addTarget(self, action: #selector(addMailByClickingSuggestion), for: .touchUpInside)
            searchBar.searchUITextField.addTarget(self, action: #selector(addMailByClickingEnter), for: .editingDidEndOnExit)
            searchVM.query.text.observeOn(MainScheduler.instance)
                    .bind(onNext: { [weak self] in self?.checkMailMatchText(text: $0) })
                    .disposed(by: bag)
        }
    }
    override func makeListVM() -> SearchListVM<SearchResultType> {
        let includeMailContact = self.includeMailContact
        return SearchListVM(source: makeSource(), pageCount: Self.defaultPageCount, compactMap: { (result: SearchItem) -> SearchResultType? in
            guard let result = result as? SearchResultType else {
                assertionFailure("unsupported type")
                return nil
            }
            let filter = { () -> Bool in
                if result.type == .mailContact {
                    return includeMailContact
                }
                return true
            }
            return filter() ? result : nil
        })
    }
    override func makeSource() -> SearchSource {
        var maker = RustSearchSourceMaker(resolver: self.userResolver, scene: .rustScene(.searchInCalendarScene))
        // 默认选中群里的所有人。使用场景为：群添加人，能搜索到这个人，但已经选中在群里，不需要再添加了
        // Rust会返回meta.inChatIds来标记这个人在哪些群里
        if let chatID = forceSelectedInChatId { maker.inChatID = chatID }
        maker.doNotSearchResignedUser = true
        maker.includeMailContact = includeMailContact
        // 接入方判断meta.isMeeting，给予提示和接口兼容
        maker.includeMeetingGroup = includeMeetingGroup
        // 群和部门的配置始终包含，再通过动态context进行开关
        maker.includeChat = true
        maker.includeDepartment = true
        return maker.makeAndReturnProtocol()
    }

    // MARK: Delegate, Callback
    public override func makeViewModel(item: SearchResultType) -> SearchResultType? {
        guard let item = super.makeViewModel(item: item) else { return nil }
        if case .chatter(let meta) = item.meta {
            assert(Thread.isMainThread, "should occur on main thread!")
            // check result has same mailAddress as input, and hide the added mailSuggestView
            if includeMailContact && !mailSuggestView.isHidden && meta.mailAddress.caseInsensitiveCompare(searchVM.query.text.value) == .orderedSame {
                mailSuggestView.isHidden = true
            }
        }
        return item
    }
    private lazy var isShowDepartmentInfoFG = SearchFeatureGatingKey.showDepartmentInfo.isUserEnabled(userResolver: self.userResolver)
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isShowDepartmentInfoFG { return UITableView.automaticDimension }
        guard includeMailContact else { return PickerConstant.UI.rowHeight }
        return ContactSearchTableViewCell.getCellHeight(searchResult: results[indexPath.row], needShowMail: includeMailContact)
    }

    private func checkMailMatchText(text: String) {
        let validEmailAddrs = ContactSearchMailSuggestionView.extractMailAddrs(from: text)
        if !validEmailAddrs.isEmpty {
            var text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if validEmailAddrs.count == 1 {
                text = BundleI18n.Calendar.Calendar_CalMail_InviteEmail + text
            } else {
                text = BundleI18n.Calendar.Calendar_EmailGuest_AddXEmailsMobile(validEmailAddrs.count, text)
            }
            mailSuggestView.updateText(text)
            mailSuggestView.isHidden = false
        } else {
            mailSuggestView.isHidden = true
        }
    }
    @objc
    private func addMailByClickingEnter() {
        addMailFromSuggesttion()
        SearchTrackUtil.track(Homeric.CAL_EMAIL_GUEST, params: ["action_type": "enter"])
    }
    @objc
    private func addMailByClickingSuggestion() {
        addMailFromSuggesttion()
        SearchTrackUtil.track(Homeric.CAL_EMAIL_GUEST, params: ["action_type": "invite"])
    }

    private func addMailFromSuggesttion() {
        let addrs = ContactSearchMailSuggestionView.extractMailAddrs(from: searchVM.query.text.value)
        guard !addrs.isEmpty else { return }
        var hasSuccess = false
        for i in addrs {
            hasSuccess = self.select(option: OptionIdentifier(type: OptionIdentifier.Types.mailContact.rawValue, id: i), from: self) || hasSuccess
        }
        afterSelected(success: hasSuccess)
    }
}

/// recognize a single mail address
private func extractMailAddr(from text: String) -> String? {
    guard let leftBracketIndex = text.range(of: "<")?.lowerBound else {
        return emailRegex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
                         .map { _ in text }
    }
    guard let rightBracketIndex = text.range(of: ">")?.lowerBound else {
        return nil
    }
    guard leftBracketIndex < text.endIndex,
        rightBracketIndex <= text.endIndex,
        leftBracketIndex < rightBracketIndex else {
        return nil
    }
    let addrText = String(text[text.index(after: leftBracketIndex) ..< rightBracketIndex])
        .trimmingCharacters(in: .whitespaces)

    return emailRegex.firstMatch(in: addrText, options: [], range: NSRange(location: 0, length: addrText.utf16.count))
                     .map { _ in addrText }
}

private let emailRegex = try! NSRegularExpression( // swiftlint:disable:this all
    pattern: "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    options: [])

public final class ContactSearchMailSuggestionView: UIButton {
    /// extract multiple mail address(eg: zzz@xxx.com), by special seperator(see impl)
    static public func extractMailAddrs(from text: String) -> [String] {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else { return [] }

        let separators: CharacterSet
        if text.contains("<") {
            // 分隔符：全角/半角分号，全角/半角逗号
            separators = CharacterSet(charactersIn: ";；,，")
        } else {
            // 分隔符：全角/半角分号，全角/半角逗号，全角/半角空格
            separators = CharacterSet(charactersIn: ";；,， 　")
        }
        let texts = text.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let validAddrs = texts.compactMap(extractMailAddr(from:))
        guard texts.count == validAddrs.count else {
            return []
        }

        return validAddrs
    }

    public override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UIColor.ud.fillFocus
            } else {
                backgroundColor = UIColor.ud.bgBody
            }
        }
    }

    private let surggestionLabel: UILabel = {
        let surggestionLabel = UILabel()
        surggestionLabel.textColor = UIColor.ud.textTitle
        surggestionLabel.font = UIFont.systemFont(ofSize: 16)
        surggestionLabel.numberOfLines = 1
        return surggestionLabel
    }()

    public init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.ud.bgBody // 防止下面的defaultView展示出来

        let icon = UIImageView(image: Resources.LarkSearchCore.Calendar.invite_mail_attendee)
        addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(12)
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }

        addSubview(surggestionLabel)
        surggestionLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(48)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(line)
        line.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview()
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
    }

    public func updateText(_ text: String) {
        surggestionLabel.text = text
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
