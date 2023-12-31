(window["webpackJsonp"] = window["webpackJsonp"] || []).push([[4],{

/***/ 1574:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.KEY_MAPS = exports.CREATE_TABLE = exports.INLINE_CODE = exports.PRINT = exports.IMAGE_FULL_SCREEN = exports.ALIGN_IMAGE_CENTER = exports.ALIGN_IMAGE_LEFT = exports.ALIGN_IMAGE_RIGHT = exports.MINDMAP = exports.PPT = exports.COMMENT = exports.MENTION = exports.BACKCOLOR = exports.SHEET = exports.REDO = exports.UNDO = exports.INSERT_IMAGE = exports.CHECKBOX = exports.LINK = exports.INSERTSEPARATOR = exports.BLOCKQUOTE = exports.INSERTCODELIST = exports.INSERTUNORDEREDLIST = exports.INSERTORDEREDLIST = exports.ALIGNFULL = exports.ALIGNRIGHT = exports.ALIGNCENTER = exports.ALIGNLEFT = exports.STRIKETHROUGH = exports.UNDERLINE = exports.ITALIC = exports.BOLD = exports.HEADING = exports.H3 = exports.H2 = exports.H1 = exports.SHORTCUTS = exports.CREATE_SHEET = exports.CREATE_DOC = exports.GLOBAL_SEARCH = undefined;

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _KEY_MAPS;

exports.getHotKeyName = getHotKeyName;

var _isArray2 = __webpack_require__(44);

var _isArray3 = _interopRequireDefault(_isArray2);

var _pick2 = __webpack_require__(719);

var _pick3 = _interopRequireDefault(_pick2);

var _keys2 = __webpack_require__(138);

var _keys3 = _interopRequireDefault(_keys2);

var _forEach2 = __webpack_require__(239);

var _forEach3 = _interopRequireDefault(_forEach2);

var _bowser = __webpack_require__(382);

var _bowser2 = _interopRequireDefault(_bowser);

var _common = __webpack_require__(19);

var _keyCode = __webpack_require__(718);

var _keyCodeHelper = __webpack_require__(2200);

var _keyCodeHelper2 = _interopRequireDefault(_keyCodeHelper);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// 搜索: search_note, sute_header的搜索框用到
var GLOBAL_SEARCH = exports.GLOBAL_SEARCH = 'GLOBAL_SEARCH';
var CREATE_DOC = exports.CREATE_DOC = 'CREATE_DOC';
var CREATE_SHEET = exports.CREATE_SHEET = 'CREATE_SHEET';
var SHORTCUTS = exports.SHORTCUTS = 'SHORTCUTS';
var H1 = exports.H1 = 'h1';
var H2 = exports.H2 = 'h2';
var H3 = exports.H3 = 'h3';
var HEADING = exports.HEADING = 'heading';
var BOLD = exports.BOLD = 'bold';
var ITALIC = exports.ITALIC = 'italic';
var UNDERLINE = exports.UNDERLINE = 'underline';
var STRIKETHROUGH = exports.STRIKETHROUGH = 'strikethrough';
var ALIGNLEFT = exports.ALIGNLEFT = 'alignleft';
var ALIGNCENTER = exports.ALIGNCENTER = 'aligncenter';
var ALIGNRIGHT = exports.ALIGNRIGHT = 'alignright';
var ALIGNFULL = exports.ALIGNFULL = 'alignfull';
var INSERTORDEREDLIST = exports.INSERTORDEREDLIST = 'insertorderedlist';
var INSERTUNORDEREDLIST = exports.INSERTUNORDEREDLIST = 'insertunorderedlist';
var INSERTCODELIST = exports.INSERTCODELIST = 'insertcodelist';
var BLOCKQUOTE = exports.BLOCKQUOTE = 'blockquote';
var INSERTSEPARATOR = exports.INSERTSEPARATOR = 'insertseparator';
var LINK = exports.LINK = 'link';
var CHECKBOX = exports.CHECKBOX = 'checkbox';
var INSERT_IMAGE = exports.INSERT_IMAGE = 'insertimage';
var UNDO = exports.UNDO = 'undo';
var REDO = exports.REDO = 'redo';
var SHEET = exports.SHEET = 'sheet';
var BACKCOLOR = exports.BACKCOLOR = 'backcolor';
var MENTION = exports.MENTION = 'mention';
var COMMENT = exports.COMMENT = 'comment';
var PPT = exports.PPT = 'ppt';
var MINDMAP = exports.MINDMAP = 'mindmap';
var ALIGN_IMAGE_RIGHT = exports.ALIGN_IMAGE_RIGHT = 'alignimageright';
var ALIGN_IMAGE_LEFT = exports.ALIGN_IMAGE_LEFT = 'alignimageleft';
var ALIGN_IMAGE_CENTER = exports.ALIGN_IMAGE_CENTER = 'alignimagecenter';
var IMAGE_FULL_SCREEN = exports.IMAGE_FULL_SCREEN = 'imagefullscreen';
var PRINT = exports.PRINT = 'print';
var INLINE_CODE = exports.INLINE_CODE = 'inlinecode';
var CREATE_TABLE = exports.CREATE_TABLE = 'doInsertTable';

// 一定要配置windows的key 默认走windows
var KEY_MAPS = exports.KEY_MAPS = (_KEY_MAPS = {}, (0, _defineProperty3.default)(_KEY_MAPS, GLOBAL_SEARCH, {
  mac: {
    metaKey: true,
    shiftKey: true,
    keyCode: 70
  },
  windows: {
    ctrlKey: true,
    shiftKey: true,
    keyCode: 70
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, CREATE_DOC, {
  mac: {
    metaKey: true,
    altKey: true,
    code: 'KeyN' // 由于mac下chrome和firefox的keyCode不同，此处用code
  },
  windows: {
    altKey: true,
    ctrlKey: true,
    keyCode: 78
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, CREATE_SHEET, {
  mac: {
    metaKey: true,
    altKey: true,
    shiftKey: true,
    keyCode: 78
  },
  windows: {
    altKey: true,
    shiftKey: true,
    ctrlKey: true,
    keyCode: 78
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, SHORTCUTS, {
  mac: {
    metaKey: true,
    keyCode: 191
  },
  windows: {
    ctrlKey: true,
    keyCode: 191
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, H1, {
  mindmapDocsEnable: false,
  windows: {
    altKey: true,
    ctrlKey: true,
    keyCode: 49
  },
  mac: {
    altKey: true,
    metaKey: true,
    keyCode: 49
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, BACKCOLOR, {
  windows: {
    keyCode: 72,
    ctrlKey: true,
    altKey: true
  },
  mac: {
    keyCode: 72,
    metaKey: true,
    altKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, H2, {
  mindmapDocsEnable: false,
  windows: {
    altKey: true,
    ctrlKey: true,
    keyCode: 50
  },
  mac: {
    altKey: true,
    metaKey: true,
    keyCode: 50
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, H3, {
  mindmapDocsEnable: false,
  windows: {
    altKey: true,
    ctrlKey: true,
    keyCode: 51
  },
  mac: {
    altKey: true,
    metaKey: true,
    keyCode: 51
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, HEADING, {
  titleEnable: false
}), (0, _defineProperty3.default)(_KEY_MAPS, BOLD, {
  windows: {
    key: 'b',
    ctrlKey: true
  },
  mac: {
    metaKey: true,
    key: 'b'
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, ITALIC, {
  windows: {
    key: 'i',
    ctrlKey: true
  },
  mac: {
    key: 'i',
    metaKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, UNDERLINE, {
  windows: {
    key: 'u',
    ctrlKey: true
  },
  mac: {
    key: 'u',
    metaKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, STRIKETHROUGH, {
  windows: {
    key: 'x',
    ctrlKey: true,
    shiftKey: true
  },
  mac: {
    key: 'x',
    metaKey: true,
    shiftKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, ALIGNLEFT, {
  titleEnable: true,
  mentionEnable: true,
  windows: {
    key: 'l',
    ctrlKey: true,
    shiftKey: true
  },
  mac: {
    key: 'l',
    metaKey: true,
    shiftKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, ALIGNCENTER, {
  titleEnable: true,
  mentionEnable: true,
  windows: {
    key: 'e',
    ctrlKey: true,
    shiftKey: true
  },
  mac: {
    key: 'e',
    metaKey: true,
    shiftKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, ALIGNRIGHT, {
  titleEnable: true,
  mentionEnable: true,
  windows: {
    key: 'r',
    ctrlKey: true,
    shiftKey: true
  },
  mac: {
    key: 'r',
    metaKey: true,
    shiftKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, ALIGNFULL, {
  listEnable: false,
  windows: {
    ctrlKey: true,
    which: 'f',
    shiftKey: true
  },
  mac: {
    metaKey: true,
    which: 'f',
    shiftKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, INSERTORDEREDLIST, [{
  imageEnable: false,
  windows: {
    key: '7',
    ctrlKey: true,
    shiftKey: true
  },
  mac: {
    key: '7',
    metaKey: true,
    shiftKey: true
  }
}, {
  imageEnable: false,
  windows: {
    key: '&', // window下key会是&...保留7小键盘
    ctrlKey: true,
    shiftKey: true
  },
  mac: {
    key: '&',
    metaKey: true,
    shiftKey: true
  }
}]), (0, _defineProperty3.default)(_KEY_MAPS, INSERTUNORDEREDLIST, [{
  imageEnable: false,
  windows: {
    key: '8',
    ctrlKey: true,
    shiftKey: true
  },
  mac: {
    key: '8',
    metaKey: true,
    shiftKey: true
  }
}, {
  imageEnable: false,
  windows: {
    key: '*',
    ctrlKey: true,
    shiftKey: true
  },
  mac: {
    key: '*',
    metaKey: true,
    shiftKey: true
  }
}]), (0, _defineProperty3.default)(_KEY_MAPS, INSERTCODELIST, {
  imageEnable: false,
  windows: {
    altKey: true,
    ctrlKey: true,
    which: 'c'
  },
  mac: {
    metaKey: true,
    altKey: true,
    which: 'c'
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, BLOCKQUOTE, {
  windows: {
    keyCode: 190,
    shiftKey: true,
    ctrlKey: true
  },
  mac: {
    keyCode: 190,
    shiftKey: true,
    metaKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, INSERTSEPARATOR, {
  windows: {
    ctrlKey: true,
    which: 's', // s
    altKey: true
  },
  mac: {
    metaKey: true,
    which: 's', // s
    altKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, LINK, {
  titleEnable: true,
  windows: {
    ctrlKey: true,
    key: 'k'
  },
  mac: {
    metaKey: true,
    key: 'k'
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, CHECKBOX, {
  imageEnable: false,
  windows: {
    ctrlKey: true,
    which: 't', // t
    altKey: true
  },
  mac: {
    metaKey: true,
    which: 't', // t
    altKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, INSERT_IMAGE, {
  listEnable: false,
  windows: {
    ctrlKey: true,
    which: 'u',
    shiftKey: true
  },
  mac: {
    metaKey: true,
    which: 'u',
    shiftKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, IMAGE_FULL_SCREEN, {
  listEnable: false,
  windows: {
    ctrlKey: true,
    which: 'f',
    shiftKey: true
  },
  mac: {
    metaKey: true,
    which: 'f',
    shiftKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, UNDO, {
  titleEnable: true,
  mentionEnable: true,
  driveEnable: true,
  windows: {
    ctrlKey: true,
    which: 'z'
  },
  mac: {
    metaKey: true,
    which: 'z'
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, REDO, [{
  // 有两个快捷键
  titleEnable: true,
  mentionEnable: true,
  driveEnable: true,
  windows: {
    ctrlKey: true,
    which: 'z',
    shiftKey: true
  },
  mac: {
    metaKey: true,
    which: 'z',
    shiftKey: true
  }
}, {
  titleEnable: true,
  driveEnable: true,
  windows: {
    ctrlKey: true,
    which: 'y'
  },
  mac: {
    metaKey: true,
    which: 'y'
  }
}]), (0, _defineProperty3.default)(_KEY_MAPS, SHEET, {
  windows: {},
  mac: {},
  imageEnable: false
}), (0, _defineProperty3.default)(_KEY_MAPS, PPT, {
  windows: {
    keyCode: 116
  },
  mac: {
    metaKey: true,
    shiftKey: true,
    keyCode: 80
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, MINDMAP, {
  window: {
    keyCode: _keyCodeHelper2.default.F6
  },
  mac: {
    metaKey: true,
    shiftKey: true,
    keyCode: _keyCodeHelper2.default.J
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, PRINT, {
  windows: {
    ctrlKey: true,
    which: 'p'
  },
  mac: {
    metaKey: true,
    which: 'p'
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, INLINE_CODE, {
  windows: {
    ctrlKey: true,
    which: 'c',
    shiftKey: true
  },
  mac: {
    ctrlKey: true,
    which: 'c',
    metaKey: true
  }
}), (0, _defineProperty3.default)(_KEY_MAPS, CREATE_TABLE, {
  windows: {
    altKey: true,
    ctrlKey: true,
    keyCode: _keyCode.KeyCode.A
  },
  mac: {
    metaKey: true,
    altKey: true,
    keyCode: _keyCode.KeyCode.A
  }
}), _KEY_MAPS);

// 遍历 防止出现按四个键 三个键条件满足 而错误响应的情况
function getHotKeyName(e) {
  // TODO:通过遍历数组来获取的方式太低效了
  var platform = '';
  var conditionLen = 0; // 记录condition的len
  var ret = '';
  if (_bowser2.default.mac) {
    platform = 'mac';
  } else if (_bowser2.default.windows) {
    platform = 'windows';
  } else {
    return '';
  }

  var _loop = function _loop(name) {
    var thisKeyMap = KEY_MAPS[name];
    var thisKeyMapList = thisKeyMap;
    if (!(0, _isArray3.default)(thisKeyMap)) {
      // 将非多个keys 转成一个list
      thisKeyMapList = [thisKeyMap];
    }
    (0, _forEach3.default)(thisKeyMapList, function (hotKeys) {
      // 没有hot key 默认走windows的 包括linux 啥的
      var hotKey = hotKeys[platform] || hotKeys.windows;
      var keys = (0, _keys3.default)(hotKey);
      var eventKey = (0, _pick3.default)(e, keys);

      // 将which 转成字符串
      if (eventKey.which !== undefined) {
        eventKey.which = String.fromCharCode(eventKey.which).toLowerCase();
      }

      if (eventKey.key) {
        eventKey.key = eventKey.key.toLowerCase();
      }

      // 浅层数据 JSON.stringify 比_isEqual快很多
      if (JSON.stringify(hotKey) === JSON.stringify(eventKey)) {
        if (keys.length > conditionLen) {
          ret = name;
          conditionLen = keys.length;
        }
      }
    });
  };

  for (var name in KEY_MAPS) {
    _loop(name);
  }

  if (ret === CREATE_SHEET && !_common.CAN_CREATE_SHEET) {
    return null;
  }

  return ret;
}

/***/ }),

/***/ 1577:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _tea = __webpack_require__(47);

var _teaHelper = __webpack_require__(242);

var _constants = __webpack_require__(1579);

function sendCollector(action, op, source, eventType, target, operationtype) {
  var cursor = getSelection().type === 'Caret';
  var _target = window.getSelection().anchorNode || target;
  (0, _tea.collectSuiteEvent)('toggle_attribute', {
    action: action,
    operationtype: operationtype || 'toolbar',
    // 移动端不存在 “快捷键操作” ，因此默认值由 “shortkey” 改为 “editorbar” 。
    source: source || 'editorbar',
    eventType: eventType || 'keydown',
    attr_op_status: op || _constants.OP_ADD,
    targetId: _target && _target.id || '',
    targetClass: _target && _target.className || '',
    is_cursor: cursor.toString(),
    target: target,
    zone: (0, _teaHelper.getZone)()
  });
}

exports.default = sendCollector;

/***/ }),

/***/ 1579:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _bytedXBlock = __webpack_require__(1582);

Object.defineProperty(exports, 'BLOCK_V_TEXT', {
  enumerable: true,
  get: function get() {
    return _bytedXBlock.BLOCK_V_TEXT;
  }
});
Object.defineProperty(exports, 'BLOCK_CONTAINER', {
  enumerable: true,
  get: function get() {
    return _bytedXBlock.BLOCK_CONTAINER;
  }
});
Object.defineProperty(exports, 'BLOCK_PLACEHOLDER', {
  enumerable: true,
  get: function get() {
    return _bytedXBlock.BLOCK_PLACEHOLDER;
  }
});
var OP_ADD = exports.OP_ADD = 'effective';
var OP_DELETE = exports.OP_DELETE = 'cancel';
var DOC_ID = exports.DOC_ID = '__DOC__';

/***/ }),

/***/ 1581:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.JOIN_CHAT_ERROR_MSG = exports.SEARCH_ERROR_MSG = exports.BLACK_LIST_IN_TABLE = exports.GUIDE_TYPE = exports.AUTHORIZE_DELAY = exports.NOTIFY_DELAY = exports.DRIVE_TYPE = exports.SUCCESS_RESPONSE_CODE = exports.NATIVE_COMMENT_STATUS = exports.AT_POSITION = exports.AT_HOLDER_DOM = exports.LARK_CHAT_SCHEMA = exports.HOLD_WHEN_REPLACE = exports.CHAT_JOIN_STATUS = exports.CAN_SELECTED_ASIDE_INDEX = exports.MENTION_ASIDE = exports.NOTIFICATION_WHITE_LIST = exports.INIT_TYPES = exports.DOM_POSITION = exports.AT_HOLDER_PREFIX = exports.TARGET_ENUM = exports.SOURCE_ENUM = exports.TYPE_ENUM = exports.KEYS = undefined;

var _userHelper = __webpack_require__(61);

var _bytedXBlock = __webpack_require__(1582);

// 按键
var KEYS = exports.KEYS = {
  RETURN: 13,
  LEFT: 37,
  UP: 38,
  RIGHT: 39,
  DOWN: 40,
  SPACE: 32,
  ESC: 27,
  BACKSPACE: 8,
  TAB: 9,
  AT: 50,
  DELETE: 46,
  FAKE_CODE: 229
};
var TYPE_ENUM = exports.TYPE_ENUM = {
  USER: 0, // 用户
  FILE: 1, // 文档
  FOLDER: 2, // 文档路径
  SHEET: 3, // sheet
  SHEET_DOC: 4, // sheet + docs
  CHAT: 5, // 群卡片
  GROUP: 6, // 群
  BLOCK: 7
}; // 从哪里发起的@

var SOURCE_ENUM = exports.SOURCE_ENUM = {
  DOC: 0, // 文档中
  DOC_COMMENT: 1, // 评论中
  SHEET: 2, // sheet中
  SHEET_COMMENT: 3 // sheet的评论中
};

var TARGET_ENUM = exports.TARGET_ENUM = {
  LARK: 0
};
var AT_HOLDER_PREFIX = exports.AT_HOLDER_PREFIX = 'at-uuid_'; // 两个dom的相对位置关系

var DOM_POSITION = exports.DOM_POSITION = {
  PREV: 4,
  AFTER: 2
};

var INIT_TYPES = exports.INIT_TYPES = {
  NOT_SELECTABLE_TYPE: 'no-select',
  USER: 'USER',
  SHEET_DOC: 'SHEET_DOC',
  ALL: 'USER-SHEET_DOC',
  CHAT: 'CHAT',
  GROUP: 'GROUP',
  USER_GROUP: 'USER-GROUP',
  DRIVE: 'DRIVE',
  UPLOAD: 'UPLOAD',

  UPLOADER_FILE: 'UPLOADER_FILE',
  REACTION_BLOCK: 'REACTION_BLOCK',
  INSERT_SHEET: 'INSERT_SHEET',
  INSERT_TABLE: 'INSERT_TABLE',
  POLL_BLOCK: _bytedXBlock.BlockType.POLL_BLOCK,
  IFRAME_BLOCK: 'IFRAME_BLOCK'
};

var NOTIFICATION_WHITE_LIST = exports.NOTIFICATION_WHITE_LIST = {
  ASIDE: [INIT_TYPES.USER, INIT_TYPES.SHEET_DOC, INIT_TYPES.ALL, INIT_TYPES.GROUP, INIT_TYPES.CHAT, INIT_TYPES.USER_GROUP],
  TYPE: [TYPE_ENUM.USER, TYPE_ENUM.GROUP]
};

// 宽度
var NORMAL_WRAPPER_SIZE = 424;
var SMALL_WRAPPER_SIZE = 313;
var DEFAULT_ASIDE_SIZE = 116;

// mention 类型
var ASIDE_MENTION_TYPES = [{
  type: INIT_TYPES.ALL,
  content: t('doc.search.filter.all'),
  boxSize: NORMAL_WRAPPER_SIZE,
  asideSize: DEFAULT_ASIDE_SIZE
}, {
  type: INIT_TYPES.SHEET_DOC,
  content: t('common.doc'),
  boxSize: NORMAL_WRAPPER_SIZE,
  asideSize: DEFAULT_ASIDE_SIZE
}, {
  type: INIT_TYPES.USER,
  content: t('common.people'),
  boxSize: NORMAL_WRAPPER_SIZE,
  asideSize: DEFAULT_ASIDE_SIZE
}];
// insert 类型
var ASIDE_INSERT_TYPES = [{
  type: INIT_TYPES.CHAT,
  content: t('etherpad.lark.group.card'),
  boxSize: NORMAL_WRAPPER_SIZE,
  asideSize: DEFAULT_ASIDE_SIZE
}, {
  type: INIT_TYPES.INSERT_TABLE,
  content: t('common.table'),
  boxSize: SMALL_WRAPPER_SIZE,
  asideSize: DEFAULT_ASIDE_SIZE,
  noList: true // 非列表结构
}, {
  type: INIT_TYPES.INSERT_SHEET,
  content: t('common.sheet'),
  boxSize: SMALL_WRAPPER_SIZE,
  asideSize: DEFAULT_ASIDE_SIZE,
  noList: true // 非列表结构
  // }, {
  //   type: INIT_TYPES.POLL_BLOCK,
  //   content: t('block.poll'),
  //   boxSize: NORMAL_WRAPPER_SIZE,
  //   asideSize: DEFAULT_ASIDE_SIZE,
  //   noList: true,
  //   noRequest: true,
  // }, {
  //   type: INIT_TYPES.REACTION_BLOCK,
  //   content: t('etherpad.reaction'),
  //   boxSize: NORMAL_WRAPPER_SIZE,
  //   asideSize: DEFAULT_ASIDE_SIZE,
  //   noList: true,
  //   noRequest: true,
}, {
  type: INIT_TYPES.POLL_BLOCK,
  content: t('block.poll'),
  boxSize: NORMAL_WRAPPER_SIZE,
  asideSize: DEFAULT_ASIDE_SIZE,
  noList: true,
  noRequest: true,
  isAlpha: true
  // }, {
  //   type: INIT_TYPES.REACTION_BLOCK,
  //   content: t('etherpad.reaction'),
  //   boxSize: NORMAL_WRAPPER_SIZE,
  //   asideSize: DEFAULT_ASIDE_SIZE,
  //   noList: true,
  //   noRequest: true,
}, {
  type: INIT_TYPES.IFRAME_BLOCK,
  content: t('block.iframe_add_embeds'),
  boxSize: NORMAL_WRAPPER_SIZE,
  asideSize: DEFAULT_ASIDE_SIZE,
  noList: true,
  noRequest: true
}];
// 多租户设置, byteUser才展示drive入口
if (_userHelper.isBytedanceUser) {
  ASIDE_INSERT_TYPES.unshift({
    type: INIT_TYPES.DRIVE,
    content: t('etherpad.Drive'),
    boxSize: NORMAL_WRAPPER_SIZE,
    asideSize: DEFAULT_ASIDE_SIZE
  });
}
var MENTION_ASIDE = exports.MENTION_ASIDE = [{
  type: INIT_TYPES.NOT_SELECTABLE_TYPE,
  content: t('etherpad.memtioned')
}].concat(ASIDE_MENTION_TYPES, [{
  type: INIT_TYPES.NOT_SELECTABLE_TYPE,
  content: t('etherpad.insert')
}], ASIDE_INSERT_TYPES);

var CAN_SELECTED_ASIDE_INDEX = exports.CAN_SELECTED_ASIDE_INDEX = [];
MENTION_ASIDE.forEach(function (aside, index) {
  aside.type !== INIT_TYPES.NOT_SELECTABLE_TYPE && CAN_SELECTED_ASIDE_INDEX.push(index);
});

var CHAT_JOIN_STATUS = exports.CHAT_JOIN_STATUS = {
  joined: t('etherpad.initiate_conversation'),
  unjoined: t('etherpad.join_group_chat')
};
var HOLD_WHEN_REPLACE = exports.HOLD_WHEN_REPLACE = 'hold-when-replace'; // line替换的时候保持改内容不被替换

var LARK_CHAT_SCHEMA = exports.LARK_CHAT_SCHEMA = 'lark://client/chat/';

var AT_HOLDER_DOM = exports.AT_HOLDER_DOM = 1;
var AT_POSITION = exports.AT_POSITION = {
  DOC: 0,
  COMMENT: 1,
  WHOLE_COMMENT: 2
};

var NATIVE_COMMENT_STATUS = exports.NATIVE_COMMENT_STATUS = {
  HIDE: 0,
  SHOW: 1
};

var SUCCESS_RESPONSE_CODE = exports.SUCCESS_RESPONSE_CODE = 0;
var DRIVE_TYPE = exports.DRIVE_TYPE = 'DRIVE';

var NOTIFY_DELAY = exports.NOTIFY_DELAY = 5000;
var AUTHORIZE_DELAY = exports.AUTHORIZE_DELAY = 8000;
var GUIDE_TYPE = exports.GUIDE_TYPE = {
  MENTION_BOX: 'mention_box',
  MENTION_USER: 'mention_user',
  MENTION_GROUP: 'mention_group',
  MENTION_INSERT_SHEET: 'mention_insert_sheet',
  MENTION_SHEET_DOC: 'mention_sheet_doc',
  MENTION_CHAT: 'mention_chat',
  MENTION_FILE: 'mention_file'
};

var BLACK_LIST_IN_TABLE = exports.BLACK_LIST_IN_TABLE = [INIT_TYPES.INSERT_TABLE, INIT_TYPES.INSERT_SHEET];

var SEARCH_ERROR_MSG = exports.SEARCH_ERROR_MSG = {
  '1': t('etherpad.server_abnormal'),
  '2': t('error.args_error'),
  '3': t('error.object_not_found'),
  '4': t('error.no_permission'),
  '5': t('warn.login_required_tips'),
  '6': t('error.request_timeout')
};

var JOIN_CHAT_ERROR_MSG = exports.JOIN_CHAT_ERROR_MSG = {
  '4013': t('etherpad.join_group_failed_limited'),
  '4014': t('etherpad.join_group_failed_invitation'),
  '4015': t('etherpad.join_group_failed_forbidden'),
  '4017': t('etherpad.join_group_failed_organization'),
  '4018': t('etherpad.join_group_failed_dissolved'),
  '4019': t('etherpad.join_group_failed_no_found')
};
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1590:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.defaultOptions = undefined;
exports.getPosition = getPosition;
exports.isFakeTextNode = isFakeTextNode;
exports.getFakeTextNodeFromFocus = getFakeTextNodeFromFocus;
exports.getPrevMentionFromFocus = getPrevMentionFromFocus;
exports.getNextMentionFromFocus = getNextMentionFromFocus;
exports.isMentionNode = isMentionNode;
exports.genUUID = genUUID;
exports.getValByName = getValByName;
exports.autoCompleteMentionSelection = autoCompleteMentionSelection;
exports.setCursor = setCursor;
exports.getSelection = getSelection;
exports.getStyle = getStyle;
exports.getJoinedText = getJoinedText;
exports.renderMentionChat = renderMentionChat;
exports.getCharsHeight = getCharsHeight;
exports.getSubContent = getSubContent;
exports.getFilter = getFilter;
exports.getMentionType = getMentionType;
exports.fixUrl = fixUrl;
exports.fixAvatarUrl = fixAvatarUrl;
exports.getExtendedAttribs = getExtendedAttribs;
exports.getMentionInfoFromAttribs = getMentionInfoFromAttribs;
exports.getPageToken = getPageToken;
exports.humanFileSize = humanFileSize;
exports.getFileTypeByFileName = getFileTypeByFileName;
exports.nodeValueCheck = nodeValueCheck;
exports.prevWordIsAt = prevWordIsAt;
exports.prevTextIsWordsOrNumber = prevTextIsWordsOrNumber;
exports.isRange = isRange;
exports.isCaret = isCaret;
exports.onUserPopoverAlign = onUserPopoverAlign;
exports.closeMentionBoxGuide = closeMentionBoxGuide;
exports.getSourceData = getSourceData;
exports.getSourceString = getSourceString;
exports.getSourceFormString = getSourceFormString;
exports.sendHoverTeaLog = sendHoverTeaLog;
exports.getMentionRecommendSource = getMentionRecommendSource;
exports.extraMentionInfoFromMentionClassName = extraMentionInfoFromMentionClassName;

var _$rjquery = __webpack_require__(499);

var _$store = __webpack_require__(83);

var _$store2 = _interopRequireDefault(_$store);

var _get2 = __webpack_require__(81);

var _get3 = _interopRequireDefault(_get2);

var _$constants = __webpack_require__(4);

var _onboarding = __webpack_require__(109);

var _string = __webpack_require__(158);

var _assign2 = __webpack_require__(506);

var _assign3 = _interopRequireDefault(_assign2);

var _filter2 = __webpack_require__(507);

var _filter3 = _interopRequireDefault(_filter2);

var _const = __webpack_require__(1581);

var _security = __webpack_require__(1616);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _dateHelper = __webpack_require__(515);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _guide = __webpack_require__(514);

var _common = __webpack_require__(70);

var _guide2 = __webpack_require__(244);

var _encryption = __webpack_require__(185);

var _tea = __webpack_require__(47);

var _tea2 = _interopRequireDefault(_tea);

var _suiteHelper = __webpack_require__(60);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var IGNORE_SPACE = 'data-contentcollector-ignore-space-at';

var defaultOptions = exports.defaultOptions = { horizontalAlign: 'left', boxWidth: 540, boxMaxHeight: 390, boxMinHeight: 350 };
/**
 *  计算一个盒子相对于一个dom的位置
 * @param {*} atDom 参考的dom的位置
 * @param {*} options
 *  {
 *    horizontalAlign, // 相对于atDom水平位置  left || center
 *    boxWidth, // 盒子的宽度
 *    boxMaxHeight // 盒子的最大高度
 *    boxMinHeight //
 *    mouseX // 鼠标的X坐标
 *    mouseY // 鼠标的Y坐标
 *  }
 */
function getPosition(atDom, options) {
  if (!atDom) {
    return;
  }

  var $atDom = (0, _$rjquery.$)(atDom);
  options = (0, _assign3.default)({}, defaultOptions, options);
  var _options = options,
      horizontalAlign = _options.horizontalAlign,
      boxWidth = _options.boxWidth,
      boxMaxHeight = _options.boxMaxHeight,
      boxMinHeight = _options.boxMinHeight,
      _options$upFirst = _options.upFirst,
      upFirst = _options$upFirst === undefined ? false : _options$upFirst,
      mouseY = _options.mouseY;
  var _options2 = options,
      _options2$$boxContain = _options2.$boxContainer,
      $boxContainer = _options2$$boxContain === undefined ? (0, _$rjquery.$)('.doc-position') : _options2$$boxContain;

  if (!$boxContainer.length) {
    $boxContainer = $atDom.closest('.innerdocbody').parent();
  }
  var relativeOffset = $boxContainer.offset(); // 左上角定位基准点的位置
  var containerHeight = $boxContainer.outerHeight();
  var etherpadContainer = (0, _$rjquery.$)('.etherpad-container').get(0);
  var EDIT_BAR_HEIGHT = (0, _$rjquery.$)('#editbar').height();
  var NAV_BAR_HEIGHT = (0, _$rjquery.$)('.navigation-bar-wrapper').height();
  var etherpadMaxLeft = 10000;
  if (etherpadContainer) {
    var style = getComputedStyle(etherpadContainer);
    etherpadMaxLeft = parseInt(style['padding-left']) + parseInt(style['margin-left']);
  }

  // 当前需要弹出盒子的位置
  var rect = getRect($atDom.get(0), mouseY);
  if (!rect) {
    return;
  }

  var _window = window,
      innerWidth = _window.innerWidth,
      innerHeight = _window.innerHeight;

  var lineHeight = parseInt(getComputedStyle($atDom.get(0))['line-height']) || 18;
  var atDomWidth = rect.width;
  var atDomHeight = rect.height;
  var atDomTop = rect.top,
      atDomLeft = rect.left;
  var relativeTop = relativeOffset.top,
      relativeLeft = relativeOffset.left;


  var top = atDomTop + lineHeight - relativeTop;
  var bottom = void 0,
      height = void 0;
  var bottomRemain = innerHeight - atDomTop - atDomHeight; // 下面剩余空间
  var topRemain = atDomTop - EDIT_BAR_HEIGHT - NAV_BAR_HEIGHT;
  var rightRemain = innerWidth - atDomLeft - (horizontalAlign === 'center' ? atDomWidth / 2 : atDomWidth);

  var left = void 0;
  if (horizontalAlign === 'left') {
    left = atDomLeft + atDomWidth - relativeLeft;
    // 右边剩下的位置不足够放下box 朝左边偏一个boxWidth的距离
    if (rightRemain < boxWidth) {
      left -= boxWidth;
    }
  } else if (horizontalAlign === 'center') {
    left = atDomLeft + atDomWidth / 2 - boxWidth / 2 - relativeLeft;
    left = Math.max(left, -relativeLeft);
    if (rightRemain < boxWidth / 2) {
      left -= rightRemain;
    }
  }

  // 防止hover@ 人被最近访问遮挡
  if (left < -etherpadMaxLeft) {
    if (innerWidth > boxWidth) {
      left = atDomLeft + atDomWidth - relativeLeft - (boxWidth - rightRemain);
    } else {
      left = -etherpadMaxLeft;
    }
  }

  // 优先朝上
  if (upFirst) {
    bottom = -atDomTop + relativeTop + containerHeight;
    top = undefined;

    // 上面不够 下面够 朝下
    if (topRemain < boxMaxHeight && bottomRemain > boxMaxHeight) {
      bottom = undefined;
      top = atDomTop + lineHeight - relativeTop;
    }
  } else {
    // 下面不够 上面够 朝上
    if (topRemain > boxMaxHeight && bottomRemain < boxMaxHeight) {
      bottom = -atDomTop + relativeTop + containerHeight;
      top = undefined;
    }
  }

  // 两边都不够
  if (bottomRemain < boxMaxHeight && topRemain < boxMaxHeight) {
    if (topRemain > boxMinHeight) {
      // 上面剩余仍然大于boxMinHeight
      bottom = -atDomTop + relativeTop + containerHeight;
      height = topRemain;
      top = undefined;
    } else {
      // 上面剩余高度小于下面高度
      height = Math.max(bottomRemain - 10, boxMinHeight);
    }
  }

  if (boxMaxHeight === boxMinHeight) {
    height = boxMaxHeight;
  }

  return {
    left: left,
    bottom: bottom,
    top: top,
    height: height
  };
}

// 获取鼠标真正指向的rect，用于处理一个span被段成多行的情况
function getRect(dom, y) {
  if (!dom.getClientRects) {
    return dom.getBoundingClientRect();
  }

  var rects = dom.getClientRects();
  if (rects.length === 1) {
    return rects[0];
  }
  if (!y) {
    return rects[rects.length - 1];
  }

  for (var i = 0; i < rects.length; i++) {
    var rect = rects[i];
    var top = rect.top;
    var bottom = rect.top + rect.height;
    if (y >= top && y <= bottom) {
      return rect;
    }
  }
}

function isFakeTextNode(node) {
  return node.getAttribute(IGNORE_SPACE);
}
function getFakeTextNodeFromFocus() {
  var sel = getSelection();
  var focusNode = sel.focusNode;
  // 鼠标聚焦到不可选择的元素，比如在safari中选中user-select:none的文件卡片

  if (!focusNode) return null;
  var focusParentNode = focusNode.parentNode;
  var node = focusNode;
  if (focusNode.nodeType === 3 && focusParentNode) {
    node = focusParentNode;
  }
  if (isFakeTextNode(node)) {
    return node;
  }
  return null;
}

/**
 *
 * @param direct
 * @param closely 是否要求是紧密挨着前一个mention 默认为true
 * @returns {Array}
 */
function getMentionFromFocus($focus, focusOffset, direct) {
  var closely = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : true;

  var $mention = [];
  var sel = getSelection();

  if ($focus) {
    while ($focus.length && !/magicdomid/.test($focus.attr('id'))) {
      var text = $focus.text();
      // focusOffset 如果为0 这种情况直接focus到了mention的前面 如果是prev 不应该返回后面那个mention
      var isCloselyNext = focusOffset === 0 && direct === 'next';
      if ($focus.hasClass('mention') && (isCloselyNext || focusOffset !== 0)) {
        return $focus;
      }

      // 是否紧密的focus到了前面那个mention
      if (direct === 'prev') {
        var isFocusCloselyOnMention = focusOffset === 0 && isCaret(sel);
        if ($focus.prev().hasClass('mention') && (isFocusCloselyOnMention || !closely)) {
          $mention = $focus.prev();
          break;
        }
      } else {
        var _isFocusCloselyOnMention = focusOffset === text.length || focusOffset === 1 && text.slice(-1) === ' ';
        if ($focus.next().hasClass('mention') && (_isFocusCloselyOnMention || !closely)) {
          $mention = $focus.next();
          break;
        }
      }
      $focus = $focus.parent();
    }
  }
  return $mention;
}

function getPrevMentionFromFocus(closely) {
  var sel = getSelection();
  var ret = [];
  var baseNode = sel.baseNode,
      baseOffset = sel.baseOffset,
      focusNode = sel.focusNode,
      focusOffset = sel.focusOffset;

  var fakeNode = getFakeTextNodeFromFocus();
  var node = focusNode;
  var offset = focusOffset;
  if (fakeNode) {
    node = fakeNode;
    offset = 0;
  }
  var end = getMentionFromFocus((0, _$rjquery.$)(node), offset, 'prev', closely);
  if (isRange(sel)) {
    var start = getMentionFromFocus((0, _$rjquery.$)(baseNode), baseOffset, 'prev', closely);
    if (start.length) {
      ret.push(start.get(0));
    }
  }
  if (end.length) {
    ret.push(end.get(0));
  }

  // 对ret按照文档中的顺序排序
  if (ret.length) {
    ret.sort(function (a, b) {
      if (a.compareDocumentPosition(b) === _const.DOM_POSITION.PREV) {
        return -1;
      }
      return 1;
    });
  }

  return (0, _$rjquery.$)(ret);
}

function getNextMentionFromFocus(closely) {
  var sel = getSelection();
  var focusNode = sel.focusNode,
      focusOffset = sel.focusOffset;

  var fakeNode = getFakeTextNodeFromFocus();
  var node = focusNode;
  var offset = focusOffset;
  if (fakeNode) {
    node = fakeNode;
    offset = 1;
  }
  return getMentionFromFocus((0, _$rjquery.$)(node), offset, 'next', closely);
}

function isMentionNode(node) {
  var $span = (0, _$rjquery.$)(node).parents('span');
  if ($span.text() === (0, _$rjquery.$)(node).text() && /mention-type/.test($span.attr('class'))) {
    return true;
  }
  return false;
}

var uui = 0;
function genUUID() {
  uui++;
  return (0, _string.generateRandomString)(12) + '-' + uui;
}

function getValByName(str, name) {
  var reg = new RegExp(name + '_([^\\s]+)');
  return (0, _get3.default)(str.match(reg), '[1]') || '';
}

var USER = _const.TYPE_ENUM.USER,
    FILE = _const.TYPE_ENUM.FILE,
    FOLDER = _const.TYPE_ENUM.FOLDER,
    SHEET = _const.TYPE_ENUM.SHEET,
    SHEET_DOC = _const.TYPE_ENUM.SHEET_DOC;

var AUTO_COMPLETE_MENTION_ATTRS = [USER, FILE, FOLDER, SHEET, SHEET_DOC].map(function (type) {
  return { attr: 'mention-type_' + type, value: 'true' };
});
function autoCompleteMentionSelection(editorInfo, _ref) {
  var documentAttributeManager = _ref.documentAttributeManager,
      newRep = _ref.newRep;

  if (editorInfo.selection.isCaret(newRep)) return;

  var selStart = newRep.selStart,
      selEnd = newRep.selEnd,
      selFocusAtStart = newRep.selFocusAtStart;

  var newSelStart = selStart;
  var newSelEnd = selEnd;
  var autoComplete = false;

  var mentionAttrs = AUTO_COMPLETE_MENTION_ATTRS;
  var selectSameLine = selStart[0] === selEnd[0];
  var startLine = selStart[0];
  var startMentions = documentAttributeManager.getAttributesPoints(mentionAttrs, startLine, startLine + 1);

  startMentions.forEach(function (_ref2) {
    var selStart = _ref2.selStart,
        selEnd = _ref2.selEnd;

    var afterMentionStart = selStart[1] < newSelStart[1] && selEnd[1] > newSelStart[1];
    if (afterMentionStart) {
      newSelStart = selStart;
      autoComplete = true;
    }

    var beforeMentionEnd = selEnd[1] > newSelEnd[1] && selStart[1] < newSelEnd[1];
    if (selectSameLine && beforeMentionEnd) {
      newSelEnd = selEnd;
      autoComplete = true;
    }
  });

  if (!selectSameLine) {
    var endLine = selEnd[0];
    var endMentions = documentAttributeManager.getAttributesPoints(mentionAttrs, endLine, endLine + 1);
    endMentions.forEach(function (_ref3) {
      var selStart = _ref3.selStart,
          selEnd = _ref3.selEnd;

      var beforeMentionEnd = selEnd[1] > newSelEnd[1] && selStart[1] < newSelEnd[1];
      if (beforeMentionEnd) {
        newSelEnd = selEnd;
        autoComplete = true;
      }
    });
  }

  if (autoComplete) {
    newRep.selStart = newSelStart;
    newRep.selEnd = newSelEnd;

    // 只改变 selStart, 聚焦selStart, 只改变 selEnd，聚焦selEnd, 两个都改变，方向不变
    var startChanged = newSelStart !== selStart;
    var endChanged = newSelEnd !== selEnd;

    var newSelFocusAtStart = void 0;
    if (startChanged && endChanged) {
      newSelFocusAtStart = selFocusAtStart;
    } else if (startChanged) {
      newSelFocusAtStart = true;
    } else {
      newSelFocusAtStart = false;
    }

    newRep.selFocusAtStart = newSelFocusAtStart;
  }
}

/**
 *
 * @param textDom
 * @param pos 位置 start || end
 */
function setCursor(textDom, pos) {
  if (textDom.nodeType === 3) {
    var selection = getSelection();
    var range = document.createRange();
    var len = 0;
    if (pos === 'end') {
      len = textDom.textContent.length;
    }
    range.setStart(textDom, len);
    range.setEnd(textDom, len);
    if (selection.rangeCount > 0) {
      selection.removeAllRanges();
    }
    selection.addRange(range);
  }
}

function getSelection() {
  if (window.getSelection) {
    return window.getSelection();
  }
  return {};
}

function getStyle(position) {
  var left = position.left,
      top = position.top,
      bottom = position.bottom,
      height = position.height;

  var style = {
    left: left,
    height: height
  };
  if (bottom !== undefined) {
    style.bottom = bottom;
  } else {
    style.top = top;
  }

  return style;
}

function getJoinedText() {
  return _const.CHAT_JOIN_STATUS.joined;
}

function renderMentionChat() {
  var data = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
  var _data$url = data.url,
      url = _data$url === undefined ? '' : _data$url,
      _data$buttonText = data.buttonText,
      buttonText = _data$buttonText === undefined ? '' : _data$buttonText,
      _data$content = data.content,
      content = _data$content === undefined ? '' : _data$content,
      _data$desc = data.desc,
      desc = _data$desc === undefined ? '' : _data$desc,
      joinConfirm = data.joinConfirm,
      chatId = data.chatId,
      notAllowedJoin = data.notAllowedJoin;

  var buttonHTML = '';
  var titCls = 'mention-chat-tit';
  var descHTML = '';
  var cardMainHTML = '';

  if (joinConfirm) {
    buttonHTML = '<div class="layout-row mention-chat-button-opt layout-cross-center" ><button\n      class="button-cancel">' + t('common.cancel') + '</button><button\n      class="button-confirm">' + t('common.confirm') + '</button></div>';
  } else {
    var isJoined = buttonText === getJoinedText();
    // mobile 不支持open lark
    var cls = (0, _classnames2.default)('mention-chat-button no-ace-listen', {
      'js-open-lark': isJoined,
      'open-lark': isJoined
    });
    // 在这里加入onClick原因: IOS下编辑状态无法触发JS绑定的click事情
    buttonHTML = '<div data-id="' + chatId + '" class="' + cls + '" onclick="(function handleOpenLark(e){\n      if (' + !isJoined + ') return;\n      if (' + _browserHelper2.default.isIE + ') return;\n      e.stopPropagation();\n      var openLarkEvent = document.createEvent(\'Event\');\n      openLarkEvent.initEvent(\'openLark\',true,true);\n      dispatchEvent(openLarkEvent);\n    }).apply(this, arguments)">' + buttonText + '</div>';
  }

  if (desc) {
    titCls += ' mt12';
    descHTML = '<div class="mention-chat-desc">' + (0, _security.escapeHTML)(desc) + '</div>';
  }

  if (notAllowedJoin) {
    cardMainHTML = '<div class="mention-chat-ct layout-column layout-main-center flex">\n    <div class="' + titCls + '" >' + t('mention.chat_notallowed_join') + '</div></div>';
  } else {
    cardMainHTML = '<div class="mention-chat-ct layout-column layout-main-center flex">\n    <div class="' + titCls + '" >' + (0, _security.escapeHTML)(content) + '</div>\n    ' + descHTML + '\n    </div>\n    ' + buttonHTML;
  }

  return ('<div class="layout-row layout-cross-center mention-chat ignore-collect hold-when-replace" contenteditable="false"\n    ' + (_browserHelper2.default.isEdge ? 'tabindex="-1"' : '') + '>\n        <span class="mention-chat-icon">\n          <img src="' + fixUrl(url) + '" />\n        </span>\n        ' + cardMainHTML + '\n    </div>').replace(/>[\n\s]+</g, '><') // 去掉html里面多余的字符串
  ;
}

var fontFamily = '';
// todo 防止xss
function getCharsHeight(content) {
  if (!fontFamily) fontFamily = getComputedStyle(document.body)['font-family'];
  var $p = (0, _$rjquery.$)('<p>' + (0, _security.escapeHTML)(content) + '</p>');
  $p.css({
    fontSize: 14,
    fontFamily: fontFamily,
    lineHeight: '20px',
    width: 204,
    position: 'absolute',
    left: -10000,
    'word-break': 'break-all'
  });
  (0, _$rjquery.$)('body').append($p);
  var height = $p.height();
  $p.remove();
  return height;
}

function getSubContent(info) {
  if (!info) return '';
  var type = info.type,
      desc = info.desc,
      department = info.department,
      edit_time = info.edit_time;

  var subContent = department;
  var CHAT = _const.TYPE_ENUM.CHAT,
      SHEET = _const.TYPE_ENUM.SHEET,
      FILE = _const.TYPE_ENUM.FILE,
      GROUP = _const.TYPE_ENUM.GROUP;


  if (type === SHEET || type === FILE) {
    subContent = t('mention.last_update') + (0, _dateHelper.forcePastShowDate)(edit_time);
  }

  if (type === CHAT || type === GROUP) {
    subContent = desc || t('mention.no_desc_tips');
  }
  return subContent;
}

function getFilter() {
  var len = arguments.length;
  var i = 0;
  var filter = '';
  while (i < len) {
    filter += arguments.length <= i ? undefined : arguments[i];
    if (i !== len - 1) {
      filter += ',';
    }
    i++;
  }
  return filter;
}

function getMentionType(typeNum) {
  for (var key in _const.TYPE_ENUM) {
    if (_const.TYPE_ENUM[key] === typeNum) {
      return key.toLowerCase();
    }
  }
}

function fixUrl(url) {
  if (url) return url.replace(/^https?:/, '');
  return url;
}

function fixAvatarUrl(url) {
  if (url) {
    return url.replace(/~([^\\.]+)/, '~cs_560x400');
  }
  return '';
}

function getExtendedAttribs(editorInfo) {
  var extendAttribs = (0, _get3.default)(editorInfo.ace_getAttributesOnSelection(), 'attribs') || [];
  extendAttribs = (0, _filter3.default)(extendAttribs, function (item) {
    var key = item[0];
    return ['backcolor', 'bold', 'italic', 'underline', 'strikethrough'].indexOf(key) > -1;
  }); // 将所有其他的属性 如行属性author等内容剔除掉
  return extendAttribs;
}

function getMentionInfoFromAttribs(attribArr, apool) {
  var numToAttrib = apool.numToAttrib;

  var info = {};
  for (var i = 0, len = attribArr.length; i < len; i++) {
    var num = parseInt(attribArr[i], 36);
    var attr = numToAttrib[num] || [];
    var matches = /mention-token|mention-type|mention-link|mention-notify|mention-sharePermHeldBack/.exec(attr[0]);
    if (matches) {
      info[matches[0]] = attr[0].split('_')[1] || attr[1];
    }
  }
  return info;
}
function getPageToken() {
  return (0, _suiteHelper.getToken)();
}
function humanFileSize(bytes) {
  var thresh = 1024;
  if (Math.abs(bytes) < thresh) {
    return bytes + ' B';
  }
  var units = ['KB', 'MB', 'GB', 'TB', 'P', 'E', 'Z', 'Y'];
  var u = -1;
  while (Math.abs(bytes) >= thresh && u < units.length) {
    bytes /= thresh;
    ++u;
  }
  return bytes.toFixed(2) + ' ' + units[u];
};

function getFileTypeByFileName(fileName) {
  return fileName.split('.').pop().toLowerCase() || 'unknown';
}

function nodeValueCheck(predicate) {
  var sel = getSelection();
  var focusOffset = sel.focusOffset,
      focusNode = sel.focusNode,
      extentNode = sel.extentNode,
      extentOffset = sel.extentOffset;

  if (!focusNode && !extentNode) return false;
  // 优先使用extentNode 理论上根据MDN的描述extentNode应该是focusNode的alias
  // 但实际使用中，focusNode和extentNode并不等同， 似乎extentNode更可靠
  /*eslint-disable*/
  // case :https://stackoverflow.com/questions/27241281/what-is-anchornode-basenode-extentnode-and-focusnode-in-the-object-returned/27347147
  /*eslint-enable*/
  var offset = void 0,
      nodeValue = void 0;
  if (extentNode) {
    offset = extentOffset;
    nodeValue = extentNode.nodeValue || '';
  } else {
    offset = focusOffset;
    nodeValue = focusNode.nodeValue || '';
  }
  var isCaret = _browserHelper2.default.isIE || sel.type === 'Caret';
  return isCaret && predicate(nodeValue, offset);
}

function prevWordIsAt(rep) {
  if (rep) {
    var selEnd = rep.selEnd,
        lines = rep.lines;

    var charIndex = selEnd[0];
    var lineText = lines.atIndex(charIndex).text;

    var value = lineText[selEnd[1] - 1];
    return value === '@';
  }
  // const predicate = (nodeValue, offset) => {
  //   return nodeValue[offset - 1] === '@';
  // };
  // return nodeValueCheck(predicate);
}

function prevTextIsWordsOrNumber() {
  var predicate = function predicate(nodeValue, offset) {
    var textBeforeAt = offset - 2 >= 0 ? nodeValue[offset - 2] : '';
    return (/^[a-zA-Z0-9]$/.test(textBeforeAt)
    );
  };
  return nodeValueCheck(predicate);
}

function isRange(sel) {
  if (_browserHelper2.default.isIE) {
    return sel && sel.toString().length > 0;
  } else {
    return sel && sel.type === 'Range';
  }
};

function isCaret(sel) {
  if (_browserHelper2.default.isIE) {
    return sel && sel.toString().length === 0;
  } else {
    return sel && sel.type === 'Caret';
  }
};

function onUserPopoverAlign(source, target, align) {
  var adjustY = align.overflow.adjustY;

  if (!adjustY || !target) {
    return;
  }

  var offsetHeight = source.offsetHeight,
      className = source.className;

  var node = target;
  var offsetTop = target.offsetTop;
  while (node.offsetParent) {
    offsetTop += node.offsetParent.offsetTop;
    node = node.offsetParent;
  }

  var docContainer = document.getElementsByClassName('etherpad-container-wrapper')[0];
  var clientY = offsetTop - docContainer.scrollTop;

  if (offsetHeight > clientY) {
    // lt
    source.style.top = clientY + 'px';
    source.className = className.replace('_l', '_lt');
  } else {
    // lb
    source.style.top = clientY - offsetHeight + target.offsetHeight + 5 + 'px';
    source.className = className.replace('_l', '_lb');
  }
}

function closeMentionBoxGuide(type) {
  var currentState = _$store2.default.getState();
  var userGuide = (0, _guide.selectUserGuide)(currentState);
  var userGuideStatus = (0, _common.selectFetchStatus)('userGuide')(currentState);

  if (userGuideStatus === _$constants.common.StatusMap.loaded && userGuide.getIn([type, _onboarding.STEP_STATE.DONE]) === false) {
    _$store2.default.dispatch((0, _guide2.closeUserGuide)(type));
  }
}

function getSourceData($target) {
  var type = (0, _tea.getFileType)();

  var list = $target.parents('.comment-list-item');
  var input = $target.parents('.comment-textarea__input');

  var isComment = list.length || input.length;

  var sourceData = {};

  if (isComment) {
    sourceData.isWhole = $target.parents('.global-comment').length > 0;
  }

  if (type === 'doc') {
    sourceData.source = !isComment ? _const.SOURCE_ENUM.DOC : _const.SOURCE_ENUM.DOC_COMMENT;
  } else {
    sourceData.source = !isComment ? _const.SOURCE_ENUM.SHEET : _const.SOURCE_ENUM.SHEET_COMMENT;
  }

  return sourceData;
}

function getSourceString(sourceData) {
  var source = sourceData.source,
      isWhole = sourceData.isWhole;

  if (source === _const.SOURCE_ENUM.DOC) {
    return 'doc';
  } else if (source === _const.SOURCE_ENUM.SHEET) {
    return 'sheet';
  } else {
    return isWhole ? 'full_comment' : 'part_comment';
  }
}

function getSourceFormString(sourceString) {
  var type = (0, _tea.getFileType)();
  var isComment = sourceString === 'full_comment' || sourceString === 'part_comment';
  if (type === 'doc') {
    return !isComment ? _const.SOURCE_ENUM.DOC : _const.SOURCE_ENUM.DOC_COMMENT;
  }

  return !isComment ? _const.SOURCE_ENUM.SHEET : _const.SOURCE_ENUM.SHEET_COMMENT;
}

function sendHoverTeaLog(source, status, type, token) {
  (0, _tea2.default)('show_hover_card', {
    source: source || 'sheet',
    chat_btn_status: status ? 'true' : 'false',
    mention_type: type,
    mention_obj_id: (0, _encryption.encryptTea)(token),
    file_type: (0, _tea.getFileType)(),
    file_id: (0, _tea.getEncryToken)()
  });
}
/**
 * 1: recent_view_user 最近打开文档的user
 * 2: recent_mention_user 最近at过的人
 * 3: lark_search_user lark搜索
 */
function getMentionRecommendSource(source) {
  var obj = {
    1: 'recent_view_user',
    2: 'recent_mention_user',
    3: 'lark_search_user'
  };
  return obj[source];
}

function extraMentionInfoFromMentionClassName() {
  var classNames = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : '';

  var attrs = classNames.split(' ');
  var mentionInfo = {};
  attrs.forEach(function (item) {
    // mention-${type}_${value}
    var match = item.match(/mention-([a-zA-Z]+)_(.+)/);
    if (match) {
      var key = match[1];
      mentionInfo[key] = match[2];
    }
  });
  return mentionInfo;
}
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1591:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = pure;
function pure(methods) {
    return function (target) {
        var original = target;
        function decorateMethods(instance, args) {
            methods.forEach(function (m) {
                var isPure = args && args.pure;
                var originFn = instance[m];
                if (!originFn && "production" !== 'production') {
                    console.error('\u6CA1\u6709\u5728 ' + original.name + ' \u4E2D\u627E\u5230\u65B9\u6CD5 ' + m + ', \u8BF7\u786E\u4FDD ' + m + ' \u4E0D\u662F arrow function');
                }
                instance[m] = function () {
                    if (!isPure) {
                        for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
                            args[_key] = arguments[_key];
                        }

                        return originFn.apply(instance, args);
                    }
                };
            });
        }
        function construct(constructor, args) {
            var c = function c() {
                decorateMethods(this, args);
                return constructor.call(this, args);
            };
            c.prototype = constructor.prototype;
            return new c();
        }
        var f = function f(opts) {
            return construct(original, opts);
        };
        f.prototype = original.prototype;
        return f;
    };
}

/***/ }),

/***/ 1598:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.genUUID = genUUID;
exports.getPageToken = getPageToken;
exports.getOwner = getOwner;
exports.UUIDv4 = UUIDv4;
exports.getListNumberId = getListNumberId;
exports.getTagName = getTagName;

var _string = __webpack_require__(158);

var _suiteHelper = __webpack_require__(60);

/**
 * Created by jinlei.chen on 2017/10/17.
 */
var uui = 0;
/**
 * 获取一个pad内部的uuid
 * @returns {string}
 */
function genUUID() {
  uui++;
  return (0, _string.generateRandomString)(6) + '-' + uui;
}

function getPageToken() {
  return (0, _suiteHelper.getToken)();
}

function getOwner() {
  return window.User ? window.User.id : 'unknown';
}

function UUIDv4() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    var r = Math.random() * 16 | 0;
    var v = c === 'x' ? r : r & 0x3 | 0x8;
    return v.toString(16);
  });
}
function getListNumberId() {
  return (0, _string.generateRandomString)(8);
}

function getTagName(node) {
  return node && (node.tagName || '').toLowerCase();
}

/***/ }),

/***/ 1610:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.BLOCK_PLACEHOLDER = exports.BLOCK_CONTAINER = undefined;

var _isFunction2 = __webpack_require__(100);

var _isFunction3 = _interopRequireDefault(_isFunction2);

exports.getScrollBarWidth = getScrollBarWidth;
exports.px2pt = px2pt;
exports.parseFont = parseFont;
exports.isBold = isBold;
exports.createCustomEvent = createCustomEvent;
exports.selectAll = selectAll;
exports.handleScroll = handleScroll;
exports.isFakeNode = isFakeNode;
exports.isNodeText = isNodeText;
exports.isNodeComment = isNodeComment;
exports.isSVG = isSVG;
exports.getFakeData = getFakeData;
exports.isFakeText = isFakeText;
exports.nodeText = nodeText;

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _object = __webpack_require__(407);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var BLOCK_CONTAINER = exports.BLOCK_CONTAINER = 'j-block-container';
var BLOCK_PLACEHOLDER = exports.BLOCK_PLACEHOLDER = 'block-placeholder';
// 计算类的函数将结果缓存于此
var scrollBarWidth = void 0;
function getScrollBarWidth() {
    if (scrollBarWidth != null) return scrollBarWidth;
    var inner = document.createElement('p');
    inner.style.width = '100%';
    inner.style.height = '200px';
    var outer = document.createElement('div');
    outer.style.position = 'absolute';
    outer.style.top = '0px';
    outer.style.left = '0px';
    outer.style.visibility = 'hidden';
    outer.style.width = '200px';
    outer.style.height = '150px';
    outer.style.overflow = 'hidden';
    outer.appendChild(inner);
    document.body.appendChild(outer);
    var w1 = inner.offsetWidth;
    outer.style.overflow = 'scroll';
    var w2 = inner.offsetWidth;
    if (w1 === w2) w2 = outer.clientWidth;
    document.body.removeChild(outer);
    scrollBarWidth = w1 - w2;
    return scrollBarWidth;
}
var dpi = void 0;
/**
 * 利用浏览器自带方法转换 px2pt
 * @param {number} pxValue
 */
function px2pt(pxValue) {
    if (!dpi) {
        var span = document.createElement('span');
        var pt = 96;
        span.style.fontSize = pt + 'pt';
        span.style.display = 'none';
        document.body.appendChild(span);
        var tempPx = window.getComputedStyle(span).fontSize;
        if (tempPx && tempPx.indexOf('px') !== -1) {
            var tempPxValue = parseFloat(tempPx);
            dpi = pt / tempPxValue;
        } else {
            dpi = 72 / 96;
        }
        document.body.removeChild(span);
    }
    return Math.round(parseFloat(pxValue) * dpi) + 'pt';
}
var parseFontSpan = document.createElement('span');
var fontCache = {};
function parseFont() {
    var font = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : '';

    if (fontCache[font]) {
        return (0, _object.plainObjectCopy)(fontCache[font]);
    }
    parseFontSpan.style.font = font;
    var style = parseFontSpan.style;
    var fontObj = {
        fontFamily: style.fontFamily || '',
        fontSize: style.fontSize || '',
        fontStyle: style.fontStyle || '',
        fontVariant: style.fontVariant || '',
        fontWeight: style.fontWeight || '',
        lineHeight: style.lineHeight || ''
    };
    fontCache[font] = fontObj;
    return (0, _object.plainObjectCopy)(fontObj);
}
function isBold(fontWeight) {
    return ['bold', '600', '700', '800', '900'].indexOf(fontWeight) !== -1;
}
function createCustomEvent(eventName) {
    var eventInitDict = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : {};

    if ((0, _isFunction3.default)(CustomEvent)) {
        return new CustomEvent(eventName, eventInitDict);
    }
    var event = document.createEvent('CustomEvent');
    event.initCustomEvent(eventName, !!eventInitDict.bubbles, !!eventInitDict.cancelable, eventInitDict.detail);
    return event;
}
/**
 * 外层元素有 contenteditable 时，内层 contenteditable 在调用 document.execCommand('selectAll') 时
 * 会把外层元素的内容也选中，所以在选中之前先把它们都设为 false
 *
 * 本函数不调用 focus()
 */
function selectAll(element) {
    var editables = [];
    element = element && element.parentElement;
    while (element) {
        var contenteditable = element.getAttribute('contenteditable');
        if (contenteditable === 'true' || contenteditable === '') {
            editables.push(element);
            element.setAttribute('contenteditable', 'false');
        }
        element = element.parentElement;
    }
    document.execCommand('selectAll');
    for (var i = 0, ii = editables.length; i < ii; i++) {
        editables[i].setAttribute('contenteditable', 'true');
    }
}
/**
 * 当换行或者退格的时候，使滚动条随着光标滚动
 * @param editor 滚动区域
 * @param expectScroll 判断此时滚动方向
 */
function handleScroll(editor, expectScroll) {
    var selection = window.getSelection();
    var focusNode = selection.focusNode;
    var textContent = selection.getRangeAt(0);
    var isText = focusNode.nodeName === '#text';
    var caretPosition = void 0;
    if (isText) {
        caretPosition = textContent.getBoundingClientRect();
    } else {
        caretPosition = focusNode.getBoundingClientRect();
    }
    var caretTop = caretPosition.top;
    var editorRect = editor.getBoundingClientRect();
    var editorTop = editorRect.top;
    var caretHeight = caretPosition.height;
    var editorHeight = editorRect.height;
    var gapTop = caretTop - editorTop;
    var gapDistance = gapTop + caretHeight - editorHeight;
    var scrollTop = editor.scrollTop;
    if (focusNode === editor) return;
    if (expectScroll) {
        if (gapTop <= scrollTop) {
            editor.scrollTop = gapTop;
        } else {
            editor.scrollTop = scrollTop + gapDistance;
        }
    } else if (gapDistance >= 0) {
        editor.scrollTop = scrollTop + gapDistance;
    }
}
function isFakeNode(node) {
    return node && node.getAttribute && typeof node.getAttribute('data-faketext') === 'string';
}
function isNodeText(node) {
    return node.nodeType === 3;
}
function isNodeComment(node) {
    return node.nodeType === 8;
}
function isSVG(node) {
    return node.tagName.toLowerCase() === 'svg';
}
function getFakeData(node) {
    if (node && node.getAttribute) {
        var text = node.getAttribute('data-faketext');
        var originText = node.innerText;
        var originTextLength = originText.length;
        var ignore = node.getAttribute('data-contentcollector-ignore-space-at');
        if (ignore === 'start' && originTextLength) {
            if (originText[originTextLength - 1].charCodeAt(0) === 8203) return originText.substr(0, originText.length - 1);
            return originText && originText.substr(1);
        }
        if (ignore === 'end' && originTextLength) {
            if (originText[0].charCodeAt(0) === 8203) return originText.substr(1);
            return originText && originText.substr(0, originText.length - 1);
        }
        return text;
    }
    return null;
}
function isFakeText(fakeText) {
    return typeof fakeText === 'string';
}
function nodeText(n) {
    if (_browserHelper2.default.msie) {
        return n.innerText;
    }
    if (isNodeText(n)) {
        return n.textContent;
    }
    if (isNodeComment(n)) {
        return '';
    }
    if (isSVG(n)) {
        return '';
    }
    if (n.className && n.className.indexOf('sheet-') > -1) return ' ';
    var fakeText = getFakeData(n);
    if (isFakeText(fakeText)) {
        return fakeText;
    }
    if (n.className && (n.className.indexOf(BLOCK_CONTAINER) !== -1 || n.className.indexOf(BLOCK_PLACEHOLDER) !== -1)) {
        return ' ';
    }
    var _text = '';
    for (var i = 0; i < n.childNodes.length; ++i) {
        _text += nodeText(n.childNodes[i]);
    }
    return _text;
}

/***/ }),

/***/ 1619:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.MindNoteEvent = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _forEach2 = __webpack_require__(1627);

var _forEach3 = _interopRequireDefault(_forEach2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * MindNote事件中心，事件中心的触发源有多个点，本地编辑操作、远端消息、组件通信等等
 */
var MindNoteEvent = exports.MindNoteEvent = undefined;
(function (MindNoteEvent) {
  /**
   * 文档加载完成（本地）
   */
  MindNoteEvent["LOADED"] = "LOADED";
  /**
   * 服务端收到的change事件（远端）
   */
  MindNoteEvent["CHANGE_SERVER"] = "CHANGE_SERVER";
  /**
   * 客户端产生的change事件（本地）
   */
  MindNoteEvent["CHANGE_CLIENT"] = "CHANGE_CLIENT";
  /**
   * 保存事件（本地）
   */
  MindNoteEvent["SAVING"] = "SAVING";
  /**
   * 保存成功事件（本地）
   */
  MindNoteEvent["SAVED"] = "SAVED";
  /**
   * 用户进入事件（远端）
   */
  MindNoteEvent["USER_ENTER"] = "USER_ENTER";
  /**
   * 用户离开事件（远端）
   */
  MindNoteEvent["USER_LEAVE"] = "USER_LEAVE";
  /**
   * 服务端收到的cursor事件（远端）
   */
  MindNoteEvent["CURSOR_SERVER"] = "CURSOR_SERVER";
  /**
   * 客户端产生的cursor事件（本地）
   */
  MindNoteEvent["CURSOR_CLIENT"] = "CURSOR_CLIENT";
  /**
   * 当用户的文档权限变更（远端）
   */
  MindNoteEvent["PERMISSION_CHANGE"] = "PERMISSION_CHANGE";
  /**
   * 当前房间发生了变化（远端）
   */
  MindNoteEvent["ROOM_CHANGE"] = "ROOM_CHANGE";
  /**
   * 当前用户的编辑权限变更（远端）
   */
  MindNoteEvent["EDITABLE_CHANGE"] = "EDITABLE_CHANGE";
  /**
   * 当前用户发生翻页钻取事件（本地）
   */
  MindNoteEvent["DRILL"] = "DRILL";
  /**
   * 打开演示模式（组件通信）
   */
  MindNoteEvent["OPEN_PRESENTATION"] = "OPEN_PRESENTATION";
  /**
   * 打开思维导图模式（组件通信）
   */
  MindNoteEvent["OPEN_MINDMAP"] = "OPEN_MINDMAP";
  /**
   * 错误
   */
  MindNoteEvent["ERROR"] = "ERROR";
  MindNoteEvent["MIND_MAP_EXPORT"] = "MIND_MAP_EXPORT";
})(MindNoteEvent || (exports.MindNoteEvent = MindNoteEvent = {}));
/**
 * 思维笔记事件源，这个事件源主要是用来IO层与视图层和交互层的互相通信
 */

var MindNoteContext = function () {
  function MindNoteContext() {
    (0, _classCallCheck3.default)(this, MindNoteContext);

    this.handlerMap = {};
  }

  (0, _createClass3.default)(MindNoteContext, [{
    key: "bind",
    value: function bind(type, handler) {
      var handlers = this.handlerMap[type];
      if (!handlers) {
        this.handlerMap[type] = [handler];
      } else {
        handlers.push(handler);
      }
    }
  }, {
    key: "unbind",
    value: function unbind(type, handler) {
      var handlers = this.handlerMap[type];
      if (handlers) {
        var index = handlers.findIndex(function (val) {
          return val === handler;
        });
        if (index !== -1) {
          handlers.splice(index, index + 1);
        }
      }
    }
  }, {
    key: "trigger",
    value: function trigger(type, e) {
      var handlers = this.handlerMap[type];
      if (handlers) {
        (0, _forEach3.default)(handlers, function (v) {
          v(e);
        });
      }
    }
  }], [{
    key: "getInstance",
    value: function getInstance() {
      if (!MindNoteContext.mindNoteContext) {
        MindNoteContext.mindNoteContext = new MindNoteContext();
      }
      return MindNoteContext.mindNoteContext;
    }
  }]);
  return MindNoteContext;
}();

exports.default = MindNoteContext;

/***/ }),

/***/ 1631:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.debounceSearchFileList = exports.debounceFetchMentionList = undefined;
exports.fetchUserPermission = fetchUserPermission;
exports.checkReadPermission = checkReadPermission;
exports.authorizePermission = authorizePermission;
exports.fetchOwnerPermission = fetchOwnerPermission;
exports.fetchFileList = fetchFileList;
exports.insertNutStore = insertNutStore;
exports.getMentionList = getMentionList;
exports.notifyAdd = notifyAdd;
exports.notifyGroup = notifyGroup;
exports.notifyDelete = notifyDelete;
exports.joinChat = joinChat;
exports.fetchMentionList = fetchMentionList;
exports.fetchUserInfo = fetchUserInfo;
exports.fetchChatInfo = fetchChatInfo;
exports.atFinder = atFinder;
exports.showNativeTips = showNativeTips;
exports.hideNativeTips = hideNativeTips;
exports.postAddMentionId = postAddMentionId;
exports.postAddGroupMentionId = postAddGroupMentionId;
exports.fetchDocInfo = fetchDocInfo;

var _$rjquery = __webpack_require__(499);

var _request = __webpack_require__(725);

var _request2 = _interopRequireDefault(_request);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _$constants = __webpack_require__(4);

var _const = __webpack_require__(1581);

var _utils = __webpack_require__(1590);

var _userHelper = __webpack_require__(61);

var _debounce2 = __webpack_require__(275);

var _debounce3 = _interopRequireDefault(_debounce2);

var _each2 = __webpack_require__(716);

var _each3 = _interopRequireDefault(_each2);

var _get2 = __webpack_require__(81);

var _get3 = _interopRequireDefault(_get2);

var _set2 = __webpack_require__(2199);

var _set3 = _interopRequireDefault(_set2);

var _omit2 = __webpack_require__(720);

var _omit3 = _interopRequireDefault(_omit2);

var _assign2 = __webpack_require__(506);

var _assign3 = _interopRequireDefault(_assign2);

var _i18nHelper = __webpack_require__(240);

var _utils2 = __webpack_require__(1598);

var _$store = __webpack_require__(83);

var _$store2 = _interopRequireDefault(_$store);

var _offlineEditHelper = __webpack_require__(377);

var _envHelper = __webpack_require__(183);

var _suiteHelper = __webpack_require__(60);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var getMentionListXhr = void 0;
var getFileListXhr = void 0;
var searchFileListXhr = void 0;
var mentionlistCacheMap = {};
var EXPIRES_TIME = 30; // mention缓存的有效期

// 查询用户对某一文档的权限
function fetchUserPermission(param) {
  var fileType = param.fileType,
      fileToken = param.fileToken,
      userId = param.userId;

  return (0, _request2.default)({
    url: '/api/suite/permission/user/?token=' + fileToken + '&type=' + fileType + '&user_id=' + userId,
    method: 'GET'
  });
}

/**
 * 查询用户或群是否有对某一文档的阅读权限
 * @param
 * type:2                            // doc是2，sheet是3
 * token:CJmJMSs6tqqfYHlAHLUz0f
 * owner_type:0                      // 用户是0，群是2
 * owner_id:6442595865021382929      // 用户ID或群ID
 */
function checkReadPermission(_ref) {
  var fileType = _ref.fileType,
      fileId = _ref.fileId,
      ownerType = _ref.ownerType,
      ownerId = _ref.ownerId;

  var url = '/api/suite/permission/members/exist/';
  return (0, _offlineEditHelper.fetch)(url, {
    body: {
      type: fileType,
      token: fileId,
      owner_type: ownerType,
      owner_id: ownerId
    },
    method: 'POST',
    noStore: true,
    readCache: false,
    once: true
  });
}

/**
 * 授权用户或群对某一文档的权限
 * @param
 * type:2                            // doc是2，sheet是3
 * token:CJmJMSs6tqqfYHlAHLUz0f
 * owners: [{
 *  "owner_id":"1515034823210197",  // 用户ID或群ID
    "owner_type":2,                 // 用户是0，群是2
    "permission":5                  // 阅读权限是1，编辑权限是5
 * }]
 * notify_lark: 0      // 是否发送lark通知
 */
function authorizePermission(_ref2) {
  var fileType = _ref2.fileType,
      fileId = _ref2.fileId,
      owners = _ref2.owners,
      _ref2$needNotify = _ref2.needNotify,
      needNotify = _ref2$needNotify === undefined ? 0 : _ref2$needNotify,
      source = _ref2.source;

  var url = '/api/suite/permission/members/create/';
  return (0, _offlineEditHelper.fetch)(url, {
    body: {
      type: fileType,
      token: fileId,
      owners: owners,
      notify_lark: needNotify,
      source: source
    },
    method: 'POST',
    noStore: true,
    readCache: false,
    once: true
  });
}

/**
 * 查询某个对象是否存在于分享面板中
 * @param {*} param
 * ownerType enum
 * 0 user
 * 2 群
 * 4 公共
 * 5 共享文件夹
 */
function fetchOwnerPermission(param) {
  var owner_type = param.ownerType,
      type = param.type,
      owner_id = param.ownerId,
      token = param.token;


  return (0, _request2.default)({
    url: _$constants.apiUrls.POST_EXIST_MEMBER_PERMISSION,
    method: 'POST',
    data: {
      owner_type: owner_type,
      owner_id: owner_id,
      type: type,
      token: token
    },
    contentType: 'application/x-www-form-urlencoded'
  });
}

function getFileList(filePath) {
  var dfd = _$rjquery.$.Deferred();
  getFileListXhr = (0, _offlineEditHelper.fetch)('/api/drive/filelist/', {
    body: {
      dir: filePath || '/',
      token: (0, _utils2.getPageToken)()
    },
    method: 'GET',
    timeout: 10000,
    noStore: true
  }).always(function (ret) {
    var errMsg = void 0;
    if (ret.statusText === 'abort') {
      return dfd.reject(ret);
    }
    if (ret.code !== 0) {
      if (ret.statusText === 'timeout' || !window.navigator.onLine) {
        errMsg = t('etherpad.network_abnormal');
      } else {
        errMsg = _const.SEARCH_ERROR_MSG[ret.code];
      }
      ret = { data: { data: [] }, message: errMsg };
      return dfd.reject(ret);
    }
    dfd.resolve(ret);
  });
  dfd.abort = getFileListXhr.abort.bind(getFileListXhr);
  return dfd;
}

function fetchFileList(param, successCbk, errorCbk) {
  // 改用promise 吧
  var xhr = getFileList(param);
  xhr.done(function (ret) {
    successCbk(ret);
  }).fail(function () {
    errorCbk();
  });
  return xhr;
}
function insertNutStore(_ref3) {
  var file_path = _ref3.file_path,
      fileName = _ref3.file_name,
      file = _ref3.file;

  var form = {
    method: 'POST',
    url: '/api/drive/insertnutstore/',
    data: JSON.stringify({
      'token': (0, _utils2.getPageToken)(),
      file_path: file_path,
      file_name: fileName
    }),
    contentType: 'applicaiton/json',
    timeout: 10000
  };
  return new Promise(function (resolve, reject) {
    (0, _request2.default)(form).done(function (ret) {
      if (ret.code === 0) {
        resolve({ drive_file_key: ret.data.drive_file_key, file: file });
      } else {
        reject(file);
      }
    }).fail(function () {
      reject(file);
    });
  });
}

var typeMap = {
  0: 'users',
  1: 'notes',
  3: 'notes',
  5: 'chats',
  6: 'groups'
};
function getMentionList(param) {
  var dfd = _$rjquery.$.Deferred();
  getMentionListXhr && getMentionListXhr.abort();
  getMentionListXhr = (0, _offlineEditHelper.fetch)('/api/mention/recommend.v2/', {
    body: param,
    method: 'POST',
    timeout: 10000,
    noStore: true
  }).always(function (ret) {
    var errMsg = void 0;
    // abort掉的不要处理 否则会闪成没结果然后又出来结果
    if (ret.statusText === 'abort') {
      return dfd.reject(ret);
    }

    if (ret.code !== 0) {
      if (ret.statusText === 'timeout' || !window.navigator.onLine) {
        errMsg = t('etherpad.network_abnormal');
      } else {
        errMsg = _const.SEARCH_ERROR_MSG[ret.code];
      }
      ret = { data: { result_list: [] }, message: errMsg };
    }

    // 将pc传过来的空title根据国际化处理
    (0, _each3.default)(ret.data.result_list, function (item) {
      var type = item.type,
          token = item.token;

      var typeInt = parseInt(type);
      var map = typeMap[typeInt];
      if (!map) {
        errMsg = _const.SEARCH_ERROR_MSG[1];
        ret = { data: { result_list: [] }, message: errMsg };
      }

      var entity = ret.data.entities[map][token];
      var title = entity.title,
          name = entity.name,
          avatarUrl = entity.avatar_url;


      if (typeInt === _const.TYPE_ENUM.SHEET || typeInt === _const.TYPE_ENUM.FILE) {
        if (!title) {
          item.content = (0, _i18nHelper.getUnnamedTitle)(typeInt);
        } else {
          item.content = title;
        }
      }
      if (typeInt === _const.TYPE_ENUM.USER) {
        item.content = (0, _userHelper.getNameByIdFromUsers)(ret.data.entities.users, token);
        item.url = avatarUrl;
      }
      if (typeInt === _const.TYPE_ENUM.CHAT || typeInt === _const.TYPE_ENUM.GROUP) {
        item.content = name;
        item.url = avatarUrl;
      }

      var newEntity = (0, _omit3.default)(entity, ['id', 'title', 'name', 'cn_name', 'en_name', 'avatar_url']);
      (0, _assign3.default)(item, newEntity);
    });

    dfd.resolve(ret);
  });
  dfd.abort = getMentionListXhr.abort.bind(getMentionListXhr);
  return dfd;
}

function notifyAdd(param) {
  var url = '/api/mention/notify/';
  return (0, _offlineEditHelper.fetch)(url, {
    body: JSON.stringify(param),
    method: 'POST',
    contentType: 'application/json',
    noStore: true,
    readCache: false
  });
}

function notifyGroup(param) {
  var url = '/api/mention/notification/';
  return (0, _offlineEditHelper.fetch)(url, {
    body: JSON.stringify(param),
    method: 'POST',
    contentType: 'application/json',
    noStore: true,
    readCache: false,
    once: true
  });
}

function notifyDelete(param) {
  return (0, _request2.default)({ url: '/api/mention/unnotify/', method: 'POST', data: param });
}
function joinChat(param) {
  var chatId = param.chatId,
      invitor = param.invitor;

  var noteToken = location.pathname.replace(/\/doc\/|\/sheet\//, '');
  return (0, _offlineEditHelper.fetch)('/api/mention/join.chat/', {
    method: 'POST',
    body: {
      token: noteToken, chat_id: chatId, invitor: invitor
    }
  });
}

var _isOutofDate = function _isOutofDate(fileTime) {
  var currentDate = +new Date();
  return (currentDate - fileTime) / 1000 > EXPIRES_TIME;
};

var _getFromCache = function _getFromCache(para) {
  var content = para.content,
      type = para.type;

  var DEFATLT_DATE = +new Date() + 30 * 1000;
  var keyWords = content === undefined || content === '' ? 'All' : content;
  var result = (0, _get3.default)(mentionlistCacheMap, type + '.' + keyWords + '.result');
  var currentToken = (0, _suiteHelper.getToken)();
  var fileToken = (0, _get3.default)(mentionlistCacheMap, type + '.' + keyWords + '.fileToken');
  var fileTime = (0, _get3.default)(mentionlistCacheMap, type + '.' + keyWords + '.time', DEFATLT_DATE);
  if (result && !_isOutofDate(fileTime) && currentToken === fileToken) {
    return result;
  };
  return null;
};

/**
 * 中文情况下
 * 如果cache里面已经存在keywords = “梦想”
 * 再次输入如“m'x”
 * 这时从输入法选项中选择“梦想”
 * 若此时“m'x”请求已经发送出去并且即将结束，abort和cancel都无法阻止
 * 最终从cache中读取的“梦想”会被“m'x”的结果覆盖
 * 故手动控制是否取消
 */
var cancel = false;
var debounceFetch = (0, _debounce3.default)(fetchMentionList, 400);
function fetchMentionList(param, cbk) {
  var fileToken = (0, _suiteHelper.getToken)();
  cancel = false;
  var xhr = getMentionList(param);
  xhr.then(function (ret) {
    if (ret.code === 0) {
      var keyWord = param.content === undefined || param.content === '' ? 'All' : param.content;
      (0, _set3.default)(mentionlistCacheMap, param.type + '.' + keyWord, { time: +new Date(), result: ret, fileToken: fileToken });
    }
    !cancel && cbk(ret);
  });
  return Object.assign({}, xhr, debounceFetch);
};
var debounceFetchHandle = void 0;
var debounceFetchMentionList = exports.debounceFetchMentionList = function debounceFetchMentionList(param, cbk) {
  var res = _getFromCache(param);
  if (res) {
    if (debounceFetchHandle) {
      debounceFetchHandle.abort();
      debounceFetchHandle.cancel();
    }
    cancel = true;
    cbk(res);
    return {
      abort: function abort() {}
    };
  } else {
    debounceFetchHandle = debounceFetch(param, cbk);
    return debounceFetchHandle;
  }
};

function searchFileList(param) {
  var dfd = _$rjquery.$.Deferred();
  searchFileListXhr = (0, _request2.default)({
    url: '/api/drive/searchfile/',
    contentType: 'application/json',
    data: JSON.stringify({
      search_key: param || '',
      token: (0, _utils2.getPageToken)()
    }),
    method: 'POST',
    timeout: 10000
  }).always(function (ret) {
    var errMsg = void 0;
    if (ret.statusText === 'abort') {
      return dfd.reject(ret);
    }
    if (ret.code !== 0) {
      if (ret.statusText === 'timeout' || !window.navigator.onLine) {
        errMsg = t('etherpad.network_abnormal');
      } else {
        errMsg = _const.SEARCH_ERROR_MSG[ret.code];
      }
      ret = { data: { data: [] }, message: errMsg };
      return dfd.reject(ret);
    }
    dfd.resolve(ret);
  });
  dfd.abort = searchFileListXhr.abort.bind(searchFileListXhr);
  return dfd;
}

var debounceSearchFileList = exports.debounceSearchFileList = (0, _debounce3.default)(function (param, cbk) {
  var xhr = searchFileList(param);
  xhr.then(function (ret) {
    cbk(ret);
  });
  return xhr;
}, 100);

function fetchUserInfo(param) {
  param.token = (0, _utils2.getPageToken)();
  return (0, _request2.default)({
    url: '/api/mention/user.detail.v2/',
    data: JSON.stringify(param),
    method: 'POST',
    contentType: 'application/json'
  });
}

function fetchChatInfo(param) {
  return (0, _request2.default)({
    url: '/api/mention/chat.info.v2/',
    data: JSON.stringify(param),
    method: 'POST',
    contentType: 'application/json'
  });
}

function atFinder(_ref4, callback) {
  var keyword = _ref4.keyword,
      show = _ref4.show,
      token = _ref4.token,
      announcementParams = _ref4.announcementParams;
  var USER = _const.TYPE_ENUM.USER,
      SHEET_DOC = _const.TYPE_ENUM.SHEET_DOC;
  // const { USER, SHEET_DOC, GROUP } = TYPE_ENUM;

  var dataObject = {
    id: 'atfinder',
    source: _const.AT_POSITION.DOC,
    show: show,
    token: token,
    type: (0, _utils.getFilter)(USER, SHEET_DOC),
    // type: getFilter(USER, SHEET_DOC, GROUP),
    content: keyword,
    onSuccess: callback
  };
  if ((0, _envHelper.isAnnouncement)()) {
    dataObject = Object.assign({}, dataObject, announcementParams);
  }
  (_browserHelper2.default.isDocs || _browserHelper2.default.isLark) && window.lark.biz.util.atfinder(dataObject);
}

function showNativeTips(items, callback) {
  (_browserHelper2.default.isDocs || _browserHelper2.default.isLark) && window.lark.biz.util.showTips && window.lark.biz.util.showTips({
    id: 'showTips',
    items: items,
    onSuccess: callback
  });
}

function hideNativeTips(callback) {
  (_browserHelper2.default.isDocs || _browserHelper2.default.isLark) && window.lark.biz.util.hideTips && window.lark.biz.util.hideTips({
    id: 'hideTips',
    onSuccess: callback
  });
}

function postAddMentionId(editorInfo, uuid, mention) {
  var state = _$store2.default.getState();
  var param = {
    to_user: [mention.token],
    source: _const.SOURCE_ENUM.DOC,
    target: _const.TARGET_ENUM.LARK,
    note_token: state.appState.currentNoteToken.get('obj_token'),
    from_user: state.appState.currentUser.get('suid')
  };

  // 解决 setAttribute之前判断下这个玩意儿存不存在
  if (mention.type === _const.TYPE_ENUM.USER) {
    var selector = '.block-id-' + uuid;
    var $mentionDom = (0, _$rjquery.$)(selector);
    if ($mentionDom.length) {
      notifyAdd(param).then(function (ret) {
        var setMentionId = function setMentionId() {
          // 回来之后再判断一次
          if ((0, _$rjquery.$)(selector).length) {
            var code = ret.code,
                data = ret.data;

            var mentionId = data['mention_id'];
            if (!code && mentionId !== undefined) {
              editorInfo.ace_inCallStackIfNecessary('performMentionId', function () {
                editorInfo.ace_makeNewEvent('nonundoable', function () {
                  editorInfo.ace_fastIncorp();
                  var blockInfo = editorInfo.plugins.blockPlugin.blockInfos.get(uuid);
                  if (blockInfo && blockInfo.instance) {
                    blockInfo.instance.setProps({
                      data: {
                        mentionId: mentionId
                      }
                    });
                  }
                });
              });
            }
          }
        };

        if (editorInfo.getInInternationalComposition()) {
          editorInfo.call('asyncNotifyCallback', setMentionId);
          return;
        }

        setMentionId();
      });
    }
  }
}
function postAddGroupMentionId(editorInfo, uuid, mention, data) {
  var state = _$store2.default.getState();
  var id = data.id;

  var param = {
    entities: {
      group_chats: [Object.assign({}, data)]
    },
    source: _const.SOURCE_ENUM.DOC,
    target: _const.TARGET_ENUM.LARK,
    token: state.appState.currentNoteToken.get('obj_token')
  };

  // 解决 setAttribute之前判断下这个玩意儿存不存在
  if (mention.type === _const.TYPE_ENUM.GROUP) {
    var selector = '.mention-tempId_' + uuid;
    var $mentionDom = (0, _$rjquery.$)(selector);
    if ($mentionDom.length) {
      notifyGroup(param).then(function (ret) {
        // 回来之后再判断一次
        if ((0, _$rjquery.$)(selector).length) {
          var rep = editorInfo.ace_domToRep((0, _$rjquery.$)(selector).get(0));
          if (!rep) {
            return;
          }
          var code = ret.code,
              _data = ret.data;

          var chats = (0, _get3.default)(_data, 'entities.group_chats');
          if (!code && chats) {
            var mentionId = chats[id];
            editorInfo.ace_inCallStackIfNecessary('performMentionId', function () {
              editorInfo.ace_makeNewEvent('nonundoable', function () {
                editorInfo.ace_fastIncorp();
                editorInfo.ace_setAttributeOnSelection(rep.selStart[2], 'mention-tempId', '', rep);
                editorInfo.ace_setAttributeOnSelection(rep.selStart[2], 'mention-id', mentionId, rep);
              });
            });
          }
        }
      });
    }
  }
}

function fetchDocInfo(param) {
  var type = param.type,
      token = param.token;

  return (0, _request2.default)({
    url: '/api/' + type + '/' + token + '/',
    method: 'GET'
  });
}
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1632:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});

__webpack_require__(1696);

var _$rjquery = __webpack_require__(499);

var _$store = __webpack_require__(83);

var _$store2 = _interopRequireDefault(_$store);

var _share = __webpack_require__(375);

var _const = __webpack_require__(1581);

var _apis = __webpack_require__(1631);

var _security = __webpack_require__(1616);

var _suiteHelper = __webpack_require__(60);

var _sanitizeHtml = __webpack_require__(1752);

var _sanitizeHtml2 = _interopRequireDefault(_sanitizeHtml);

var _close_tips3x = __webpack_require__(2303);

var _close_tips3x2 = _interopRequireDefault(_close_tips3x);

var _utils = __webpack_require__(1590);

var _index = __webpack_require__(1755);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// import MentionBox from './MentionBox';
/**
 * Created by jinlei.chen on 2017/9/8.
 */
var CommentMention = {
  reset: function reset() {},
  notifyMap: {}, // 一条评论对应的通知
  timerMap: {}, // 一条评论对应的延迟执行timer
  taskCount: 0, // 调用showTips的次数
  calTextWithMention: function calTextWithMention(input) {
    var $input = (0, _$rjquery.$)(input);
    var toUsers = [];
    var $inputClone = $input.clone();
    if (CommentMention.isMentionBoxVisible()) {
      CommentMention.mentionBox.close();
    }

    // 存在mention
    if ($input.find('.mention').length) {
      var $mentions = $inputClone.find('.mention');
      for (var i = 0, len = $mentions.length; i < len; i++) {
        var $mention = $mentions.eq(i);
        var text = $mention.text();
        var href = $mention.find('a').attr('href') || '';
        var type = $mention.attr('type');
        var token = $mention.attr('token');
        var $at = (0, _$rjquery.$)('<at type=\'' + type + '\' href=\'' + href + '\' token=\'' + token + '\'>' + (0, _security.escapeHTML)(text) + '</at>');
        if (type === _const.TYPE_ENUM.USER.toString() && token) {
          toUsers.push(token);
        }
        $mention.replaceWith($at);
      }
    }
    return $inputClone.html().replace(/<div><br(\/?)><\/div>/g, '\n').replace(/<div>/gi, '\n').replace(/<\/div>/gi, '').replace(/<br(\/?)>/g, '\n').replace(/<([^<>\s/]+)([^>]*)>/g, function (text, tagName, c) {
      if (tagName === 'at') {
        return text;
      }
      return '';
    }).replace(/<\/([^<>]+)>/g, function (text, tagName) {
      if (tagName === 'at') {
        return text;
      }
      return '';
    }).replace(/&nbsp;/g, '');
  },
  saveNativeMentionNotification: function saveNativeMentionNotification(content, tempCommentId) {
    // 若当前用户没有分享权限，不处理
    var currentUserPermissions = (0, _share.selectCurrentPermission)(_$store2.default.getState()) || [];
    if (currentUserPermissions.indexOf(8) <= -1) {
      return;
    }

    var replaceReg = /<at .*?>.*?<\/at>/g;
    var toUsers = [];
    content.replace(replaceReg, function ($0) {
      var tokenReg = /(?:<at.*? token=(?:'|"))(.*)(?:(?:'|").*>.*<\/at>)/;
      var token = $0.match(tokenReg)[1];
      var typeReg = /(?:<at.*? type=(?:'|"))(\d)(?:(?:'|").*>.*<\/at>)/;
      var type = $0.match(typeReg)[1];
      // @人或群，需要发送通知
      if (parseInt(type) === _const.TYPE_ENUM.USER || parseInt(type) === _const.TYPE_ENUM.GROUP) {
        if (window.User.id !== token) {
          toUsers.push({ token: token, type: type, content: content });
        }
      }
    });
    if (toUsers.length > 0) {
      CommentMention.notifyMap[tempCommentId] = toUsers;
    }
  },
  /**
   * 评论提交成功之后发notify
   */
  /**
   * 产品决定评论中@人先不上自动授权了
   * 撤销通知先不上了，若@了群则直接通知，@用户不需要额外通知，服务端本身实现了自动通知人
   * 代码先不删，后面还会重新用到的～～
   */
  sendMentionNotification: function sendMentionNotification(tempCommentId) {
    var notifyMap = CommentMention.notifyMap;
    var entities = notifyMap[tempCommentId];
    if (entities && entities.length > 0) {
      CommentMention.notifyLark(entities);
    }
    /*
    const noPermissions = [];
    const timeout = 10000;
    let timer;
    let successCount = 0;
    if (notifyMap[tempCommentId] && notifyMap[tempCommentId].length > 0) {
      const entities = notifyMap[tempCommentId];
      const handler = () => {
        // 无权限的人，需要给这些人授权，然后lark通知
        if (noPermissions.length > 0) {
          CommentMention.delayAuthorizePermission(tempCommentId, noPermissions).then(() => {
            CommentMention.notifyLark(entities);
          });
        } else {
          CommentMention.delayNotifyLark(tempCommentId, entities);
        }
      };
      entities.forEach(({ type, token }) => {
        const isUser = parseInt(type) === TYPE_ENUM.USER;
        checkReadPermission({
          fileType: 2, // doc 2 sheet 3
          fileId: getToken(),
          ownerId: token,
          ownerType: isUser ? 0 : 2, // 0 用户 2 群
        }).then((res) => {
          if (res.code === 0) {
            if (res.data && res.data.existed) {
              // 有权限
            } else {
              // 无权限
              noPermissions.push({ type, token });
            }
          }
          if (++successCount >= entities.length) {
            if (timer) {
              clearTimeout(timer);
              timer = null;
            }
            handler();
          }
        }).catch(e => {
          if (++successCount >= entities.length) {
            if (timer) {
              clearTimeout(timer);
              timer = null;
            }
            handler();
          }
        });
      });
       // 超时处理
      timer = setTimeout(() => {
        timer = null;
        if (successCount < entities.length) {
          handler();
        }
      }, timeout);
    } */
  },

  delayAuthorizePermission: function delayAuthorizePermission(uuid, entities) {
    return new Promise(function (resolve, reject) {
      var tipsText = t('mobile.authorize.notify.all');
      CommentMention.showTips(tipsText, function (callId) {
        if (callId === 1) {
          // 手动关闭
          (0, _apis.hideNativeTips)();
        } else if (callId === 3) {
          // 撤销
          CommentMention.clearTimer(uuid);
        }
      });
      CommentMention.timerMap[uuid] = setTimeout(function () {
        if (--CommentMention.taskCount <= 0) {
          CommentMention.taskCount = 0;
          (0, _apis.hideNativeTips)();
        }
        var owners = entities.map(function (_ref) {
          var token = _ref.token,
              type = _ref.type;

          return {
            owner_id: token,
            owner_type: parseInt(type) === _const.TYPE_ENUM.USER ? 0 : 2,
            permission: 1
          };
        });
        (0, _apis.authorizePermission)({
          fileType: 2, // doc 2 sheet 3
          fileId: (0, _suiteHelper.getToken)(),
          owners: JSON.stringify(owners),
          source: 'doc_comment' // 打点，勿删
        }).then(function (res) {
          if (res.code === 0) {
            resolve(entities);
          } else {
            reject(entities);
          }
        });
      }, _const.AUTHORIZE_DELAY);
    });
  },

  delayNotifyLark: function delayNotifyLark(uuid, entities) {
    var tipsText = t('mobile.mention.notify.all');
    CommentMention.showTips(tipsText, function (callId) {
      if (callId === 1) {
        // 手动关闭
        (0, _apis.hideNativeTips)();
      } else if (callId === 3) {
        // 撤销
        CommentMention.clearTimer(uuid);
      }
    });
    CommentMention.timerMap[uuid] = setTimeout(function () {
      if (--CommentMention.taskCount <= 0) {
        CommentMention.taskCount = 0;
        (0, _apis.hideNativeTips)();
      }
      CommentMention.notifyLark(entities);
    }, _const.NOTIFY_DELAY);
  },

  notifyLark: function notifyLark(entities) {
    var users = [];
    var groups = [];
    entities.forEach(function (item) {
      if (parseInt(item.type) === _const.TYPE_ENUM.USER) {
        users.push(item);
      } else if (parseInt(item.type) === _const.TYPE_ENUM.GROUP) {
        groups.push(item);
      }
    });
    var params = {
      from_user: window.User.id,
      source: _const.SOURCE_ENUM.DOC_COMMENT,
      target: _const.TARGET_ENUM.LARK
    };
    // @的用户，后端本身做了自动通知
    // if (users.length > 0) {
    //   notifyAdd(Object.assign({
    //     note_token: getToken(),
    //     to_user: users.map(({ token }) => token),
    //   }, params));
    // }
    if (groups.length > 0) {
      (0, _apis.notifyGroup)(Object.assign({
        token: (0, _suiteHelper.getToken)(),
        entities: {
          group_chats: groups.map(function (_ref2) {
            var token = _ref2.token,
                content = _ref2.content;

            return { 'id': token, 'text': content ? content.replace(/<at .*?>/g, '').replace(/<\/at>/g, '') : '' };
          })
        }
      }, params));
    }
  },

  showTips: function showTips(text, callback) {
    CommentMention.taskCount++;
    (0, _apis.showNativeTips)([{
      id: 1,
      base64Image: _close_tips3x2.default
    }, {
      id: 2,
      text: text
    }, {
      id: 3,
      text: t('mobile.mention.notify.undo')
    }], callback);
  },

  clearTimer: function clearTimer(key) {
    if (CommentMention.timerMap[key]) {
      clearTimeout(CommentMention.timerMap[key]);
      CommentMention.timerMap[key] = null;
      // 确认已经所有@都处理完了才hide
      if (--CommentMention.taskCount <= 0) {
        CommentMention.taskCount = 0;
        (0, _apis.hideNativeTips)();
      }
    }
  },

  contentSanitize: function contentSanitize(content) {
    return (0, _sanitizeHtml2.default)(content.trim(), {
      allowedTags: ['at'],
      allowedAttributes: {
        'at': ['href', 'type', 'token']
      },
      // ios mention如果不为 href="xxx" 会有 bug
      transformTags: {
        'at': function at(tagName, attribs) {
          var type = attribs.type,
              href = attribs.href,
              token = attribs.token;

          var newHref = type === '0' || type === '6' ? 'x' : href;
          return {
            tagName: 'at',
            attribs: {
              type: type,
              href: newHref,
              token: token
            }
          };
        }
      }
    });
  },
  encodeMentionContent: function encodeMentionContent(content) {
    var replaceReg = /<at .*?>.*?<\/at>/g;
    var startIndex = 0;
    var res = '';
    content.replace(replaceReg, function ($0, $1) {
      res += (0, _security.escapeHTML)(content.slice(startIndex, $1));
      res += $0;
      startIndex = $0.length + $1;
    });
    res += (0, _security.escapeHTML)(content.slice(startIndex, content.length));

    return res;
  },

  addMention: function addMention(mention, uuid, context) {
    var type = mention.type,
        content = mention.content,
        token = mention.token,
        url = mention.url;
    var $input = context.$input;

    var ct = (0, _security.escapeHTML)(content);
    var className = 'cmt-mention mention mention-type_' + type;
    var mentionHtml = void 0;

    if (type === _const.TYPE_ENUM.USER) {
      ct = '@' + ct;
      mentionHtml = '<a  href="">' + ct + '</a>';
    } else {
      mentionHtml = '<a  href="' + url + '" target="_blank" >' + ct + '</a>';
    }
    if (uuid) {
      var fragment = document.createDocumentFragment();
      var $mention = (0, _$rjquery.$)('<span class="' + className + '"\n                              token="' + token + '"\n                              type="' + type + '">' + mentionHtml + '</span>');
      var endTextNode = document.createTextNode('\xA0');
      fragment.appendChild($mention.get(0));
      fragment.appendChild(endTextNode);
      var $thisAtHolder = (0, _$rjquery.$)('.' + _const.AT_HOLDER_PREFIX + uuid);
      var $atParent = $thisAtHolder.parent('.mention');
      // 合并到另一个@ 里面去了 移除@那个node 在后面添加一个新的@内容
      if ($atParent.length) {
        $thisAtHolder.remove();
        $atParent.after(fragment);
      } else {
        $thisAtHolder.after(fragment);
        $thisAtHolder.remove();
      }
      $input.trigger('input');
      CommentMention.moveCursorTextEnd(endTextNode);
    }
  },
  moveCursorIfNecessary: function moveCursorIfNecessary(context) {
    var evt = context.evt;
    var keyCode = evt.keyCode;
    var LEFT = _const.KEYS.LEFT,
        RIGHT = _const.KEYS.RIGHT;


    if (keyCode === LEFT) {
      var $mentionNode = (0, _utils.getPrevMentionFromFocus)();
      if ($mentionNode.length) {
        var textDom = $mentionNode.find('a').get(0).lastChild;
        CommentMention.moveCursorTextStart(textDom);
      }
    } else if (keyCode === RIGHT) {
      var _$mentionNode = (0, _utils.getNextMentionFromFocus)();
      if (_$mentionNode.length) {
        var _textDom = _$mentionNode.find('a').get(0).lastChild;
        CommentMention.moveCursorTextEnd(_textDom);
      }
    }
  },

  handleKey: function handleKey(event) {
    var $input = (0, _$rjquery.$)(event.target);
    return _index.docMention.handleKeyEvent({ evt: event, $input: $input }, CommentMention, 'comment');
  },

  handleKeyEvent: function handleKeyEvent(context) {
    var evt = context.evt,
        $input = context.$input;
    var type = evt.type,
        shiftKey = evt.shiftKey,
        key = evt.key;


    if (key === '@' && type === 'keydown') {
      var $firstChild = $input.children().eq(0);
      if ($firstChild.prop('nodeName') === 'BR') {
        $firstChild.remove();
      }
    }

    if (type === 'keyup' && !shiftKey) {
      var $mentionNode = (0, _utils.getPrevMentionFromFocus)(false);

      // 将写到了 mention里面的字符串移除出去
      if (!$mentionNode.length) {
        return;
      }
      var $a = $mentionNode.eq(0).find('a');
      var aText = $a.text();
      var allText = $mentionNode.eq(0).text();

      if (allText === aText) {
        return;
      }
      var index = allText.indexOf(aText);
      var textDom = void 0;
      $mentionNode.html($a);
      if (index > 0) {
        // 在前面加了内容
        textDom = document.createTextNode(allText.slice(0, index));
        $mentionNode.before(textDom);
      } else {
        textDom = document.createTextNode(allText.slice(aText.length + index));
        $mentionNode.after(textDom);
      }
      CommentMention.moveCursorTextEnd(textDom);
    }
  },
  notifyAdd: function notifyAdd() {
    var params = {
      note_token: (0, _suiteHelper.getToken)(),
      from_user: window.User.s,
      source: _const.SOURCE_ENUM.DCO_COMMENT,
      target: _const.TARGET_ENUM.LARK
    };
    return (0, _apis.notifyAdd)(params);
  },
  moveCursorTextEnd: function moveCursorTextEnd(textDom) {
    (0, _utils.setCursor)(textDom, 'end');
  },
  moveCursorTextStart: function moveCursorTextStart(textDom) {
    (0, _utils.setCursor)(textDom, 'start');
  },
  deleteMentionIfNecessary: function deleteMentionIfNecessary(context) {
    var $mentionNode = (0, _utils.getPrevMentionFromFocus)();
    var evt = context.evt,
        $input = context.$input;
    var type = evt.type;

    var sel = (0, _utils.getSelection)();
    var baseNode = sel.baseNode,
        baseOffset = sel.baseOffset,
        focusNode = sel.focusNode,
        focusOffset = sel.focusOffset;

    var $crackElem = void 0,
        startNode = void 0,
        endNode = void 0;

    if ($mentionNode.length && type === 'keydown') {
      var $prevNode = $mentionNode.prev();
      // 直接把base和focus的字符串都裁掉一些 将选区中的元素全部移除
      if ((0, _utils.isRange)(sel)) {
        if (focusNode && focusNode.nodeValue) {
          focusNode.nodeValue = focusNode.nodeValue.slice(0, focusOffset);
        }
        if (baseNode && baseNode.nodeValue) {
          baseNode.nodeValue = baseNode.nodeValue.slice(baseOffset);
        }
        if (baseNode.compareDocumentPosition(focusNode) === 4) {
          // 前
          startNode = baseNode;
          endNode = focusNode;
        } else {
          startNode = focusNode;
          endNode = baseNode;
        }

        $crackElem = CommentMention.findCrackElem(startNode, endNode, $input);
        $crackElem.remove();
      }
      $mentionNode.remove();
      var prevTextNode = $prevNode.contents().filter(function () {
        return this.nodeType === 3;
      }).get(0);
      if (prevTextNode && prevTextNode.length) {
        (0, _utils.setCursor)(prevTextNode, 'end');
      }
      $input.trigger('input');
      evt.preventDefault();
    }
  },
  findCrackElem: function findCrackElem(startNode, endNode, $input) {
    var ret = [];
    var contents = $input.contents();
    var PREV = _const.DOM_POSITION.PREV,
        AFTER = _const.DOM_POSITION.AFTER;

    for (var i = 0, len = contents.length; i < len; i++) {
      if (startNode.compareDocumentPosition(contents[i]) === PREV && endNode.compareDocumentPosition(contents[i]) === AFTER) {
        ret.push(contents[i]);
      }
    }
    return (0, _$rjquery.$)(ret);
  },
  findParent: function findParent(node) {
    if (node) {
      while (node.parentNode && node !== document) {
        if ((0, _$rjquery.$)(node.parentNode).hasClass('comment-list__input')) {
          return node;
        }
        node = node.parentNode;
      }
    }
    return null;
  },
  // showMentionBox: function (context, props, evt) {
  //   const { keyCode } = evt;
  //   if (keyCode === 229) { // win中文输入法输入的@ document.execCommand('delete') 没法删除 timeout才行
  //     setTimeout(function () {
  //       document.execCommand('delete');
  //       CommentMention._showMentionBox(context, props, evt);
  //     });
  //     return;
  //   }
  //   CommentMention._showMentionBox(context, props, evt);
  // },
  // _showMentionBox: function (context, props, evt) {
  //   const { $input, collectSource } = context;
  //   const { uuid } = props;
  //   const sel = getSelection();
  //   const focusOffset = sel.focusOffset;
  //   const focusNode = sel.focusNode;
  //   if (focusNode) {
  //     const text = focusNode.nodeValue || '';
  //     const atDom = $(`<span class="${AT_HOLDER_PREFIX}${uuid}">@</span>`).get(0);
  //
  //     // 没有在mention里面
  //     const $mentionNode = getPrevMentionFromFocus();
  //     if ($mentionNode.length) {
  //       $mentionNode.after(atDom);
  //     } else if (focusNode.nodeType === 3 && !isMentionNode(focusNode)) {
  //       const fragment = document.createDocumentFragment();
  //       const prevText = text.slice(0, focusOffset);
  //       const afterText = text.slice(focusOffset);
  //       fragment.appendChild(document.createTextNode(prevText));
  //       fragment.appendChild(atDom);
  //       fragment.appendChild(document.createTextNode(afterText));
  //       $(focusNode).replaceWith(fragment);
  //     } else {
  //       // 删除掉一个多余的br
  //       if (_get(focusNode, 'lastElementChild.nodeName', '').toUpperCase() === 'BR') {
  //         $(focusNode.lastElementChild).remove();
  //       }
  //       $input.append(atDom);
  //     }
  //     $input.trigger('input');
  //
  //     CommentMention.moveCursorTextEnd(atDom.lastChild);
  //     const zone = getZone();
  //     collectSuiteEvent('open_mention', {
  //       source: collectSource,
  //       zone,
  //     });
  //
  //     const position = getPosition(atDom, { boxWidth: 280 });
  //     CommentMention.mentionBox = new MentionBox({
  //       style: getStyle(position),
  //       boxType: 'comment',
  //       source: SOURCE_ENUM.DOC_COMMENT,
  //       ...props,
  //       onConfirm: function (evt) {
  //         const { type: actionType, token, chat_id: chatId } = evt.data || {};
  //         const _token = parseInt(actionType) === TYPE_ENUM.CHAT ? chatId : token;
  //         collectSuiteEvent('confirm_mention', {
  //           action: actionType, // 0 用户 1文档
  //           source: collectSource,
  //           zone,
  //           mention_type: getMentionType(actionType),
  //           mention_obj_id: encryptTea(_token),
  //         });
  //         CommentMention.addMention(evt.data, uuid, context);
  //         CommentMention.mentionBox.close();
  //       },
  //     });
  //   }
  // },
  isMentionBoxVisible: function isMentionBoxVisible() {
    return CommentMention.mentionBox && CommentMention.mentionBox.isVisiable();
  }
};

exports.default = CommentMention;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1648:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
var selectNetworkState = exports.selectNetworkState = function selectNetworkState(state) {
  return state.appState.networkState;
};

/***/ }),

/***/ 1666:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _container = __webpack_require__(1757);

var _container2 = _interopRequireDefault(_container);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _container2.default;

/***/ }),

/***/ 1669:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.MENU_LOOKUP_TABLE = exports.TEMPLATE_ID = exports.TOUTIAOQUAN_TEMPLATE_TEXT = exports.ICONS = exports.MINDNOTE = exports.EDIT_SAVE = exports.SAVE = exports.EDIT_DISABLE = exports.EDIT = exports.COPY_URL = exports.SHARE_TO_TOU_TIAO_QUAN = exports.SHARE_TO_LARK = exports.MORE_OPERATE_DISABLE = exports.MORE_OPERATE = exports.SHARE_DISABLE = exports.SHARE = undefined;

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _reduce2 = __webpack_require__(160);

var _reduce3 = _interopRequireDefault(_reduce2);

var _MENU_LOOKUP_TABLE;

var _iconHelper = __webpack_require__(750);

var _base64Helper = __webpack_require__(740);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SHARE = exports.SHARE = 'SHARE';
var SHARE_DISABLE = exports.SHARE_DISABLE = 'SHARE_DISABLE';
var MORE_OPERATE = exports.MORE_OPERATE = 'MORE_OPERATE'; // 更多 icon
var MORE_OPERATE_DISABLE = exports.MORE_OPERATE_DISABLE = 'MORE_OPERATE_DISABLE'; // 更多 icon 置灰

var SHARE_TO_LARK = exports.SHARE_TO_LARK = 'share_to_lark';
var SHARE_TO_TOU_TIAO_QUAN = exports.SHARE_TO_TOU_TIAO_QUAN = 'share_to_toutiao';

var COPY_URL = exports.COPY_URL = 'copy_link';

var EDIT = exports.EDIT = 'EDIT';
var EDIT_DISABLE = exports.EDIT_DISABLE = 'EDIT_DISABLE';
var SAVE = exports.SAVE = 'SAVE';
var EDIT_SAVE = exports.EDIT_SAVE = 'EDIT_SAVE';

var MINDNOTE = exports.MINDNOTE = 'MINDNOTE';

var ICONS = exports.ICONS = (0, _reduce3.default)([EDIT, SAVE, SHARE, MORE_OPERATE, MINDNOTE], function (memo, icon) {
  memo[icon] = (0, _iconHelper.getHeaderIcon)(icon);
  return memo;
}, {});

var TOUTIAOQUAN_TEMPLATE_TEXT = exports.TOUTIAOQUAN_TEMPLATE_TEXT = t('mobile.user_survey');
var TEMPLATE_ID = exports.TEMPLATE_ID = 'chunjie';

var getIcon = function getIcon(id, iconName) {
  var disabled = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;

  var status = disabled ? 'disable' : 'normal';
  return {
    id: id,
    disabled: disabled,
    imageBase64: (0, _base64Helper.transformBase64)(ICONS[iconName][status])
  };
};

var MENU_LOOKUP_TABLE = exports.MENU_LOOKUP_TABLE = (_MENU_LOOKUP_TABLE = {}, (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, SHARE, getIcon(SHARE, SHARE)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, SHARE_DISABLE, getIcon(SHARE, SHARE, true)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, MORE_OPERATE, getIcon(MORE_OPERATE, MORE_OPERATE)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, MORE_OPERATE_DISABLE, getIcon(MORE_OPERATE, MORE_OPERATE, true)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, MINDNOTE, getIcon(MINDNOTE, MINDNOTE)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, EDIT, getIcon(EDIT, EDIT)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, EDIT_SAVE, getIcon(EDIT, SAVE)), (0, _defineProperty3.default)(_MENU_LOOKUP_TABLE, EDIT_DISABLE, getIcon(EDIT, EDIT, true)), _MENU_LOOKUP_TABLE);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1670:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _MindNoteContext = __webpack_require__(1619);

var _MindNoteContext2 = _interopRequireDefault(_MindNoteContext);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _MindNoteContext2.default;

/***/ }),

/***/ 1695:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.CollabQueue = exports.ChangeSetType = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var ChangeSetType = exports.ChangeSetType = undefined;
(function (ChangeSetType) {
    ChangeSetType["DOC"] = "DOC";
    ChangeSetType["SHEET"] = "SHEET";
})(ChangeSetType || (exports.ChangeSetType = ChangeSetType = {}));

var CollabQueue = exports.CollabQueue = function () {
    function CollabQueue(editor) {
        (0, _classCallCheck3.default)(this, CollabQueue);

        this.queue = [];
        this.queueMap = new Map();
        this.isFiring = false;
        this.editor = editor;
    }

    (0, _createClass3.default)(CollabQueue, [{
        key: "push",
        value: function push(csType) {
            this.queue.push(csType);
            this.fireNext();
        }
    }, {
        key: "fireNext",
        value: function fireNext() {
            var _this = this;

            if (this.isFiring) {
                return;
            }
            var nextCSType = this.queue.shift();
            if (!this.queueMap.get(nextCSType)) {
                throw new Error('this.queueMap should contain queue type: ' + nextCSType);
            }
            this.isFiring = true;
            var csQueue = this.queueMap.get(nextCSType);
            var docVersion = this.editor.plugins.client.getRev();
            csQueue.sendNextCS(docVersion).finally(function () {
                _this.isFiring = false;
                if (_this.queue.length > 0) {
                    _this.fireNext();
                }
            });
        }
    }, {
        key: "registerCSQueue",
        value: function registerCSQueue(qc) {
            this.queueMap.set(qc.type, qc);
        }
    }]);
    return CollabQueue;
}();

/***/ }),

/***/ 1696:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 1697:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.docDeleteMentionIfNecessary = docDeleteMentionIfNecessary;
exports.docMoveCursorIfNecessary = docMoveCursorIfNecessary;
exports.getExtendedAttribs = getExtendedAttribs;
exports.performAtHolder = performAtHolder;
exports.performSpace = performSpace;
exports.performAt = performAt;
exports.findParentNodeFromClass = findParentNodeFromClass;

var _apis = __webpack_require__(1631);

var _uniqBy2 = __webpack_require__(391);

var _uniqBy3 = _interopRequireDefault(_uniqBy2);

var _filter2 = __webpack_require__(507);

var _filter3 = _interopRequireDefault(_filter2);

var _get2 = __webpack_require__(81);

var _get3 = _interopRequireDefault(_get2);

var _const = __webpack_require__(1581);

var _utils = __webpack_require__(1590);

var _string = __webpack_require__(1698);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function docDeleteMentionIfNecessary(context, callback) {
  var rep = context.rep,
      editorInfo = context.editorInfo,
      evt = context.evt;
  var selStart = rep.selStart,
      selEnd = rep.selEnd;

  var endMentionRep = void 0;
  var finalSelStart = selStart;
  var finalSelEnd = selEnd;

  var $mentionNode = (0, _utils.getPrevMentionFromFocus)();
  // 判断选取 || 删除的范围是否包含这个@ 包含就整个删除了
  var className = $mentionNode.attr('class');
  // 群卡片不在这里操作
  if (!$mentionNode.length || (0, _utils.getValByName)(className, 'mention-type') === String(_const.TYPE_ENUM.CHAT)) {
    return;
  }

  var startMentionRep = editorInfo.ace_domToRep($mentionNode.get(0));
  if (!startMentionRep) {
    return;
  }

  if ($mentionNode.get(1)) {
    endMentionRep = editorInfo.ace_domToRep($mentionNode.get(1));
  }

  if (startMentionRep.selStart[1] < selStart[1]) {
    finalSelStart = startMentionRep.selStart;
  }

  if (startMentionRep.selEnd[1] > selEnd[1] && startMentionRep.selEnd[0] >= selEnd[0]) {
    finalSelEnd = startMentionRep.selEnd;
  }

  if (endMentionRep && endMentionRep.selEnd[1] > selEnd[1]) {
    finalSelEnd = endMentionRep.selEnd;
  }

  editorInfo.ace_inCallStackIfNecessary('docDeleteMention', function () {
    editorInfo.dom ? editorInfo.ace_performDocumentReplaceRange(rep.zoneId, finalSelStart, finalSelEnd, '') : editorInfo.ace_performDocumentReplaceRange(finalSelStart, finalSelEnd, '');
  });
  editorInfo.ace_updateBrowserSelectionFromRep();

  var mentionId = (0, _utils.getValByName)(className, 'mention-id');
  var mentionTempId = (0, _utils.getValByName)(className, 'mention-tempId');
  var token = (0, _utils.getValByName)(className, 'mention-token');
  var type = (0, _utils.getValByName)(className, 'mention-type');
  evt.preventDefault();

  // todo fix 选区中包含多个@删除的情况 处理麻烦优先级不高
  if (mentionId && mentionId !== 'undefined' && type === _const.TYPE_ENUM.USER.toString()) {
    (0, _apis.notifyDelete)({ mention_id: mentionId, token: token, source: _const.SOURCE_ENUM.DOC, note_token: (0, _utils.getPageToken)() });
  }

  // 2018-09-07 添加删除mention回调
  if (mentionTempId && mentionTempId !== 'undefined' && (type === _const.TYPE_ENUM.USER.toString() || type === _const.TYPE_ENUM.GROUP.toString())) {
    // eslint-disable-next-line
    callback && callback({ type: type, mentionTempId: mentionTempId, mentionToken: token, fileToken: (0, _utils.getPageToken)() });
  }
  return true;
}

function docMoveCursorIfNecessary(context) {
  var evt = context.evt,
      editorInfo = context.editorInfo;
  var keyCode = evt.keyCode;

  var fakeTextNode = (0, _utils.getFakeTextNodeFromFocus)();
  editorInfo.fastIncorp();
  var rep = editorInfo.getRep();
  var targetNode = getTargetNodeFromFocus(keyCode);
  if (targetNode && fakeTextNode) {
    evt.preventDefault();
    if ((0, _utils.isFakeTextNode)(targetNode)) {
      var fakeNodeRep = editorInfo.ace_domToRep(targetNode);
      if (!fakeNodeRep) {
        return;
      }
      var point = [fakeNodeRep.selStart[0], fakeNodeRep.selStart[1]];
      editorInfo.selection.setWithSelection(rep.zoneId, point, point, false);
    }
    editorInfo.ace_updateBrowserSelectionFromRep();
  }
}

function getTargetNodeFromFocus(keyCode) {
  var LEFT = _const.KEYS.LEFT,
      RIGHT = _const.KEYS.RIGHT;

  var $mentionNode = void 0;
  if (keyCode === LEFT) {
    $mentionNode = (0, _utils.getPrevMentionFromFocus)();
    if ($mentionNode.length) {
      return $mentionNode.prev().get(0);
    }
  } else if (keyCode === RIGHT) {
    $mentionNode = (0, _utils.getNextMentionFromFocus)();
    if ($mentionNode.length) {
      return $mentionNode.next().get(0);
    }
  }
  return null;
}

function getExtendedAttribs(editorInfo) {
  var extendAttribs = (0, _get3.default)(editorInfo.ace_getAttributesOnSelection(), 'attribs') || [];
  extendAttribs = (0, _filter3.default)(extendAttribs, function (item) {
    var key = item[0];
    return ['backcolor', 'bold', 'italic', 'underline', 'strikethrough'].indexOf(key) > -1;
  }); // 将所有其他的属性 如行属性author等内容剔除掉
  return extendAttribs;
}

function _uniqAttrs(attrs) {
  return (0, _uniqBy3.default)(attrs, function (item) {
    return item[0];
  });
}

function performAtHolder(editorInfo, selStart, selEnd, text, attrs) {
  if (editorInfo.dom) {
    editorInfo.ace_performDocumentReplaceRangeWithAttributes(editorInfo.ace_getRep().zoneId, selStart, selEnd, text, _uniqAttrs(attrs));
  } else {
    editorInfo.ace_performDocumentReplaceRangeWithAttributes(selStart, selEnd, text, _uniqAttrs(attrs));
  }
  editorInfo.ace_updateBrowserSelectionFromRep();
}

function performSpace(editorInfo, selStart, selEnd, attrs) {
  editorInfo.ace_inCallStackIfNecessary('performSpace', function () {
    editorInfo.ace_makeNewEvent('nonundoable', function () {
      editorInfo.ace_fastIncorp(); // performSpace的时候使domClean = true
      if (editorInfo.dom) {
        editorInfo.ace_performDocumentReplaceRangeWithAttributes(editorInfo.ace_getRep().zoneId, selStart, selEnd, ' ', _uniqAttrs(attrs));
      } else {
        editorInfo.ace_performDocumentReplaceRangeWithAttributes(selStart, selEnd, ' ', _uniqAttrs(attrs));
      }
    });
  });
}

function performAt(editorInfo, selStart, selEnd, text, attrs) {
  var strArray = (0, _string.getSplitStringArray)(text, ' ');
  var ops = strArray.map(function (str, index) {
    return {
      start: selStart,
      end: index === 0 ? selEnd : selStart,
      newText: str,
      attributes: /^\n+$/.test(str) ? [] : _uniqAttrs(attrs)
    };
  });
  editorInfo.ace_callWithAce(function () {
    if (editorInfo.dom) {
      editorInfo.ace_performDocumentReplaceMultiRangeWithAttributes(editorInfo.ace_getRep().zoneId, ops);
    } else {
      editorInfo.ace_performDocumentReplaceMultiRangeWithAttributes(ops);
    }
  }, 'performAt', true);
}

function findParentNodeFromClass(node, classname) {
  var parentNode = null;
  var n = node;
  while (!parentNode && n) {
    if (n.classList && n.classList.contains(classname)) {
      parentNode = n;
    }
    n = n.parentNode;
  }
  return parentNode;
};

/***/ }),

/***/ 1698:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getSplitStringArray = getSplitStringArray;
exports.text2Array = text2Array;
/**
 * 分割字符串，获取操作数组
 *  @param {String} str 字符串
 *  @param {String} splitStr 分割的字符
 *  @param {array} attrs 属性数组
 *  @return {array}
 */
function getSplitStringArray(str, splitStr) {
  var result = [];
  if (!str || !str.length) return result;
  var _str = '';
  for (var i = 0; i < str.length; ++i) {
    if (str[i] !== splitStr) {
      _str += str[i];
    } else {
      if (_str) {
        result.push(_str);
        _str = '';
      }
      result.push(str[i]);
    }
  }
  if (_str) result.push(_str);
  return result;
}

function text2Array(text) {
  var arr = [];
  var str = '';
  text.split('').forEach(function (t) {
    if (t === '\n') {
      if (str) {
        arr.push(str);
        str = '';
      }
      arr.push(t);
    } else {
      str += t;
    }
  });
  if (str) {
    arr.push(str);
  }
  return arr;
}

/***/ }),

/***/ 1699:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _assign2 = __webpack_require__(506);

var _assign3 = _interopRequireDefault(_assign2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var chatInfoCache = {}; /**
                         * 统一数据源
                         * 所有的群名片在这里管理
                         */

var BaseChatStatus = {
  init: function init(context) {},
  reset: function reset() {
    chatInfoCache = {};
  },
  setCacheInfo: function setCacheInfo(filtedInfos) {
    (0, _assign3.default)(chatInfoCache, filtedInfos);
  },
  getCacheInfo: function getCacheInfo(token) {
    return chatInfoCache[token];
  },
  getAllCacheInfo: function getAllCacheInfo() {
    return chatInfoCache;
  }
};

exports.default = BaseChatStatus;

/***/ }),

/***/ 1700:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
var getSingleLineText = exports.getSingleLineText = function getSingleLineText(rep, dRep) {
  var _ref = dRep || rep,
      selStart = _ref.selStart,
      selEnd = _ref.selEnd;

  var lineEntry = rep.lines.atIndex(rep.selEnd[0]) || {};
  var lineText = lineEntry.text,
      lineMarker = lineEntry.lineMarker;

  var textLen = (lineText || '').length;
  var lineCount = rep.lines.length();
  var isNotTail = selEnd[1] < textLen;
  var text = ' ';

  if (!selStart || !selEnd) return '\n \n';

  // 标题行不可添加
  if (selStart[0] === 0) {
    text = '\n' + text;
  }

  // 不是本行开头 插入一个前置\n 换行

  if (selStart[1] > lineMarker) {
    text = '\n ';
  }

  // 不是本行末尾 || 是最后一行 （插入一个\n)换行
  if (isNotTail || selEnd[0] + 1 === lineCount) {
    text += '\n';
  }

  // 下一行是图片 群卡片之类，加一个空行
  var nextLineAttrs = rep.attributeManager.getAllAttributesOnLine(selStart[0] + 1);
  var attribKeys = getAttributeKey(nextLineAttrs);
  if (attribKeys['gallery'] || attribKeys['image-previewer']) {
    if (text.slice(-1) !== '\n') {
      text += '\n';
    }
  }

  var node = lineEntry.lineNode;
  if ((node.className || '').indexOf('tp-sub') > -1) {
    text = '\n \n';
  }

  return text;
};

function getAttributeKey(attrs) {
  var ret = {};
  if (!attrs) return ret;
  for (var i = 0, len = attrs.length; i < len; i++) {
    ret[attrs[i][0]] = true;
  }
  return ret;
}

/***/ }),

/***/ 1702:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
var handlersMap = {};
var oldHandlerMap = {};
var registedMap = {};
// isReplace的意思是重写覆盖
function register(key, handler) {
    var isReplace = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;

    if (!key || !handler) return false;
    if (key.indexOf('window.') === 0) {
        key = key.replace('window.', '');
    }
    var hostObj = getApiHostObj(key);
    var props = key.split('.');
    var apiName = props[props.length - 1];
    if (!hostObj || !apiName) return false;
    handler.isReplace = isReplace;
    // 已经有地方调用注册过了
    if (hostObj[apiName] && registedMap[key]) {
        var handlers = handlersMap[key];
        handlers.push(handler);
    } else {
        // 第一次注册
        handlersMap[key] = [handler];
        registedMap[key] = true;
        oldHandlerMap[key] = hostObj[apiName]; // 存下之前的，兼容处理，全部unregister之后设回去
        hostObj[apiName] = function () {
            var args = arguments;
            var handlers = handlersMap[key];
            var topFirstHandler = void 0; // 最后入队的isReplace为true的handler
            for (var i = handlers.length - 1; i >= 0; i--) {
                var fn = handlers[i];
                if (typeof fn === 'function' && fn.isReplace) {
                    topFirstHandler = fn;
                    break;
                }
            }
            // 覆盖式回调，只执行它，别的忽略
            if (topFirstHandler) {
                return topFirstHandler.apply(null, args);
            }
            // 调一下之前的
            oldHandlerMap[key] && oldHandlerMap[key].apply(null, args);
            handlersMap[key].forEach(function (fn) {
                if (typeof fn === 'function') {
                    return fn.apply(null, args);
                }
            });
        };
    }
    return true;
}
function getApiHostObj(key) {
    if (!key) return null;
    var props = key.split('.');
    if (props.length === 0) return null;
    var hostObj = window;
    for (var i = 0; i < props.length - 1; i++) {
        var prop = props[i];
        if (!hostObj[prop]) {
            return null;
        } else {
            hostObj = hostObj[prop];
        }
    }
    return hostObj;
}
function unregister(key, handler) {
    var result = true;
    if (!key) return false;
    if (key.indexOf('window.') === 0) {
        key = key.replace('window.', '');
    }
    if (!handlersMap[key]) return false;
    // 没有handler就unregister all
    if (!handler) {
        handlersMap[key].length = 0;
        registedMap[key] = false;
    } else {
        delete handler.isReplace;
        var handlers = handlersMap[key] || [];
        if (handlers.length > 0) {
            var newHandlers = handlers.filter(function (fn) {
                return fn !== handler;
            });
            handlersMap[key] = newHandlers;
            if (newHandlers.length === 0) {
                registedMap[key] = false;
            }
            result = newHandlers.length < handlers.length ? true : false;
        }
    }
    // 恢复初始状态
    if (!registedMap[key]) {
        var hostObj = getApiHostObj(key);
        if (hostObj) {
            var props = key.split('.');
            var apiName = props[props.length - 1];
            hostObj[apiName] = oldHandlerMap[key] || function () {
                // noop
            };
            delete oldHandlerMap[key];
        }
    }
    return result;
}
var JsBridgeManager = exports.JsBridgeManager = {
    register: register,
    unregister: unregister
};

/***/ }),

/***/ 1705:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.fixShareUrl = fixShareUrl;
exports.reload = reload;

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function fixShareUrl(url) {
    if (url) {
        return url.replace(/docsource:/, 'https:');
    }
    return url;
}
function reload() {
    if (_browserHelper2.default.isAndroid) {
        window.clear && window.clear();
        window.replace && window.replace(location.pathname + location.search + location.hash);
    } else {
        location.reload(true);
    }
}

/***/ }),

/***/ 1706:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _regenerator = __webpack_require__(13);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _isEqual2 = __webpack_require__(501);

var _isEqual3 = _interopRequireDefault(_isEqual2);

var _noop2 = __webpack_require__(383);

var _noop3 = _interopRequireDefault(_noop2);

var _class, _temp;
/* eslint-disable */


var _react = __webpack_require__(1);

var _constants = __webpack_require__(1669);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _share = __webpack_require__(1766);

var _share2 = _interopRequireDefault(_share);

var _eventEmitter = __webpack_require__(272);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

var _events = __webpack_require__(273);

var _events2 = _interopRequireDefault(_events);

var _offlineCreateHelper = __webpack_require__(379);

var _sdkCompatibleHelper = __webpack_require__(82);

var _tea = __webpack_require__(47);

var _urlHelper = __webpack_require__(184);

var _suiteHelper = __webpack_require__(60);

var _mindNoteContext = __webpack_require__(1670);

var _mindNoteContext2 = _interopRequireDefault(_mindNoteContext);

var _MindNoteContext = __webpack_require__(1619);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var PARTIAL_LOADING_STATUS_CHANGE = 'PARTIAL_LOADING_STATUS_CHANGE';

var AppHeader = (_temp = _class = function (_PureComponent) {
  (0, _inherits3.default)(AppHeader, _PureComponent);

  function AppHeader(props) {
    var _this2 = this;

    (0, _classCallCheck3.default)(this, AppHeader);

    var _this = (0, _possibleConstructorReturn3.default)(this, (AppHeader.__proto__ || Object.getPrototypeOf(AppHeader)).call(this, props));

    _this.handleWindowUnload = function () {
      _this.setMenu([], (0, _noop3.default)());
    };

    _this.getNodeToken = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee() {
      var _this$props, onLine, getTokenInfo, token, type, _ref2, items;

      return _regenerator2.default.wrap(function _callee$(_context) {
        while (1) {
          switch (_context.prev = _context.next) {
            case 0:
              console.log('isPreventGetTokenInfo');
              console.log(_sdkCompatibleHelper.isPreventGetTokenInfo);

              if (!(_sdkCompatibleHelper.isPreventGetTokenInfo || (0, _suiteHelper.isMindNote)())) {
                _context.next = 4;
                break;
              }

              return _context.abrupt('return');

            case 4:
              _this$props = _this.props, onLine = _this$props.onLine, getTokenInfo = _this$props.getTokenInfo;

              if (!(onLine && !_this.nodeToken)) {
                _context.next = 13;
                break;
              }

              token = (0, _suiteHelper.getToken)();
              type = (0, _suiteHelper.suiteType)() === 'doc' ? 2 : 3;
              _context.next = 10;
              return getTokenInfo(token, type);

            case 10:
              _ref2 = _context.sent;
              items = _ref2.payload.items;
              // doc 2 sheet 3
              _this.nodeToken = items.length ? items[0] : null;

            case 13:
              return _context.abrupt('return', _this.nodeToken);

            case 14:
            case 'end':
              return _context.stop();
          }
        }
      }, _callee, _this2);
    }));

    _this.handleMenuClick = function (data) {
      if (!data || !data.id) {
        return;
      }

      var editor = _this.props.editor;

      var clickedItem = _this.__items.find(function (item) {
        return item.id === data.id;
      });
      var itemDisabled = clickedItem.disabled;

      if (itemDisabled) {
        return;
      }
      // 派发clickMenu事件
      editor && editor.call('clickMenu');
      if (_sdkCompatibleHelper.isSupportClickToEdit) {
        // 触发 appEditControl.js 中 setReadMode 方法。
        _eventEmitter2.default.trigger(_events2.default.MOBILE.COMMON.END_EDIT, [{ reportEvent: data.id === _constants.SHARE ? 'click_share' : 'click_file_manage' }]);
      }

      switch (data.id) {
        case _constants.EDIT:
          _this.handleEditClick(data);
          break;
        case _constants.SHARE:
          _this.handleShareClick(data);
          break;
        case _constants.MORE_OPERATE:
          // todo 加统计
          _this.handleMoreOperateClick(data);
          break;
        default:
          break;
      }
    };

    _this.handleEditClick = function (data) {
      var editor = _this.props.editor;

      if (editor && editor.isEditing()) {
        _eventEmitter2.default.trigger(_events2.default.MOBILE.COMMON.END_EDIT);

        (0, _tea.collectSuiteEvent)('finish_edit', {
          template_id: _this.props.isTemplate ? _constants.TEMPLATE_ID : ''
        });
      } else {
        _eventEmitter2.default.trigger(_events2.default.MOBILE.COMMON.BEGIN_EDIT);

        (0, _tea.collectSuiteEvent)('start_edit', {
          template_id: _this.props.isTemplate ? _constants.TEMPLATE_ID : ''
        });
      }
      _this.setHeaderMenu();
    };

    _this.handleShareClick = function (data) {
      var _this$props2 = _this.props,
          currentNote = _this$props2.currentNote,
          isTemplate = _this$props2.isTemplate,
          editor = _this$props2.editor;

      var share = _share2.default.create({
        currentNote: currentNote,
        isTemplate: isTemplate,
        defaultTitle: t('common.unnamed_document')
      });
      return share.handleShareClick(editor);
    };

    _this.handleMoreOperateClick = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2() {
      var nodeToken;
      return _regenerator2.default.wrap(function _callee2$(_context2) {
        while (1) {
          switch (_context2.prev = _context2.next) {
            case 0:
              if (_sdkCompatibleHelper.isSupportClickToEdit) {
                _context2.next = 2;
                break;
              }

              return _context2.abrupt('return', _this.handleShareClick());

            case 2:
              nodeToken = _this.nodeToken;

              if (nodeToken) {
                _context2.next = 7;
                break;
              }

              _context2.next = 6;
              return _this.getNodeToken();

            case 6:
              nodeToken = _context2.sent;

            case 7:
              window.lark.biz.util.more(nodeToken);

            case 8:
            case 'end':
              return _context2.stop();
          }
        }
      }, _callee2, _this2);
    }));

    _this.isEditable = function () {
      var _this$props3 = _this.props,
          onLine = _this$props3.onLine,
          hasWritePermission = _this$props3.hasWritePermission;

      return onLine && hasWritePermission || (0, _offlineCreateHelper.isOfflineCreateDoc)();
    };

    _this.setHeaderMenu = function (disable) {
      var _this$props4 = _this.props,
          onLine = _this$props4.onLine,
          messageShowing = _this$props4.messageShowing,
          editor = _this$props4.editor;

      var editIcon = _constants.EDIT;
      var shareIcon = _constants.SHARE;
      var moreOperateIcon = _constants.MORE_OPERATE;
      var mindNoteIcon = null;
      /**
       * 是否全量兼容单击进入编辑态
       * 1. 是： 图标为 分享 和 更多
       * 2. 否： 图片为 编辑 和 更多， 点击更多的操作为分享
       */
      if (_sdkCompatibleHelper.isSupportClickToEdit) {
        if (!onLine || (0, _offlineCreateHelper.isOfflineCreateDoc)()) {
          shareIcon = _constants.SHARE_DISABLE;
          moreOperateIcon = _constants.MORE_OPERATE_DISABLE;
        }
        editIcon = null;
      } else {
        if (editor && editor.isEditing()) {
          editIcon = _constants.EDIT_SAVE;
        }
        if (!_this.isEditable() || messageShowing) {
          editIcon = _constants.EDIT_DISABLE;
        }
        if (!onLine) {
          editIcon = _constants.EDIT_DISABLE;
          moreOperateIcon = _constants.MORE_OPERATE_DISABLE;
        }
        // sheet 中没有 editor， Lark1.16 之前 sheet 没有编辑按钮
        if (!editor) {
          editIcon = null;
        }
        shareIcon = null;
      }

      var hanlder = _this.handleMenuClick;
      if (disable) {
        shareIcon = _constants.SHARE_DISABLE;
        moreOperateIcon = _constants.MORE_OPERATE_DISABLE;
        hanlder = _noop3.default;
      }

      // 最佳实践内不显示右上角的按钮。
      if ((0, _urlHelper.parseQuery)(window.location.search).tt) {
        editIcon = null;
        shareIcon = null;
        moreOperateIcon = null;
        hanlder = _noop3.default;
      }
      // 思维笔记
      if ((0, _suiteHelper.isMindNote)()) {
        editIcon = null;
        shareIcon = _constants.SHARE;
        mindNoteIcon = _constants.MINDNOTE;
        hanlder = function hanlder(data) {
          if (data.id === _constants.MINDNOTE) {
            var mindNoteContext = _mindNoteContext2.default.getInstance();
            mindNoteContext.trigger(_MindNoteContext.MindNoteEvent.OPEN_MINDMAP);
            window.lark.biz.util.toggleTitlebar({
              states: 0
            });
            document.querySelector('html').classList.add('openMap');
          } else {
            _this.handleMenuClick(data);
          }
        };
      }
      var menu = [];
      [editIcon, mindNoteIcon, shareIcon, moreOperateIcon].forEach(function (item) {
        item && menu.push(_constants.MENU_LOOKUP_TABLE[item]);
      });

      _this.setMenu(menu, hanlder);
    };

    _this.setMenu = function (items, onClick) {
      if ((0, _isEqual3.default)(_this.__items, items)) {
        return;
      }

      _this.__items = items;

      window.lark.biz.navigation.setMenu({
        items: items,
        onSuccess: function onSuccess(data) {
          onClick(data);
        }
      });
    };

    _this.__items = [];
    _this.nodeToken = null;
    return _this;
  }

  (0, _createClass3.default)(AppHeader, [{
    key: 'componentDidMount',
    value: function componentDidMount() {
      window.addEventListener('unload', this.handleWindowUnload);
      this.getNodeToken();
      this.setHeaderMenu();
      _eventEmitter2.default.on(_events2.default.MOBILE.DOCS.CREATE_SUCCESS, this.setHeaderMenu);
      if (!_sdkCompatibleHelper.isSupportClickToEdit) {
        // 都是热更新惹的祸
        _eventEmitter2.default.on(_events2.default.MOBILE.COMMON.SET_MENU, this.setHeaderMenu);
      }
      // 分块 loading 按钮置灰
      this.props.editor && this.props.editor.on(PARTIAL_LOADING_STATUS_CHANGE, this.setHeaderMenu);
    }
  }, {
    key: 'componentDidUpdate',
    value: function componentDidUpdate() {
      this.getNodeToken();
      this.setHeaderMenu();
    }
  }, {
    key: 'componentWillUnmount',
    value: function componentWillUnmount() {
      this.setMenu([], (0, _noop3.default)());
      window.removeEventListener('unload', this.handleWindowUnload);
      if (!_sdkCompatibleHelper.isSupportClickToEdit) {
        _eventEmitter2.default.off(_events2.default.MOBILE.COMMON.SET_MENU, this.setHeaderMenu);
      }
      _eventEmitter2.default.off(_events2.default.MOBILE.DOCS.CREATE_SUCCESS, this.setHeaderMenu);
      this.props.editor && this.props.editor.off(PARTIAL_LOADING_STATUS_CHANGE, this.setHeaderMenu);
    }

    // 设置header图标

  }, {
    key: 'render',
    value: function render() {
      return null;
    }
  }]);
  return AppHeader;
}(_react.PureComponent), _class.propTypes = {
  currentNote: _propTypes2.default.object,
  isTemplate: _propTypes2.default.bool,
  onLine: _propTypes2.default.bool,
  editor: _propTypes2.default.object,
  getTokenInfo: _propTypes2.default.func,
  messageShowing: _propTypes2.default.bool,
  hasWritePermission: _propTypes2.default.bool
}, _temp);
exports.default = AppHeader;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1740:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.fetchChatInfo = fetchChatInfo;
exports.updateChatsStatus = updateChatsStatus;

var _each2 = __webpack_require__(716);

var _each3 = _interopRequireDefault(_each2);

var _pick2 = __webpack_require__(719);

var _pick3 = _interopRequireDefault(_pick2);

var _forEach2 = __webpack_require__(239);

var _forEach3 = _interopRequireDefault(_forEach2);

var _keys2 = __webpack_require__(138);

var _keys3 = _interopRequireDefault(_keys2);

var _chatStatusManage = __webpack_require__(1699);

var _chatStatusManage2 = _interopRequireDefault(_chatStatusManage);

var _index = __webpack_require__(1598);

var _offlineEditHelper = __webpack_require__(377);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function fetchChatInfo(param) {
  var method = 'POST';
  var contentType = 'application/json';

  return (0, _offlineEditHelper.fetch)('/api/mention/chat.info.v2/', {
    key: 'chat.info.v2',
    body: param,
    method: method,
    contentType: contentType
  }).then(function (res) {
    if (res.code === 0) {
      (0, _each3.default)(res.data, function (info) {
        info.hasjoin = info['has_join'];
      });
    }
    return res;
  });
}

function updateChatsStatus(editor, chatIds, source) {
  var updateChat = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : function () {};
  var parentCls = arguments[4];

  if (!chatIds.length) {
    return;
  }

  var allCacheInfos = _chatStatusManage2.default.getAllCacheInfo();
  var chatIdInCache = (0, _pick3.default)(allCacheInfos, chatIds);

  if ((0, _keys3.default)(chatIdInCache).length === chatIds.length) {
    (0, _forEach3.default)(chatIdInCache, function (info, chatId) {
      updateChat(editor, chatId, info, parentCls);
    });

    return;
  }
  // todo 缓存chatId对应的 infos
  var token = (0, _index.getPageToken)();
  fetchChatInfo({ chat_ids: chatIds, source: source, token: token }).then(function (ret) {
    if (ret.code) return;
    _chatStatusManage2.default.setCacheInfo(ret.data);

    (0, _forEach3.default)(ret.data, function (info, chatId) {
      updateChat(editor, chatId, info, parentCls);
    });
  });
}

/***/ }),

/***/ 1742:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _bytedXEditor = __webpack_require__(1569);

var _sendCollectorData = __webpack_require__(1577);

var _sendCollectorData2 = _interopRequireDefault(_sendCollectorData);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var getHotKeyName = _bytedXEditor.hotkeys.getHotKeyName,
    UNDO = _bytedXEditor.hotkeys.UNDO;

var Undo = function Undo(props) {
  var _this = this;

  (0, _classCallCheck3.default)(this, Undo);

  this.aceKeyEvent = function (hook, context) {
    var evt = context.evt,
        isTypeForSpecialKey = context.isTypeForSpecialKey;

    // 在keydown的时候触发快捷键，避免keyup触发。导致多次触发

    if (getHotKeyName(evt) === UNDO && isTypeForSpecialKey) {
      _this.editor.triggerCommand(UNDO);
      evt.preventDefault();
      return true;
    }
    return false;
  };

  this.editor = props.editor;
  this.editor.registerCommand(UNDO, function (cmdName, editor) {
    editor.doUndoRedo(cmdName);
    (0, _sendCollectorData2.default)(cmdName);
  });
};

exports.default = Undo;

/***/ }),

/***/ 1743:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _bytedXEditor = __webpack_require__(1569);

var _sendCollectorData = __webpack_require__(1577);

var _sendCollectorData2 = _interopRequireDefault(_sendCollectorData);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var getHotKeyName = _bytedXEditor.hotkeys.getHotKeyName,
    REDO = _bytedXEditor.hotkeys.REDO;

var Redo = function Redo(props) {
  var _this = this;

  (0, _classCallCheck3.default)(this, Redo);

  this.aceKeyEvent = function (hook, context) {
    var evt = context.evt;

    if (getHotKeyName(evt) === REDO) {
      evt.preventDefault();
      _this.editor.triggerCommand(REDO);
      return true;
    }
    return false;
  };

  this.editor = props.editor;
  this.editor.registerCommand(REDO, function (cmdName, editor) {
    editor.doUndoRedo(cmdName);
    (0, _sendCollectorData2.default)(cmdName);
  });
};

exports.default = Redo;

/***/ }),

/***/ 1744:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _sendCollectorData = __webpack_require__(1577);

var _sendCollectorData2 = _interopRequireDefault(_sendCollectorData);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Indent = function Indent(props) {
  var _this = this;

  (0, _classCallCheck3.default)(this, Indent);

  this.doIndent = function (isLeft) {
    _this.editor.inCallStackIfNecessary('fastIncorp', function () {
      _this.editor.fastIncorp();
    });
    _this.editor.doTabKey({
      shiftKey: isLeft,
      stopImmediatePropagation: function stopImmediatePropagation() {}
    });
    (0, _sendCollectorData2.default)((isLeft ? 'Shift-' : '') + 'tab');
  };

  this.editor = props.editor;
  this.editor.registerCommand('indentleft', function (cmdName, editor) {
    _this.doIndent(true);
  });
  this.editor.registerCommand('indentright', function (cmdName, editor) {
    _this.doIndent();
  });
};

exports.default = Indent;

/***/ }),

/***/ 1746:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.toPlanbAtType = exports.PLANB_AT_TYPE = undefined;

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _regenerator = __webpack_require__(13);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _toPlanbAtType, _PlanB$GUIDE_TEXT;

var _$store = __webpack_require__(83);

var _$store2 = _interopRequireDefault(_$store);

var _dynamicCss = __webpack_require__(1886);

var _dynamicCss2 = _interopRequireDefault(_dynamicCss);

var _abTestHelper = __webpack_require__(738);

var _share = __webpack_require__(375);

var _guide = __webpack_require__(514);

var _guide2 = __webpack_require__(244);

var _const = __webpack_require__(1581);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

/**
 * 提供 AB 实验通用的接口和内部方法
 * 实验文档：https://docs.bytedance.net/doc/CNHG9By4CyLQrwCWMFrIOa
 */
var PlaceholderABTest = function () {
    function PlaceholderABTest() {
        var _this = this;

        (0, _classCallCheck3.default)(this, PlaceholderABTest);

        this.isGuideDone = function (guide) {
            var guides = _this.getCurGuides();
            return guides.getIn([guide, 'is_done']) !== false;
        };
        this.updated = false;
    }

    (0, _createClass3.default)(PlaceholderABTest, [{
        key: 'getBodyId',
        value: function getBodyId() {
            return document.body.id ? '#' + document.body.id : '';
        }
        /**
         * 覆盖了 ./note_title.less 和 src/common/styles/i18n.less 里的规则
         */

    }, {
        key: 'genTitleRule',
        value: function genTitleRule(content) {
            var id = this.getBodyId();
            return '\n    ' + id + ' #innerdocbody.innerdocbody.blank-title.docbody--write[contenteditable=true]>div:first-child::before {\n      content: "' + content + '";\n    }';
        }
        /**
         * 覆盖了 ./note_title.less 和 src/common/styles/i18n.less 里的规则
         */

    }, {
        key: 'genBodyRule',
        value: function genBodyRule(content) {
            var id = this.getBodyId();
            return '\n    ' + id + ' #innerdocbody.innerdocbody.blank-body.docbody--write[contenteditable=true]>div:nth-child(2)::before {\n      content: "' + content + '";\n    }';
        }
    }, {
        key: 'setPlaceholder',
        value: function setPlaceholder(body) {
            var title = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : null;

            _dynamicCss2.default.deleteRuleById(PlaceholderABTest.BODY_PLACEHOLDER_RULE_ID);
            _dynamicCss2.default.insertRule(this.genBodyRule(body), PlaceholderABTest.BODY_PLACEHOLDER_RULE_ID);
            if (title !== null) {
                _dynamicCss2.default.deleteRuleById(PlaceholderABTest.TITLE_PLACEHOLDER_RULE_ID);
                _dynamicCss2.default.insertRule(this.genTitleRule(title), PlaceholderABTest.TITLE_PLACEHOLDER_RULE_ID);
            }
        }
    }, {
        key: 'clearPlaceholder',
        value: function clearPlaceholder() {
            _dynamicCss2.default.deleteRuleById(PlaceholderABTest.BODY_PLACEHOLDER_RULE_ID);
            _dynamicCss2.default.deleteRuleById(PlaceholderABTest.TITLE_PLACEHOLDER_RULE_ID);
        }
    }, {
        key: 'fetchGuidesAPI',
        value: function () {
            var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee() {
                return _regenerator2.default.wrap(function _callee$(_context) {
                    while (1) {
                        switch (_context.prev = _context.next) {
                            case 0:
                                return _context.abrupt('return', _$store2.default.dispatch((0, _guide2.fetchUserGuide)()));

                            case 1:
                            case 'end':
                                return _context.stop();
                        }
                    }
                }, _callee, this);
            }));

            function fetchGuidesAPI() {
                return _ref.apply(this, arguments);
            }

            return fetchGuidesAPI;
        }()
    }, {
        key: 'getCurGuides',
        value: function getCurGuides() {
            return (0, _guide.selectUserGuide)(_$store2.default.getState());
        }
    }, {
        key: 'clearUpdated',
        value: function clearUpdated() {
            this.updated = false;
        }
    }, {
        key: 'updateGuideAPI',
        value: function () {
            var _ref2 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2(guide) {
                return _regenerator2.default.wrap(function _callee2$(_context2) {
                    while (1) {
                        switch (_context2.prev = _context2.next) {
                            case 0:
                                // 假设更新成功，同时也有加锁的作用
                                this.updated = true;
                                _context2.prev = 1;
                                _context2.next = 4;
                                return _$store2.default.dispatch((0, _guide2.updateUserGuide)(guide));

                            case 4:
                                _context2.next = 10;
                                break;

                            case 6:
                                _context2.prev = 6;
                                _context2.t0 = _context2['catch'](1);

                                this.updated = false;
                                throw _context2.t0;

                            case 10:
                            case 'end':
                                return _context2.stop();
                        }
                    }
                }, _callee2, this, [[1, 6]]);
            }));

            function updateGuideAPI(_x2) {
                return _ref2.apply(this, arguments);
            }

            return updateGuideAPI;
        }()
    }, {
        key: 'markGuideAsDoneAPI',
        value: function () {
            var _ref3 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee3(guide) {
                return _regenerator2.default.wrap(function _callee3$(_context3) {
                    while (1) {
                        switch (_context3.prev = _context3.next) {
                            case 0:
                                return _context3.abrupt('return', _$store2.default.dispatch((0, _guide2.closeUserGuide)(guide)));

                            case 1:
                            case 'end':
                                return _context3.stop();
                        }
                    }
                }, _callee3, this);
            }));

            function markGuideAsDoneAPI(_x3) {
                return _ref3.apply(this, arguments);
            }

            return markGuideAsDoneAPI;
        }()
        /**
         * 不是移动端且有编辑权限才进行实验
         */

    }, {
        key: 'canStart',
        value: function canStart() {
            return !_browserHelper2.default.isMobile && (0, _share.ifhaveEditPermission)(_$store2.default.getState());
        }
    }, {
        key: 'isUpdated',
        get: function get() {
            return this.updated;
        }
    }]);
    return PlaceholderABTest;
}();

PlaceholderABTest.TITLE_PLACEHOLDER_RULE_ID = 'TITLE_PLACEHOLDER_RULE_ID';
PlaceholderABTest.BODY_PLACEHOLDER_RULE_ID = 'BODY_PLACEHOLDER_RULE_ID';
/**
 * Plan A 同时使用 title 和 body 的 placeholder 进行引导，但只有一种文案
 */

var PlanA = function (_PlaceholderABTest) {
    (0, _inherits3.default)(PlanA, _PlaceholderABTest);

    function PlanA() {
        (0, _classCallCheck3.default)(this, PlanA);

        var _this2 = (0, _possibleConstructorReturn3.default)(this, (PlanA.__proto__ || Object.getPrototypeOf(PlanA)).apply(this, arguments));

        _this2.isDone = true;
        return _this2;
    }

    (0, _createClass3.default)(PlanA, [{
        key: 'start',
        value: function () {
            var _ref4 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee4() {
                return _regenerator2.default.wrap(function _callee4$(_context4) {
                    while (1) {
                        switch (_context4.prev = _context4.next) {
                            case 0:
                                if (this.canStart()) {
                                    _context4.next = 2;
                                    break;
                                }

                                return _context4.abrupt('return');

                            case 2:
                                this.init();

                            case 3:
                            case 'end':
                                return _context4.stop();
                        }
                    }
                }, _callee4, this);
            }));

            function start() {
                return _ref4.apply(this, arguments);
            }

            return start;
        }()
    }, {
        key: 'update',
        value: function () {
            var _ref5 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee5() {
                return _regenerator2.default.wrap(function _callee5$(_context5) {
                    while (1) {
                        switch (_context5.prev = _context5.next) {
                            case 0:
                                if (!(this.isDone || this.isUpdated)) {
                                    _context5.next = 2;
                                    break;
                                }

                                return _context5.abrupt('return');

                            case 2:
                                _context5.next = 4;
                                return this.updateGuideAPI(PlanA.ATPLACEHOLDER_AT_KEY);

                            case 4:
                            case 'end':
                                return _context5.stop();
                        }
                    }
                }, _callee5, this);
            }));

            function update() {
                return _ref5.apply(this, arguments);
            }

            return update;
        }()
    }, {
        key: 'markAsDone',
        value: function () {
            var _ref6 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee6(key) {
                return _regenerator2.default.wrap(function _callee6$(_context6) {
                    while (1) {
                        switch (_context6.prev = _context6.next) {
                            case 0:
                            case 'end':
                                return _context6.stop();
                        }
                    }
                }, _callee6, this);
            }));

            function markAsDone(_x4) {
                return _ref6.apply(this, arguments);
            }

            return markAsDone;
        }()
    }, {
        key: 'init',
        value: function init() {
            this.clearPlaceholder();
            this.clearUpdated();
            this.isDone = this.isGuideDone(PlanA.ATPLACEHOLDER_AT_KEY);
            if (!this.isDone) {
                // 显示 placeholder 引导
                this.setPlaceholder(t('abtest.atplaceholder.a.at.body'), t('abtest.atplaceholder.a.at.title'));
            }
        }
    }]);
    return PlanA;
}(PlaceholderABTest);

