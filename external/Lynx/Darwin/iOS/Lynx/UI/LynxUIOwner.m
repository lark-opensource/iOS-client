// Copyright 2019 The Lynx Authors. All rights reserved.
#import "LynxUIOwner.h"
#import "LynxBaseInspectorOwner.h"
#import "LynxComponentRegistry.h"
#import "LynxEnv.h"
#import "LynxEventHandler.h"
#import "LynxFontFaceManager.h"
#import "LynxGenericReportInfo.h"
#import "LynxGlobalObserver.h"
#import "LynxPropsProcessor.h"
#import "LynxRootUI.h"
#import "LynxService.h"
#import "LynxServiceAppLogProtocol.h"
#import "LynxTemplateRender+Internal.h"
#import "LynxTimingHandler.h"
#import "LynxTraceEvent.h"
#import "LynxTraceEventWrapper.h"
#import "LynxUI+Internal.h"
#import "LynxUICollection.h"
#import "LynxUIComponent.h"
#import "LynxUIContext.h"
#import "LynxUIExposure.h"
#import "LynxUIImage.h"
#import "LynxUIIntersectionObserver.h"
#import "LynxUIMethodProcessor.h"
#import "LynxUIOwner+Accessibility.h"
#import "LynxUIText.h"
#import "LynxUIUnitUtils.h"
#import "LynxView+Internal.h"
#import "LynxViewInternal.h"
#import "LynxWeakProxy.h"
#import "UIView+Lynx.h"

// TODO(zhengsenyao): For white-screen problem investigation of preLayout, remove it later.
NSString* const kEnableLynxDetailLog = @"enable_lynx_detail_log";
const NSString* const kLynxTimingFlag = @"__lynx_timing_flag";

#pragma mark LynxUIContext (Internal)

@interface LynxUIContext () {
  __weak LynxEventHandler* _eventHandler;
  __weak LynxEventEmitter* _eventEmitter;
  __weak UIView* _rootView;
  NSDictionary* _keyframesDict;
}

@end

@implementation LynxUIContext (Internal)

- (void)setEventHandler:(LynxEventHandler*)eventHandler {
  _eventHandler = eventHandler;
}

- (void)setEventEmitter:(LynxEventEmitter*)eventEmitter {
  _eventEmitter = eventEmitter;
}

- (void)setRootView:(UIView*)rootView {
  _rootView = rootView;
}

- (void)setKeyframesDict:(NSDictionary*)keyframesDict {
  _keyframesDict = keyframesDict;
}

- (void)mergeKeyframesWithLynxKeyframes:(LynxKeyframes*)keyframes forKey:(NSString*)name {
  if (_keyframesDict == nil) {
    _keyframesDict = [[NSMutableDictionary alloc] init];
  }
  [(NSMutableDictionary*)_keyframesDict setValue:keyframes forKey:name];
}

@end

#pragma mark LynxUIOwner

@interface LynxUIOwner ()
@property(nonatomic) LynxRootUI* rootUI;
@property(nonatomic) CGSize oldRootSize;
@property(nonatomic) BOOL hasRootAttached;
@property(nonatomic, weak) LynxView* containerView;
@property(nonatomic) NSMutableDictionary<NSString*, LynxWeakProxy*>* nameLynxUIMap;
@property(nonatomic) NSMutableDictionary<NSNumber*, LynxUI*>* uiHolder;
@property(nonatomic) NSMutableArray* a11yMutationList;
@property(nonatomic) NSMutableArray<id<LynxForegroundProtocol>>* foregroundListeners;
/**
 * componentIdToUiIdHolder is used to map radon component id to element id.
 * Because unlike virtual component id, radon component id is not equal to element id.
 * In method invokeUIMethod, we need to use this map and radon(js) component id to find related
 * UI.
 */
@property(nonatomic) NSMutableDictionary<NSNumber*, NSNumber*>* componentIdToUiIdHolder;
@property(nonatomic) NSMutableSet<LynxUI*>* uisThatHasNewLayout;
@property(nonatomic) NSMutableSet<LynxUI*>* uisThatHasOperations;
@property(nonatomic) LynxFontFaceContext* fontFaceContext;
@property(nonatomic) LynxComponentScopeRegistry* componentRegistry;
// Record used components in LynxView.
@property(nonatomic) NSMutableSet<NSString*>* componentSet;
@property(nonatomic) NSMutableDictionary<NSString*, NSHashTable<LynxUI*>*>* a11yIDHolder;
@end

@implementation LynxUIOwner {
  BOOL _enableDetailLog;
}

- (void)attachLynxView:(LynxView* _Nonnull)containerView {
  _containerView = containerView;
  _uiContext.rootView = _containerView;
}

