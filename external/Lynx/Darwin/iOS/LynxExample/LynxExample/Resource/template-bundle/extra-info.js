     m0.2.0.0unknown2.12.1ß   OFNI                	    
                                 2.1 ; http://10.87.50.213:8787/main1/intermediate/debug-info.jsoncard  /app-service.jsµ
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
    throw new Error("c17d999bb9524f75e16e1aa4a050d0be");
  } catch (e) {
    e.name = 'LynxGetSourceMapReleaseError';
    tt.setSourceMapRelease(e);
  }
})();
tt.__sourcemap__release__ = "c17d999bb9524f75e16e1aa4a050d0be";tt.define("app-service.js", function(require, module, exports, Card,setTimeout,setInterval,clearInterval,clearTimeout,NativeModules,tt,console,Component,TaroLynx,nativeAppId,Behavior,LynxJSBI,lynx,window,document,frames,self,location,navigator,localStorage,history,Caches,screen,alert,confirm,prompt,fetch,XMLHttpRequest,WebSocket,webkit,Reporter,print,global){
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
}})) || Promise;}var __getOwnPropNames = Object.getOwnPropertyNames;
var __commonJS = (cb, mod) => function __require() {
  return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
};
var require_counter = __commonJS({
  "src/component/counter/index.js?sfc"() {
    globComponentRegistPath = "src/component/counter/index";
    Component({});
  }
});
var require_text = __commonJS({
  "src/component/text/index.js?sfc"() {
    globComponentRegistPath = "src/component/text/index";
    Component({});
  }
});
require_counter();
require_text();
globComponentRegistPath = "src/index";
Card({
  data: {
    "test": "test",
    "color": "red"
  },
  handleTap() {
    this.setData({
      count: this.data.count + 1
    });
  },
  onLoad() {
    this.setData({
      "user": "nihao1",
      "age": 18
    });
  }
});

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
//# sourceMappingURL=http://10.87.50.213:8787/main1/intermediate/app-service.js.map	src/indexcolorredtestl{"enableLayoutOnly":true,"extraInfo":{"a":1},"component":false,"dsl":0,"bundleModuleMode":1,"cli":"unknown"} 	              ++T     countersrc/component/counter/index    cus-textsrc/component/text/index    ¬    .__globalPropsSystemInfoa
color
nihao"$renderComponent0"$renderComponent1$renderPage0
$page_CreatePage&$kTemplateAssembler_AttachPage$component
$data$props$recursive$parent"$componentInfoMap$child"_GetComponentInfo$_CreateVirtualNodetext_AppendChildraw-text*_SetStaticAttributeToÈTÈT  c o u n t e r 	e,gÄ~öN$childComponent(_UpdateComponentInfocounter6src/component/counter/indexcus-text0src/component/text/index _MarkPageElementpage$_SetDynamicStyleTodisplay:$;background-color:;view._CreateVirtualComponent_ProcessData2_MarkComponentHasRenderer"_GetComponentData$_GetComponentProps_SetAttributeTo     ×    ?Ë   ?Ì   ?Í   ?Î   ?Ï   ?Ð   ?Ñ   ?Ò   @?Ó   >Ë   >Ì   >Í   >Î   >Ï   >Ð   >Ñ   ½@Ò    >Ó   :Ë   :Ì   :Í   :Î   :Ï   :Ð   :Ñ   ½ MÐ   9Ð   Æ½MÑ   9Ñ   Æ8Ô   ²8Õ   í:Ó   8Ö   8Õ   8Ó   íÊ(^   6 8 à Ð   Ð Ð Ð  0  Å À 0 À  À Ð ` C    n®  °  ²  ´  ¶  ¸ º ¶ ` ` `  ÎÆ8Þ   a  ìÇÈ8ß   à   ¶íb 8á   a  a í` a É8ß   â   ·íb 8ã   a à   ä   î8á   a a í)^Í  Ð 	ð °      ° °     Ð  p   à  ° À    à  @   Ð  p PC    n®  °  ²  ´  ¶  ¸ º ¶ ` ` `  ÎÆ8Þ   a  ìÇÈ8ß   à   ¸íb 8á   a  a í` a É8ß   â   ¹íb 8ã   a à   å   î8á   a a í)^Ç  ðË 	ð °      ° °     Ð  p   à  ° À    à  
ð  Ð  p PC ¤  
¦  ´  ¶  ¸ º ¶ ¶ º Ì ¶
 ` ` `  ÎÆ8ç   a  è   ²8Ð   é   & é   " 8ç   a  ê   ³8Ñ   ë   & ë   " 8Þ   a  ìÇÈ8ì   ë8ß   í   ²íb 8á   a  a í8î   a ï   8Í   ð   8Î   ñ   í` a É8ß   ò   ³íb 8á   a a í` a À` ` 8ó   ³8Õ   ê   ë   ²" Àa À8á   a a í8ô   a ìÏç*8õ   a ì8Ñ   a 8ö   a ì8÷   a ìÏ" 8ß   à   ´íb 8á   a a í` a À8ß   â   µíb 8ø   a à   8Ï   î8á   a a í)^ð  ø 	ð ` Ð  À À ÿÿÿß Ð 0 à  Ð  Ð  ÿÿÿ¯   0 °          ° °     Ð  p  °  À    À   `  0    à  °     Ð  p   à  Ð  0 Ð À À   ð p Ð  p  Ð p P À    p       p   ° p   ° Ð °     Ð  p   à  ° À      ð   Ð  p 