PlanA.ATPLACEHOLDER_AT_KEY = 'atplaceholder_a_at';
var PLANB_AT_TYPE = exports.PLANB_AT_TYPE = undefined;
(function (PLANB_AT_TYPE) {
    PLANB_AT_TYPE["GROUP"] = "atplaceholder_b_at_group";
    PLANB_AT_TYPE["DOC"] = "atplaceholder_b_at_doc";
    PLANB_AT_TYPE["GROUP_CARD"] = "atplaceholder_b_at_group_card";
    PLANB_AT_TYPE["SHEET"] = "atplaceholder_b_at_sheet";
    PLANB_AT_TYPE["FILE"] = "atplaceholder_b_at_file";
})(PLANB_AT_TYPE || (exports.PLANB_AT_TYPE = PLANB_AT_TYPE = {}));
var toPlanbAtType = exports.toPlanbAtType = (_toPlanbAtType = {}, (0, _defineProperty3.default)(_toPlanbAtType, _const.TYPE_ENUM.GROUP, PLANB_AT_TYPE.GROUP), (0, _defineProperty3.default)(_toPlanbAtType, _const.TYPE_ENUM.FILE, PLANB_AT_TYPE.DOC), (0, _defineProperty3.default)(_toPlanbAtType, _const.TYPE_ENUM.SHEET, PLANB_AT_TYPE.DOC), (0, _defineProperty3.default)(_toPlanbAtType, _const.TYPE_ENUM.CHAT, PLANB_AT_TYPE.GROUP_CARD), _toPlanbAtType);
/**
 * Plan B 只使用 body 的 placeholder 进行引导，分多种文案
 */