- (instancetype)initWithContainerView:(LynxView*)containerView
                       templateRender:(LynxTemplateRender*)templateRender
                    componentRegistry:(LynxComponentScopeRegistry*)registry
                        screenMetrics:(LynxScreenMetrics*)screenMetrics {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"LynxUIOwner init")
  self = [super init];
  if (self) {
    _enableDetailLog = [LynxEnv getBoolExperimentSettings:kEnableLynxDetailLog];
    _containerView = containerView;
    _templateRender = templateRender;
    _hasRootAttached = NO;
    _nameLynxUIMap = [[NSMutableDictionary alloc] init];
    _uiHolder = [[NSMutableDictionary alloc] init];
    _componentIdToUiIdHolder = [[NSMutableDictionary alloc] init];
    _oldRootSize = CGSizeZero;
    _uiContext = [[LynxUIContext alloc] initWithScreenMetrics:screenMetrics];
    _uiContext.rootView = containerView;
    _uiContext.rootUI = _rootUI;
    _uisThatHasNewLayout = [NSMutableSet new];
    _uisThatHasOperations = [NSMutableSet new];
    _fontFaceContext = [LynxFontFaceContext new];
    _uiContext.fontFaceContext = _fontFaceContext;
    _fontFaceContext.rootView = containerView;
    _componentRegistry = registry;
    _componentSet = [[NSMutableSet alloc] init];
    _a11yIDHolder = [[NSMutableDictionary alloc] init];
    _a11yMutationList = [[NSMutableArray alloc] init];
    _foregroundListeners = [[NSMutableArray alloc] init];
    // make sure singleton `LynxEnv` is already initialized
    // for registry of some LynxUI
    [LynxEnv sharedInstance];
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(didReceiveMemoryWarning)
               name:UIApplicationDidReceiveMemoryWarningNotification
             object:nil];

    [self listenAccessibilityFocused];
  }
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
  return self;
}

- (NSArray<LynxUI*>*)uiWithA11yID:(NSString*)a11yID {
  return self.a11yIDHolder[a11yID] ? [self.a11yIDHolder[a11yID] allObjects] : @[];
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
  [_uiHolder enumerateKeysAndObjectsUsingBlock:^(NSNumber* _Nonnull key, LynxUI* _Nonnull obj,
                                                 BOOL* _Nonnull stop) {
    if ([obj respondsToSelector:@selector(freeMemoryCache)]) {
      [obj freeMemoryCache];
    }
  }];
}

- (LynxUI*)findUIBySign:(NSInteger)sign {
  return [_uiHolder objectForKey:[NSNumber numberWithInteger:sign]];
}

/**
 * Finds the component by its component id.
 *
 * If the component to find is root, whose component id is -1, then getRootUI()
 * is returned. If the component to find is a VirtualComponent, whose component
 * id equals to its sign of ui, then findUIBySign is called to find it directly.
 * If the component to find is a RadonComponent, whose component id doesn't
 * equal to its sign of ui, then mComponentIdToUiIdHolder is used to find its
 * sign before calling findUIBySign.
 *
 * @param componentId the id of the component to find.
 * @return the component to find.
 */
- (LynxUI*)findUIByComponentId:(NSInteger)componentId {
  if (componentId == -1) {
    return _rootUI;
  }
  NSInteger sign = _componentIdToUiIdHolder[@(componentId)]
                       ? [_componentIdToUiIdHolder[@(componentId)] integerValue]
                       : componentId;
  return [self findUIBySign:sign];
}

- (LynxUI*)findUIByIdSelector:(NSString*)idSelector withinUI:(LynxUI*)ui {
  if (ui && [ui.idSelector isEqualToString:idSelector]) {
    return ui;
  }

  for (LynxUI* child in ui.children) {
    if ([child.idSelector isEqualToString:idSelector]) {
      return child;
    }
    if (![child isKindOfClass:LynxUIComponent.class]) {
      LynxUI* target = [self findUIByIdSelector:idSelector withinUI:child];
      if (target != nil) {
        return target;
      }
    }
  }

  return nil;
}

- (LynxUI*)findUIByIdSelectorInParent:(NSString*)idSelector child:(LynxUI*)child {
  if (child && [child.idSelector isEqualToString:idSelector]) {
    return child;
  }

  if (!child) {
    return nil;
  }

  LynxUI* parent = child.parent;
  if (parent) {
    return [self findUIByIdSelectorInParent:idSelector child:child];
  }
  return nil;
}

