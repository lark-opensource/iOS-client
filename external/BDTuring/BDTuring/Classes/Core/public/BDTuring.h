//
//  BDTuring.h
//  BDTuring
//
//  Created by bob on 2019/8/23.
//

#import "BDTuringDefine.h"
#import "BDTuringVerifyResult.h"

NS_ASSUME_NONNULL_BEGIN

@class UIView, BDTuringConfig, BDTuring, BDTuringVerifyModel;

/*! @abstract captcha
@discussion  UIView + WKWebview to hold the captcha
*/
__attribute__((objc_subclassing_restricted))
@interface BDTuring : NSObject

/*! @abstract current AppID
*/
@property (nonatomic, copy, readonly) NSString *appID;

/*! @abstract whether to close it when  user touch mask , default is YES
*/
@property (nonatomic, assign) BOOL closeVerifyViewWhenTouchMask;

/*! @abstract whether the captcha is shown
*/
@property (atomic, assign, readonly) BOOL isShowVerifyView;

/*! @abstract whether to move the captcha if the keyboard hidden , default is no
*/
@property (nonatomic, assign) BOOL adjustViewWhenKeyboardHiden;

/*! @abstract Delegate
*/
@property (nonatomic, weak, nullable) id<BDTuringDelegate> delegate;

/*! @abstract get a BDTuring with a  appID, if it does not exist, return nil
*/
+ (nullable instancetype)turingWithAppID:(NSString *)appID;

/*! @abstract get a BDTuring with a  BDTuringConfig, if it does not exist, create a new
*/
+ (instancetype)turingWithConfig:(BDTuringConfig *)config;

/*! @abstract use a BDTuringConfig to create a BDTuring
*/
- (instancetype)initWithConfig:(BDTuringConfig *)config;

/*! @abstract call the captcha
 @param callback the callback you want to recieve result
    [turing popVerifyViewWithModel:yourcallback];
*/

- (void)popVerifyViewWithCallback:(BDTuringVerifyResultCallback)callback;

/*! @abstract call the captcha
 @param model the model decide which captcha is actually called
 you can create model from 'BDTuringVerifyModel+Creator'
 recommended usage e.g.
    BDTuringVerifyModel *model = [BDTuringVerifyModel parameterModelWithParameter:response];
 
    model.regionType = your.config.regionType;
    model.callback = yourcallback;
    [turing popVerifyViewWithModel:model];
*/
- (void)popVerifyViewWithModel:(BDTuringVerifyModel *)model;

- (void)preloadVerifyViewWithModel:(BDTuringVerifyModel *)model;


/*! @abstract call the picture  captcha
 @param regionType CN SG or VA
 @param challengeCode  challengeCode or the errorCode
 @param callback callback on main queue
 
 recommended usage e.g.
    yourcode = xxx
    BDTuringVerifyModel *model = [BDTuringVerifyModel pictureModelWithCode:yourcode];
    BDTuringVerifyModel *model = [BDTuringVerifyModel slidePictureModelWithCode:yourcode];
    BDTuringVerifyModel *model = [BDTuringVerifyModel rotatePictureModelWithCode:yourcode];
 
    model.regionType = your.config.regionType;
    model.callback = yourcallback;
    [turing popVerifyViewWithModel:model];
*/
- (void)popPictureVerifyViewWithRegionType:(BDTuringRegionType)regionType
                             challengeCode:(NSInteger)challengeCode
                                  callback:(BDTuringVerifyCallback)callback __attribute__((deprecated("please use -[BDTuring popVerifyViewWithModel] & [BDTuring popVerifyViewWithCallback]")));


/*! @abstract call the sms captcha
 @param regionType CN SG or VA
 @param scene the scene
 @param callback callback on main queue
  recommended usage e.g.
     BDTuringVerifyModel *model = [BDTuringVerifyModel smsModelWithScene:@"your scene"];
  
     model.regionType = your.config.regionType;
     model.callback = yourcallback;
     [turing popVerifyViewWithModel:model];
*/
- (void)popSMSVerifyViewWithRegionType:(BDTuringRegionType)regionType
                                 scene:(NSString *)scene
                              callback:(BDTuringVerifyCallback)callback __attribute__((deprecated("please use -[BDTuring popVerifyViewWithModel]  & [BDTuring popVerifyViewWithCallback]")));


/*! @abstract  you close it
*/
- (void)closeVerifyView;

+ (NSString *)sdkVersion;

@end

NS_ASSUME_NONNULL_END
