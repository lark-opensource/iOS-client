//
//  Provider+UserInfo.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/7/27.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkLocalizations
import UniverseDesignIcon
import UniverseDesignTag
import LarkMessengerInterface
import UniverseDesignToast
import EENavigator
import SwiftProtobuf
import ByteWebImage
import LarkUIKit
import LarkFeatureGating
import RustPB
import Swinject
import LarkSDKInterface

extension LarkProfileDataProvider {
    // swiftlint:disable function_body_length
    public func getUserInfo() -> ProfileUserInfo {
        guard let userInfo = userProfile?.userInfoProtocol else {
            return ProfileUserInfo(name: "", isSelf: false)
        }

        let company: UIView? = generateCompanyView()

        let tagViews: [UIView] = generateTagViews()

        var customBadges: [UIView] = []
        let customeFields = userInfo.customTagFields
        if !customeFields.isEmpty {
            customeFields.forEach { field in
                var options = JSONDecodingOptions()
                options.ignoreUnknownFields = true
                if let customImg = try? LarkUserProfile.CustomImage(jsonString: field.jsonFieldVal, options: options) {
                    let imageView = UIImageView()
                    customBadges.append(imageView)
                    imageView.bt.setLarkImage(with: .default(key: customImg.resourceKey),
                                              trackStart: {
                                                return TrackInfo(scene: .Profile, fromType: .avatar)
                                              },
                                              completion: { [weak imageView] result in
                                                  switch result {
                                                  case let .success(imageResult):
                                                      if let image = imageResult.image {
                                                          imageView?.image = image
                                                          imageView?.snp.makeConstraints { make in
                                                              make.width.equalTo(image.size.width / image.size.height * 18)
                                                          }
                                                      }
                                                  case .failure: break
                                                  }
                                              })
                }
            }
        }
        let descriptionView: ProfileStatusView? = generateUserDescription(userInfo: userInfo)
        let settingService = try? userResolver.resolve(assert: UserUniversalSettingService.self)
        return ProfileUserInfo(id: userInfo.userID,
                               name: userInfo.displayName(with: settingService),
                               alias: userInfo.alias,
                               pronouns: userInfo.genderPronouns,
                               nameTag: tagViews,
                               customBadges: customBadges,
                               descriptionView: descriptionView,
                               companyView: company,
                               focusList: userInfo.chatterStatus,
                               isSelf: currentChatterId == userInfo.userID,
                               metaUnitDescription: userInfo.metaUnitDescription.getString())
    }
    // swiftlint:enable function_body_length

    private func isSameYear(timeStamp1: Int64, timeStamp2: Int64) -> Bool {

        let timeInterval1: TimeInterval = TimeInterval(timeStamp1)
        let date1 = Date(timeIntervalSince1970: timeInterval1)

        let timeInterval2: TimeInterval = TimeInterval(timeStamp2)
        let date2 = Date(timeIntervalSince1970: timeInterval2)

        let comp1 = Calendar.current.dateComponents([.year], from: date1)
        let comp2 = Calendar.current.dateComponents([.year], from: date2)

        return comp1.year == comp2.year
    }

    private func transformData(timeStamp: Int64, showYear: Bool) -> String {
        let timeMatter = DateFormatter()
        if showYear {
            timeMatter.dateFormat = "yyyy/MM/dd"
        } else {
            timeMatter.dateFormat = "MM/dd"
        }

        let timeInterval: TimeInterval = TimeInterval(timeStamp)
        let date = Date(timeIntervalSince1970: timeInterval)

        return timeMatter.string(from: date)
    }
}