// refId is used in ReactLynx
- (LynxUI*)findUIByRefId:(NSString*)refId withinUI:(LynxUI*)ui {
  if (ui && [ui.refId isEqualToString:refId]) {
    return ui;
  }

  for (LynxUI* child in ui.children) {
    if ([child.refId isEqualToString:refId]) {
      return child;
    }
    if (![child isKindOfClass:LynxUIComponent.class]) {
      LynxUI* target = [self findUIByRefId:refId withinUI:child];
      if (target != nil) {
        return target;
      }
    }
  }

  return nil;
}

// Due to historical reason, componentSet may be used in another thread. To promise thread safty,
// we return an empty set in this function. And this function will be removed later.
- (NSSet<NSString*>*)componentSet {
  (void)_componentSet;
  return [[NSSet alloc] init];
}

/**
 * Only reported when the component is first created.
 *
 * @param componentName the used component in LynxView
 */
- (void)componentStatistic:(NSString*)componentName {
  // According to the client configuration "enable_component_statistic_report" whether to enable
  // reporting.
  if ([LynxEnv getBoolExperimentSettings:@"enable_component_statistic_report"] &&
      ![_componentSet containsObject:componentName]) {
    [_componentSet addObject:componentName];
    __weak typeof(self) weakSelf = self;
    // Report asynchronously to avoid affecting the main thread.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      __strong __typeof(weakSelf) strongSelf = weakSelf;
      if (strongSelf == nil) {
        return;
      }
      // statistical data: A component in LynxView.
      // statistical data: LynxView information.
      // AppLog object, through which statistical data is reported.
      NSDictionary* extraData = [[strongSelf->_templateRender genericReportInfo] toJson];
      [LynxService(LynxServiceAppLogProtocol) onReportEvent:@"lynxsdk_component_statistic"
                                                      props:@{@"component_name" : componentName}
                                                  extraData:extraData];
    });
  }
}

- (void)invokeUIMethod:(NSString*)method
                params:(NSDictionary*)params
              callback:(LynxUIMethodCallbackBlock)callback
              fromRoot:(int)componentId
               toNodes:(NSArray*)nodes {
  LynxUI* targetUI = [self findUIByComponentId:componentId];
  NSString* errorMsg = @"component not found";

  if (targetUI) {
    for (size_t i = 0; i < nodes.count; i++) {
      NSString* node = [nodes objectAtIndex:i];
      BOOL isCalledByRef = params != nil && params.count > 0 && params[@"_isCallByRefId"];
      if (![node hasPrefix:@"#"] && !isCalledByRef) {
        if (callback) {
          callback(
              kUIMethodSelectorNotSupported,
              [node stringByAppendingString:@" not support，only support id selector currently"]);
        }
        return;
      }
      targetUI = isCalledByRef
                     ? [self findUIByRefId:node withinUI:targetUI]
                     : [self findUIByIdSelector:[node substringFromIndex:1] withinUI:targetUI];
      if (!targetUI) {
        errorMsg = [@"not found " stringByAppendingString:node];
        break;
      }
    }
  }

  if (targetUI) {
    [LynxUIMethodProcessor invokeMethod:method
                             withParams:params
                             withResult:callback
                                  forUI:targetUI];
  } else if (callback) {
    callback(kUIMethodNodeNotFound, errorMsg);
  }
}

- (void)invokeUIMethodForSelectorQuery:(NSString*)method
                                params:(NSDictionary*)params
                              callback:(LynxUIMethodCallbackBlock)callback
                                toNode:(int)sign {
  LynxUI* targetUI = [self findUIBySign:sign];
  if (targetUI) {
    LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                       [[targetUI.tagName ?: @"UIOwner"
                           stringByAppendingString:@".invokeUIMethodForSelectorQuery."]
                           stringByAppendingString:method ?: @""]);
    [LynxUIMethodProcessor invokeMethod:method
                             withParams:params
                             withResult:callback
                                  forUI:targetUI];
    LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER);
  } else if (callback) {
    callback(kUIMethodNoUiForNode, @"node does not have a LynxUI");
  }
}

- (bool)isTransitionProps:(NSString*)value {
  return [value hasPrefix:@"transition"];
}

- (bool)isTransformProps:(NSString*)value {
  if ([value isEqualToString:@"transform"]) {
    return true;
  }
  return false;
}

- (void)addAttributeTimingFlagFromProps:(NSDictionary*)props {
  if (!props) {
    return;
  }
  id timingFlagValue = [props objectForKey:kLynxTimingFlag];
  if (![timingFlagValue isKindOfClass:[NSString class]] || [timingFlagValue length] == 0) {
    // timingFlagValue is illegal, just return.
    return;
  }
  [self.uiContext.timingHandler addAttributeTimingFlag:timingFlagValue];
}