var PlanB = function (_PlaceholderABTest2) {
    (0, _inherits3.default)(PlanB, _PlaceholderABTest2);

    function PlanB() {
        (0, _classCallCheck3.default)(this, PlanB);
        return (0, _possibleConstructorReturn3.default)(this, (PlanB.__proto__ || Object.getPrototypeOf(PlanB)).apply(this, arguments));
    }

    (0, _createClass3.default)(PlanB, [{
        key: 'start',
        value: function () {
            var _ref7 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee7() {
                return _regenerator2.default.wrap(function _callee7$(_context7) {
                    while (1) {
                        switch (_context7.prev = _context7.next) {
                            case 0:
                                if (this.canStart()) {
                                    _context7.next = 2;
                                    break;
                                }

                                return _context7.abrupt('return');

                            case 2:
                                this.init();

                            case 3:
                            case 'end':
                                return _context7.stop();
                        }
                    }
                }, _callee7, this);
            }));

            function start() {
                return _ref7.apply(this, arguments);
            }

            return start;
        }()
    }, {
        key: 'update',
        value: function () {
            var _ref8 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee8() {
                return _regenerator2.default.wrap(function _callee8$(_context8) {
                    while (1) {
                        switch (_context8.prev = _context8.next) {
                            case 0:
                                if (!(this.isDone || this.isUpdated)) {
                                    _context8.next = 2;
                                    break;
                                }

                                return _context8.abrupt('return');

                            case 2:
                                _context8.next = 4;
                                return this.updateGuideAPI(this.curGuide);

                            case 4:
                            case 'end':
                                return _context8.stop();
                        }
                    }
                }, _callee8, this);
            }));

            function update() {
                return _ref8.apply(this, arguments);
            }

            return update;
        }()
    }, {
        key: 'markAsDone',
        value: function () {
            var _ref9 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee9(guide) {
                return _regenerator2.default.wrap(function _callee9$(_context9) {
                    while (1) {
                        switch (_context9.prev = _context9.next) {
                            case 0:
                                if (!(this.isDone || !PlanB.GUIDE_TYPES.includes(guide) || this.isGuideDone(guide))) {
                                    _context9.next = 2;
                                    break;
                                }

                                return _context9.abrupt('return');

                            case 2:
                                _context9.next = 4;
                                return this.markGuideAsDoneAPI(guide);

                            case 4:
                                if (this.curGuide === guide) {
                                    // done 了 curGuide 之后需要出现新的引导项，故重新 init 一下
                                    this.init();
                                }

                            case 5:
                            case 'end':
                                return _context9.stop();
                        }
                    }
                }, _callee9, this);
            }));

            function markAsDone(_x5) {
                return _ref9.apply(this, arguments);
            }

            return markAsDone;
        }()
    }, {
        key: 'init',
        value: function init() {
            var _this4 = this;

            this.clearPlaceholder();
            this.clearUpdated();
            this.curGuide = PlanB.GUIDE_TYPES.find(function (GUIDE_TYPE) {
                return !_this4.isGuideDone(GUIDE_TYPE);
            });
            if (this.curGuide !== undefined) {
                // 显示 placeholder 引导
                this.setPlaceholder(PlanB.GUIDE_TEXT[this.curGuide]);
            }
        }
    }, {
        key: 'isDone',
        get: function get() {
            return this.curGuide === undefined;
        }
    }]);
    return PlanB;
}(PlaceholderABTest);

