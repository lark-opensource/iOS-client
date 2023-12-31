//
//  MailSearchResultView.swift
//  MailSDK
//
//  Created by tefeng liu on 2019/7/8.
//

import Foundation
import Lottie
import UniverseDesignButton
import RxSwift

protocol MailSearchResultViewDelegate: AnyObject {
    func noNetworkBannerRetryHandler()
    func reloadTrashMailButtonHandler()
}

class MailSearchResultView: UIView {
    enum Status {
        case none, result, resultInOffline, noResult, noNormalResult // 联网状态下【正常邮件】无法命中，但【已删除/垃圾邮件】有命中
        case fail, failInOffline, noResultInOffline, noNormalResultInOffline // 离线状态下【正常邮件】无法命中，但【已删除/垃圾邮件】有命中
        case retry, autoSearchRemote, autoSearchRemoteInOffline
        case noResultWithFilter, noResultWithFilterInOffline
    }

    fileprivate(set) var tableview: UITableView = .init(frame: .zero)

    let noResultView: UIView
    private let icon = UIImageView()
    private let textLabel = UILabel()
    private let animationView: LOTAnimationView = {
        let animation = AnimationViews.spinAnimation
        animation.backgroundColor = UIColor.clear
        animation.contentMode = .scaleAspectFit
        animation.isHidden = true
        return animation
    }()
    private lazy var noNetworkBanner: MailSearchNoNetworkBanner = {
        let view = MailSearchNoNetworkBanner(viewWidth: self.viewWidth, scene: self.scene)
        view.didTapHeader = { [weak self] in
            self?.delegate?.noNetworkBannerRetryHandler()
        }
        view.isHidden = true
        return view
    }()
    private lazy var retryButton: UDButton = {
        var config = UDButtonUIConifg.secondaryGray
        config.type = .middle
        var button = UDButton(config)
        button.setTitle(BundleI18n.MailSDK.Mail_InternetCutOff_Reload_Button, for: .normal)
        button.isUserInteractionEnabled = false
        button.isHidden = true
        return button
    }()
    private lazy var hasTrashMailTipsLabel: UILabel = {
        let hasTrashMailTipsLabel = UILabel()
        hasTrashMailTipsLabel.font = UIFont.systemFont(ofSize: 14.0)
        hasTrashMailTipsLabel.textColor = .ud.textPlaceholder
        hasTrashMailTipsLabel.textAlignment = .center
        hasTrashMailTipsLabel.isHidden = true
        hasTrashMailTipsLabel.numberOfLines = 0
        return hasTrashMailTipsLabel
    }()
    private lazy var reloadTrashMailButton: UIButton = {
        let reloadTrashMailButton = UIButton(frame: CGRect(x: 0, y: 0, width: 125, height: 20))
        reloadTrashMailButton.setTitle(BundleI18n.MailSDK.Email_Shared_SearchMail_ViewMessages_Button, for: .normal)
        reloadTrashMailButton.titleLabel?.font = UIFont.systemFont(ofSize: 12.0)
        reloadTrashMailButton.setTitleColor(.ud.primaryPri500, for: .normal)
        reloadTrashMailButton.rx.tap.bind { [weak self] in
            self?.delegate?.reloadTrashMailButtonHandler()
        }.disposed(by: disposeBag)
        reloadTrashMailButton.isHidden = true
        reloadTrashMailButton.isUserInteractionEnabled = true
        return reloadTrashMailButton
    }()
    var viewWidth: CGFloat = 0.0
    weak var delegate: MailSearchResultViewDelegate?
    let disposeBag = DisposeBag()

