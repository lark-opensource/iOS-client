//
//  AWERepoCommercialAnchorModelCameraClient.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/9/29.
//

#ifndef AWERepoCommercialAnchorModelProtocol_h
#define AWERepoCommercialAnchorModelProtocol_h

@class AWEVideoPublishViewModel;

@protocol AWERepoCommercialAnchorModelCameraClient <NSObject>

- (nullable NSDictionary *)acc_TCMResultOfOpenReocordJSB;

- (long long)acc_starAtlasOrderID;

- (NSDictionary *)acc_resultOfOpenReocordJSB;

- (BOOL)hasPassiveAnchor;

- (BOOL)acc_isCommerceLinkAd;

- (NSString *)acc_anchorID;

- (NSString *)acc_anchorContent;

- (NSString *)acc_anchorTitle;

- (NSArray *)acc_anchorIconList;

- (BOOL)acc_isDisableDraft;

- (void)clearAnchorInfo;

- (void)resetAllAnchorInfo;

- (void)clearGoodsSeedingInfo;

- (void)updateIsPassiveAnchor:(BOOL)isPassiveAnchor;

- (BOOL)isCloseAbilityPassiveAnchor;

- (BOOL)isItemAbilityPassiveAnchor;

- (void)enablePassiveAnchorCloseAndItemAbility;

- (void)updateIsCommerceLinkAd:(BOOL)isCommerceLinkAd;

- (void)updateCommerceAdLinkTags:(NSString *)commerceAdLinkTags isCommerceLinkAd:(BOOL)isCommerceLinkAd;

- (void)updateStarAtlasOrderID:(long long)starAtlasOrderID;

- (void)updateStarAtlasChannel:(long)starAtlasChannel;

- (void)updateResultOfOpenReocordJSB:(NSDictionary *)resultOfOpenReocordJSB;

- (NSDictionary *)goodsInfoDict;

- (void)updateAnchorID:(NSString *)anchorID;

- (void)updateAnchorContent:(NSString *)anchorContent;

- (void)updateAnchorTitle:(NSString *)anchorTitle;

- (void)updateAnchorIconList:(NSArray *)anchorIconList;

- (void)updateStarAtlasTCMContent:(NSDictionary *)dict;

- (void)clearStarAtlasTCMContent;

- (NSString *)acc_starAtlasTCMContentBrandName;

- (void)makeDisableDraft;

- (void)syncGoodsSeedingWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel;

- (void)syncAnchorInfoWithPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel;

@end

#endif /* AWERepoCommercialAnchorModelProtocol_h */