PlanB.GUIDE_TYPES = [
// PLANB_AT_TYPE.GROUP,
PLANB_AT_TYPE.DOC, PLANB_AT_TYPE.GROUP_CARD, PLANB_AT_TYPE.SHEET, PLANB_AT_TYPE.FILE];
PlanB.GUIDE_TEXT = (_PlanB$GUIDE_TEXT = {}, (0, _defineProperty3.default)(_PlanB$GUIDE_TEXT, PLANB_AT_TYPE.DOC, t('abtest.atplaceholder.b.at.doc')), (0, _defineProperty3.default)(_PlanB$GUIDE_TEXT, PLANB_AT_TYPE.GROUP_CARD, t('abtest.atplaceholder.b.at.groupcard')), (0, _defineProperty3.default)(_PlanB$GUIDE_TEXT, PLANB_AT_TYPE.SHEET, t('abtest.atplaceholder.b.at.sheet')), (0, _defineProperty3.default)(_PlanB$GUIDE_TEXT, PLANB_AT_TYPE.FILE, t('abtest.atplaceholder.b.at.file')), _PlanB$GUIDE_TEXT);
/**
 * Plan C 是对照组，什么都不改变
 */

var PlanC = function (_PlaceholderABTest3) {
    (0, _inherits3.default)(PlanC, _PlaceholderABTest3);

    function PlanC() {
        (0, _classCallCheck3.default)(this, PlanC);
        return (0, _possibleConstructorReturn3.default)(this, (PlanC.__proto__ || Object.getPrototypeOf(PlanC)).apply(this, arguments));
    }

    (0, _createClass3.default)(PlanC, [{
        key: 'start',
        value: function () {
            var _ref10 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee10() {
                return _regenerator2.default.wrap(function _callee10$(_context10) {
                    while (1) {
                        switch (_context10.prev = _context10.next) {
                            case 0:
                            case 'end':
                                return _context10.stop();
                        }
                    }
                }, _callee10, this);
            }));

            function start() {
                return _ref10.apply(this, arguments);
            }

            return start;
        }()
    }, {
        key: 'update',
        value: function () {
            var _ref11 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee11() {
                return _regenerator2.default.wrap(function _callee11$(_context11) {
                    while (1) {
                        switch (_context11.prev = _context11.next) {
                            case 0:
                            case 'end':
                                return _context11.stop();
                        }
                    }
                }, _callee11, this);
            }));

            function update() {
                return _ref11.apply(this, arguments);
            }

            return update;
        }()
    }, {
        key: 'markAsDone',
        value: function () {
            var _ref12 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee12(guide) {
                return _regenerator2.default.wrap(function _callee12$(_context12) {
                    while (1) {
                        switch (_context12.prev = _context12.next) {
                            case 0:
                            case 'end':
                                return _context12.stop();
                        }
                    }
                }, _callee12, this);
            }));

            function markAsDone(_x6) {
                return _ref12.apply(this, arguments);
            }

            return markAsDone;
        }()
    }]);
    return PlanC;
}(PlaceholderABTest);