    var status: Status = .none {
        didSet {
            self.noResultView.isHidden = true
            self.tableview.isHidden = true
            self.retryButton.isHidden = true
            self.hasTrashMailTipsLabel.isHidden = true
            self.reloadTrashMailButton.isHidden = true
            self.animationView.isHidden = true
            self.animationView.stop()
            switch status {
            case .none:
                self.noResultView.isHidden = false
                self.icon.image = Resources.feed_empty_data_icon
                self.textLabel.text = BundleI18n.MailSDK.Mail_ASLSearch_EmailTab_EmptyStateText
                self.isUserInteractionEnabled = false
                self.setNoNetBannerHidden(true)
            case .result:
                self.tableview.isHidden = false
                self.isUserInteractionEnabled = true
                self.setNoNetBannerHidden(true)
            case .resultInOffline:
                self.noResultView.isHidden = true
                self.tableview.isHidden = false
                self.isUserInteractionEnabled = true
                self.setNoNetBannerHidden(false)
            case .noResult:
                self.noResultView.isHidden = false
                self.update()
                self.icon.image = Resources.mail_search_empty
                self.isUserInteractionEnabled = false
                self.setNoNetBannerHidden(true)
            case .noResultInOffline:
                self.noResultView.isHidden = false
                self.update()
                self.icon.image = Resources.mail_search_empty
                self.isUserInteractionEnabled = true
                self.setNoNetBannerHidden(false)
            case .noResultWithFilter:
                self.noResultView.isHidden = false
                self.textLabel.text = BundleI18n.MailSDK.Mail_AdvancedSearch_NoData
                self.icon.image = Resources.mail_search_empty
                self.isUserInteractionEnabled = true
                self.setNoNetBannerHidden(true)
            case .noResultWithFilterInOffline:
                self.noResultView.isHidden = false
                self.textLabel.text = BundleI18n.MailSDK.Mail_AdvancedSearch_NoData
                self.icon.image = Resources.mail_search_empty
                self.isUserInteractionEnabled = true
                self.setNoNetBannerHidden(false)
            case .fail:
                self.noResultView.isHidden = false
                icon.image = Resources.feed_error_icon
                textLabel.text = BundleI18n.MailSDK.Mail_Common_NetworkError
                self.isUserInteractionEnabled = true
                self.setNoNetBannerHidden(true)
            case .failInOffline:
                self.noResultView.isHidden = false
                icon.image = Resources.feed_error_icon
                textLabel.text = BundleI18n.MailSDK.Mail_InternetCutOff_ConnectAndReload_Empty
                retryButton.isHidden = false
                self.isUserInteractionEnabled = true
                self.setNoNetBannerHidden(false)
            case .retry:
                self.noResultView.isHidden = false
                icon.image = Resources.feed_error_icon
                textLabel.text = BundleI18n.MailSDK.Mail_ThirdClinet_FailedToLoadRetry
                self.isUserInteractionEnabled = true
                self.setNoNetBannerHidden(true)
            case .autoSearchRemote:
                self.tableview.isHidden = false
                self.animationView.isHidden = false
                self.animationView.play()
                self.isUserInteractionEnabled = false
                self.setNoNetBannerHidden(true)
                self.animationView.snp.remakeConstraints { (make) in
                    make.centerX.equalToSuperview()
                    make.top.equalTo(10)
                    make.width.height.equalTo(20)
                }
            case .autoSearchRemoteInOffline:
                self.tableview.isHidden = false
                self.animationView.isHidden = false
                self.animationView.play()
                self.isUserInteractionEnabled = false
                self.setNoNetBannerHidden(false)
                self.animationView.snp.remakeConstraints { (make) in
                    make.centerX.equalToSuperview()
                    make.top.equalTo(noNetworkBanner.snp.bottom).offset(10)
                    make.width.height.equalTo(20)
                }
            case .noNormalResult:
                hasTrashMailTipsLabel.isHidden = false
                reloadTrashMailButton.isHidden = false
                setNoNetBannerHidden(true)
                hasTrashMailTipsLabel.text = BundleI18n.MailSDK.Email_Shared_SearchMail_MatchResultInTrashOrSpam_Notice
                hasTrashMailTipsLabel.sizeToFit()
                isUserInteractionEnabled = true
            case .noNormalResultInOffline:
                hasTrashMailTipsLabel.isHidden = false
                reloadTrashMailButton.isHidden = false
                setNoNetBannerHidden(false)
                hasTrashMailTipsLabel.text = BundleI18n.MailSDK.Email_Shared_SearchMail_MatchResultInTrashOrSpam_Notice
                hasTrashMailTipsLabel.sizeToFit()
                isUserInteractionEnabled = true
            }
        }
    }
    var scene: MailSearchScene = .inMailTab

    init(delegate: MailSearchResultViewDelegate? = nil, noResultView: UIView? = nil, scene: MailSearchScene = .inMailTab, viewWidth: CGFloat) {
        self.noResultView = noResultView ?? UIView()
        self.scene = scene
        self.delegate = delegate
        self.viewWidth = viewWidth
        super.init(frame: CGRect(x: 0, y: 0, width: viewWidth, height: Display.height))
        self.initTable()

        self.textLabel.textColor = UIColor.ud.textCaption
        self.addSubview(self.noResultView)
        self.noResultView.isHidden = true
        if noResultView == nil {
            self.initNoResultView()
        }
        self.addSubview(self.animationView)
        self.animationView.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(10)
            make.width.height.equalTo(20)
        }
        
