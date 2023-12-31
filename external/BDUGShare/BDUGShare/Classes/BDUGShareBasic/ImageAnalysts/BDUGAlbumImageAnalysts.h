//
//  BDUGAlbumImageAnalysts.h
//  BDUGShare_Example
//
//  Created by 杨阳 on 2019/6/19.
//  Copyright © 2019 xunianqiang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^BDUGShareAnalysisContinueBlock)(BOOL analysisSucceed);
typedef void(^BDUGShareAnalysisPriorityBlock)(BDUGShareAnalysisContinueBlock continueBlock);

typedef BOOL(^BDUGShareImageShouldAnalysisBlock)(void);

@protocol BDUGAlbumImageAnalystsDelegate <NSObject>

- (void)analysisShareInfo:(UIImage *)image hasReadMark:(BOOL *)hasReadMark completion:(BDUGShareAnalysisContinueBlock)completion;

@end

@interface BDUGAlbumImageAnalysts : NSObject

@property (nonatomic, weak) id <BDUGAlbumImageAnalystsDelegate> imageHiddenMarkDelegate;
@property (nonatomic, weak) id <BDUGAlbumImageAnalystsDelegate> imageQRCodeDelegate;
@property (nonatomic, assign) NSInteger maxReadImageCount;

@property (nonatomic, copy) BDUGShareImageShouldAnalysisBlock imageShouldAnalysisBlock;

+ (instancetype)sharedManager;

- (void)activateAlbumImageAnalystsWithPermissionAlert:(BOOL)permission notificationName:(NSString *)notificationName;

- (void)markAlbumImageIdentifier:(NSString *)imageIdentifier valid:(BOOL)valid;

+ (void)cleanCache;

@end

