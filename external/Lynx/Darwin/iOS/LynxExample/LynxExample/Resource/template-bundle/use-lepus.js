¤k   asm0.2.0.0unknown2.12.1Ç   OFNI                 	    
                                2.1 # /entry/intermediate/debug-info.jsoncard  ò/app-service.js]
  (function(){
  'use strict';
  var g = (new Function('return this;'))();
  var inited = false;
  function __init_card_bundle__(lynxCoreInject){
  if(inited){return;}
  inited = true;
  g.__bundle__holder = undefined;
  var tt = lynxCoreInject.tt;
(function () {
  'use strict'
  if (typeof tt.setSourceMapRelease !== 'function') {
    return;
  }
  try {
    throw new Error("cdeb2125a5266bee33857e146be0ac79");
  } catch (e) {
    e.name = 'LynxGetSourceMapReleaseError';
    tt.setSourceMapRelease(e);
  }
})();
tt.__sourcemap__release__ = "cdeb2125a5266bee33857e146be0ac79";tt.define("app-service.js", function(require, module, exports, __Card,setTimeout,setInterval,clearInterval,clearTimeout,NativeModules,tt,console,__Component,ReactLynx,nativeAppId,Behavior,LynxJSBI,lynx,window,document,frames,self,location,navigator,localStorage,history,Caches,screen,alert,confirm,prompt,fetch,XMLHttpRequest,WebSocket,webkit,Reporter,print,global){
  lynx = lynx || {};lynx.__cardVersion="unknown";lynx._switches={asyncSetState:0,fixMergeOrder:1};lynx.targetSdkVersion="2.1"; 
  var lynxGlobal = (function(){
    if(typeof globalThis === 'object'){
      return globalThis;
    }else {
      return (0, eval)('this');
    }
  })();
;var Promise = (typeof lynx === "object" ? lynx.Promise : null) || lynxGlobal.Promise;if(typeof Promise === "undefined"){var Promise = (lynxGlobal.getPromise && lynxGlobal.getPromise({setTimeout:setTimeout,clearTimeout:clearTimeout,onUnhandled:function(id,reason){
  console.error('unhandled rejection:',reason && reason.message, reason && reason.stack)
}})) || Promise;}var __getOwnPropSymbols = Object.getOwnPropertySymbols;
var __hasOwnProp = Object.prototype.hasOwnProperty;
var __propIsEnum = Object.prototype.propertyIsEnumerable;
var __objRest = (source, exclude) => {
  var target = {};
  for (var prop in source)
    if (__hasOwnProp.call(source, prop) && exclude.indexOf(prop) < 0)
      target[prop] = source[prop];
  if (source != null && __getOwnPropSymbols)
    for (var prop of __getOwnPropSymbols(source)) {
      if (exclude.indexOf(prop) < 0 && __propIsEnum.call(source, prop))
        target[prop] = source[prop];
    }
  return target;
};
try {
  let __currentUnmountingComponent;
  (function(__global, __ReactLynx, lynx2) {
    class PropsMap {
      constructor() {
        this._map = {};
      }
      set(props = {}, propsId) {
        this._map[propsId] = props;
      }
      getProps(propsId) {
        return this._map[propsId];
      }
      deleteProps() {
        if (__currentUnmountingComponent) {
          try {
            Object.keys(__currentUnmountingComponent.__childrenPropsIds || {}).forEach((propsId2) => {
              delete this._map[propsId2];
            });
          } catch (e) {
            console.alog("shim propsMap failed: delete failed");
          }
          __currentUnmountingComponent.__childrenPropsIds = {};
        }
      }
      clear() {
        this._map = {};
      }
    }
    let shimed = false;
    for (let k in __global.multiApps) {
      const reactAppInstance = __global.multiApps[k];
      if (typeof reactAppInstance === "object" && reactAppInstance !== null) {
        if (reactAppInstance._reactLynx === __ReactLynx) {
          const __original_onReactComponentUnmount = reactAppInstance.onReactComponentUnmount;
          reactAppInstance.onReactComponentUnmount = function(componentId) {
            __currentUnmountingComponent = reactAppInstance._componentInstance[componentId];
            __original_onReactComponentUnmount.call(reactAppInstance, componentId);
            __currentUnmountingComponent = void 0;
          };
          reactAppInstance.__original_propsMap = reactAppInstance._propsMap;
          reactAppInstance._propsMap = reactAppInstance._reactLynx.propsMap = new PropsMap();
          shimed = true;
          break;
        }
      }
    }
    if (!shimed) {
      lynx2.reportError(new Error("propsMap shim failed"));
    }
  })(typeof globalThis === "object" ? globalThis : (0, eval)("this"), ReactLynx, lynx);
} catch (e) {
  if (e) {
    const {
      message,
      stack
    } = e;
    const newError = new Error(`propsMap shim failed: ${message}`);
    newError.stack = stack;
    lynx.reportError(newError);
  }
}
try {
  (function(__global, __ReactLynx, lynx2) {
    let shimed = false;
    for (let k in __global.multiApps) {
      const reactAppInstance = __global.multiApps[k];
      if (typeof reactAppInstance === "object" && reactAppInstance !== null) {
        if (reactAppInstance._reactLynx === __ReactLynx) {
          const __original_processVersionsAndCheckForConflict = reactAppInstance.processVersionsAndCheckForConflict;
          reactAppInstance.processVersionsAndCheckForConflict = function(updateState, instance) {
            const ret = __original_processVersionsAndCheckForConflict.call(reactAppInstance, updateState, instance);
            if (!(instance === reactAppInstance.appInstance)) {
              if (ret) {
                for (let k2 in updateState) {
                  delete updateState[k2];
                }
              }
            }
            return ret;
          };
          shimed = true;
          break;
        }
      }
    }
    if (!shimed) {
      lynx2.reportError(new Error("conflictDetect shim failed"));
    }
  })(typeof globalThis === "object" ? globalThis : (0, eval)("this"), ReactLynx, lynx);
} catch (e) {
  if (e) {
    const {
      message,
      stack
    } = e;
    const newError = new Error(`conflictDetect shim failed: ${message}`);
    newError.stack = stack;
    lynx.reportError(newError);
  }
}
(function(__ReactLynx) {
  const ReactLynx2 = __ReactLynx;
  ReactLynx2.__mountEvent = __mountEvent;
  ReactLynx2.__handleSpreadProps = function(instance, props, __eid_or_cid__, __eventId__N, __refId__N, isComponent, container, key) {
    const newProps = {};
    let hasSpecialProps = false;
    for (const k in props) {
      const r = extractTypeAndNameFromPropsKey(k);
      if (r && typeof props[k] === "function" && (isComponent === true && k.match(/^(bind|catch|capture-bind|global-bind|capture-catch)[A-Za-z]/) || isComponent === false && (k.match(/^on[A-Z]/) || k.match(/^(bind|catch|capture-bind|global-bind|capture-catch)[A-Za-z]/)))) {
        const handler = props[k];
        const [eventType, eventName] = r;
        const handlerName = "__id_" + __eid_or_cid__ + "_" + k + "_" + __eventId__N;
        __mountEvent(instance, handlerName, handler);
        newProps[k] = {
          __MAGIC_TYPE__: "Event",
          eventName,
          eventType,
          handlerName
        };
        hasSpecialProps = true;
      } else if (k === "ref") {
        const ref = props[k];
        newProps["react-ref"] = __putIntoRefs(instance, ref, "$reactRefId_" + __eid_or_cid__ + "_" + __refId__N, isComponent ? "com" : "native");
        hasSpecialProps = true;
      } else {
        newProps[k] = props[k];
      }
    }
    if (hasSpecialProps) {
      ReactLynx2.__push(container, key, newProps);
    }
    return newProps;
  };
  ReactLynx2.__push = function(container, key, value) {
    if (!container[key]) {
      container[key] = [];
    }
    container[key].push(value);
    return value;
  };
  ReactLynx2.__putIntoPropsMap = function(__ReactLynx2, props, parentInstance) {
    const _a = props, {
      propsId,
      children
    } = _a, rest = __objRest(_a, [
      "propsId",
      "children"
    ]);
    __ReactLynx2.propsMap.set(rest, propsId);
    parentInstance.__childrenPropsIds[propsId] = 1;
    return props;
  };
  ReactLynx2.__putIntoRefs = __putIntoRefs;
  ReactLynx2.createContext = function() {
    throw new Error("Context support is deleted from Radon Diff");
  };
  ReactLynx2.__runInJS = function(value) {
    return value;
  };
  ReactLynx2.__isEntryComponent = __isEntryComponent;
  ReactLynx2.__registerComponent = function(c, name) {
    globComponentRegistPath = name;
    __isEntryComponent(name) ? __Card(c) : __Component(c);
    return c;
  };
  function __mountEvent(instance, handlerName, handler) {
    return instance[handlerName] = handler;
  }
  function extractTypeAndNameFromPropsKey(propsKey) {
    if (propsKey.startsWith("on")) {
      const prefix = propsKey.match(/Catch$/) ? (propsKey = propsKey.slice(0, -5), "catch") : "bind";
      const suffix = propsKey.match(/^onClick/) ? "tap" : propsKey.slice(2).toLowerCase();
      return [`${prefix}Event`, suffix];
    }
    const match = propsKey.match(/^(bind|catch|capture-bind|global-bind|capture-catch)([A-Za-z]+)$/);
    if (match) {
      const eventType = match[1].indexOf("capture") > -1 ? match[1] : `${match[1]}Event`;
      return [eventType, match[2]];
    }
  }
  function __putIntoRefs(instance, ref, refId, type) {
    if (typeof ref === "object") {
      const _ref = ref;
      ref = (node) => {
        _ref.current = node;
      };
    }
    instance.$refs.push({
      ref,
      refId,
      type
    });
    return refId;
  }
  function __isEntryComponent(name) {
    return "demo1-App" === name;
  }
})(ReactLynx);
function __ReactLynx_handleThis(name, that) {
  if (Array.isArray(that.$refs) && that.$refs.length > 0) {
    that.$refs.forEach((refObj) => {
      if (typeof refObj.ref === "function") {
        try {
          refObj.ref.call(that, null);
        } catch (error) {
        }
      }
    });
  }
  that.$refs = [];
  that.__storedListEventHandlers = {};
  if (ReactLynx.__isEntryComponent(name)) {
    that.props.propsId = "app";
  }
  const constInfos = {"demo1-App":["Hello"]};
  if (constInfos[name]) {
    constInfos[name].forEach((key) => {
      delete that.__tempKeys[key];
    });
  }
}
var index_lynx_default = ReactLynx;
var Component = ReactLynx.ReactComponent;
var createContext = ReactLynx.createContext;
var __runInJS = ReactLynx.__runInJS;
var useState = ReactLynx.useState;
var useReducer = ReactLynx.useReducer;
var useEffect = ReactLynx.useEffect;
var useMemo = ReactLynx.useMemo;
var useCallback = ReactLynx.useCallback;
var useInstance = ReactLynx.useInstance;
var lazy = ReactLynx.lazy;
var _Hello = class extends Component {
  constructor() {
    super(...arguments);
    this.__childrenPropsIds = {};
  }
  render() {
    const {
      text
    } = this.props;
    return {
      props: {
        children: [{
          props: {
            children: [text]
          }
        }]
      }
    };
  }
  _createData() {
    this.__eventId__N_named = {};
    this.__eventId__N = {};
    this.__propsId__N = {};
    this.__refId__N = {};
    this.__tempKeys = {};
    __ReactLynx_handleThis("Hello-Hello", this);
    const __elementTree = this.render();
    return this.__tempKeys;
  }
};
_Hello.defaultProps = {
  text: "worldï¼"
};
var Hello = /* @__PURE__ */ ReactLynx.__registerComponent(_Hello, "Hello-Hello");
var Hello_default = Hello;
var _App = class extends Component {
  constructor() {
    super(...arguments);
    this.__childrenPropsIds = {};
  }
  render() {
    return {
      props: {
        children: [{
          type: Hello_default,
          props: ReactLynx.__putIntoPropsMap(ReactLynx, {
            "text": "world",
            "propsId": this.props.propsId + "-58216001-" + this.__propsId__N["58216001"]++
          }, this)
        }]
      }
    };
  }
  _createData() {
    this.__eventId__N_named = {};
    this.__eventId__N = {};
    this.__propsId__N = {};
    this.__refId__N = {};
    this.__propsId__N["58216001"] = 0;
    this.__tempKeys = {};
    __ReactLynx_handleThis("demo1-App", this);
    const __elementTree = this.render();
    return this.__tempKeys;
  }
};
var App = ReactLynx.__registerComponent(_App, "demo1-App");
var demo1_default = App;

});
tt.require("app-service.js");
  };
  
  if(g && g.bundleSupportLoadScript){
  var res = {init: __init_card_bundle__};
  
  g.__bundle__holder = res;
  return res
  }else{
  __init_card_bundle__({"tt": tt});
  };
  })();
