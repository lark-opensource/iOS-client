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

#import "AWEAutoresizingCollectionView.h"
#import "AWECollectionStickerPickerController.h"
#import "AWECollectionStickerPickerModel.h"
#import "AWEDouyinStickerCategoryModel.h"
#import "AWEExploreStickerViewController.h"
#import "AWEPhotoPickerCollectionViewCell.h"
#import "AWEPhotoPickerController.h"
#import "AWEPhotoPickerModel.h"
#import "AWEStickerCategoryModel.h"
#import "AWEStickerDownloadManager.h"
#import "AWEStickerPicckerDataSource.h"
#import "AWEStickerPickerCategoryBaseCell.h"
#import "AWEStickerPickerCategoryCell.h"
#import "AWEStickerPickerCategoryTabView.h"
#import "AWEStickerPickerCollectionViewCell.h"
#import "AWEStickerPickerController+LayoutManager.h"
#import "AWEStickerPickerController.h"
#import "AWEStickerPickerControllerPluginProtocol.h"
#import "AWEStickerPickerDataContainer.h"
#import "AWEStickerPickerDataContainerProtocol.h"
#import "AWEStickerPickerDefaultLogger.h"
#import "AWEStickerPickerDefaultUIConfiguration.h"
#import "AWEStickerPickerEmptyView.h"
#import "AWEStickerPickerErrorView.h"
#import "AWEStickerPickerExploreView.h"
#import "AWEStickerPickerFavoriteView.h"
#import "AWEStickerPickerHashtagCollectionViewCell.h"
#import "AWEStickerPickerHashtagView.h"
#import "AWEStickerPickerLoadingView.h"
#import "AWEStickerPickerLogMarcos.h"
#import "AWEStickerPickerLogger.h"
#import "AWEStickerPickerModel+Favorite.h"
#import "AWEStickerPickerModel+Search.h"
#import "AWEStickerPickerModel.h"
#import "AWEStickerPickerOverlayView.h"
#import "AWEStickerPickerSearchBar.h"
#import "AWEStickerPickerSearchBarConfig.h"
#import "AWEStickerPickerSearchCollectionViewCell.h"
#import "AWEStickerPickerSearchView.h"
#import "AWEStickerPickerStickerBaseCell.h"
#import "AWEStickerPickerStickerCell.h"
#import "AWEStickerPickerTabViewLayout.h"
#import "AWEStickerPickerUIConfigurationProtocol.h"
#import "AWEStickerPickerView.h"
#import "AWEStickerViewLayoutManagerProtocol.h"
#import "ACCAICoverNetServiceProtocol.h"
#import "ACCActivityConfigProtocol.h"
#import "ACCAdTaskContext.h"
#import "ACCAdTrackContext.h"
#import "ACCAlbumInputData.h"
#import "ACCAlgorithmProtocolD.h"
#import "ACCAlgorithmWrapper.h"
#import "ACCAssetImageGeneratorTracker.h"
#import "ACCAudioAuthUtils.h"
#import "ACCAudioExport.h"
#import "ACCAudioNetServiceProtocol.h"
#import "ACCAudioPlayerProtocol.h"
#import "ACCAwemeModelProtocolD.h"
#import "ACCBarItem+Adapter.h"
#import "ACCBarItemToastView.h"
#import "ACCBatchPublishServiceProtocol.h"
#import "ACCBeautyBuildInDataSourceImpl.h"
#import "ACCBeautyComponentBarItemPlugin.h"
#import "ACCBeautyComponentFlowPlugin.h"
#import "ACCBeautyDataServiceImpl.h"
#import "ACCBeautyFeatureComponentTrackerPlugin.h"
#import "ACCBeautyServiceImpl.h"
#import "ACCBeautyWrapper.h"
#import "ACCBirthdayTemplateModel.h"
#import "ACCBlockSequencer.h"
#import "ACCCameraClient.h"
#import "ACCCameraControlProtocolD.h"
#import "ACCCameraControlWrapper.h"
#import "ACCCameraFactory.h"
#import "ACCCameraFactoryImpls.h"
#import "ACCCameraServiceNewImpls.h"
#import "ACCCameraSwapComponent.h"
#import "ACCCameraSwapService.h"
#import "ACCCameraTypeDefine.h"
#import "ACCCanvasUtils.h"
#import "ACCCaptureComponent.h"
#import "ACCCaptureScreenAnimationView.h"
#import "ACCCaptureService.h"
#import "ACCCaptureViewModel.h"
#import "ACCChallengeNetServiceProtocol.h"
#import "ACCClipVideoProtocol.h"
#import "ACCCommerceServiceProtocol.h"
#import "ACCCommonMultiRowsCollectionLayout.h"
#import "ACCConfigKeyDefines.h"
#import "ACCCreativeBrightnessABUtil.h"
#import "ACCCreativePage.h"
#import "ACCCreativePathConstants.h"
#import "ACCCreativePathManager.h"
#import "ACCCreativePathMessage.h"
#import "ACCCutMusicBarChartView.h"
#import "ACCCutMusicPanelView.h"
#import "ACCCutMusicRangeChangeContext.h"
#import "ACCCutSameGamePlayConfigFetcherProtocol.h"
#import "ACCCutSameLVConstDefinitionProtocol.h"
#import "ACCCutSameMaterialImportManagerProtocol.h"
#import "ACCCutSameProtocol.h"
#import "ACCCutSameToEditManagerProtocol.h"
#import "ACCCutSameVideoCompressConfigProtocol.h"
#import "ACCCutSameVideoCompressorProtocol.h"
#import "ACCCutSameWorksAssetModel.h"
#import "ACCCutSameWorksManagerProtocol.h"
#import "ACCDUXProtocl.h"
#import "ACCDraftModelProtocol.h"
#import "ACCDraftProtocol.h"
#import "ACCDraftResourceRecoverProtocol.h"
#import "ACCDraftSaveLandingProtocol.h"
#import "ACCDummyHitTestView.h"
#import "ACCEditActivityDataHelperProtocol.h"
#import "ACCEditAudioEffectProtocolD.h"
#import "ACCEditAudioEffectWraper.h"
#import "ACCEditBarClipFeatureSortSource.h"
#import "ACCEditBarIMSortSource.h"
#import "ACCEditBarItemExtraData.h"
#import "ACCEditBarItemLottieExtraData.h"
#import "ACCEditBarSortSource.h"
#import "ACCEditBeautyWrapper.h"
#import "ACCEditBingoManager.h"
#import "ACCEditBottomToolBarContainer.h"
#import "ACCEditCanvasConfigProtocol.h"
#import "ACCEditCanvasHelper.h"
#import "ACCEditCanvasLivePhotoUtils.h"
#import "ACCEditCanvasWrapper.h"
#import "ACCEditCaptureFrameWrapper.h"
#import "ACCEditCompileSession.h"
#import "ACCEditContainerView.h"
#import "ACCEditEffectProtocolD.h"
#import "ACCEditEffectWraper.h"
#import "ACCEditFilterWraper.h"
#import "ACCEditHDRProtocolD.h"
#import "ACCEditHDRWraper.h"
#import "ACCEditImageAlbumMixedProtocolD.h"
#import "ACCEditMVModel.h"
#import "ACCEditMusicBizModule.h"
#import "ACCEditPageTextStorage.h"
#import "ACCEditPageTextView.h"
#import "ACCEditPlayerComponent.h"
#import "ACCEditPlayerMonitorProtocol.h"
#import "ACCEditPlayerMonitorService.h"
#import "ACCEditPlayerViewModel.h"
#import "ACCEditPreviewProtocolD.h"
#import "ACCEditPreviewWraper.h"
#import "ACCEditService.h"
#import "ACCEditServiceImpls.h"
#import "ACCEditSessionBuilder.h"
#import "ACCEditSessionBuilderImpls.h"
#import "ACCEditSessionConfigBuilder.h"
#import "ACCEditSmartMovieProtocol.h"
#import "ACCEditStickerWraper.h"
#import "ACCEditTRToolBarContainer.h"
#import "ACCEditTagsDefine.h"
#import "ACCEditToPublishRouterCoordinatorProtocol.h"
#import "ACCEditToolBarContainer.h"
#import "ACCEditTransitionService.h"
#import "ACCEditTransitionServiceProtocol.h"
#import "ACCEditVideoData.h"
#import "ACCEditVideoDataConsumer.h"
#import "ACCEditVideoDataDowngrading.h"
#import "ACCEditVideoDataFactory.h"
#import "ACCEditVideoDataProtocol.h"
#import "ACCEditViewControllerInputData.h"
#import "ACCEditViewModel.h"
#import "ACCEditorConfig.h"
#import "ACCEditorDraftService.h"
#import "ACCEditorDraftServiceImpl.h"
#import "ACCEditorMusicConfigAssembler.h"
#import "ACCEditorStickerConfigAssembler.h"
#import "ACCEditorTrackerTool.h"
#import "ACCEffectDownloadParam.h"
#import "ACCEffectMessageDownloadOperation.h"
#import "ACCEffectMessageDownloader.h"
#import "ACCEffectWrapper.h"
#import "ACCExposureSlider.h"
#import "ACCFeedbackProtocol.h"
#import "ACCFileUploadResponseInfoModel.h"
#import "ACCFileUploadServiceProtocol.h"
#import "ACCFilterComponentBeautyPlugin.h"
#import "ACCFilterComponentDPlugin.h"
#import "ACCFilterComponentFlowPlugin.h"
#import "ACCFilterComponentGesturePlugin.h"
#import "ACCFilterComponentTipsPlugin.h"
#import "ACCFilterComponentTrackerPlugin.h"
#import "ACCFilterDataServiceImpl.h"
#import "ACCFilterServiceImpl.h"
#import "ACCFilterWrapper.h"
#import "ACCFlashComponent.h"
#import "ACCFlowerAuditDataService.h"
#import "ACCFlowerCampaignDefine.h"
#import "ACCFlowerCampaignManagerProtocol.h"
#import "ACCFlowerRedPacketHelperProtocol.h"
#import "ACCFlowerRedpacketPropTipView.h"
#import "ACCFlowerRewardModel.h"
#import "ACCFlowerService.h"
#import "ACCFocusComponent.h"
#import "ACCFocusViewModel.h"
#import "ACCFriendsServiceProtocol.h"
#import "ACCGrootStickerModel.h"
#import "ACCHashTagAppendService.h"
#import "ACCHashTagServiceProtocol.h"
#import "ACCIMModuleServiceProtocol.h"
#import "ACCIMServiceProtocol.h"
#import "ACCImageAlbumData.h"
#import "ACCImageAlbumEditAssetsExportOutputDataProtocol.h"
#import "ACCImageAlbumEditImageInputInfo.h"
#import "ACCImageAlbumEditInputData.h"
#import "ACCImageAlbumEditorDefine.h"
#import "ACCImageAlbumExportItemModel.h"
#import "ACCImageAlbumItemBaseResourceModel.h"
#import "ACCImageAlbumItemModel.h"
#import "ACCImageAlbumStickerModel.h"
#import "ACCImageEditItemCoverInfo.h"
#import "ACCInfoStickerNetServiceProtocol.h"
#import "ACCIronManServiceProtocol.h"
#import "ACCKaraokeDataHelperProtocol.h"
#import "ACCKaraokeDefines.h"
#import "ACCKaraokeService.h"
#import "ACCKaraokeTimeSlice.h"
#import "ACCKaraokeWrapper.h"
#import "ACCLVAudioRecoverUtil.h"
#import "ACCLanguageDefine.h"
#import "ACCLayoutContainerProtocolD.h"
#import "ACCLightningCaptureButtonAnimationProtocol.h"
#import "ACCLightningRecordAlienationView.h"
#import "ACCLightningRecordAnimatable.h"
#import "ACCLightningRecordAnimationView.h"
#import "ACCLightningRecordBlurView.h"
#import "ACCLightningRecordButton.h"
#import "ACCLightningRecordLongtailView.h"
#import "ACCLightningRecordRedView.h"
#import "ACCLightningRecordRingView.h"
#import "ACCLightningRecordWhiteView.h"
#import "ACCLightningStyleRecordFlowComponent.h"
#import "ACCLivePhotoFramesRecorder.h"
#import "ACCLiveServiceProtocol.h"
#import "ACCMVAudioBeatTrackManager.h"
#import "ACCMVCategoryModel.h"
#import "ACCMVTemplateMergedInfo.h"
#import "ACCMVTemplatesFetchProtocol.h"
#import "ACCMainServiceProtocol.h"
#import "ACCMeasureOnceItem.h"
#import "ACCMediaContainerView.h"
#import "ACCMediaSourceManager.h"
#import "ACCMessageFilterable.h"
#import "ACCMessageWrapper.h"
#import "ACCMeteorModeUtils.h"
#import "ACCMigrateContextModel.h"
#import "ACCModernPOIStickerDataHelperProtocol.h"
#import "ACCMonitorToolDefines.h"
#import "ACCMonitorToolMsgProtocol.h"
#import "ACCMusicMVTemplateModelProtocol.h"
#import "ACCMusicModelProtocolD.h"
#import "ACCMusicNetServiceProtocol.h"
#import "ACCMusicRecommendPropBubbleView.h"
#import "ACCMusicRecommendPropModel.h"
#import "ACCMusicTransModelProtocol.h"
#import "ACCNLEBundleResource.h"
#import "ACCNLEEditAudioEffectWrapper.h"
#import "ACCNLEEditBeautyWrapper.h"
#import "ACCNLEEditCanvasWrapper.h"
#import "ACCNLEEditCaptureFrameWrapper.h"
#import "ACCNLEEditFilterWrapper.h"
#import "ACCNLEEditHDRWrapper.h"
#import "ACCNLEEditMultiTrackWrapper.h"
#import "ACCNLEEditPreviewWrapper.h"
#import "ACCNLEEditService.h"
#import "ACCNLEEditSmartMovieWrapper.h"
#import "ACCNLEEditSpecialEffectWrapper.h"
#import "ACCNLEEditStickerWrapper.h"
#import "ACCNLEEditVideoData.h"
#import "ACCNLEEditorBuilder.h"
#import "ACCNLEHeaders.h"
#import "ACCNLELogger.h"
#import "ACCNLEPublishEditService.h"
#import "ACCNLEPublishEditorBuilder.h"
#import "ACCNLEUtils.h"
#import "ACCNetworkUtils.h"
#import "ACCNewYearWishEditModel.h"
#import "ACCPOIServiceProtocol.h"
#import "ACCPOIStickerModel.h"
#import "ACCPhotoAlbumDefine.h"
#import "ACCPhotoConfigProtocol.h"
#import "ACCPhotoWaterMarkUtil.h"
#import "ACCPrivacyPermissionDecouplingManagerProtocol.h"
#import "ACCPropComponentLogConfigProtocol.h"
#import "ACCPropComponentV2.h"
#import "ACCPropConfigProtocol.h"
#import "ACCPropExploreExperimentalControl.h"
#import "ACCPropExploreService.h"
#import "ACCPropExploreServiceImpl.h"
#import "ACCPropPickerComponent.h"
#import "ACCPropPickerViewModel.h"
#import "ACCPropRecommendMusicProtocol.h"
#import "ACCPropRecommendMusicReponseModel.h"
#import "ACCPropRecommendMusicView.h"
#import "ACCPropSelection.h"
#import "ACCPropViewModel.h"
#import "ACCPublishNetServiceProtocol.h"
#import "ACCPublishPrivacySecurityManagerProtocol.h"
#import "ACCPublishRepositoryNLESyncProtocol.h"
#import "ACCPublishServiceFactoryProtocol.h"
#import "ACCPublishServiceMessage.h"
#import "ACCPublishServiceProtocol.h"
#import "ACCPublishServiceSaveAlbumHandle.h"
#import "ACCPublishStrongPopView.h"
#import "ACCPublishViewControllerInputData.h"
#import "ACCQRCodeResultHandlerProtocol.h"
#import "ACCQuickStoryIMServiceProtocol.h"
#import "ACCQuickStoryRecordComponent.h"
#import "ACCQuickStoryRecorderTipsComponent.h"
#import "ACCQuickStoryRecorderTipsViewModel.h"
#import "ACCRNEventProtocol.h"
#import "ACCRecognitionConfig.h"
#import "ACCRecognitionEnumerate.h"
#import "ACCRecognitionGrootConfig.h"
#import "ACCRecognitionTrackModel.h"
#import "ACCRecordARService.h"
#import "ACCRecordAuthComponent.h"
#import "ACCRecordAuthService.h"
#import "ACCRecordAuthServiceImpl.h"
#import "ACCRecordCompleteComponent.h"
#import "ACCRecordCompletePauseStateHandler.h"
#import "ACCRecordCompleteTrackSender.h"
#import "ACCRecordCompleteTrackSenderProtocol.h"
#import "ACCRecordConfigService.h"
#import "ACCRecordConfigServiceImpl.h"
#import "ACCRecordContainerMode.h"
#import "ACCRecordDeleteComponent.h"
#import "ACCRecordDeleteTrackSender.h"
#import "ACCRecordDeleteTrackSenderProtocol.h"
#import "ACCRecordDraftHelper.h"
#import "ACCRecordFlowComponent.h"
#import "ACCRecordFlowConfigProtocol.h"
#import "ACCRecordFlowService.h"
#import "ACCRecordFlowServiceImpl.h"
#import "ACCRecordFrameSamplingBaseHandler.h"
#import "ACCRecordFrameSamplingDuetHandler.h"
#import "ACCRecordFrameSamplingHandlerChain.h"
#import "ACCRecordFrameSamplingMusicAItHandler.h"
#import "ACCRecordFrameSamplingServiceImpl.h"
#import "ACCRecordFrameSamplingServiceProtocol.h"
#import "ACCRecordFrameSamplingStickerHandler.h"
#import "ACCRecordGestureComponent.h"
#import "ACCRecordGestureService.h"
#import "ACCRecordGestureServiceImpl.h"
#import "ACCRecordGradientView.h"
#import "ACCRecordLayoutGuide.h"
#import "ACCRecordLayoutManager.h"
#import "ACCRecordMemoryControl.h"
#import "ACCRecordMode+LiteTheme.h"
#import "ACCRecordMode+MeteorMode.h"
#import "ACCRecordModeBackgroundModelProtocol.h"
#import "ACCRecordModeFactory.h"
#import "ACCRecordProgressComponent.h"
#import "ACCRecordPropCheckerComponent.h"
#import "ACCRecordPropService.h"
#import "ACCRecordPropServiceImpl.h"
#import "ACCRecordSelectPropComponent.h"
#import "ACCRecordSelectPropViewModel.h"
#import "ACCRecordSplitTipComponent.h"
#import "ACCRecordSubmodeComponent.h"
#import "ACCRecordSubmodeViewModel.h"
#import "ACCRecordSwitchModeComponent.h"
#import "ACCRecordSwitchModeServiceImpl.h"
#import "ACCRecordSwitchModeViewModel.h"
#import "ACCRecordTapGestureRecognizer.h"
#import "ACCRecordToEditRouterCoordinatorProtocol.h"
#import "ACCRecordTrackHelper.h"
#import "ACCRecordTrackServiceImpl.h"
#import "ACCRecordViewController.h"
#import "ACCRecordViewControllerInputData.h"
#import "ACCRecordViewControllerNotificationDefine.h"
#import "ACCRecorderBackgroundManagerProtocol.h"
#import "ACCRecorderEvent.h"
#import "ACCRecorderLivePhotoProtocol.h"
#import "ACCRecorderMeteorModeServiceProtocol.h"
#import "ACCRecorderProtocolD.h"
#import "ACCRecorderRedPacketProtocol.h"
#import "ACCRecorderToolBarDefinesD.h"
#import "ACCRecorderViewContainerImpl.h"
#import "ACCRecorderWrapper.h"
#import "ACCReorderableForCollectionViewFlowLayout.h"
#import "ACCRepoActivityModel.h"
#import "ACCRepoAudioModeModel.h"
#import "ACCRepoBirthdayModel.h"
#import "ACCRepoCanvasBusinessModel.h"
#import "ACCRepoCanvasModel.h"
#import "ACCRepoChallengeBindModel.h"
#import "ACCRepoChallengeModel+Track.h"
#import "ACCRepoDraftFeedModelProtocol.h"
#import "ACCRepoEditEffectModel+NLESync.h"
#import "ACCRepoEditEffectModel.h"
#import "ACCRepoImageAlbumInfoModel+ACCStickerLogic.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "ACCRepoKaraokeModelProtocol.h"
#import "ACCRepoLastGroupTrackModelProtocol.h"
#import "ACCRepoLivePhotoModel.h"
#import "ACCRepoMissionModelProtocol.h"
#import "ACCRepoNearbyModelProtocol.h"
#import "ACCRepoPOIModelProtocol.h"
#import "ACCRepoPointerTransferModel.h"
#import "ACCRepoQuickStoryModel.h"
#import "ACCRepoRearResourceModel.h"
#import "ACCRepoRecorderTrackerToolModel.h"
#import "ACCRepoRedPacketModel.h"
#import "ACCRepoSearchClueModelProtocol.h"
#import "ACCRepoSecurityInfoModel.h"
#import "ACCRepoSmartMovieInfoModel.h"
#import "ACCRepoStickerModel+InteractionSticker.h"
#import "ACCRepoStickerModel+Publish.h"
#import "ACCRepoTextModeModel.h"
#import "ACCRepoUserIncentiveModelProtocol.h"
#import "ACCRepositoryReeditContextProtocol.h"
#import "ACCRouterProtocolD.h"
#import "ACCScanService.h"
#import "ACCScreenSimulatedTorchView.h"
#import "ACCSelectAlbumAssetsProtocol.h"
#import "ACCSelectMusicInputData.h"
#import "ACCSelectMusicProtocol.h"
#import "ACCSelectMusicStudioParamsProtocol.h"
#import "ACCSelfieEmojiViewControllerInputData.h"
#import "ACCShareServiceProtocol.h"
#import "ACCShootSameStickerModel.h"
#import "ACCSkeletonDetectTipsManager.h"
#import "ACCSkeletonDetectTipsView.h"
#import "ACCSmartMovieABConfig.h"
#import "ACCSmartMovieDefines.h"
#import "ACCSmartMovieManagerProtocol.h"
#import "ACCSmartMovieUtils.h"
#import "ACCSocialStickerBindingController.h"
#import "ACCSocialStickerCommDefines.h"
#import "ACCSocialStickerModel.h"
#import "ACCSpeedControlComponent.h"
#import "ACCSpeedControlViewModel.h"
#import "ACCSpeedProbeProtocol.h"
#import "ACCStickerApplyPredicate.h"
#import "ACCStickerBlockApplyPredicate.h"
#import "ACCStickerControllerPluginFactoryTemplate.h"
#import "ACCStickerGroupedApplyPredicate.h"
#import "ACCStickerMigrantsProtocol.h"
#import "ACCStickerMigrateUtil.h"
#import "ACCStickersPanelSettingProtocol.h"
#import "ACCStoryTextAnchorModels.h"
#import "ACCStudioGlobalConfig.h"
#import "ACCStudioLiteRedPacket.h"
#import "ACCStudioRepoNearbyModelProtocol.h"
#import "ACCSwitchLengthCell.h"
#import "ACCSwitchLengthView.h"
#import "ACCTapicEngineProtocol.h"
#import "ACCTextStickerSettingsConfig.h"
#import "ACCToolBarAdapterUtils.h"
#import "ACCToolBarCommonProtocol.h"
#import "ACCToolBarCommonViewLayout.h"
#import "ACCToolBarContainer.h"
#import "ACCToolBarContainerAdapter.h"
#import "ACCToolBarContainerPageEnum.h"
#import "ACCToolBarFoldView.h"
#import "ACCToolBarItemView.h"
#import "ACCToolBarItemsModel.h"
#import "ACCToolBarPageView.h"
#import "ACCToolBarScrollStackView.h"
#import "ACCToolBarSortDataSource.h"
#import "ACCToolBarView.h"
#import "ACCTrackerUtility.h"
#import "ACCUIReactTrackImpl.h"
#import "ACCUIReactTrackProtocol.h"
#import "ACCUserModelProtocolD.h"
#import "ACCUserProfileProtocol.h"
#import "ACCUserServiceProtocolD.h"
#import "ACCVEVideoData.h"
#import "ACCVideoDataTranslator.h"
#import "ACCVideoEdgeDataHelper.h"
#import "ACCVideoEditToolBarDefinition.h"
#import "ACCVideoEditVolumeChangeContext.h"
#import "ACCVideoExportUtils.h"
#import "ACCVideoMusicCategoryModel.h"
#import "ACCVideoMusicListResponse.h"
#import "ACCVideoMusicProtocol.h"
#import "ACCVideoPublishProtocol.h"
#import "ACCWaveformView.h"
#import "ACCWorksPreviewViewControllerProtocol.h"
#import "AWE2DStickerTextGenerator.h"
#import "AWE2DTextInputViewController.h"
#import "AWEAIMusicRecommendManager.h"
#import "AWEAIMusicRecommendTask.h"
#import "AWEAggregatedEffectView.h"
#import "AWEAlbumFaceCache.h"
#import "AWEAlbumImageModel.h"
#import "AWEAlbumPhotoCollector.h"
#import "AWEAssetModel.h"
#import "AWEAudioClipFeatureManager.h"
#import "AWEAudioClipView.h"
#import "AWEAudioModeDataHelper.h"
#import "AWECameraContainerDefine.h"
#import "AWECameraContainerFeatureButtonScrollView.h"
#import "AWECameraContainerIconManager.h"
#import "AWECameraManager.h"
#import "AWECameraPreviewContainerView.h"
#import "AWECaptureButtonAnimationView.h"
#import "AWECenteredScrollFlowLayout.h"
#import "AWECutSameMaterialAssetModel.h"
#import "AWEDouPlusEffectHintView.h"
#import "AWEEditActionContainerView.h"
#import "AWEEditActionContainerViewLayout.h"
#import "AWEEditAlgorithmManager.h"
#import "AWEEditAndPublishViewData+Business.h"
#import "AWEEditAndPublishViewDataSource.h"
#import "AWEEditPageProtocol.h"
#import "AWEEditRightTopActionContainerViewProtocol.h"
#import "AWEEditRightTopVerticalActionContainerView.h"
#import "AWEEffectHintViewProtocol.h"
#import "AWEEffectPlatformDataManager.h"
#import "AWEEffectPlatformManager+Download.h"
#import "AWEEffectPlatformManager.h"
#import "AWEEffectPlatformManagerDelegateImpl.h"
#import "AWEFlashModeSwitchButton.h"
#import "AWEHashTagAutoAppendService.h"
#import "AWEIMGuideSelectionImageView.h"
#import "AWEImageAndTitleBubble.h"
#import "AWEInteractionEditTagStickerModel.h"
#import "AWEInteractionGrootStickerModel.h"
#import "AWEInteractionHashtagStickerModel.h"
#import "AWEInteractionLiveStickerModel.h"
#import "AWEInteractionMentionStickerModel.h"
#import "AWEInteractionPOIStickerModel.h"
#import "AWEInteractionSocialTextStickerModel.h"
#import "AWEInteractionStickerModel+DAddition.h"
#import "AWEInteractionStickerModel+Subclass.h"
#import "AWEInteractionVideoReplyCommentStickerModel.h"
#import "AWEInteractionVideoReplyStickerModel.h"
#import "AWEInteractionVideoShareStickerModel.h"
#import "AWELiveDuetPostureCollectionViewCell.h"
#import "AWELiveDuetPostureViewController.h"
#import "AWEMVTemplateModel.h"
#import "AWEMVUtil.h"
#import "AWEMattingCollectionViewCell.h"
#import "AWEMattingView.h"
#import "AWEModernStickerCollectionViewCell.h"
#import "AWEModernStickerCollectionViewCoordinator.h"
#import "AWEModernStickerContentCollectionView.h"
#import "AWEModernStickerContentCollectionViewCell.h"
#import "AWEModernStickerSwitchTabView.h"
#import "AWEModernStickerTitleCellViewModel.h"
#import "AWEModernStickerTitleCollectionView.h"
#import "AWEModernStickerTitleCollectionViewCell.h"
#import "AWEModernStickerViewController.h"
#import "AWEModulConfigProtocol.h"
#import "AWEMusicStickerRecommendManager.h"
#import "AWEOriginStickerUserView.h"
#import "AWEPhotoMovieManager.h"
#import "AWEPrivacyPermissionTypeDefines.h"
#import "AWEPropSecurityTipsHelper.h"
#import "AWEPublishFirstFrameTracker.h"
#import "AWERecoderToolBarContainer.h"
#import "AWERecognitionLeadTipView.h"
#import "AWERecognitionLoadingView.h"
#import "AWERecognitionModeSwitchButton.h"
#import "AWERecordDefaultCameraPositionUtils.h"
#import "AWERecordFirstFrameTrackerNew.h"
#import "AWERecordInformationRepoModel+ACCRepositoryRequestParamsProtocol.h"
#import "AWERecordInformationRepoModel.h"
#import "AWERecordLoadingView.h"
#import "AWERecorderTipsAndBubbleManager.h"
#import "AWERedPackThemeService.h"
#import "AWERepoAuthorityContext.h"
#import "AWERepoAuthorityModel.h"
#import "AWERepoCaptionModel.h"
#import "AWERepoChallengeModel.h"
#import "AWERepoCommercialAnchorModelCameraClient.h"
#import "AWERepoCommercialBridgeModelProtocol.h"
#import "AWERepoContextModel.h"
#import "AWERepoCutSameModel.h"
#import "AWERepoDraftModel.h"
#import "AWERepoDuetModel.h"
#import "AWERepoFilterModel+NLESync.h"
#import "AWERepoFilterModel.h"
#import "AWERepoFlowControlModel.h"
#import "AWERepoFlowerTrackModel.h"
#import "AWERepoGameModel.h"
#import "AWERepoMVModel.h"
#import "AWERepoMusicModel+NLESync.h"
#import "AWERepoMusicModel.h"
#import "AWERepoMusicSearchModel.h"
#import "AWERepoPropModel.h"
#import "AWERepoPublishConfigModel.h"
#import "AWERepoReshootModel+NLESync.h"
#import "AWERepoReshootModel.h"
#import "AWERepoShareModel.h"
#import "AWERepoStickerModel.h"
#import "AWERepoTrackModel.h"
#import "AWERepoTranscodingModel.h"
#import "AWERepoUploadInfomationModel.h"
#import "AWERepoVideoInfoModel+NLESync.h"
#import "AWERepoVideoInfoModel+VideoData.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoVoiceChangerModel+NLESync.h"
#import "AWERepoVoiceChangerModel.h"
#import "AWEReshootVideoProgressView.h"
#import "AWEScrollBarChartView.h"
#import "AWEScrollStringButton.h"
#import "AWEShareMusicToStoryUtils.h"
#import "AWESpecialEffectSimplifiedABManager.h"
#import "AWEStickerApplyHandlerContainer.h"
#import "AWEStickerCommerceEnterView.h"
#import "AWEStickerDataManager+AWEConvenience.h"
#import "AWEStickerDataManager.h"
#import "AWEStickerFeatureManager.h"
#import "AWEStickerHintView.h"
#import "AWEStickerMusicManager+Local.h"
#import "AWEStickerPickerControllerCollectionStickerPlugin.h"
#import "AWEStickerPickerControllerDuetPropBubblePlugin.h"
#import "AWEStickerPickerControllerExploreStickerPlugin.h"
#import "AWEStickerPickerControllerFavoritePlugin.h"
#import "AWEStickerPickerControllerMusicPropBubblePlugin.h"
#import "AWEStickerPickerControllerSchemaStickerPlugin.h"
#import "AWEStickerPickerControllerSecurityTipsPlugin.h"
#import "AWEStickerPickerControllerShowcaseEntrancePlugin.h"
#import "AWEStickerPickerControllerSwitchCameraPlugin.h"
#import "AWEStickerPickerDelegate.h"
#import "AWEStickerSwitchImageView.h"
#import "AWEStoryTextImageModel+WidthLimit.h"
#import "AWEStudioAuthorityView.h"
#import "AWEStudioBaseCollectionViewCell.h"
#import "AWEStudioBaseViewController.h"
#import "AWEStudioDefines.h"
#import "AWEStudioFeedbackRecorderConsts.h"
#import "AWEStudioVideoProgressView.h"
#import "AWESwitchModeSingleTabConfigD.h"
#import "AWESwitchRecordModeCollectionView.h"
#import "AWESwitchRecordModeCollectionViewCell.h"
#import "AWESwitchRecordModeView.h"
#import "AWEVideoBGStickerManager.h"
#import "AWEVideoEditDefine.h"
#import "AWEVideoEffectPathBlockManager.h"
#import "AWEVideoFragmentInfo.h"
#import "AWEVideoFragmentInfo_private.h"
#import "AWEVideoPublishResponseModel.h"
#import "AWEVideoPublishViewModel+ACCPreviewEdge.h"
#import "AWEVideoPublishViewModel+ACCTask.h"
#import "AWEVideoPublishViewModel+FilterEdit.h"
#import "AWEVideoPublishViewModel+InteractionSticker.h"
#import "AWEVideoPublishViewModel+SourceInfo.h"
#import "AWEVideoRecordOutputParameter.h"
#import "AWEVideoRecorderARGestureDelegateModel.h"
#import "AWEVideoRecorderMessage.h"
#import "AWEVideoSpecialEffectsDefines.h"
#import "AWEWaterMarkDownloader.h"
#import "AWEXScreenAdaptManager.h"
#import "CAKAlbumAssetModel+Convertor.h"
#import "CAKAlbumModel+Convertor.h"
#import "HTSVideoData+AWEAIVideoClipInfo.h"
#import "HTSVideoData+AWEAddtions.h"
#import "HTSVideoData+AWEMute.h"
#import "HTSVideoData+AWEPersistent.h"
#import "HTSVideoData+AudioTrack.h"
#import "HTSVideoData+Capability.h"
#import "HTSVideoProgressView.h"
#import "HTSVideoSpeedControl.h"
#import "IESEffectModel+ACCGuideVideo.h"
#import "IESEffectModel+ACCRedpacket.h"
#import "IESEffectModel+DStickerAddditions.h"
#import "IESInfoSticker+ACCAdditions.h"
#import "NLEEditor_OC+Extension.h"
#import "NLEFilter_OC+Extension.h"
#import "NLEModel_OC+Extension.h"
#import "NLEResourceAV_OC+Extension.h"
#import "NLETrackMV_OC+Extension.h"
#import "NLETrackSlot_OC+Extension.h"
#import "NLETrack_OC+Extension.h"
#import "UIImage+GaussianBlur.h"
#import "UIViewController+AWECreativePath.h"
#import "VEEditorSession+ACCAudioEffect.h"
#import "VEEditorSession+ACCFilter.h"
#import "VEEditorSession+ACCSticker.h"
#import "ACCJSRuntimeContext.h"
#import "ACCLynxDefaultPackage.h"
#import "ACCLynxDefaultPackageLoadModel.h"
#import "ACCLynxDefaultPackageTemplate.h"
#import "ACCLynxView.h"
#import "ACCLynxWindowContext.h"
#import "ACCLynxWindowService.h"
#import "ACCXBridgeTemplateProtocol.h"
#import "ACCAPPSettingsProtocol.h"
#import "ACCActionSheetProtocol.h"
#import "ACCAlertControllerProtocol.h"
#import "ACCAsyncBlockOperation.h"
#import "ACCAsyncOperation.h"
#import "ACCAttributeBuilder+Attribute.h"
#import "ACCAttributeBuilder.h"
#import "ACCBubbleAnimation+Private.h"
#import "ACCBubbleAnimation.h"
#import "ACCBubbleAnimationManager.h"
#import "ACCBubbleAnimationTimingFunction.h"
#import "ACCBubbleDefinition.h"
#import "ACCBubbleProtocol.h"
#import "ACCButton.h"
#import "ACCCollectionButton.h"
#import "ACCCommonSearchBarProtocol.h"
#import "ACCCornerBarNaviController.h"
#import "ACCCreativePerformanceTool.h"
#import "ACCDeallocHelper.h"
#import "ACCEncryptProtocol.h"
#import "ACCEventAttribute.h"
#import "ACCEventContext+Convenience.h"
#import "ACCEventContext.h"
#import "ACCFileDownloadTask.h"
#import "ACCFileDownloader.h"
#import "ACCGradientProtocol.h"
#import "ACCGradientView.h"
#import "ACCHTTPJSONRequestSerializer.h"
#import "ACCImageAlbumAssetsExportManagerProtocol.h"
#import "ACCImageAlbumEditTransferProtocol.h"
#import "ACCImageAlbumLandingModeManagerProtocol.h"
#import "ACCImageThemeProtocol.h"
#import "ACCImageViewProtocol.h"
#import "ACCInteractionView.h"
#import "ACCKdebugSignPost.h"
#import "ACCLocationProtocol.h"
#import "ACCMBCircularProgressBarLayer.h"
#import "ACCMBCircularProgressBarView.h"
#import "ACCMaskWindowProtocol.h"
#import "ACCMultiStyleAlertProtocol.h"
#import "ACCMusicFontProtocol.h"
#import "ACCNetworkDefine.h"
#import "ACCNewActionSheetProtocol.h"
#import "ACCPassThroughView.h"
#import "ACCPlaybackView.h"
#import "ACCRefreshHeader.h"
#import "ACCScrollStringButtonProtocol.h"
#import "ACCSelectedAssetsBottomViewProtocol.h"
#import "ACCSelectedAssetsViewProtocol.h"
#import "ACCSettingsProtocol.h"
#import "ACCStatusBarControllerFinder.h"
#import "ACCSubtitleActionSheetProtocol.h"
#import "ACCTextInputAlertProcotol.h"
#import "ACCTextViewProtocol.h"
#import "ACCThrottle.h"
#import "ACCTimingManager.h"
#import "ACCTransitioningDelegateProtocol.h"
#import "ACCTypeCovertDefine.h"
#import "ACCVideoHelper.h"
#import "ACCVideoInspectorProtocol.h"
#import "ACCVideoPreloadProtocol.h"
#import "ACCVideoPublishAsImageAlbumProtocol.h"
#import "ACCViewControllerProtocol.h"
#import "ACCWaterfallCollectionViewLayout.h"
#import "ACCWebViewProtocol.h"
#import "AWEBigToSmallDismissAnimation.h"
#import "AWEBigToSmallModalDelegate.h"
#import "AWEBigToSmallPresentAnimation.h"
#import "CADisplayLink+ACCBlock.h"
#import "NLENode_OC+ACCAdditions.h"
#import "NLESegmentSticker_OC+ACCAdditions.h"
#import "NLETrackSlot_OC+ACCAdditions.h"
#import "NSObject+ACCEventContext.h"
#import "UIDevice+ACCAdditions.h"
#import "UIImage+ACCUIKit.h"
#import "UINavigationBar+ACCChangeBottonBorderColor.h"
#import "UINavigationController+ACCExpendCompletion.h"
#import "UIScrollView+ACCInfiniteScrolling.h"
#import "UIView+ACCBubbleAnimation.h"
#import "UIView+ACCTextLoadingView.h"
#import "UIViewController+ACCStatusBar.h"
#import "UIViewController+ACCUIKitEmptyPage.h"
#import "UIViewController+AWEDismissPresentVCStack.h"
#import "ACCAlertDefaultImpl.h"
#import "ACCCustomWebImageManager.h"
#import "ACCWebImageDefaultImpl.h"
#import "ACCWebImageOptions.h"
#import "ACCWebImageTransformProtocol.h"
#import "ACCWebImageTransformer.h"
#import "NSArray+AnimatedType.h"
#import "UIAlertController+ACCAlertDefaultImpl.h"
#import "UIButton+ACCAdditions.h"
#import "UIImageView+ACCWebImage.h"
#import "ACCExifUtil.h"
#import "ACCPersonalRecommendWords.h"
#import "ACCSecurityFramesCheck.h"
#import "ACCSecurityFramesExporter.h"
#import "ACCSecurityFramesSaver.h"
#import "ACCSecurityFramesUtils.h"

FOUNDATION_EXPORT double CameraClientVersionNumber;
FOUNDATION_EXPORT const unsigned char CameraClientVersionString[];
