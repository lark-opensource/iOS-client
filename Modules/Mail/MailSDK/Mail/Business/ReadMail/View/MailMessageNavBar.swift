//
//  MailMessageNavBar.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/4/21.
//

import Foundation
import LarkUIKit
import RxSwift
import UIKit
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor

public enum MailMessageNavBarType {
    case FeedNavBarType
    case NormalNavBarType
}

protocol MailMessageNavBarDelegate: AnyObject {
    func searchKeywordDidChange(_ keyword: String?)
    func exitContentSearch()
}

protocol MailFeedNavBarDelegate: AnyObject {
    func jumpToProfile(emailAddress: String, name: String)
    func feedMoreAction(address: String, name: String, sender: UIControl)
}

/// 实现读信页 NavBar，使用LarkUIKit/TitleNaviBar
/// 实现自定义隐藏效果
class MailMessageNavBar: UIView {

    static var navBarHeight: CGFloat {
        return MailTitleNaviBar.navBarHeight
    }

    // 获取 ActionType 对应的按钮
    var rightItemsMap = [ActionType: UIButton]()

    private let disposeBag = DisposeBag()
    let address: String
    let name: String
    let titleNavBar: TitleNaviBar
    private let navBarAnimateInterval: TimeInterval = 0.3
    private lazy var searchNavBar: MailSearchNaviBar? = {
        let searchBar = MailSearchNaviBar()

        searchBar.cancelButton.rx.tap.asDriver().drive(onNext: { [weak self] () in
            self?.delegate?.exitContentSearch()
        }).disposed(by: disposeBag)

        searchBar.searchTextField.rx
            .controlEvent([.editingChanged])
            .asObservable()
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance).subscribe(onNext: { [weak self] _ in
                guard let self = self, self.isInSearchMode else { return }
                self.searchTextChanged()
            })
            .disposed(by: self.disposeBag)

