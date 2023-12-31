// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_SSR_SSR_NODE_KEY_H_
#define LYNX_SSR_SSR_NODE_KEY_H_

namespace lynx {
namespace ssr {

static constexpr char kSSRApiVersion[] = "1.1";

class ServerDomConstructor;

/* Here is the specification of ssr format
 * SSR format is represented by a lepus value.
 * The value is similar to a nested dictionary,
 * but for better performance, value is stored as an array.
 * And each field of data will be stored at a fixed position of the array,.
 * And this file describe what data is stored in each position of the array.
 */

// The SSR page is stored in the kSSRRootTree.
// And a RadonValue type array is stored in kSSRRootTree.
namespace SSRDataKey {
enum Keys : uint32_t {
  kVersion = 0,
  kPageConfig,
  kPageProps,
  kGlobalProps,
  kSystemInfo,
  kSSRRootTree,
  kSpecialInfo,
  kSSRScript,
  kCount
};
}

namespace CSSInfoKey {
enum Keys : uint32_t {
  kCSSId = 0,
  kValueType,
  kValuePattern,
  kCSSValueType,
  kDefaultValue,
  kValue,
  kCount
};
}

// An array describes RadonBase is stored in the kRadonBase.
// Depending on the type of node, an array to describe the extra info for the
// type of node will be stored in kRadonTypedValue. Currently the type can be
// RadonPlug/RadonNode/RadonComponent
namespace RadonValueKey {
enum Keys : uint32_t { kRadonBase = 0, kRadonTypedValue, kNodeType, kCount };
}

namespace RadonBaseKey {
enum Keys : uint32_t {
  kRadonChildren = 0,
  kTagName,
  kNodeType,
  kNodeIndex,
  kCount
};
}

namespace RadonPlugKey {
enum Keys : uint32_t { kComponentSsrId = 0, kCount };
};

namespace RadonEventKey {
enum Keys : uint32_t { kType = 0, kName, kFuncName, kArgs, kEventType, kCount };

enum EventType : uint32_t {
  kNormal,
  kPiper,
};

enum PiperEventParams : uint32_t {
  kPiperName = 0,
  kPiperArgs,
  kPiperInfoCount
};
}  // namespace RadonEventKey

// CSS is stored in kStyles.
namespace RadonNodeKey {
enum Keys : uint32_t {
  kStyles = 0,
  kAttributes,
  kStaticEvents,
  kDataSet,
  kCount
};
}

// Radon component is inherited from RadonNode,
// So that info of the Radon is stored here.
namespace RadonComponentKey {
enum Keys : uint32_t { kRadonNode = 0, kTid, kName, kSsrId, kCount };
}

namespace RadonSlotKey {
enum Keys : uint32_t { kRadonSlotName = 0, kCount };
}

// page config props
#define FOREACH_PAGECONFIG_FIELD(V)             \
  V(Version, String)                            \
  V(GlobalFlattern, BOOL)                       \
  V(GlobalImplicit, BOOL)                       \
  V(DSL, DSLType)                               \
  V(AutoExpose, BOOL)                           \
  V(BundleModuleMode, BundleModeType)           \
  V(EnableAsyncDisplay, BOOL)                   \
  V(EnableImageDownsampling, BOOL)              \
  V(EnableViewReceiveTouch, BOOL)               \
  V(EnableLepusStrictCheck, BOOL)               \
  V(LepusQuickjsStackSize, Integer)             \
  V(EnableEventThrough, BOOL)                   \
  V(EnableLepusNullPropAsUndef, BOOL)           \
  V(EnableTextNonContiguousLayout, BOOL)        \
  V(AbsoluteInContentBound, BOOL)               \
  V(QuirksMode, BOOL)                           \
  V(FontScaleSpOnly, BOOL)                      \
  V(RemoveComponentElement, BOOL)               \
  V(StrictPropType, BOOL)                       \
  V(EnableNewLayoutOnly, BOOL)                  \
  V(CSSAlignWithLegacyW3C, BOOL)                \
  V(EnableLocalAsset, BOOL)                     \
  V(EnableComponentLifecycleAlignWebview, BOOL) \
  V(EnableCSSInheritance, BOOL)                 \
  V(CustomCSSInheritList, UnorderedSet)         \
  V(UnifyVWVH, BOOL)                            \
  V(UseNewImage, NewImageType)                  \
  V(AsyncRedirectUrl, BOOL)                     \
  V(CliVersion, String)                         \
  V(CustomData, String)                         \
  V(UseNewSwiper, BOOL)                         \
  V(EnableCSSStrictMode, BOOL)                  \
  V(TargetSDKVersion, String)                   \
  V(LepusVersion, String)                       \
  V(RadonMode, String)                          \
  V(EnableLepusNG, BOOL)                        \
  V(TapSlop, String)                            \
  V(DefaultOverflowVisible, BOOL)               \
  V(EnableCreateViewAsync, BOOL)                \
  V(EnableSavePageData, BOOL)                   \
  V(ListNewArchitecture, BOOL)                  \
  V(EnableListMoveOperation, BOOL)              \
  V(EnableAccessibilityElement, BOOL)           \
  V(EnableOverlapForAccessibilityElement, BOOL) \
  V(ReactVersion, String)                       \
  V(DefaultDisplayLinear, BOOL)                 \
  V(EnableTextRefactor, BOOL)                   \
  V(DataStrictMode, BOOL)                       \
  V(EnableZIndex, BOOL)                         \
  V(EnableReactOnlyPropsId, BOOL)               \
  V(EnableLynxAir, BOOL)                        \
  V(EnableTextLayerRender, BOOL)                \
  V(GlobalAutoResumeAnimation, BOOL)            \
  V(EnableReduceInitDataCopy, BOOL)             \
  V(EnableCSSParser, BOOL)                      \
  V(IsTargetSdkVerionHigherThan21, BOOL)        \
  V(KeyboardCallbackUseRelativeHeight, BOOL)    \
  V(EnableEventRefactor, BOOL)                  \
  V(ForceCalcNewStyle, BOOL)                    \
  V(TrialOptions, LepusValue)

namespace PageConfigKey {
enum PageConfig : uint32_t {
  kPageConfigStart = 0,
#define GEN_PAGECONFIG_KEYS(name, type) k##name,
  FOREACH_PAGECONFIG_FIELD(GEN_PAGECONFIG_KEYS)
#undef GEN_PAGECONFIG_KEYS
      kPageConfigCount,
};

enum Keys : uint32_t {
  kSupportComponentJS = 0,
  kTargetSdkVersion,
  kUseLepusNG,
  kPageConfig,
  kCount
};
}  // namespace PageConfigKey

static constexpr const char* const kLepusModuleFromPiper = "fromPiper";
static constexpr const char* const kLepusModuleCallbackId = "callbackId";
static constexpr const char* const kLepusModuleMethodDetail = "methodDetail";
static constexpr const char* const kLepusModuleParam = "param";
static constexpr const char* const kLepusModuleMethod = "method";
static constexpr const char* const kLepusModuleModule = "module";
static constexpr const char* const kLepusModuleTasmEntryName = "tasmEntryName";
static constexpr const char* const kLepusModuleCallMethod = "call";

}  // namespace ssr
}  // namespace lynx
#endif  // LYNX_SSR_SSR_NODE_KEY_H_