function createPlan() {
    var _getABParameters = (0, _abTestHelper.getABParameters)(),
        placeholder = _getABParameters.placeholder;

    if (placeholder) {
        if (placeholder.onboardingText === 'titleAndBodyChange') return new PlanA();
        if (placeholder.onboardingText === 'bodyChange') return new PlanB();
    }
    return new PlanC();
}
exports.default = createPlan();
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1755:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.docMention = exports.default = undefined;

var _slicedToArray2 = __webpack_require__(136);

var _slicedToArray3 = _interopRequireDefault(_slicedToArray2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _class, _temp, _initialiseProps; /**
                                      * Created by jinlei.chen on 2017/9/18.
                                      */
// 正文@
// import Hover from './Hover';


__webpack_require__(1696);

var _$rjquery = __webpack_require__(499);

var _utils = __webpack_require__(1590);

var _const = __webpack_require__(1581);

var _get2 = __webpack_require__(81);

var _get3 = _interopRequireDefault(_get2);

var _forEach2 = __webpack_require__(239);

var _forEach3 = _interopRequireDefault(_forEach2);

var _map2 = __webpack_require__(504);

var _map3 = _interopRequireDefault(_map2);

var _DocMention = __webpack_require__(2304);

var _DocMention2 = _interopRequireDefault(_DocMention);

var _docChatStatusManage = __webpack_require__(1882);

var _docChatStatusManage2 = _interopRequireDefault(_docChatStatusManage);

var _larkHelper = __webpack_require__(1881);

var _larkHelper2 = _interopRequireDefault(_larkHelper);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var MAX_KEY_WORDS_LEN = 32; // 最长的搜索字串长度

var isLarkHelperInited = false;

// todo将Mention里面关于ace_inner.js的兼容代码去掉
var Mention = (_temp = _class = function Mention(props) {
  (0, _classCallCheck3.default)(this, Mention);

  _initialiseProps.call(this);

  var editor = props.editor;

  this.props = props;
  if (editor) {
    this.editor = editor;
    this.init();
  }
  this.docMention = new _DocMention2.default(props);
}

// todo 是否需要传个zoneId进来


/** 兼容老的etherpad  */

// 响应mention

/**
 * 搜索的关键词获取
 * @returns {string}
 */
, _initialiseProps = function _initialiseProps() {
  var _this = this;

  this.className = 'Mention';

  this.init = function () {
    _this.initContainer();
    _this.cache = {};
    _this.handleResize = function () {};
    // this.hover = new Hover(this.props);

    if (!isLarkHelperInited) {
      _larkHelper2.default.init();
      isLarkHelperInited = true;
    }

    var _props = _this.props,
        showChatCards = _props.showChatCards,
        source = _props.source;
    // 是否需要展示群名片

    if (showChatCards) {
      _docChatStatusManage2.default.init({ editor: _this.editor, source: source });
    }
  };

  this.onMount = function () {
    _this.updateMentionInfo({ 0: _this.editor.getClientVars().apool.numToAttrib });
  };

  this.searchStringRange = function (hook, context) {
    var attributeList = context.attributeList;

    if (attributeList.find(function (attr) {
      return attr.indexOf('mention-chatId_') > -1 || attr.indexOf('drive-fileId') > -1;
    })) {
      context.isSearchable = false;
    }
  };

  this.aceInitialized = function (name, context) {
    _this.editor = context.editorInfo;
    _this.docMention.editor = _this.editor;
    _this.init();
  };

  this.initContainer = function () {
    var editor = _this.editor;

    var docbody = editor.getDocBody();
    var $container = (0, _$rjquery.$)(docbody).parents('.etherpad-container');
    if (!$container.length) $container = (0, _$rjquery.$)(docbody).parent();
    _this.$positionHolder = (0, _$rjquery.$)('.doc-position');
    if (!_this.$positionHolder.length) {
      _this.$positionHolder = (0, _$rjquery.$)('<div class="doc-position"></div>');
      $container.prepend(_this.$positionHolder);
    }
  };

  this.updateMentionInfo = function (attributes) {
    _docChatStatusManage2.default.update(_this.editor, attributes);
  };

  this.collectCommentQuote = function (hookName, _ref) {
    var node = _ref.node,
        attributes = _ref.attributes;

    var className = node ? (0, _get3.default)(node, 'children[0].className', '') : attributes ? (0, _map3.default)(attributes, function (attr) {
      return attr[0] || '';
    }).join(' ') : '';
    if (className.indexOf('mention-chatId') > -1) {
      return '[' + t('etherpad.lark.group.card') + ']';
    }
  };

  this.collectCommentTargetType = function (hookName, _ref2) {
    var node = _ref2.node;

    // 给打点用的
    if ((0, _get3.default)(node, 'children[0].className', '').indexOf('mention-chatId') > -1) {
      return 'groupCard';
    }
  };

  this.changesetApply = function (name, context) {
    var changeset = context.changeset,
        editor = context.editor;

    if (!changeset) return;
    var attributesMap = editor.ace_getAttributesFromChangeset(context.changeset);
    var zones = Object.keys(attributesMap);
    if (!zones.length) return;
    _docChatStatusManage2.default.update(editor, attributesMap);
  };

  this.reset = function () {
    _this.cache = {};
    var showChatCards = _this.props.showChatCards;

    if (showChatCards) {
      _docChatStatusManage2.default.reset();
    }
    _this.docMention.destory();
    // this.hover.destory();
    _larkHelper2.default.destory();
    _this.editor = null;
    isLarkHelperInited = false;
    _this.closeMention();
  };

  this.processBeforeInsertNode = function (name, context) {
    return _this.docMention.processBeforeInsertNode(name, context);
  };

  this.aceAttribsToClasses = function (name, context) {
    return _this.docMention.aceAttribsToClasses(name, context);
  };

  this.aceCreateDomLine = function (name, context) {
    return _this.docMention.aceCreateDomLine(name, context);
  };

  this.collectContentPre = function (name, context) {
    return _this.docMention.collectContentPre(name, context);
  };

  this.aceBeforeCopy = function (name) {
    return _this.docMention.aceBeforeCopy(name);
  };

  this.aceAfterCompositionEnd = function (name) {
    return _this.docMention.aceAfterCompositionEnd(name);
  };

  this.acePaste = function (name, context) {
    return _this.docMention.acePaste(name, context);
  };

  this.aceAfterPaste = function (name, context) {
    return _this.docMention.acePaste(name, context);
  };

  this.beforeAceSelectionChange = function (hookName, args) {
    (0, _utils.autoCompleteMentionSelection)(_this.editor, args);
  };

  this.commentListUpdate = function () {
    _this.handleResize();
  };

  this.editorSizeChange = function () {
    _this.handleResize();
  };

  this.isCursorInAt = function () {
    var editor = _this.editor;

    var rep = editor.ace_getRep();
    var lineNode = (0, _get3.default)(rep.lines.atIndex(rep.selStart[0]), 'lineNode');
    return editor.selection.isCaret() && (0, _$rjquery.$)(lineNode).find('.mention-type_' + _const.TYPE_ENUM.CHAT).length;
  };

  this.isStandardAt = function (evt) {
    var key = evt.key,
        shiftKey = evt.shiftKey,
        type = evt.type;

    var originalEvent = evt.originalEvent || evt;
    if (type !== 'keydown') {
      return false;
    }
    var isAt = (key === '@' || (0, _get3.default)(originalEvent, 'code') === 'Digit2') && shiftKey;
    return isAt;
  };

  this.linesWillReplace = function (name, context) {
    var oldLineEntries = context.oldLineEntries,
        newLineEntries = context.newLineEntries;
    // 删除line的时候不存在newLine 新建line的时候不存在oldLine

    if (!oldLineEntries[0] || !newLineEntries[0]) {
      return;
    }
    var holdCls = '.' + _const.HOLD_WHEN_REPLACE;
    (0, _forEach3.default)(oldLineEntries, function (oldEntry, index) {
      var oldLineNode = oldEntry.lineNode;

      if (!newLineEntries[index]) return;

      var newLineNode = newLineEntries[index].lineNode;

      // 如果是坚果云名片，需要替换

      if ((0, _$rjquery.$)(newLineNode).find('.drive').length || (0, _$rjquery.$)(oldLineNode).find('.drive').length) return;

      var $holdContent = (0, _$rjquery.$)(oldLineNode).find(holdCls);
      // 保持内容不被替换
      if ($holdContent.length) {
        (0, _$rjquery.$)(newLineNode).find(holdCls).replaceWith($holdContent);
        _this.editor.ace_markNodeClean(newLineNode, newLineEntries[index]);
      }
    });
  };

  this.prevTextIsWordsOrNumber = function () {
    _this.editor.ace_inCallStackIfNecessary('openMention', function () {
      _this.editor.ace_fastIncorp();
    });
    if (_browserHelper2.default.isIE) return (0, _utils.prevTextIsWordsOrNumber)();
    var rep = _this.editor.ace_getRep();

    var _rep$selStart = (0, _slicedToArray3.default)(rep.selStart, 2),
        selStartLine = _rep$selStart[0],
        selStartChar = _rep$selStart[1];

    var curLine = rep.lines.atIndex(selStartLine);
    var textBeforeAt = selStartChar ? curLine.text.slice(selStartChar - 2, selStartChar - 1) : '';
    return (/^[a-zA-Z0-9]$/.test(textBeforeAt)
    );
  };

  this.openMention = function (context, evt) {
    // const uuid = this.uuid = genUUID();
    // this.component = this.docMention;
    // this.closeMention();
    // const mentionBoxProps = {
    //   uuid,
    //   list: [],
    //   message: this.cache.message,
    // };
    //
    // evt.preventDefault();
    // this.component.showMentionBox(context, mentionBoxProps, evt);
    // LogFlow('confirm_mention').push({
    //   recommend_group: 'default_recomment',
    // });
    return true;
  };

  this.getKeyWords = function () {
    var text = (0, _$rjquery.$)('.' + _const.AT_HOLDER_PREFIX + _this.uuid).text();
    if (text.slice(0, 1) !== '@') {
      // 防止@符号被删除掉
      _this.closeMention();
      return;
    }
    var keyWords = text.slice(1);
    // 将&nbsp;转成空格
    keyWords = (keyWords || '').split(String.fromCharCode(160)).join(' ');
    return keyWords.slice(0, MAX_KEY_WORDS_LEN);
  };

  this.closeMention = function () {};
}, _temp);
exports.default = Mention;
var docMention = exports.docMention = new Mention({
  type: 'doc',
  postAddMentionId: true,
  hoverArea: '#innerdocbody',
  showable: true, // 是否展现Mention，由于DocMention采用插件机制，无法传入props，故设置默认值为true。只读情况下，key事件层次可以拦截掉Mention唤出，故无影响。
  showChatCards: true,
  boxWidth: 540,
  displayLargePopover: true,
  source: _const.SOURCE_ENUM.DOC,
  container: '.doc-position'
});
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1757:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _user = __webpack_require__(56);

var _reactRedux = __webpack_require__(238);

var _Watermark = __webpack_require__(1758);

var _Watermark2 = _interopRequireDefault(_Watermark);

var _user2 = __webpack_require__(527);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var mapStateToProps = function mapStateToProps(state) {
    return {
        currentUser: (0, _user.selectCurrentUser)(state)
    };
};
var mapDispatchToProps = {
    fetchCurrentUser: _user2.fetchCurrentUser
};
exports.default = (0, _reactRedux.connect)(mapStateToProps, mapDispatchToProps)(_Watermark2.default);

/***/ }),

