#import "TTDownloadMetaData.h"

@interface TTQueue : NSObject

- (id)initWhithSize:(NSInteger)queueSizeMax;

- (BOOL)enqueue:(id)task insertType:(InsertType)insertType;

- (id)dequeue;

- (NSInteger)getQueueTaskCount;

- (NSInteger)getQueueSizeMax;

@end
