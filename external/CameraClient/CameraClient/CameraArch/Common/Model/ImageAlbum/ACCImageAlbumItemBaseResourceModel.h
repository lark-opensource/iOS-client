//
//  ACCImageAlbumItemBaseResourceModel.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/4.
//

#import <Foundation/Foundation.h>
#import <Mantle/MTLModel.h>
#import "ACCImageAlbumEditorDefine.h"

NS_ASSUME_NONNULL_BEGIN

/**
               -------------            VE item  processed              -------------
 file path setter        | 绝对路径 |      ------------------------------>       | 相对路径 |    ------> 存到 repo image data
               ------------             draft item processed             ------------
 file path getter   < --------------------------------------------------------------------------------------------------------
 
 后续可以processer改为从外面业务注入的方式，现在是自己作为了processer去直接操作了
 
 因此 我们存入repo image的草稿中的路径都是子类处理过的相对路径，在runtime的时候 根据子类的处理去拼接出正确的路径
 
---> 草稿资源 ACCImageAlbumItemDraftResourceRestorableModel
  * 处理的是 根据taskId获取的草稿目录
  * filepath setter 我们自己的草稿路径下的资源  可以传相对路径 也可以传 绝对路径，会去掉草稿目录
  * filepath getter 绝对路径 根据当前草稿目录进行拼接
 
---> VE资源 ACCImageAlbumItemVEResourceRestorableModel
  * 处理的是 document路径，和现在视频VE的处理方式类似
  * filepath setter VE目录下的绝对路径
  * filepath getter 会根据当前document 路径去拼接filePath
 
 ---> 为什么两种资源处理方式不同？
  * 主要是考虑到迁机需求，草稿目录下的资源会同步迁移过来，只有根据草稿目录和相对路径才能正确获取
  *  而VE资源的迁机恢复走的是草稿恢复重新下载的模式，所以其实不会用到迁机过来的路径，并且资源不是保存在草稿目录下
 
 --->  目前贴纸的VE资源比较特殊 因为是拷贝到资源目录下的 所以当做草稿资源使用
 
*/

FOUNDATION_EXPORT NSArray *ACCImageAlbumDeepCopyObjectArray(NSArray <NSObject<NSCopying> *> *targetArray);
FOUNDATION_EXPORT NSDictionary *ACCImageAlbumDeepCopyObjectDictionary(NSDictionary <id, NSObject<NSCopying> *> *targetDictionary);

@interface ACCImageAlbumItemBaseItemModel : MTLModel

ACCImageEditModeObjUsingCustomerInitOnly;

- (instancetype)initWithTaskId:(NSString *)taskId;

@property (nonatomic, copy, readonly) NSString *taskId;

- (id)copyWithZone:(nullable NSZone *)zone NS_REQUIRES_SUPER;

/// @override
/// 从草稿恢复会copy一份pulishViewModel,在编辑后点取消需要能恢复到原貌， 所以我们的数据也需要进行一次深拷贝
/// 子类根据自己的propertys进行处理，基础类型 或者 非mutable的string等不需要处理
/// override to deep copy objects or objects in array / dictionary ...
- (void)deepCopyValuesIfNeedFromTarget:(id)target NS_REQUIRES_SUPER;

/// 资源恢复 或者迁机等 重新load了VE资源后更新
- (void)updateRecoveredEffectIfNeedWithIdentifier:(NSString *)effectIdentifier filePath:(NSString *)filePath;

/// 比较奇怪的需求，将一个图集分裂成多个publish model去发布成多个作品
/// 得益于之前存储的是文件名称并且继承了统一的资源基类，我们将所有带草稿资源的model进行资源自动copy
/// draft目录(继承ACCImageAlbumItemDraftResourceRestorableModel)，将自动做迁移，子类可不处理
/// 非draft资源(继承ACCImageAlbumItemVEResourceRestorableModel)，例如特效滤镜等因为是共用的VE目录-
/// 则并不需要迁移，子类如需处理可按需override自己处理
/// NS_REQUIRES_SUPER 进行taskId的重新赋值
- (void)amazingMigrateResourceToNewDraftWithTaskId:(NSString *)taskId NS_REQUIRES_SUPER;

@end

@interface ACCImageAlbumItemBaseResourceModel : ACCImageAlbumItemBaseItemModel

ACCImageEditModeObjUsingCustomerInitOnly;

- (void)setAbsoluteFilePath:(NSString *)filePath;

- (NSString *)getAbsoluteFilePath;

#pragma mark - util
/// 后续可以改成注入一个资源获取的delegate 而不是由image data自己去做草稿的处理
+ (NSString *)draftFolderPathWithTaskId:(NSString *)taskId;
+ (NSString *)documentPath;

@end

@interface ACCImageAlbumItemDraftResourceRestorableModel : ACCImageAlbumItemBaseResourceModel

@end


@interface ACCImageAlbumItemVEResourceRestorableModel : ACCImageAlbumItemBaseResourceModel

@property (nonatomic, copy) NSString *effectIdentifier;

@end

NS_ASSUME_NONNULL_END
