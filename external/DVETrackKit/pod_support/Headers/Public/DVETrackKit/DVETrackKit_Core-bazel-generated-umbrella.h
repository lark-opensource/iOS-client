#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "DVEAttachRange.h"
#import "DVEAttachable.h"
#import "DVEAttacher.h"
#import "DVEAudioBeatsPoint.h"
#import "DVEAudioFadeInOutView.h"
#import "DVEAudioFeaturePoint.h"
#import "DVEAudioPoint.h"
#import "DVEAudioSegmentTag.h"
#import "DVEAudioWaveLayer.h"
#import "DVEAudioWaveView.h"
#import "DVEAudioWaveViewModel.h"
#import "DVEBorderEditView.h"
#import "DVEEditBoxCornerInfo.h"
#import "DVEEditBoxView.h"
#import "DVEEditItem.h"
#import "DVEEditTransform.h"
#import "DVEKeyFrameItem.h"
#import "DVEKeyFrameProtocol.h"
#import "DVEKeyFrameView.h"
#import "DVEKeyFrameViewModel.h"
#import "DVELinkageDescription.h"
#import "DVEMediaContext+AudioOperation.h"
#import "DVEMediaContext+Blend.h"
#import "DVEMediaContext+FilterOperation.h"
#import "DVEMediaContext+Operation.h"
#import "DVEMediaContext+Private.h"
#import "DVEMediaContext+SlotUtils.h"
#import "DVEMediaContext+StickerOperation.h"
#import "DVEMediaContext+VideoOperation.h"
#import "DVEMediaContext.h"
#import "DVEMediaContextNLEEditorDelegate.h"
#import "DVEMediaContextNLEInterfaceDelegate.h"
#import "DVEMediaContextPlayerDelegate.h"
#import "DVEMediaTimelineContentView.h"
#import "DVEMediaTimelineScaleHandler.h"
#import "DVEMediaTimelineView.h"
#import "DVEMultipleTrackAttacher.h"
#import "DVEMultipleTrackAudioCell.h"
#import "DVEMultipleTrackAudioCellViewModel.h"
#import "DVEMultipleTrackAudioViewModel.h"
#import "DVEMultipleTrackCollectionView.h"
#import "DVEMultipleTrackCombinationViewModel.h"
#import "DVEMultipleTrackController.h"
#import "DVEMultipleTrackEffectCell.h"
#import "DVEMultipleTrackEffectCellViewModel.h"
#import "DVEMultipleTrackEffectViewModel.h"
#import "DVEMultipleTrackFilterCell.h"
#import "DVEMultipleTrackFilterCellViewModel.h"
#import "DVEMultipleTrackFilterViewModel.h"
#import "DVEMultipleTrackStickerCell.h"
#import "DVEMultipleTrackStickerCellViewModel.h"
#import "DVEMultipleTrackStickerViewModel.h"
#import "DVEMultipleTrackType.h"
#import "DVEMultipleTrackVideoCell.h"
#import "DVEMultipleTrackVideoCellViewModel.h"
#import "DVEMultipleTrackVideoViewModel.h"
#import "DVEMultipleTrackView+Clip.h"
#import "DVEMultipleTrackView+EdgeDetect.h"
#import "DVEMultipleTrackView+Move.h"
#import "DVEMultipleTrackView.h"
#import "DVEMultipleTrackViewCell.h"
#import "DVEMultipleTrackViewCellViewModel.h"
#import "DVEMultipleTrackViewConstants.h"
#import "DVEMultipleTrackViewDelegate.h"
#import "DVEMultipleTrackViewFlowLayout.h"
#import "DVEMultipleTrackViewModel.h"
#import "DVEMultipleTrackViewProtocol.h"
#import "DVEMusicWaveGenerator.h"
#import "DVEOriginalSoundButton.h"
#import "DVEPinchControl.h"
#import "DVERulerModel.h"
#import "DVESegmentClipView.h"
#import "DVESelectSegment.h"
#import "DVETimelineGlobal.h"
#import "DVETimelineRuler.h"
#import "DVETimelineRulerViewModel.h"
#import "DVETools.h"
#import "DVETrackConfig.h"
#import "DVETrackUIModel.h"
#import "DVETransformEditView.h"
#import "DVETransformEventHandler.h"
#import "DVEVector2.h"
#import "DVEVideoAnimationChangePayload.h"
#import "DVEVideoAnimationShadowView.h"
#import "DVEVideoAttacher.h"
#import "DVEVideoSegmentClipInfo.h"
#import "DVEVideoSegmentView.h"
#import "DVEVideoThumbnailCell.h"
#import "DVEVideoThumbnailLayout.h"
#import "DVEVideoThumbnailLoader.h"
#import "DVEVideoThumbnailManager.h"
#import "DVEVideoThumbnailTask.h"
#import "DVEVideoThumbnailView.h"
#import "DVEVideoTrackPreviewDelegate.h"
#import "DVEVideoTrackPreviewView.h"
#import "DVEVideoTrackThumbnail.h"
#import "DVEVideoTrackViewModel.h"
#import "DVEVideoTransitionItem.h"
#import "DVEVideoTransitionModel.h"
#import "DVEVideoTriangleView.h"
#import "MPMacros.h"
#import "MPUIColorDefines.h"
#import "MPUILayoutDefines.h"
#import "MeepoButton.h"
#import "VEDGeometricDrawView.h"
#import "VEDMaskAbleProtocol.h"
#import "VEDMaskCircleDrawView.h"
#import "VEDMaskDrawView.h"
#import "VEDMaskEditView.h"
#import "VEDMaskEditViewConfig.h"
#import "VEDMaskEditViewProtocol.h"
#import "VEDMaskLineDrawView.h"
#import "VEDMaskMirrorDrawView.h"
#import "VEDMaskPanGestureHandler.h"
#import "VEDMaskPinchGestureHandler.h"
#import "VEDMaskRectDrawView.h"
#import "VEDMaskRotateGesture.h"
#import "VEDMaskShapeType.h"
#import "VEDMaskTransform.h"

FOUNDATION_EXPORT double DVETrackKitVersionNumber;
FOUNDATION_EXPORT const unsigned char DVETrackKitVersionString[];