        return searchBar
    }()

    var isInSearchMode: Bool = false

    weak var delegate: MailMessageNavBarDelegate?
    weak var feedDelegate: MailFeedNavBarDelegate?
    
    var type: MailMessageNavBarType = .NormalNavBarType
    
    init(type: MailMessageNavBarType = .NormalNavBarType, address: String = "", name: String = "") {
        self.type = type
        self.name = name
        self.address = address
        if type == .NormalNavBarType {
            self.titleNavBar = MailTitleNaviBar(titleString: "")
        } else {
            let titleView = MailFeedTitleView(title: name, mailFrom: address) // title
            self.titleNavBar = MailFeedTitleNaviBar(titleView: titleView)
        }
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var navBarHeight: CGFloat {
        return titleNavBar.naviBarHeight
    }
    
    /// 设置bar右边actionsItem并返回对应的buttons，可以进行进一步设置
    @discardableResult
    func setRightItems(_ rightItems: [TitleNaviBarItem]) -> [UIButton]? {
        titleNavBar.rightItems = rightItems
        let rightViews = titleNavBar.rightViews as? [UIButton]
        setupBarButtons(rightViews)
        rightItemsMap.removeAll()
        if let rightButtons = rightViews {
            zip(rightItems, rightButtons).map { itemAndButton in
                rightItemsMap[itemAndButton.0.mailActionType] = itemAndButton.1
            }
        }
        return rightViews
    }

    /// 设置bar左边actionsItem并返回对应的buttons，可以进行进一步设置
    @discardableResult
    func setLeftItems(_ leftItems: [TitleNaviBarItem]) -> [UIButton]? {
        titleNavBar.leftItems = leftItems
        let leftViews = titleNavBar.leftViews as? [UIButton]

        leftViews?.enumerated().forEach({ (index, btn) in
            let id = "\(MailAccessibilityIdentifierKey.ReadMailLeftNavKey)_\(index)"
            btn.accessibilityIdentifier = id
        })
        setupBarButtons(leftViews)
        return leftViews
    }

    func setNavBarHidden(_ navBarHidden: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: navBarAnimateInterval) {
                self.alpha = navBarHidden ? 0 : 1
            }
        } else {
            self.alpha = navBarHidden ? 0 : 1
        }
    }

    func showSearchBar() {
        guard let searchNavBar = searchNavBar else {
            return
        }
        isInSearchMode = true
        func showSearchBarAnimation() {
            searchNavBar.searchTextField.becomeFirstResponder()
            searchNavBar.isHidden = false
            UIView.animate(withDuration: navBarAnimateInterval) {
                searchNavBar.snp.remakeConstraints { (make) in
                    make.left.right.top.equalToSuperview()
                    make.bottom.equalToSuperview()
                }
                searchNavBar.superview?.layoutIfNeeded()
            }
        }

        if searchNavBar.superview == nil {
            addSubview(searchNavBar)
            searchNavBar.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(snp.top)
            }
            DispatchQueue.main.async {
                showSearchBarAnimation()
            }
        } else {
            showSearchBarAnimation()
        }
    }

    @objc
    func hideSearchBar() {
        guard let searchNavBar = searchNavBar, searchNavBar.superview != nil else {
            return
        }
        isInSearchMode = false
        searchNavBar.searchTextField.resignFirstResponder()
        UIView.animate(withDuration: navBarAnimateInterval) {
            searchNavBar.snp.remakeConstraints { (make) in
                make.left.right.equalToSuperview()
                make.bottom.equalTo(self.snp.top)
            }
            searchNavBar.superview?.layoutIfNeeded()
        } completion: { (finish) in
            if finish {
                searchNavBar.reset()
                searchNavBar.isHidden = true
            }
        }
    }

    func updateSearchCount(currentIdx: Int, total: Int) {
        searchNavBar?.updateSearchCount(currentIdx: currentIdx, total: total)
    }

    func showLoading(_ show: Bool) {
        searchNavBar?.showLoading(show)
    }

    // MARK: privte
    private func searchTextChanged() {
        let keyword = searchNavBar?.searchTextField.text
        delegate?.searchKeywordDidChange(keyword)
    }

    private func setupBarButtons(_ btns: [UIButton]?) {
        guard let btns = btns else { return }
        for btn in btns {
            var img: UIImage? = nil
            if let mode = btn.image(for: .normal)?.renderingMode {
                img = btn.image(for: .normal)?.mail.alpha(0.7)?.withRenderingMode(mode)
            }
            btn.setImage(img, for: .highlighted)
            btn.tintColor = UIColor.ud.iconN1
        }
    }

    private func setupViews() {
        isUserInteractionEnabled = true
        backgroundColor = .clear
        addSubview(titleNavBar)
        titleNavBar.snp.makeConstraints { (make) in
            make.left.top.right.bottom.equalToSuperview()
        }
    }
}

/// 继承主端 TitleNaviBar
class MailTitleNaviBar: TitleNaviBar {

    static let navBarHeight: CGFloat = 44
    override init(titleView: UIView, leftBarItems: [TitleNaviBarItem] = [], rightBarItems: [TitleNaviBarItem] = []) {
        super.init(titleView: titleView, leftBarItems: leftBarItems, rightBarItems: rightBarItems)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        isUserInteractionEnabled = true
        titleView.removeFromSuperview()
        backgroundColor = UDColor.readMsgListBG
        (leftView as? UIStackView)?.spacing = 18
    }
    
    override func calcButtonsStackPadding() -> Int {
        return 16
    }

    override var naviBarHeight: CGFloat {
        return MailTitleNaviBar.navBarHeight
    }
}


private struct AssociatedKeys {
    static var mailActionType = "mailActionType"
}

