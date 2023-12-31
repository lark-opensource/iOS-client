//
//  CalendarDetailCardViewController.swift
//  Calendar
//
//  Created by Hongbin Liang on 4/13/23.
//

import Foundation
import UIKit
import LarkBizAvatar
import RxSwift
import LarkUIKit
import UniverseDesignButton
import UniverseDesignIcon

struct CalendarDetailHeaderData {
    var title: String
    var avatarInfo: CalendarAvatar
}

struct CalendarDetailContentData {
    var ownerName: String
    var subscriberNum: Int
    var description: String
    var hasSubscribed: Bool
}

class CalendarDetailCardViewController: UIViewController {
    private let fullScreenCloseButton = UIButton(type: .custom)
    private let fakeNaviTitle = UILabel()
    private let loadingView = LoadingPlaceholderView()
    private let fullScreenTipView = PlaceHolderIconLabelView()
    private let failedRetryView = LoadFaildRetryView()

    private let headerContainer = UIView()
    private let headerBG = CalendarDetailHeaderBGView()
    private let titleLabel = UILabel()
    private let avatarView = BizAvatar()

    private let scrollView = UIScrollView()
    private let ownerLabel = UILabel.cd.textLabel()
    private let ownerDetailLabel = UILabel.cd.textLabel()
    private let subscriberNumLabel = UILabel.cd.textLabel()
    private let numDetailLabel = UILabel.cd.textLabel()
    private let descLabel = UILabel.cd.textLabel()
    private let descDetailLabel = UILabel.cd.textLabel()

    private let bottomBtn = UDButton()

    typealias ViewModel = CalendarDetailCardViewModel
    private let viewModel: ViewModel
    private let disposeBag = DisposeBag()

    init(viewModel: CalendarDetailCardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .ud.bgBody
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutContent()

        layoutDecorations()
        bindData()
    }

    private func layoutDecorations() {
        loadingView.text = I18n.Calendar_Common_LoadingCommon
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(failedRetryView)
        failedRetryView.retryAction = { [weak self] in
            self?.viewModel.reload()
        }
        failedRetryView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(fullScreenTipView)
        fullScreenTipView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        fullScreenCloseButton.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        view.addSubview(fullScreenCloseButton)
        fullScreenCloseButton.snp.makeConstraints {
            $0.size.equalTo(CalendarUI.closeIconSize)
            $0.leading.equalTo(16)
            $0.top.equalTo(CalendarUI.closeIconY)
        }

        fakeNaviTitle.textColor = .ud.staticWhite
        view.addSubview(fakeNaviTitle)
        fakeNaviTitle.font = UIFont.cd.mediumFont(ofSize: 17)
        fakeNaviTitle.text = I18n.Calendar_Calendar_CalendarDetails
        fakeNaviTitle.snp.makeConstraints { make in
            make.centerY.equalTo(fullScreenCloseButton.snp.centerY)
            make.centerX.equalToSuperview()
        }
    }

    private func layoutContent() {
        view.addSubview(headerContainer)
        headerContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(230)
        }

