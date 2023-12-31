const sendiOSMessage = (message, body) => {
  const send = window.webkit?.messageHandlers?.sendDataToiOS;
  if (send) send.postMessage(message, body);
};

const openPicker = (config) => {
  const send = window.webkit?.messageHandlers?.openPicker;
  send && send.postMessage(config);
};

const close = () => {
  const send = window.webkit?.messageHandlers?.close;
  send && send.postMessage("close");
};

export { openPicker, close };