- (void)createUIWithSign:(NSInteger)sign
                 tagName:(NSString*)tagName
                eventSet:(NSSet<NSString*>*)eventSet
           lepusEventSet:(NSSet<NSString*>*)lepusEventSet
                   props:(NSDictionary*)props {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                     [@"UIOwner.createView." stringByAppendingString:tagName ?: @""])
  BOOL supported = YES;
  LynxUI* ui;
  if (!_hasRootAttached && [tagName isEqualToString:@"page"]) {
    _hasRootAttached = YES;
    _rootUI = [[LynxRootUI alloc] initWithLynxView:_containerView];
    _uiContext.rootUI = (LynxRootUI*)_rootUI;
    [_uiContext.uiExposure setRootUI:_rootUI];
    ui = _rootUI;
    LLogInfo(@"LynxUIOwner create rootUI %p with containerView %p", _rootUI, _containerView);
  } else {
    Class clazz = [_componentRegistry uiClassWithName:tagName accessible:&supported];
    if (supported) {
      ui = [[clazz alloc] init];
      [[self.containerView getLifecycleDispatcher] lynxViewDidCreateElement:ui name:tagName];
    }
  }
  if (supported) {
    ui.context = _uiContext;
    ui.sign = sign;
    ui.tagName = tagName;
    [ui setImplicitAnimation];
    [ui updateCSSDefaultValue];
    if (eventSet || lepusEventSet) {
      [ui setRawEvents:eventSet andLepusRawEvents:lepusEventSet];
    }
    [_uiHolder setObject:ui forKey:[NSNumber numberWithInteger:sign]];
    // Report the usage of the component.
    [self componentStatistic:tagName];
    [self updateComponentIdToUiIdMapIfNeedWithSign:sign tagName:tagName props:props];
    if (props && props.count != 0) {
      [self addAttributeTimingFlagFromProps:props];
      // TODO(WUJINTIAN): Like eventSet, passing the transition and animation properties separately
      // can avoid extra traversal.
      //  When updating UI, the transition and animation properties need to be consumed last.
      for (NSString* key in props) {
        if (![self isTransitionProps:key] && ![key hasPrefix:@"animation-"]) {
          [LynxPropsProcessor updateProp:props[key] withKey:key forUI:ui];
        }
      }
      for (NSString* key in props) {
        if ([self isTransitionProps:key] || [key hasPrefix:@"animation-"]) {
          [LynxPropsProcessor updateProp:props[key] withKey:key forUI:ui];
        }
      }
    }
    if (ui.a11yID) {
      NSHashTable<LynxUI*>* table = self.a11yIDHolder[ui.a11yID];
      if (!table) {
        table = [NSHashTable weakObjectsHashTable];
        self.a11yIDHolder[ui.a11yID] = table;
      }
      [table addObject:ui];
    }
    if ([ui conformsToProtocol:@protocol(LynxForegroundProtocol)]) {
      [self registerForegroundListener:(id<LynxForegroundProtocol>)ui];
    }

    [ui animationPropsDidUpdate];
    [ui propsDidUpdate];
    if ([ui notifyParent]) {
      [self markHasUIOperationsBottomUp:ui];
    } else {
      [self markHasUIOperations:ui];
    }
    [self addLynxUIToNameLynxUIMap:ui];
  } else {
    @throw [NSException
        exceptionWithName:@"LynxCreateUIException"
                   reason:[NSString stringWithFormat:@"%@ ui not found when create UI", tagName]
                 userInfo:nil];
  }
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)updateUIWithSign:(NSInteger)sign
                   props:(NSDictionary*)props
                eventSet:(NSSet<NSString*>*)eventSet
           lepusEventSet:(NSSet<NSString*>*)lepusEventSet {
  LynxUI* ui = _uiHolder[[NSNumber numberWithInteger:sign]];
  [self updateComponentIdToUiIdMapIfNeedWithSign:sign tagName:ui.tagName props:props];
  LYNX_TRACE_SECTION_WITH_INFO(LYNX_TRACE_CATEGORY_WRAPPER,
                               [@"UIOwner.updateProps." stringByAppendingString:ui.tagName ?: @""],
                               props)
  if (eventSet || lepusEventSet) {
    [ui setRawEvents:eventSet andLepusRawEvents:lepusEventSet];
  }
  if (props && props.count != 0) {
    [self addAttributeTimingFlagFromProps:props];
    // TODO(WUJINTIAN): Like eventSet, passing the transition and animation properties separately
    // can avoid extra traversal.
    //  When updating UI, the transition and animation properties need to be consumed first.
    for (NSString* key in props) {
      if ([self isTransitionProps:key] || [key isEqualToString:@"animation"]) {
        [LynxPropsProcessor updateProp:props[key] withKey:key forUI:ui];
      }
    }
    [ui animationPropsDidUpdate];
    for (NSString* key in props) {
      if (![self isTransitionProps:key] && ![key isEqualToString:@"animation"]) {
        [LynxPropsProcessor updateProp:props[key] withKey:key forUI:ui];
      }
    }
  }
  [ui propsDidUpdate];
  [self markHasUIOperations:ui];
  [self addLynxUIToNameLynxUIMap:ui];
  if ([self observeA11yMutations]) {
    for (NSString* key in props) {
      [self addA11yPropsMutation:key sign:@(sign) a11yID:ui.a11yID toArray:self.a11yMutationList];
    }
  }
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
  if (!ui) {
    LLogError(@"LynxUIOwner.mm unable to update ui with sign:%@ props:%@", @(sign), props);
  }
}

