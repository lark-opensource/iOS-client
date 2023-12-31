//
//  MedalDetailViewController.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/9/8.
//

import UIKit
import Foundation
import LarkUIKit
import LarkContainer
import RxSwift
import RxCocoa
import ServerPB
import ByteWebImage
import UniverseDesignIcon

final class MedalDetailViewController: BaseUIViewController, UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver

    public override var navigationBarStyle: NavigationBarStyle {
        return .clear
    }

    @ScopedInjectedLazy private var profileAPI: LarkProfileAPI?

    private let userID: String
    private var medal: LarkMedalItem?

    private var disposeBag = DisposeBag()

    private lazy var cardView: UIView = {
        let cardView = UIView()
        cardView.layer.cornerRadius = 16
        cardView.clipsToBounds = true
        cardView.backgroundColor = UIColor.ud.bgFloat
        return cardView
    }()

    private lazy var medalImageView: UIImageView = {
        let medalImageView = UIImageView()
        return medalImageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.numberOfLines = 2
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 4
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textPlaceholder
        return label
    }()

    private lazy var invalidImageView: UIImageView = {
        let invalidImageView = UIImageView()
        invalidImageView.contentMode = .scaleAspectFill
        invalidImageView.image = BundleResources.LarkProfile.invalid_bg_image
        invalidImageView.isHidden = true
        return invalidImageView
    }()

    private lazy var invalidLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.numberOfLines = 1
        label.textColor = UIColor.ud.iconDisabled
        label.text = BundleI18n.LarkProfile.Lark_Profile_Expired
        label.isHidden = true
        return label
    }()

    public init(resolver: UserResolver, userID: String, medal: LarkMedalItem?) {
        self.userID = userID
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
        self.medal = medal
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        LarkProfileTracker.trackAvatarMedalDetailClick(extra: ["medal_id": self.medal?.medalID])
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = BundleI18n.LarkProfile.Lark_Profile_BadgeDetails

        self.view.backgroundColor = UIColor.ud.bgBase

        layoutSubViews()

        if let medal = self.medal {
            self.profileAPI?.getMedalDetailBy(userID: userID,
                                             medalID: medal.medalID,
                                             grantID: medal.grantID)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] res in
                    self?.setDetail(response: res)
                }).disposed(by: disposeBag)
        } else {
            self.profileAPI?.getCurrentMedalBy(userID: userID)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] res in
                    self?.setDetail(response: res.transformData())
                }).disposed(by: disposeBag)
        }
    }

    func setDetail(response: ServerPB_Medal_GetUserMedalDetailResponse) {
        self.titleLabel.text = response.name.getString()
        self.subTitleLabel.text = response.explanation.getString()
        self.invalidLabel.isHidden = response.isValid
        self.invalidImageView.isHidden = response.isValid
        LarkProfileTracker.trackAvatarMedalDetailView(invalidImageView.isHidden,
                                                      extra: ["medal_id": self.medal?.medalID,
                                                              "to_user_id": userID])

        let startTime = transformData(timeStamp: response.effectTime)
        let endTime = transformData(timeStamp: response.expireTime)

        self.timeLabel.text = BundleI18n.LarkProfile.Lark_Profile_ValidFor + " \(startTime) - \(endTime)"

        var passThrough = ImagePassThrough()
        passThrough.key = response.medalImage.key
        passThrough.fsUnit = response.medalImage.fsUnit

        self.medalImageView.bt.setLarkImage(with: .default(key: response.medalImage.key),
                                            placeholder: BundleResources.LarkProfile.default_bg_image,
                                            passThrough: passThrough)
    }

    func layoutSubViews() {
        self.view.addSubview(cardView)
        cardView.addSubview(medalImageView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subTitleLabel)
        cardView.addSubview(timeLabel)
        cardView.addSubview(invalidImageView)
        invalidImageView.addSubview(invalidLabel)

        invalidLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 12).inverted()

        cardView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide).offset(40)
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(500)
        }

        medalImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(58)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(160)
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(medalImageView.snp.bottom).offset(26)
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
        }

        subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.equalTo(titleLabel)
        }

        timeLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-19)
            make.left.right.equalTo(titleLabel)
        }

        invalidImageView.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
        }

        invalidLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview().multipliedBy(1.16)
            make.centerY.equalToSuperview().multipliedBy(0.83)
        }
    }

    private func transformData(timeStamp: Int64) -> String {
        if timeStamp == -1 {
            return BundleI18n.LarkProfile.Lark_Profile_BadgeNeverExpires
        }
        let timeMatter = DateFormatter()
        timeMatter.dateFormat = "yyyy.MM.dd"

        let timeInterval: TimeInterval = TimeInterval(timeStamp)
        let date = Date(timeIntervalSince1970: timeInterval)

        return timeMatter.string(from: date)
    }
}

extension ServerPB_Medal_GetUserTakingMedalResponse {
    func transformData() -> ServerPB_Medal_GetUserMedalDetailResponse {
        var res = ServerPB_Medal_GetUserMedalDetailResponse()
        res.medalImage = self.medalImage
        res.medalShowImage = self.medalShowImage
        res.name = self.name
        res.explanation = self.explanation
        res.isValid = self.isValid
        res.effectTime = self.effectTime
        res.expireTime = self.expireTime

        return res
    }
}