        // noNetworkBanner
        addSubview(noNetworkBanner)
        noNetworkBanner.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(noNetworkBanner.bannerHeight)
        }

        addSubview(hasTrashMailTipsLabel)
        hasTrashMailTipsLabel.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(28)
            make.centerX.equalToSuperview()
            make.top.equalTo(noNetworkBanner.snp.bottom).offset(150)
        }

        addSubview(reloadTrashMailButton)
        reloadTrashMailButton.snp.makeConstraints { (make) in
            make.top.equalTo(hasTrashMailTipsLabel.snp.bottom).offset(4)
            make.centerX.equalTo(textLabel)
            make.height.equalTo(36)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window = self.window else { return }
        if scene == .inSearchTab {
            let top = UIScreen.main.bounds.height / 3
            self.noResultView.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.top.greaterThanOrEqualToSuperview()
                make.top.equalTo(window).offset(top).priority(780)
                make.width.equalToSuperview()
            }
        } else {
            self.noResultView.snp.remakeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.centerY.equalTo(window)
                make.width.equalToSuperview()
            }
        }
    }
    
    func setNoNetBannerHidden(_ isHidden: Bool) {
        guard FeatureManager.open(FeatureKey(fgKey: .offlineSearch, openInMailClient: true)) else { return }
        guard noNetworkBanner.isHidden != isHidden else {
            return
        }
        noNetworkBanner.isHidden = isHidden
        var inset = tableview.contentInset
        let needScrollToTop = tableview.contentOffset.y == 0
        inset.top += isHidden ? -noNetworkBanner.bannerHeight : noNetworkBanner.bannerHeight
        tableview.contentInset = inset
        if needScrollToTop {
            tableview.btd_scrollToTop()
        }
    }

    func refreshNoResultView(_ keyword: String) {
        update(keyword)
    }

    fileprivate func initTable() {
        let tableview = UITableView(frame: .zero, style: .plain)
        tableview.isHidden = true
        tableview.backgroundColor = UIColor.clear
        tableview.separatorColor = UIColor.clear
        tableview.separatorStyle = .none
        tableview.estimatedRowHeight = 64
        tableview.estimatedSectionHeaderHeight = 0
        tableview.estimatedSectionFooterHeight = 0
        tableview.rowHeight = UITableView.automaticDimension
        tableview.keyboardDismissMode = .onDrag
        tableview.contentInset = UIEdgeInsets.zero
        tableview.allowsMultipleSelection = true
        tableview.showsVerticalScrollIndicator = false
        tableview.tableFooterView = UIView()
        self.addSubview(tableview)
        tableview.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        tableview.contentInsetAdjustmentBehavior = .automatic
//        tableview.alwaysBounceVertical = true
        self.tableview = tableview
    }

    fileprivate func initNoResultView() {
        // 图标
        icon.image = Resources.mail_search_empty
        let iconSize = CGSize(width: 100, height: 100)
        noResultView.addSubview(icon)
        icon.snp.makeConstraints({ make in
            make.size.equalTo(iconSize)
            make.centerX.equalToSuperview()
            if scene == .inSearchTab {
                make.top.equalToSuperview()
            } else {
                make.top.equalToSuperview().offset(-50)
            }
        })

        noResultView.addSubview(textLabel)
        textLabel.textAlignment = .center
        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.lineBreakMode = .byTruncatingMiddle
        textLabel.numberOfLines = 0
        textLabel.snp.makeConstraints({ make in
            make.top.equalTo(icon.snp.bottom).offset(16)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.bottom.equalToSuperview()
        })
        
        noResultView.addSubview(retryButton)
        retryButton.snp.makeConstraints { (make) in
            make.top.equalTo(textLabel.snp.bottom).offset(16)
            make.centerX.equalTo(textLabel)
            make.height.equalTo(36)
        }

        noResultView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    private func update(_ keyword: String = "") {
        let wholeText = BundleI18n.MailSDK.Mail_Search_NoResultFound(keyword)
        let template = BundleI18n.MailSDK.__Mail_Search_NoResultFound as NSString

        let attributedString = NSMutableAttributedString(string: wholeText)
        attributedString.addAttribute(.foregroundColor,
                                      value: UIColor.ud.textCaption,
                                      range: NSRange(location: 0, length: attributedString.length))
        let start = template.range(of: "{{").location
        if start != NSNotFound {
            attributedString.addAttribute(.foregroundColor,
                                          value: UIColor.ud.primaryContentDefault,
                                          range: NSRange(location: start, length: (keyword as NSString).length))
        }

        textLabel.attributedText = attributedString
    }
}
