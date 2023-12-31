//
//  HTSVideoAudioSupplier.h
//  Pods
//
//  Created by 何海 on 16/8/11.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^HTSVideoAudioCompletion)(id audio, NSError *error);
typedef BOOL (^HTSVideoAudioEnableClipBlock)(id audio);
typedef void (^HTSVideoAudioWillClipBlock)(id audio, NSError *error);

@protocol HTSVideoAudioSupplier <NSObject>

@property (nonatomic, copy) HTSVideoAudioCompletion completion;
@property (nonatomic, copy) HTSVideoAudioEnableClipBlock enableClipBlock;
@property (nonatomic, copy) HTSVideoAudioWillClipBlock willClipBlock;

@end
