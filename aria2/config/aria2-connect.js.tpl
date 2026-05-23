(function () {
  var storageKey = "AriaNg.Options";
  var versionKey = "fzdocker.aria2.configVersion";
  var configVersion = "${RPC_PORT}:${RPC_SECRET_STANDARD_BASE64}";

  if (localStorage.getItem(versionKey) === configVersion) {
    return;
  }

  var options = {};
  try {
    options = JSON.parse(localStorage.getItem(storageKey) || "{}");
  } catch (e) {
    options = {};
  }

  options.rpcHost = location.hostname || "localhost";
  options.rpcPort = "${RPC_PORT}";
  options.rpcInterface = "jsonrpc";
  options.protocol = "http";
  options.httpMethod = options.httpMethod || "POST";
  options.secret = "${RPC_SECRET_STANDARD_BASE64}";

  localStorage.setItem(storageKey, JSON.stringify(options));
  localStorage.setItem(versionKey, configVersion);
})();
