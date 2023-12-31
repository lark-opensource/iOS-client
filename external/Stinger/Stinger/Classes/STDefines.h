//
//  STDefines.h
//  Pods
//
//  Created by 李永光 on 2019/12/11.
//

#ifndef STDefines_h
#define STDefines_h

typedef void *StingerIMP;


#pragma mark - enum

typedef NS_OPTIONS(NSInteger, STOptions) {
    STOptionAfter = 0,     // Called after the original implementation (default)
    STOptionInstead = 1,   // Will replace the original implementation.
    STOptionBefore = 2,    // Called before the original implementation.
    STOptionAutomaticRemoval = 1 << 3, // Will remove the hook after the first execution.
    STOptionWeakCheckSignature = 1 << 16, // Original method's signature and the block's signature should be consistent by default. The return type only check when STOptionInstead is on. With STOptionWeakCheckSignature on, we will only check the first argument type(id<StingerParams>) and the return type.
};

#define StingerPositionFilter 0x07

typedef NS_ENUM(NSInteger, STHookErrorCode) {
    STHookErrorErrorMethodNotFound = -1,
    STHookErrorErrorBlockNotMatched = -2,
    STHookErrorErrorIDExisted = -3,
    STHookErrorOther = -4,
};


#pragma mark - protocol

@protocol STToken <NSObject>

/// Remove a specific hook.
/// @return YES if deregistration is successful, otherwise NO.
- (BOOL)remove;

@end


@protocol STHookInfo <STToken>
@required
@property (nonatomic, assign) SEL selector;
@property (nonatomic, copy) id block;
@property (nonatomic, assign) STOptions options;
@property (nonatomic, weak) id object;

@optional
+ (instancetype)infoWithSelector:(SEL)selector object:(id)object options:(STOptions)optionss block:(id)block error:(NSError **)error;

@end


@protocol StingerParams
@required
- (id)slf;
- (SEL)sel;
- (NSArray *)arguments;
- (NSString *)typeEncoding;
- (void)invokeAndGetOriginalRetValue:(void *)retLoc;

/*!@method preGenerateInvocationIfNeed
   @discussion 初始化函数的参数准备，提前存储调用参数，
   可以支持异步 @p -[StingerParam_invokeAndGetOriginalRetValue:] 调用
 */
- (void)preGenerateInvocationIfNeed;
@end


@protocol STHookInfoPool <NSObject>
@required
@property (nonatomic, strong, readonly) NSMutableArray<id<STHookInfo>> *beforeInfos;
@property (nonatomic, strong, readonly) id<STHookInfo> insteadInfo;
@property (nonatomic, strong, readonly) NSMutableArray<id<STHookInfo>> *afterInfos;
@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic) IMP originalIMP;
@property (nonatomic) SEL sel;
@property (nonatomic) StingerIMP stingerIMP;

- (BOOL)addInfo:(id<STHookInfo>)info;
- (BOOL)removeInfo:(id<STHookInfo>)info;

@optional
@property (nonatomic, weak) Class hookedCls;
@property (nonatomic, weak) Class statedCls;
@property (nonatomic, assign) BOOL isInstanceHook;

+ (instancetype)poolWithTypeEncoding:(NSString *)typeEncoding originalIMP:(IMP)imp selector:(SEL)sel;
@end

#endif /* STDefines_h */
