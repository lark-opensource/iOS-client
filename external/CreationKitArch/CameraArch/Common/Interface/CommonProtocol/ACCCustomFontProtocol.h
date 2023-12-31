//
//  ACCCustomFontProtocol.h
//  Pods
//
//  Created by chengfei xiao on 2019/11/13.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>
#import "AWEStoryTextImageModel.h"


NS_ASSUME_NONNULL_BEGIN

@protocol ACCCustomFontProtocol <NSObject>

- (UIFont *)fontWithModel:(AWEStoryFontModel *)fontModel size:(CGFloat)size;

- (NSArray<AWEStoryFontModel *> *)stickerFonts;

- (void)downloadFontWithModel:(AWEStoryFontModel *)model completion:(void (^)(NSString *filePath,BOOL success))completion;

- (void)prefetchFontEffects;

- (AWEStoryFontModel *)fontModelForName:(NSString *)fontName;

- (NSString *)fontFilePath:(NSString *)filePath;

@end

FOUNDATION_STATIC_INLINE id<ACCCustomFontProtocol> ACCCustomFont() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCCustomFontProtocol)];
}

NS_ASSUME_NONNULL_END
