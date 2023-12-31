//
//  DVEToastProtocol.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVEToastProtocol <NSObject>

- (void)show:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
