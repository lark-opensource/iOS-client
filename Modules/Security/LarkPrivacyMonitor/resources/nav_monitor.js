!function () {
    window.webkit.messageHandlers.SCSNetworkFlowMonitor.postMessage({
        "href": window.location.href,
        "url": window.location.href,
        "referrer": document.referrer
    });
}()
