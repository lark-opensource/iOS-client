//
//  VCAlias.swift
//  ByteView
//
//  Created by kiri on 2021/6/20.
//

import Foundation
import ByteViewCommon
import SwiftProtobuf
import ByteViewUI
import ByteViewNetwork

typealias CommonResources = ByteViewCommon.BundleResources.ByteViewCommon.Common
typealias AvatarResources = ByteViewCommon.BundleResources.ByteViewCommon.Avatar

typealias I18n = BundleI18n.ByteView

// Common
typealias Logger = ByteViewCommon.Logger
typealias RwAtomic = ByteViewCommon.RwAtomic
typealias Listeners<Element> = ByteViewCommon.Listeners<Element>

// UI
typealias GuideView = ByteViewUI.GuideView
typealias GuideStyle = ByteViewUI.GuideStyle
typealias GuideDirection = ByteViewUI.GuideDirection
typealias TriangleView = ByteViewUI.TriangleView
typealias RefreshAnimator = ByteViewUI.RefreshAnimator
typealias VisualButton = ByteViewUI.VisualButton
typealias LoadingView = ByteViewUI.LoadingView
typealias LoadingButton = ByteViewUI.LoadingButton
typealias LoadingTipView = ByteViewUI.LoadingTipView
typealias AnchorToastView = ByteViewUI.AnchorToastView
typealias PaddingLabel = ByteViewUI.PaddingLabel

// DynamicModal
typealias DynamicModalDelegate = ByteViewUI.DynamicModalDelegate
typealias DynamicModalConfig = ByteViewUI.DynamicModalConfig
typealias DynamicModalPopoverConfig = ByteViewUI.DynamicModalPopoverConfig
typealias DynamicModalPresentationStyle = ByteViewUI.DynamicModalPresentationStyle
typealias PanChildViewControllerProtocol = ByteViewUI.PanChildViewControllerProtocol
typealias PanHeight = ByteViewUI.PanHeight
typealias PanWidth = ByteViewUI.PanWidth
typealias RoadAxis = ByteViewUI.RoadAxis
typealias RoadLayout = ByteViewUI.RoadLayout

// Utils
typealias Display = ByteViewCommon.Display

typealias ParticipantRole = Participant.Role
typealias FollowInfo = ByteViewNetwork.FollowInfo
typealias ByteviewUser = ByteViewNetwork.ByteviewUser
typealias I18nKeyInfo = ByteViewNetwork.I18nKeyInfo
typealias CalendarInfo = ByteViewNetwork.CalendarInfo
typealias LobbyInfo = ByteViewNetwork.LobbyInfo
typealias LobbyParticipant = ByteViewNetwork.LobbyParticipant
typealias PreLobbyParticipant = ByteViewNetwork.PreLobbyParticipant

typealias ParticipantMeetingRole = Participant.MeetingRole
typealias VideoChatSecuritySetting = VideoChatSettings.SecuritySetting
typealias PlanType = VideoChatSettings.PlanType

typealias LanguageType = InterpreterSetting.LanguageType

typealias BreakoutRoomInfo = ByteViewNetwork.BreakoutRoomInfo
typealias BreakoutRoomInfoStatus = BreakoutRoomInfo.Status

typealias InterpreterSetting = ByteViewNetwork.InterpreterSetting

typealias VirtualBackgroundInfo = ByteViewNetwork.VirtualBackgroundInfo
typealias FileStatus = VirtualBackgroundInfo.FileStatus
typealias VirtualBgMaterialSource = VirtualBackgroundInfo.MaterialSource
