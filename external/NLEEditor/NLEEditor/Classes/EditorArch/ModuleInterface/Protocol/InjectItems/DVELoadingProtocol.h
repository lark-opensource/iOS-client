//
//  DVELoadingProtocol.h
//  NLEEditor
//
//  Created by Lincoln on 2022/1/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol DVELoadingProtocol <NSObject>

- (void)showLoadingOnWindow;

- (void)updateLoadingLabelWithText:(NSString *)text;

- (void)dismissLoadingOnWindow;

@end

NS_ASSUME_NONNULL_END
