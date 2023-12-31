//
//  Resources.swift
//  Moments
//
//  Created by liluobin on 2021/1/7.
//

import Foundation
import LarkLocalizations
import UniverseDesignIcon
import UIKit

public final class Resources {
    public static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.MomentBundle, compatibleWith: nil) ?? UIImage()
    }

    static let personInfoRightOutlined = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.iconN3)

    static let momentsinteractiveIcon = UDIcon.getIconByKey(.memberFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    static let momentsTrampleLight = UDIcon.getIconByKey(.thumbdownOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let momentsTrampleDark = UDIcon.getIconByKey(.thumbdownFilled, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let momentsTrampleClose = UDIcon.getIconByKey(.closeCircleColorful, size: CGSize(width: 24, height: 24))
    static let momentsTrampleLoad = UDIcon.getIconByKey(.loadingOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.lineBorderCard)
    static let momentsRightOutlined = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 7.06, height: 13.33)).ud.withTintColor(UIColor.ud.iconN3)
    static let momentsClose = UDIcon.closeFilled.ud.withTintColor(UIColor.ud.iconN2)
    static let momentsAdd = UDIcon.getIconByKey(.addOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.N500)

    static let momentsNavBarClose = UDIcon.closeSmallOutlined.ud.withTintColor(UIColor.ud.iconN1)

    static let momentsThumbsup = UDIcon.getIconByKey(.thumbsupOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)
    static let momentsThumbsupDisabled = UDIcon.getIconByKey(.thumbsupOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconDisabled)
    static let momentsReply = UDIcon.getIconByKey(.replyCnOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let momentsReplyDisabled = UDIcon.getIconByKey(.replyCnOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconDisabled)
    static let momentsForward = UDIcon.getIconByKey(.shareOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let momentsMore = UDIcon.getIconByKey(.moreOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)
    static let momentsMoreN2 = UDIcon.getIconByKey(.moreOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let momentsMoreNav = UDIcon.getIconByKey(.moreBoldOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
    static let momentsSharePostLink = UDIcon.getIconByKey(.linkCopyOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)

    static let shareMoments = UDIcon.getIconByKey(.shareOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1) // note: 没有被用上
    static let replyClose = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 15, height: 15)).ud.withTintColor(UIColor.ud.iconN3)

    static let momentVideoPlay = Resources.image(named: "video_play")

    static let postSendingStatus = Resources.image(named: "postSendingStatus")
    //udicon 使用colorful的图片的时候，在这里直接定义uiimage的时候似乎无法适配darkmode，所以写成block，在给imageview赋值时再取
    static let postSendFail: (() -> UIImage) = {
        return UDIcon.getIconByKey(.warningRedColorful, size: CGSize(width: 20, height: 20)).withRenderingMode(.alwaysOriginal)
    }
    static let postInIsUnderReview = UDIcon.getIconByKey(.infoFilled, size: CGSize(width: 20, height: 20))

    static let postFollow = UDIcon.getIconByKey(.addOutlined, iconColor: .ud.primaryContentDefault, size: CGSize(width: 14, height: 14))
    static let postFollowing = Resources.image(named: "postFollowing")

    static let momentsHotComment = Resources.image(named: "moments_hot_comment")

    static let postDetailNoPermission = Resources.image(named: "postDetailNoPermission")
    static let postDeleted = Resources.image(named: "postDeleted")
    static let reactionImageUnknown = Resources.image(named: "reaction_image")
    static let postEveryOneCanSee = Resources.image(named: "everyOneCanSee")
    static let postJustAutherSee = UDIcon.getIconByKey(.invisibleOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let iconBellOutlined = UDIcon.bellOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let iconVideoFilled = UDIcon.videoFilled.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let iconSendPostVideo = UDIcon.expandRightFilled.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let boardcast = UDIcon.getIconByKey(.setTopOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let cancelBoardcast = UDIcon.getIconByKey(.setTopCancelOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let editBoardcast = UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)

    static let iconUserProfile = UDIcon.memberOutlined.ud.withTintColor(UIColor.ud.iconN1)
    static let iconUserAvatarBg = Resources.image(named: "avatar_bg")
    static let whiteBack = Resources.image(named: "back_white")
    static let blackBack = UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.iconN1)

    /// 菜单相关按钮
    static let menuCopy = UDIcon.getIconByKey(.copyOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
    static let menuReply = UDIcon.getIconByKey(.replyCnOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
    static let menuReplyDisabled = UDIcon.getIconByKey(.replyCnOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconDisabled)
    static let menuDelete = UDIcon.getIconByKey(.deleteTrashOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)
    static let menuReport = UDIcon.getIconByKey(.alarmOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN1)

    static let placedPostHeaderPinned_overseas = Resources.image(named: "pinnedMoment_overseas")
    static let placedPostHeaderPinned_CN = Resources.image(named: "pinnedMoment_cn")
    static let placedPostHeaderBack_light = Resources.image(named: "placedPostHeaderBack_light")
    static let placedPostHeaderBack_dark = Resources.image(named: "placedPostHeaderBack_dark")
    static let placedPostHeaderRight = Resources.image(named: "placedPostHeaderRight")
    static let nickNameArrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
    static let rightArrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 13, height: 13)).ud.withTintColor(UIColor.ud.iconN3)
    static let placeBoardcastSelect = UDIcon.listCheckOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    static let momentNoFollows = Resources.image(named: "moment_no_follows")
    static let detailNavArrow = UDIcon.getIconByKey(.expandRightFilled, size: CGSize(width: 10, height: 10)).ud.withTintColor(UIColor.ud.iconN1)
    static let popOverMenuDeleteTrash = UDIcon.getIconByKey(.deleteTrashOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let popOverMenuAlarm = UDIcon.getIconByKey(.alarmOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
    static let allArrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.iconN3)
    static let listCheck = UDIcon.listCheckColorful
    static let leftShadow = Resources.image(named: "left_shadow")
    static let rightShadow = Resources.image(named: "right_shadow")
    static let categoryBack = UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let rightEidtMenu = Resources.image(named: "moments_right_menu")
    static let categoryDele = UDIcon.getIconByKey(.noFilled, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulRed)
    static let categoryAdd = UDIcon.getIconByKey(.moreAddFilled, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.colorfulGreen)
    static let refreshIcon = UDIcon.getIconByKey(.refreshOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let refreshNormal = Resources.image(named: "refresh_normal")
    static let refreshHighLight = Resources.image(named: "refresh_highLight")
    static let refreshLoadingBg = Resources.image(named: "refresh_loading_bg")
    static let hashTagheaderBgDarkMode = Resources.image(named: "hashTagheaderBgDarkMode")
    static let hashTagheaderBgLightMode = Resources.image(named: "hashTagheaderBgLightMode")
    static let hashTagheaderBgPadLeft = Resources.image(named: "hashTagheaderBgPadLeft")
    static let hashTagheaderBgPadRight = Resources.image(named: "hashTagheaderBgPadRight")
    static let rightArrowFilled = UDIcon.getIconByKey(.expandRightFilled)
    static let categoriesOutlined = UDIcon.getIconByKey(.momentsCategoriesOutlined)
    static let bellCoverOutlined = Resources.image(named: "bell_cover_outlined")
    static let bellColumnOutlined = Resources.image(named: "bell_column_outlined")
    static let imageDownloadFailed = UDIcon.loadfailFilled.ud.withTintColor(UIColor.ud.iconN3)
    static let addOutlined = UDIcon.getIconByKey(.addOutlined, renderingMode: .alwaysTemplate, iconColor: .white, size: CGSize(width: 24, height: 24))
    static let leftOutlined = UDIcon.getIconByKey(.leftOutlined,
                                                  renderingMode: .alwaysTemplate,
                                                  size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
}
