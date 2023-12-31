//
//  LVExporterVideoData+Private.h
//  LVTemplate
//
//  Created by luochaojing on 2020/3/10.
//

#ifndef LVExporterVideoData_Private_h
#define LVExporterVideoData_Private_h

#import "LVExporterVideoData.h"
#import <TTVideoEditor/HTSVideoData.h>
#import "LVMediaDraft.h"

@interface LVExporterVideoData ()

@property (nonatomic, strong, readonly) HTSVideoData *videoData;
@property (nonatomic, strong, readonly) LVMediaDraft *draft;

- (instancetype)initWithVideoData:(HTSVideoData *)videoData draft:(LVMediaDraft *)draft;

@end

#endif /* LVExporterVideoData_Private_h */
