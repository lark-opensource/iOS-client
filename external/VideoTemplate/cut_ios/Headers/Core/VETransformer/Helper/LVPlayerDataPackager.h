////
////  LVPlayerDataPackager.h
////  LVTemplate
////
////  Created by zenglifeng on 2019/8/27.
////
//
#import <Foundation/Foundation.h>
#import "LVMediaDraft.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVPlayerDataPackager : NSObject

//+ (NSString *)genTextParametersOfSegment:(LVMediaSegment *)segment;

+ (void)setTextPlaceHolder:(NSString *)placeHolder;

+ (void)setTaileaderPlaceHolder:(NSString *)placeHolder;

+ (NSString *)taileaderPlaceHolder;

@end

NS_ASSUME_NONNULL_END
