//
//  InMeetRegistry.swift
//  ByteView
//
//  Created by kiri on 2021/4/2.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewTracker
import ByteViewWidgetService

/// 会中组件注册功能，目前只注册了视图组件
final class InMeetRegistry {
    static let shared = InMeetRegistry()

    private var viewComponents: [InMeetViewComponent.Type] = {
        var fullScreenTypes: [InMeetViewComponent.Type] = [
            InMeetTransitionComponent.self,
            InMeetBroadcastComponent.self,
            InMeetCountDownComponent.self,
            InMeetTopBarComponent.self,
            InMeetPopoverComponent.self,
            InMeetBottomBarComponent.self,
            InMeetFlowComponent.self,
            InMeetShareComponent.self,
            InMeetSubtitleComponent.self,
            InMeetTipsComponent.self,
            InMeetAttentionComponent.self,
            InMeetInterpreterComponent.self,
            InMeetSingleVideoComponent.self,
            InMeetOrientationToolComponent.self,
            InMeetGuideComponent.self,
            InMeetReconnectComponent.self,
            InMeetMiscComponent.self,
            InMeetRtcComponent.self,
            InMeetBatteryComponent.self,
            InMeetReactionComponent.self,
            InMeetMessageBubbleComponent.self,
            InMeetInteractionComponent.self,
            InMeetMeetingStatusComponent.self,
            InMeetAnchorToastComponent.self,
            InMeetActiveSpeakerComponent.self,
            InMeetEffectComponent.self,
            TopExtendContainerComponent.self,
            InMeetWebinarRehearsalComponent.self,
            InMeetNotesComponent.self
        ]
        if Display.phone {
            fullScreenTypes.append(InMeetLandscapeToolsComponent.self)
            fullScreenTypes.append(InMeetMobileLandscapeRightComponent.self)
        }
        return fullScreenTypes
    }()

    let viewModelConfigs: [ObjectIdentifier: InMeetViewModelConfig] = {
        var configs: [ObjectIdentifier: InMeetViewModelConfig] = [:]
        func vm<T: InMeetViewModelComponent>(_ vmType: T.Type, isLazy: Bool = true) {
            let config = InMeetViewModelConfig(vmType, isLazy: isLazy)
            configs[config.id] = config
        }
        vm(InMeetRtcViewModel.self, isLazy: false)
        vm(InMeetRecordViewModel.self, isLazy: false)
        vm(InMeetTranscribeViewModel.self, isLazy: false)
        vm(InMeetActiveSpeakerViewModel.self, isLazy: false)
        vm(InMeetLiveViewModel.self, isLazy: false)
        vm(InMeetBillingViewModel.self, isLazy: false)
        vm(InMeetChimeViewModel.self, isLazy: false)
        vm(InMeetTrackViewModel.self, isLazy: false)
        vm(InMeetPerfMonitor.self, isLazy: false)
        vm(InMeetAudioViewModel.self, isLazy: false)
        vm(InMeetMiscViewModel.self, isLazy: false)
        vm(InMeetSelfShareScreenViewModel.self, isLazy: false)
        vm(InMeetShareScreenVM.self, isLazy: false)
        vm(InMeetLobbyViewModel.self, isLazy: false)
        vm(InMeetSubtitleViewModel.self, isLazy: false)
        vm(InMeetTipViewModel.self, isLazy: false)
        vm(HowlingDetection.self, isLazy: false)
        vm(InMeetAutoEndViewModel.self, isLazy: false)
        vm(InMeetRenameViewModel.self, isLazy: false)
        vm(FocusVideoManager.self, isLazy: false)
        vm(InMeetHeartbeatTrackViewModel.self, isLazy: false)
        vm(InMeetWebSpaceManager.self, isLazy: false)
        vm(InMeetInterviewSpaceViewModel.self, isLazy: false)
        vm(InMeetShareViewModel.self, isLazy: false)
        vm(InMeetWbManager.self)
        vm(InMeetFollowManager.self)
        vm(BreakoutRoomManager.self)
        vm(InMeetHandsUpViewModel.self)
        vm(InMeetInterpreterViewModel.self)
        vm(InMeetGridViewModel.self)
        vm(ChatMessageViewModel.self)
        vm(ToolBarViewModel.self)
        vm(InMeetFlowMeetingStatusViewModel.self)
        vm(FloatingInteractionViewModel.self)
        vm(InMeetFlowStatusViewModel.self)
        vm(InMeetRtcNetworkStatusViewModel.self)
        vm(CountDownManager.self)
        vm(InMeetPerfAdjustViewModel.self, isLazy: false)
        vm(InMeetTopBarViewModel.self)
        vm(InMeetMyselfViewModel.self, isLazy: false)
        vm(InMeetStatusReactionViewModel.self)
        vm(InMeetVoteViewModel.self)
        vm(InMeetBatteryStatusManager.self)
        #if DEBUG
        vm(InMeetDebugViewModel.self, isLazy: false)
        #endif
        vm(InMeetPhoneCallViewModel.self, isLazy: false)
        vm(InMeetStatusManager.self)
        vm(IMChatViewModel.self, isLazy: false)
        vm(MyAIViewModel.self, isLazy: false)
        vm(ShareWatermarkManager.self, isLazy: false)
        #if swift(>=5.7.1)
        if #available(iOS 16.1, *), ByteViewWidgetService.areActivitiesEnabled {
            vm(InMeetLiveActivityViewModel.self, isLazy: false)
        }
        #endif
        vm(InMeetRefuseReplyViewModel.self, isLazy: false)
        vm(InMeetNotesProviderViewModel.self, isLazy: false)
        vm(InMeetBenefitViewModel.self, isLazy: false)
        vm(InMeetHandoffViewModel.self, isLazy: false)
        return configs
    }()

    func loadComponents(_ container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext,
                        successHandler: (InMeetViewComponent) -> Void,
                        errorHandler: (Error) -> Bool = { _ in false }) {
        for t in viewComponents {
            do {
                let c = try t.init(container: container, viewModel: viewModel, layoutContext: layoutContext)
                #if DEBUG
                Util.observeDeinit(c)
                #endif
                let name = "InMeetViewComponent_\(c.componentIdentifier.rawValue)"
                MemoryLeakTracker.addAssociatedItem(c as AnyObject, name: name, for: viewModel.meeting.sessionId)
                successHandler(c)
            } catch {
                if errorHandler(error) {
                    break
                }
            }
        }
    }
}