        headerContainer.addSubview(headerBG)
        headerBG.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerContainer.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.leading.equalTo(20)
            make.size.equalTo(CGSize(width: 72, height: 72))
            make.bottom.equalTo(-24)
        }

        titleLabel.font = UIFont.systemFont(ofSize: 20)
        titleLabel.textColor = .ud.staticWhite
        titleLabel.numberOfLines = 2
        headerContainer.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(avatarView.snp.trailing).offset(20)
            make.centerY.equalTo(avatarView.snp.centerY)
            make.trailing.equalTo(-20)
        }

        var btnConfig: UDButtonUIConifg = .secondaryBlue
        btnConfig.type = .big
        bottomBtn.config = btnConfig

        view.addSubview(bottomBtn)
        bottomBtn.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).inset(12)
            make.height.equalTo(48)
        }

        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBtn.snp.top).offset(-12)
        }
        let showSubscribers = FG.showSubscribers

        let contentWrapper = UIView()
        scrollView.addSubview(contentWrapper)
        contentWrapper.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview().inset(20)
            make.centerX.bottom.equalToSuperview()
        }

        let ownerStr = I18n.Calendar_Share_Owner
        ownerLabel.text = ownerStr
        ownerLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        ownerLabel.textColor = .ud.textCaption
        contentWrapper.addSubview(ownerLabel)

        let subscriberNumStr = I18n.Calendar_Share_HowManySubscribedNoColon_Desc
        subscriberNumLabel.text = showSubscribers ? subscriberNumStr : ""
        subscriberNumLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        subscriberNumLabel.textColor = .ud.textCaption
        if showSubscribers { contentWrapper.addSubview(subscriberNumLabel) }

        let descStr = showSubscribers ? I18n.Calendar_Share_CalendarDescNoColon_Desc : I18n.Calendar_Edit_Description
        descLabel.text = descStr
        descLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        descLabel.textColor = .ud.textCaption
        contentWrapper.addSubview(descLabel)

        ownerDetailLabel.numberOfLines = 2
        contentWrapper.addSubview(ownerDetailLabel)

        if showSubscribers { contentWrapper.addSubview(numDetailLabel) }

        descDetailLabel.numberOfLines = 0
        contentWrapper.addSubview(descDetailLabel)

        ownerLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview()
        }

        if showSubscribers {
            subscriberNumLabel.snp.makeConstraints { make in
                make.top.equalTo(ownerDetailLabel.snp.bottom).offset(16)
                make.leading.equalToSuperview()
            }
        }

        descLabel.snp.makeConstraints { make in
            make.top.equalTo((showSubscribers ? subscriberNumLabel : ownerDetailLabel).snp.bottom).offset(16)
            make.leading.equalToSuperview()
        }

        let longestLabel = [ownerLabel, subscriberNumLabel, descLabel].max { lLabel, rLabel in
            lLabel.text?.width(with: .systemFont(ofSize: 16)) ?? 0 < rLabel.text?.width(with: .systemFont(ofSize: 16)) ?? 0
        } ?? descLabel

        ownerDetailLabel.snp.makeConstraints { make in
            make.leading.equalTo(longestLabel.snp.trailing).offset(16)
            make.top.equalTo(ownerLabel.snp.top)
            make.trailing.lessThanOrEqualToSuperview()
        }

        if showSubscribers {
            numDetailLabel.snp.makeConstraints { make in
                make.leading.equalTo(longestLabel.snp.trailing).offset(16)
                make.top.equalTo(subscriberNumLabel.snp.top)
                make.trailing.lessThanOrEqualToSuperview()
            }
        }

        descDetailLabel.snp.makeConstraints { make in
            make.leading.equalTo(longestLabel.snp.trailing).offset(16)
            make.top.equalTo(descLabel.snp.top)
            make.trailing.lessThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    private func bindData() {
        viewModel.rxViewStatus
            .subscribeForUI { [weak self] status in
                guard let self = self else { return }
                // reset
                self.loadingView.isHidden = true
                self.failedRetryView.isHidden = true
                self.fullScreenTipView.isHidden = true

                if case .loading = status { self.loadingView.isHidden = false }

                if case .error(let errorType) = status, case .fetchError = errorType {
                    self.failedRetryView.isHidden = false
                }

                if case .error(let errorType) = status, case .apiError(let errorInfo) = errorType {
                    self.fullScreenTipView.isHidden = false
                    self.fullScreenTipView.image = errorInfo.definedType.defaultImage()
                    self.fullScreenTipView.title = errorInfo.tip
                    CalendarBiz.detailLogger.error(errorInfo.tip)
                }

                if case .dataLoaded = status {
                    CalendarTracerV2.CalendarCard.traceView { $0.calendar_id = self.viewModel.calID ?? "" }
                }

                let showContent = self.loadingView.isHidden && self.failedRetryView.isHidden && self.fullScreenTipView.isHidden
                let iconColor = showContent ? UIColor.ud.staticWhite : UIColor.ud.iconN1
                let closeIcon = UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined, iconColor: iconColor).scaleNaviSize()
                self.fullScreenCloseButton.setImage(closeIcon, for: .normal)
                self.fakeNaviTitle.isHidden = !showContent
            }.disposed(by: disposeBag)

        viewModel.rxHeaderData
            .subscribeForUI { [weak self] headerData in
                guard let self = self, let headerData = headerData else { return }
                self.titleLabel.text = headerData.title
                switch headerData.avatarInfo {
                case let .normal(avatar: image, key: key):
                    var avatarInfo: (avatar: UIImage, key: String)
                    if let image = image {
                        avatarInfo = (image, key)
                    } else {
                        avatarInfo = ViewModel.defaultAvatar
                    }
                    self.avatarView.image = avatarInfo.avatar
                    self.headerBG.setHeaderBGImageWithOriginImage(avatarInfo.avatar, avatarInfo.key)
                case let .primary(avatarKey: key, identifier: identifier):
                    self.avatarView.setAvatarByIdentifier(identifier, avatarKey: key, avatarViewParams: .defaultBig) { [weak self] imageResult in
                        guard let self = self else { return }
                        var avatarInfo: (avatar: UIImage, key: String)
                        if case .success(let imageResult) = imageResult, let image = imageResult.image {
                            avatarInfo = (image, imageResult.request.requestKey)
                        } else {
                            avatarInfo = ViewModel.defaultAvatar
                            CalendarBiz.detailLogger.error("header avatar download failed, use the defaul")
                        }
                        self.headerBG.setHeaderBGImageWithOriginImage(avatarInfo.avatar, avatarInfo.key)
                    }
                }
            }.disposed(by: disposeBag)

        viewModel.rxContentData
            .subscribeForUI { [weak self] contentData in
                guard let self = self, let contentData = contentData else { return }
                self.ownerDetailLabel.text = contentData.ownerName
                self.descDetailLabel.text = contentData.description
                self.numDetailLabel.text = String(contentData.subscriberNum)
                self.bottomBtn.tag = contentData.hasSubscribed ? 0 : 1
                self.bottomBtn.addTarget(self, action: #selector(self.bottomBtnClicked), for: .touchUpInside)
                self.bottomBtn.setTitle(contentData.hasSubscribed ? I18n.Calendar_Share_View : I18n.Calendar_Bot_SubscribeButton, for: .normal)
            }.disposed(by: disposeBag)

        viewModel.rxToastStatus
            .bind(to: rx.toast).disposed(by: disposeBag)
    }

    @objc
    private func bottomBtnClicked(_ sender: UIButton) {
        if sender.tag == 0 {
            self.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.viewModel.jumpToSlideView(from: self)
            }
        } else if sender.tag == 1 {
            viewModel.doSubscribe()

            CalendarTracerV2.CalendarCard.traceClick {
                $0.click("sub")
                $0.calendar_id = self.viewModel.calID ?? ""
            }
        } else {
            CalendarBiz.detailLogger.error("bottomBtnClicked outof range")
        }
    }

    @objc
    private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