- (void)insertNode:(NSInteger)childSign toParent:(NSInteger)parentSign atIndex:(NSInteger)index {
  LynxUI* child = _uiHolder[[NSNumber numberWithInteger:childSign]];
  LynxUI* parent = _uiHolder[[NSNumber numberWithInteger:parentSign]];
  if (child == nil || parent == nil) {
    @throw [NSException exceptionWithName:@"LynxInsertUIException"
                                   reason:@"child or parent is null"
                                 userInfo:nil];
  }
  if (index == -1) {  // If the index is equal to -1 should add to the last
    index = parent.children.count;
  }
#if LYNX_ENABLE_TRACING
  // stringByAppendingFormat is not suitable for the situation which may be executed frequently
  NSString* p2c =
      [[parent.tagName stringByAppendingString:@"->"] stringByAppendingString:child.tagName ?: @""];
  [LynxTraceEvent beginSection:LYNX_TRACE_CATEGORY_WRAPPER
                      withName:[[@"UIOwner.createView." stringByAppendingString:@"parent->child:"]
                                   stringByAppendingString:p2c ?: @""]];
#endif
  if (_enableDetailLog && [parent isEqual:_rootUI]) {
    LLogInfo(@"LynxUIOwner insert node %p to rootUI %p", child, parent);
  }
  [parent insertChild:child atIndex:index];
  [self markHasUIOperations:parent];
  if ([self observeA11yMutations]) {
    [self addA11yMutation:@"insert"
                     sign:@(childSign)
                   a11yID:child.a11yID
                  toArray:self.a11yMutationList];
  }
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)listWillReuseNode:(NSInteger)sign withItemKey:(NSString*)itemKey {
  LynxUI* node = _uiHolder[[NSNumber numberWithInteger:sign]];
  if (node) {
    if ([node.parent isKindOfClass:LynxUICollection.class]) {
      [node onListCellPrepareForReuse:itemKey withList:node.parent];
    }
  }
}

- (void)detachNode:(NSInteger)childSign {
  LynxUI* child = _uiHolder[[NSNumber numberWithInteger:childSign]];
  if (child == nil) {
    @throw [NSException exceptionWithName:@"LynxDetachUIException"
                                   reason:@"child is null"
                                 userInfo:nil];
  }
  LynxUI* parent = child.parent;
  if (parent != nil) {
    [self recordNodeThatNeedLayoutBottomUp:parent];
    NSUInteger index = [parent.children indexOfObject:child];
    if (index != NSNotFound) {
      [parent removeChild:child atIndex:index];
    }
    if ([parent notifyParent]) {
      [self markHasUIOperationsBottomUp:parent];
    } else {
      [self markHasUIOperations:parent];
    }
  }
  if ([self observeA11yMutations]) {
    [self addA11yMutation:@"remove"
                     sign:@(childSign)
                   a11yID:child.a11yID
                  toArray:self.a11yMutationList];
  }
}

- (void)removeUIFromHolderRecursively:(LynxUI*)node {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                     [@"UIOwner.remove." stringByAppendingString:node.tagName ?: @""])

  [_uiHolder removeObjectForKey:@(node.sign)];
  [self removeLynxUIFromNameLynxUIMap:node];
  [_uiContext removeUIFromExposuredMap:node];
  [_uiContext removeUIFromIntersectionManager:node];
  if ([self observeA11yMutations]) {
    [self addA11yMutation:@"detach"
                     sign:@(node.sign)
                   a11yID:node.a11yID
                  toArray:self.a11yMutationList];
  }
  for (LynxUI* child in node.children) {
    [self removeUIFromHolderRecursively:child];
  }
  if (node.a11yID) {
    [self.a11yIDHolder[node.a11yID] removeObject:node];
  }
  if ([node conformsToProtocol:@protocol(LynxForegroundProtocol)]) {
    [self unRegisterForegroundListener:(id<LynxForegroundProtocol>)node];
  }
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)recycleNode:(NSInteger)sign {
  LynxUI* child = _uiHolder[[NSNumber numberWithInteger:sign]];
  if (child == nil) {
    return;
  }
  LynxUI* parent = child.parent;
  if (parent != nil) {
    [self recordNodeThatNeedLayoutBottomUp:parent];
    NSUInteger index = [parent.children indexOfObject:child];
    if (index != NSNotFound) {
      [parent removeChild:child atIndex:index];
    }
    if ([parent notifyParent]) {
      [self markHasUIOperationsBottomUp:parent];
    } else {
      [self markHasUIOperations:parent];
    }
  }
  [self removeUIFromHolderRecursively:child];
}

