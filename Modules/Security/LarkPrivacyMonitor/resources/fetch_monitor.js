!function () {
    new PerformanceObserver((entityList) => {
        entityList.getEntries().forEach((entity) => {
            window.webkit.messageHandlers.SCSNetworkFlowMonitor.postMessage({
                "referrer": document.referrer,
                "href": window.location.href,
                "url": entity.name
            });
        });
    }).observe({entryTypes: ['resource']})
}()
