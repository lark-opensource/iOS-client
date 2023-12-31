//
//  MomentSettingViewModel.swift
//  Moment
//
//  Created by zc09v on 2021/6/11.
//
import LarkFeatureGating
import RxSwift
import LarkContainer
import LKCommonsLogging
import RxCocoa
import DateToolsSwift
import Foundation
import LarkSetting

enum MomentSettingItemType {
    // 公司圈通知
    case notify
    // 公司圈花名设置
    case nickNamce
}

protocol MomentSettingItem {
    var cellIdentifier: String { get }
    var title: String { get }
    var type: MomentSettingItemType { get }
}

final class MomentSettingViewModel: UserResolverWrapper {
    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    enum ErrorType {
        case notifySetFail
    }
    static let logger = Logger.log(MomentSettingViewModel.self, category: "Module.Moments.Setting")
    private(set) var items: [[MomentSettingItem]] = []
    var userCircleConfig: RawData.UserCircleConfig?
    @ScopedInjectedLazy var settingService: MomentsConfigAndSettingService?
    @ScopedInjectedLazy private var settingNot: MomentsUserGlobalConfigAndSettingNotification?
    @ScopedInjectedLazy private var redDotNotifyService: RedDotNotifyService?
    private var currenttimeStamp: Int64 {
        return Int64(Date().timeIntervalSince1970)
    }

    /// 刷新信号
    public var tableRefreshPublish: PublishSubject<Void> = PublishSubject<Void>()
    public lazy var tableRefreshDriver: Driver<Void> = {
        return tableRefreshPublish.asDriver(onErrorJustReturn: ())
    }()

    /// 错误信号
    let errorPublish = PublishSubject<MomentSettingViewModel.ErrorType>()
    var errorDriver: Driver<MomentSettingViewModel.ErrorType> {
        return errorPublish.asDriver(onErrorRecover: { _ in Driver<MomentSettingViewModel.ErrorType>.empty() })
    }

    private let disposeBag = DisposeBag()

    /// 日期转换函数
    static func dateToString(_ date: Date, dateFormat: String = "yyyy-MM-dd") -> String {
        return date.format(with: dateFormat)
    }

    /// 日期转换推进（当前时间戳的下一天起始）
    static func tomorrowDay(_ date: Date) -> Date {
        return Calendar.current.startOfDay(for: date.tomorrow)
    }

    func setup() {
        settingService?.getUserSettingWithFinish { [weak self] setting in
            guard let self = self else { return }
            var notifyItem: [MomentSettingItem] = []
            notifyItem.append(NotifyMomentSettingItem(title: BundleI18n.Moment.Lark_Settings_MomentsNewMomentsBadgesTitle,
                                                      detail: self.getRedDotNotifyItemDetail(adminEnableRedDotNotify: setting.adminEnableRedDotNotify),
                                                      isOn: setting.adminEnableRedDotNotify && !setting.muteRedDotNotify,
                                                      isEnable: setting.adminEnableRedDotNotify,
                                                      handleIsOn: { [weak self] isOn in
                                                         self?.setRedDotNotify(enable: isOn)
                                                      }))
            self.items.append(notifyItem)
            self.tableRefreshPublish.onNext(())
            self.setUserCircleConfig()
        } onError: { error in
            Self.logger.error("getUserSetting error", error: error)
        }

        settingNot?.rxConfig.subscribe(onNext: { [weak self] nof in
            guard let self = self,
                  let notifyItems = self.items.first(where: { notifyItem in
                      return notifyItem.first?.type == .notify
                  }),
                  let notifyItem = notifyItems.first as? NotifyMomentSettingItem else {
                      return
                  }
            notifyItem.isOn = nof.userSetting.adminEnableRedDotNotify && !nof.userSetting.muteRedDotNotify
            notifyItem.isEnable = nof.userSetting.adminEnableRedDotNotify
            notifyItem.detail = self.getRedDotNotifyItemDetail(adminEnableRedDotNotify: nof.userSetting.adminEnableRedDotNotify)
            self.tableRefreshPublish.onNext(())
            Self.logger.info("recive userSettingnNof isOn: \(!nof.userSetting.muteRedDotNotify), isEnable: \( nof.userSetting.adminEnableRedDotNotify)")
        }).disposed(by: self.disposeBag)
    }