- (void)updateUI:(NSInteger)sign
      layoutLeft:(CGFloat)left
             top:(CGFloat)top
           width:(CGFloat)width
          height:(CGFloat)height
         padding:(UIEdgeInsets)padding
          border:(UIEdgeInsets)border
          margin:(UIEdgeInsets)margin
          sticky:(nullable NSArray*)sticky {
  LynxUI* ui = _uiHolder[[NSNumber numberWithInteger:sign]];
  if (!ui) {
    return;
  }
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                     [@"UIOwner.updateLayout." stringByAppendingString:ui.tagName ?: @""])
  CGRect frame = CGRectMake(left, top, width, height);
  if (ui.alignHeight) {
    (&frame)->size.height = (NSInteger)height;
  }
  if (ui.alignWidth) {
    (&frame)->size.width = (NSInteger)width;
  }
  // To make up for the precision loss caused by float calculation or float to double conversion.
  [LynxUIUnitUtils roundRectToPhysicalPixelGrid:&frame];
  [LynxUIUnitUtils roundInsetsToPhysicalPixelGrid:&padding];
  [LynxUIUnitUtils roundInsetsToPhysicalPixelGrid:&border];
  [LynxUIUnitUtils roundInsetsToPhysicalPixelGrid:&margin];

  [ui updateFrame:frame
              withPadding:padding
                   border:border
                   margin:margin
      withLayoutAnimation:!ui.isFirstAnimatedReady];
  if (!ui.context.enableFiberArch) {
    // fiber arch use onNodeReady, no need do this hack operation
    [ui onAnimatedNodeReady];
  }
  [ui updateSticky:sticky];
  if ([ui notifyParent]) {
    [self markHasUIOperationsBottomUp:ui];
  } else {
    [self markHasUIOperations:ui];
  }
  [self recordNodeThatNeedLayoutBottomUp:ui];
  if ([self observeA11yMutations]) {
    [self addA11yMutation:@"update" sign:@(sign) a11yID:ui.a11yID toArray:self.a11yMutationList];
  }
  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

- (void)updateUI:(NSInteger)sign
      layoutLeft:(CGFloat)left
             top:(CGFloat)top
           width:(CGFloat)width
          height:(CGFloat)height
         padding:(UIEdgeInsets)padding
          border:(UIEdgeInsets)border {
  [self updateUI:sign
      layoutLeft:left
             top:top
           width:width
          height:height
         padding:padding
          border:border
          margin:UIEdgeInsetsZero
          sticky:nil];
}

- (void)recordNodeThatNeedLayoutBottomUp:(LynxUI*)ui {
  while (ui) {
    if ([_uisThatHasNewLayout containsObject:ui]) {
      break;
    }
    [_uisThatHasNewLayout addObject:ui];
    ui = ui.parent;
  }
}

- (void)willContainerViewMoveToWindow:(UIWindow*)window {
  [_uiContext.uiExposure willMoveToWindow:window == nil ? YES : NO];
  [_rootUI dispatchMoveToWindow:window];
}

- (void)onReceiveUIOperation:(id)value onUI:(NSInteger)sign {
  LynxUI* ui = _uiHolder[[NSNumber numberWithInteger:sign]];
  if (ui) {
    LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                       [@"UIOwner.ReceiveUIOperation." stringByAppendingString:ui.tagName ?: @""]);
    [ui onReceiveUIOperation:value];
    LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
  }
}

- (void)markHasUIOperations:(LynxUI*)ui {
  if (ui) {
    [_uisThatHasOperations addObject:ui];
  }
}

- (void)markHasUIOperationsBottomUp:(LynxUI*)ui {
  while (ui) {
    [_uisThatHasOperations addObject:ui];
    ui = ui.parent;
  }
}

- (void)finishLayoutOperation:(int64_t)operationID componentID:(NSInteger)componentID {
  NSMutableSet<LynxUI*>* uisThatHasOperations = [NSMutableSet setWithSet:_uisThatHasOperations];
  [_uisThatHasOperations removeAllObjects];
  for (LynxUI* ui in uisThatHasOperations) {
    [ui finishLayoutOperation];
  }
  if ([self observeA11yMutations]) {
    [self flushMutations:self.a11yMutationList withLynxView:self.rootUI.lynxView];
  }
  // find the right componnet by componentID on async-list
  if (componentID) {
    LynxUIComponent* component = (LynxUIComponent*)[self findUIBySign:componentID];
    [component asyncListItemRenderFinished:operationID];
  }
  // Notify layout did finish.
  [_rootUI.context.observer notifyLayout:nil];
}