textworldï¼	demo1-AppconsolealogassertdebugerrorinfologreportwarnStringindexOflengthsubstrMathabsacosasinatanceilcosexpfloormaxminpowrandomroundsinsqrttan$kTemplateAssembler __globalPropsnamestyleclassflattenclip-radiusoverlapuser-interaction-enablednative-interaction-enabledblock-native-eventenableLayoutOnlycssAlignWithLegacyW3Cintersection-observerstrigger-global-eventexposure-sceneexposure-idexposure-screen-margin-topexposure-screen-margin-bottomexposure-screen-margin-leftexposure-screen-margin-right	focusablefocus-indexaccessibility-labelaccessibility-elementaccessibility-traitsHello-HellodefaultDataProcessor
entryPointgetDerivedStateFromErrorgetDerivedStateFromPropspathrendershouldComponentUpdateassigndepstidHello$renderPage0$$__function_id__$$__func_name__<anonymous>__params_sizs__AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz__toLowerCase__noopreplace([A-Z])__hyphenlize$styleProps-push	__IsArray__emptyArray__typeofsequenceExpression__pop: array empty__popstringobjectkeys: ;__stringifyStylenumberjoin __classNames__MAGIC_TYPE__
JSXElementtypepropsheaderchildrenfooterlist-rowblockdefault__flattenListChildrenReactLynxFragment	className__static_className__static_styleiddataSetdata-set	substringdata-sliceEventhandlerInstance	eventType	eventNamehandlerMethodhandlerNameincludes_HandlePropscomponentAttrsComponent type is null, id is comptypevalue
renderList_updateComponentInfos__renderComponents__plugParent
__isInText	__isEntry__isInXTextpage	undefinedbooleanbelongingTolistListinline-textx-textx-inline-textimageinline-imageisDynamicComponentSlotslotNamemapchildraw-text__getDepIdentifiers__RegisterDataProcessor__setup__globalPropslynxNaN__Number	__Booleantruefalse[object Object]function__StringstateHello  !viewpropsId
-58216001-world
SystemInfoapptheme-appThemelocalelynx-rtlltr$page$renderComponent0__getGlobalState.{"dsl":1,"bundleModuleMode":1,"cli":"unknown"}               #    Hello-HelloHello-Hello    g    	
 !"#+$%&'()*+,-./0123456789:;<=>?@ABCDEFGH
 I