    // 获取并设置花名信息（从userCircleConfig中获取）
    private func setUserCircleConfig() {
        var nickNameItem: [MomentSettingItem] = []
        self.settingService?.getUserCircleConfigWithFinsih({ [weak self] (config) in
            /// 判断当前开启了花名模式，并且当前用户选择过花名
            self?.userCircleConfig = config
            let fgValue = (try? self?.userResolver.resolve(assert: FeatureGatingService.self))?.staticFeatureGatingValue(with: "moments.profile.new") ?? false
            if config.anonymityPolicy.enabled,
               config.anonymityPolicy.type == .nickname,
               !config.nicknameUser.userID.isEmpty,
               fgValue {
                // 添加花名名称
                nickNameItem.append(CardMomentSettingItem(title: BundleI18n.Moment.Moments_Settings_MyNicknameProfilePage_Button, subtitleLabel: config.nicknameUser.name ?? "" ))
                // 添加花名修改时间
                let date = Date(timeIntervalSince1970: TimeInterval(config.renewNicknameTimeSec))
                let tomorrowtimeStamp = MomentSettingViewModel.tomorrowDay(date).timeIntervalSince1970
                if self?.currenttimeStamp ?? 0 > Int64(tomorrowtimeStamp) {
                    /// 花名到期，可修改
                    nickNameItem.append(CardMomentSettingItem(
                        title: BundleI18n.Moment.Moments_Settings_AddNewNicknameExpired_Button,
                        subtitleLabel: ""))
                } else {
                    /// 花名未到期
                    nickNameItem.append(CardMomentSettingItem(title: BundleI18n.Moment.Moments_Settings_AddNewNicknameExpired_Button,
                                                              subtitleLabel: BundleI18n.Moment.Moments_Settings_AddNewNickname_AddAfterDate_Placeholder(
                                                                MomentSettingViewModel.dateToString(MomentSettingViewModel.tomorrowDay(date)
                                                                ))))
                }
                self?.items.append(nickNameItem)
                self?.tableRefreshPublish.onNext(())
            }
        }, onError: { error in
            Self.logger.error("getUserCircleConfig error", error: error)
        })
    }

    /// 用于修改花名后，刷新花名信息
    func refreshItems() {
        var nickNameItem: [MomentSettingItem] = []
        nickNameItem.append(CardMomentSettingItem(title: BundleI18n.Moment.Moments_Settings_MyNicknameProfilePage_Button, subtitleLabel: userCircleConfig?.nicknameUser.name ?? "" ))
        if let renewNicknameTimeSec = userCircleConfig?.renewNicknameTimeSec {
            let date = Date(timeIntervalSince1970: TimeInterval(renewNicknameTimeSec))
            let tomorrowtimeStamp = MomentSettingViewModel.tomorrowDay(date).timeIntervalSince1970
            if currenttimeStamp > Int64(tomorrowtimeStamp) {
                /// 花名到期，可修改
                nickNameItem.append(CardMomentSettingItem(
                    title: BundleI18n.Moment.Moments_Settings_AddNewNicknameExpired_Button,
                    subtitleLabel: ""))
            } else {
                /// 花名未到期
                nickNameItem.append(CardMomentSettingItem(title: BundleI18n.Moment.Moments_Settings_AddNewNicknameExpired_Button,
                                                          subtitleLabel: BundleI18n.Moment.Moments_Settings_AddNewNickname_AddAfterDate_Placeholder(
                                                            MomentSettingViewModel.dateToString(MomentSettingViewModel.tomorrowDay(date)
                                                            ))))
            }
        } else {
            /// 打印日志
            Self.logger.error("MomentSettingViewModel renewNicknameTimeSec error")
        }

        if let idx = self.items.firstIndex(where: { arr in
            return arr.first?.type == .nickNamce
        }) {
            self.items[idx] = nickNameItem
        }
    }

    private func getRedDotNotifyItemDetail(adminEnableRedDotNotify: Bool) -> String {
        return adminEnableRedDotNotify ? BundleI18n.Moment.Moments_RedDotBadgesTurnedOn_Text : BundleI18n.Moment.Moments_RedDotBadgesTurnedOff_Text
    }

    private func setRedDotNotify(enable: Bool) {
        settingService?.setRedDotNotify(enable: enable, finish: { [weak self] success in
            //该设置存在多端同步，设置成功后，会通过push来设置状态
            if !success {
                self?.errorPublish.onNext(.notifySetFail)
                self?.tableRefreshPublish.onNext(())
            } else {
                self?.redDotNotifyService?.setMuteRedDotNotify(!enable)
            }
        })
        MomentsTracer.trackSettingDetailClick(type: .notice(enable))
    }
}
