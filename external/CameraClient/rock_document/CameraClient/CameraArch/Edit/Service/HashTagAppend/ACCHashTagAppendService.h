//
//  ACCHashTagAppendService.h
//  CameraClient
//
//  Created by liuqing on 2020/5/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// ************************************************************************
// ***** IM STORY 模式在用 请勿再加任何代码，后面清理IM STORY的时候回一并清理掉 *****
// ************************************************************************

@protocol ACCHashTagAppendService <NSObject>

@required

- (void)appendHashTagIfNeededWithAppendPublishTitle:(NSMutableString *)publishTitle;
- (NSMutableString *)appendingPublishTitle;
- (NSMutableString *)appendingPublishTitleForSelectMusic;
- (void)updatePublishTitleWithHashTagArray:(NSArray *)currentHashTagArray appendingPublishTitle:(NSMutableString *)publishTitle;
- (void)saveHashTagToTitleExtraInfo;

- (NSString *)generatepublishTitleWithChallengeNames:(NSArray<NSString *> *)challengeNameArray publishTItle:(NSString *)publishTItle;

@end

NS_ASSUME_NONNULL_END
