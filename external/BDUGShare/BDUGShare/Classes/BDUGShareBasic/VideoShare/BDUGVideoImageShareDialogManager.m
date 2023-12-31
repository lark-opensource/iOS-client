//
//  BDUGVideoImageShareDialogManager.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/15.
//

#import "BDUGVideoImageShareDialogManager.h"
#import "BDUGVideoImageShareModel.h"
#import "BDUGShareEvent.h"

static NSString *const kBDUGShareDialogCurerntShowAmount = @"kBDUGShareDialogCurerntShowAmount";

@interface BDUGVideoImageShareDialogManager ()

@property (nonatomic, assign) NSInteger maxShowAmount;
@property (nonatomic, assign) NSInteger currentShowAmount;

@property (nonatomic, copy) BDUGVideoSharePreviewDialogBlock videoPreviewBlock;
@property (nonatomic, copy) BDUGVideoAlbumAuthorizationBlock albumAuthorizationBlock;
@property (nonatomic, copy) BDUGVideoSaveSucceedDialogBlock videoSaveSucceedBlock;

@property (nonatomic, copy) BDUGVideoDownloadProgressBlock downloadProgressBlock;
@property (nonatomic, copy) BDUGVideoShareBlock downloadCompletionBlock;

@end

@implementation BDUGVideoImageShareDialogManager

@synthesize currentShowAmount = _currentShowAmount;

#pragma mark - life cycle

+ (instancetype)sharedManager
{
    static BDUGVideoImageShareDialogManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self class] new];
    });
    return sharedManager;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - public method - register

+ (void)videoPreviewShareRegisterDialogBlock:(BDUGVideoSharePreviewDialogBlock)dialogBlock
{
    //默认最大三次。
    [self videoPreviewShareRegisterDialogBlock:dialogBlock maxShowAmount:3];
}

+ (void)videoPreviewShareRegisterDialogBlock:(BDUGVideoSharePreviewDialogBlock)dialogBlock
                               maxShowAmount:(NSInteger)showAmount
{
    [BDUGVideoImageShareDialogManager sharedManager].videoPreviewBlock = dialogBlock;
    [BDUGVideoImageShareDialogManager sharedManager].maxShowAmount = showAmount;
}

+ (void)albumAuthorizationRegisterDialogBlock:(BDUGVideoAlbumAuthorizationBlock)authorizationBlock
{
    [BDUGVideoImageShareDialogManager sharedManager].albumAuthorizationBlock = authorizationBlock;
}

+ (void)videoSaveSucceedRegisterDialogBlock:(BDUGVideoSaveSucceedDialogBlock)dialogBlock
{
    [BDUGVideoImageShareDialogManager sharedManager].videoSaveSucceedBlock = dialogBlock;
}

+ (void)videoDownloadRegisterProgress:(void(^)(CGFloat progress))progress
                           completion:(BDUGVideoShareBlock)completion
{
    [BDUGVideoImageShareDialogManager sharedManager].downloadProgressBlock = progress;
    [BDUGVideoImageShareDialogManager sharedManager].downloadCompletionBlock = completion;
}

#pragma mark - public method - invoke

+ (void)invokeVideoPreviewDialogBlock:(BDUGVideoImageShareInfo *)shareInfo
                        continueBlock:(BDUGVideoShareBlock)continueBlock {
    if (BDUG_VIDEO_DIALOG_MGR.currentShowAmount < BDUG_VIDEO_DIALOG_MGR.maxShowAmount &&
        [BDUGVideoImageShareDialogManager sharedManager].videoPreviewBlock) {
        [BDUGVideoImageShareDialogManager sharedManager].videoPreviewBlock(shareInfo, continueBlock);
        BDUG_VIDEO_DIALOG_MGR.currentShowAmount += 1;
    } else {
        //业务方没有实现或者弹窗次数超出max，直接continue
        !continueBlock ?: continueBlock();
    }
}

+ (void)invokeAlbumAuthorizationDialogBlock:(BDUGVideoImageShareInfo *)shareInfo
                              continueBlock:(BDUGVideoShareBlock)continueBlock
{
    if ([BDUGVideoImageShareDialogManager sharedManager].albumAuthorizationBlock) {
        [BDUGVideoImageShareDialogManager sharedManager].albumAuthorizationBlock(shareInfo, continueBlock);
    } else {
        //业务方没有实现，直接continue
        !continueBlock ?: continueBlock();
    }
}

+ (void)invokeVideoSaveSucceedDialogBlock:(BDUGVideoImageShareContentModel *)contentModel
                            continueBlock:(BDUGVideoShareBlock)continueBlock
{
    if ([BDUGVideoImageShareDialogManager sharedManager].videoSaveSucceedBlock) {
        [BDUGVideoImageShareDialogManager sharedManager].videoSaveSucceedBlock(contentModel, continueBlock);
    } else {
        //业务方没有实现，直接continue
        !continueBlock ?: continueBlock();
    }
}

+ (void)invokeDownloadProgress:(CGFloat)progress
{
    ![BDUGVideoImageShareDialogManager sharedManager].downloadProgressBlock ?: [BDUGVideoImageShareDialogManager sharedManager].downloadProgressBlock(progress);
}

+ (void)invokeDownloadCompletion
{
    ![BDUGVideoImageShareDialogManager sharedManager].downloadCompletionBlock ?: [BDUGVideoImageShareDialogManager sharedManager].downloadCompletionBlock();
}

#pragma mark - get & set

- (void)setCurrentShowAmount:(NSInteger)currentShowAmount {
    _currentShowAmount = currentShowAmount;
    [[NSUserDefaults standardUserDefaults] setObject:@(_currentShowAmount) forKey:kBDUGShareDialogCurerntShowAmount];
}

- (NSInteger)currentShowAmount {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSNumber *currentNumber = [[NSUserDefaults standardUserDefaults] objectForKey:kBDUGShareDialogCurerntShowAmount];
        self->_currentShowAmount = currentNumber.integerValue;
    });
    return _currentShowAmount;
}

@end