JK
LMN	ðøð¨@@ ð¤@¨@¬@°@´@¸@¼@À@ÈÌÐÔØÜàäèìðôøü ¤°Ä¨È@Ì@Ð@Ô@ØÜ@à@ä@è@ì@ð@ôøüð	¡ÀüøA¡Àüø	¡Àüø	¡Àüø¡Àüø A¡Àüø¡	¡Àüø¼ôøô¢øüð	¡ÀüøA¡Àüø	¡Àüø	¡Àüø¢¡Àüø A¡Àüø¡	¡Àüø¼ôø±£¡Àü¢Âñ¤ñ£Äù¥¦£ÄùüHü ¾øü¼ô±£¢Â¢£Äñ¤ñ§¦Êù¤Æù¥¨i¤ÆùIø@ü©¼¡Àüø1¦1I11¾ I  5OPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~K
LN	Rðøøøøøøøøøøøøøøøø ¡ø¢£ø¤¥ø¦§ø¨©øª«ø¬­ø®¯ø°±ø²³øP   K
LN	     $\K
LN	pXP` XP`@ H øP K
L$N	 HP    K
LN	X ÀXP``P  K
LN	¸P   K
LN	P   K
	LN	 HpXP`pX0HP`P
  	$
 K

LN	2 HÀXP` HÀ¢X° H ¤ÀX ° ´°H¬¤¬°¨ ¤êÿ`P`P	  $
 K
LN	mpXP` HÀXP`¨ÀÐXÉX  ¤ H¤¨ À X`¨¬¤ÀX¤¬¨¬°¨H³`¨ ¬¨H X¬ °¬H¨¨X°¸´¸¼´H`¢`¨¬¤À¤X¨¸°¼´¸´H´¼À¸°À°X¸¼´¼À¸¸XÀÈ ÄÈ ÌÄH`¨ëÿ```¬ÿ`HP
  
  ¡¢£¤K