- (void)layoutDidFinish {
  NSMutableSet<LynxUI*>* uisThatHasNewLayout = [NSMutableSet setWithSet:_uisThatHasNewLayout];
  [_uisThatHasNewLayout removeAllObjects];
  for (LynxUI* ui in uisThatHasNewLayout) {
    LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                       [@"UIOwner.layoutFinish." stringByAppendingString:ui.tagName ?: @""])
    [ui layoutDidFinished];
    LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
  }

  if (_containerView && !CGSizeEqualToSize(_oldRootSize, _rootUI.frame.size)) {
    _containerView.intrinsicContentSize = _rootUI.frame.size;
    _oldRootSize = _rootUI.frame.size;
  }
  [_rootUI.context.eventEmitter dispatchLayoutEvent];

  // Post `UIAccessibilityLayoutChangedNotification` to trigger updating accessibility elements
  if (UIAccessibilityIsVoiceOverRunning()) {
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
  }
  // Notify layout did finish.
  [_rootUI.context.observer notifyLayout:nil];
}

- (void)onAnimatedNodeReady:(NSInteger)sign {
  LynxUI* ui = _uiHolder[[NSNumber numberWithInteger:sign]];
  if (ui) {
    LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER,
                       [@"UIOwner.onAnimatedNodeReady." stringByAppendingString:ui.tagName ?: @""])
    [ui onAnimatedNodeReady];
    LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
  }
}

- (void)onNodeReady:(NSInteger)sign {
  LynxUI* ui = _uiHolder[[NSNumber numberWithInteger:sign]];
  if (ui) {
    if (ui.context.enableFiberArch) {
      // here to simulate onAnimatedNodeReady process in onNodeReady, it's better to remove
      // onAnimatedNodeReady
      [ui onAnimatedNodeReady];
    }
    [ui onNodeReady];
    // Notify layout did finish.
    [_rootUI.context.observer notifyLayout:nil];
  }
}

- (nullable LynxUI*)uiWithName:(NSString*)name {
  for (NSNumber* sign in _uiHolder) {
    LynxUI* ui = _uiHolder[sign];
    if ([ui.name isEqualToString:name]) {
      return ui;
    }
  }
  return nil;
}

- (nullable LynxUI*)uiWithIdSelector:(NSString*)idSelector {
  for (NSNumber* sign in _uiHolder) {
    LynxUI* ui = _uiHolder[sign];
    if ([ui.idSelector isEqualToString:idSelector]) {
      return ui;
    }
  }
  return nil;
}

- (void)reset {
  [_uiContext.uiExposure destroyExposure];
  if ([_uiContext.intersectionManager enableNewIntersectionObserver]) {
    [_uiContext.intersectionManager destroyIntersectionObserver];
  }
  [_uiHolder removeAllObjects];
  [_componentIdToUiIdHolder removeAllObjects];
  _hasRootAttached = NO;
  _oldRootSize = CGSizeZero;
  [_foregroundListeners removeAllObjects];
}

- (void)pauseRootLayoutAnimation {
  _rootUI.layoutAnimationRunning = NO;
}

- (void)resumeRootLayoutAnimation {
  _rootUI.layoutAnimationRunning = YES;
}

- (void)updateAnimationKeyframes:(NSDictionary*)keyframesDict {
  NSDictionary* dict = [keyframesDict objectForKey:@"keyframes"];
  for (NSString* name in dict) {
    LynxKeyframes* keyframes = [[LynxKeyframes alloc] init];
    keyframes.styles = dict[name];
    [_uiContext mergeKeyframesWithLynxKeyframes:keyframes forKey:name];
  }
}

/**
 *在 cell 复用 ，prepareForReuse 时进行调用，复用成功时调用 restart。
 */
- (void)resetAnimation {
  [_uiHolder enumerateKeysAndObjectsUsingBlock:^(NSNumber* _Nonnull key, LynxUI* _Nonnull obj,
                                                 BOOL* _Nonnull stop) {
    [obj.animationManager resetAnimation];
  }];
}
- (void)restartAnimation {
  [_uiHolder enumerateKeysAndObjectsUsingBlock:^(NSNumber* _Nonnull key, LynxUI* _Nonnull obj,
                                                 BOOL* _Nonnull stop) {
    [obj.animationManager restartAnimation];

    if ([obj isKindOfClass:[LynxUIImage class]]) {
      LynxUIImage* uiImage = (LynxUIImage*)obj;
      if (uiImage.isAnimated) {
        [uiImage startAnimating];
      }
    }
  }];
}