/***/ 1758:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _userHelper = __webpack_require__(61);

var _watermarkHelper = __webpack_require__(1759);

var _watermark = __webpack_require__(1760);

var _watermark2 = _interopRequireDefault(_watermark);

__webpack_require__(1761);

var _get2 = __webpack_require__(81);

var _get3 = _interopRequireDefault(_get2);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var currentMark = '';
/**
 * 可能会有多个地方使用评论组件，在水印信息不更新的情况下保证只有一次样式注入
 */
function renderWatermarkStyle(platform, currentUser) {
    /* 如果当前user不存在，或者不是头条租户，则不渲染 */
    if (!currentUser.get('id')) {
        return;
    }
    var user = {
        name: currentUser.get('name'),
        mobile: currentUser.get('mobile'),
        email: currentUser.get('email')
    };
    var mark = (0, _watermarkHelper.getMark)(user);
    if (mark === currentMark) return; // 水印信息没更新，不需要重复渲染
    currentMark = mark;
    if (platform === 'web') {
        (0, _watermark2.default)(mark, {
            selector: '.watermark-wrapper-' + platform,
            type: 'canvas'
        });
    } else if (platform === 'mobile') {
        var ratio = document.documentElement.offsetWidth / 375;
        var fontSize = 14 * ratio;
        var gap = 80 * ratio;
        (0, _watermark2.default)(mark, {
            selector: '.watermark-wrapper-' + platform,
            fontSize: fontSize,
            gap: gap,
            type: 'canvas'
        });
    }
}
/**
 * 给 Docs 文档打水印
 */

var Watermark = function (_React$Component) {
    (0, _inherits3.default)(Watermark, _React$Component);

    function Watermark(props) {
        (0, _classCallCheck3.default)(this, Watermark);

        var _this = (0, _possibleConstructorReturn3.default)(this, (Watermark.__proto__ || Object.getPrototypeOf(Watermark)).call(this, props));

        _this.isNeedRendWatermark = function () {
            // 头条用户和每日优鲜显示水印，其他租户不显示水印
            var tenantId = (0, _get3.default)(window, 'User.tenantId');
            return _this.state.isBytedanceUser || tenantId === '6636599569817796867' || tenantId === '2';
        };
        _this.state = {
            isBytedanceUser: (0, _userHelper.getIsBytedanceUser)()
        };
        return _this;
    }
    /**
     * 由于mobile端没有触发获取user信息的请isBytedanceUser求，如果组件初始化后view为null则触发action
     */


    (0, _createClass3.default)(Watermark, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            var _props = this.props,
                platform = _props.platform,
                currentUser = _props.currentUser,
                fetchCurrentUser = _props.fetchCurrentUser;
            /* 移动端没有user数据，需要拉取一次 */

            if (platform === 'mobile' && currentUser.size <= 0) {
                fetchCurrentUser();
            }
            if (this.isNeedRendWatermark()) {
                renderWatermarkStyle(platform, currentUser);
            }
        }
        /**
         * 若多次dispatch的user信息一样，则不进行重复操作
         *
         * @param {object} nextProps
         */

    }, {
        key: 'shouldComponentUpdate',
        value: function shouldComponentUpdate(nextProps) {
            if (!nextProps.currentUser) {
                return false;
            }
            if (this.props.currentUser && nextProps.currentUser.get('id') === this.props.currentUser.get('id')) {
                return false;
            }
            return true;
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate() {
            if (this.isNeedRendWatermark()) {
                renderWatermarkStyle(this.props.platform, this.props.currentUser);
            }
        }
    }, {
        key: 'render',
        value: function render() {
            if (this.isNeedRendWatermark()) {
                return _react2.default.createElement("div", { className: 'watermark-wrapper-' + this.props.platform });
            }
            return null;
        }
    }]);
    return Watermark;
}(_react2.default.Component);

Watermark.propTypes = {
    /**
     * @type {Imutable} User info
     */
    currentUser: _propTypes2.default.object,
    /**
     * @type {string} web | mobile
     */
    platform: _propTypes2.default.string,
    fetchCurrentUser: _propTypes2.default.func
};
Watermark.defaultProps = {
    platform: 'web'
};
exports.default = Watermark;

/***/ }),

/***/ 1759:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
/**
 * 通过用户信息获取水印文字，如果mobile存在，则取mobile，否则取邮箱前缀。
 *
 * @param {object} user
 */
var getMark = exports.getMark = function getMark(user) {
    var mark = '';
    var name = user.name;
    var mobile = user.mobile;
    var email = user.email;
    var subMobile = '';
    var subEmail = '';
    if (mobile && mobile.length >= 4) {
        subMobile = mobile.substring(mobile.length - 4, mobile.length);
    }
    if (email) {
        var matchs = email.match(/.+(?=@)/);
        subEmail = matchs ? matchs[0] : '';
    }
    switch (true) {
        // 如果mobile存在，且总长度<25
        case subMobile && getActualLength(name + subMobile) < 25:
            mark = name + ' ' + subMobile;
            break;
        // 如果mobile存在，且总长度>=25
        case subMobile && getActualLength(name + subMobile) >= 25:
            mark = name.substring(0, 17) + '... ' + subMobile;
            break;
        // 如果name+email<25
        case getActualLength(name + subEmail) < 25:
            mark = name + ' ' + subEmail;
            break;
        // 如果name和email长度都>=25
        case getActualLength(name) > 25 && getActualLength(subEmail) > 25:
            mark = subEmail.substring(0, 22) + '...';
            break;
        // 如果name+email>=25，且name<=25,且email>25
        case getActualLength(name) <= 25 && getActualLength(subEmail) > 25:
            mark = name;
            break;
        default:
            mark = subEmail;
    }
    return mark;
};
/**
 * 获取真实的8位长度，这是由于浏览器在进行渲染的时候，8位的字符算作0.5个font，16位字符算作一个font。
 *
 * @param {string} str
 */
var getActualLength = exports.getActualLength = function getActualLength(str) {
    var length = 0;
    for (var index = 0; index < str.length; index++) {
        var e = str[index];
        if (e.codePointAt(0) >= 256) {
            length += 2;
        } else {
            length += 1;
        }
    }
    return length;
};

/***/ }),

/***/ 1761:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 1766:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.default = undefined;

var _defineProperty2 = __webpack_require__(11);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _find2 = __webpack_require__(376);

var _find3 = _interopRequireDefault(_find2);

var _class, _temp;

var _constants = __webpack_require__(1669);

var _tea = __webpack_require__(47);

var _getTemplateAbstract = __webpack_require__(1767);

var _getAllUrlParams = __webpack_require__(384);

var _offlineCreateHelper = __webpack_require__(379);

var _urlHelper = __webpack_require__(1705);

var _networkStateHelper = __webpack_require__(181);

var _networkHelper = __webpack_require__(121);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var fid = (0, _getAllUrlParams.getAllUrlParams)().fid || '';

var Share = (_temp = _class = function () {
  function Share() {
    var _this = this;

    (0, _classCallCheck3.default)(this, Share);

    this.setCurrentNote = function (currentNote) {
      _this.currentNote = currentNote;
    };

    this.setDefaultTitle = function (title) {
      _this.defaultTitle = title;
    };

    this.setIsTemplate = function (isTemplate) {
      _this.isTemplate = isTemplate;
    };

    this.getTitle = function () {
      var currentNote = _this.currentNote,
          defaultTitle = _this.defaultTitle;

      var title = currentNote && (currentNote.get('title') || currentNote.get('name'));

      return title || defaultTitle;
    };

    this.getDefaultText = function (editor) {
      var text = '';

      if (_this.isTemplate) {
        text = '' + (0, _getTemplateAbstract.getAbstract)(editor);
      }

      return text;
    };

    this.getTopic = function () {
      var text = '';

      if (_this.isTemplate) {
        text = _constants.TOUTIAOQUAN_TEMPLATE_TEXT;
      }

      return text;
    };

    this.handleShareClick = function (editor) {
      if (editor) {
        var docContainer = editor.getInnerContainer();
        docContainer && docContainer.blur();
      }

      if ((0, _offlineCreateHelper.isOfflineCreateDoc)() || !(0, _networkStateHelper.isOnLine)()) {
        return;
      }

      (0, _tea.collectSuiteEvent)('click_share_btn', {
        template_id: _this.isTemplate ? _constants.TEMPLATE_ID : ''
      });

      // 域名更换，租户域名私有化。如果在新域名下，优先使用后台返回的文档固有的url
      var url = _networkHelper.pathPrefix && _this.currentNote && _this.currentNote.get('url');
      if (!url) {
        url = (0, _urlHelper.fixShareUrl)(window.location.href);
      }
      window.lark.biz.util.share({
        title: _this.getTitle(),
        content: _this.getDefaultText(editor),
        topic: _this.getTopic(editor),
        url: url,
        feed_id: fid,
        onSuccess: _this.handleSharePopupClick
      });
    };

    this.handleSharePopupClick = function (data) {
      var _ID_TO_PLATFORM;

      var ID_TO_PLATFORM = (_ID_TO_PLATFORM = {}, (0, _defineProperty3.default)(_ID_TO_PLATFORM, _constants.SHARE_TO_LARK, 'lark'), (0, _defineProperty3.default)(_ID_TO_PLATFORM, _constants.SHARE_TO_TOU_TIAO_QUAN, 'toutiao_circle'), (0, _defineProperty3.default)(_ID_TO_PLATFORM, _constants.COPY_URL, 'copy'), _ID_TO_PLATFORM);
      (0, _find3.default)([_constants.SHARE_TO_LARK, _constants.SHARE_TO_TOU_TIAO_QUAN, _constants.COPY_URL], function (id) {
        if (id === data.id) {
          _this.collectShareEvent(ID_TO_PLATFORM[id]);
          return true;
        }
      });
    };

    this.collectShareEvent = function (toPlatform) {
      (0, _tea.collectSuiteEvent)('share', {
        to_platform: toPlatform,
        template_id: _this.isTemplate ? _constants.TEMPLATE_ID : ''
      });
    };
  }

  (0, _createClass3.default)(Share, null, [{
    key: 'create',
    value: function create(_ref) {
      var currentNote = _ref.currentNote,
          defaultTitle = _ref.defaultTitle,
          isTemplate = _ref.isTemplate;

      var share = new Share();
      share.setCurrentNote(currentNote);
      share.setDefaultTitle(defaultTitle);
      share.setIsTemplate(isTemplate);
      return share;
    }
  }]);
  return Share;
}(), _class.disable = function () {
  window.lark.biz.util.share({
    enable: false
  });
}, _class.enable = function () {
  window.lark.biz.util.share({
    enable: true
  });
}, _temp);
exports.default = Share;

/***/ }),

/***/ 1767:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.getAbstract = getAbstract;
function getAbstract(ace) {
  var rep = ace.getRep();
  var textArray = rep.alltext.split('\n');
  var repLen = rep.lines.length();
  var firstTime = true;
  var context = '';

  for (var i = 0; i < repLen; i++) {
    // 找到摘要那一行
    var _context = '';
    if (ace.getAttributeOnLine(rep.zoneId, i, 'template') === 'abstract') {
      _context += '◇' + textArray[i] + '\n';
      var start = i;
      var end = i;
      for (var j = i + 1; j < repLen; j++) {
        var attrbiute = ace.getAttributeOnLine(rep.zoneId, j, 'template');
        if (attrbiute === 'block') {
          end = j;
          i = j;
          break;
        }
        if (attrbiute === 'abstract' && j - i !== 1) {
          end = j;
          i = j - 1;
          break;
        }
      }
      for (var range = start; range < end; range++) {
        if (ace.getAttributeOnLine(rep.zoneId, range, 'template') !== 'abstract' && textArray[range] !== ' ') {
          var list = ace.getAttributeOnLine(rep.zoneId, range, 'list');
          if (firstTime && list && list.indexOf('done') > -1) {
            _context += (firstTime ? '-' : '') + textArray[range] + (firstTime ? '\n' : '    ');
            _context = _context.replace('（请注明）', '').replace('(Please clarify here)', '');
          } else if (!list) {
            _context += (firstTime ? '-' : '') + textArray[range] + (firstTime ? '\n' : '    ');
          }
        }
      }
      if (_context.length > 1000) {
        _context = _context.substr(0, 995) + '...\n';
      } else {
        if (!firstTime) {
          _context += '\n';
        }
      }
      firstTime = false;
    }
    context += _context;
  }
  return context.replace(/\*/g, '');
};

/***/ }),

/***/ 1842:
/***/ (function(module, exports) {

/* (ignored) */

/***/ }),

/***/ 1843:
/***/ (function(module, exports) {

/* (ignored) */

/***/ }),

/***/ 1861:
/***/ (function(module, exports) {

/* (ignored) */

/***/ }),

/***/ 1864:
/***/ (function(module, exports) {

/* (ignored) */

/***/ }),

/***/ 1881:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _$rjquery = __webpack_require__(499);

var _encryption = __webpack_require__(185);

var _tea = __webpack_require__(47);

var _tea2 = _interopRequireDefault(_tea);

var _const = __webpack_require__(1581);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var larkOpenTimeout = void 0;
var duration = 500;
function init() {
  // 此自定义事件目的为兼容IOS编辑状态下无法响应Click事件
  (0, _$rjquery.$)(document).on('openLark', '.js-open-lark', handleOpenLark);
  (0, _$rjquery.$)(document).on('click', '.js-open-lark', handleOpenLark);
  (0, _$rjquery.$)(window).on('blur beforeunload', handleBlur);
}

function destory() {
  (0, _$rjquery.$)(document).off('openLark', '.js-open-lark', handleOpenLark);
  (0, _$rjquery.$)(document).off('click', '.js-open-lark', handleOpenLark);
  (0, _$rjquery.$)(window).off('blur beforeunload', handleBlur);
}

function handleOpenLark(e) {
  var $target = (0, _$rjquery.$)(e.currentTarget);
  var chatId = $target.data('id');
  var source = $target.data('source');
  var type = $target.data('type');
  location.href = _const.LARK_CHAT_SCHEMA + chatId;
  handleBlur(e);
  larkOpenTimeout = setTimeout(function () {
    // todo 优雅的下载
    window.open('https://lark.bytedance.net/');
  }, duration);

  (0, _tea2.default)('click_chat_btn', {
    source: source || 'doc',
    chat_type: type === '6' ? 'group' : type === '0' ? 'P2P' : 'chat',
    mention_obj_id: (0, _encryption.encryptTea)(chatId),
    file_type: (0, _tea.getFileType)(),
    file_id: (0, _tea.getEncryToken)()
  });
}

function handleBlur(e) {
  larkOpenTimeout && clearTimeout(larkOpenTimeout);
  larkOpenTimeout = null;
}

exports.default = {
  init: init,
  destory: destory
};

/***/ }),

/***/ 1882:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
  value: true
});

var _forEach2 = __webpack_require__(239);

var _forEach3 = _interopRequireDefault(_forEach2);

var _filter2 = __webpack_require__(507);

var _filter3 = _interopRequireDefault(_filter2);

var _assign2 = __webpack_require__(506);

var _assign3 = _interopRequireDefault(_assign2);

var _apis = __webpack_require__(1631);

var _$rjquery = __webpack_require__(499);

var _const = __webpack_require__(1581);

var _utils = __webpack_require__(1590);

var _chatMetionUtils = __webpack_require__(1740);

var _chatStatusManage = __webpack_require__(1699);

var _chatStatusManage2 = _interopRequireDefault(_chatStatusManage);

var _userHelper = __webpack_require__(61);

var _bytedXEditor = __webpack_require__(1569);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var getLineNumberByAttrFromEditor = _bytedXEditor.AttributePoolHelper.getLineNumberByAttrFromEditor; /**
                                                                                                      * @fileOverview 管理群名片的加群状态 动态更新当前的加群状态
                                                                                                      */

var editor = void 0;
var buttonCls = '.mention-chat-button-opt .button-cancel,.mention-chat-button-opt .button-confirm';

var ChatStatus = {
  init: function init(context) {
    _chatStatusManage2.default.init(context);
    editor = context.editor;
    var innerDocBody = editor.getDocBody();
    if (!context.pure) {
      (0, _$rjquery.$)(innerDocBody).on('click', '.mention-chat-button', handleJoinChat);
      (0, _$rjquery.$)(innerDocBody).on('click', buttonCls, handleConfirmJoin);
    }
    this.source = context.source;
  },
  reset: function reset() {
    _chatStatusManage2.default.reset();
    var innerDocBody = editor.getDocBody();
    (0, _$rjquery.$)(innerDocBody).off('click', '.mention-chat-button', handleJoinChat);
    (0, _$rjquery.$)(innerDocBody).off('click', buttonCls, handleConfirmJoin);
    editor = null;
  },
  update: function update(editor, attribsMap) {
    // 更新群名片的状态
    var chatIds = parseChatIdFromAttrib(attribsMap);

    (0, _chatMetionUtils.updateChatsStatus)(editor, chatIds, this.source, updateChatJoinStatus);
  },
  // 分块的情况下，使用 nodes 更新
  updateWithNodes: function updateWithNodes(editor, nodes) {
    var _this = this;

    var clsNames = getNodesCls(nodes);
    var chatIds = [];
    (0, _forEach3.default)(clsNames, function (cls) {
      var id = (0, _utils.getValByName)(cls, 'mention-chatId');
      if (id && id !== '') {
        chatIds.push(id);
      }
    });

    if (!chatIds.length) return;

    var needToFetch = [];

    (0, _forEach3.default)(chatIds, function (chatId) {
      var info = _this.getCacheInfo(chatId);
      if (!info) {
        return needToFetch.push(chatId);
      }
      updateChatJoinStatus(editor, chatId, info);
    });

    if (needToFetch.length > 0) {
      (0, _chatMetionUtils.updateChatsStatus)(editor, needToFetch, this.source, updateChatJoinStatus);
    }
  },
  // 将搜索回来的结果洗数成 chatInfo
  setCacheInfo: function setCacheInfo(newInfos) {
    var chatInfos = (0, _filter3.default)(newInfos, function (item) {
      return item.type === _const.TYPE_ENUM.CHAT;
    });
    var filtedInfos = {};
    (0, _forEach3.default)(chatInfos, function (info) {
      filtedInfos[info.token] = Object.assign({}, info);
      filtedInfos[info.token].hasjoin = true; // 能搜索到的一定join了
    });
    _chatStatusManage2.default.setCacheInfo(filtedInfos);
  },
  getCacheInfo: function getCacheInfo(token) {
    return _chatStatusManage2.default.getCacheInfo(token);
  }
};

function getNodesCls(nodes) {
  var $mentions = (0, _$rjquery.$)(nodes).find('.mention');
  var clsNames = [];
  for (var i = 0, len = $mentions.length; i < len; i++) {
    clsNames.push($mentions.eq(i).prop('className'));
  }
  return clsNames;
}

function handleJoinChat(e) {
  var $button = (0, _$rjquery.$)(this);
  var $mention = $button.parents('.mention');
  if ($button.text() === _const.CHAT_JOIN_STATUS.unjoined) {
    // 加入群聊
    var infos = (0, _assign3.default)({}, getCurrentMentionInfo($mention), { hasjoin: false, joinConfirm: true });
    var html = (0, _utils.renderMentionChat)(infos);
    updateMentionHTML($mention, html);
    return false;
  }
}

function getInvitor(cls) {
  var invitor = cls.match(/(^| )author-([^\s]+)/);
  if (invitor) {
    invitor = invitor[2];
  } else {
    invitor = '';
  }
  return invitor;
}

function handleConfirmJoin(e) {
  var $mention = (0, _$rjquery.$)(e.currentTarget).parents('.mention');
  var infos = getCurrentMentionInfo($mention);
  var cls = $mention.prop('className');
  var chatId = (0, _utils.getValByName)(cls, 'mention-chatId');
  // const pad = editor && editor.ace_getPad();
  if ((0, _$rjquery.$)(e.currentTarget).hasClass('button-confirm')) {
    var invitor = getInvitor(cls);
    (0, _apis.joinChat)({
      chatId: chatId,
      invitor: invitor
    }).always(function (ret) {
      var code = ret.code,
          data = ret.data;

      if (code !== 0) {
        editor && editor.call('alert', {
          message: t('etherpad.join_group_failed')
        });
        return;
      }

      if (data.code !== 0) {
        editor && editor.call('alert', {
          message: _const.JOIN_CHAT_ERROR_MSG[data.code]
        });
        return;
      }

      var newInfos = (0, _assign3.default)({}, infos, {
        hasjoin: true,
        joinConfirm: false
      });

      ChatStatus.setCacheInfo([newInfos]);
      updateChatJoinStatus(editor, chatId, newInfos);
    });
  } else {
    updateChatJoinStatus(editor, chatId, (0, _assign3.default)({
      hasjoin: false,
      joinConfirm: false
    }, infos));
  }

  return false;
}

function getCurrentMentionInfo($mention) {
  var url = $mention.find('.mention-chat-icon img').prop('src');
  var desc = $mention.find('.mention-chat-desc').text();
  var content = $mention.find('.mention-chat-tit').text();
  var buttonText = $mention.find('.mention-chat-button-opt').text();
  var chatId = (0, _utils.getValByName)($mention.prop('className'), 'mention-chatId');
  return {
    url: url,
    desc: desc,
    buttonText: buttonText,
    joinConfirm: true,
    content: content,
    chatId: chatId,
    token: chatId,
    type: _const.TYPE_ENUM.CHAT
  };
}

function parseChatIdFromAttrib(attrsMap) {
  var chatIds = [];
  for (var zoneId in attrsMap) {
    var attrs = attrsMap[zoneId];
    (0, _forEach3.default)(attrs, function (attr) {
      if (!attr) return;
      var key = attr[0];
      var values = key.split('_');
      if (values && values[0] && values[0] === 'mention-chatId') {
        var value = values[1];
        if (chatIds.indexOf(value) < 0) {
          chatIds.push(value);
        }
      }
    });
  }
  return chatIds;
}

function updateChatJoinStatus(editor, chatId, info) {
  var isCurrentUserToCuser = (0, _userHelper.getIsCurrentUserToCuser)();
  var content = info.content,
      hasjoin = info.hasjoin,
      url = info.url,
      desc = info.desc,
      isCrossTenant = info.is_cross_tenant,
      isExternal = info.is_external;


  var notAllowedJoin = (isCrossTenant || isExternal) && !hasjoin;
  var notAllowedToCuserJoin = isExternal && isCurrentUserToCuser && !hasjoin; // 在跨租户的文档中,对C端用户的协作者访问，不在的群不允许加入，使用占位符
  notAllowedJoin = notAllowedJoin || notAllowedToCuserJoin;

  var buttonText = _const.CHAT_JOIN_STATUS.unjoined;

  if (hasjoin) {
    buttonText = (0, _utils.getJoinedText)();
  }

  var data = { url: url, desc: desc, content: content, buttonText: buttonText, chatId: chatId, notAllowedJoin: notAllowedJoin };
  var allChatsLine = getLineNumberByAttrFromEditor(editor, 'mention-chatId_' + chatId + ',true', true);

  allChatsLine.forEach(function (chatsLine) {
    var lineNum = chatsLine.lineNum,
        table = chatsLine.table;

    if (lineNum === -1) return;

    var reps = editor.getReps();
    var zoneId = table ? table.cellId : '0';
    var num = table ? table.lineNum : lineNum;
    var lines = reps[zoneId].lines;

    var lineEntry = lines.atIndex(num);

    if (!lineEntry || !lineEntry.lineNode) return;

    var lineNode = lineEntry.lineNode;

    var $chatsInDoc = (0, _$rjquery.$)(lineNode).find('.mention-chatId_' + chatId);

    var len = $chatsInDoc.length;
    if (len) {
      var html = (0, _utils.renderMentionChat)(data);
      // 更新所有的该chatId的卡片
      for (var i = 0; i < len; i++) {
        var $chat = $chatsInDoc.eq(i);
        updateMentionHTML($chat, html);
      }
    }
  });
}

function updateMentionHTML($chat, html) {
  var $domLine = $chat.parents('[id^=magicdomid]');
  var zone = editor.dom.zoneOfdom($domLine.get(0));
  var rep = editor.ace_getReps()[zone];
  $chat.html(html);
  editor.ace_markNodeClean($domLine.get(0), rep.lines.atKey($domLine.get(0).id));
}
exports.default = ChatStatus;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1886:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
var style = document.createElement('style');
style.type = 'text/css';
style.title = 'dynamicsyntax';
var appendedStyle = document.head.appendChild(style);
var dynamicCss = appendedStyle.sheet;
var idToSelectorTextMap = {};
var _findRuleIndex = function _findRuleIndex(selectorText) {
    var found = -1;
    var regexMode = selectorText instanceof RegExp;
    [].find.call(dynamicCss.cssRules, function (rule, index) {
        var curSelectorText = rule.selectorText;
        if (regexMode) {
            if (selectorText.test(curSelectorText)) {
                found = index;
                return true;
            }
            return false;
        }
        if (curSelectorText === selectorText) {
            found = index;
            return true;
        }
        return false;
    });
    return found;
};
var hasRule = function hasRule(selectorText) {
    return _findRuleIndex(selectorText) !== -1;
};
var insertRule = function insertRule(rule, id) {
    var cssRules = dynamicCss.cssRules;
    // ie 下会报index size error
    var len = cssRules.length ? cssRules.length : 0;
    var index = dynamicCss.insertRule(rule, len);
    if (id) {
        var insertedRule = cssRules[index];
        if (insertedRule instanceof CSSStyleRule) {
            idToSelectorTextMap[id] = insertedRule.selectorText;
        }
    }
};
var deleteRuleBySelectorText = function deleteRuleBySelectorText() {
    var selectorText = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : '';

    var index = _findRuleIndex(selectorText);
    if (index === -1) return;
    dynamicCss.deleteRule(index);
};
var deleteRuleById = function deleteRuleById() {
    var id = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : '';

    var selectorText = idToSelectorTextMap[id];
    if (!selectorText) return;
    deleteRuleBySelectorText(selectorText);
    delete idToSelectorTextMap[id];
};
var deleteRulesByRegExp = function deleteRulesByRegExp(regex, clearIds) {
    if (!regex) return;
    var rules = dynamicCss.cssRules;
    var deletedRules = [];
    for (var index = rules.length - 1; index >= 0; index--) {
        var rule = rules[index];
        if (!(rule instanceof CSSStyleRule)) {
            continue;
        }
        var selectorText = rule.selectorText;

        if (selectorText.match(regex)) {
            deletedRules.push(selectorText);
            dynamicCss.deleteRule(index);
        }
    }
    if (!clearIds) return;
    deletedRules.find(function (selectorText) {
        for (var key in idToSelectorTextMap) {
            if (idToSelectorTextMap[key] === selectorText) {
                delete idToSelectorTextMap[key];
                return true;
            }
        }
        return false;
    });
};
exports.default = {
    hasRule: hasRule,
    insertRule: insertRule,
    deleteRuleById: deleteRuleById,
    deleteRulesByRegExp: deleteRulesByRegExp,
    deleteRuleBySelectorText: deleteRuleBySelectorText
};

/***/ }),

/***/ 1903:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.urlFilter = undefined;
exports.render = render;

var _template2 = __webpack_require__(2244);

var _template3 = _interopRequireDefault(_template2);

var _bytedXEditor = __webpack_require__(1569);

var _common = __webpack_require__(19);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function render(template) {
  return (0, _template3.default)(template, {
    evaluate: /\{\{([\s\S]+?)\}\}/g,
    interpolate: /\{\{=([\s\S]+?)\}\}/g,
    escape: /\{\{\{([\s\S]+?)\}\}\}/g
  });
}

var getRegexpFilter = function getRegexpFilter(regExp, tag) {
  return function (lineText, textAndClassFunc) {
    regExp.lastIndex = 0;
    var regExpMatchs = null;
    var splitPoints = null;
    var execResult = void 0;
    var inCodeBlock = false;

    while (execResult = regExp.exec(lineText)) {
      if (!regExpMatchs) {
        regExpMatchs = [];
        splitPoints = [];
      }
      var startIndex = execResult.index;
      var regExpMatch = execResult[0];
      regExpMatchs.push([startIndex, regExpMatch]);
      splitPoints.push(startIndex, startIndex + regExpMatch.length);
    }

    if (!regExpMatchs) return textAndClassFunc;

    function regExpMatchForIndex(idx, hasUrlAttr) {
      for (var k = 0; k < regExpMatchs.length; k++) {
        var u = regExpMatchs[k];
        if (idx >= u[0] && idx < u[0] + u[1].length) {
          if (hasUrlAttr) {
            regExpMatchs.splice(k, 1);
            k--;
          } else {
            return u[1];
          }
        }
      }
      return false;
    }

    var handleRegExpMatchsAfterSplit = function () {
      var curIndex = 0;
      return function (txt, cls) {
        if (cls.indexOf('list:code') !== -1) {
          inCodeBlock = true;
        }
        var txtlen = txt.length;
        var newCls = cls;
        var hasUrlAttri = cls.indexOf('url-') > -1;
        var regExpMatch = regExpMatchForIndex(curIndex, hasUrlAttri);
        // 跳过codeblock
        if (regExpMatch && !inCodeBlock) {
          newCls += ' ' + tag + ':' + regExpMatch;
        }
        textAndClassFunc(txt, newCls);
        curIndex += txtlen;
      };
    }();

    return _bytedXEditor.LineStyleFilter.textAndClassFuncSplitter(handleRegExpMatchsAfterSplit, splitPoints);
  };
};