L¥N	¬pXP`  HX ¨¬¤ÀX¤¨ ¬ °´¸¼À¬Hïÿ`P` ÀX  ¤¤¨ À X¨¬¤¨¨X¬´¼À¸°À°X¸¼´¼ÄÀÄÈÀH¬ðÿ``ã`¨¬¤À¤X¬°¨¬¬X°¸ÀÄ ¼´À´X¼À¸ÀÈ ÄÈ ÌÄH°ðÿ``Æ`¬°¨À ¨X°´¬°°X´¼ÄÈ¢À¸À¸XÀÄ ¼ÄÌ¢ÈÌ¢ÐÈHÄÌ¢ÈÌ¢ÐÈH´êÿ``£`´¸ °À°X¬`¸¼´À¬¬X´¸°¼ ÀÄÈÌÐ¼H`´¼¸¼À¸H´¼¸¼À¸H`
¥¦    
 §(¨' ©
ª«¬­
®¯°±²³´µ ¶K
L·N	Æ° H ¤À»X  ¤¨¬¤À¤X `¬°¨À  X¬0°¼ À¼H¬H¡`¨¬¤À¤X¨°¸¼´¬À¬X´¸°¼0ÀÄ¼H¨òÿ``¬°¨À¹¨X¸ ¼¸H´¬À¬X¸0¼À¸H­`´´È°`Ä ÈÄHÀ¸À°¢°X´Ä°È¢ÀÄÀHÀÈÌ¤Ä ¼À¼XÄÈ¢ÀÈ Ì¤ÄÐ0Ôì  ðìHè²à¢ä°Üà®ØÐH´çÿ``Ð`°´¬À¬XË`´¸°À°X´¼ÄÈ¢À¸À¸XÀÄ ¼È0ÌÔØªÐØÜ¬ÔÈH´íÿ`±`¸¼´À´XÀ0ÄÈÀH¨`ÀÄ ¼À¼X¸`ÄÈ¢ÀÀ ¸¸X¼Ì°Ð¦ÈÌÈHÈ ÐÔ¨Ì¤ÄÀÄX ÌÐ¦ÈÔ0Ø¤Üä¤è²àÔH¼ïÿ``ÄÌ¢ÈÌÐ¢ÔÈHÄ ¼À¼XÈ0ÌÔÜªØÜªàØHÔÈHï`Ô ØÔHÐ¦ÈÀÈÈ¤Ä`Ì¦ÄÄÈ¢À`ÐÔ¨ÌÐ¦ÈÀ¤À¢ÀXÈÌ¤ÄÄXÙÐ0ÔÜà®Øàä°Üäè²àèì´äÐH`Ð0ÔÜà®Øàä°Üäè²àÐHº`ÔÔpÔÈªÐ`Ø¬ÐÐÈ¨Ì`à äàHÜ¬ÔÀªÌÌÈ¦È`Ð¨ÈÈÈ¤Ä`ÔØªÐÔ¨ÌÀ¦ÄÄpÄXÌÌÈ¦È`Ô ÜªØÜªàØHÐp¨ÈÈXÔ0ØÜàÔH`Ô0ØÜàÔH`Áý`	¸  
 ¹ª	C'§(º°&³²»µ­