/**
 * when LynxView is enter foreground
 */
- (void)onEnterForeground {
  [self resumeAnimation];
  for (id listener in _foregroundListeners) {
    [listener onEnterForeground];
  }
}

/**
 * when LynxView is enter background
 */
- (void)onEnterBackground {
  for (id listener in _foregroundListeners) {
    [listener onEnterBackground];
  }
}

/**
 * register listener for LynxUI which implement `LynxForegroundProtocol` protocol
 * LynxForegroundProtocol is triggered when lynxview enter/exit foreground
 */
- (void)registerForegroundListener:(id<LynxForegroundProtocol>)listener {
  [_foregroundListeners addObject:listener];
}

/**
 * unregister listener for LynxUI which implement `LynxForegroundProtocol` protocol
 * LynxForegroundProtocol is triggered when lynxview enter/exit foreground
 */
- (void)unRegisterForegroundListener:(id<LynxForegroundProtocol>)listener {
  [_foregroundListeners removeObject:listener];
}

- (void)resumeAnimation {
  [_uiHolder enumerateKeysAndObjectsUsingBlock:^(NSNumber* _Nonnull key, LynxUI* _Nonnull obj,
                                                 BOOL* _Nonnull stop) {
    [obj.animationManager resumeAnimation];
  }];
}

- (void)updateFontFaceWithDictionary:(NSDictionary*)dic {
  if (dic == nil) return;

  NSString* fontFamily = [dic valueForKey:@"font-family"];
  NSString* src = [dic valueForKey:@"src"];

  LynxFontFace* face = [[LynxFontFace alloc] initWithFamilyName:fontFamily andSrc:src];
  if (face == nil) return;

  [_fontFaceContext addFontFace:face];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)updateClient:(id<LynxViewClient>)client {
#pragma clang diagnostic pop
  _fontFaceContext.resourceFetcher = client;
  _uiContext.imageFetcher = client;
}

- (LynxComponentScopeRegistry*)getComponentRegistry {
  return _componentRegistry;
}

- (void)didMoveToWindow:(BOOL)windowIsNil {
  [_uiContext.uiExposure didMoveToWindow:windowIsNil];
  if ([_uiContext.intersectionManager enableNewIntersectionObserver]) {
    [_uiContext.intersectionManager didMoveToWindow:windowIsNil];
  }
  if (!windowIsNil) {
    [self resumeAnimation];
  }
}

#pragma mark - property: nameLynxUIMap related

- (void)addLynxUIToNameLynxUIMap:(LynxUI*)ui {
  if (ui.name && ui.name.length != 0) {
    LynxWeakProxy* weakUI = [LynxWeakProxy proxyWithTarget:ui];
    [_nameLynxUIMap setObject:weakUI forKey:ui.name];
  }
}

- (void)removeLynxUIFromNameLynxUIMap:(LynxUI*)ui {
  if (ui.name && ui.name.length != 0) {
    LynxWeakProxy* weakLynxUI = [_nameLynxUIMap objectForKey:ui.name];
    if (weakLynxUI) {
      [_nameLynxUIMap removeObjectForKey:ui.name];
    }
  }
}

- (nullable LynxWeakProxy*)weakLynxUIWithName:(NSString*)name {
  return [_nameLynxUIMap objectForKey:name];
}

- (id<LynxBaseInspectorOwner>)baseInspectOwner {
  return _containerView ? _containerView.baseInspectorOwner : nil;
}

- (BOOL)observeA11yMutations {
  return self.rootUI.context.enableA11yIDMutationObserver && UIAccessibilityIsVoiceOverRunning();
}

#pragma mark - property: componentIdToUiIdMap related

- (void)updateComponentIdToUiIdMapIfNeedWithSign:(NSInteger)sign
                                         tagName:(NSString*)tagName
                                           props:(NSDictionary*)props {
  if ([tagName isEqualToString:@"component"] && [props objectForKey:@"ComponentID"]) {
    [_componentIdToUiIdHolder setObject:@(sign) forKey:[props objectForKey:@"ComponentID"]];
  }
}

- (BOOL)isTagVirtual:(NSString*)tagName {
  BOOL supported = YES;
  Class clazz = [_componentRegistry shadowNodeClassWithName:tagName accessible:&supported];
  if (supported) {
    LynxShadowNode* node;
    NSInteger sign = 0;
    if (clazz) {
      node = [[clazz alloc] initWithSign:sign tagName:tagName];
      return [node isVirtual];
    }
  }
  return NO;
}
@end