var urlFilter = exports.urlFilter = getRegexpFilter(_common.LINK_REG, 'url');

/***/ }),

/***/ 1920:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.htmlEncode = htmlEncode;
exports.htmlDecode = htmlDecode;
var HTML_ENTITIES = {
  '&nbsp;': '\xA0',
  '&iexcl;': '\xA1',
  '&cent;': '\xA2',
  '&pound;': '\xA3',
  '&curren;': '\xA4',
  '&yen;': '\xA5',
  '&brvbar;': '\xA6',
  '&sect;': '\xA7',
  '&uml;': '\xA8',
  '&copy;': '\xA9',
  '&ordf;': '\xAA',
  '&laquo;': '\xAB',
  '&not;': '\xAC',
  '&shy;': '\xAD',
  '&reg;': '\xAE',
  '&macr;': '\xAF',
  '&deg;': '\xB0',
  '&plusmn;': '\xB1',
  '&sup2;': '\xB2',
  '&sup3;': '\xB3',
  '&acute;': '\xB4',
  '&micro;': '\xB5',
  '&para;': '\xB6',
  '&middot;': '\xB7',
  '&cedil;': '\xB8',
  '&sup1;': '\xB9',
  '&ordm;': '\xBA',
  '&raquo;': '\xBB',
  '&frac14;': '\xBC',
  '&frac12;': '\xBD',
  '&frac34;': '\xBE',
  '&iquest;': '\xBF',
  '&Agrave;': '\xC0',
  '&Aacute;': '\xC1',
  '&Acirc;': '\xC2',
  '&Atilde;': '\xC3',
  '&Auml;': '\xC4',
  '&Aring;': '\xC5',
  '&AElig;': '\xC6',
  '&Ccedil;': '\xC7',
  '&Egrave;': '\xC8',
  '&Eacute;': '\xC9',
  '&Ecirc;': '\xCA',
  '&Euml;': '\xCB',
  '&Igrave;': '\xCC',
  '&Iacute;': '\xCD',
  '&Icirc;': '\xCE',
  '&Iuml;': '\xCF',
  '&ETH;': '\xD0',
  '&Ntilde;': '\xD1',
  '&Ograve;': '\xD2',
  '&Oacute;': '\xD3',
  '&Ocirc;': '\xD4',
  '&Otilde;': '\xD5',
  '&Ouml;': '\xD6',
  '&times;': '\xD7',
  '&Oslash;': '\xD8',
  '&Ugrave;': '\xD9',
  '&Uacute;': '\xDA',
  '&Ucirc;': '\xDB',
  '&Uuml;': '\xDC',
  '&Yacute;': '\xDD',
  '&THORN;': '\xDE',
  '&szlig;': '\xDF',
  '&agrave;': '\xE0',
  '&aacute;': '\xE1',
  '&acirc;': '\xE2',
  '&atilde;': '\xE3',
  '&auml;': '\xE4',
  '&aring;': '\xE5',
  '&aelig;': '\xE6',
  '&ccedil;': '\xE7',
  '&egrave;': '\xE8',
  '&eacute;': '\xE9',
  '&ecirc;': '\xEA',
  '&euml;': '\xEB',
  '&igrave;': '\xEC',
  '&iacute;': '\xED',
  '&icirc;': '\xEE',
  '&iuml;': '\xEF',
  '&eth;': '\xF0',
  '&ntilde;': '\xF1',
  '&ograve;': '\xF2',
  '&oacute;': '\xF3',
  '&ocirc;': '\xF4',
  '&otilde;': '\xF5',
  '&ouml;': '\xF6',
  '&divide;': '\xF7',
  '&oslash;': '\xF8',
  '&ugrave;': '\xF9',
  '&uacute;': '\xFA',
  '&ucirc;': '\xFB',
  '&uuml;': '\xFC',
  '&yacute;': '\xFD',
  '&thorn;': '\xFE',
  '&yuml;': '\xFF',
  '&quot;': '"',
  '&amp;': '&',
  '&lt;': '<',
  '&gt;': '>',
  '&apos;': '\'',
  '&OElig;': '\u0152',
  '&oelig;': '\u0153',
  '&Scaron;': '\u0160',
  '&scaron;': '\u0161',
  '&Yuml;': '\u0178',
  '&circ;': '\u02C6',
  '&tilde;': '\u02DC',
  '&ensp;': '\u2002',
  '&emsp;': '\u2003',
  '&thinsp;': '\u2009',
  '&zwnj;': '\u200C',
  '&zwj;': '\u200D',
  '&lrm;': '\u200E',
  '&rlm;': '\u200F',
  '&ndash;': '\u2013',
  '&mdash;': '\u2014',
  '&lsquo;': '\u2018',
  '&rsquo;': '\u2019',
  '&sbquo;': '\u201A',
  '&ldquo;': '\u201C',
  '&rdquo;': '\u201D',
  '&bdquo;': '\u201E',
  '&dagger;': '\u2020',
  '&Dagger;': '\u2021',
  '&permil;': '\u2030',
  '&lsaquo;': '\u2039',
  '&rsaquo;': '\u203A',
  '&euro;': '\u20AC',
  '&fnof;': '\u0192',
  '&Alpha;': '\u0391',
  '&Beta;': '\u0392',
  '&Gamma;': '\u0393',
  '&Delta;': '\u0394',
  '&Epsilon;': '\u0395',
  '&Zeta;': '\u0396',
  '&Eta;': '\u0397',
  '&Theta;': '\u0398',
  '&Iota;': '\u0399',
  '&Kappa;': '\u039A',
  '&Lambda;': '\u039B',
  '&Mu;': '\u039C',
  '&Nu;': '\u039D',
  '&Xi;': '\u039E',
  '&Omicron;': '\u039F',
  '&Pi;': '\u03A0',
  '&Rho;': '\u03A1',
  '&Sigma;': '\u03A3',
  '&Tau;': '\u03A4',
  '&Upsilon;': '\u03A5',
  '&Phi;': '\u03A6',
  '&Chi;': '\u03A7',
  '&Psi;': '\u03A8',
  '&Omega;': '\u03A9',
  '&alpha;': '\u03B1',
  '&beta;': '\u03B2',
  '&gamma;': '\u03B3',
  '&delta;': '\u03B4',
  '&epsilon;': '\u03B5',
  '&zeta;': '\u03B6',
  '&eta;': '\u03B7',
  '&theta;': '\u03B8',
  '&iota;': '\u03B9',
  '&kappa;': '\u03BA',
  '&lambda;': '\u03BB',
  '&mu;': '\u03BC',
  '&nu;': '\u03BD',
  '&xi;': '\u03BE',
  '&omicron;': '\u03BF',
  '&pi;': '\u03C0',
  '&rho;': '\u03C1',
  '&sigmaf;': '\u03C2',
  '&sigma;': '\u03C3',
  '&tau;': '\u03C4',
  '&upsilon;': '\u03C5',
  '&phi;': '\u03C6',
  '&chi;': '\u03C7',
  '&psi;': '\u03C8',
  '&omega;': '\u03C9',
  '&thetasym;': '\u03D1',
  '&upsih;': '\u03D2',
  '&piv;': '\u03D6',
  '&bull;': '\u2022',
  '&hellip;': '\u2026',
  '&prime;': '\u2032',
  '&Prime;': '\u2033',
  '&oline;': '\u203E',
  '&frasl;': '\u2044',
  '&weierp;': '\u2118',
  '&image;': '\u2111',
  '&real;': '\u211C',
  '&trade;': '\u2122',
  '&alefsym;': '\u2135',
  '&larr;': '\u2190',
  '&uarr;': '\u2191',
  '&rarr;': '\u2192',
  '&darr;': '\u2193',
  '&harr;': '\u2194',
  '&crarr;': '\u21B5',
  '&lArr;': '\u21D0',
  '&uArr;': '\u21D1',
  '&rArr;': '\u21D2',
  '&dArr;': '\u21D3',
  '&hArr;': '\u21D4',
  '&forall;': '\u2200',
  '&part;': '\u2202',
  '&exist;': '\u2203',
  '&empty;': '\u2205',
  '&nabla;': '\u2207',
  '&isin;': '\u2208',
  '&notin;': '\u2209',
  '&ni;': '\u220B',
  '&prod;': '\u220F',
  '&sum;': '\u2211',
  '&minus;': '\u2212',
  '&lowast;': '\u2217',
  '&radic;': '\u221A',
  '&prop;': '\u221D',
  '&infin;': '\u221E',
  '&ang;': '\u2220',
  '&and;': '\u2227',
  '&or;': '\u2228',
  '&cap;': '\u2229',
  '&cup;': '\u222A',
  '&int;': '\u222B',
  '&there4;': '\u2234',
  '&sim;': '\u223C',
  '&cong;': '\u2245',
  '&asymp;': '\u2248',
  '&ne;': '\u2260',
  '&equiv;': '\u2261',
  '&le;': '\u2264',
  '&ge;': '\u2265',
  '&sub;': '\u2282',
  '&sup;': '\u2283',
  '&nsub;': '\u2284',
  '&sube;': '\u2286',
  '&supe;': '\u2287',
  '&oplus;': '\u2295',
  '&otimes;': '\u2297',
  '&perp;': '\u22A5',
  '&sdot;': '\u22C5',
  '&lceil;': '\u2308',
  '&rceil;': '\u2309',
  '&lfloor;': '\u230A',
  '&rfloor;': '\u230B',
  '&lang;': '\u2329',
  '&rang;': '\u232A',
  '&loz;': '\u25CA',
  '&spades;': '\u2660',
  '&clubs;': '\u2663',
  '&hearts;': '\u2665',
  '&diams;': '\u2666'
};

function _decodeEntity(code) {
  // name type
  if (code.charAt(1) !== '#') {
    return HTML_ENTITIES[code] || code;
  }

  var n = void 0;
  var c = code.charAt(2);
  // hex number
  if (c === 'x' || c === 'X') {
    c = code.substring(3, code.length - 1);
    n = parseInt(c, 16);
  } else {
    c = code.substring(2, code.length - 1);
    n = parseInt(c);
  }
  return isNaN(n) ? code : String.fromCharCode(n);
}

function htmlEncode(str) {
  return str.replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/'/g, '&#39;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function htmlDecode(str) {
  return str.replace(/&#?\w+;/g, _decodeEntity);
}

/***/ }),

/***/ 1960:
/***/ (function(module, exports) {

module.exports = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAL4AAAC+CAYAAACLdLWdAAAAAXNSR0IArs4c6QAAGJdJREFUeAHtXWusHdV1XntmzuPaYGNsY2Oh0kKLo9gpARRaVIKxeflHG7lSmxBT+09rJNqg5E/aUBKUEhBR8ycRNEihlSo7NqQPFeVHZQxcA3WFQoRNiNPm0phA5Dg2tmNssM9rZna/NefM9fG95zFzzsyceayR7p199uzZe61vf7Nm7ecokiMSBLTWy+s2rSbt4E9fRVot04qWKa2XEs74vUgTVRAuKz4TlTsFNxHfIE1NxDdI6TMIn9BKnVQ44zf+1NukzJmqRTNKqeORCFzwTIC1HEERALlLzSZdQ+SsdkmtJtKrNf6Iw1ovCZrPWOmUOoVyZxSpGZQ7YyBMZM6Uy/QWHorWWHkX6GYh/oDKBtHNVouut7W7HpZ7A6z1zYhbOOCWiV0C6c/iTbEPb4ppSxl7SyXajzhnYgKlvGAhflcFgdQKFn2t1u4GV+kNAGcd4hZ3JclMEKQ/DRfqZUOraaWMabwRDiIOUXIwAoUnPohtNGz7Nu2qLVrTRrgRy/NJDXVcKdqtDL2jYlkv4iFw86lnMK0KS/xGQ6/VZG91tboHZF8VDK68pFJHDKV3KrK2VyrqYF60CqNHoYgP676i0XA/6yp3K/zh68IAldu0ig4Y2sADYDyNt8Cx3Oo5R7FCEL/eam2EK3M/dL8T5LfmYCA/gQBIb+O0B67Q49VSaXfeQckt8UFwNFSdTQ7pB2Hdb8h7RUaqn6LXTVKPlsvms3ltEOeO+CC8WW86d8NvfwCN1TWREqJgmaEx/BO8Cx6rls1n8ADkqms0N8QH4cv1lrOVXPoSBpWuLhhHY1UXg2WHyKCvV0vmdjwAzVgLSyjzzBMfhDdA+D/XLj0EK39FQrgVtBh1WBn0MB6Af8IDkOnu0EwTv9nUGFW1n4QPf2NBmTgZtRW9ZinrvnJZ7Z+MAOOXaoyfRfI5wMovPle3n3C080MhffL4M+aMPdcB18UEJBi7yMxZ/FrT3gK35htwa1aMrb1kEAEC6hjcny9Ola0dEWSWWBaZIT5GWte42v4HTDZZlxg6UlBgBECklw1l/RVGgtETlP4j9a4ON15rDefLLjlvCOnTSyiuG9TRAa4rrrP0StqWLNUWHwBeVm84O9E9eXvagRT5ziOA7s8XqhXzHvT8vHc+Nl2h1BK/1mqt147aBV9+ZbogE2mCIaCOKlNvniqV9gZLn2yq1L2SOq7NQ+SqF4T0yZIh2tJgsFCHcH0eSqPrkyqLD4BWdlybDdFWguQ2SQTg+kx3XJ+jk5Sju+zUEB+uza1wbZ6Rbsru6slTGN2epr4brs9LadAqFa7OuYb9GbwWnxPSp4ESccmAcRfUsVfXcRURIt+JEx8zKT+H184uuDn+dhshxJekWUKA65jrmut80nJPlPi1Rutrrus+nsbGz6QrJq/lc11znXPdT1LHifj4UN5EI/ZJ9M9vm6TyUvZkEUCj9yk0eu+bxFz/xIkP0ldrTedpbMC0abKwS+mpQECpZ6fK5mdB/nqS8iRKfJB+cb1hfx/D27ckqaSUlW4EQMJXqhXrUyD/6aQkTYz4bOlB+ueE9ElVbbbK6ZD/rqQsfyKNW/bp2b0R0meLjElKy9zwOAKuJFFuIsTnhqz49ElUZ8bLQLvP40oCasROfHRbPSK9NwnUZE6KYK4wZ+JWJ1YfnwcquM82biUk//whYBjG/djW5Im4NIuN+Dw0jcx5RDb2t0pc4Ei+k0MAjVwXfv/mBRXre3FIEQvxecIZz8sA6WUaQhy1VpA8Qf4mGfquOCa2RU58kH0l5mC/IRPOCsLO2NVUx6Yq5sfxEEQ6pTlSN4TdGp5PL6SPnQ0FKkCvYE5F7TJHSvx60/0KWuUbClQromoCCDCnmFtRFhWZq8NrZHmpWdRPZpTKSl7ZRYAbu/D3b49qDW8kxAfZL4Nf/yO4OLIwPLvcyoDk6ij8/WvxEIy9e8PYrk6XXy+kzwB1si1iZ012BF3kYxMfvtffwgeTfW+yzajMSM9cY86NK/BYro63rR92z4LVL40riNwvCARFAK5OyyDzunG2KxzL4mMvy28L6YNWl6SLCgHmHHNvnPxGJr63a7EsKBkHe7l3DATa05jtLaNmMZKrgyfuEvTi/FQGqkaFXe6LBgFvVPcjcH3eD5vfSBYfpMe0UdmfPizYkj5qBPSKNhfD5xva4vPnd/hrGLD6Iz004UWUOyJHoNUk8/D/kXHsXVIfniEyLXIvWU56yXJyfmM1kZHIIqhI1OKBLVOZnwj7WaJQxGeyw7d/VT6/E0mdJZ8JPiVjHXyVrDf3kQL5NRMcpMfbm8i2SeG6XnAxtX73k+Rcgw+/GxmxbfgmF77IchM/BEFBDUV8kH6bdvV3gmYu6VKEQLNO5b3/Suav3iG3MkXugsWky92zxjXhi9hknDtNRqNOzhW/Q80Nf5oZ668MdS/I/1RQxAMTH9a+DH/qEKyDfFIzKLppSQdLXt6zk4yj75Kz6FLS1YUDJVP1D8k8fYrcK34b5P90Riy/OozpDFfD6gf6Dm/gd5n38WQh/UDCpPUiuzds6YOQnnXQ1YvIWbzEaweYbx1Iq1pz5NJXtDk6J7rPz0DEh7U3+YvhffKQ6DQj0Gp4Pj27N8MsfbcaTH63XKXSm/9F5Drdl9Ib5q/aB9yeJBDxsWj8bsyRuDq9Gotk/RAwD//Ma8iyTx/uQIPXNEmd+4DMd/833K0TSs0cZa4GKX4o8fEEoR2gHwiSmaRJHwLs13PvzYUN2SFyok1gnjpORu0s2R+9kZwrPzrkhjRd1g+0OTtYpqHEbzadTVrTmsHZyNW0IqDOtvvpg8unyXz/BN4SDWresolaN97lNW6NIz8n853/gQ3EmyDFB3OVOTtMRO7EHXg4pB8cmEAuphsBG/31gfvuwPHah2Sg67P1idvJuepjnm7Wj/+brNenibNxFy4ie+3vk/ORG4lUiIwTRKnD2f8YVORAi19vtTZibOOGQRnItXwhoOrnyF16OdlrbvIUM+Dfl0B6bhjbGNklDHyVf7CHyi/9e3obveCsx90BVTOQ+NpV9w+4Vy7lDgEMYoHYDvrv24em0g+eI7dUQVfoUrQTpshZchk5Fy8h492fUvkF/lZfOl2fYdztS3w0EFZA+TtzV7eiUH8EQGKFP11d4KUxjv4CI7kfeO6N5+d07nQxrYHHBMwjb5P5Myy1TudxZ4fDPaXrS/xGw92MG4e2AXrmKpHZRMDp9NdX2sRXZ37t6aFL3VMb2qrpqYWY+oB+/gMvETl26vRl7jKH+wnWl/iuckee5N+vMIlPNwLcqOXDvZRf9mi7fvg+GsZowPaZrMZjA14//zvp7OcfxOGexMda2rVo1GJ6nhyFQcBpwa05Q+6yVaQxRZkP81c/J7J4OXXv3ht+E/CDYbz3Cy996v6Bwx6XewjWk/ia7K090kpUXhFwbbJOnUBDlaj5B3/oaWkeepOM478kd+qi/lrz28Ast+f090810Sv9uDyP+PCNDFereyYqrRSeGAIK/fbWSezHCnemecdm0hdd4vXZl/Z93/PhXczZGXjwy8Do/UYYeF9CF5nLzOm5xc1rvDZs+zYkWjU3ofzOGQKYeGaeOdmee3/5b3kDVua7M1Se/hdv1NaZupjciy/p5+WcBwMNW41BrfQeelWH0893yziP+Oj/RKM2nX2z3YJLeHQEVP0smR9gfTasfOvaT3qrryr/+c84t0hjFqe9dCV8+/k9OXNL5IUrCg+Qu+LKuZdS9bvNaepPfLwSFBabbEyV1CJMdAi4mHzmWfkaVmAtIn3pcm8pIk875r57Z/GyTmM2WJG8WosbuLxaK80HhiY2MrdxzFr0Cyw+HuC1sPbtJn2aNYlBtj/7+0ALd2Ioefwsv/vXAaxzowbSn4KFbve5q9oHpH75YZvw7Kp4a2+Dy8JvDQN5tm7YQNSjnz94Tkmk1Mvb3KYf+6VdQHytXWghR94QYJfEah6fVUsrA701GIDCCGxYwnMmnquEwS3n8t/EhLX2nJ7ZzFMa6HC7N/FdhY86zL4MUqpBzGI99YWpmEuILvtt36wFykx1KlUrLKRb0CH8CFuInF+MXvNI31yPxeh4iLJweNwm+pYv66zFhw9kYvXKuoLz3scln2fT8HpszNONUPp5njF6b7ghyz49uzeepc8I6VlZdLiuY47Dz/fmZcwSv9Wi63Eh7Pq0UABK4uQR0EtWklfTYxSt0cOjL1rk9d54DdnU+/TzlWVuM8dx5Yd8dZb4tnbXz09e7JhLL45mYObXH0zuPdr6PZlg67O4w3GP+LMOGqajSsPWR0jOuUSgm+Me8fEaKMEJujmX2opSgoCPADjucR2/PeKjt+saRCz0r8tZEMgjAsxx5jrr1nF1HGyRK4cgUAQE2lz3GrcuKRB/cg2wIsAdp45BR52DjPDGKWca8m5zfdbia7H4aagVkSEBBNpc9yw+lhcL8ROAPOoigo4yBx3hjVq+NObnc73j47OrI4cgUAQE2lw30NLFN2D0kiKoLDoKAsx15rxRt0msvfChUAgw5w3S0pVZqFoXZdGB6TDx9VWChSBQKATAeRBfFXLFVaEqWpS9EAFw3sAW0ksvjJVfgkC+EWDOW5ixtkzGbMNV9PP7w+0VebYeLcK3fGx2Nnk4wSW1hwBzHktyxOILHwqGADjPPn6adwMqWI2IuokgAM4beAlXEilMChEEUoIAc55dneGbsqREYBFDEIgEAXCet/sUix8JmpJJVhBgzvMkNbH4WakxkTMqBMqd2ZlR5Sf5CALZQICJn91NI7OBsUiZPgSa3KsTblut9CkhEgkCoRBgzqMfXyx+KNQkcfYRAOcttHAbeALkCIHAHdeHmzIwyZ3UQqhVmKTMefTj6zOF0VgUFQQYAXCeXZ0TgoYgUCgEwHlMS1YnC6W0KFt4BJjzBvY+F+IXngrFAgCcP8E+/vlvxBRLf9G2qAgofcIipd7GutuiQjCy3m4IyMKkHSZQir+lPEz09FwH50F8cwYfOE2PUBmQ5Gu7GvTGoXG/MzKaomuuNOgLfyzzCkdDr3MXOG9VLZqpTaYOx5J9kjeXMfphhjC92MAoMnFLJnqh5RgLAea8hY9hHT/XsE/JbmrBsfybT4eb0CoDWMGxjT2lUqeY853ZmRrujhyCQBEQaHPdI74iJcQvQp2Ljlhw2OZ6x+IL8YUTRUGgi/iYtyAWvyj1XnA9fa53LD53acohCBQBgTbXvfm15TK9VW+qs/xVuCKoHpWOQQemgqbz5QrRU+rfIucACKA35yxznZN6xEdEq1a39+H3XQHulyRAIM5BLBmkiolimvYx1zn32RUVmLE2jb58IX5AzMMMYoUdwJJBqoCVEDKZx/HOPbPEt5Sx19ZuyKyKmzzMIJYMYKWDJ8xxX5JO45aoVKL9eA2c9i/IWRDIEwLMbea4r9Ms8XHBwYySl/0LchYE8oQAc5s57us0S3yOwHKsaf+CnAWBPCEwl9sXEF8pQ4ifp9oWXWYRmMvtC4iPPs6DWIIuK7Jm4ZJAPhBQx9vcPq/NBcSHD4QeH9p9/rKEBiHAA1NB/gblIdfiR4A5zdzuLmm2O9OPVIbeoR3a4v+Wc28EwgxgyYBUbwyTimVOzy1rHvErlvVizXGO4Cu4q+Ymlt/nEQgzgCUDUudxSz6kjlQs88W55c4jPl4Jbr3R2olX+BfnJpbf5xGQAazzWKQ5hP1zdjKn58p4gY/vX1RkbffDchYEsoxAPy73JH6log5iqcqBLCsssgsCzGGPyz2g6El8TmdoY16DoMf9EiUIpBYBcLiv59KX+JWKsQu+kWy4k9pqFcEGIcDcBYef7pemL/Fx4zHctKffjRIvCKQcgT0dDvcUsy/xOTX6Px/veZdECgIpR2AYd+d1Z3brUy2Vdp9rtF7HHvo3dMcXJSzz6DNa04peZ+4Okn6gxecbTVKPDspArgkCaUMgCGeHEr9cNp/FXIefpE05kUcQ6IUAc5U52+tad9xAV4cTooGgaw37MUxh+G73jXkNb/tmLa+qFUQv9RhzdpiyQy0+Z1Atm89g67VDwzKT64LAJBFgjjJXg8gQeM/pWtP+C+3qp4JkKmkEgUkgoAy1baps/WOQsgMTH1tklGsNB1ZfXxEkY0kjCCSLgDo8VTGvhpvTDFJuIFeHM+IMlUEPB8lU0ggCSSPA3AxKepYtsMXnxLD6BlyeV9GvfyP/lkMQSAUCil6Di3MTiD9v+nE/+QJbfM6AM7aUdV+YAvoVLPGCQBQIjMrJUMRnQctltR+fdHoyCqElD0FgXASYi8zJsPmEcnX8zOHyLEZDF1uL6xV+nJwFgeQRUMfQoF0Nqx96B8DQFp+V44LQmJClicnXtJTYhQBzcBTScxYjWXy/7Fq99RKGyNb5v+UsCCSFAIj78lS1dOuo5Y1F/EZDr3HJOQDXpzSqAHKfIBAWAVj5lkHmdVhWOPIcspFcHV/QdsHqYf+3nAWBZBBQD49DepZxLIvPGXDffr3hPKdJ386/5RAE4kQA83FeqFbMu2D1A/fZ95JnbOJzpiD/Zejl+RFCK3sVInGCQDQIqKPoxbkWpH9v3PzGcnX8wlkQZerN4z6Ffn5yFgTmIsDc6nBsbNJz3pEQnzOaKpX2wnMSf5/BkCMGBNTftTkWTdaRuDq+KB1//3n4+xv8ODkLAuMiAL9+Gn79HVF6FJESnxUE+VfC338DIRnVHbfG5X4g4I3OfhykPxolHJG5Or5QLCB8sbtxDjQv2r9PzoLAXASYQx0uRUp6Lidy4nOm8MV4RHcrBB+ry4nzkqOYCDB3mEPMpTgQiIX4LOiCivU9CP/5OISWPPOPAHOHORSXprERnwXGwt8nsN3DI3EJL/nmEwHmDHMnTu0ib9z2ErZWt7+Dnp5tva5JnCDQjQB6cJ6aqlr3dsfFEU6E+OjpMWtN59/Q5bMpDiUkz5wgoNSzU2XzT+DmOHFrlAjxWQmQv1pv2JjTQ7fErZTknz0EQMRXqhWL5+DUk5A+Vh+/WwFWCIp9ihXsjpewINAh/R8lRXpGPDHic2FQ7DQ/1QgM3duQ08tRAATAhY6lP5OktokSnxXjp9rz49CISVJRKSt9CHgN2bZPn4h7041A4sTnwkF+h1vu6LaSLci7a6NAYa77Ngfib8j2gjWxxm2vwjmu3nQ+h4bvt/A3kYewn1wSHw8CMHou/j4fdz/9MOknTnwW8FzD/gwE2Q7yl4cJLNeziwAI3+RpCHGOyAZFJxXEZ2Frrdat2lHY4llmdQatvGylU8d4wllcc2/CYpEa4rPgsPgrsX53p8znD1uN6U7fmU9/Dyx+5LMsR9U8VX41A9NecGB8FWGZ2TlqrabkPq5DpYyvdhaRpIb0DE+qLH53fcH1WQ/XZxfeA7KAvRuYzIS9dRmbo1wuGKXqqSU+KwnX57KO6yNbl0RZ6zHnBdeGtwBh1yaSheFxiJsqV2euggwcAMT8DeMrCLfmXpff6UKA64jrql1n6SU9o5Zqi99drd52hdr+tkxy60YlPWEQ6RVDWX857g5nSWmUGeL7gOCLLFu0S9+Qbk8fkUmf0U2JXYvxRZIdk5YkTPmZIz4rB9//Euzk8AiGve9DONXuWpjKyFJauDUuf5QBO5t9GeH3syQ7y5pJ4vsgN5v6elvbT8o3uXxEEjoreo0/CTXKl0gSknBoMZm2lgy899EvQ2Gpmjo8VFtJMCYC6jC+JXsvY55l0jMImbb43bUIl6dcbzlbyaUvYeT36u5rEh4PAXRPHsLKja9XS+Z2uDW52C8pN8T3qxYPgIkZn3ejJfAAfNA1frycwyOANhQ+vKAew0zKZ0D42NfBhpdw9DtyR3wfCjwAqtl0NjmkH0Qb4AY/Xs4BEFD0uknq0XLZfBaERw9y/o7cEr+7quqt1kbtqvsRdyceCKv7moTbCIDgNkJ7lKEfr5ZKu/OOSyGI71ciSL+i0XA3u8rdgrfAdX58oc+KDhja2FGpGLtA/mNFwaJQxO+uVIwEr9Vkb3W1ugftgVXd1/IfVkcMpXcqsrZjpPVg/vWdr2Fhie9DgbeA0bDt2+AKbUFjeCMeguX+tXyd1XE0VnfDldlRsawXYd0LPe278MTvJne7QUxrtXY3uEpvADjrELe4O01WwiD2abRKXza0msbEselymQ4iLpcN1VHqRIg/ADWQ3my1CKPD7nql8ZUXRTcjbuGAWyZ2CaQ+i3bLPq3UtKWMvaUS7UdcrrogowRXiB8CTZC+1GzSNUTOapfUarhFqzFYhjPCWi8JkdXoSZU6hXJnMKg0g3JnDISJzBlY9LdAdJm6HRBZIX5AoIYlw0OxvG4THgCHH4KrSKvlWtFSvCmW4U2xFL8Xwc+oIFwG6BXk5+8owTsPNGCtm4hvkNJnED4Jy30CjslJ/D6OjYjeJmXOVC2aAbmPD5NFrg9H4P8B0L8cfSyxxK4AAAAASUVORK5CYII="

/***/ }),

/***/ 1961:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _tips = __webpack_require__(2664);

var _tips2 = _interopRequireDefault(_tips);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

exports.default = _tips2.default;

/***/ }),

/***/ 1962:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _regenerator = __webpack_require__(13);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _urlHelper = __webpack_require__(184);

var _offlineEditHelper = __webpack_require__(377);

var _toastHelper = __webpack_require__(381);

var _common = __webpack_require__(19);

var _tea = __webpack_require__(47);

var _tea2 = _interopRequireDefault(_tea);

__webpack_require__(2666);

var _suiteHelper = __webpack_require__(60);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var UseTemplate = function (_PureComponent) {
    (0, _inherits3.default)(UseTemplate, _PureComponent);

    function UseTemplate(props) {
        var _this2 = this;

        (0, _classCallCheck3.default)(this, UseTemplate);

        var _this = (0, _possibleConstructorReturn3.default)(this, (UseTemplate.__proto__ || Object.getPrototypeOf(UseTemplate)).call(this, props));

        _this.isLocked = false;
        _this.fileType = (0, _suiteHelper.suiteType)();
        _this.fetchTemplateInfo = function () {
            var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee() {
                var templateToken = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : _this.state.templateToken;

                var response, _response$data, parent_node, template;

                return _regenerator2.default.wrap(function _callee$(_context) {
                    while (1) {
                        switch (_context.prev = _context.next) {
                            case 0:
                                _context.prev = 0;
                                _context.next = 3;
                                return (0, _offlineEditHelper.fetch)('/api/obj_template/get/?type=' + _common.NUM_FILE_TYPE[_this.fileType.toUpperCase()] + '&token=' + templateToken, { method: 'GET' });

                            case 3:
                                response = _context.sent;

                                if (response.code === 0) {
                                    _response$data = response.data, parent_node = _response$data.parent_node, template = _response$data.template;

                                    _this.setState({
                                        templateName: template.name,
                                        parentToken: parent_node.token,
                                        parentName: parent_node.name
                                    });
                                } else {
                                    (0, _toastHelper.showToast)({
                                        type: 1,
                                        message: t('common.error'),
                                        duration: 3
                                    });
                                }
                                _context.next = 10;
                                break;

                            case 7:
                                _context.prev = 7;
                                _context.t0 = _context['catch'](0);

                                (0, _toastHelper.showToast)({
                                    type: 1,
                                    message: t('common.error'),
                                    duration: 3
                                });

                            case 10:
                            case 'end':
                                return _context.stop();
                        }
                    }
                }, _callee, _this2, [[0, 7]]);
            }));

            return function () {
                return _ref.apply(this, arguments);
            };
        }();
        _this.createTemplate = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2() {
            var _this$state, templateToken, templateName, parentToken, parentName, response;

            return _regenerator2.default.wrap(function _callee2$(_context2) {
                while (1) {
                    switch (_context2.prev = _context2.next) {
                        case 0:
                            if (!_this.isLocked) {
                                _context2.next = 2;
                                break;
                            }

                            return _context2.abrupt('return');

                        case 2:
                            _this.isLocked = true;
                            _context2.prev = 3;
                            _this$state = _this.state, templateToken = _this$state.templateToken, templateName = _this$state.templateName, parentToken = _this$state.parentToken, parentName = _this$state.parentName;
                            _context2.next = 7;
                            return (0, _offlineEditHelper.fetch)('/api/obj_template/create_obj/', {
                                method: 'POST',
                                headers: {
                                    'Content-Type': _offlineEditHelper.TYPE_FORM_DATA
                                },
                                body: 'type=' + _common.NUM_FILE_TYPE[_this.fileType.toUpperCase()] + '&token=' + templateToken,
                                serverFirst: true
                            });

                        case 7:
                            response = _context2.sent;

                            if (response.code === 0) {
                                (0, _tea2.default)('click_template_confirm', {
                                    parent_node_token: parentToken,
                                    parent_node_name: parentName,
                                    template_id: templateToken,
                                    template_name: templateName,
                                    file_id: response.data.obj_token,
                                    is_system_template: true
                                });
                                // 延迟页面跳转，使上报请求能够发出。
                                setTimeout(function () {
                                    return window.location.href = '/' + _this.fileType + '/' + response.data.obj_token;
                                }, 200);
                            } else {
                                (0, _toastHelper.showToast)({
                                    type: 1,
                                    message: t('common.error'),
                                    duration: 3
                                });
                            }
                            _context2.next = 14;
                            break;

                        case 11:
                            _context2.prev = 11;
                            _context2.t0 = _context2['catch'](3);

                            (0, _toastHelper.showToast)({
                                type: 1,
                                message: t('common.error'),
                                duration: 3
                            });

                        case 14:
                            _this.isLocked = false;

                        case 15:
                        case 'end':
                            return _context2.stop();
                    }
                }
            }, _callee2, _this2, [[3, 11]]);
        }));
        _this.state = {
            templateToken: (0, _urlHelper.parseQuery)(window.location.search).tt || '',
            templateName: '',
            parentToken: '',
            parentName: ''
        };
        return _this;
    }

    (0, _createClass3.default)(UseTemplate, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            if (this.state.templateToken) {
                this.fetchTemplateInfo();
                (0, _tea2.default)('click_template_entrance', { template_source: 'lark_bot' });
            }
        }
    }, {
        key: 'render',
        value: function render() {
            return this.state.templateToken ? _react2.default.createElement("div", { className: "use-template-container", onClick: this.createTemplate }, _react2.default.createElement("div", { className: "use-template" }, t('template.modal_confirm'))) : null;
        }
    }, {
        key: 'componentDidUpdate',
        value: function componentDidUpdate(prevProps) {
            var templateToken = (0, _urlHelper.parseQuery)(window.location.search).tt || '';
            if (prevProps.curSuiteToken !== this.props.curSuiteToken && this.state.templateToken !== templateToken) {
                this.setState({ templateToken: templateToken });
                if (templateToken) {
                    this.fetchTemplateInfo(templateToken);
                }
            }
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            var _state = this.state,
                templateToken = _state.templateToken,
                templateName = _state.templateName,
                parentToken = _state.parentToken,
                parentName = _state.parentName;

            (0, _tea2.default)('click_template_cancel', {
                parent_node_token: parentToken,
                parent_node_name: parentName,
                template_id: templateToken,
                template_name: templateName
            });
        }
    }]);
    return UseTemplate;
}(_react.PureComponent);