®¯£ K
L¼N	pXP` HX ¤ÀX ¤ ¨¬°¤Hñÿ`P`  HÀÈ` ÀÔX ¤ÀX`¤¨ ÀX¨0¬¤¬´¸°¨¤H¨0¬¤¬´¸°¨¤HP`¤ ¨¤H ÀX ¤ ¤¨¬°ð´¨¸ð¼Ì°Ð¦ÈÌÈHÈ ÐÔ¨Ì¤ÄÀíÄX ÌÐ¦ÈÐ¤Ô¨Ì¤ÔØªÐÀÐXÜ ¦àÜHª Ü`¤Üà®ØÀØX¬Ô`¤àä°ÜÀ®ÔÔXà ¦äàH¬¨Ì`¤Üà®ØÀØX¦Ü®¤Å`¤àä°ÜÀÜX¦à°¬¾`ð ¦ôðHì´äÀäÈ²à`¦ðô¸ìð¶èÀ´ààXèð´ìððô¦ü ¾øºðøô¦ü ¾øºðøô¦ü ¾øºðø´ôìH`¤ìô¶ðôø¶üðHì´äÀäXè¤ðø¸ôø¸üôH¦ð¶èø`è¤ì¦ð¶èø¼ÿ`£Ä0ÈÌÐÔØÜàäèìÄH`¤¨  À X`¨¬¤ÀX¤¨ ¤¤X° ´¸¼°H```
¼¦   G
 H@K
