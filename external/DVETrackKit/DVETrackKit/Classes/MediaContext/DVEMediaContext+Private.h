//
//   DVEMediaContext+Private.h
//   DVETrackKit
//
//   Created  by ByteDance on 2021/12/8.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEMediaContext ()

@property (nonatomic, strong) RACSubject *editorDidChangeSubject;

@property (nonatomic, strong) RACSubject *coverButtonChangeSubject;

@end


NS_ASSUME_NONNULL_END