exports.default = UseTemplate;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(28)))

/***/ }),

/***/ 1963:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.AppDocTitle = exports.AppTitle = undefined;

var _container = __webpack_require__(2670);

exports.AppTitle = _container.AppTitle;
exports.AppDocTitle = _container.AppDocTitle;

/***/ }),

/***/ 1964:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.storeLarkTitle = exports.toggleHeaderShown = undefined;

var _$constants = __webpack_require__(4);

/**
 * 控制移动端header显示或隐藏
 */
var toggleHeaderShown = exports.toggleHeaderShown = function toggleHeaderShown() {
    var shown = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : true;
    return {
        type: _$constants.actionTypes.header.TOGGLE_HEADER_SHOWN,
        payload: {
            shown: shown
        }
    };
};
/**
 * 移动端标题
 */
var storeLarkTitle = exports.storeLarkTitle = function storeLarkTitle(title) {
    return {
        type: _$constants.actionTypes.header.STORE_LARK_TITLE,
        payload: {
            title: title
        }
    };
};

/***/ }),

/***/ 1970:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
var addHairline = exports.addHairline = function () {
    var hairline = void 0;
    return function () {
        if (typeof hairline !== 'undefined') return hairline;
        if (window.devicePixelRatio && devicePixelRatio >= 2) {
            var testElem = document.createElement('div');
            testElem.style.border = '.5px solid transparent';
            document.body.appendChild(testElem);
            if (testElem.offsetHeight === 1 && /iphone|ipad|itouch/i.test(navigator.appVersion)) {
                hairline = true;
            } else {
                hairline = false;
            }
            document.body.removeChild(testElem);
        } else {
            hairline = false;
        }
        return hairline;
    };
}();

/***/ }),

/***/ 2200:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
var keyCode = exports.keyCode = {
    A: 65,
    B: 66,
    C: 67,
    I: 73,
    J: 74,
    R: 82,
    V: 86,
    X: 88,
    Y: 89,
    Z: 90,
    F6: 117,
    DELETE: 8,
    TAB: 9,
    ENTER: 13,
    ESC: 27,
    PAGE_UP: 33,
    PAGE_DOWN: 34,
    END: 35,
    HOME: 36,
    LEFT: 37,
    UP: 38,
    RIGHT: 39,
    DOWN: 40
};
exports.default = keyCode;

/***/ }),

/***/ 2266:
/***/ (function(module, exports) {

/* (ignored) */

/***/ }),

/***/ 2303:
/***/ (function(module, exports) {

module.exports = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGAAAABgCAYAAADimHc4AAAAAXNSR0IArs4c6QAAA99JREFUeAHtnL1rFEEYh39zMUEQG4UgYqciNsE0olhYaaciqJ1VCmtBUDTBhfhR2VpZWIhYWEWx0AtaaSEaC/8EC1tBRHLxxneR3cRzv26zM/OO/AaO3czszbzzPMfczM5tACYSIAESIAESIAESIAESIAESIAESIAESIAESIAESIAESIAESIAESIAESIAESIAESIAESIAESIAES+J8IGO+dmbf7YXFFXrvQQx8zuI8L5pf3OEYbTOweDLAgcR2AwXtsxy1cM99GL+v6b78CErsPq/gkndiWd8TgJSZxBon5mef5PrluD0mTfXntzJs2WJG4Dktca3meg5OegzrLqxzgshSuw0+vtDgpUpaQ2K3lb3RYksI3WJYW1uGnzVnMYk1ic5z8CrCYLunPiSASMvgWOwrjMiX5hRe3y/QroCfDTXnyK6Ee/g9M4E15uN2U+BWwiAcS9lJF6H4k1MMfygThkoz/Xypi7aTIrwBjLKZwXsbcZxXRu5XQBL7FHBbNo4oYOyvyOwvKwk7slEz5nsoX3aksq+D4SmSd7nR21BT+HfOwIB4nWWEEpF3xLUEh/BRDOAE+JSiFH16ADwmK4esQ4FKCcvh6BLiQEAF8XQK6lBAJfH0CupAQEXydAjYjITL4egW0kRAhfN0CxpEwgZsY4rmsrMvuag6lbA4eV7hp+E1S2IVYkwibrZjLazKiRin8NGj9AtIo20pQDj8eAW0kRAA/LgHjSIgEftolv/sBaYubSYlZlYhvSxW2shqLz3Ir+0nlNUoK4xKQTjWHeCHs6r67ZoLsMbeQWteRFlU6ekvdPL+42e43dYrbaZ0bh4B28DMoqiXoH4IW7KwMOMuViyyDjxntgqPbPeaCBsfJ0i3gz5jfr4SfLrImcVQkhdvoH4f4yLV6h6C6YWd0qtlssaZuONIpYFz42acqQgn6BLSFH6kEXQI2Cz9CCXoEdAU/Mgk6BHQNPyIJ4QW4gh+JhLACXMOPQEI4Ab7gK5cQRoBv+Iol+BcQCr5SCX7vBSV2t3Cov7fj8tcL6abOJM7V3jsa4HHmzOXRr4ABrkpn/n4aMevd6L2dLN/FsYkEi7NYsMddNL+xTr8CgL0bG8/PfcLPGm0iYSgPbTtOfgVYvPunPyHgZ0HUSejhQ3apq6NfAVO4Jx15nXfG4Ltssl8M+ou1TAJGxvwe7sqDes4F+J8FWWswj2PyJTiNLXgrD+F9zYWEPrlhj0hcB2Xjf0U+FOm/VGAiARIgARIgARIgARIgARIgARIgARIgARIgARIgARIgARIgARIgARIgARIgARIgARIgARIgARKIjcBvQVQEJlZwJ7sAAAAASUVORK5CYII="

/***/ }),

/***/ 2304:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _dec, _class, _class2, _temp, _initialiseProps; /**
                                                     * Created by jinlei.chen on 2017/9/8.
                                                     */

// import MentionBox from './MentionBox';


__webpack_require__(1696);

var _$rjquery = __webpack_require__(499);

var _tea = __webpack_require__(47);

var _tea2 = _interopRequireDefault(_tea);

var _teaHelper = __webpack_require__(242);

var _forEach2 = __webpack_require__(239);

var _forEach3 = _interopRequireDefault(_forEach2);

var _get2 = __webpack_require__(81);

var _get3 = _interopRequireDefault(_get2);

var _find2 = __webpack_require__(376);

var _find3 = _interopRequireDefault(_find2);

var _isEmpty2 = __webpack_require__(505);

var _isEmpty3 = _interopRequireDefault(_isEmpty2);

var _filter2 = __webpack_require__(507);

var _filter3 = _interopRequireDefault(_filter2);

var _isFunction2 = __webpack_require__(100);

var _isFunction3 = _interopRequireDefault(_isFunction2);

var _singleLineHelper = __webpack_require__(1700);

var _encryption = __webpack_require__(185);

var _timeHelper = __webpack_require__(390);

var _classnames = __webpack_require__(29);

var _classnames2 = _interopRequireDefault(_classnames);

var _pure = __webpack_require__(1591);

var _pure2 = _interopRequireDefault(_pure);

var _abtest_placeholder = __webpack_require__(1746);

var _abtest_placeholder2 = _interopRequireDefault(_abtest_placeholder);

var _LogContext = __webpack_require__(733);

var _utils = __webpack_require__(1590);

var _editorOprations = __webpack_require__(1697);

var _const = __webpack_require__(1581);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

// import { postAddMentionId } from './apis';

var INLINE_CODE_OPEN_HTML = '<span data-faketext="" data-contentcollector-ignore-space-at="end">&#8203;</span>';
var INLINE_CODE_CLOSE_HTML = '<span data-faketext="" data-contentcollector-ignore-space-at="start">&#8203;</span>';
var DocMention = (_dec = (0, _pure2.default)(['showMentionBox', 'handleConfirm']), _dec(_class = (_temp = _class2 = function () {
  function DocMention(props) {
    (0, _classCallCheck3.default)(this, DocMention);

    _initialiseProps.call(this);

    var editor = props.editor;

    this.props = props;
    this.editor = editor;
    this.taskQueue = [];
    editor && editor.on('asyncNotifyCallback', this.pushTaskQueue);
  }
  //  todo 动态更新 文档title之类

  // todo 不删除 前面那个node


  (0, _createClass3.default)(DocMention, [{
    key: 'showMentionBox',

    /**
     * 调起@选择框
     * @param eventInfo
     */
    value: function showMentionBox(context, props, evt) {
      // const { rep, editor } = context;
      // const { uuid } = props;
      // const author = editor.getAuthor();
      // const { type, boxWidth, container, source } = this.props;
      //
      // const holderCls = `${AT_HOLDER_PREFIX}${uuid}`;
      // const extendAttribs = this._getExtendedAttribs(editor);
      // performAtHolder(editor, [rep.selStart[0], rep.selStart[1] - 1], rep.selEnd, '@',
      //   [['author', author], ['at-holder', true], [holderCls, true]].concat(extendAttribs));
      //
      // const $boxContainer = $(container);
      // const $atHolderDom = $(`.${AT_HOLDER_PREFIX}${uuid}`);
      // const position = getPosition($atHolderDom, { boxWidth, $boxContainer });
      // const style = getStyle(position);
      //
      // // In shit ie11 flex elem with max-height has strange display
      // if (browserHelper.modernIE) {
      //   style.height = mentionDefaultOptions.boxMinHeight + 'px';
      // }
      //
      // this.mentionBox = new MentionBox({
      //   style,
      //   boxType: type,
      //   token: getPageToken(),
      //   boxContainer: $boxContainer.get(0),
      //   source,
      //   ...props,
      //   rep,
      //   container,
      //   onConfirm: (evt) => this.handleConfirm(evt, context, props),
      //   editor: editor,
      //   onAsideClick: () => editor.ace_updateBrowserSelectionFromRep(true),
      //   // onClose: () => pub('mentionBoxClose')
      // });
      // collectEvent('open_mention', {
      //   action: _get(evt, 'data.type'), // 0 用户 1文档
      //   source: type,
      //   eventType: _get(evt, 'e.type') || 'keydown',
      //   targetId: '',
      //   targetClass: '',
      //   zone: getZone(rep),
      // });
    }
  }, {
    key: 'handleConfirm',
    value: function handleConfirm(evt, context, props) {
      var editor = this.editor;
      var rep = context.rep;

      var author = editor.getAuthor();
      var uuid = props.uuid;
      var data = evt.data,
          fromNotification = evt.fromNotification,
          isClick = evt.isClick;
      var type = data.type,
          token = data.token,
          url = data.url,
          shouldNotifyLark = data.shouldNotifyLark;
      var content = data.content;
      var _type = this.props.type;

      var $atHolderDom = (0, _$rjquery.$)('.' + _const.AT_HOLDER_PREFIX + uuid);
      content = (content || '').trim();
      // !!调用focus使光标回到编辑器内部
      editor.ace_updateBrowserSelectionFromRep(true);

      this.mentionBox.close();

      if ((0, _isEmpty3.default)(data)) return;
      var _window$teaMap = window.teaMap,
          ownerId = _window$teaMap.ownerId,
          createUid = _window$teaMap.createUid;
      // 防止@ 被人删除导致问题

      if ($atHolderDom.length) {
        var time = window.teaMap.createTime || new Date().getTime();
        var _actionType = (0, _get3.default)(evt, 'data.type');
        var _recommendSource = (0, _get3.default)(evt, 'data.source');
        (0, _LogContext.LogFlow)('confirm_mention').report({
          action: _actionType, // 0 用户 1文档
          source: _type,
          event_type: isClick ? 'mouseclick' : 'keydown',
          mention_type: (0, _teaHelper.getMentionType)(_actionType),
          owner_id: (0, _encryption.encryptTea)(ownerId),
          create_uid: (0, _encryption.encryptTea)(createUid),
          create_time: time,
          create_date: (0, _timeHelper.getDateStr)(time),
          mention_obj_id: (0, _encryption.encryptTea)(token),
          mention_notification_status: shouldNotifyLark && shouldNotifyLark.toString(),
          is_owner: (window.userId === createUid).toString(),
          zone: (0, _teaHelper.getZone)(rep),
          recommend_source: (0, _utils.getMentionRecommendSource)(_recommendSource)
        });
        // 这里标记结束的引导是 TYPE_ENUM.FILE（Docs 文档）、TYPE_ENUM.SHEET（Sheet 文档）和 TYPE_ENUM.CHAT（群名片）
        if (_abtest_placeholder.toPlanbAtType[type]) {
          _abtest_placeholder2.default.markAsDone(_abtest_placeholder.toPlanbAtType[type]);
        }

        fromNotification && (0, _tea2.default)('click_confirm_mention_btn', {
          source: _type,
          confirm_mention_btn_type: fromNotification,
          mention_type: (0, _teaHelper.getMentionType)(_actionType),
          mention_obj_id: (0, _encryption.encryptTea)(token),
          mention_notification_status: shouldNotifyLark && shouldNotifyLark.toString(),
          file_type: (0, _tea.getFileType)(),
          file_id: (0, _tea.getEncryToken)()
        });

        editor.ace_inCallStackIfNecessary('mentionFastIncrop', function () {
          editor.ace_fastIncorp(true);
        });
        // fastIncorp之后 line新建 还没有domId domToRep需要setTimeoutfun
        var uui = '' + _const.AT_HOLDER_PREFIX + uuid;
        $atHolderDom = (0, _$rjquery.$)('.' + uui);
        // fastIncorp后 原来的line 被删除了 重新获取一遍dom
        var atRep = editor.ace_domToRep($atHolderDom.get(0));
        if (!atRep) {
          return;
        }
        var selStart = atRep.selStart,
            selEnd = atRep.selEnd;


        var ct = content;
        var text = ' ';
        var attrs = [['author', author], ['at-holder', 0], [uui, 0], ['mention-type_' + type, true], // 数字 0 会被干掉
        ['mention-link_' + encodeURIComponent(url), true]];

        var extendAttribs = this._getExtendedAttribs(editor);
        switch (type) {
          case _const.TYPE_ENUM.GROUP:
          case _const.TYPE_ENUM.USER:
            attrs.push(['mention-tempId_' + uuid, true]);
            text = '@' + ct;
            attrs.push(['mention-token_' + token, true]);
            if (_type !== 'doc') {
              attrs.push(['mention-notify_' + shouldNotifyLark, true]);
            }
            attrs = attrs.concat(extendAttribs);
            break;
          case _const.TYPE_ENUM.CHAT:
            text = (0, _singleLineHelper.getSingleLineText)(rep);
            attrs.push(['mention-chatId_' + token, true]);
            break;
          case _const.TYPE_ENUM.BLOCK:
            {
              var blockPlugin = editor.plugins.blockPlugin;

              text = (0, _singleLineHelper.getSingleLineText)(rep) + '\n';
              attrs = blockPlugin.getAttrsFromBlockDataSet(evt.data.dataSet);
              break;
            }
          default:
            // 避免连续的@文档因attribute完全相同被cc合并
            attrs.push(['mention-uuid_' + uuid, true]);
            attrs.push(['mention-token_' + token, true]);
            text = ct;
            attrs = attrs.concat(extendAttribs);
            break;
        }

        (0, _editorOprations.performAt)(editor, selStart, selEnd, text, attrs);

        if (type === _const.TYPE_ENUM.CHAT || type === _const.TYPE_ENUM.BLOCK) {
          var nextLine = rep.selStart[0] + 1;
          // 将光标移动到下一行
          if (text.slice(-1) !== '\n' && nextLine < rep.lines.length()) {
            editor.ace_inCallStackIfNecessary('insertChatPerformRepChange', function () {
              if (editor.dom) {
                editor.ace_performSelectionChange(rep.zoneId, [nextLine, 0], [nextLine, 0]);
              } else {
                editor.ace_performSelectionChange([nextLine, 0], [nextLine, 0]);
              }
            });
          }
          editor.ace_updateBrowserSelectionFromRep(true);
        } else {
          var afterSpaceSelEnd = [selStart[0], selStart[1] + text.length];
          var attribs = [['author', author]].concat(extendAttribs);
          (0, _editorOprations.performSpace)(editor, afterSpaceSelEnd, afterSpaceSelEnd, attribs);
          // 如果在评论框里的editor,确定的时候不发notify, 而是提交的时候提交notify
          // if (_type !== 'comment') {
          //   postAddMentionId(editor, this.tempId, data);
          // }
        }
      }
    }
  }]);
  return DocMention;
}(), _initialiseProps = function _initialiseProps() {
  var _this = this;

  this.acePaste = function (name, context) {
    var e = context.e,
        html = context.html;


    var clipboardData = e.originalEvent.clipboardData || window.clipboardData;
    // https://w3c.github.io/clipboard-apis/#override-paste
    if (!clipboardData || !(0, _find3.default)(clipboardData.types, function (type) {
      return type === 'text/html';
    })) {
      return;
    }

    var pasteHtml = html || clipboardData.getData('text/html');
    var $content = (0, _$rjquery.$)('<section></section>').append(pasteHtml);

    // 修改mention的mention-tempId
    var $mentions = $content.find('.mention');
    if ($mentions.length) {
      (0, _forEach3.default)($mentions, function (mention) {
        mention.className = mention.className.replace(/mention-tempId_\S*/, '');
      });
      context.html = $content.html();
      e.stopImmediatePropagation();
      e.preventDefault();
      return context.html;
    }
  };

  this.aceAttribsToClasses = function (name, args) {
    var key = args.key,
        value = args.value;

    var mentionKeys = ['mention-type', 'mention-link', 'mention-token', 'mention-id', 'mention-tempId',
    // 'mention-content',
    // 'mention-desc',
    'mention-chatId'];
    if (mentionKeys.indexOf(key) > -1) {
      return key + '_' + value;
    }

    if (/mention/.test(key)) {
      return key;
    }

    if (/at-(.+)/.test(key)) {
      return key;
    }
  };

  this.aceAfterCompositionEnd = function (name) {
    while (_this.taskQueue.length) {
      var task = _this.taskQueue.pop();
      if ((0, _isFunction3.default)(task)) {
        task();
      }
    }
  };

  this.processBeforeInsertNode = function (name, context) {
    var entry = context.entry,
        cls = context.cls;

    if (/(^| )mention-token|mention-chatId/.test(cls)) {
      var attrs = cls.split(' ');
      var mentionAttrs = {};
      (0, _forEach3.default)(attrs, function (item) {
        var match = item.match(/(.+)_(.+)/);
        if (match) {
          var key = match[1].split('-')[1];
          mentionAttrs[key] = match[2];
        }
      });
      var type = mentionAttrs.type;

      if (parseInt(type) === _const.TYPE_ENUM.CHAT) {
        entry.domInfo.lineManagerType = 'mention_chat';
      }
    }
  };

  this.aceCreateDomLine = function (name, context) {
    var spanClass = context.spanClass;

    if (/(^| )mention-token|mention-chatId/.test(spanClass)) {
      var attrs = spanClass.split(' ');
      var mentionAttrs = {};
      (0, _forEach3.default)(attrs, function (item) {
        var match = item.match(/(.+)_(.+)/);
        if (match) {
          var key = match[1].split('-')[1];
          mentionAttrs[key] = match[2];
        }
      });
      var type = mentionAttrs.type,
          link = mentionAttrs.link;

      var href = link && decodeURIComponent(link) || '';
      var extraOpenTags = void 0;
      var extraCloseTags = void 0;
      var rawHtml = void 0;
      var addedSpanClass = void 0;
      var addedLineClass = void 0;
      switch (parseInt(type)) {
        case _const.TYPE_ENUM.GROUP:
        case _const.TYPE_ENUM.USER:
          extraOpenTags = '<a href="javascript:void(0)" contenteditable="false">';
          extraCloseTags = '</a>';
          break;
        case _const.TYPE_ENUM.CHAT:
          // extraOpenTags = `${renderMentionChat({ url: href })}`;
          // extraCloseTags = '</div>';
          rawHtml = '' + (0, _utils.renderMentionChat)({ url: href });
          addedSpanClass = 'ignore-dom';
          addedLineClass = 'single-line mention-chat-card ignore-attr-heading';
          context.attributes = Object.assign({}, context.attributes, { 'data-faketext': context.text });
          break;
        default:
          extraOpenTags = '<a href="' + href + '" rel="noopener noreferrer" target="_blank" contenteditable="false">';
          extraCloseTags = '</a>';
          break;
      }

      if (rawHtml) {
        context.rawHtml = rawHtml;
      } else {
        context.extraOpenTags = '' + context.extraOpenTags + extraOpenTags;
        context.extraCloseTags = '' + extraCloseTags + context.extraCloseTags;
        context.extraOpenHtml = INLINE_CODE_OPEN_HTML;
        context.extraCloseHtml = INLINE_CODE_CLOSE_HTML;
      }
      context.spanClass = (0, _classnames2.default)(spanClass, 'mention', addedSpanClass);

      if (addedLineClass) {
        context.lineClass = context.lineClass + ' ' + addedLineClass;
      }
    }
  };

  this.aceBeforeCopy = function (hook) {
    var selection = window.getSelection();
    var range = void 0;
    if (selection.getRangeAt) {
      range = selection.getRangeAt(0);
    } else {
      range = document.createRange();
      range.setStart(selection.anchorNode, selection.anchorOffset);
      range.setEnd(selection.focusNode, selection.focusOffset);
    }
    if (range.endContainer.nodeType === 3) {
      var parentNode = (0, _editorOprations.findParentNodeFromClass)(range.endContainer, 'mention-type_' + _const.TYPE_ENUM.USER);
      if (parentNode) {
        return parentNode.outerHTML + '<span> </span>';
      }
    }
    return null;
  };

  this.collectContentPre = function (hook, context) {
    var tname = context.tname,
        node = context.node;
    var cc = context.cc,
        state = context.state,
        cls = context.cls;


    if (tname === 'a') {
      while (node && tname !== 'span' && tname !== 'body') {
        node = node.parentNode;
        tname = ((0, _get3.default)(node, 'tagName') || '').toLocaleLowerCase();
      }
      var pCls = node && node.className;
      if (pCls && pCls.indexOf('mention') > -1) {
        (0, _forEach3.default)(pCls.split(' '), function (item) {
          if (/mention|b/.test(item)) {
            cc.doAttrib(state, item);
          }
        });
      }
    }

    if (tname === 'span' && cls && cls.indexOf('at-holder') > -1) {
      (0, _forEach3.default)(cls.split(' '), function (item) {
        if (/at-(.+)/.test(item)) {
          cc.doAttrib(state, item);
        }
      });
    }
  };

  this.deleteMentionIfNecessary = _editorOprations.docDeleteMentionIfNecessary;
  this.moveCursorIfNecessary = _editorOprations.docMoveCursorIfNecessary;

  this.pushTaskQueue = function (task) {
    _this.taskQueue.push(task);
  };

  this._getExtendedAttribs = function () {
    var editor = _this.editor;

    var zoneId = editor.getRep().zoneId;
    var extendAttribs = (0, _get3.default)(editor.ace_getAttributesOnSelection(zoneId), 'attribs') || [];
    extendAttribs = (0, _filter3.default)(extendAttribs, function (item) {
      var key = item[0];
      return ['backcolor', 'bold', 'italic', 'underline', 'strikethrough'].indexOf(key) > -1;
    }); // 将所有其他的属性 如行属性author等内容剔除掉
    return extendAttribs;
  };

  this.isMentionBoxVisible = function () {
    return false;
  };

  this.destory = function () {
    _this.taskQueue = [];
    _this.editor && _this.editor.off('asyncNotifyCallback', _this.pushTaskQueue);
  };
}, _temp)) || _class);
;

exports.default = DocMention;

/***/ }),

/***/ 2664:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

__webpack_require__(2665);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function Tips(props) {
  return _react2.default.createElement(
    'div',
    { className: 'tips-container', onClick: props.handleClick },
    _react2.default.createElement(
      'div',
      { className: 'tips-container__img' },
      _react2.default.createElement('img', { src: props.imgSrc })
    ),
    _react2.default.createElement(
      'div',
      { className: 'tips-container__text' },
      _react2.default.createElement(
        'pre',
        null,
        props.text
      )
    )
  );
}

Tips.propTypes = {
  text: _propTypes2.default.string,
  imgSrc: _propTypes2.default.string,
  handleClick: function handleClick() {}
};

exports.default = Tips;

/***/ }),

/***/ 2665:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 2666:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 2670:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.AppDocTitle = exports.AppTitle = undefined;

var _reactRedux = __webpack_require__(238);

var _reactRouterDom = __webpack_require__(278);

var _title = __webpack_require__(2671);

var _title2 = _interopRequireDefault(_title);

var _doc_title = __webpack_require__(2672);

var _doc_title2 = _interopRequireDefault(_doc_title);

var _suite = __webpack_require__(69);

var _header = __webpack_require__(1964);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var mapDispatchToProps = {
  storeLarkTitle: _header.storeLarkTitle
};

var mapStateToProps = function mapStateToProps(state) {
  return {
    currentNote: (0, _suite.selectCurrentSuiteByObjToken)(state)
  };
};

var AppTitle = exports.AppTitle = (0, _reactRouterDom.withRouter)((0, _reactRedux.connect)(mapStateToProps, mapDispatchToProps)(_title2.default));

var AppDocTitle = exports.AppDocTitle = (0, _reactRouterDom.withRouter)((0, _reactRedux.connect)(mapStateToProps, mapDispatchToProps)(_doc_title2.default));

/***/ }),

/***/ 2671:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _class, _temp;

var _react = __webpack_require__(1);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Title = (_temp = _class = function (_Component) {
  (0, _inherits3.default)(Title, _Component);

  function Title(props) {
    (0, _classCallCheck3.default)(this, Title);
    return (0, _possibleConstructorReturn3.default)(this, (Title.__proto__ || Object.getPrototypeOf(Title)).call(this, props));
  }

  (0, _createClass3.default)(Title, [{
    key: 'componentWillReceiveProps',
    value: function componentWillReceiveProps(nextProps) {
      var currentNote = nextProps.currentNote,
          defaultName = nextProps.defaultName;

      if (!currentNote) return;

      this.setLarkTitle(this.getTitle(currentNote) || defaultName);
      console.log('willReceiveProps', this.getTitle(currentNote));
    }
  }, {
    key: 'getTitle',
    value: function getTitle(currentNote) {
      return currentNote && (currentNote.get('title') || currentNote.get('name'));
    }
  }, {
    key: 'setLarkTitle',
    value: function setLarkTitle(title) {
      var currentNote = this.props.currentNote;

      var isExternal = currentNote ? currentNote.is_external : false;
      window.lark.biz.navigation.setTitle({
        title: title,
        is_external: isExternal
      });
    }
  }, {
    key: 'render',
    value: function render() {
      return null;
    }
  }]);
  return Title;
}(_react.Component), _class.propTypes = {
  currentNote: _propTypes2.default.object,
  defaultName: _propTypes2.default.string
}, _temp);
exports.default = Title;

/***/ }),

/***/ 2672:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _classCallCheck2 = __webpack_require__(5);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(8);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(6);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(9);

var _inherits3 = _interopRequireDefault(_inherits2);

var _class, _temp;

var _react = __webpack_require__(1);

var _propTypes = __webpack_require__(0);

var _propTypes2 = _interopRequireDefault(_propTypes);

var _$rjquery = __webpack_require__(499);

var _browserHelper = __webpack_require__(34);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _sdkCompatibleHelper = __webpack_require__(82);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var DEFAULT_TOP_NAME = 'Docs';
var DEFAULT_TYPE = 0; // title默认type
var USER_TYPE = 1; // 用户编辑了的title

// 设置padding top , 后续需要根据版本号判断是否设置，因为老版本不支持
if ((0, _sdkCompatibleHelper.isSupportHideTitleBar)()) {
  if (_browserHelper2.default.isMobile && _browserHelper2.default.isAndroid) {
    document.body.style.paddingTop = '50px';
  } else if (_browserHelper2.default.isMobile && _browserHelper2.default.isIOS) {
    document.body.style.paddingTop = '48px';
  }
}

var DocTitle = (_temp = _class = function (_Component) {
  (0, _inherits3.default)(DocTitle, _Component);

  function DocTitle(props) {
    (0, _classCallCheck3.default)(this, DocTitle);

    var _this = (0, _possibleConstructorReturn3.default)(this, (DocTitle.__proto__ || Object.getPrototypeOf(DocTitle)).call(this, props));

    _this.handleScroll = function (event) {
      var nextTitleParam = {
        title: DEFAULT_TOP_NAME,
        type: DEFAULT_TYPE
      };
      var titleLineBottom = _this.cacheTitleLineBottom();

      if (!titleLineBottom) return;

      if (window.scrollY > titleLineBottom) {
        nextTitleParam = _this.getTitle();
      }

      if (_this.titleParam.title !== nextTitleParam.title) {
        _this.setLarkTitle(nextTitleParam);
        _this.titleParam = nextTitleParam;
      }
    };

    _this.titleParam = {};
    _this.currentScrollTop = 0;
    _this.continuousScroll = null;
    return _this;
  }

  (0, _createClass3.default)(DocTitle, [{
    key: 'componentDidMount',
    value: function componentDidMount() {
      window.addEventListener('scroll', this.handleScroll);
      this.setLarkTitle();
    }
  }, {
    key: 'componentDidUpdate',
    value: function componentDidUpdate() {
      this.setLarkTitle();
    }
  }, {
    key: 'componentWillUnmount',
    value: function componentWillUnmount() {
      window.removeEventListener('scroll', this.handleScroll);
    }
  }, {
    key: 'getTitle',
    value: function getTitle() {
      var defaultName = this.props.defaultName;

      if (this.props.editor && this.props.editor.plugins.noteTitlePlugin) {
        var title = this.props.editor.plugins.noteTitlePlugin.getTitle();
        return {
          title: title || defaultName,
          type: USER_TYPE
        };
      }
      return {
        title: DEFAULT_TOP_NAME,
        type: DEFAULT_TYPE
      };
    }
  }, {
    key: 'setLarkTitle',
    value: function setLarkTitle(param) {
      var _props = this.props,
          storeLarkTitle = _props.storeLarkTitle,
          currentNote = _props.currentNote;

      var isExternal = currentNote ? currentNote.is_external : false;
      param = param || {
        title: DEFAULT_TOP_NAME,
        type: DEFAULT_TYPE,
        is_external: isExternal
      };

      window.lark.biz.navigation.setTitle(param);
      storeLarkTitle(param.title);
    }
  }, {
    key: 'cacheTitleLineBottom',
    value: function cacheTitleLineBottom() {
      if (!this.titleLineBottom) {
        var editor = this.props.editor;

        if (!editor) return;

        var docContainerEl = editor.getInnerContainer();
        if (!docContainerEl) return;

        var titleEl = docContainerEl.querySelector('div:first-child');
        if (!titleEl) return;

        var $titleEl = (0, _$rjquery.$)(titleEl);
        var lineHeight = $titleEl.css('font-size') || '';
        // 新版ui 顶部多了一个padding
        var bodyPaddingTop = parseInt(getComputedStyle(document.body)['padding-top'], 10) || 0;

        // 1.5 line-height, 只算上边距即1.25
        this.titleLineBottom = $titleEl.offset().top + Number(lineHeight.replace('px', '')) * 1.25 - bodyPaddingTop;
      }

      return this.titleLineBottom;
    }
  }, {
    key: 'render',
    value: function render() {
      return null;
    }
  }]);
  return DocTitle;
}(_react.Component), _class.propTypes = {
  defaultName: _propTypes2.default.string,
  editor: _propTypes2.default.object,
  storeLarkTitle: _propTypes2.default.func,
  currentNote: _propTypes2.default.object
}, _temp);
exports.default = DocTitle;

/***/ })

}]);
//# sourceMappingURL=https://s3.pstatp.com/eesz/resource/bear/js/docs~sheet.3f41428355b50be693dc.js.map