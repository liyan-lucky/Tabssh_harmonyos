const fs = require('fs');
const path = require('path');
const Module = require('module');
const { createRequire } = require('module');

const toolsRoot = path.resolve(process.env.DEVECO_TOOLS_ROOT || 'C:/Program Files/Huawei/DevEco Studio/tools');
const sdkRoot = path.resolve(process.env.TABSSH_HWSDK_ROOT || 'C:/Program Files/Huawei/DevEco Studio/sdk/default');
const hvigorRoot = path.resolve(toolsRoot, 'hvigor');
const hvigorEntry = path.resolve(hvigorRoot, 'bin/hvigorw.js');
const hvigorRequire = createRequire(hvigorEntry);
const hvigorPackageRoot = path.resolve(hvigorRoot, 'hvigor');
const hmosLoaderPath = path.resolve(hvigorRoot, 'hvigor-ohos-plugin/src/sdk/hmos-sdk-loader.js');
const platformSdksPath = path.resolve(
  hvigorRoot,
  'hvigor-ohos-plugin/node_modules/@ohos/hos-sdkmanager-common/build/src/hos/mapper/platform-sdks.js'
);

for (const requiredPath of [hvigorEntry, hmosLoaderPath, platformSdksPath, sdkRoot]) {
  if (!fs.existsSync(requiredPath)) {
    throw new Error(`Required DevEco component is missing: ${requiredPath}`);
  }
}

const extraNodePath = path.resolve(hvigorRoot, 'hvigor/node_modules');
process.env.NODE_PATH = process.env.NODE_PATH
  ? `${extraNodePath}${path.delimiter}${process.env.NODE_PATH}`
  : extraNodePath;
Module._initPaths();

const originalResolveFilename = Module._resolveFilename;
Module._resolveFilename = function (request, parent, isMain, options) {
  if (request === '@ohos/hvigor') {
    return originalResolveFilename.call(this, hvigorPackageRoot, parent, isMain, options);
  }
  if (request.startsWith('@ohos/hvigor/')) {
    return originalResolveFilename.call(
      this,
      path.join(hvigorPackageRoot, request.slice('@ohos/hvigor/'.length)),
      parent,
      isMain,
      options
    );
  }
  return originalResolveFilename.call(this, request, parent, isMain, options);
};

function apiVersion(value) {
  return { getMajor: () => value, getValue: () => value };
}

function component(name, location) {
  return {
    getPath: () => name,
    getLocation: () => location,
    getVersion: () => '6.1.1.125',
    getReleaseType: () => 'Release',
    getFullApiVersion: () => apiVersion(24)
  };
}

function patchHmosLoader(loader) {
  if (!loader || loader.__tabsshPatched) return;
  loader.prototype.checkComponentExistence = function () { return true; };
  loader.prototype.getHmosSdkComponents = async function (_version, names) {
    const result = new Map();
    names.forEach((name) => result.set(name, component(name, path.resolve(sdkRoot, 'openharmony', name))));
    return result;
  };
  loader.prototype.getHmsSdkComponents = async function (_version, names) {
    const result = new Map();
    names.forEach((name) => result.set(name, component(name, path.resolve(sdkRoot, 'hms', name))));
    return result;
  };
  loader.__tabsshPatched = true;
}

const originalLoad = Module._load;
Module._load = function (request, parent, isMain) {
  const loaded = originalLoad.call(this, request, parent, isMain);
  if (loaded && loaded.HmosSdkLoader) {
    patchHmosLoader(loaded.HmosSdkLoader);
  }
  return loaded;
};

const { PlatformSdks } = hvigorRequire(platformSdksPath);
if (Array.isArray(PlatformSdks._additional) && !PlatformSdks._additional.includes('js')) {
  PlatformSdks._additional = PlatformSdks._additional.concat('js');
}
const { HmosSdkLoader } = hvigorRequire(hmosLoaderPath);
patchHmosLoader(HmosSdkLoader);

const originalRead = fs.readFileSync.bind(fs);
fs.readFileSync = function (filePath, options) {
  try {
    return originalRead(filePath, options);
  } catch (error) {
    const normalized = typeof filePath === 'string' ? filePath.replace(/\\/g, '/').toLowerCase() : '';
    if (error && error.code === 'ENOENT' && normalized.includes('/toolchains/modulecheck/') && normalized.endsWith('.json')) {
      const fallback = '{}\n';
      const encoding = typeof options === 'string' ? options : options && options.encoding;
      return encoding ? fallback : Buffer.from(fallback);
    }
    throw error;
  }
};

const selfRequireFlag = `--require=${__filename}`;
if (!process.env.NODE_OPTIONS || !process.env.NODE_OPTIONS.includes(__filename)) {
  process.env.NODE_OPTIONS = process.env.NODE_OPTIONS
    ? `${selfRequireFlag} ${process.env.NODE_OPTIONS}`
    : selfRequireFlag;
}

if (require.main === module) {
  const tasks = process.argv.slice(2);
  process.argv = [
    process.argv[0],
    hvigorEntry,
    '--no-daemon',
    '--mode', 'module',
    '-p', 'product=default',
    '-p', 'module=entry@default',
    '-p', 'pageType=page',
    '-p', 'compileResInc=true',
    ...(tasks.length > 0 ? tasks : ['assembleHap'])
  ];
  hvigorRequire(hvigorEntry);
}