// MARK: - InMeetViewModelComponents
extension InMeetShareScreenVM: InMeetViewModelComponent {}
extension InMeetSelfShareScreenViewModel: InMeetViewModelComponent {}
extension InMeetRecordViewModel: InMeetViewModelComponent {}
extension InMeetTranscribeViewModel: InMeetViewModelComponent {}
extension InMeetTrackViewModel: InMeetViewModelComponent {}
extension InMeetAudioViewModel: InMeetViewModelComponent {}
extension InMeetTipViewModel: InMeetViewModelComponent {}
extension InMeetAutoEndViewModel: InMeetViewModelComponent {}
extension InMeetWhiteboardViewModel: InMeetViewModelComponent {}
extension InMeetHandsUpViewModel: InMeetViewModelComponent {}
extension InMeetLobbyViewModel: InMeetViewModelComponent {}
extension InMeetSubtitleViewModel: InMeetViewModelComponent {}
extension FocusVideoManager: InMeetViewModelComponent {}
extension InMeetGridViewModel: InMeetViewModelComponent {}
extension ToolBarViewModel: InMeetViewModelComponent {}
extension ShareWatermarkManager: InMeetViewModelComponent {}
extension FloatingInteractionViewModel: InMeetViewModelComponent {}
extension InMeetStatusReactionViewModel: InMeetViewModelComponent {}
extension InMeetFlowStatusViewModel: InMeetViewModelComponent { }
extension CountDownManager: InMeetViewModelComponent {}
#if swift(>=5.7.1)
@available(iOS 16.1, *)
extension InMeetLiveActivityViewModel: InMeetViewModelComponent {}
#endif
extension InMeetPerfMonitor: InMeetViewModelComponent {}
extension InMeetNotesProviderViewModel: InMeetViewModelComponent {}
extension InMeetBenefitViewModel: InMeetViewModelComponent {}

// MARK: - InMeetViewModelSimpleComponent
extension InMeetActiveSpeakerViewModel: InMeetViewModelSimpleComponent {}
extension InMeetLiveViewModel: InMeetViewModelSimpleComponent {}
extension InMeetChimeViewModel: InMeetViewModelSimpleComponent {}
extension HowlingDetection: InMeetViewModelSimpleComponent {}
extension InMeetRenameViewModel: InMeetViewModelSimpleComponent {}
extension InMeetWbManager: InMeetViewModelSimpleComponent {}
extension InMeetFollowManager: InMeetViewModelSimpleComponent {}
extension InMeetMiscViewModel: InMeetViewModelSimpleComponent {}
extension BreakoutRoomManager: InMeetViewModelSimpleComponent {}
extension InMeetPerfAdjustViewModel: InMeetViewModelComponent {}
extension InMeetPhoneCallViewModel: InMeetViewModelSimpleComponent {}
#if DEBUG
extension InMeetDebugViewModel: InMeetViewModelSimpleComponent {}
#endif
extension InMeetBatteryStatusManager: InMeetViewModelComponent {}

// MARK: - InMeetViewModelSimpleContextComponent
extension ChatMessageViewModel: InMeetViewModelSimpleContextComponent {}
extension IMChatViewModel: InMeetViewModelSimpleContextComponent {}
extension InMeetInterpreterViewModel: InMeetViewModelSimpleContextComponent {}
extension MyAIViewModel: InMeetViewModelSimpleContextComponent {}

// MARK: - Customized InMeetViewModelComponent
extension InMeetBillingViewModel: InMeetViewModelComponent {
    convenience init(resolver: InMeetViewModelResolver) {
        self.init(meeting: resolver.meeting,
                  tips: resolver.resolve())
    }
}

extension InMeetRtcViewModel: InMeetViewModelComponent {
    convenience init(resolver: InMeetViewModelResolver) {
        self.init(meeting: resolver.meeting,
                  context: resolver.viewContext,
                  breakoutRoom: resolver.resolve()!)
    }
}

extension InMeetFlowMeetingStatusViewModel: InMeetViewModelComponent {
    convenience init(resolver: InMeetViewModelResolver) {
        self.init(meeting: resolver.meeting, context: resolver.viewContext, resolver: resolver)
    }
}

extension InMeetRtcNetworkStatusViewModel: InMeetViewModelComponent {
    convenience init(resolver: InMeetViewModelResolver) {
        self.init(meeting: resolver.meeting, context: resolver.viewContext, breakoutRoom: resolver.resolve())
    }
}

extension InMeetTopBarViewModel: InMeetViewModelComponent {
    convenience init(resolver: InMeetViewModelResolver) {
        self.init(meeting: resolver.meeting,
                  context: resolver.viewContext,
                  resolver: resolver)
    }
}

extension InMeetStatusManager: InMeetViewModelComponent {
    convenience init(resolver: InMeetViewModelResolver) {
        self.init(meeting: resolver.meeting, context: resolver.viewContext, resolver: resolver)
    }
}

extension InMeetRefuseReplyViewModel: InMeetViewModelComponent {}