L½N	* ° H ¤ÀX ¤¤¨   ¤ ¨0¬°¼À¸ÀÄ ¼À´¨¸¨Hâÿ`¾¾  ,¿ÀÁÂÃ  ÄÅ
 ªÆ£ÇÈ
¡ÉÊËÌÍCHÎDÏÐÑÒÓK
LDN	ç  ¤ ¸ X¤° ´°H¨X¬¤`¸¼´¸°À°È¬`¼À¸¼´À¬¬X¸ ¼ÄÈ¢ÀÄ¸H¸¼´¸°¤`° ´¸¼ÀðÄÈ¢ÀøÄÈ¢ÀøÄÈ¢Àø°H¨¨P`¬°¨À¨X¤`¸ ¼¸H´¬À¤¤X `´ ¸´H°¨À  X¤¤P`¨ ¬¨H X¤¬´¸°¨À¨X°´¬¸ ¼ÀÄÈðÌÐ¦ÈøÌÐ¦ÈøÌÐ¦Èø¸H¤çÿ`¤¤P`° ´°H¬¤À¤È `°´¬°¨À  X¨¬¤¬°¨°´¬´¸°¸¼´ÀÄ  ¼À¼X¸`ÄÈ¢ÀÀ ¸¸X¼¼È`È ÌÐÔØðÜà®ØøÜà®ØøÜà®ØøÈH¼¼P`ÀÄ ¼À¼X¸`ÄÈ¢ÀÀ ¸à¸X¢Ä0È0ÌÐÄHÈ ÌÐÔÈHÀ¨Ä¨È¨Ì¨ÐÐXÔªÜäè²à®ØÀØXàªä°Üè ®ì ð¢ô¤ø¦üèHÔïÿ``Ð¨Ø àä°Ü¬ÔÀÔX Ü¨à®Øä è¬ìðäHÐñÿ`Ð¨Ø¤àä°Ü¬ÔÀÔXà ä¤ì¨ð¶è¦ð¨ô¸ìàHÐðÿ`Ð¨Ø¢àä°Ü¬ÔÀÔX¢Ü¨à®Øä è¬ìðäHÐñÿ`Ø0ÜàØHÐÐP`ÈÌ¤ÄÀÄX¢À`ÌÐ¦ÈÀ¤ÀÀX ¼`ÈÌ¤ÄÀ¢¼¼X¸`ÄÈ¢ÀÀ ¸Ô¸XÄ0ÐÐÈ¨Ì`ØÜ¬ÔÀªÌÌXÈ`ÈÌÄHÈ ÌÐÔÈHÈ0ÌÐÈHÀ·ÀXÄ¢ÌÔØªÐ¦ÈÀ¯ÈXÐ¢Ô¨ÌØ Ü¦àäèðìü ¾øÀøX¼ô`¡ÀüÀ¾ôôXð`ð¶èøìü ¾øÀøX¼ô`¡ÀüÀ¾ôôXð`ð¶èøìð¶èøØHÄÍÿ``ÀÀP`¼À¸À³¸XÄ0ÌÌXÈ`ÈÌÄHÈ ÌÐÔÈHÈ0ÌÐÈHÀÀXÄ¢ÌÔØªÐ¦ÈÀÈXÐ¢Ô¨ÌØ Ü¦àäèðìð¶èøìð¶èøìð¶èøØHÄçÿ``ÀÀP`Ä ÈÄHÀ¸À¯¸XÄ0ÈÌÄHÈ ÌÐÔÈHÈ0ÌÐÈHÀÀXÄ¢ÌÔØªÐ¦ÈÀÈXÐ¢Ô¨ÌØ Ü¦àäèðìð¶èøìð¶èøìð¶èøØHÄçÿ``ÀÀP`Ä ÈÄHÀ¸À¤¸XÀ Ä ¼Ä È¢ÀÈ¡Ì¤ÄÌ¢Ð¦ÈÐ£Ô¨ÌÐ¤ÔÔX¦à0äè0 ìðàH¬Ð¨ØØpØXÜÜP``à0¢äè0ì ðôàH¬ÐÜ ¨àäèÜHÔä°¤è²àäàHªà¬èì´ä°ÜÀ©ÜX¬äªè²àè°ì´ä²ððÈ¸ì`!²Iü¼ôÀºììÈ¶è`²øü¼ôøºðÀ¸èèXô0¨ø°üñ¥¢Âù¦°¢ÂùôH`ÔÓÿ`ÔÔXà0¨äèð§ø¸ôø@¸üôHàH`Ü0à¨äÜH¬Ü0¨àÜHÔ¯ÔXà0¨äàH¤ØØX§ä0 èì0¨ðü0¨üH1¨IüäH`ä ¨èìäHä ¨è¦ô1¨I1¨I¨ôHðôðøü¼ôøøü¼ôøøü¼ôøäH`Ôä°¤è²àäàHªà¬èì´ä°ÜÀ´ÜX¬äªè²àè°ì´ä²ððÈ¸ì`!²Iü¼ôÀºììÈ¶è`²øü¼ôøºðÀ¸èèXô0°øôHø ¶ü²ñ¤Æù¤Æù¤ÆùøHø0¨ü¶øH`ÔÈÿ`Ô»ÔXØ¬àèì´ä°ÜÀ³ÜXä¬è²à°ììÈ¶è`ü °üHøºðÀ¸èèÈ´ä`°ôøºðô¸ìÀ¶ääXð0¨ø¬ü¼ôðHô ´ø°üñ£Äù£Äù£ÄùôHô0¨ø´üôH`ØÉÿ``ÔÔP``° ´°H¬¤À¤X `´ ¸´H©°¨À  X¨¨X¤`¬¤¤X°0ª´¸¸h°H´0¸¼À´H´0¸¼´H``° ´°H¬¤À¤È `°´¬¥°¨À  X¬0´¦¸°¬H°0´¸°H`	
·D
¦ ¥¼½ ÏÐÒK
L$N	8È`  ¤ HÀÈ`ÀXðøøP`È`¤ ¨¤H ÀÈ` ÀXP`P    F
 GK