extension TitleNaviBarItem {
    var mailActionType: ActionType {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.mailActionType) as? ActionType ?? .unknown
        }
        set {
            objc_setAssociatedObject(self,
                                     &AssociatedKeys.mailActionType,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

/// Feed读信页TitleNaviBar
class MailFeedTitleNaviBar: TitleNaviBar {
    
    static let navBarHeight: CGFloat = Display.pad ? 56 : 44
    var feedTitleView: MailFeedTitleView?
    weak var delegate: MailFeedNavBarDelegate?

    override init(titleView: UIView, leftBarItems: [TitleNaviBarItem] = [], rightBarItems: [TitleNaviBarItem] = []) {
        super.init(titleView: titleView, leftBarItems: leftBarItems, rightBarItems: rightBarItems)
        self.feedTitleView = titleView as? MailFeedTitleView
        setupViews()
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.titleViewTappedBlock = { [weak self] _ in
            self?.delegate?.jumpToProfile(emailAddress: self?.feedTitleView?.mailFrom ?? "", name: self?.feedTitleView?.name ?? "")
        }
        isUserInteractionEnabled = true
        (leftView as? UIStackView)?.spacing = 18
       
        titleView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(MailFeedTitleNaviBar.navBarHeight)
            if Display.pad {
                make.left.greaterThanOrEqualTo(108)
                make.bottom.equalToSuperview().offset(-6)
            } else {
                make.left.greaterThanOrEqualTo(self.leftView ?? 50)
                make.bottom.equalToSuperview()
            }
            make.right.lessThanOrEqualTo(self.rightView ?? -50)
        }
    }
    
    override func calcButtonsStackPadding() -> Int {
        return 16
    }

    override var naviBarHeight: CGFloat {
        return MailFeedTitleNaviBar.navBarHeight
    }
}

class MailFeedTitleView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.title3
        label.textColor = UDColor.textTitle
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        return label
    }()
    
    private let followIconImageView: UIImageView = {
        let imageView = UIImageView(image: UDIcon.laterFilled.ud.withTintColor(UDColor.colorfulYellow))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let arrowIconImageView: UIImageView = {
        let imageView = UIImageView(image: UDIcon.expandRightFilled)
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let mailFromLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.caption3
        label.textColor = UDColor.textCaption
        label.textAlignment = .center
        return label
    }()
    
    private let titleView: UIStackView = {
        let view = UIStackView()
        return view
    }()
    
    weak var delegate: MailFeedNavBarDelegate?
    var name = ""
    var mailFrom = ""
    
    init(title: String, mailFrom: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        mailFromLabel.text = mailFrom
        setupSubviews()
        self.name = title
        self.mailFrom = mailFrom
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        addSubview(mailFromLabel)
        addSubview(titleView)
        titleView.addArrangedSubview(titleLabel)
        titleView.addArrangedSubview(followIconImageView)
        titleView.addArrangedSubview(arrowIconImageView)
        titleView.axis = .horizontal
        titleView.alignment = .center
        titleView.spacing = 6
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.height.equalTo(24)
            make.right.equalTo(followIconImageView.snp.left).offset(-6)
        }
        
        mailFromLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-5.5)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
                        
        followIconImageView.snp.makeConstraints { make in
            make.width.equalTo(16)
            make.height.equalTo(16)
            make.right.equalTo(arrowIconImageView.snp.left).offset(-6)
        }
        
        arrowIconImageView.snp.makeConstraints { make in
            make.width.equalTo(12)
            make.height.equalTo(12)
            make.right.equalToSuperview()
        }
        
        titleView.snp.makeConstraints { make in
            make.bottom.equalTo(mailFromLabel.snp_topMargin).offset(-12)
            make.centerX.equalTo(mailFromLabel)
            let titleLabelSize = titleLabel.intrinsicContentSize
            make.height.equalTo(titleLabelSize.height)
            let titleViewWidth = titleLabelSize.width + 16 + 12 + 6 + 6
            make.width.equalTo(titleViewWidth).priority(.high)
            make.width.lessThanOrEqualToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        
        titleView.distribution = .fill
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        followIconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        arrowIconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        mailFromLabel.sizeToFit()
        
    }
}



