
var global = typeof window !== 'undefined'
? window : typeof global !== 'undefined' ? global : typeof self !== 'undefined' ? self : {};
;

(function() {
    function needReport(params) {
        if (window.location.href === 'about:blank') {
            return false;
         }
        return true;
    }

    // 埋点统计
    function statLogMonitor(params, service) {
        if (!needReport(params)) {
            return
        }
        params.serviceType = service
        if (window.webkit) {
            window.webkit.messageHandlers.lkMailStatLogMonitor.postMessage(params);
        } else if (window.lkMailStatLogMonitor) {
            lkMailStatLogMonitor(params);
        }
    }

     // initTime
    function statLogInitTime(jsDuration) {
        if (!needReport([jsDuration])) {
            return
        }
        var body = {duration:jsDuration}
        if (window.webkit) {
            window.webkit.messageHandlers.lkMailStatLogInitTime.postMessage(body);
        } else if (window.lkMailStatLogInitTime) {
            lkMailStatLogInitTime(body);
        }
    }

    function onDomContentLoaded() {
        var msg = {}
        msg.stage = 'DomContentLoaded';
        window.setTimeout(function() {
            // native 计算webview初始化时间
            if (window.history.length <= 1) {
                statLogInitTime(performance.now());
            }
        }, 0)
    }

    var bridge = {}
    bridge.lkMailStatLogMonitor = statLogMonitor
    bridge.lkMailStatLogInitTime = statLogInitTime
    global.lkMailMonitor = bridge

    // Use the handy event callback
    window.addEventListener( "DOMContentLoaded", onDomContentLoaded );

    function sendError(errorDic) {
        var eventValue = {}
        var category = errorDic.category;
        var msg = errorDic.msg;
        var title = errorDic.title;
        eventValue["category"] = category;
        eventValue["msg"] = msg;
        eventValue["title"] = title;
        var message = {}
        message.action = category
        message.event = eventValue
        statLogMonitor(message, 'monitor')
    }

    var addEventListener = global.addEventListener;
    // https://developer.mozilla.org/zh-CN/docs/Web/Events/unhandledrejection
    if (addEventListener) {
    global.addEventListener('unhandledrejection', function (event) {
        if (event) {
        var reason = event.reason;
        sendError({
            title: 'unhandledrejection',
            msg:'unhandledrejection' + reason,
            category: 'js_error',
            level: 'error'
            });
        }
        }, true);
//    global.addEventListener('error', function (event) {
//        if (event) {
//        var target = event.target || event.srcElement;
//        var isElementTarget = target instanceof HTMLElement;
//        const { message, source, lineno, colno, error } = event;
//        // var url = target.src || target.href;
//        if (!isElementTarget) {
//        sendError({
//            title:"error",
//            msg:message,
//            category:'js_error',
//            level: 'error'
//            });
//        };
//        }
//        }, true);
    }
})()
