(function() {
    console.log("try inject LKWebTranslateJSB _dispatchEventFromNative");

    if (window.LKWebTranslateJSB) {
        return;
    }

    function _dispatchEventFromNative(message) {
        console.log(message);
        console.log(message.param);
        if (message.func) {
            var evt = document.createEvent('Events');
            evt.initEvent(message.func, false, true);
            if (typeof message.param === 'object') {
                for (var k in message.param) {
                    evt[k] = message.param[k];
                }
            }
            document.dispatchEvent(evt);
        }
    }

    window.LKWebTranslateJSB = {
        _dispatchEventFromNative: _dispatchEventFromNative
    };

    console.log("inject LKWebTranslateJSB _dispatchEventFromNative success");
})();
