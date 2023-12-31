//
//  LVDraftMigrationTask590.h
//  VideoTemplate
//
//  Created by Nemo on 2021/6/25.
//

#import "LVDraftMigrationTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVDraftMigrationTask590 : LVDraftMigrationTask

@end

@interface LVDraftFigureEffectMigration : NSObject

+ (void)migrateFigureOfDraftString:(NSString *)jsonString
                         draftPath:(NSString *)draftPath
                        completion:(void (^)(NSString *, LVMigrationResultError))completion;

+ (void)migrateFigureOfDraft:(NSDictionary *)json
                   draftPath:(NSString *)draftPath
                  completion:(void (^)(NSMutableDictionary *, LVMigrationResultError))completion;

+ (NSMutableDictionary *)migratePartialFaceEffect:(NSDictionary *)JSON;

@end

NS_ASSUME_NONNULL_END
