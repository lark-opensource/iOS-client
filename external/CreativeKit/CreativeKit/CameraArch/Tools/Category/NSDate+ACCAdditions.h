//
//  NSDate+ACCAdditions.h
//  CameraClient
//
//  Created by Liu Deping on 2019/12/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (ACCAdditions)

- (NSString *)acc_stringWithFormat:(NSString *)format;
- (NSInteger)acc_dateInteger;
@end

NS_ASSUME_NONNULL_END