LÔN	,ð°ð H° ¤ ¨ ¤H ¤ÀX  ¨ ¸ ¼´¸°´¬¤øêÿ`P¾¾¾  K
LÕN	ÐX©00¤ ¨ ¤ H`©00¤ ¨ ¤ ¤H¾¾  %K
LÖN		ÀX  ø`×%  Å

 ØK
LÙN	" HÀXP` HÀXX`P` HÀXøP`P  K
LÚN	ppP   $ÅÛÜÝÞK
LßN	? HÀXP·` HÀXP¬` HÀXX`P`  HÀX  HX¤ ¤ H`P`  ¤ HÀXP`P
  >DÁ ÀÂ¿K
L$N	    ¤H  ¨°¬°´¸¼¬H¨¬ð°´¬ø°´¬ø°´¬ø°´¬øH¾½D  à>DK
L$N	(ðøø  ¤H @ø¤ ¤ Hð P Ô ª
»ý 
»ýáâãK
L$N	 )¨ðøøðð ø ø ð¤¬°´¨¨ øø ø¨øøøP   	DÁÀ Â¿K
L$N	    ¤H  ¨°¬°´¸¼¬H¨¬ð°´¬ø°´¬ø°´¬ø°´¬øH¾½D  àI
 DK
L$N	.ðøø  ¤H  ¤¨@ ø¤¬¨¬¨H¤ð¤ ¤P Ô ª
Àá 
Ááäå$æãK
L$N	 1ðøøððøøð ¸¨¼´¸°´¬´¨°´´°¨¬¤ø ¤øø¨ø¨øøøP   %çäèéê¶ë
ìí@K
LJN	H pÈ`X(`  øX(`ðø0¤¬ °¨ H¨ ¤ ¨ ¤HX 0¤¨¬ H` 0¤¨¬ H  ¤  ¤¨¬°H%%×%ç%%¾   îïJ¦ ç·Ú
ÙÕß¥Ôð%	¾Ö½¸×D¼ñ