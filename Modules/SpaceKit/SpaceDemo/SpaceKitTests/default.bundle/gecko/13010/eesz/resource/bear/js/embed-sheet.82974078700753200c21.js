(window["webpackJsonp"] = window["webpackJsonp"] || []).push([[16],{

/***/ 2251:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 2252:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.UndoManger = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _cloneDeep2 = __webpack_require__(754);

var _cloneDeep3 = _interopRequireDefault(_cloneDeep2);

var _sheetCommon = __webpack_require__(1591);

var _bytedXEditor = __webpack_require__(299);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var BlockRef = _bytedXEditor.BlockUndoDispatcher.BlockRef;

var BLOCK = 'SHEET';
var MAX_LENGTH = 2147483647;

var UndoManger = exports.UndoManger = function () {
    function UndoManger() {
        (0, _classCallCheck3.default)(this, UndoManger);

        this.blockId = BLOCK;
        this.undoStack = [];
        this.redoStack = [];
        this.embedManageCbs = [];
    }

    (0, _createClass3.default)(UndoManger, [{
        key: 'register',
        value: function register(dispatcher) {
            dispatcher.register(this);
            this.undoDispatcher = dispatcher;
        }
    }, {
        key: 'do',
        value: function _do(cmdData) {
            var undoStackLength = this.undoStack.length;
            if (undoStackLength >= MAX_LENGTH) {
                this.undoStack = this.undoStack.slice(undoStackLength - MAX_LENGTH);
            }
            this.undoStack.push(cmdData);
            this.redoStack = [];
            this.undoDispatcher.do(new BlockRef(BLOCK));
        }
    }, {
        key: 'canUndo',
        value: function canUndo() {
            return this.undoDispatcher && this.undoDispatcher.stack.undoStack.length > 0;
        }
    }, {
        key: 'undo',
        value: function undo() {
            this.undoDispatcher.undo();
        }
    }, {
        key: 'canRedo',
        value: function canRedo() {
            return this.undoDispatcher && this.undoDispatcher.stack.redoStack.length > 0;
        }
    }, {
        key: 'redo',
        value: function redo() {
            this.undoDispatcher.redo();
        }
    }, {
        key: 'clear',
        value: function clear() {
            this.undoStack = [];
            this.redoStack = [];
            this.embedManageCbs = [];
            this.undoDispatcher = null;
        }
    }, {
        key: 'clearBySheetId',
        value: function clearBySheetId(sheetId) {
            this.undoStack = this.undoStack.filter(function (cmdData) {
                return cmdData.sheetId !== sheetId;
            });
            this.redoStack = this.redoStack.filter(function (cmdData) {
                return cmdData.sheetId !== sheetId;
            });
        }
    }, {
        key: 'onUndo',
        value: function onUndo() {
            var cmdData = this.undoStack.pop();
            if (cmdData) {
                this.redoStack.push(cmdData);
                this.notify(cmdData, _sheetCommon.ActionType.undo);
            }
        }
    }, {
        key: 'onRedo',
        value: function onRedo() {
            var cmdData = this.redoStack.pop();
            if (cmdData) {
                this.undoStack.push(cmdData);
                this.notify(cmdData, _sheetCommon.ActionType.redo);
            }
        }
    }, {
        key: 'onDo',
        value: function onDo() {
            this.redoStack = [];
        }
    }, {
        key: 'notify',
        value: function notify(cmdData, type) {
            this.embedManageCbs.forEach(function (cb) {
                return cb(cmdData, type);
            });
        }
    }, {
        key: 'onNotify',
        value: function onNotify(embedCb) {
            this.embedManageCbs.push(embedCb);
        }
    }, {
        key: 'offNotify',
        value: function offNotify(embedCb) {
            this.embedManageCbs = this.embedManageCbs.filter(function (cb) {
                return cb !== embedCb;
            });
        }
    }, {
        key: 'export',
        value: function _export() {
            return (0, _cloneDeep3.default)({
                undoStack: this.undoStack,
                redoStack: this.redoStack
            });
        }
    }, {
        key: 'import',
        value: function _import(undoStack, redoStack) {
            if (undoStack) {
                this.undoStack = (0, _cloneDeep3.default)(undoStack);
            }
            if (redoStack) {
                this.redoStack = (0, _cloneDeep3.default)(redoStack);
            }
        }
    }]);
    return UndoManger;
}();

var undoManger = new UndoManger();
exports.default = undoManger;

/***/ }),

/***/ 2253:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.SheetPlaceholder = undefined;

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _classnames = __webpack_require__(127);

var _classnames2 = _interopRequireDefault(_classnames);

__webpack_require__(3852);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SheetPlaceholder = exports.SheetPlaceholder = function SheetPlaceholder(props) {
    var style = Object.assign({}, props.style);
    var rowCount = props.rowCount,
        colCount = props.colCount,
        rowHeight = props.rowHeight,
        colWidth = props.colWidth;

    if (rowHeight && colWidth) {
        style.backgroundSize = colWidth + 'px ' + rowHeight + 'px';
        if (rowCount && colCount) {
            style.height = rowCount * rowHeight + 1;
            style.width = colCount * colWidth + 1;
        }
    }
    var className = (0, _classnames2.default)(props.className, 'sheet-place-holder', {
        'sheet-place-holder_inline': rowCount && colCount
    });
    return _react2.default.createElement("div", { className: className, style: style });
};
SheetPlaceholder.defaultProps = {
    colWidth: 102,
    rowHeight: 22
};

/***/ }),

/***/ 3833:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.EmbedSheetQuickAccess = undefined;

var _DocSheet = __webpack_require__(3834);

var DocSheet = _interopRequireWildcard(_DocSheet);

var _EmbedSheetQuickAccess = __webpack_require__(3853);

var _EmbedSheetQuickAccess2 = _interopRequireDefault(_EmbedSheetQuickAccess);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj.default = obj; return newObj; } }

exports.EmbedSheetQuickAccess = _EmbedSheetQuickAccess2.default;
exports.default = DocSheet;

/***/ }),

/***/ 3834:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.screenshotPromise = exports.findMention = undefined;

var _regenerator = __webpack_require__(12);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var findMention = exports.findMention = function () {
    var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(mentionId, scrollElement, scrollTopFunc) {
        return _regenerator2.default.wrap(function _callee$(_context) {
            while (1) {
                switch (_context.prev = _context.next) {
                    case 0:
                        _context.t0 = manager;

                        if (!_context.t0) {
                            _context.next = 5;
                            break;
                        }

                        _context.next = 4;
                        return manager.findMention(mentionId, scrollElement, scrollTopFunc);

                    case 4:
                        _context.t0 = _context.sent;

                    case 5:
                        return _context.abrupt('return', _context.t0);

                    case 6:
                    case 'end':
                        return _context.stop();
                }
            }
        }, _callee, this);
    }));

    return function findMention(_x, _x2, _x3) {
        return _ref.apply(this, arguments);
    };
}();

var screenshotPromise = exports.screenshotPromise = function () {
    var _ref2 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee3() {
        var _this2 = this;

        var isBlob = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : true;
        return _regenerator2.default.wrap(function _callee3$(_context3) {
            while (1) {
                switch (_context3.prev = _context3.next) {
                    case 0:
                        if (!manager) {
                            _context3.next = 6;
                            break;
                        }

                        _context3.next = 3;
                        return manager.screenshot(isBlob, true);

                    case 3:
                        return _context3.abrupt('return', {
                            done: function () {
                                var _ref3 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2() {
                                    return _regenerator2.default.wrap(function _callee2$(_context2) {
                                        while (1) {
                                            switch (_context2.prev = _context2.next) {
                                                case 0:
                                                    if (!manager) {
                                                        _context2.next = 3;
                                                        break;
                                                    }

                                                    _context2.next = 3;
                                                    return manager.screenshot(false, false);

                                                case 3:
                                                case 'end':
                                                    return _context2.stop();
                                            }
                                        }
                                    }, _callee2, _this2);
                                }));

                                return function done() {
                                    return _ref3.apply(this, arguments);
                                };
                            }()
                        });

                    case 6:
                        throw new Error('EmbedSheetManager NULL');

                    case 7:
                    case 'end':
                        return _context3.stop();
                }
            }
        }, _callee3, this);
    }));

    return function screenshotPromise() {
        return _ref2.apply(this, arguments);
    };
}();
// 从左到右从上到下的 ThirdPartyComment[]
// 不用包含Resolved
// 不用关心数据是否加载完


exports.mountSheet = mountSheet;
exports.unmountSheet = unmountSheet;
exports.handleCopy = handleCopy;
exports.setMaxWidth = setMaxWidth;
exports.setSize = setSize;
exports.setZoom = setZoom;
exports.destroy = destroy;
exports.getUpdateTime = getUpdateTime;
exports.freeze = freeze;
exports.unfreeze = unfreeze;
exports.enterHistoryMode = enterHistoryMode;
exports.addSheet = addSheet;
exports.pasteSheet = pasteSheet;
exports.delSheet = delSheet;
exports.wakeup = wakeup;
exports.suspend = suspend;
exports.syncVirtualScroll = syncVirtualScroll;
exports.updateSheetSelectionState = updateSheetSelectionState;
exports.getComments = getComments;
exports.getActiveComments = getActiveComments;
exports.getResolvedComments = getResolvedComments;
exports.startNewComment = startNewComment;
exports.saveComment = saveComment;
exports.removeComment = removeComment;
exports.removeTempComment = removeTempComment;
exports.addHighlight = addHighlight;
exports.removeHighlight = removeHighlight;
exports.activateComment = activateComment;
exports.deactivateComment = deactivateComment;
exports.resolveComment = resolveComment;
exports.reopenComment = reopenComment;
exports.getQuoteType = getQuoteType;
exports.findComment = findComment;
exports.setResolvedCommentIds = setResolvedCommentIds;
exports.setCommentData = setCommentData;

var _EmbedSheetManager = __webpack_require__(3835);

var _sheetCommon = __webpack_require__(1591);

var _undoManager = __webpack_require__(2252);

var _undoManager2 = _interopRequireDefault(_undoManager);

var _sheetCore = __webpack_require__(1594);

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var manager = null;
var maxWidth = 240;
var stashActionList = [];
var mountedToken = '';
// 根据 block_token 获取要拉取的 sheet Id 列表
function getSheetIdsByBlockTokens(blockTokens) {
    var sheetIds = [];
    if (blockTokens && blockTokens.length) {
        blockTokens.forEach(function (blockToken) {
            // blockToken 格式： blocktoken_sheetId(block 化后建的) 或者直接是 sheetId(block 化之前建的)
            var result = blockToken.split('_');
            if (result && result.length > 1) {
                sheetIds.push(result[1]);
            } else {
                sheetIds.push(result[0]);
            }
        });
    }
    return sheetIds.length ? sheetIds : undefined;
}
function ensureManager(editor, token, sheetTokenList) {
    if (manager) {
        return manager;
    }
    var sheetIds = getSheetIdsByBlockTokens(sheetTokenList);
    manager = new _EmbedSheetManager.EmbedSheetManager(token, editor, sheetIds);
    manager.setMaxWidth(maxWidth);
    // 方便出问题调试
    window.embedSheetManager = manager;
    return manager;
}
function mountSheet(options) {
    var _this = this;

    var editor = options.editor,
        token = options.token,
        csQueue = options.csQueue,
        undoDispatcher = options.undoDispatcher,
        sheetTokenList = options.sheetTokenList;

    if (mountedToken.length > 0 && mountedToken !== token) {
        return _$moirae2.default.count('ee.docs.sheet.embed_manager_token_diff');
    }
    mountedToken = token;
    manager = ensureManager(editor, token, sheetTokenList);
    if (stashActionList) {
        stashActionList.forEach(function (item) {
            manager[item.key] && manager[item.key].call(_this, item.action);
        });
        stashActionList = [];
    }
    manager.registerCSQueue(csQueue);
    manager.mountSheet(options);
    _undoManager2.default.register(undoDispatcher);
}
function unmountSheet(sheetId) {
    if (!manager) {
        return;
    }
    console.log('UnMountSheet: ' + sheetId);
    manager.unmountSheet(sheetId);
}
function handleCopy(editor, token, sheetId) {
    manager = ensureManager(editor, token);
    if (!manager) {
        return '';
    }
    return manager.handleCopy(sheetId);
}
function setMaxWidth(width) {
    if (manager && width !== maxWidth) {
        maxWidth = width;
        manager.setMaxWidth(width);
    }
}
function setSize(width, height) {
    if (manager) {
        maxWidth = width;
        manager.setSize(width, height);
    }
}
function setZoom(zoom) {
    manager && manager.setZoom(zoom);
}
function destroy() {
    mountedToken = '';
    if (manager) {
        manager.destroy();
        window.embedSheetManagers = manager = null;
    }
    _undoManager2.default.clear();
}
function getUpdateTime() {
    return manager ? manager.updateTime : 0;
}
function freeze() {
    if (manager) {
        manager.freezeView();
    }
}
function unfreeze(token) {
    if (manager) {
        manager.unfreezeView();
    }
}
function enterHistoryMode(sheetId, startTime, endTime, token, editor) {
    if (!manager) {
        ensureManager(editor, token);
    }
    manager && manager.enterHistoryMode(sheetId, startTime, endTime);
}
function getCopySheetAction(sheetId, sheetName, index, rowCount, columnCount) {
    return {
        action: _sheetCommon.ACTIONS.COPY_SHEET,
        sheet_id: sheetId,
        value: {
            index: index,
            sheet_id: sheetId,
            sheet_name: sheetName,
            snapshot: {
                id: sheetId,
                index: index,
                name: sheetName,
                rowCount: rowCount,
                columnCount: columnCount
            }
        }
    };
}
function getSheetInfo() {
    var id = (0, _sheetCommon.genSheetId)();
    var index = 0;
    var baseRev = 0;
    var name = id;
    if (manager) {
        var ids = manager.sheetIds;
        id = (0, _sheetCommon.genSheetId)(ids);
        name = id;
        index = ids.length;
        baseRev = manager.baseRev;
    }
    return { id: id, name: name, index: index, baseRev: baseRev };
}
function addSheet(rowCount, columnCount) {
    var _getSheetInfo = getSheetInfo(),
        id = _getSheetInfo.id,
        name = _getSheetInfo.name,
        index = _getSheetInfo.index,
        baseRev = _getSheetInfo.baseRev;

    var action = getCopySheetAction(id, name, index, rowCount, columnCount);
    if (manager) {
        manager.addSheet(action);
    } else {
        stashActionList.push({
            key: 'addSheet',
            action: action
        });
    }
    return {
        base_rev: baseRev,
        content: [action]
    };
}
function pasteSheet(styles, table) {
    var _getSheetInfo2 = getSheetInfo(),
        id = _getSheetInfo2.id,
        name = _getSheetInfo2.name,
        index = _getSheetInfo2.index,
        baseRev = _getSheetInfo2.baseRev;

    var action = getCopySheetAction(id, name, index, 1, 1);
    if (Array.isArray(styles)) table = styles.join('') + table;
    var snap = (0, _sheetCore.parseHtml2Snapshot)(table);
    if (snap !== null) {
        Object.assign(action.value.snapshot, snap);
    }
    if (manager) {
        manager.pasteSheet(action);
    } else {
        stashActionList.push({
            key: 'pasteSheet',
            action: action
        });
    }
    return {
        base_rev: baseRev,
        content: [action]
    };
}
function delSheet(sheetId) {
    unmountSheet(sheetId);
}
function wakeup(sheetToken, sheetId) {
    manager && manager.wakeup(sheetId);
}
function suspend(sheetToken, sheetId) {
    manager && manager.suspend(sheetId);
}
/**
 * 让每个 sheet 检查一下是否需要 wakeup 或 suspend
 */
function syncVirtualScroll(sheetToken) {
    manager && manager.syncVirtualScroll();
}
function updateSheetSelectionState(sheetId, isSelect) {
    manager && manager.updateSheetSelectionState(sheetId, isSelect);
}
function getComments(sheetId) {
    if (manager) {
        return manager.commentManager.getComments(sheetId);
    } else {
        return [];
    }
}
// 激活单元格 ThirdPartyComment[]
// 不用关心数据是否加载完
function getActiveComments(sheetId) {
    if (manager) {
        return manager.commentManager.getActiveComments(sheetId);
    } else {
        return [];
    }
}
// 表格中被Resolved的ThirdPartyComment[]
// 不用关心数据是否加载完
function getResolvedComments(sheetId) {
    if (manager) {
        return manager.commentManager.getResolvedComments(sheetId);
    } else {
        return [];
    }
}
// 新启动一个Comment，这里会有一个临时CommentId写入Sheet数据结构中
// tempCommentId: 临时CommentId
function startNewComment(sheetId, tempCommentId) {
    if (manager) {
        return manager.commentManager.startNewComment(sheetId, tempCommentId);
    } else {
        return null;
    }
}
// 新启动一个Comment，这里会有一个临时CommentId写入Sheet数据结构中
// tempCommentId: 临时CommentId
// commentId: 正式CommentId
function saveComment(sheetId, tempCommentId, commentId) {
    if (manager) {
        return manager.commentManager.saveComment(sheetId, tempCommentId, commentId);
    } else {
        return Promise.reject('EmbedSheetManagerNULL');
    }
}
// 清除一个Comment，需要扫描所有Sheet
function removeComment(sheetId, commentId) {
    if (manager) {
        return manager.commentManager.removeComment(sheetId, commentId);
    } else {
        return Promise.reject('EmbedSheetManagerNULL');
    }
}
// 清楚临时Comment
function removeTempComment(sheetId, commentId) {
    if (manager) {
        return manager.commentManager.removeTempComment(sheetId, commentId);
    } else {
        return null;
    }
}
// 高亮指定CommentId对应的单元格
function addHighlight(sheetId, commentId) {
    if (manager) {
        return manager.commentManager.addHighlight(sheetId, commentId);
    } else {
        return null;
    }
}
// 高亮指定CommentId对应的单元格
function removeHighlight(sheetId, commentId) {
    if (manager) {
        return manager.commentManager.removeHighlight(sheetId, commentId);
    } else {
        return null;
    }
}
// 高亮指定CommentId对应的单元格
function activateComment(sheetId, commentId) {
    if (manager) {
        return manager.commentManager.activateComment(sheetId, commentId);
    } else {
        return null;
    }
}
// 高亮指定CommentId对应的单元格
function deactivateComment(sheetId, commentId) {
    if (manager) {
        return manager.commentManager.deactivateComment(sheetId, commentId);
    } else {
        return null;
    }
}
// Resolve一个Comment
// 需要确认所有Sheet中的这个Comment确实被Resolve后再Resolve
function resolveComment(sheetId, commentId) {
    if (manager) {
        return manager.commentManager.resolveComment(sheetId, commentId);
    } else {
        return Promise.reject('EmbedSheetManagerNULL');
    }
}
// reopen一个Comment
// 需要确认所有Sheet中的这个Comment确实被Resolve后再Resolve
function reopenComment(sheetId, commentId) {
    if (manager) {
        return manager.commentManager.reopenComment(sheetId, commentId);
    } else {
        return Promise.reject('EmbedSheetManagerNULL');
    }
}
// 行为埋点
function getQuoteType(sheetId, commentId) {
    if (manager) {
        return manager.commentManager.getQuoteType(sheetId, commentId);
    } else {
        return null;
    }
}
// 查找一个Comment并滚动到对应位置，完成后Resolve
function findComment(sheetId, commentId) {
    if (manager) {
        return manager.commentManager.findComment(sheetId, commentId);
    } else {
        return Promise.reject('EmbedSheetManagerNULL');
    }
}
// 设置被解决的Comment列表
function setResolvedCommentIds(sheetId, resolvedCommentIds) {
    if (manager) {
        return manager.commentManager.setResolvedCommentIds(sheetId, resolvedCommentIds);
    } else {
        return Promise.reject('EmbedSheetManagerNULL');
    }
}
function setCommentData(sheetId, commentData) {
    if (manager) {
        return manager.commentManager.setCommentData(sheetId, commentData);
    } else {
        return Promise.reject('EmbedSheetManagerNULL');
    }
}
window.findMention = findMention;
window.screenshotPromise = screenshotPromise;

/***/ }),

/***/ 3835:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.EmbedSheetManager = undefined;

var _regenerator = __webpack_require__(12);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _range2 = __webpack_require__(235);

var _range3 = _interopRequireDefault(_range2);

var _isUndefined2 = __webpack_require__(227);

var _isUndefined3 = _interopRequireDefault(_isUndefined2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _reactDom = __webpack_require__(47);

var _reactDom2 = _interopRequireDefault(_reactDom);

var _$store = __webpack_require__(64);

var _$store2 = _interopRequireDefault(_$store);

var _reactRedux = __webpack_require__(300);

var _sheet = __webpack_require__(745);

var _encode = __webpack_require__(2196);

var _sheetIo = __webpack_require__(1621);

var _sheetCore = __webpack_require__(1594);

var _sheetCommon = __webpack_require__(1591);

var _sheetHelper = __webpack_require__(1893);

var _modal = __webpack_require__(1900);

var _tea = __webpack_require__(42);

var _Subject = __webpack_require__(3836);

var _EmbedSheetManagerImp = __webpack_require__(3838);

var _EmbedSheetManagerImp2 = _interopRequireDefault(_EmbedSheetManagerImp);

var _EmbedSheetCommentManager = __webpack_require__(3842);

var _EmbedSheetCommentManager2 = _interopRequireDefault(_EmbedSheetCommentManager);

var _PerformanceEmbedSheet = __webpack_require__(3843);

var _PerformanceEmbedSheet2 = _interopRequireDefault(_PerformanceEmbedSheet);

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

__webpack_require__(2251);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function getSnapshotByAction(action) {
    if (action.action === _sheetCommon.ACTIONS.ADD_SHEET) {
        return {
            id: action.sheet_id,
            index: action.value.index,
            name: action.sheet_name
        };
    } else if (action.action === _sheetCommon.ACTIONS.COPY_SHEET) {
        return action.value.snapshot || {
            id: action.value.sheet_id,
            name: action.value.sheet_name,
            index: action.value.index
        };
    }
    throw new Error('Invalid SnapshotAction');
}
function defaultSheets() {
    return {
        1: {
            snapshot: {
                id: '1',
                index: 0,
                name: 'Sheet1'
            },
            actions: [],
            loaded: false
        }
    };
}

var EmbedSheetManager = function () {
    function EmbedSheetManager(token, editor, sheetIds) {
        var _this = this;

        (0, _classCallCheck3.default)(this, EmbedSheetManager);

        this.editor = editor;
        this.token = '';
        this.mountOptions = {};
        this.sheetComponents = new Map();
        this.spreadLoaded = false;
        this.actionAfterLoaded = [];
        this.clientVarsReady = false;
        this.unusableSheets = [];
        this.mountedSheetOptions = {}; // mountSheet 时候传的参数，包含一些回调
        this.mountedSheets = [];
        this.sheets = {};
        this.maxWidth = 1;
        this.hosts = {};
        this.mountQueue = [];
        this.mounting = null;
        this.rafId = null;
        this.needUniqFitRow = {};
        this.clientVarsLoadingTimer = null;
        this.updateSheetSelectionStateCoreTimer = 0;
        this.sheetSelectionState = [];
        this._mountSheet = new _Subject.Subject();
        this._unmountSheet = new _Subject.Subject();
        /**
         * watchdog需要记录的时间
         */
        this._updateTime = 0;
        this.getContextBindList = function () {
            return [{ key: _sheetIo.CollaborativeEvents.RESTORE_SHEET, handler: _this.onRestoreSheet }];
        };
        this.bindSheetEvents = function () {
            var context = _this.collaSpread.context;
            _this.getContextBindList().forEach(function (event) {
                context.bind(event.key, event.handler);
            });
        };
        this.unbindSheetEvents = function () {
            var context = _this.collaSpread.context;
            _this.getContextBindList().forEach(function (event) {
                context.unbind(event.key, event.handler);
            });
        };
        this.onRestoreSheet = function (sheetId) {
            if (!_this.imp) return;
            _this.imp.createSheetFromDataStore(sheetId);
            _this.updateEmbedSheet(sheetId);
        };
        this.checkSpreadLoaded = function () {
            _this.spreadLoaded = _this.imp && _this.imp.isCollaSpreadLoaded() || false;
            return _this.spreadLoaded;
        };
        this.checkAllSheetHostMounted = function () {
            // 检查是否所有的sheet都挂载了host
            var sheets = _this.imp && _this.imp.collaSpread.spread.sheets || [];
            var _iteratorNormalCompletion = true;
            var _didIteratorError = false;
            var _iteratorError = undefined;

            try {
                for (var _iterator = sheets[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
                    var sheet = _step.value;

                    if (sheet && (0, _isUndefined3.default)(sheet._host)) {
                        // 有未挂载host的sheet
                        return false;
                    }
                }
            } catch (err) {
                _didIteratorError = true;
                _iteratorError = err;
            } finally {
                try {
                    if (!_iteratorNormalCompletion && _iterator.return) {
                        _iterator.return();
                    }
                } finally {
                    if (_didIteratorError) {
                        throw _iteratorError;
                    }
                }
            }

            return true;
        };
        this.onSpreadLoaded = function (clientVarsData) {
            _this.checkSpreadLoaded();
            if (_this.spreadLoaded) {
                var sheets = _this.sheets;

                for (var sheetId in sheets) {
                    sheets[sheetId].loaded = true;
                }
                _this.imp && _this.imp.handleSpreadLoaded(clientVarsData);
                Object.getOwnPropertyNames(_this.hosts).forEach(function (sheetId) {
                    _this.updateEmbedSheet(sheetId);
                });
                setTimeout(function () {
                    _this.updateUnusableSheet(true);
                }, 200);
                _this.initChartData();
                _this.registerChartChange();
            }
            clearTimeout(_this.clientVarsLoadingTimer);
        };
        this.onSpreadLoading = function () {
            _this.spreadLoaded = false;
        };
        this.registerCSQueue = function (csQueue) {
            _this.collaSpread.engine.registerCSQueue(csQueue);
        };
        this.onApplyActions = function (actions) {
            _this._updateTime = Date.now();
            var sheets = _this.sheets;

            actions.forEach(function (action) {
                var sheetId = action.action === _sheetCommon.ACTIONS.COPY_SHEET ? action.value.sheet_id : action.sheet_id;
                switch (action.action) {
                    case _sheetCommon.ACTIONS.COPY_SHEET:
                    case _sheetCommon.ACTIONS.ADD_SHEET:
                        var snapshot = getSnapshotByAction(action);
                        if (sheets[sheetId]) {
                            sheets[sheetId].snapshot = snapshot;
                        } else {
                            sheets[sheetId] = {
                                snapshot: snapshot,
                                actions: [],
                                loaded: true
                            };
                        }
                        break;
                    default:
                        if (sheets[sheetId]) {
                            sheets[sheetId].actions.push(action);
                        }
                }
            });
            _this.imp && _this.imp.applyActions(actions, false);
            _this.updateUnusableSheet(true);
        };
        this.onProduceChangeset = function () {
            _this._updateTime = Date.now();
        };
        this.onLocalConflict = function () {
            (0, _tea.collectSuiteEvent)('client_sheet_edit_conflict_local');
        };
        this.onRejectCommit = function () {
            (0, _tea.collectSuiteEvent)('client_sheet_edit_conflict');
            _this.onConflict();
        };
        this.onError = function (data) {
            if (data.code !== _sheetCommon.Errors.ERROR_WATCH_DOG_ALERT && data.code !== _sheetCommon.Errors.ERROR_WATCH_DOG_DONE && data.code !== _sheetCommon.Errors.ERROR_WATCH_DOG_WARNING) {
                _this.freezeSheet(true);
            }
            (0, _modal.showServerErrorModal)(data.code, 'embed-sheet-manager');
        };
        this.onConflict = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee() {
            var backup, record, backupActions;
            return _regenerator2.default.wrap(function _callee$(_context) {
                while (1) {
                    switch (_context.prev = _context.next) {
                        case 0:
                            backup = _this.collaSpread.backup;

                            _this.freezeSheet(true);
                            // doc 插 sheet 遇到冲突时候存成冲突记录, 删掉 local 数据
                            _context.prev = 2;
                            record = {
                                timestamp: Date.now(),
                                baseRev: -1,
                                actions: ''
                            };
                            _context.next = 6;
                            return backup.getBackupActions();

                        case 6:
                            backupActions = _context.sent;

                            record.actions = (0, _encode.gzip)(JSON.stringify(backupActions));
                            _context.next = 10;
                            return backup.checkBackupRev();

                        case 10:
                            record.baseRev = _context.sent;
                            _context.next = 13;
                            return backup.clearBackup();

                        case 13:
                            _context.next = 15;
                            return backup.addLocalRecord(record);

                        case 15:
                            _context.next = 20;
                            break;

                        case 17:
                            _context.prev = 17;
                            _context.t0 = _context['catch'](2);

                            // Raven上报
                            _$moirae2.default.ravenCatch(_context.t0);

                        case 20:
                            (0, _modal.showError)(_modal.ErrorTypes.ERROR_ACTION_CONFLICT, {
                                onConfirm: function onConfirm() {
                                    _this.collaSpread.context.trigger(_sheetIo.CollaborativeEvents.CONFLICT_HANDLE);
                                }
                            });

                        case 21:
                        case 'end':
                            return _context.stop();
                    }
                }
            }, _callee, _this, [[2, 17]]);
        }));
        this.screenshot = function (isBlob, isScreenShotMode) {
            return _this.imp && _this.imp.screenshot(isBlob, isScreenShotMode);
        };
        this.addSheet = function (action, sheetId) {
            _this.executeLocal(action);
        };
        this.pasteSheet = function (action) {
            _this.executeLocal(action);
            _this.needUniqFitRow[action.sheet_id] = true;
        };
        this.collectUserChange = function (actions) {
            _this.collaSpread.context.trigger(_sheetIo.CollaborativeEvents.PRODUCE_ACTIONS, actions);
        };
        this.onMountSheetComp = function (sheetId, comp) {
            _this.sheetComponents.set(sheetId, comp);
            // TODO: 这个是要干啥...
            _this.imp && _this.imp.createSheetFromDataStore(sheetId);
            var result = _this.updateEmbedSheet(sheetId);
            if (_this.spreadLoaded && !result) {
                _this.collaSpread.sync.forceHeartbeatSync(function () {
                    return;
                }, function () {
                    return;
                });
            }
        };
        this.onUnmountSheetComp = function (sheetId, comp) {
            _this.sheetComponents.delete(sheetId);
            var snapshot = _this.imp && _this.imp.getSheetSnapshot(sheetId);
            var s = _this.sheets[sheetId];
            if (snapshot && s && s.loaded) {
                _this.sheets[sheetId] = {
                    snapshot: (0, _sheetHelper.pickSheetSnapshot)(snapshot),
                    loaded: true,
                    actions: []
                };
            }
        };
        this.onMountEmbedSheet = function (sheetId) {
            var sheetOptions = _this.mountedSheetOptions[sheetId];
            if (sheetOptions && typeof sheetOptions.mountCb === 'function') {
                sheetOptions.mountCb();
            }
        };
        this.mountSheet = function (options) {
            var sheetId = options.sheetId,
                container = options.host,
                order = options.order;

            if (!container) {
                return _$moirae2.default.teaLog({ key: 'client_sheet_embed_manager_no_container' });
            }
            // TODO: 现在同个 sheetId 只能挂载在一个 DOM
            // 后续调整 UI 架构解决
            if (_this.mountQueue.filter(function (item) {
                return item.sheetId === sheetId;
            }).length > 0) {
                return _$moirae2.default.teaLog({ key: 'client_sheet_embed_manager_mount_queue_repeat' });
            }
            // 建立一个属于我们sheet的挂载点，保证不受doc改动的影响。
            var host = document.createElement('div');
            container.innerHTML = '';
            container.appendChild(host);
            _this.hosts[sheetId] = host;
            _this.mountedSheetOptions[sheetId] = options;
            _this._mountSheet.next({ sheetId: sheetId, order: order });
            _this.innerMountSheet(sheetId, options);
        };
        this.mountNext = function () {
            var mountSheetInfo = _this.mountQueue.shift();
            _this.mounting = null;
            if (!mountSheetInfo) {
                return;
            }
            var sheetId = mountSheetInfo.sheetId,
                options = mountSheetInfo.options;

            _this.mountOptions[sheetId] = options;
            if (!sheetId) {
                return;
            }
            _this.mounting = mountSheetInfo;
            _this.rafId = (0, _sheetCommon.raf)(function () {
                if (!_this.imp) {
                    return _$moirae2.default.teaLog({ key: 'client_sheet_embed_manager_no_imp' });
                }
                var host = _this.hosts[sheetId];
                _this.rafId = null;
                _reactDom2.default.render(_react2.default.createElement(_reactRedux.Provider, { store: _$store2.default }, _react2.default.createElement(_PerformanceEmbedSheet2.default, { editor: _this.editor, manager: _this, maxWidth: _this.maxWidth, sheetId: sheetId, onMount: _this.onMountSheetComp, onUnmount: _this.onUnmountSheetComp, onMountEmbedSheet: _this.onMountEmbedSheet, collaSpread: _this.imp.collaSpread })), host);
                // 强制超时处理
                // TODO：再做实验优化
                setTimeout(function () {
                    _this.mounting = null;
                    _this.mountNext();
                }, 200);
            });
        };
        this.freezeView = function () {
            _this.freezeSheet(true);
        };
        this.unfreezeView = function () {
            _this.freezeSheet(false);
        };
        this.findMention = function () {
            var _ref2 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2(mentionId, scrollElement, scrollTopFunc) {
                return _regenerator2.default.wrap(function _callee2$(_context2) {
                    while (1) {
                        switch (_context2.prev = _context2.next) {
                            case 0:
                                return _context2.abrupt('return', new Promise(function (resolve, reject) {
                                    var core = function core() {
                                        // 等所有的sheet都挂载了host且加载完毕再定位@人的目标单元格
                                        if (_this.checkSpreadLoaded() && _this.imp && _this.checkAllSheetHostMounted()) {
                                            resolve(_this.imp.findMention(mentionId, scrollElement, scrollTopFunc));
                                        } else {
                                            setTimeout(function () {
                                                core();
                                            }, 100);
                                        }
                                    };
                                    core();
                                }));

                            case 1:
                            case 'end':
                                return _context2.stop();
                        }
                    }
                }, _callee2, _this);
            }));

            return function (_x, _x2, _x3) {
                return _ref2.apply(this, arguments);
            };
        }();
        this.updateSheetSelectionState = function (sheetId, isSelect) {
            var updateSheetSelectionStateCore = function updateSheetSelectionStateCore() {
                if (_this.sheetSelectionState.length === 1) {
                    _this.sheetSelectionState.forEach(function (selectedSheetId) {
                        var sheet = _this.imp && _this.imp.collaSpread.spread.getSheetFromId(selectedSheetId);
                        if (!sheet) {
                            return;
                        }
                        var selectionModel = sheet._selectionModel.toArray();
                        if (selectionModel.length === 0) {
                            _this.updateEmbedSheet(selectedSheetId, true);
                        } else {
                            _this.updateEmbedSheet(selectedSheetId, false);
                        }
                    });
                } else {
                    _this.sheetSelectionState.forEach(function (selectedSheetId) {
                        _this.updateEmbedSheet(selectedSheetId, true);
                    });
                }
            };
            window.clearTimeout(_this.updateSheetSelectionStateCoreTimer);
            if (isSelect === true) {
                _this.sheetSelectionState.push(sheetId);
                _this.updateSheetSelectionStateCoreTimer = window.setTimeout(updateSheetSelectionStateCore, 10);
            } else {
                _this.sheetSelectionState = _this.sheetSelectionState.filter(function (item) {
                    return item !== sheetId;
                });
                _this.updateEmbedSheet(sheetId, false);
            }
        };
        this.destroy = function () {
            try {
                _this.mountQueue = [];
                _this.mounting = null;
                if (_this.rafId) {
                    (0, _sheetCommon.unraf)(_this.rafId);
                    _this.rafId = null;
                }
                _this.unbindSheetEvents();
                _this.collaSpread.context.removeEventHandler(_this);
                _this.cmtManager.destroy();
                // 三行顺序不可变更，具有前后依赖
                // 先卸载EmbedSheet对象
                _this.sheetComponents.forEach(function (comp, sheetId) {
                    return _this.unmountSheet(sheetId);
                });
                // 再卸载IMP，在其中会卸载Spread对象
                _this.imp && _this.imp.destroy();
                // 最后清理hosts
                _this.hosts = {};
                _sheetIo.watchDog.watchDone();
                _$store2.default.dispatch((0, _sheet.resetSpreadState)());
            } catch (ex) {
                _$moirae2.default.ravenCatch(ex, {
                    scm: JSON.stringify(window.scm),
                    key: 'SHEET_EMB_DESTROY_ERROR'
                });
                throw ex;
            }
        };
        this.token = token;
        this._mountSheet.subscribe(function (_ref3) {
            var sheetId = _ref3.sheetId,
                order = _ref3.order;

            _this.mountedSheets.splice(order, 0, sheetId);
        });
        this._unmountSheet.subscribe(function (sheetId) {
            var index = _this.mountedSheets.indexOf(sheetId);
            if (index > -1) {
                _this.mountedSheets.splice(index, 1);
            }
        });
        this.createImp(sheetIds);
        this.createCommentManager();
        this.bindSheetEvents();
    }

    (0, _createClass3.default)(EmbedSheetManager, [{
        key: 'createImp',
        value: function createImp(sheetIds) {
            var sheetId = sheetIds && sheetIds.length ? sheetIds[0] : undefined;
            this.imp = new _EmbedSheetManagerImp2.default(this, sheetId);
            this.collaSpread.context.addEventHandler(this);
        }
    }, {
        key: 'createCommentManager',
        value: function createCommentManager() {
            this.cmtManager = new _EmbedSheetCommentManager2.default(this);
        }
    }, {
        key: 'registerChartChange',
        value: function registerChartChange() {
            var sheets = this.imp && this.imp.collaSpread.spread.sheets || [];
            sheets.forEach(function (sheet) {
                sheet.chartModel.registerChartChange(function (params) {
                    if (params.changeType === _sheetCore.ChartChangeType.Del) {
                        _$store2.default.dispatch((0, _sheet.delChart)(sheet.id(), params.chartId));
                    } else if (params.chart) {
                        _$store2.default.dispatch((0, _sheet.setChart)(params.chart, true));
                    }
                });
            });
        }
    }, {
        key: 'initChartData',
        value: function initChartData() {
            var sheets = this.imp && this.imp.collaSpread.spread.sheets || [];
            var data = {};
            sheets.forEach(function (s) {
                return data[s._id_] = s.getChartMap();
            });
            _$store2.default.dispatch((0, _sheet.initChart)(data));
        }
    }, {
        key: 'onClientVars',
        value: function onClientVars(args) {
            var sheetSnapshots = args.snapshot.sheets || {};
            this.sheets = defaultSheets();
            for (var name in sheetSnapshots) {
                var sheetSnapshot = sheetSnapshots[name];
                var sheetId = sheetSnapshot.id;
                this.sheets[sheetId] = {
                    snapshot: sheetSnapshot,
                    actions: [],
                    loaded: false
                };
            }
            for (var _sheetId in this.sheets) {
                this.sheets[_sheetId].loaded = false;
            }
            this.clientVarsReady = true;
            this.imp && this.imp.handleClientVars(args);
            this.updateUnusableSheet(false);
            // 10s 如果没有调用 spreadLoaded 的话，则上报超时
            clearTimeout(this.clientVarsLoadingTimer);
            this.clientVarsLoadingTimer = setTimeout(function () {
                (0, _tea.collectSuiteEvent)('client_dev_embedsheet_clientvars_timeout');
            }, 10000); // 10s
        }
        // execute action and collect actions

    }, {
        key: 'executeLocal',
        value: function executeLocal(action) {
            this.checkSpreadLoaded();
            if (this.spreadLoaded && this.imp) {
                this.imp.applyActions([action], true);
            } else {
                this.actionAfterLoaded.push([action]);
            }
        }
    }, {
        key: 'freezeSheet',
        value: function freezeSheet(freeze) {
            _$store2.default.dispatch((0, _sheet.freezeSheetToggle)(freeze));
        }
    }, {
        key: 'setMaxWidth',
        value: function setMaxWidth(maxWidth) {
            this.maxWidth = maxWidth;
            this.sheetComponents.forEach(function (comp) {
                return comp.onMaxWidthChange(maxWidth);
            });
        }
    }, {
        key: 'setSize',
        value: function setSize(width, height) {
            this.sheetComponents.forEach(function (comp) {
                return comp.onSizeChange(width, height);
            });
        }
    }, {
        key: 'wakeup',
        value: function wakeup(sheetId) {
            this.collaSpread.context.trigger(_sheetIo.CollaborativeEvents.WAKEUP, sheetId);
        }
    }, {
        key: 'suspend',
        value: function suspend(sheetId) {
            this.collaSpread.context.trigger(_sheetIo.CollaborativeEvents.SUSPEND, sheetId);
        }
    }, {
        key: 'syncVirtualScroll',
        value: function syncVirtualScroll(sheetIdList) {
            this.collaSpread.context.trigger(_sheetIo.CollaborativeEvents.SYNC_VIRTUAL_SCROLL, {
                sheetIdList: sheetIdList
            });
        }
    }, {
        key: 'setZoom',
        value: function setZoom(zoom) {
            this.sheetComponents.forEach(function (comp) {
                return comp.onZoomChange(zoom);
            });
        }
    }, {
        key: 'handleFitRow',
        value: function handleFitRow(sheetId) {
            var sheet = this.imp && this.imp.collaSpread.spread.getSheetFromId(sheetId);
            if (!sheet) {
                return;
            }
            var changedRows = (0, _range3.default)(sheet.getRowCount());
            var changesets = (0, _sheetHelper.uniqFitRow)(sheet, changedRows);
            this.collectUserChange(changesets);
            delete this.needUniqFitRow[sheetId];
        }
    }, {
        key: 'addUnusableSheet',
        value: function addUnusableSheet(sheetId) {
            if (this.unusableSheets.indexOf(sheetId) === -1) {
                this.unusableSheets.push(sheetId);
            }
        }
    }, {
        key: 'updateUnusableSheet',
        value: function updateUnusableSheet(withReport) {
            var _this2 = this;

            var readySheets = [];
            if (this.unusableSheets.length === 0) {
                return;
            }
            if (withReport) {
                _$moirae2.default.teaLog({ key: 'client_sheet_embed_manager_update_unusable_2' });
            }
            this.unusableSheets.forEach(function (sheetId) {
                var sheet = _this2.imp && _this2.imp.collaSpread.spread.getSheetFromId(sheetId) || null;
                if (!sheet) {
                    _this2.imp && _this2.imp.createSheetFromDataStore(sheetId, withReport);
                }
                if (_this2.updateEmbedSheet(sheetId, false, withReport)) {
                    readySheets.push(sheetId);
                }
            });
            this.unusableSheets = this.unusableSheets.filter(function (sheetId) {
                return readySheets.indexOf(sheetId) === -1;
            });
            if (withReport) {
                if (this.unusableSheets.length === 0) {
                    _$moirae2.default.teaLog({ key: 'client_sheet_embed_manager_update_unusable_fin_2' });
                } else {
                    _$moirae2.default.teaLog({ key: 'client_sheet_embed_manager_update_unusable_fail_2' });
                }
            }
        }
    }, {
        key: 'updateEmbedSheet',
        value: function updateEmbedSheet(sheetId) {
            var isSelect = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;
            var withReport = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : false;

            var comp = this.sheetComponents.get(sheetId);
            if (!this.imp) {
                this.addUnusableSheet(sheetId);
                if (withReport) {
                    _$moirae2.default.teaLog({ key: 'client_sheet_embed_manager_no_imp_reuse_2' });
                }
                return false;
            }
            if (!comp) {
                this.addUnusableSheet(sheetId);
                if (withReport) {
                    _$moirae2.default.teaLog({ key: 'client_sheet_embed_manager_no_comp_reuse_2' });
                }
                return false;
            }
            var content = this.imp.getEmbedSheet(sheetId, isSelect);
            if (!content) {
                this.addUnusableSheet(sheetId);
                if (withReport) {
                    _$moirae2.default.teaLog({ key: 'client_sheet_embed_manager_no_embed_content_reuse_2' });
                }
                return false;
            }
            comp.setEmbedSheet(content);
            if (this.needUniqFitRow[sheetId] === true) {
                this.handleFitRow(sheetId);
            }
            return true;
        }
        // TODO：换一个好听的名字

    }, {
        key: 'innerMountSheet',
        value: function innerMountSheet(sheetId, options) {
            this.mountQueue.push({
                sheetId: sheetId,
                options: options
            });
            if (!this.mounting) {
                this.mountNext();
            }
        }
    }, {
        key: 'handleCopy',
        value: function handleCopy(sheetId) {
            return this.imp ? this.imp.handleCopy(sheetId) : '';
        }
    }, {
        key: 'unmountSheet',
        value: function unmountSheet(sheetId) {
            var _this3 = this;

            var host = this.hosts[sheetId];
            // 同一个sheet可能被unmount多次
            if (!host) {
                return;
            }
            if (!this.spreadLoaded) {
                return;
            }
            console.log('UnmountSheet ' + sheetId);
            delete this.hosts[sheetId];
            this.sheetSelectionState = this.sheetSelectionState.filter(function (item) {
                return item !== sheetId;
            });
            // 查找下一个应该被激活的表格
            var findNextActiveSheetId = function findNextActiveSheetId() {
                if (!_this3.imp) {
                    return '';
                }
                // 寻找mountedSheets中待移除表格的顺位
                var oldActiveIndex = _this3.mountedSheets.findIndex(function (item) {
                    return item === sheetId;
                });
                var collaSpread = _this3.imp.collaSpread;
                var spread = collaSpread.spread;
                var currentSheet = spread.getActiveSheet();
                // 如果移除的表格不是当前激活的表格，则无需操作
                if (currentSheet.id() !== sheetId) {
                    return currentSheet.id();
                }
                // 设置新顺位
                // 如果是头部，则新表格继续是头部，否则是删除顺位的前一个表格
                var newActiveIndex = oldActiveIndex > 0 ? oldActiveIndex - 1 : 1;
                var newActiveSheetId = _this3.mountedSheets[newActiveIndex];
                return newActiveSheetId;
            };
            var setNextActiveSheet = function setNextActiveSheet(nextActiveSheetId) {
                if (_this3.imp) {
                    var collaSpread = _this3.imp.collaSpread;
                    var spread = collaSpread.spread;
                    if (_this3.mountedSheets.length > 0) {
                        var nextActiveSheetIndex = spread.getSheetIndexFromId(nextActiveSheetId) || 0;
                        var currentActiveSheetIndex = spread.getActiveSheetIndex();
                        if (nextActiveSheetIndex !== currentActiveSheetIndex) {
                            spread.setActiveSheetIndex(spread.getSheetIndexFromId(nextActiveSheetId) || 0);
                        } else {
                            spread.uiEvents && spread.uiEvents.emit(_sheetCommon.Events.SheetTabRepaint, { workbook: spread });
                        }
                    }
                }
            };
            var nextActiveSheetId = findNextActiveSheetId();
            this._unmountSheet.next(sheetId);
            this.mountQueue = this.mountQueue.filter(function (item) {
                return item.sheetId !== sheetId;
            });
            if (this.rafId && this.mounting && this.mounting.sheetId === sheetId) {
                (0, _sheetCommon.unraf)(this.rafId);
                this.rafId = null;
                this.mountNext();
                return;
            }
            try {
                // 下述两句不可以调换位置，因为需要先将DOM移除，再出发FullSheetTabs的渲染更新
                // 渲染更新会依赖DOM位置
                _reactDom2.default.unmountComponentAtNode(host);
                // 设置新的激活表格
                if (nextActiveSheetId && nextActiveSheetId.length > 0) {
                    setNextActiveSheet(nextActiveSheetId);
                }
            } catch (e) {
                // Raven上报
                _$moirae2.default.ravenCatch(e);
            }
        }
    }, {
        key: 'onDataTable',
        value: function onDataTable(sheetId, rowData) {
            var sheet = this.sheets[sheetId];
            if (sheet) {
                if (!sheet.snapshot.data) {
                    sheet.snapshot.data = { dataTable: {} };
                }
                Object.assign(sheet.snapshot.data.dataTable, rowData);
            }
        }
    }, {
        key: 'onProduceActions',
        value: function onProduceActions(actions) {
            this.groupActions(actions);
        }
    }, {
        key: 'groupActions',
        value: function groupActions(actions) {
            var sheets = this.sheets;

            actions.forEach(function (action) {
                var sheetId = action.action === _sheetCommon.ACTIONS.COPY_SHEET ? action.value.sheet_id : action.sheet_id;
                switch (action.action) {
                    case _sheetCommon.ACTIONS.COPY_SHEET:
                    case _sheetCommon.ACTIONS.ADD_SHEET:
                        var snapshot = getSnapshotByAction(action);
                        if (sheets[sheetId]) {
                            sheets[sheetId].snapshot = snapshot;
                        } else {
                            sheets[sheetId] = {
                                snapshot: snapshot,
                                actions: [],
                                loaded: true
                            };
                        }
                        break;
                    case _sheetCommon.ACTIONS.DEL_SHEET:
                        delete sheets[sheetId];
                        break;
                    case _sheetCommon.ACTIONS.SET_SHEET:
                        if (sheets[sheetId]) {
                            sheets[sheetId].snapshot.name = action.value.sheet_name;
                        }
                        break;
                    default:
                        if (sheets[sheetId]) {
                            sheets[sheetId].actions.push(action);
                        }
                }
            });
        }
    }, {
        key: 'onRefetchClientVars',
        value: function onRefetchClientVars() {
            this.sheets = {};
        }
    }, {
        key: 'updateTime',
        get: function get() {
            return this._updateTime;
        }
    }, {
        key: 'sheetIds',
        get: function get() {
            return Object.keys(this.sheets);
        }
    }, {
        key: 'baseRev',
        get: function get() {
            return this.collaSpread.engine.getBaseRev();
        }
    }, {
        key: 'commentManager',
        get: function get() {
            return this.cmtManager;
        }
    }, {
        key: 'collaSpread',
        get: function get() {
            return this.imp.collaSpread;
        }
    }]);
    return EmbedSheetManager;
}();

exports.EmbedSheetManager = EmbedSheetManager;

/***/ }),

/***/ 3836:
/***/ (function(module, exports, __webpack_require__) {

"use strict";

function __export(m) {
    for (var p in m) if (!exports.hasOwnProperty(p)) exports[p] = m[p];
}
Object.defineProperty(exports, "__esModule", { value: true });
__export(__webpack_require__(3837));
//# sourceMappingURL=Subject.js.map

/***/ }),

/***/ 3837:
/***/ (function(module, exports, __webpack_require__) {

"use strict";

Object.defineProperty(exports, "__esModule", { value: true });
var rxjs_1 = __webpack_require__(781);
exports.Subject = rxjs_1.Subject;
//# sourceMappingURL=Subject.js.map

/***/ }),

/***/ 3838:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _find2 = __webpack_require__(238);

var _find3 = _interopRequireDefault(_find2);

var _each2 = __webpack_require__(1574);

var _each3 = _interopRequireDefault(_each2);

var _toArray2 = __webpack_require__(3876);

var _toArray3 = _interopRequireDefault(_toArray2);

var _some2 = __webpack_require__(3880);

var _some3 = _interopRequireDefault(_some2);

var _uniq2 = __webpack_require__(352);

var _uniq3 = _interopRequireDefault(_uniq2);

var _collaborative_spread = __webpack_require__(2125);

var _sheetCore = __webpack_require__(1594);

var _sheetCommon = __webpack_require__(1591);

var _sheetIo = __webpack_require__(1621);

var _utils = __webpack_require__(1678);

var _sheet = __webpack_require__(1660);

var _sheet2 = __webpack_require__(745);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _$store = __webpack_require__(64);

var _$store2 = _interopRequireDefault(_$store);

var _EmbedSheet = __webpack_require__(3839);

var _EmbedSheet2 = _interopRequireDefault(_EmbedSheet);

var _EmbedUndoManager = __webpack_require__(3841);

var _EmbedUndoManager2 = _interopRequireDefault(_EmbedUndoManager);

var _undoManager = __webpack_require__(2252);

var _undoManager2 = _interopRequireDefault(_undoManager);

var _browserHelper = __webpack_require__(27);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var HorizontalPosition = _sheetCore.Sheets.HorizontalPosition,
    VerticalPosition = _sheetCore.Sheets.VerticalPosition;

var showCellTimer = void 0;
var highCellTimer = void 0;

var EmbedSheetManagerImp = function () {
    function EmbedSheetManagerImp(manager, firstSheetId) {
        var _this = this;

        (0, _classCallCheck3.default)(this, EmbedSheetManagerImp);

        this.actionAfterLoaded = [];
        this.spreadLoaded = false;
        this.screenShotKeys = [];
        this.screenShotIdx = 0;
        this.screenShotResolve = null;
        this.screenShotReject = null;
        this.isScreenShotMode = false;
        this.isBlob = false;
        this.cachedEmbedSheet = {};
        this.isCollaSpreadLoaded = function () {
            if (!_this.spreadLoaded) {
                var reduxState = _$store2.default.getState();
                var spreadState = reduxState.sheet.fetchState.spreadState;
                _this.spreadLoaded = spreadState.loaded;
            }
            return _this.spreadLoaded;
        };
        this.isClientVarsReady = function () {
            return _this.manager.clientVarsReady;
        };
        this.getContextBindList = function () {
            return [{ key: _sheetIo.CollaborativeEvents.APPLY_ACTIONS_LOCAL, handler: _this.clearRedDot }];
        };
        this.bindSheetEvents = function () {
            var context = _this.collaSpread.context;
            _this.getContextBindList().forEach(function (event) {
                context.bind(event.key, event.handler);
            });
        };
        this.unbindSheetEvents = function () {
            var context = _this.collaSpread.context;
            _this.getContextBindList().forEach(function (event) {
                context.unbind(event.key, event.handler);
            });
        };
        this.createCollaborativeSpread = function (firstSheetId) {
            _this.collaSpread = new _collaborative_spread.CollaborativeSpread(_this.manager.token, firstSheetId, true, {
                scrollbarMaxAlign: true,
                showHorizontalScrollbar: false,
                showVerticalScrollbar: false,
                hideSelection: true,
                embed: true
            }, function () {
                return;
            }, function () {
                return;
            });
            _this.collaSpread.switch();
            var spread = _this.collaSpread.spread;
            spread.defaults = {
                rowHeaderColWidth: 24
            };
            spread.defaultStyle = {
                wordWrap: _sheetCommon.WORD_WRAP_TYPE.AUTOWRAP,
                vAlign: _sheetCommon.VerticalAlign.Center
            };
            _this.collaSpread.spreadLoaded = _this.manager.spreadLoaded;
            spread.setUndoManger(new _EmbedUndoManager2.default(spread, _undoManager2.default));
        };
        this.handleClientVars = function (clientVarsDataRaw) {
            if (!_this.manager.clientVarsReady) {
                return;
            }
            var snapshot = {
                sheets: {},
                version: clientVarsDataRaw.snapshot.version || _sheetIo.SNAPSHOT_VERSION.NEW_CALC_ENGINE
            };
            var mountedSheets = _this.manager.mountedSheets;
            mountedSheets.forEach(function (sheetId, index) {
                var s = _this.manager.sheets[sheetId];
                // 如果出现了不存在的Sheet，则跳出
                if (!s) {
                    return;
                }
                snapshot.sheets[sheetId] = Object.assign({}, s.snapshot, { index: index });
                _this.actionAfterLoaded = _this.actionAfterLoaded.concat(s.actions);
            });
            var clientVarData = {
                snapshot: snapshot,
                sheetCount: mountedSheets.length
            };
            _this.collaSpread.onClientVars(clientVarData);
        };
        this.fetchRemoteSheetData = function (s, sheetId) {
            console.log('FetchingRemoteData ' + sheetId);
            _this.collaSpread.sync.fetchSheetSplitData(s);
            _this.collaSpread.spreadLoaded = _this.isCollaSpreadLoaded();
        };
        this.clearRedDot = function (actions) {
            // 清理表格中所有红标
            if (_this.collaSpread.spreadLoaded) {
                var sheetIdList = (0, _uniq3.default)(actions.map(function (item) {
                    return item.sheet_id;
                }));
                sheetIdList.forEach(function (item) {
                    _this.collaSpread.spread.clearNodeCalcSnapshot(item);
                });
            }
        };
        this.findMention = function (mentionId, scrollElement, scrollTopFunc) {
            if (_this.isCollaSpreadLoaded()) {
                var targetCol = -1;
                var targetRow = -1;
                var targetSheetId = '';
                var sheetList = _this.collaSpread.spread.sheets;
                var target = (0, _some3.default)((0, _toArray3.default)(sheetList), function (item) {
                    var founded = false;
                    var dataTable = item._dataModel.dataTable;
                    (0, _each3.default)(dataTable, function (row, rowKey) {
                        if (founded) {
                            return;
                        }
                        (0, _each3.default)(row, function (cell, colKey) {
                            if (founded) {
                                return;
                            }
                            if (cell.segmentArray && cell.segmentArray.length > 0) {
                                (0, _each3.default)(cell.segmentArray, function (sItem) {
                                    if (sItem.mentionId && sItem.mentionId === mentionId) {
                                        targetCol = parseInt(colKey, 10);
                                        targetRow = parseInt(rowKey, 10);
                                        targetSheetId = item.id();
                                        founded = true;
                                    }
                                });
                            }
                        });
                    });
                    return founded;
                });
                if (target) {
                    var spread = _this.collaSpread.spread;
                    var targetSheet = spread.getSheetFromId(targetSheetId);
                    var cellRect = targetSheet.getCellRect(targetRow, targetCol);
                    var host = targetSheet._host;
                    if (!host) {
                        return;
                    }
                    var box = host.getBoundingClientRect();
                    var doc = host.ownerDocument;
                    var etherPadContianer = scrollElement || document.querySelector('.etherpad-container-wrapper');
                    if (doc && etherPadContianer) {
                        var offsetTop = box.top + etherPadContianer.scrollTop;
                        // 滚动Doc视口至合适位置
                        var clientHeight = document.documentElement.clientHeight;
                        var newScrollTop = offsetTop + cellRect.y - 128;
                        if (_browserHelper2.default.isMobile) {
                            clientHeight = clientHeight * 0.2;
                        }
                        if (etherPadContianer && (newScrollTop > etherPadContianer.scrollTop + clientHeight || newScrollTop < etherPadContianer.scrollTop - 128)) {
                            if (scrollTopFunc) {
                                scrollTopFunc(newScrollTop);
                            } else {
                                etherPadContianer.scrollTop = newScrollTop;
                            }
                        }
                    }
                    spread.setActiveSheet(targetSheet.name());
                    targetSheet.setActiveCell(targetRow, targetCol);
                    // 先激活才行
                    _this.collaSpread.context.trigger(_sheetIo.CollaborativeEvents.WAKEUP, targetSheetId);
                    if (showCellTimer) {
                        clearTimeout(showCellTimer);
                        showCellTimer = null;
                    }
                    showCellTimer = setTimeout(function () {
                        targetSheet._highlightCells = targetSheet._highlightCells || new Map();
                        targetSheet._highlightCells.set(targetRow + '_' + targetCol, 1);
                        targetSheet.showCell(targetRow, targetCol, VerticalPosition.center, HorizontalPosition.center, true);
                        targetSheet.notifyShell(_sheetCore.ShellNotifyType.SearchChanged);
                        clearTimeout(showCellTimer);
                        showCellTimer = null;
                    }, 200);
                    var deleteHighCell = function deleteHighCell() {
                        targetSheet._highlightCells = null;
                        targetSheet.notifyShell(_sheetCore.ShellNotifyType.SearchChanged);
                    };
                    if (highCellTimer) {
                        clearTimeout(highCellTimer);
                        highCellTimer = null;
                        deleteHighCell();
                    }
                    highCellTimer = setTimeout(function () {
                        deleteHighCell();
                        clearTimeout(highCellTimer);
                        highCellTimer = null;
                    }, 2200);
                }
                return !!target;
            } else {
                return false;
            }
        };
        this.screenshot = function (isBlob, isScreenShotMode) {
            return new Promise(function (resolve, reject) {
                var keys = [];
                _this.manager.sheetComponents.forEach(function (v, k) {
                    keys.push(k);
                });
                _this.screenShotKeys = keys;
                _this.screenShotIdx = 0;
                _this.screenShotResolve = resolve;
                _this.screenShotReject = reject;
                _this.isBlob = isBlob;
                _this.isScreenShotMode = isScreenShotMode;
                _this.screenShotNext();
            });
        };
        this.screenShotNext = function (error) {
            var comp = _this.manager.sheetComponents.get(_this.screenShotKeys[_this.screenShotIdx]);
            if (error) {
                _this.screenShotReject && _this.screenShotReject(error);
            }
            if (comp) {
                comp.onScreenShot(_this.isBlob, _this.isScreenShotMode);
            } else {
                _this.screenShotResolve && _this.screenShotResolve();
            }
        };
        this.manager = manager;
        this.createCollaborativeSpread(firstSheetId);
        this.bindSheetEvents();
    }

    (0, _createClass3.default)(EmbedSheetManagerImp, [{
        key: 'createSheetFromDataStore',
        value: function createSheetFromDataStore(sheetId) {
            var withReport = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

            var sheet = this.collaSpread.spread.getSheetFromId(sheetId);
            var s = this.manager.sheets[sheetId];
            if (!sheet) {
                if (!s) {
                    this.manager.addUnusableSheet(sheetId);
                    if (withReport) {
                        _$moirae2.default.teaLog({ key: 'client_sheet_embed_manager_imp_no_worksheet_2' });
                    }
                    return;
                }
                var index = this.manager.mountedSheets.indexOf(sheetId);
                if (index === -1) {
                    index = s.snapshot.index || 0;
                }
                /**
                 * 拉取单个 sheet 的 RowData 数据
                 * 一般场景是 sheet@doc 中，A用户删除了一个表格，B用户这个刷新了，这时候B用户是没有该表格的 RowData 数据的
                 * 这时候A用户撤销了删除表格操作，B用户需要去拉取该表格数据
                 */
                if (!s.snapshot.data) {
                    this.fetchRemoteSheetData(s, sheetId);
                }
                var action = {
                    action: _sheetCommon.ACTIONS.COPY_SHEET,
                    sheet_id: sheetId,
                    value: {
                        index: index,
                        sheet_id: sheetId,
                        sheet_name: s.snapshot.name,
                        snapshot: s.snapshot
                    }
                };
                this.collaSpread.applyActions([action].concat(s.actions));
            }
        }
    }, {
        key: 'getEmbedSheet',
        value: function getEmbedSheet(sheetId) {
            var _this2 = this;

            var isSelect = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

            var sheet = this.collaSpread.spread.getSheetFromId(sheetId);
            if (!sheet) {
                return null;
            }
            var collaSpreadLoaded = this.isCollaSpreadLoaded();
            var mountOption = this.manager.mountOptions[sheetId];
            var isTemplate = mountOption && mountOption.isTemplate;
            var commentManager = this.manager.commentManager;
            var lastActiveCommentId = '';
            if (this.cachedEmbedSheet[sheetId] && this.cachedEmbedSheet[sheetId].isSelect === isSelect && this.cachedEmbedSheet[sheetId].collaSpreadLoaded === collaSpreadLoaded) {
                return this.cachedEmbedSheet[sheetId].value;
            } else {
                this.cachedEmbedSheet[sheetId] = {
                    key: sheetId,
                    value: _react2.default.createElement(_EmbedSheet2.default, { sheetId: sheetId, isSelect: isSelect, isTemplate: isTemplate, collaSpread: this.collaSpread, collaSpreadLoaded: this.isCollaSpreadLoaded(), shell: {
                            onDeleteSheet: function onDeleteSheet() {
                                mountOption && mountOption.deleteFn();
                            },
                            onFullScreenMode: function onFullScreenMode() {
                                return;
                            },
                            onHistoryMode: function onHistoryMode() {
                                return;
                            },
                            onRenderError: function onRenderError() {
                                _this2.manager.addUnusableSheet(sheetId);
                            },
                            onScreenShotReady: function onScreenShotReady(error) {
                                if (error) {
                                    _this2.screenShotNext(error);
                                    return;
                                }
                                _this2.screenShotIdx += 1;
                                _this2.screenShotNext();
                            },
                            onCutWholeSheet: function onCutWholeSheet(e) {
                                mountOption && mountOption.onCutWholeSheet(e);
                            }
                        }, comment: {
                            // 表格渲染完成时，通知Block
                            onCommentLoaded: function onCommentLoaded() {
                                if (mountOption && mountOption.onCommentLoaded) {
                                    mountOption.onCommentLoaded(commentManager.getComments(sheet.id()));
                                }
                            },
                            // 当行发生增删时，通知Block该表有变更，提供该表所有评论信息
                            // 评论组件会作出Diff以保证性能
                            onCommentBatchUpdate: function onCommentBatchUpdate() {
                                if (mountOption && mountOption.onCommentBatchUpdate) {
                                    mountOption.onCommentBatchUpdate(commentManager.getComments(sheet.id()));
                                }
                            },
                            // 当活动单元格变化时，通知Block
                            onActiveCommentChange: function onActiveCommentChange() {
                                var newActiveComments = _this2.manager.commentManager.getActiveComments(sheet.id()).map(function (item) {
                                    return item.commentId || '';
                                });
                                var newActiveCommentId = newActiveComments.length > 0 ? newActiveComments[0] : '';
                                if (newActiveCommentId !== lastActiveCommentId) {
                                    if (mountOption && mountOption.onActiveCommentChange) {
                                        mountOption.onActiveCommentChange(newActiveCommentId);
                                    }
                                }
                                lastActiveCommentId = newActiveCommentId;
                            },
                            onClearActiveCommentId: function onClearActiveCommentId() {
                                lastActiveCommentId = '';
                            }
                        } }),
                    isSelect: isSelect,
                    collaSpreadLoaded: collaSpreadLoaded
                };
            }
            return this.cachedEmbedSheet[sheetId].value;
        }
    }, {
        key: 'getSheetSnapshot',
        value: function getSheetSnapshot(sheetId) {
            var spread = this.collaSpread.spread;
            if (!spread) {
                return null;
            }
            var sheet = spread.getSheetFromId(sheetId);
            if (sheet) {
                return sheet.toJSON();
            }
            return null;
        }
    }, {
        key: 'handleSpreadLoaded',
        value: function handleSpreadLoaded(clientVarsData) {
            var _this3 = this;

            if (!this.isCollaSpreadLoaded()) {
                return;
            }
            var spread = this.collaSpread.spread;
            this.collaSpread.spreadLoaded = true;
            if (this.actionAfterLoaded.length) {
                this.applyActions(this.actionAfterLoaded, false);
                // 执行完进行清理以确保不会被重复执行
                this.actionAfterLoaded = [];
            }
            if (this.manager.actionAfterLoaded.length) {
                this.manager.actionAfterLoaded.forEach(function (item) {
                    _this3.applyActions(item, true);
                });
                // 执行完进行清理以确保不会被重复执行
                this.manager.actionAfterLoaded = [];
            }
            // 解除冻结
            _$store2.default.dispatch((0, _sheet2.freezeSheetToggle)(false));
            // 设置编辑权限
            var editable = (0, _sheet.editableSelector)(_$store2.default.getState());
            (0, _utils.setSpreadEdit)(spread, editable);
            _$moirae2.default.teaLog({ key: 'client_sheet_embed_count', length: this.collaSpread.spread.sheets.length });
            this.collaSpread.spread.sheets.forEach(function (sheet) {
                _$moirae2.default.teaLog({ key: 'client_sheet_embed_row_count', length: sheet.getRowCount() });
                _$moirae2.default.teaLog({ key: 'client_sheet_embed_col_count', length: sheet.getColumnCount() });
            });
            // 公式引擎升级
            if (clientVarsData.snapshot.nodeCalcSnapshot) {
                spread.applyNodeCalcSnapshot(clientVarsData.snapshot.nodeCalcSnapshot);
            }
            if (spread.getSpreadVersion() < _sheetIo.SNAPSHOT_VERSION.NEW_CALC_ENGINE && spread.getCellFormulaValidationList().length === 0 && editable) {
                spread.commandManager().execute({
                    cmd: _sheetCommon.ACTIONS.UPGRADE_SNAPSHOT,
                    sheetId: spread.getActiveSheet().id()
                });
            }
        }
    }, {
        key: 'handleCopy',
        value: function handleCopy(sheetId) {
            var spread = this.collaSpread.spread;
            var sheet = spread.getSheetFromId(sheetId);
            return sheet ? sheet.toHtml() : '';
        }
        // 可能是远程action也可能是本地操作产生的
        // 如果有创建sheet的action，随即应该创建EmbedSheet替换placeholder

    }, {
        key: 'applyActions',
        value: function applyActions(actions) {
            var local = arguments.length > 1 && arguments[1] !== undefined ? arguments[1] : false;

            var sheets = this.collaSpread.spread.sheets;
            // 新建 sheet 的 action，如果 sheet 存在，则去掉这个 action
            actions = actions.filter(function (action) {
                if (action.action === _sheetCommon.ACTIONS.COPY_SHEET) {
                    var copyAction = action;
                    var sheetId = copyAction.sheet_id;
                    var sheetExist = (0, _find3.default)(sheets, function (sheet) {
                        return sheet.id() === sheetId;
                    });
                    return !sheetExist;
                } else {
                    return true;
                }
            });
            this.collaSpread.applyActions(actions, false, local);
            // 清理表格中所有红标
            if (this.collaSpread.spreadLoaded && local === false) {
                this.clearRedDot(actions);
            }
        }
    }, {
        key: 'destroy',
        value: function destroy() {
            try {
                this.unbindSheetEvents();
                this.collaSpread.destroy();
                this.cachedEmbedSheet = {};
                this.spreadLoaded = false;
            } catch (ex) {
                _$moirae2.default.ravenCatch(ex, {
                    scm: JSON.stringify(window.scm),
                    key: 'SHEET_EMB_DESTROY_ERROR'
                });
                throw ex;
            }
        }
    }]);
    return EmbedSheetManagerImp;
}();

exports.default = EmbedSheetManagerImp;

/***/ }),

/***/ 3839:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.EmbedSheet = undefined;

var _regenerator = __webpack_require__(12);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(10);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(11);

var _inherits3 = _interopRequireDefault(_inherits2);

var _typeof2 = __webpack_require__(82);

var _typeof3 = _interopRequireDefault(_typeof2);

var _findIndex2 = __webpack_require__(346);

var _findIndex3 = _interopRequireDefault(_findIndex2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _$decorators = __webpack_require__(553);

var _redux = __webpack_require__(66);

var _reactRedux = __webpack_require__(300);

var _sheet = __webpack_require__(744);

var _sheet2 = __webpack_require__(1660);

var _sheet3 = __webpack_require__(745);

var _tea = __webpack_require__(42);

var _info = __webpack_require__(3840);

var _info2 = _interopRequireDefault(_info);

var _hyperlink = __webpack_require__(2141);

var _hyperlink2 = _interopRequireDefault(_hyperlink);

var _Mention = __webpack_require__(2139);

var _Mention2 = _interopRequireDefault(_Mention);

var _headerSelectionBubble = __webpack_require__(2142);

var _headerSelectionBubble2 = _interopRequireDefault(_headerSelectionBubble);

var _browserHelper = __webpack_require__(27);

var _browserHelper2 = _interopRequireDefault(_browserHelper);

var _sdkCompatibleHelper = __webpack_require__(45);

var _core = __webpack_require__(1704);

var _dom = __webpack_require__(1686);

var _isEqual = __webpack_require__(748);

var _isEqual2 = _interopRequireDefault(_isEqual);

__webpack_require__(2251);

var _sheetShell = __webpack_require__(1713);

var _sheetCore = __webpack_require__(1594);

var _utils = __webpack_require__(1678);

var _Toolbar_m = __webpack_require__(2144);

var _Toolbar_m2 = _interopRequireDefault(_Toolbar_m);

var _ContextMenu = __webpack_require__(2143);

var _ContextMenu2 = _interopRequireDefault(_ContextMenu);

var _share = __webpack_require__(342);

var _common = __webpack_require__(19);

var _eventEmitter = __webpack_require__(110);

var _eventEmitter2 = _interopRequireDefault(_eventEmitter);

var _editor = __webpack_require__(1778);

var _timeoutHelper = __webpack_require__(1801);

var _jsBridgeHelper = __webpack_require__(1606);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var __decorate = undefined && undefined.__decorate || function (decorators, target, key, desc) {
    var c = arguments.length,
        r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc,
        d;
    if ((typeof Reflect === "undefined" ? "undefined" : (0, _typeof3.default)(Reflect)) === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);else for (var i = decorators.length - 1; i >= 0; i--) {
        if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    }return c > 3 && r && Object.defineProperty(target, key, r), r;
};

_sheetCore.dependency.mobileEditor = _editor.sheetEditor;

var EmbedSheet = exports.EmbedSheet = function (_React$Component) {
    (0, _inherits3.default)(EmbedSheet, _React$Component);

    function EmbedSheet(props) {
        (0, _classCallCheck3.default)(this, EmbedSheet);

        var _this = (0, _possibleConstructorReturn3.default)(this, (EmbedSheet.__proto__ || Object.getPrototypeOf(EmbedSheet)).call(this, props));

        _this._virtualScrollSyncing = false;
        _this.stickyOffset = 0;
        _this.initScreenHeight = window.innerHeight;
        _this._isInVirtualScroll = false; // 是否处于虚拟滚动
        _this.isActive = false;
        _this.onScroll = function () {
            if (_this.state.screenShotBlob) {
                return;
            }
            if (_this.isFixSize()) {
                return;
            }
            _this._syncVirtualScroll();
        };
        _this.getBindList = function () {
            return [{ key: _sheet.Events.Focus, handler: _this.onFocus }, { key: _sheet.Events.LoseFocus, handler: _this.onLoseFocus }, { key: _sheet.Events.CutSheet, handler: _this.handleCutSheet }, { key: _sheet.Events.CellPress, handler: _this.onCellPress }, { key: _sheet.Events.SelectionChanged, handler: _this.handleSelectionChange }];
        };
        _this.handleSelectionChange = function (type, _ref) {
            var sheet = _ref.sheet;

            var row = sheet.getActiveRowIndex();
            var col = sheet.getActiveColumnIndex();
            var segArr = sheet.getSegmentArray(row, col) || [];
            var hasSeg = !!segArr.find(function (_ref2) {
                var type = _ref2.type;

                return type === 'mention' || type === 'url';
            });
            var timeout = hasSeg ? _sheet.Timeout.commentCardShow : _sheet.Timeout.dblClickEdit + 100;
            _eventEmitter2.default.emit('setSheetBlockSelection', sheet._host);
            (0, _timeoutHelper.addGroupTimeout)('sheet_comments', function () {
                if (_editor.sheetEditor.isEditing()) return;
                _this.props.comment.onActiveCommentChange();
            }, timeout);
        };
        _this.handleCutSheet = function (type, e) {
            _this.props.shell.onCutWholeSheet(e);
            _this.props.shell.onDeleteSheet();
        };
        _this.collectMoveToNextRow = function () {
            var _this$props = _this.props,
                sheetId = _this$props.sheetId,
                collaSpread = _this$props.collaSpread;

            if (sheetId === collaSpread.getActiveSheet().id()) {
                (0, _tea.collectSuiteEvent)('click_sheet_edit_action', { sheet_edit_action_type: 'click_keyboard_next_row' });
            }
        };
        _this.doViewportResize = function () {
            var sheetView = _this._shell.sheetView();
            if (!sheetView) {
                return;
            }

            var _sheetView$contentSiz = sheetView.contentSizeHint(),
                width = _sheetView$contentSiz.width,
                height = _sheetView$contentSiz.height;

            var maxWidth = _this.props.maxWidth;
            if (!maxWidth) return; // 避免 maxWidth 为 0 导致显示错误
            var screenWidth = window.innerWidth; // TODO: 有没有更好的办法获取容器宽度
            var docPaddingWidth = Math.floor((screenWidth - maxWidth) / 2);
            maxWidth = screenWidth - 2; // 右边间距
            // 移动端doc两边的padding宽度可能会比默认行头宽度小，所以需要手动调整行头宽度
            var sheet = _this.getCurrentSheet();
            if (sheet && docPaddingWidth < sheet.defaults.rowHeaderColWidth) {
                sheet.defaults.rowHeaderColWidth = docPaddingWidth;
            }
            var maxHeight = _this.props.maxHeight || Infinity;
            // show right margin
            if (maxWidth - 2 > width) {
                sheetView.setRightMargin(true);
            } else {
                sheetView.setRightMargin(false);
            }
            width += sheetView._rightMargin;
            var options = _this.props.collaSpread.spread.options;
            var showHorizontalScrollbar = width > maxWidth;
            options.showHorizontalScrollbar = showHorizontalScrollbar;
            if (showHorizontalScrollbar) {
                width = maxWidth;
                sheetView.setBottomMargin(true);
            } else {
                sheetView.setBottomMargin(false);
            }
            height += sheetView._bottomMargin;
            var showVerticalScrollbar = height > maxHeight;
            if (showVerticalScrollbar) {
                if (width > maxWidth) {
                    width = maxWidth;
                    options.showHorizontalScrollbar = true;
                }
                height = maxHeight;
            }
            options.showVerticalScrollbar = showVerticalScrollbar;
            if (_this.state.width !== width || _this.state.height !== height) {
                _this.setState({ width: width, height: height });
            }
        };
        _this._asyncVirtualScroll = function () {
            setTimeout(function () {
                _this._syncVirtualScroll();
            }, 300);
        };
        _this.onFocus = function (e, args) {
            return;
        };
        _this.onLoseFocus = function (e, args) {
            var sheet = args.sheet;
            if (sheet && _this.getCurrentSheet() === sheet) {
                // sheet.endEdit();
                if (!args.ignoreRepaintSelection) {
                    sheet.clearSelection(true);
                }
            }
        };
        _this.onCellPress = function (type, info) {
            var spread = _this.props.collaSpread.spread;
            var row = info.row,
                col = info.col;

            var activeSheet = spread.getActiveSheet();
            if (activeSheet === _this.getCurrentSheet()) {
                var selectionRange = activeSheet.getSelections()[0];
                if (!(selectionRange && selectionRange.contain(new _sheetCore.Range(row, col, 1, 1, activeSheet)))) {
                    activeSheet.setActiveCell(row, col);
                }
            } else {
                _this.selectCurrentSheet();
                activeSheet = spread.getActiveSheet();
                activeSheet && activeSheet.setActiveCell(row, col);
            }
        };
        _this.selectCurrentSheet = function (e) {
            var setActiveSheetId = _this.props.setActiveSheetId;
            var spread = _this.props.collaSpread.spread;

            var curSheet = _this.getCurrentSheet();
            var activeSheet = spread.getActiveSheet();
            if (activeSheet !== curSheet) {
                activeSheet && activeSheet.clearSelection(true);
                spread.setActiveSheet(curSheet.name(), true);
                setActiveSheetId(curSheet.id());
            }
        };
        _this.setFasterDom = function (elem) {
            if (!elem) return;
            _this._fasterDom = elem;
            _this.createShell(elem);
        };
        _this.getDomRef = function (ref) {
            _this._workbookWrapper = null;
            if ((0, _sdkCompatibleHelper.isSupportSheetEditor)()) {
                var currentTarget = ref;
                while (currentTarget) {
                    if (currentTarget.classList.contains('sheet')) {
                        break;
                    }
                    currentTarget = currentTarget.parentElement;
                }
                if (currentTarget) {
                    _this._workbookWrapper = currentTarget;
                    _this._workbookWrapper.tabIndex = -1;
                }
            }
        };
        _this.getCanvasBoundingRect = function () {
            if (_this._fasterDom) {
                return _this._fasterDom.getBoundingClientRect();
            } else {
                return document.body.getBoundingClientRect();
            }
        };
        _this.handleDoubleClick = (0, _utils.doubleTapWrapper)(function (e) {
            if (_editor.sheetEditor && !_editor.sheetEditor.isEditing()) {
                (0, _tea.collectSuiteEvent)('sheet-operation', {
                    action: 'open_keyboard',
                    op_item: 'double_click'
                });
                _editor.sheetEditor.startEdit();
            }
            if (!_this._workbookWrapper) {
                var hostElement = _this._fasterDom;
                while (hostElement) {
                    if (hostElement.classList.contains('sheet')) {
                        break;
                    }
                    hostElement = hostElement.parentElement;
                }
                if (hostElement) {
                    _this._workbookWrapper = hostElement;
                    _this._workbookWrapper.tabIndex = -1;
                }
            }
            _this._workbookWrapper && _this._workbookWrapper.focus();
        }, _sheet.Timeout.dblClickEdit);
        _this.state = {
            width: 308,
            height: 68,
            fasterStyle: {
                position: 'relative',
                top: null,
                bottom: null
            },
            screenShotBlob: null,
            isScreenShoting: false
        };
        // Firefox 使用 sticky 属性会造成 canvas 闪烁
        var isBrowserSupportSticky = [_browserHelper2.default.safari, _browserHelper2.default.chrome].some(function (value) {
            return value;
        });
        var isBrowserNotSupportSticky = [_browserHelper2.default.android, _browserHelper2.default.isLark].some(function (value) {
            return value;
        });
        _this.isSupportSticky = _this.testSupportSticky() && isBrowserSupportSticky && !isBrowserNotSupportSticky;
        _this.scrollContainer = null;
        return _this;
    }

    (0, _createClass3.default)(EmbedSheet, [{
        key: "getCurrentSheet",
        value: function getCurrentSheet() {
            if (!this.props.collaSpread || !this.props.collaSpread.spread) return null;
            return this.props.collaSpread.spread.getSheetFromId(this.props.sheetId);
        }
    }, {
        key: "componentWillReceiveProps",
        value: function componentWillReceiveProps(nextProps) {
            if (nextProps.isScreenShotMode !== this.props.isScreenShotMode) {
                this.onScreenShot(nextProps.isScreenShotMode, nextProps.isBlob);
            }
        }
    }, {
        key: "shouldComponentUpdate",
        value: function shouldComponentUpdate(nextProps, nextState) {
            if (nextState.isScreenShoting === true) {
                return false;
            }
            return true;
        }
    }, {
        key: "componentDidMount",
        value: function componentDidMount() {
            _jsBridgeHelper.JsBridgeManager.register('lark.biz.sheet.requestScreenshot', this.handleRequestScreenshot);
            _jsBridgeHelper.JsBridgeManager.register('lark.biz.sheet.finishScreenshot', this.handleFinishScreenshot);
            var _props = this.props,
                collaSpread = _props.collaSpread,
                sheetId = _props.sheetId,
                editable = _props.editable;

            var spread = collaSpread.spread;
            var context = collaSpread.context;
            this.bindEvents();
            this._canvas && this._canvas.addEventListener('touchend', this.selectCurrentSheet);
            this._canvas && this._canvas.addEventListener('touchend', this.handleDoubleClick);
            window.addEventListener('scroll', this.onScroll, true);
            _eventEmitter2.default.on('sheet_in_doc:start_doc_edit', this.preventFocusCanvas);
            _eventEmitter2.default.on('sheet_in_doc:end_doc_edit', this.unpreventFocusCanvas);
            _eventEmitter2.default.on('sheet_in_doc:sheetSelect', this.handleSheetSelectEvent);
            _eventEmitter2.default.on(_editor.EditEvent.EDIT_START, this.handleStartEdit);
            _eventEmitter2.default.on(_editor.EditEvent.EDIT_END, this.handleEndEdit);
            _eventEmitter2.default.on(_editor.EditEvent.EDIT_NEXT_ROW, this.collectMoveToNextRow);
            // onclientvars 和 didmount 是同一时机，所以放在这里。
            var curSheet = this.getCurrentSheet();
            curSheet.clearSelection(true);
            curSheet.setSheetHost(this._fasterDom);
            this._shell.updateSheet(curSheet);
            this.doViewportResize();
            this.setEditable(editable);
            this._hyperlink = new _hyperlink2.default({
                spread: spread,
                sheetId: sheetId
            });
            this._mention = new _Mention2.default({
                sheet: curSheet,
                spread: spread,
                context: context,
                container: this._fasterDom,
                getCanvasBoundingRect: this.getCanvasBoundingRect,
                sheetId: sheetId
            });
            // 创建DialogOverlay
            var overlay = document.createElement('div');
            var wrapper = document.getElementById('mainContainer') || document.body;
            Object.assign(overlay.style, {
                position: 'fixed',
                'z-index': 99
            });
            overlay.className = 'embed-sheet-dialog-overlay';
            wrapper.appendChild(overlay);
            // 调整WorkSheet在Workbook中的顺位
            // 获取所有挂在的表格DOM
            var allEmbedSheetDom = document.querySelectorAll('.embed-spreadsheet-wrap');
            // 查询目标位置
            var targetSheetIndex = (0, _findIndex3.default)(allEmbedSheetDom, function (item) {
                return item.classList.contains("sheet-id-" + sheetId);
            });
            // 查询原位置
            var sourceSheetIndex = spread.getSheetIndexFromId(sheetId);
            // 移动表格
            if (sourceSheetIndex !== -1 && targetSheetIndex !== -1 && sourceSheetIndex !== targetSheetIndex) {
                spread.moveSheet(sourceSheetIndex, targetSheetIndex, false);
            }
            this.props.comment.onCommentLoaded();
        }
    }, {
        key: "componentDidUpdate",
        value: function componentDidUpdate(prevProps, prevState) {
            var state = this.state;
            var props = this.props;
            if (state.screenShotBlob) {
                return;
            }
            this.setZoom(props.zoom);
            if (prevProps.maxWidth !== props.maxWidth) {
                this.doViewportResize();
            }
            if (prevState.height !== state.height && this._virtualWrap) {
                window.dispatchEvent((0, _dom.createCustomEvent)('afterSheetResize', { detail: { sheetId: props.sheetId } }));
            }
            this.setEditable(props.editable);
            this._syncVirtualScroll();
        }
    }, {
        key: "componentWillUnmount",
        value: function componentWillUnmount() {
            _jsBridgeHelper.JsBridgeManager.unregister('lark.biz.sheet.requestScreenshot', this.handleRequestScreenshot);
            _jsBridgeHelper.JsBridgeManager.unregister('lark.biz.sheet.finishScreenshot', this.handleFinishScreenshot);
            this.unbindEvents();
            this._hyperlink && this._hyperlink.destroy();
            this._mention && this._mention.destroy();
            this._canvas && this._canvas.removeEventListener('touchend', this.selectCurrentSheet);
            this._canvas && this._canvas.removeEventListener('touchend', this.handleDoubleClick);
            window.removeEventListener('scroll', this.onScroll, true);
            _eventEmitter2.default.off('sheet_in_doc:start_doc_edit', this.preventFocusCanvas);
            _eventEmitter2.default.off('sheet_in_doc:end_doc_edit', this.unpreventFocusCanvas);
            _eventEmitter2.default.off('sheet_in_doc:sheetSelect', this.handleSheetSelectEvent);
            _eventEmitter2.default.off(_editor.EditEvent.EDIT_START, this.handleStartEdit);
            _eventEmitter2.default.off(_editor.EditEvent.EDIT_END, this.handleEndEdit);
            _eventEmitter2.default.off(_editor.EditEvent.EDIT_NEXT_ROW, this.collectMoveToNextRow);
            this._shell && this._shell.exit();
            _editor.sheetEditor && _editor.sheetEditor.destroy();
        }
    }, {
        key: "setEditable",
        value: function setEditable(b) {
            this.getCurrentSheet().options.isProtected = !b;
            this._shell && this._shell.setEditable(b);
        }
    }, {
        key: "isFixSize",
        value: function isFixSize() {
            return this.props.maxHeight && this.props.maxHeight !== Infinity;
        }
    }, {
        key: "bindEvents",
        value: function bindEvents() {
            var collaSpread = this.props.collaSpread;
            var context = collaSpread.context;
            context.addEventHandler(this);
            this.toggleSheetEventsBinding(true);
            var spread = collaSpread.spread;
            spread.bind(_sheet.Events.ActiveSheetChanged, this.handleActiveSheetChanged);
        }
    }, {
        key: "toggleSheetEventsBinding",
        value: function toggleSheetEventsBinding(bind) {
            var bindList = this.getBindList();
            var sheet = this.getCurrentSheet();
            if (!sheet) return;
            bindList.forEach(function (event) {
                if (Array.isArray(event.key)) {
                    event.key.forEach(function (key) {
                        bind ? sheet.bind(key, event.handler) : sheet.unbind(key, event.handler);
                    });
                } else {
                    bind ? sheet.bind(event.key, event.handler) : sheet.unbind(event.key, event.handler);
                }
            });
        }
    }, {
        key: "unbindEvents",
        value: function unbindEvents() {
            var collaSpread = this.props.collaSpread;
            var context = collaSpread.context;
            this.toggleSheetEventsBinding(false);
            context && context.removeEventHandler(this);
            var spread = collaSpread.spread;
            spread && spread.unbind(_sheet.Events.ActiveSheetChanged, this.handleActiveSheetChanged);
            (0, _timeoutHelper.clearGroupTimeout)('sheet_comments');
        }
    }, {
        key: "handleEndEdit",
        value: function handleEndEdit() {
            this._asyncVirtualScroll();
            this.unpreventFocusCanvas();
        }
    }, {
        key: "handleStartEdit",
        value: function handleStartEdit() {
            var _props2 = this.props,
                collaSpread = _props2.collaSpread,
                sheetId = _props2.sheetId;
            var spread = collaSpread.spread;

            if (!spread) return;
            var activeSheetId = spread.getActiveSheet().id();
            if (activeSheetId !== sheetId) {
                this.preventFocusCanvas();
            }
        }
    }, {
        key: "handleFinishScreenshot",
        value: function handleFinishScreenshot() {
            if (!this._canvas) return;
            var parentNode = this._canvas.parentNode;
            var img = parentNode && parentNode.querySelector('.screenshot_img');
            img && parentNode && parentNode.removeChild(img);
        }
    }, {
        key: "handleRequestScreenshot",
        value: function handleRequestScreenshot() {
            var _this2 = this;

            if (!this.isInsideViewport()) {
                var collaSpread = this.props.collaSpread;
                var spread = collaSpread.spread;

                if (!spread) return;
                _eventEmitter2.default.emit('sheet_in_doc:sheet_outside_viewport', spread.sheets.length);
                return;
            }
            if (!this._canvas) return;
            var parentNode = this._canvas.parentNode;
            var img = parentNode && parentNode.querySelector('.screenshot_img');
            if (img) return;
            var dataUrl = this._canvas.toDataURL('image/png');
            img = new Image();
            img.className = 'screenshot_img';
            img.style.position = 'absolute';
            img.style.left = '0px';
            img.style.top = '0px';
            img.style.width = '100%';
            var handler = function handler() {
                _eventEmitter2.default.emit('sheet_in_doc:reset_outside_viewport_count');
                window.lark.biz.sheet.screenshotReady();
                // 1秒后自动关闭截图
                setTimeout(function () {
                    _this2.handleFinishScreenshot();
                }, 1000);
            };
            img.onload = handler;
            img.onerror = handler;
            parentNode && parentNode.appendChild(img);
            img.src = dataUrl;
        }
    }, {
        key: "preventFocusCanvas",
        value: function preventFocusCanvas() {
            this._canvas && this._canvas.addEventListener('touchend', this.preventDefault);
        }
    }, {
        key: "unpreventFocusCanvas",
        value: function unpreventFocusCanvas() {
            var collaSpread = this.props.collaSpread;
            var spread = collaSpread.spread;

            if (!spread || spread.editor.isEditing()) return;
            this._canvas && this._canvas.removeEventListener('touchend', this.preventDefault);
        }
    }, {
        key: "preventDefault",
        value: function preventDefault(e) {
            e.preventDefault();
        }
    }, {
        key: "handleActiveSheetChanged",
        value: function handleActiveSheetChanged(type, _ref3) {
            var oldSheet = _ref3.oldSheet,
                newSheet = _ref3.newSheet;

            this.props.comment.onClearActiveCommentId();
            // 只在active的sheet中处理一次就行
            var _props3 = this.props,
                sheetId = _props3.sheetId,
                collaSpread = _props3.collaSpread;

            var shouldRestoreEditing = false;
            if (newSheet && sheetId === newSheet.id()) {
                if (oldSheet) {
                    oldSheet.clearSelection(true, false, false);
                    oldSheet._trigger(_sheet.Events.LoseFocus, { sheet: oldSheet, ignoreRepaintSelection: true });
                    shouldRestoreEditing = oldSheet.editor && (oldSheet.editor.isEditing() || oldSheet.editor.finished);
                    if (newSheet.getSelections().length === 0) {
                        _eventEmitter2.default.emit('closeSheetToolbar');
                    }
                }
                _editor.sheetEditor.updateSpreadSheet(collaSpread.spread, newSheet);
                shouldRestoreEditing && _editor.sheetEditor.startEdit();
            }
        }
    }, {
        key: "handleSheetSelectEvent",
        value: function handleSheetSelectEvent(isSelect) {
            if (!isSelect) {
                var sheet = this.getCurrentSheet();
                sheet.clearSelection(true);
                sheet._trigger(_sheet.Events.LoseFocus, { sheet: sheet, ignoreRepaintSelection: true });
            }
        }
    }, {
        key: "setZoom",
        value: function setZoom(zoom) {
            var sheetView = this._shell.sheetView();
            sheetView.zoomContent(zoom);
        }
    }, {
        key: "_scrollY",
        value: function _scrollY(stepY) {
            if (Math.abs(stepY) > 0) {
                var scrollContainer = this._scrollParent(this._canvas);
                var top = 0;
                var left = 0;
                if (scrollContainer instanceof Window || scrollContainer instanceof HTMLBodyElement || scrollContainer instanceof Document) {
                    scrollContainer = window;
                    top = window.pageYOffset || document.documentElement.scrollTop || document.body.scrollTop || 0;
                    left = window.pageXOffset || document.documentElement.scrollLeft || document.body.scrollLeft || 0;
                } else {
                    top = scrollContainer.scrollTop;
                    left = scrollContainer.scrollLeft;
                }
                if (scrollContainer.scrollTo) {
                    scrollContainer.scrollTo(left, top + stepY);
                }
            }
        }
    }, {
        key: "_wakeup",
        value: function _wakeup() {
            // 已经 active，不用再 wakeup
            if (this.isActive) return;
            var fx = this._shell && this._shell.ui();
            if (!fx) return;
            this.isActive = true;
            fx.wakeup();
        }
    }, {
        key: "onWakeup",
        value: function onWakeup(sheetId) {
            // 没有 sheetId 的时候表示广播唤醒
            if (!sheetId || this.props.sheetId === sheetId) {
                this._wakeup();
            }
        }
    }, {
        key: "_suspend",
        value: function _suspend() {
            // 已经 inactive，不用再 suspend
            if (!this.isActive) return;
            var fx = this._shell.ui();
            if (!fx) return;
            this.isActive = false;
            fx.suspend();
        }
    }, {
        key: "onSuspend",
        value: function onSuspend(sheetId) {
            // 没有 sheetId 的时候表示广播唤醒
            if (!sheetId || this.props.sheetId === sheetId) {
                this._suspend();
            }
        }
    }, {
        key: "onSyncVirtualScroll",
        value: function onSyncVirtualScroll() {
            return this._syncVirtualScroll();
        }
    }, {
        key: "onScreenShot",
        value: function onScreenShot(isScreenShotMode, isBlob) {
            var _this3 = this;

            if (isScreenShotMode) {
                this.setState({
                    isScreenShoting: true
                });
                // 不要使用原有封装的的wakeup方法，会导致状态错误
                // 在这里单独写一个对底层的直接调用
                var fx = this._shell && this._shell.ui();
                if (!fx) return;
                fx.wakeup();
                // setTimeout 延迟以确保资源Ready
                setTimeout((0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee() {
                    var screenShotBlob;
                    return _regenerator2.default.wrap(function _callee$(_context) {
                        while (1) {
                            switch (_context.prev = _context.next) {
                                case 0:
                                    _context.next = 2;
                                    return _this3._shell.screenShot(isBlob);

                                case 2:
                                    screenShotBlob = _context.sent;

                                    _this3.setState({
                                        screenShotBlob: screenShotBlob,
                                        isScreenShoting: false
                                    }, function () {
                                        _this3.props.shell.onScreenShotReady();
                                    });

                                case 4:
                                case "end":
                                    return _context.stop();
                            }
                        }
                    }, _callee, _this3);
                })), 0);
            } else {
                this.setState({
                    screenShotBlob: null,
                    isScreenShoting: false
                }, function () {
                    _this3.props.shell.onScreenShotReady();
                });
            }
        }
    }, {
        key: "isInsideViewport",
        value: function isInsideViewport() {
            var bufferZone = 100;
            var windowHeight = _browserHelper2.default.mobile ? this.initScreenHeight : window.innerHeight;
            var editor = this.props.editor;
            // 移动端有些场景会渲染两次，确保editor是最新的
            if (_browserHelper2.default.mobile && window.__editor) {
                editor = window.__editor;
            }
            var idxLine = $(editor.dom.getAceLineForNode(this._virtualWrap)).index();
            var editorOffset = editor.getScrollPos();

            var _editor$getLineRectBy = editor.getLineRectByIndex(idxLine),
                top = _editor$getLineRectBy.top,
                bottom = _editor$getLineRectBy.bottom;

            top -= editorOffset;
            bottom -= editorOffset;
            return !(bottom < -bufferZone || windowHeight + bufferZone < top);
        }
    }, {
        key: "_syncVirtualScroll",
        value: function _syncVirtualScroll() {
            var ui = this._shell && this._shell.ui();
            var sheetView = this._shell && this._shell.sheetView();
            var windowHeight = _browserHelper2.default.mobile ? this.initScreenHeight : window.innerHeight;
            if (this.isInsideViewport()) {
                this._wakeup();
            } else {
                this._suspend();
            }
            var state = this.state;
            // 移动端超过 8 倍屏幕高度时，才开启虚拟滚动
            var limit = _browserHelper2.default.mobile ? windowHeight * 8 : windowHeight;
            var newFasterStyle = void 0;
            if (limit > state.height + this.stickyOffset) {
                ui && ui.updateByCfg({
                    width: state.width,
                    height: state.height
                });
                newFasterStyle = {
                    top: null,
                    bottom: null,
                    position: 'relative'
                };
                this._isInVirtualScroll = false;
            } else {
                var rect = this._virtualWrap.getBoundingClientRect();
                var offset = this.stickyOffset;
                var wrapTop = Math.round(rect.top);
                var wrapBottom = Math.round(rect.bottom);
                var top = Math.max(offset, wrapTop) - wrapTop;
                // let faster has only visible height
                ui && ui.updateByCfg({
                    width: state.width,
                    height: windowHeight - offset
                });
                this._virtualScrollSyncing = true;
                sheetView && sheetView.contentDoc().updateByCfg({ posY: top });
                this._virtualScrollSyncing = false;
                var delta = 2;
                var hasAchieveDocStart = wrapTop + delta <= offset;
                var hasAchieveDocEnd = wrapBottom <= this._fasterDom.offsetHeight + delta + offset;
                if (hasAchieveDocStart) {
                    this._isInVirtualScroll = true;
                    if (!this.isSupportSticky) {
                        if (!hasAchieveDocEnd) {
                            newFasterStyle = {
                                top: offset,
                                bottom: null,
                                position: 'fixed'
                            };
                        } else if (hasAchieveDocEnd) {
                            newFasterStyle = {
                                top: null,
                                bottom: 0,
                                position: 'absolute'
                            };
                        }
                    }
                } else if (!hasAchieveDocEnd) {
                    this._isInVirtualScroll = false;
                    if (!this.isSupportSticky) {
                        newFasterStyle = {
                            top: 0,
                            bottom: null,
                            position: 'relative'
                        };
                    }
                }
            }
            if (!(0, _isEqual2.default)(newFasterStyle, this.state.fasterStyle) && newFasterStyle) {
                this.setState({
                    fasterStyle: newFasterStyle
                });
            }
        }
    }, {
        key: "createShell",
        value: function createShell(container) {
            var _this4 = this;

            this._shell = new _sheetShell.MobileSheetShell(container, this.props.collaSpread.spread, this.props.collaSpread.context, true);
            this._shell.initTeaEvents(function (operation, data) {
                data = data || {};
                (0, _tea.collectSuiteEvent)(operation, Object.assign({
                    shell_file_id: (0, _tea.getEncryToken)()
                }, data));
            });
            this._shell.sheetView().addListener(_core.FEventType.BeforeFlush, function () {
                _this4._syncVirtualScroll();
                setTimeout(function () {
                    return _this4.doViewportResize();
                });
                return false;
            });
            this._shell.sheetView().children().each(function (child) {
                if (child instanceof _sheetShell.MobileTableView) {
                    child.contentDoc().addListener(_core.FEventType.AfterChange, function (e) {
                        if (_this4.isFixSize()) {
                            return false;
                        }
                        var ce = e;
                        if ('posX' in ce.changes && 'posY' in ce.changes) {
                            var x = ce.changes['posX'];
                            var y = ce.changes['posY'];
                            if (Math.abs(x.current - x.before) > Math.abs(y.current - y.before)) {
                                y.current = y.before;
                            }
                        }
                        var changes = ce.changes;
                        if (!_this4._isInVirtualScroll && !_this4._virtualScrollSyncing && changes.posY !== undefined) {
                            var oPosY = changes.posY.before || 0;
                            _this4._scrollY(changes.posY.current - oPosY);
                            changes.posY.current = oPosY;
                        }
                        return false;
                    });
                }
            });
        }
    }, {
        key: "_scrollParent",
        value: function _scrollParent(node) {
            var p = node;
            if (this.scrollContainer) {
                return this.scrollContainer;
            }
            var style = p && getComputedStyle(p);
            while (p && (p.scrollHeight <= p.clientHeight || style.overflowY !== 'scroll' && style.overflowY !== 'auto')) {
                p = p.parentElement;
                style = p && getComputedStyle(p);
            }
            this.scrollContainer = p || window;
            return this.scrollContainer;
        }
    }, {
        key: "testSupportSticky",
        value: function testSupportSticky() {
            var testNode = document.createElement('div');
            var prefixes = ['', '-webkit-'];
            return prefixes.some(function (prefix) {
                try {
                    testNode.style.position = prefix + 'sticky';
                } catch (e) {
                    // Raven上报
                    window.Raven && window.Raven.captureException(e);
                    // ConsoleError
                    console.error(e);
                }
                return testNode.style.position !== '';
            });
        }
    }, {
        key: "render",
        value: function render() {
            var _this5 = this;

            var _state = this.state,
                width = _state.width,
                height = _state.height,
                screenShotBlob = _state.screenShotBlob;
            var _props4 = this.props,
                copyPermission = _props4.copyPermission,
                editable = _props4.editable,
                commentable = _props4.commentable,
                online = _props4.online,
                collaSpreadLoaded = _props4.collaSpreadLoaded,
                sheetId = _props4.sheetId,
                isSelect = _props4.isSelect,
                isBlob = _props4.isBlob;
            var spread = this.props.collaSpread.spread;

            var sheetContainerStyle = {
                width: width,
                height: height,
                position: 'relative'
            };
            var _state$fasterStyle = this.state.fasterStyle,
                position = _state$fasterStyle.position,
                top = _state$fasterStyle.top,
                bottom = _state$fasterStyle.bottom;

            var canCopy = copyPermission === _common.USER_TYPE_ON_SUITE.READABLE || editable;
            if (this.isFixSize()) {
                sheetContainerStyle.margin = 'auto';
            }
            var fasterStyle = {
                position: position
            };
            if (top != null) {
                fasterStyle.top = top;
            } else if (bottom != null) {
                fasterStyle.bottom = bottom;
            }
            var fasterCanvasStyle = {
                display: 'block'
            };
            var screenShotImg = null;
            if (screenShotBlob) {
                console.log("SheetScreenShot " + sheetId);
                var imgSrc = isBlob ? window.URL.createObjectURL(screenShotBlob) : screenShotBlob;
                fasterCanvasStyle.display = 'none';
                screenShotImg = _react2.default.createElement("img", { src: imgSrc, style: { width: '100%' }, onLoad: function onLoad() {
                        isBlob && window.URL.revokeObjectURL(imgSrc);
                    } });
            }
            return _react2.default.createElement("div", { className: "spreadsheet-wrap embed-spreadsheet-wrap sheet-id-" + sheetId, ref: this.getDomRef }, !online && _react2.default.createElement("div", { className: "spreadsheet-info spreadsheet-info_offline" }, _react2.default.createElement(_info2.default, { className: "spreadsheet-info__icon" }), _react2.default.createElement("span", null, t('sheet.no_offline_edit_support'))), online && !collaSpreadLoaded && _react2.default.createElement("div", { className: "spreadsheet-info" }, _react2.default.createElement(_info2.default, { className: "spreadsheet-info__icon" }), _react2.default.createElement("span", null, t('sheet.still_loading_tips'))), _react2.default.createElement("div", { className: "faster-wrapper", style: sheetContainerStyle, ref: function ref(_ref5) {
                    return _this5._virtualWrap = _ref5;
                } }, _react2.default.createElement("div", { className: "\n                spreadsheet embed-spreadsheet faster\n                " + (this.isSupportSticky ? 'faster-sticky' : '') + "\n                " + (collaSpreadLoaded ? 'spread-loaded' : '') + "\n                " + (isSelect ? 'embed-spreadsheet_select' : '') + "\n              ", style: this.isSupportSticky ? {} : fasterStyle, ref: this.setFasterDom }, editable && this._shell && _react2.default.createElement(_headerSelectionBubble2.default, { sheet: this.getCurrentSheet(), shell: this._shell, isEmbed: true }), screenShotImg, _react2.default.createElement("canvas", { className: "spreadsheet-canvas", style: fasterCanvasStyle, ref: function ref(_ref6) {
                    return _this5._canvas = _ref6;
                } })), _sdkCompatibleHelper.isSupportSheetContextMenu && _react2.default.createElement(_ContextMenu2.default, { spread: spread, shell: this._shell, sheetId: sheetId, editable: editable, commentable: commentable, canCopy: canCopy, sheetRef: this._canvas, isEmbed: true }), _sdkCompatibleHelper.isSupportSheetToolbar && _react2.default.createElement(_Toolbar_m2.default, { spread: spread, commentable: commentable, editable: editable, sheetId: sheetId, isEmbed: true })));
        }
    }]);
    return EmbedSheet;
}(_react2.default.Component);

__decorate([(0, _$decorators.Bind)()], EmbedSheet.prototype, "handleEndEdit", null);
__decorate([(0, _$decorators.Bind)()], EmbedSheet.prototype, "handleStartEdit", null);
__decorate([(0, _$decorators.Bind)()], EmbedSheet.prototype, "handleFinishScreenshot", null);
__decorate([(0, _$decorators.Bind)()], EmbedSheet.prototype, "handleRequestScreenshot", null);
__decorate([(0, _$decorators.Bind)()], EmbedSheet.prototype, "preventFocusCanvas", null);
__decorate([(0, _$decorators.Bind)()], EmbedSheet.prototype, "unpreventFocusCanvas", null);
__decorate([(0, _$decorators.Bind)()], EmbedSheet.prototype, "preventDefault", null);
__decorate([(0, _$decorators.Bind)()], EmbedSheet.prototype, "handleActiveSheetChanged", null);
__decorate([(0, _$decorators.Bind)()], EmbedSheet.prototype, "handleSheetSelectEvent", null);
exports.default = (0, _reactRedux.connect)(function (state) {
    return {
        editable: (0, _sheet2.editableSelector)(state) && state.sheet.status.online,
        commentable: (0, _sheet2.commentableSelector)(state),
        onComment: state.sheet.embedToolbar.onComment,
        canCopy: (0, _share.selectCopyPermission)(state),
        online: state.sheet.status.online
    };
}, function (dispatch) {
    return (0, _redux.bindActionCreators)({
        setActiveSheetId: _sheet3.setActiveSheetId,
        showHyperlinkEditor: _sheet3.showHyperlinkEditor
    }, dispatch);
})(EmbedSheet);
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 3840:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(20);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 16 16", fill: "#88909A" }, props),
    _react2.default.createElement("path", { d: "M8 15.5a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15zm0-1a6.5 6.5 0 1 0 0-13 6.5 6.5 0 0 0 0 13zM6 8.22v-.5C7.1 6.53 7.93 5.99 8.52 6.1c.89.17.8.94.74 1.23-.05.3-1.8 4.6-1.44 4.66.24.04.72-.34 1.44-1.16v.63C8.6 12.48 7.75 13 6.68 13c-.67 0-.82-.59-.56-1.26.56-1.46 1.52-3.95 1.52-4.42 0-.47-.54-.17-1.63.9zM8.7 5.3a1.15 1.15 0 1 1 0-2.3 1.15 1.15 0 0 1 0 2.3z" })
  );
};

/***/ }),

/***/ 3841:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _sheetCommon = __webpack_require__(1591);

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var EmbedUndoManager = function () {
    function EmbedUndoManager(spread, undoManger) {
        var _this = this;

        (0, _classCallCheck3.default)(this, EmbedUndoManager);

        this.spread = spread;
        this.undoManger = undoManger;
        this.execCmd = function (cmdData, type) {
            var spread = _this.spread;

            var sheet = spread.getSheetFromId(cmdData.sheetId);
            if (!sheet) return;
            try {
                var cmd = spread.commandManager()[cmdData.cmd];
                if (cmd) {
                    cmd.execute(spread, cmdData, type);
                }
            } catch (e) {
                // Raven上报
                _$moirae2.default.ravenCatch(e);
            }
        };
        undoManger.onNotify(this.execCmd);
    }

    (0, _createClass3.default)(EmbedUndoManager, [{
        key: '_addCommand',
        value: function _addCommand(cmdData, actionType) {
            if (cmdData && actionType === _sheetCommon.ActionType.execute) {
                this.undoManger.do(cmdData);
            }
        }
    }, {
        key: 'canUndo',
        value: function canUndo() {
            return this.undoManger.canUndo();
        }
    }, {
        key: 'undo',
        value: function undo() {
            this.undoManger.undo();
            return true;
        }
    }, {
        key: 'canRedo',
        value: function canRedo() {
            return this.undoManger.canRedo();
        }
    }, {
        key: 'redo',
        value: function redo() {
            this.undoManger.redo();
            return true;
        }
    }, {
        key: 'clear',
        value: function clear() {
            //
        }
    }, {
        key: 'dispose',
        value: function dispose() {
            var sheetId = this.spread.getActiveSheet().id();
            this.undoManger.clearBySheetId(sheetId);
            this.undoManger.offNotify(this.execCmd);
        }
    }]);
    return EmbedUndoManager;
}();

exports.default = EmbedUndoManager;

/***/ }),

/***/ 3842:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.EmbedSheetCommentManager = undefined;

var _regenerator = __webpack_require__(12);

var _regenerator2 = _interopRequireDefault(_regenerator);

var _asyncToGenerator2 = __webpack_require__(99);

var _asyncToGenerator3 = _interopRequireDefault(_asyncToGenerator2);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _uniqBy2 = __webpack_require__(788);

var _uniqBy3 = _interopRequireDefault(_uniqBy2);

var _sheetIo = __webpack_require__(1621);

var _sheetCore = __webpack_require__(1594);

var _string = __webpack_require__(163);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Commands = _sheetCore.Sheets.CommandKeys;

var EmbedSheetCommentManager = exports.EmbedSheetCommentManager = function () {
    function EmbedSheetCommentManager(manager) {
        var _this = this;

        (0, _classCallCheck3.default)(this, EmbedSheetCommentManager);

        this.handleAcceptCommentChange = function (e) {
            var commentId = e.comment_id,
                sheetId = e.sheet_id;

            var commentItem = _this.findCommentCore(sheetId, commentId);
            var targetSheet = _this.spread.getSheetFromId(sheetId);
            if (commentItem && targetSheet) {
                var comments = targetSheet.getComments(commentItem.row, commentItem.col) || [];
                targetSheet.setComments(commentItem.row, commentItem.col, (0, _uniqBy3.default)(comments.concat({
                    id: commentId,
                    isResolved: false
                }).reverse(), 'id').reverse());
                var embedSheet = _this.manager.imp.getEmbedSheet(sheetId);
                if (embedSheet.props.comment.onCommentBatchUpdate) {
                    embedSheet.props.comment.onCommentBatchUpdate();
                }
            }
        };
        this.manager = manager;
        this.spread = this.manager.imp.collaSpread.spread;
        this.commentData = new Map();
        this.commentDataReadyMap = {};
        var context = this.manager.imp.collaSpread.context;
        context.bind(_sheetIo.CollaborativeEvents.ACCEPT_COMMENT_CHANGE, this.handleAcceptCommentChange);
    }

    (0, _createClass3.default)(EmbedSheetCommentManager, [{
        key: 'destroy',
        value: function destroy() {
            var context = this.manager.imp.collaSpread.context;
            context.unbind(_sheetIo.CollaborativeEvents.ACCEPT_COMMENT_CHANGE, this.handleAcceptCommentChange);
        }
        // 从左到右从上到下的 ThirdPartyComment[]
        // 不用包含Resolved
        // 不用关心数据是否加载完

    }, {
        key: 'getComments',
        value: function getComments(sheetId) {
            var _this2 = this;

            return this.getCommentsRaw(sheetId).filter(function (item) {
                return item.resolved === false;
            }).map(function (item) {
                return _this2.commentRaw2BlockSheetCommentInfo(item);
            });
        }
        // 激活单元格 ThirdPartyComment[]
        // 不用关心数据是否加载完

    }, {
        key: 'getActiveComments',
        value: function getActiveComments(sheetId) {
            var _this3 = this;

            var activeCordinate = this.getActiveCellCordinateInfo(sheetId);
            if (activeCordinate) {
                return this.getCommentsRaw(sheetId).filter(function (item) {
                    return item.col === activeCordinate.col && item.row === activeCordinate.row && item.resolved === false;
                }).map(function (item) {
                    return _this3.commentRaw2BlockSheetCommentInfo(item);
                });
            } else {
                return [];
            }
        }
        // 表格中被Resolved的ThirdPartyComment[]
        // 不用关心数据是否加载完

    }, {
        key: 'getResolvedComments',
        value: function getResolvedComments(sheetId) {
            var _this4 = this;

            return this.getCommentsRaw(sheetId).filter(function (item) {
                return item.resolved;
            }).map(function (item) {
                return _this4.commentRaw2BlockSheetCommentInfo(item);
            });
        }
        // 新启动一个Comment，这里会有一个临时CommentId写入Sheet数据结构中
        // tempCommentId: 临时CommentId
        // 利用tempCommentId 去实现UI变更

    }, {
        key: 'startNewComment',
        value: function startNewComment(sheetId, tempCommentId) {
            var activeCordinate = this.getActiveCellCordinateInfo(sheetId);
            var targetSheet = this.spread.getSheetFromId(sheetId);
            if (!activeCordinate || !targetSheet) {
                return;
            }
            var comments = targetSheet.getComments(activeCordinate.row, activeCordinate.col) || [];
            targetSheet.setComments(activeCordinate.row, activeCordinate.col, (0, _uniqBy3.default)(comments.concat({
                id: tempCommentId,
                isResolved: false
            }).reverse(), 'id').reverse());
            this.activateComment(sheetId, tempCommentId);
            // 返回坐标
            var rect = targetSheet.getCellRect(activeCordinate.row, activeCordinate.col);
            return {
                offsetTop: rect.y,
                offsetHeight: rect.height,
                cellCordinate: '' + (0, _string.intToAZ)(activeCordinate.col) + activeCordinate.row
            };
        }
        // 保存Comment
        // tempCommentId: 临时CommentId
        // commentId: 正式CommentId

    }, {
        key: 'saveComment',
        value: function saveComment(sheetId, commentId) {
            var _this5 = this;

            var tempCommentId = arguments.length > 2 && arguments[2] !== undefined ? arguments[2] : '';
            var isResolved = arguments.length > 3 && arguments[3] !== undefined ? arguments[3] : false;

            return new Promise(function (resolve, reject) {
                var targetSheet = _this5.spread.getSheetFromId(sheetId);
                var commandManager = _this5.spread.commandManager();
                if (!targetSheet) {
                    return reject();
                }
                var tempCommentItem = _this5.findCommentCore(sheetId, tempCommentId);
                if (!tempCommentItem) {
                    return reject();
                }
                // 解释以下为什么isResolved一定为True
                // 是因为，后端默认记录都是isResolve，这样可以在数据加载的时候确保不会有黄点渲染出来
                // 等到评论数据Ready后，根据评论数据是否Resolve，动态改变评论状态，显示黄点
                commandManager.execute({
                    cmd: Commands.SET_COMMENTS,
                    sheetId: targetSheet.id(),
                    target: {
                        row: tempCommentItem.row,
                        col: tempCommentItem.col
                    },
                    value: {
                        comments: [{
                            id: commentId,
                            isResolved: true
                        }]
                    }
                });
                if (tempCommentId !== commentId) {
                    _this5.removeTempComment(sheetId, tempCommentId, true);
                }
                var comments = targetSheet.getComments(tempCommentItem.row, tempCommentItem.col) || [];
                targetSheet.setComments(tempCommentItem.row, tempCommentItem.col, (0, _uniqBy3.default)(comments.concat({
                    id: commentId,
                    isResolved: false
                }).reverse(), 'id').reverse());
                resolve();
            });
        }
        // 清除一个Comment，需要扫描所有Sheet

    }, {
        key: 'removeComment',
        value: function removeComment(sheetId, commentId) {
            this.removeTempComment(sheetId, commentId);
        }
        // 清除临时Comment

    }, {
        key: 'removeTempComment',
        value: function removeTempComment(sheetId, commentId, active) {
            var commentRawInfo = this.findCommentCore(sheetId, commentId);
            var targetSheet = this.spread.getSheetFromId(sheetId);
            if (!commentRawInfo || !targetSheet) {
                return;
            }
            var commentsOld = targetSheet.getComments(commentRawInfo.row, commentRawInfo.col) || [];
            var commentNew = commentsOld.filter(function (item) {
                return item.id !== commentId;
            });
            targetSheet.setComments(commentRawInfo.row, commentRawInfo.col, commentNew);
            !active && this.deactivateComment(sheetId, commentId);
        }
        // 高亮指定CommentId对应的单元格
        // 鼠标移动到评论卡片时，高亮对应的单元格

    }, {
        key: 'addHighlight',
        value: function addHighlight(sheetId, commentId) {
            var targetSheet = this.spread.getSheetFromId(sheetId);
            if (!targetSheet) {
                return;
            }
            var commentRawInfo = this.findCommentCore(sheetId, commentId);
            commentRawInfo && targetSheet.setHoverComment(commentRawInfo.row, commentRawInfo.col);
        }
        // 取消高亮指定CommentId对应的单元格

    }, {
        key: 'removeHighlight',
        value: function removeHighlight(sheetId, commentId) {
            var targetSheet = this.spread.getSheetFromId(sheetId);
            if (!targetSheet) {
                return;
            }
            targetSheet.clearHoverComment();
        }
        // 高亮指定CommentId对应的单元格
        // 鼠标点击到评论卡片时，高亮对应的单元格

    }, {
        key: 'activateComment',
        value: function activateComment(sheetId, commentId) {
            var targetSheet = this.spread.getSheetFromId(sheetId);
            if (!targetSheet) {
                return;
            }
            var activeSheet = this.spread.getActiveSheet();
            if (targetSheet !== activeSheet) {
                this.spread.setActiveSheet(targetSheet.name(), true);
            }
            var commentRawInfo = this.findCommentCore(sheetId, commentId);
            if (commentRawInfo) {
                targetSheet.clearHoverComment();
                targetSheet.clearActiveComment();
                targetSheet.showCell(commentRawInfo.row, commentRawInfo.col, 0, 0);
                targetSheet.addActiveComment(commentRawInfo.row, commentRawInfo.col);
                targetSheet.setActiveCell(commentRawInfo.row, commentRawInfo.col);
            }
        }
        // 取消高亮指定CommentId对应的单元格

    }, {
        key: 'deactivateComment',
        value: function deactivateComment(sheetId, commentId) {
            var targetSheet = this.spread.getSheetFromId(sheetId);
            if (!targetSheet) {
                return;
            }
            targetSheet.clearActiveComment();
        }
        // Resolve一个Comment
        // 需要确认所有Sheet中的这个Comment确实被Resolve后再Resolve

    }, {
        key: 'resolveComment',
        value: function resolveComment(sheetId, commentId) {
            var _this6 = this;

            return new Promise(function () {
                var _ref = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee(resolve, reject) {
                    var targetSheet, commentRawInfo, row, col, comments;
                    return _regenerator2.default.wrap(function _callee$(_context) {
                        while (1) {
                            switch (_context.prev = _context.next) {
                                case 0:
                                    _context.next = 2;
                                    return _this6.waitForSpreadLoaded();

                                case 2:
                                    targetSheet = _this6.spread.getSheetFromId(sheetId);

                                    if (targetSheet) {
                                        _context.next = 5;
                                        break;
                                    }

                                    return _context.abrupt('return');

                                case 5:
                                    commentRawInfo = _this6.findCommentCore(sheetId, commentId);

                                    if (commentRawInfo) {
                                        _context.next = 8;
                                        break;
                                    }

                                    return _context.abrupt('return');

                                case 8:
                                    row = commentRawInfo.row, col = commentRawInfo.col;
                                    comments = targetSheet.getComments(row, col) || [];

                                    targetSheet.setComments(row, col, (0, _uniqBy3.default)(comments.concat({
                                        id: commentId,
                                        isResolved: true
                                    }).reverse(), 'id').reverse());
                                    resolve();

                                case 12:
                                case 'end':
                                    return _context.stop();
                            }
                        }
                    }, _callee, _this6);
                }));

                return function (_x3, _x4) {
                    return _ref.apply(this, arguments);
                };
            }());
        }
        // reopen一个Comment
        // 需要确认所有Sheet中的这个Comment确实被Resolve后再Resolve

    }, {
        key: 'reopenComment',
        value: function reopenComment(sheetId, commentId) {
            var _this7 = this;

            return new Promise(function () {
                var _ref2 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee2(resolve, reject) {
                    var targetSheet, commentRawInfo, row, col, comments;
                    return _regenerator2.default.wrap(function _callee2$(_context2) {
                        while (1) {
                            switch (_context2.prev = _context2.next) {
                                case 0:
                                    _context2.next = 2;
                                    return _this7.waitForSpreadLoaded();

                                case 2:
                                    targetSheet = _this7.spread.getSheetFromId(sheetId);

                                    if (targetSheet) {
                                        _context2.next = 5;
                                        break;
                                    }

                                    return _context2.abrupt('return');

                                case 5:
                                    commentRawInfo = _this7.findCommentCore(sheetId, commentId);

                                    if (commentRawInfo) {
                                        _context2.next = 8;
                                        break;
                                    }

                                    return _context2.abrupt('return');

                                case 8:
                                    row = commentRawInfo.row, col = commentRawInfo.col;
                                    comments = targetSheet.getComments(row, col) || [];

                                    targetSheet.setComments(row, col, (0, _uniqBy3.default)(comments.concat({
                                        id: commentId,
                                        isResolved: false
                                    }).reverse(), 'id').reverse());
                                    resolve();

                                case 12:
                                case 'end':
                                    return _context2.stop();
                            }
                        }
                    }, _callee2, _this7);
                }));

                return function (_x5, _x6) {
                    return _ref2.apply(this, arguments);
                };
            }());
        }
        // 行为埋点

    }, {
        key: 'getQuoteType',
        value: function getQuoteType(sheetId, commentId) {
            throw new Error('NOT IMPLEMENT');
        }
        // 查找一个Comment并滚动到对应位置，完成后Resolve

    }, {
        key: 'findComment',
        value: function findComment(sheetId, commentId) {
            var _this8 = this;

            return new Promise(function () {
                var _ref3 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee3(resolve, reject) {
                    var targetSheet, commentRawInfo;
                    return _regenerator2.default.wrap(function _callee3$(_context3) {
                        while (1) {
                            switch (_context3.prev = _context3.next) {
                                case 0:
                                    _context3.next = 2;
                                    return _this8.waitForSpreadLoaded();

                                case 2:
                                    _context3.next = 4;
                                    return _this8.waitForCommentDataReady(sheetId);

                                case 4:
                                    targetSheet = _this8.spread.getSheetFromId(sheetId);
                                    commentRawInfo = _this8.findCommentCore(sheetId, commentId);

                                    if (commentRawInfo) {
                                        // 返回坐标
                                        targetSheet.showCell(commentRawInfo.row, commentRawInfo.col, 0, 0);
                                        resolve({
                                            row: commentRawInfo.row,
                                            col: commentRawInfo.col,
                                            offsetTop: commentRawInfo.top,
                                            offsetHeight: commentRawInfo.height
                                        });
                                    } else {
                                        reject();
                                    }

                                case 7:
                                case 'end':
                                    return _context3.stop();
                            }
                        }
                    }, _callee3, _this8);
                }));

                return function (_x7, _x8) {
                    return _ref3.apply(this, arguments);
                };
            }());
        }
        // 设置被解决的Comment列表

    }, {
        key: 'setResolvedCommentIds',
        value: function setResolvedCommentIds(sheetId, resolvedCommentIds) {
            var _this9 = this;

            resolvedCommentIds.forEach(function (item) {
                _this9.resolveComment(sheetId, item);
            });
        }
        // 设置评论数据

    }, {
        key: 'setCommentData',
        value: function () {
            var _ref4 = (0, _asyncToGenerator3.default)( /*#__PURE__*/_regenerator2.default.mark(function _callee4(sheetId, commentData) {
                var _this10 = this;

                var targetSheet, updateCommentItem;
                return _regenerator2.default.wrap(function _callee4$(_context4) {
                    while (1) {
                        switch (_context4.prev = _context4.next) {
                            case 0:
                                _context4.next = 2;
                                return this.waitForSpreadLoaded();

                            case 2:
                                targetSheet = this.spread.getSheetFromId(sheetId);

                                this.commentData.set(sheetId, commentData);

                                updateCommentItem = function updateCommentItem(commentId, isResolved) {
                                    var commentItem = _this10.findCommentCore(sheetId, commentId);
                                    if (!commentItem) {
                                        return;
                                    } else {
                                        var comments = targetSheet.getComments(commentItem.row, commentItem.col) || [];
                                        targetSheet.setComments(commentItem.row, commentItem.col, (0, _uniqBy3.default)(comments.concat({
                                            id: commentId,
                                            isResolved: isResolved
                                        }).reverse(), 'id').reverse());
                                    }
                                };

                                commentData.comments.forEach(function (cItem) {
                                    updateCommentItem(cItem.commentId, cItem.finish === 1);
                                });
                                this.commentDataReadyMap[sheetId] = true;

                            case 7:
                            case 'end':
                                return _context4.stop();
                        }
                    }
                }, _callee4, this);
            }));

            function setCommentData(_x9, _x10) {
                return _ref4.apply(this, arguments);
            }

            return setCommentData;
        }()
        // 获取全量评论数据

    }, {
        key: 'getSheetCommentData',
        value: function getSheetCommentData(sheetId) {
            return this.commentData.get(sheetId);
        }
        // 查找一个Comment并滚动到对应位置，完成后Resolve

    }, {
        key: 'findCommentCore',
        value: function findCommentCore(sheetId, commentId) {
            var commentRawInfo = this.getCommentsRaw(sheetId);
            var targetCommentInfo = commentRawInfo.filter(function (item) {
                return item.id === commentId;
            });
            if (targetCommentInfo && targetCommentInfo.length > 0) {
                return targetCommentInfo[0];
            } else {
                return null;
            }
        }
    }, {
        key: 'getCommentsRaw',
        value: function getCommentsRaw(sheetId) {
            var targetSheet = this.spread.getSheetFromId(sheetId);
            var commentRawList = [];
            if (targetSheet) {
                var allComments = targetSheet.getAllComments();
                allComments.forEach(function (item) {
                    var cellPos = targetSheet.getCellInDocPos(item.row, item.col);
                    var cellRect = targetSheet.getCellRect(item.row, item.col);
                    if (cellPos && cellRect) {
                        item.comments.forEach(function (cItem) {
                            commentRawList.push({
                                id: cItem.id,
                                row: item.row,
                                col: item.col,
                                top: cellPos.y,
                                height: cellRect.height,
                                resolved: cItem.isResolved
                            });
                        });
                    }
                });
                return commentRawList;
            } else {
                return [];
            }
        }
    }, {
        key: 'commentRaw2BlockSheetCommentInfo',
        value: function commentRaw2BlockSheetCommentInfo(raw) {
            return {
                commentId: raw.id,
                offsetTop: raw.top,
                offsetHeight: raw.height,
                isResolved: raw.resolved
            };
        }
    }, {
        key: 'getActiveCellCordinateInfo',
        value: function getActiveCellCordinateInfo(sheetId) {
            var targetSheet = this.spread.getSheetFromId(sheetId);
            if (targetSheet) {
                return {
                    row: targetSheet.getActiveRowIndex(),
                    col: targetSheet.getActiveColumnIndex()
                };
            } else {
                return null;
            }
        }
    }, {
        key: 'waitForSpreadLoaded',
        value: function waitForSpreadLoaded() {
            var _this11 = this;

            return new Promise(function (resolve, reject) {
                var checkCore = function checkCore() {
                    if (_this11.manager.checkSpreadLoaded()) {
                        resolve();
                    } else {
                        setTimeout(checkCore, 500);
                    }
                };
                checkCore();
            });
        }
    }, {
        key: 'waitForCommentDataReady',
        value: function waitForCommentDataReady(sheetId) {
            var _this12 = this;

            return new Promise(function (resolve, reject) {
                var checkCore = function checkCore() {
                    if (_this12.commentDataReadyMap[sheetId]) {
                        resolve();
                    } else {
                        setTimeout(checkCore, 500);
                    }
                };
                checkCore();
            });
        }
    }]);
    return EmbedSheetCommentManager;
}();

exports.default = EmbedSheetCommentManager;

/***/ }),

/***/ 3843:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.default = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(10);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(11);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _sheetPlaceholder = __webpack_require__(3844);

var _$moirae = __webpack_require__(449);

var _$moirae2 = _interopRequireDefault(_$moirae);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var checkTimer = 0;
var tick = 0;
var dataStoreMonitor = null;
var spreadMonitor = null;
var spreadLoadedMonitor = false;
var isInitCheck = true;
var loadStateMap = {};
var checkLoadState = function checkLoadState() {
    tick += 1;
    if (tick > 60 && spreadLoadedMonitor === true) {
        window.clearInterval(checkTimer);
        var keys = Object.getOwnPropertyNames(loadStateMap);
        var badCase = 0;
        keys.forEach(function (item) {
            if (loadStateMap[item] !== true) {
                badCase += 1;
            }
        });
        if (badCase !== 0) {
            if (isInitCheck) {
                _$moirae2.default.mean('ee.docs.sheet.embed.load_succ_initial', 0);
            } else {
                _$moirae2.default.mean('ee.docs.sheet.embed.load_succ_edit', 0);
            }
            findoutWhy();
        } else {
            if (isInitCheck) {
                _$moirae2.default.mean('ee.docs.sheet.embed.load_succ_initial', 1);
            } else {
                _$moirae2.default.mean('ee.docs.sheet.embed.load_succ_edit', 1);
            }
        }
        isInitCheck = false;
    }
};
var findoutWhy = function findoutWhy() {
    var keys = Object.getOwnPropertyNames(loadStateMap);
    if (!dataStoreMonitor || !spreadMonitor) {
        return;
    }
    var dataStoreSheets = Object.getOwnPropertyNames(dataStoreMonitor.sheets);
    var dataStoreMountedSheets = dataStoreMonitor.mountedSheets;
    keys.forEach(function (item) {
        // 查找出未成功的ID
        if (loadStateMap[item] !== true) {
            var hasReason = true;
            var sheet = spreadMonitor.getSheetFromId(item);
            if (dataStoreSheets.indexOf(item) === -1) {
                hasReason = true;
                _$moirae2.default.count('ee.docs.sheet.embed_manager_datastore_target_sheet_not_in');
            }
            if (dataStoreMountedSheets.indexOf(item) === -1) {
                hasReason = true;
                _$moirae2.default.count('ee.docs.sheet.embed_manager_datastore_mounted_target_sheet_not_in');
            }
            if (!sheet) {
                hasReason = true;
                _$moirae2.default.count('ee.docs.sheet.embed_manager_sheet_not_in_spread');
            }
            if (!hasReason) {
                _$moirae2.default.count('ee.docs.sheet.embed_manager_unknow');
            }
        }
    });
};

var PerformanceEmbedSheet = function (_React$PureComponent) {
    (0, _inherits3.default)(PerformanceEmbedSheet, _React$PureComponent);

    function PerformanceEmbedSheet(props) {
        (0, _classCallCheck3.default)(this, PerformanceEmbedSheet);

        var _this = (0, _possibleConstructorReturn3.default)(this, (PerformanceEmbedSheet.__proto__ || Object.getPrototypeOf(PerformanceEmbedSheet)).call(this, props));

        _this.comp = null;
        _this.onMountEmbedSheet = function (ref) {
            if (ref) {
                _this.props.onMountEmbedSheet(_this.props.sheetId);
            }
        };
        _this.state = {
            zoom: 1,
            maxWidth: props.maxWidth,
            content: null,
            isScreenShotMode: false,
            isBlob: false
        };
        return _this;
    }

    (0, _createClass3.default)(PerformanceEmbedSheet, [{
        key: 'componentDidMount',
        value: function componentDidMount() {
            this.props.onMount(this.props.sheetId, this);
        }
    }, {
        key: 'componentWillUnmount',
        value: function componentWillUnmount() {
            var sheetId = this.props.sheetId;

            delete loadStateMap[sheetId];
            this.props.onUnmount(this.props.sheetId, this);
        }
    }, {
        key: 'onMaxWidthChange',
        value: function onMaxWidthChange(maxWidth) {
            this.setState({ maxWidth: maxWidth, maxHeight: Infinity });
        }
    }, {
        key: 'onSizeChange',
        value: function onSizeChange(maxWidth, maxHeight) {
            this.setState({ maxWidth: maxWidth, maxHeight: maxHeight });
        }
    }, {
        key: 'setEmbedSheet',
        value: function setEmbedSheet(embedSheet) {
            this.setState({ content: embedSheet });
        }
    }, {
        key: 'onZoomChange',
        value: function onZoomChange(zoom) {
            this.setState({ zoom: zoom });
        }
    }, {
        key: 'onScreenShot',
        value: function onScreenShot() {
            var isBlob = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : true;
            var isScreenShotMode = arguments[1];

            this.setState({
                isScreenShotMode: isScreenShotMode,
                isBlob: isBlob
            });
        }
    }, {
        key: 'render',
        value: function render() {
            var state = this.state;
            var _props = this.props,
                sheetId = _props.sheetId,
                dataStore = _props.dataStore,
                collaSpread = _props.collaSpread;
            var spread = collaSpread.spread;

            dataStoreMonitor = dataStore;
            spreadMonitor = spread;
            if (spreadLoadedMonitor !== true) {
                spreadLoadedMonitor = collaSpread.spreadLoaded;
            }
            if (state.content !== null) {
                loadStateMap[sheetId] = true;
                this.comp = _react2.default.cloneElement(state.content, {
                    zoom: state.zoom,
                    editor: this.props.editor,
                    maxWidth: state.maxWidth,
                    maxHeight: state.maxHeight,
                    isScreenShotMode: state.isScreenShotMode,
                    isBlob: state.isBlob,
                    ref: this.onMountEmbedSheet
                });
            } else {
                console.log('state content is null ' + sheetId);
                loadStateMap[sheetId] = false;
            }
            tick = 0;
            window.clearInterval(checkTimer);
            checkTimer = window.setInterval(checkLoadState, 1000);
            return this.comp || _react2.default.createElement(_sheetPlaceholder.SheetLoadingPlaceholder, { rowCount: 3, colCount: 3 });
        }
    }]);
    return PerformanceEmbedSheet;
}(_react2.default.PureComponent);

exports.default = PerformanceEmbedSheet;

/***/ }),

/***/ 3844:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.SheetPlaceholder = undefined;

var _SheetLoadingPlaceHolder = __webpack_require__(3845);

Object.keys(_SheetLoadingPlaceHolder).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _SheetLoadingPlaceHolder[key];
    }
  });
});

var _SheetPlaceholder = __webpack_require__(2253);

exports.SheetPlaceholder = _SheetPlaceholder.SheetPlaceholder;
exports.default = _SheetPlaceholder.SheetPlaceholder;

/***/ }),

/***/ 3845:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.SheetLoadingPlaceholder = undefined;

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _spin = __webpack_require__(3846);

var _spin2 = _interopRequireDefault(_spin);

var _SheetPlaceholder = __webpack_require__(2253);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SheetLoadingPlaceholder = exports.SheetLoadingPlaceholder = function SheetLoadingPlaceholder(props) {
    return _react2.default.createElement(_spin2.default, { wrapperClassName: props.wrapperClassName }, _react2.default.createElement(_SheetPlaceholder.SheetPlaceholder, { rowHeight: props.rowHeight, colWidth: props.colWidth, rowCount: props.rowCount, colCount: props.colCount, style: props.style }));
};

/***/ }),

/***/ 3846:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _Spin = __webpack_require__(3847);

Object.keys(_Spin).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _Spin[key];
    }
  });
});
exports.default = _Spin.Spin;

/***/ }),

/***/ 3847:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.Spin = undefined;

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(10);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(11);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _classnames = __webpack_require__(127);

var _classnames2 = _interopRequireDefault(_classnames);

var _block = __webpack_require__(3848);

__webpack_require__(3851);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var Spin = function (_React$PureComponent) {
    (0, _inherits3.default)(Spin, _React$PureComponent);

    function Spin(props) {
        (0, _classCallCheck3.default)(this, Spin);

        var _this = (0, _possibleConstructorReturn3.default)(this, (Spin.__proto__ || Object.getPrototypeOf(Spin)).call(this, props));

        _this.state = {
            spinning: !!props.spinning
        };
        return _this;
    }

    (0, _createClass3.default)(Spin, [{
        key: 'componentWillReceiveProps',
        value: function componentWillReceiveProps(nextProps) {
            if ('spinning' in nextProps) {
                this.setState({ spinning: !!nextProps.spinning });
            }
        }
    }, {
        key: 'render',
        value: function render() {
            var props = this.props;
            var tip = props.tip,
                children = props.children;

            var nested = !!children;
            var className = (0, _classnames2.default)(props.className, 'spin', {
                spin_nested: nested
            });
            var spin = _react2.default.createElement("div", { className: className, style: props.style }, props.indicator, tip && _react2.default.createElement("div", { className: "spin__text" }, tip));
            if (!nested) return spin;
            var spinning = this.state.spinning;

            return _react2.default.createElement("div", { className: (0, _classnames2.default)(props.wrapperClassName, 'spin-nested-container') }, spinning && spin, _react2.default.createElement("div", { className: "spin__content" }, children));
        }
    }]);
    return Spin;
}(_react2.default.PureComponent);

Spin.defaultProps = {
    indicator: _react2.default.createElement(_block.SpinIndicator, null),
    spinning: true
};
exports.Spin = Spin;

/***/ }),

/***/ 3848:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _SpinIndicator = __webpack_require__(3849);

Object.keys(_SpinIndicator).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function get() {
      return _SpinIndicator[key];
    }
  });
});

/***/ }),

/***/ 3849:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});
exports.SpinIndicator = undefined;

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

__webpack_require__(3850);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var SpinIndicator = exports.SpinIndicator = function SpinIndicator() {
    return _react2.default.createElement("div", { className: "spin-indicator" }, _react2.default.createElement("span", { className: "spin-indicator__block" }), _react2.default.createElement("span", { className: "spin-indicator__block" }), _react2.default.createElement("span", { className: "spin-indicator__block" }), _react2.default.createElement("span", { className: "spin-indicator__block" }), _react2.default.createElement("span", { className: "spin-indicator__block" }), _react2.default.createElement("span", { className: "spin-indicator__block" }), _react2.default.createElement("span", { className: "spin-indicator__block" }), _react2.default.createElement("span", { className: "spin-indicator__block" }), _react2.default.createElement("span", { className: "spin-indicator__block" }));
};

/***/ }),

/***/ 3850:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3851:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3852:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3853:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/* WEBPACK VAR INJECTION */(function(t) {

Object.defineProperty(exports, "__esModule", {
    value: true
});

var _popover = __webpack_require__(3854);

var _popover2 = _interopRequireDefault(_popover);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(10);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(11);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

var _redux = __webpack_require__(66);

var _classnames = __webpack_require__(127);

var _classnames2 = _interopRequireDefault(_classnames);

var _reactRedux = __webpack_require__(300);

var _sheet = __webpack_require__(745);

var _tea = __webpack_require__(42);

__webpack_require__(3864);

var _qaFullscreen = __webpack_require__(3865);

var _qaFullscreen2 = _interopRequireDefault(_qaFullscreen);

var _qaDelete = __webpack_require__(3866);

var _qaDelete2 = _interopRequireDefault(_qaDelete);

var _qaAccessButton = __webpack_require__(3867);

var _qaAccessButton2 = _interopRequireDefault(_qaAccessButton);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var AccessPlateRaw = function AccessPlateRaw(props) {
    var _onClick = function _onClick(type) {
        props.hideDropdownMenu();
        props.hideFindbar();
        props.onItemClick(type);
    };
    return _react2.default.createElement("ul", { className: (0, _classnames2.default)('sheet-quick-access-plate layout-column', {
            'sheet-quick-access-plate--hidden': !props.visible
        }) }, _react2.default.createElement("li", { className: "sheet-quick-access-plate__item layout-row layout-cross-center", onClick: function onClick() {
            return _onClick('FULLSCREEN');
        } }, _react2.default.createElement(_qaFullscreen2.default, { className: "sheet-quick-access-plate__icon" }), _react2.default.createElement("span", null, t('sheet.fullscreen'))), props.editable && _react2.default.createElement("li", { className: "sheet-quick-access-plate__item layout-row layout-cross-center", onClick: function onClick() {
            return _onClick('DELETE');
        } }, _react2.default.createElement(_qaDelete2.default, { className: "sheet-quick-access-plate__icon" }), _react2.default.createElement("span", null, t('sheet.delete'))));
};
var AccessPlate = (0, _reactRedux.connect)(null, function (dispatch) {
    return (0, _redux.bindActionCreators)({
        hideFindbar: _sheet.hideFindbar,
        hideDropdownMenu: _sheet.hideDropdownMenu
    }, dispatch);
})(AccessPlateRaw);

var EmbedSheetQuickAccess = function (_React$Component) {
    (0, _inherits3.default)(EmbedSheetQuickAccess, _React$Component);

    function EmbedSheetQuickAccess() {
        (0, _classCallCheck3.default)(this, EmbedSheetQuickAccess);

        var _this = (0, _possibleConstructorReturn3.default)(this, (EmbedSheetQuickAccess.__proto__ || Object.getPrototypeOf(EmbedSheetQuickAccess)).apply(this, arguments));

        _this.state = {
            plateActive: false
        };
        _this.handleOnDropdownItemClick = function (e) {
            _this.setState({
                plateActive: false
            });
            if (e === 'FULLSCREEN') {
                _this.props.onEnterFullScreen();
                (0, _tea.collectSuiteEvent)('click_enter_full_screen', { source: 'click_btn' });
            } else if (e === 'DELETE') {
                _this.props.onDeleteSheet();
                (0, _tea.collectSuiteEvent)('click_doc_delete_sheet');
            }
        };
        _this.handlePopVisibleChange = function (visible) {
            if (_this.state.plateActive !== visible) {
                _this.setState({
                    plateActive: visible
                });
            }
        };
        return _this;
    }

    (0, _createClass3.default)(EmbedSheetQuickAccess, [{
        key: 'render',
        value: function render() {
            var props = this.props,
                state = this.state;
            var spread = props.spread,
                editable = props.editable;
            var plateActive = state.plateActive;
            // if (!visible || !online) {
            //   return null;
            // }
            // if (!spreadLoaded) {
            //   return null;
            // }

            var triggerStyle = {
                fill: plateActive ? '#07F' : '#C0C4C9',
                colir: plateActive ? '#07F' : '#C0C4C9'
            };
            var plate = _react2.default.createElement(AccessPlate, { spread: spread, editable: editable, visible: plateActive, onItemClick: this.handleOnDropdownItemClick });
            return _react2.default.createElement("div", { className: "sheet-quick-access-wrapper" }, _react2.default.createElement(_popover2.default, { prefixCls: "sheet-quick-access-popover", content: plate, trigger: "hover", mouseLeaveDelay: 0.5, placement: "bottomRight", visible: plateActive, onVisibleChange: this.handlePopVisibleChange }, _react2.default.createElement(_qaAccessButton2.default, { style: triggerStyle })));
        }
    }]);
    return EmbedSheetQuickAccess;
}(_react2.default.Component);

exports.default = EmbedSheetQuickAccess;
/* WEBPACK VAR INJECTION */}.call(this, __webpack_require__(25)))

/***/ }),

/***/ 3854:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _extends2 = __webpack_require__(20);

var _extends3 = _interopRequireDefault(_extends2);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(10);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(11);

var _inherits3 = _interopRequireDefault(_inherits2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _tooltip = __webpack_require__(3855);

var _tooltip2 = _interopRequireDefault(_tooltip);

var _warning = __webpack_require__(3862);

var _warning2 = _interopRequireDefault(_warning);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var Popover = function (_React$Component) {
    (0, _inherits3['default'])(Popover, _React$Component);

    function Popover() {
        (0, _classCallCheck3['default'])(this, Popover);

        var _this = (0, _possibleConstructorReturn3['default'])(this, (Popover.__proto__ || Object.getPrototypeOf(Popover)).apply(this, arguments));

        _this.saveTooltip = function (node) {
            _this.tooltip = node;
        };
        return _this;
    }

    (0, _createClass3['default'])(Popover, [{
        key: 'getPopupDomNode',
        value: function getPopupDomNode() {
            return this.tooltip.getPopupDomNode();
        }
    }, {
        key: 'getOverlay',
        value: function getOverlay() {
            var _props = this.props,
                title = _props.title,
                prefixCls = _props.prefixCls,
                content = _props.content;

            (0, _warning2['default'])(!('overlay' in this.props), 'Popover[overlay] is removed, please use Popover[content] instead, ' + 'see: https://u.ant.design/popover-content');
            return React.createElement(
                'div',
                null,
                title && React.createElement(
                    'div',
                    { className: prefixCls + '-title' },
                    title
                ),
                React.createElement(
                    'div',
                    { className: prefixCls + '-inner-content' },
                    content
                )
            );
        }
    }, {
        key: 'render',
        value: function render() {
            var props = (0, _extends3['default'])({}, this.props);
            delete props.title;
            return React.createElement(_tooltip2['default'], (0, _extends3['default'])({}, props, { ref: this.saveTooltip, overlay: this.getOverlay() }));
        }
    }]);
    return Popover;
}(React.Component);

exports['default'] = Popover;

Popover.defaultProps = {
    prefixCls: 'ant-popover',
    placement: 'top',
    transitionName: 'zoom-big',
    trigger: 'hover',
    mouseEnterDelay: 0.1,
    mouseLeaveDelay: 0.1,
    overlayStyle: {}
};
module.exports = exports['default'];

/***/ }),

/***/ 3855:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _defineProperty2 = __webpack_require__(9);

var _defineProperty3 = _interopRequireDefault(_defineProperty2);

var _classCallCheck2 = __webpack_require__(6);

var _classCallCheck3 = _interopRequireDefault(_classCallCheck2);

var _createClass2 = __webpack_require__(7);

var _createClass3 = _interopRequireDefault(_createClass2);

var _possibleConstructorReturn2 = __webpack_require__(10);

var _possibleConstructorReturn3 = _interopRequireDefault(_possibleConstructorReturn2);

var _inherits2 = __webpack_require__(11);

var _inherits3 = _interopRequireDefault(_inherits2);

var _extends2 = __webpack_require__(20);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var React = _interopRequireWildcard(_react);

var _rcTooltip = __webpack_require__(3869);

var _rcTooltip2 = _interopRequireDefault(_rcTooltip);

var _classnames = __webpack_require__(1799);

var _classnames2 = _interopRequireDefault(_classnames);

var _placements = __webpack_require__(3860);

var _placements2 = _interopRequireDefault(_placements);

function _interopRequireWildcard(obj) { if (obj && obj.__esModule) { return obj; } else { var newObj = {}; if (obj != null) { for (var key in obj) { if (Object.prototype.hasOwnProperty.call(obj, key)) newObj[key] = obj[key]; } } newObj['default'] = obj; return newObj; } }

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var splitObject = function splitObject(obj, keys) {
    var picked = {};
    var omitted = (0, _extends3['default'])({}, obj);
    keys.forEach(function (key) {
        if (obj && key in obj) {
            picked[key] = obj[key];
            delete omitted[key];
        }
    });
    return { picked: picked, omitted: omitted };
};

var Tooltip = function (_React$Component) {
    (0, _inherits3['default'])(Tooltip, _React$Component);

    function Tooltip(props) {
        (0, _classCallCheck3['default'])(this, Tooltip);

        var _this = (0, _possibleConstructorReturn3['default'])(this, (Tooltip.__proto__ || Object.getPrototypeOf(Tooltip)).call(this, props));

        _this.onVisibleChange = function (visible) {
            var onVisibleChange = _this.props.onVisibleChange;

            if (!('visible' in _this.props)) {
                _this.setState({ visible: _this.isNoTitle() ? false : visible });
            }
            if (onVisibleChange && !_this.isNoTitle()) {
                onVisibleChange(visible);
            }
        };
        // 动态设置动画点
        _this.onPopupAlign = function (domNode, align) {
            var placements = _this.getPlacements();
            // 当前返回的位置
            var placement = Object.keys(placements).filter(function (key) {
                return placements[key].points[0] === align.points[0] && placements[key].points[1] === align.points[1];
            })[0];
            if (!placement) {
                return;
            }
            // 根据当前坐标设置动画点
            var rect = domNode.getBoundingClientRect();
            var transformOrigin = {
                top: '50%',
                left: '50%'
            };
            if (placement.indexOf('top') >= 0 || placement.indexOf('Bottom') >= 0) {
                transformOrigin.top = rect.height - align.offset[1] + 'px';
            } else if (placement.indexOf('Top') >= 0 || placement.indexOf('bottom') >= 0) {
                transformOrigin.top = -align.offset[1] + 'px';
            }
            if (placement.indexOf('left') >= 0 || placement.indexOf('Right') >= 0) {
                transformOrigin.left = rect.width - align.offset[0] + 'px';
            } else if (placement.indexOf('right') >= 0 || placement.indexOf('Left') >= 0) {
                transformOrigin.left = -align.offset[0] + 'px';
            }
            domNode.style.transformOrigin = transformOrigin.left + ' ' + transformOrigin.top;
        };
        _this.saveTooltip = function (node) {
            _this.tooltip = node;
        };
        _this.state = {
            visible: !!props.visible || !!props.defaultVisible
        };
        return _this;
    }

    (0, _createClass3['default'])(Tooltip, [{
        key: 'componentWillReceiveProps',
        value: function componentWillReceiveProps(nextProps) {
            if ('visible' in nextProps) {
                this.setState({ visible: nextProps.visible });
            }
        }
    }, {
        key: 'getPopupDomNode',
        value: function getPopupDomNode() {
            return this.tooltip.getPopupDomNode();
        }
    }, {
        key: 'getPlacements',
        value: function getPlacements() {
            var _props = this.props,
                builtinPlacements = _props.builtinPlacements,
                arrowPointAtCenter = _props.arrowPointAtCenter,
                autoAdjustOverflow = _props.autoAdjustOverflow;

            return builtinPlacements || (0, _placements2['default'])({
                arrowPointAtCenter: arrowPointAtCenter,
                verticalArrowShift: 8,
                autoAdjustOverflow: autoAdjustOverflow
            });
        }
    }, {
        key: 'isHoverTrigger',
        value: function isHoverTrigger() {
            var trigger = this.props.trigger;

            if (!trigger || trigger === 'hover') {
                return true;
            }
            if (Array.isArray(trigger)) {
                return trigger.indexOf('hover') >= 0;
            }
            return false;
        }
        // Fix Tooltip won't hide at disabled button
        // mouse events don't trigger at disabled button in Chrome
        // https://github.com/react-component/tooltip/issues/18

    }, {
        key: 'getDisabledCompatibleChildren',
        value: function getDisabledCompatibleChildren(element) {
            if ((element.type.__ANT_BUTTON || element.type === 'button') && element.props.disabled && this.isHoverTrigger()) {
                // Pick some layout related style properties up to span
                // Prevent layout bugs like https://github.com/ant-design/ant-design/issues/5254
                var _splitObject = splitObject(element.props.style, ['position', 'left', 'right', 'top', 'bottom', 'float', 'display', 'zIndex']),
                    picked = _splitObject.picked,
                    omitted = _splitObject.omitted;

                var spanStyle = (0, _extends3['default'])({ display: 'inline-block' }, picked, { cursor: 'not-allowed' });
                var buttonStyle = (0, _extends3['default'])({}, omitted, { pointerEvents: 'none' });
                var child = (0, _react.cloneElement)(element, {
                    style: buttonStyle,
                    className: null
                });
                return React.createElement(
                    'span',
                    { style: spanStyle, className: element.props.className },
                    child
                );
            }
            return element;
        }
    }, {
        key: 'isNoTitle',
        value: function isNoTitle() {
            var _props2 = this.props,
                title = _props2.title,
                overlay = _props2.overlay;

            return !title && !overlay; // overlay for old version compatibility
        }
    }, {
        key: 'render',
        value: function render() {
            var props = this.props,
                state = this.state;
            var prefixCls = props.prefixCls,
                title = props.title,
                overlay = props.overlay,
                openClassName = props.openClassName,
                getPopupContainer = props.getPopupContainer,
                getTooltipContainer = props.getTooltipContainer;

            var children = props.children;
            var visible = state.visible;
            // Hide tooltip when there is no title
            if (!('visible' in props) && this.isNoTitle()) {
                visible = false;
            }
            var child = this.getDisabledCompatibleChildren(React.isValidElement(children) ? children : React.createElement(
                'span',
                null,
                children
            ));
            var childProps = child.props;
            var childCls = (0, _classnames2['default'])(childProps.className, (0, _defineProperty3['default'])({}, openClassName || prefixCls + '-open', true));
            return React.createElement(
                _rcTooltip2['default'],
                (0, _extends3['default'])({}, this.props, { getTooltipContainer: getPopupContainer || getTooltipContainer, ref: this.saveTooltip, builtinPlacements: this.getPlacements(), overlay: overlay || title || '', visible: visible, onVisibleChange: this.onVisibleChange, onPopupAlign: this.onPopupAlign }),
                visible ? (0, _react.cloneElement)(child, { className: childCls }) : child
            );
        }
    }]);
    return Tooltip;
}(React.Component);

exports['default'] = Tooltip;

Tooltip.defaultProps = {
    prefixCls: 'ant-tooltip',
    placement: 'top',
    transitionName: 'zoom-big-fast',
    mouseEnterDelay: 0.1,
    mouseLeaveDelay: 0.1,
    arrowPointAtCenter: false,
    autoAdjustOverflow: true
};
module.exports = exports['default'];

/***/ }),

/***/ 3856:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, '__esModule', {
  value: true
});
exports['default'] = addEventListener;

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var _EventObject = __webpack_require__(3857);

var _EventObject2 = _interopRequireDefault(_EventObject);

function addEventListener(target, eventType, callback, option) {
  function wrapCallback(e) {
    var ne = new _EventObject2['default'](e);
    callback.call(target, ne);
  }

  if (target.addEventListener) {
    var _ret = (function () {
      var useCapture = false;
      if (typeof option === 'object') {
        useCapture = option.capture || false;
      } else if (typeof option === 'boolean') {
        useCapture = option;
      }

      target.addEventListener(eventType, wrapCallback, option || false);

      return {
        v: {
          remove: function remove() {
            target.removeEventListener(eventType, wrapCallback, useCapture);
          }
        }
      };
    })();

    if (typeof _ret === 'object') return _ret.v;
  } else if (target.attachEvent) {
    target.attachEvent('on' + eventType, wrapCallback);
    return {
      remove: function remove() {
        target.detachEvent('on' + eventType, wrapCallback);
      }
    };
  }
}

module.exports = exports['default'];

/***/ }),

/***/ 3857:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
 * @ignore
 * event object for dom
 * @author yiminghe@gmail.com
 */



Object.defineProperty(exports, '__esModule', {
  value: true
});

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var _EventBaseObject = __webpack_require__(3858);

var _EventBaseObject2 = _interopRequireDefault(_EventBaseObject);

var _objectAssign = __webpack_require__(558);

var _objectAssign2 = _interopRequireDefault(_objectAssign);

var TRUE = true;
var FALSE = false;
var commonProps = ['altKey', 'bubbles', 'cancelable', 'ctrlKey', 'currentTarget', 'eventPhase', 'metaKey', 'shiftKey', 'target', 'timeStamp', 'view', 'type'];

function isNullOrUndefined(w) {
  return w === null || w === undefined;
}

var eventNormalizers = [{
  reg: /^key/,
  props: ['char', 'charCode', 'key', 'keyCode', 'which'],
  fix: function fix(event, nativeEvent) {
    if (isNullOrUndefined(event.which)) {
      event.which = !isNullOrUndefined(nativeEvent.charCode) ? nativeEvent.charCode : nativeEvent.keyCode;
    }

    // add metaKey to non-Mac browsers (use ctrl for PC 's and Meta for Macs)
    if (event.metaKey === undefined) {
      event.metaKey = event.ctrlKey;
    }
  }
}, {
  reg: /^touch/,
  props: ['touches', 'changedTouches', 'targetTouches']
}, {
  reg: /^hashchange$/,
  props: ['newURL', 'oldURL']
}, {
  reg: /^gesturechange$/i,
  props: ['rotation', 'scale']
}, {
  reg: /^(mousewheel|DOMMouseScroll)$/,
  props: [],
  fix: function fix(event, nativeEvent) {
    var deltaX = undefined;
    var deltaY = undefined;
    var delta = undefined;
    var wheelDelta = nativeEvent.wheelDelta;
    var axis = nativeEvent.axis;
    var wheelDeltaY = nativeEvent.wheelDeltaY;
    var wheelDeltaX = nativeEvent.wheelDeltaX;
    var detail = nativeEvent.detail;

    // ie/webkit
    if (wheelDelta) {
      delta = wheelDelta / 120;
    }

    // gecko
    if (detail) {
      // press control e.detail == 1 else e.detail == 3
      delta = 0 - (detail % 3 === 0 ? detail / 3 : detail);
    }

    // Gecko
    if (axis !== undefined) {
      if (axis === event.HORIZONTAL_AXIS) {
        deltaY = 0;
        deltaX = 0 - delta;
      } else if (axis === event.VERTICAL_AXIS) {
        deltaX = 0;
        deltaY = delta;
      }
    }

    // Webkit
    if (wheelDeltaY !== undefined) {
      deltaY = wheelDeltaY / 120;
    }
    if (wheelDeltaX !== undefined) {
      deltaX = -1 * wheelDeltaX / 120;
    }

    // 默认 deltaY (ie)
    if (!deltaX && !deltaY) {
      deltaY = delta;
    }

    if (deltaX !== undefined) {
      /**
       * deltaX of mousewheel event
       * @property deltaX
       * @member Event.DomEvent.Object
       */
      event.deltaX = deltaX;
    }

    if (deltaY !== undefined) {
      /**
       * deltaY of mousewheel event
       * @property deltaY
       * @member Event.DomEvent.Object
       */
      event.deltaY = deltaY;
    }

    if (delta !== undefined) {
      /**
       * delta of mousewheel event
       * @property delta
       * @member Event.DomEvent.Object
       */
      event.delta = delta;
    }
  }
}, {
  reg: /^mouse|contextmenu|click|mspointer|(^DOMMouseScroll$)/i,
  props: ['buttons', 'clientX', 'clientY', 'button', 'offsetX', 'relatedTarget', 'which', 'fromElement', 'toElement', 'offsetY', 'pageX', 'pageY', 'screenX', 'screenY'],
  fix: function fix(event, nativeEvent) {
    var eventDoc = undefined;
    var doc = undefined;
    var body = undefined;
    var target = event.target;
    var button = nativeEvent.button;

    // Calculate pageX/Y if missing and clientX/Y available
    if (target && isNullOrUndefined(event.pageX) && !isNullOrUndefined(nativeEvent.clientX)) {
      eventDoc = target.ownerDocument || document;
      doc = eventDoc.documentElement;
      body = eventDoc.body;
      event.pageX = nativeEvent.clientX + (doc && doc.scrollLeft || body && body.scrollLeft || 0) - (doc && doc.clientLeft || body && body.clientLeft || 0);
      event.pageY = nativeEvent.clientY + (doc && doc.scrollTop || body && body.scrollTop || 0) - (doc && doc.clientTop || body && body.clientTop || 0);
    }

    // which for click: 1 === left; 2 === middle; 3 === right
    // do not use button
    if (!event.which && button !== undefined) {
      if (button & 1) {
        event.which = 1;
      } else if (button & 2) {
        event.which = 3;
      } else if (button & 4) {
        event.which = 2;
      } else {
        event.which = 0;
      }
    }

    // add relatedTarget, if necessary
    if (!event.relatedTarget && event.fromElement) {
      event.relatedTarget = event.fromElement === target ? event.toElement : event.fromElement;
    }

    return event;
  }
}];

function retTrue() {
  return TRUE;
}

function retFalse() {
  return FALSE;
}

function DomEventObject(nativeEvent) {
  var type = nativeEvent.type;

  var isNative = typeof nativeEvent.stopPropagation === 'function' || typeof nativeEvent.cancelBubble === 'boolean';

  _EventBaseObject2['default'].call(this);

  this.nativeEvent = nativeEvent;

  // in case dom event has been mark as default prevented by lower dom node
  var isDefaultPrevented = retFalse;
  if ('defaultPrevented' in nativeEvent) {
    isDefaultPrevented = nativeEvent.defaultPrevented ? retTrue : retFalse;
  } else if ('getPreventDefault' in nativeEvent) {
    // https://bugzilla.mozilla.org/show_bug.cgi?id=691151
    isDefaultPrevented = nativeEvent.getPreventDefault() ? retTrue : retFalse;
  } else if ('returnValue' in nativeEvent) {
    isDefaultPrevented = nativeEvent.returnValue === FALSE ? retTrue : retFalse;
  }

  this.isDefaultPrevented = isDefaultPrevented;

  var fixFns = [];
  var fixFn = undefined;
  var l = undefined;
  var prop = undefined;
  var props = commonProps.concat();

  eventNormalizers.forEach(function (normalizer) {
    if (type.match(normalizer.reg)) {
      props = props.concat(normalizer.props);
      if (normalizer.fix) {
        fixFns.push(normalizer.fix);
      }
    }
  });

  l = props.length;

  // clone properties of the original event object
  while (l) {
    prop = props[--l];
    this[prop] = nativeEvent[prop];
  }

  // fix target property, if necessary
  if (!this.target && isNative) {
    this.target = nativeEvent.srcElement || document; // srcElement might not be defined either
  }

  // check if target is a text node (safari)
  if (this.target && this.target.nodeType === 3) {
    this.target = this.target.parentNode;
  }

  l = fixFns.length;

  while (l) {
    fixFn = fixFns[--l];
    fixFn(this, nativeEvent);
  }

  this.timeStamp = nativeEvent.timeStamp || Date.now();
}

var EventBaseObjectProto = _EventBaseObject2['default'].prototype;

(0, _objectAssign2['default'])(DomEventObject.prototype, EventBaseObjectProto, {
  constructor: DomEventObject,

  preventDefault: function preventDefault() {
    var e = this.nativeEvent;

    // if preventDefault exists run it on the original event
    if (e.preventDefault) {
      e.preventDefault();
    } else {
      // otherwise set the returnValue property of the original event to FALSE (IE)
      e.returnValue = FALSE;
    }

    EventBaseObjectProto.preventDefault.call(this);
  },

  stopPropagation: function stopPropagation() {
    var e = this.nativeEvent;

    // if stopPropagation exists run it on the original event
    if (e.stopPropagation) {
      e.stopPropagation();
    } else {
      // otherwise set the cancelBubble property of the original event to TRUE (IE)
      e.cancelBubble = TRUE;
    }

    EventBaseObjectProto.stopPropagation.call(this);
  }
});

exports['default'] = DomEventObject;
module.exports = exports['default'];

/***/ }),

/***/ 3858:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
 * @ignore
 * base event object for custom and dom event.
 * @author yiminghe@gmail.com
 */



Object.defineProperty(exports, "__esModule", {
  value: true
});
function returnFalse() {
  return false;
}

function returnTrue() {
  return true;
}

function EventBaseObject() {
  this.timeStamp = Date.now();
  this.target = undefined;
  this.currentTarget = undefined;
}

EventBaseObject.prototype = {
  isEventObject: 1,

  constructor: EventBaseObject,

  isDefaultPrevented: returnFalse,

  isPropagationStopped: returnFalse,

  isImmediatePropagationStopped: returnFalse,

  preventDefault: function preventDefault() {
    this.isDefaultPrevented = returnTrue;
  },

  stopPropagation: function stopPropagation() {
    this.isPropagationStopped = returnTrue;
  },

  stopImmediatePropagation: function stopImmediatePropagation() {
    this.isImmediatePropagationStopped = returnTrue;
    // fixed 1.2
    // call stopPropagation implicitly
    this.stopPropagation();
  },

  halt: function halt(immediate) {
    if (immediate) {
      this.stopImmediatePropagation();
    } else {
      this.stopPropagation();
    }
    this.preventDefault();
  }
};

exports["default"] = EventBaseObject;
module.exports = exports["default"];

/***/ }),

/***/ 3859:
/***/ (function(module, exports, __webpack_require__) {

var __WEBPACK_AMD_DEFINE_ARRAY__, __WEBPACK_AMD_DEFINE_RESULT__;/*!
  Copyright (c) 2017 Jed Watson.
  Licensed under the MIT License (MIT), see
  http://jedwatson.github.io/classnames
*/
/* global define */

(function () {
	'use strict';

	var hasOwn = {}.hasOwnProperty;

	function classNames () {
		var classes = [];

		for (var i = 0; i < arguments.length; i++) {
			var arg = arguments[i];
			if (!arg) continue;

			var argType = typeof arg;

			if (argType === 'string' || argType === 'number') {
				classes.push(arg);
			} else if (Array.isArray(arg) && arg.length) {
				var inner = classNames.apply(null, arg);
				if (inner) {
					classes.push(inner);
				}
			} else if (argType === 'object') {
				for (var key in arg) {
					if (hasOwn.call(arg, key) && arg[key]) {
						classes.push(key);
					}
				}
			}
		}

		return classes.join(' ');
	}

	if (typeof module !== 'undefined' && module.exports) {
		classNames.default = classNames;
		module.exports = classNames;
	} else if (true) {
		// register as 'classnames', consistent with npm package name
		!(__WEBPACK_AMD_DEFINE_ARRAY__ = [], __WEBPACK_AMD_DEFINE_RESULT__ = (function () {
			return classNames;
		}).apply(exports, __WEBPACK_AMD_DEFINE_ARRAY__),
				__WEBPACK_AMD_DEFINE_RESULT__ !== undefined && (module.exports = __WEBPACK_AMD_DEFINE_RESULT__));
	} else {}
}());


/***/ }),

/***/ 3860:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _extends2 = __webpack_require__(20);

var _extends3 = _interopRequireDefault(_extends2);

exports.getOverflowOptions = getOverflowOptions;
exports['default'] = getPlacements;

var _placements = __webpack_require__(3861);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var autoAdjustOverflowEnabled = {
    adjustX: 1,
    adjustY: 1
};
var autoAdjustOverflowDisabled = {
    adjustX: 0,
    adjustY: 0
};
var targetOffset = [0, 0];
function getOverflowOptions(autoAdjustOverflow) {
    if (typeof autoAdjustOverflow === 'boolean') {
        return autoAdjustOverflow ? autoAdjustOverflowEnabled : autoAdjustOverflowDisabled;
    }
    return (0, _extends3['default'])({}, autoAdjustOverflowDisabled, autoAdjustOverflow);
}
function getPlacements() {
    var config = arguments.length > 0 && arguments[0] !== undefined ? arguments[0] : {};
    var _config$arrowWidth = config.arrowWidth,
        arrowWidth = _config$arrowWidth === undefined ? 5 : _config$arrowWidth,
        _config$horizontalArr = config.horizontalArrowShift,
        horizontalArrowShift = _config$horizontalArr === undefined ? 16 : _config$horizontalArr,
        _config$verticalArrow = config.verticalArrowShift,
        verticalArrowShift = _config$verticalArrow === undefined ? 12 : _config$verticalArrow,
        _config$autoAdjustOve = config.autoAdjustOverflow,
        autoAdjustOverflow = _config$autoAdjustOve === undefined ? true : _config$autoAdjustOve;

    var placementMap = {
        left: {
            points: ['cr', 'cl'],
            offset: [-4, 0]
        },
        right: {
            points: ['cl', 'cr'],
            offset: [4, 0]
        },
        top: {
            points: ['bc', 'tc'],
            offset: [0, -4]
        },
        bottom: {
            points: ['tc', 'bc'],
            offset: [0, 4]
        },
        topLeft: {
            points: ['bl', 'tc'],
            offset: [-(horizontalArrowShift + arrowWidth), -4]
        },
        leftTop: {
            points: ['tr', 'cl'],
            offset: [-4, -(verticalArrowShift + arrowWidth)]
        },
        topRight: {
            points: ['br', 'tc'],
            offset: [horizontalArrowShift + arrowWidth, -4]
        },
        rightTop: {
            points: ['tl', 'cr'],
            offset: [4, -(verticalArrowShift + arrowWidth)]
        },
        bottomRight: {
            points: ['tr', 'bc'],
            offset: [horizontalArrowShift + arrowWidth, 4]
        },
        rightBottom: {
            points: ['bl', 'cr'],
            offset: [4, verticalArrowShift + arrowWidth]
        },
        bottomLeft: {
            points: ['tl', 'bc'],
            offset: [-(horizontalArrowShift + arrowWidth), 4]
        },
        leftBottom: {
            points: ['br', 'cl'],
            offset: [-4, verticalArrowShift + arrowWidth]
        }
    };
    Object.keys(placementMap).forEach(function (key) {
        placementMap[key] = config.arrowPointAtCenter ? (0, _extends3['default'])({}, placementMap[key], { overflow: getOverflowOptions(autoAdjustOverflow), targetOffset: targetOffset }) : (0, _extends3['default'])({}, _placements.placements[key], { overflow: getOverflowOptions(autoAdjustOverflow) });
    });
    return placementMap;
}

/***/ }),

/***/ 3861:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


exports.__esModule = true;
var autoAdjustOverflow = {
  adjustX: 1,
  adjustY: 1
};

var targetOffset = [0, 0];

var placements = exports.placements = {
  left: {
    points: ['cr', 'cl'],
    overflow: autoAdjustOverflow,
    offset: [-4, 0],
    targetOffset: targetOffset
  },
  right: {
    points: ['cl', 'cr'],
    overflow: autoAdjustOverflow,
    offset: [4, 0],
    targetOffset: targetOffset
  },
  top: {
    points: ['bc', 'tc'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  bottom: {
    points: ['tc', 'bc'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  topLeft: {
    points: ['bl', 'tl'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  leftTop: {
    points: ['tr', 'tl'],
    overflow: autoAdjustOverflow,
    offset: [-4, 0],
    targetOffset: targetOffset
  },
  topRight: {
    points: ['br', 'tr'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  rightTop: {
    points: ['tl', 'tr'],
    overflow: autoAdjustOverflow,
    offset: [4, 0],
    targetOffset: targetOffset
  },
  bottomRight: {
    points: ['tr', 'br'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  rightBottom: {
    points: ['bl', 'br'],
    overflow: autoAdjustOverflow,
    offset: [4, 0],
    targetOffset: targetOffset
  },
  bottomLeft: {
    points: ['tl', 'bl'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  leftBottom: {
    points: ['br', 'bl'],
    overflow: autoAdjustOverflow,
    offset: [-4, 0],
    targetOffset: targetOffset
  }
};

exports['default'] = placements;

/***/ }),

/***/ 3862:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
    value: true
});

var _warning = __webpack_require__(3863);

var _warning2 = _interopRequireDefault(_warning);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { 'default': obj }; }

var warned = {};

exports['default'] = function (valid, message) {
    if (!valid && !warned[message]) {
        (0, _warning2['default'])(false, message);
        warned[message] = true;
    }
};

module.exports = exports['default'];

/***/ }),

/***/ 3863:
/***/ (function(module, exports, __webpack_require__) {

"use strict";
/**
 * Copyright (c) 2014-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */



/**
 * Similar to invariant but only logs a warning if the condition is not met.
 * This can be used to log issues in development environments in critical
 * paths. Removing the logging code for production environments will keep the
 * same logic and follow the same code paths.
 */

var __DEV__ = "production" !== 'production';

var warning = function() {};

if (__DEV__) {
  var printWarning = function printWarning(format, args) {
    var len = arguments.length;
    args = new Array(len > 2 ? len - 2 : 0);
    for (var key = 2; key < len; key++) {
      args[key - 2] = arguments[key];
    }
    var argIndex = 0;
    var message = 'Warning: ' +
      format.replace(/%s/g, function() {
        return args[argIndex++];
      });
    if (typeof console !== 'undefined') {
      console.error(message);
    }
    try {
      // --- Welcome to debugging React ---
      // This error was thrown as a convenience so that you can use this stack
      // to find the callsite that caused this warning to fire.
      throw new Error(message);
    } catch (x) {}
  }

  warning = function(condition, format, args) {
    var len = arguments.length;
    args = new Array(len > 2 ? len - 2 : 0);
    for (var key = 2; key < len; key++) {
      args[key - 2] = arguments[key];
    }
    if (format === undefined) {
      throw new Error(
          '`warning(condition, format, ...args)` requires a warning ' +
          'message argument'
      );
    }
    if (!condition) {
      printWarning.apply(null, [format].concat(args));
    }
  };
}

module.exports = warning;


/***/ }),

/***/ 3864:
/***/ (function(module, exports, __webpack_require__) {

// extracted by mini-css-extract-plugin

/***/ }),

/***/ 3865:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(20);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M17 15.59V14a1 1 0 0 1 2 0v5h-5a1 1 0 0 1 0-2h1.59l-2.62-2.62a1 1 0 0 1 1.41-1.41L17 15.59zM8.41 7l2.54 2.54a1 1 0 0 1-1.41 1.41L7 8.41V10a1 1 0 1 1-2 0V5h5a1 1 0 1 1 0 2H8.41z", fillRule: "evenodd" })
  );
};

/***/ }),

/***/ 3866:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(20);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "24", height: "24", viewBox: "0 0 24 24", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M16.5 7H19a1 1 0 0 1 0 2h-1v8.95c0 1.13-1 2.05-2.25 2.05h-7.5C7.01 20 6 19.08 6 17.95V9H5a1 1 0 1 1 0-2h11.5zM16 9H8v8.79c0 .03.17.21.5.21h7c.33 0 .5-.18.5-.21V9zM9 4h6a1 1 0 0 1 0 2H9a1 1 0 1 1 0-2zm1.25 7c.41 0 .75.34.75.75v3.5a.75.75 0 1 1-1.5 0v-3.5c0-.41.34-.75.75-.75zm3.5 0c.41 0 .75.34.75.75v3.5a.75.75 0 1 1-1.5 0v-3.5c0-.41.34-.75.75-.75z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3867:
/***/ (function(module, exports, __webpack_require__) {

"use strict";


Object.defineProperty(exports, "__esModule", {
  value: true
});

var _extends2 = __webpack_require__(20);

var _extends3 = _interopRequireDefault(_extends2);

var _react = __webpack_require__(1);

var _react2 = _interopRequireDefault(_react);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _objectWithoutProperties(obj, keys) {
  var target = {};for (var i in obj) {
    if (keys.indexOf(i) >= 0) continue;if (!Object.prototype.hasOwnProperty.call(obj, i)) continue;target[i] = obj[i];
  }return target;
}

exports.default = function (_ref) {
  var _ref$styles = _ref.styles,
      styles = _ref$styles === undefined ? {} : _ref$styles,
      props = _objectWithoutProperties(_ref, ["styles"]);

  return _react2.default.createElement(
    "svg",
    (0, _extends3.default)({ width: "28", height: "28", viewBox: "0 0 28 28", xmlns: "http://www.w3.org/2000/svg" }, props),
    _react2.default.createElement("path", { d: "M14 0a14 14 0 1 1 0 28 14 14 0 0 1 0-28zm0 1.5a12.5 12.5 0 1 0 0 25 12.5 12.5 0 0 0 0-25zM10 10h8a1 1 0 0 1 0 2h-8a1 1 0 0 1 0-2zm0 6h8a1 1 0 0 1 0 2h-8a1 1 0 0 1 0-2z", fillRule: "nonzero" })
  );
};

/***/ }),

/***/ 3869:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);

// EXTERNAL MODULE: ./node_modules/babel-runtime/helpers/extends.js
var helpers_extends = __webpack_require__(20);
var extends_default = /*#__PURE__*/__webpack_require__.n(helpers_extends);

// EXTERNAL MODULE: ./node_modules/babel-runtime/helpers/objectWithoutProperties.js
var objectWithoutProperties = __webpack_require__(38);
var objectWithoutProperties_default = /*#__PURE__*/__webpack_require__.n(objectWithoutProperties);

// EXTERNAL MODULE: ./node_modules/babel-runtime/helpers/classCallCheck.js
var classCallCheck = __webpack_require__(6);
var classCallCheck_default = /*#__PURE__*/__webpack_require__.n(classCallCheck);

// EXTERNAL MODULE: ./node_modules/babel-runtime/helpers/possibleConstructorReturn.js
var possibleConstructorReturn = __webpack_require__(10);
var possibleConstructorReturn_default = /*#__PURE__*/__webpack_require__.n(possibleConstructorReturn);

// EXTERNAL MODULE: ./node_modules/babel-runtime/helpers/inherits.js
var inherits = __webpack_require__(11);
var inherits_default = /*#__PURE__*/__webpack_require__.n(inherits);

// EXTERNAL MODULE: ./node_modules/react/index.js
var react = __webpack_require__(1);
var react_default = /*#__PURE__*/__webpack_require__.n(react);

// EXTERNAL MODULE: ./node_modules/prop-types/index.js
var prop_types = __webpack_require__(2);
var prop_types_default = /*#__PURE__*/__webpack_require__.n(prop_types);

// EXTERNAL MODULE: ./node_modules/react-dom/index.js
var react_dom = __webpack_require__(47);
var react_dom_default = /*#__PURE__*/__webpack_require__.n(react_dom);

// CONCATENATED MODULE: ./node_modules/rc-util/es/Dom/contains.js
function contains(root, n) {
  var node = n;
  while (node) {
    if (node === root) {
      return true;
    }
    node = node.parentNode;
  }

  return false;
}
// EXTERNAL MODULE: ./node_modules/add-dom-event-listener/lib/index.js
var lib = __webpack_require__(3856);
var lib_default = /*#__PURE__*/__webpack_require__.n(lib);

// CONCATENATED MODULE: ./node_modules/rc-util/es/Dom/addEventListener.js



function addEventListenerWrap(target, eventType, cb, option) {
  /* eslint camelcase: 2 */
  var callback = react_dom_default.a.unstable_batchedUpdates ? function run(e) {
    react_dom_default.a.unstable_batchedUpdates(cb, e);
  } : cb;
  return lib_default()(target, eventType, callback, option);
}
// EXTERNAL MODULE: ./node_modules/babel-runtime/helpers/createClass.js
var createClass = __webpack_require__(7);
var createClass_default = /*#__PURE__*/__webpack_require__.n(createClass);

// CONCATENATED MODULE: ./node_modules/rc-util/es/ContainerRender.js








var ContainerRender_ContainerRender = function (_React$Component) {
  inherits_default()(ContainerRender, _React$Component);

  function ContainerRender() {
    var _ref;

    var _temp, _this, _ret;

    classCallCheck_default()(this, ContainerRender);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = possibleConstructorReturn_default()(this, (_ref = ContainerRender.__proto__ || Object.getPrototypeOf(ContainerRender)).call.apply(_ref, [this].concat(args))), _this), _this.removeContainer = function () {
      if (_this.container) {
        react_dom_default.a.unmountComponentAtNode(_this.container);
        _this.container.parentNode.removeChild(_this.container);
        _this.container = null;
      }
    }, _this.renderComponent = function (props, ready) {
      var _this$props = _this.props,
          visible = _this$props.visible,
          getComponent = _this$props.getComponent,
          forceRender = _this$props.forceRender,
          getContainer = _this$props.getContainer,
          parent = _this$props.parent;

      if (visible || parent._component || forceRender) {
        if (!_this.container) {
          _this.container = getContainer();
        }
        react_dom_default.a.unstable_renderSubtreeIntoContainer(parent, getComponent(props), _this.container, function callback() {
          if (ready) {
            ready.call(this);
          }
        });
      }
    }, _temp), possibleConstructorReturn_default()(_this, _ret);
  }

  createClass_default()(ContainerRender, [{
    key: 'componentDidMount',
    value: function componentDidMount() {
      if (this.props.autoMount) {
        this.renderComponent();
      }
    }
  }, {
    key: 'componentDidUpdate',
    value: function componentDidUpdate() {
      if (this.props.autoMount) {
        this.renderComponent();
      }
    }
  }, {
    key: 'componentWillUnmount',
    value: function componentWillUnmount() {
      if (this.props.autoDestroy) {
        this.removeContainer();
      }
    }
  }, {
    key: 'render',
    value: function render() {
      return this.props.children({
        renderComponent: this.renderComponent,
        removeContainer: this.removeContainer
      });
    }
  }]);

  return ContainerRender;
}(react_default.a.Component);

ContainerRender_ContainerRender.propTypes = {
  autoMount: prop_types_default.a.bool,
  autoDestroy: prop_types_default.a.bool,
  visible: prop_types_default.a.bool,
  forceRender: prop_types_default.a.bool,
  parent: prop_types_default.a.any,
  getComponent: prop_types_default.a.func.isRequired,
  getContainer: prop_types_default.a.func.isRequired,
  children: prop_types_default.a.func.isRequired
};
ContainerRender_ContainerRender.defaultProps = {
  autoMount: true,
  autoDestroy: true,
  forceRender: false
};
/* harmony default export */ var es_ContainerRender = (ContainerRender_ContainerRender);
// CONCATENATED MODULE: ./node_modules/rc-util/es/Portal.js








var Portal_Portal = function (_React$Component) {
  inherits_default()(Portal, _React$Component);

  function Portal() {
    classCallCheck_default()(this, Portal);

    return possibleConstructorReturn_default()(this, (Portal.__proto__ || Object.getPrototypeOf(Portal)).apply(this, arguments));
  }

  createClass_default()(Portal, [{
    key: 'componentDidMount',
    value: function componentDidMount() {
      this.createContainer();
    }
  }, {
    key: 'componentDidUpdate',
    value: function componentDidUpdate(prevProps) {
      var didUpdate = this.props.didUpdate;

      if (didUpdate) {
        didUpdate(prevProps);
      }
    }
  }, {
    key: 'componentWillUnmount',
    value: function componentWillUnmount() {
      this.removeContainer();
    }
  }, {
    key: 'createContainer',
    value: function createContainer() {
      this._container = this.props.getContainer();
      this.forceUpdate();
    }
  }, {
    key: 'removeContainer',
    value: function removeContainer() {
      if (this._container) {
        this._container.parentNode.removeChild(this._container);
      }
    }
  }, {
    key: 'render',
    value: function render() {
      if (this._container) {
        return react_dom_default.a.createPortal(this.props.children, this._container);
      }
      return null;
    }
  }]);

  return Portal;
}(react_default.a.Component);

Portal_Portal.propTypes = {
  getContainer: prop_types_default.a.func.isRequired,
  children: prop_types_default.a.node.isRequired,
  didUpdate: prop_types_default.a.func
};
/* harmony default export */ var es_Portal = (Portal_Portal);
// EXTERNAL MODULE: ./node_modules/rc-trigger/node_modules/classnames/index.js
var classnames = __webpack_require__(3859);
var classnames_default = /*#__PURE__*/__webpack_require__.n(classnames);

// CONCATENATED MODULE: ./node_modules/rc-trigger/es/utils.js

function isPointsEq(a1, a2, isAlignPoint) {
  if (isAlignPoint) {
    return a1[0] === a2[0];
  }
  return a1[0] === a2[0] && a1[1] === a2[1];
}

function getAlignFromPlacement(builtinPlacements, placementStr, align) {
  var baseAlign = builtinPlacements[placementStr] || {};
  return extends_default()({}, baseAlign, align);
}

function getAlignPopupClassName(builtinPlacements, prefixCls, align, isAlignPoint) {
  var points = align.points;
  for (var placement in builtinPlacements) {
    if (builtinPlacements.hasOwnProperty(placement)) {
      if (isPointsEq(builtinPlacements[placement].points, points, isAlignPoint)) {
        return prefixCls + '-placement-' + placement;
      }
    }
  }
  return '';
}

function saveRef(name, component) {
  this[name] = component;
}
// EXTERNAL MODULE: ./node_modules/dom-align/es/index.js + 12 modules
var es = __webpack_require__(2254);

// CONCATENATED MODULE: ./node_modules/rc-align/es/util.js
function buffer(fn, ms) {
  var timer = void 0;

  function clear() {
    if (timer) {
      clearTimeout(timer);
      timer = null;
    }
  }

  function bufferFn() {
    clear();
    timer = setTimeout(fn, ms);
  }

  bufferFn.clear = clear;

  return bufferFn;
}

function isSamePoint(prev, next) {
  if (prev === next) return true;
  if (!prev || !next) return false;

  if ('pageX' in next && 'pageY' in next) {
    return prev.pageX === next.pageX && prev.pageY === next.pageY;
  }

  if ('clientX' in next && 'clientY' in next) {
    return prev.clientX === next.clientX && prev.clientY === next.clientY;
  }

  return false;
}

function isWindow(obj) {
  return obj && typeof obj === 'object' && obj.window === obj;
}
// CONCATENATED MODULE: ./node_modules/rc-align/es/Align.js











function getElement(func) {
  if (typeof func !== 'function' || !func) return null;
  return func();
}

function getPoint(point) {
  if (typeof point !== 'object' || !point) return null;
  return point;
}

var Align_Align = function (_Component) {
  inherits_default()(Align, _Component);

  function Align() {
    var _temp, _this, _ret;

    classCallCheck_default()(this, Align);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = possibleConstructorReturn_default()(this, _Component.call.apply(_Component, [this].concat(args))), _this), _this.forceAlign = function () {
      var _this$props = _this.props,
          disabled = _this$props.disabled,
          target = _this$props.target,
          align = _this$props.align,
          onAlign = _this$props.onAlign;

      if (!disabled && target) {
        var source = react_dom_default.a.findDOMNode(_this);

        var result = void 0;
        var element = getElement(target);
        var point = getPoint(target);

        if (element) {
          result = Object(es["alignElement"])(source, element, align);
        } else if (point) {
          result = Object(es["alignPoint"])(source, point, align);
        }

        if (onAlign) {
          onAlign(source, result);
        }
      }
    }, _temp), possibleConstructorReturn_default()(_this, _ret);
  }

  Align.prototype.componentDidMount = function componentDidMount() {
    var props = this.props;
    // if parent ref not attached .... use document.getElementById
    this.forceAlign();
    if (!props.disabled && props.monitorWindowResize) {
      this.startMonitorWindowResize();
    }
  };

  Align.prototype.componentDidUpdate = function componentDidUpdate(prevProps) {
    var reAlign = false;
    var props = this.props;

    if (!props.disabled) {
      var source = react_dom_default.a.findDOMNode(this);
      var sourceRect = source ? source.getBoundingClientRect() : null;

      if (prevProps.disabled) {
        reAlign = true;
      } else {
        var lastElement = getElement(prevProps.target);
        var currentElement = getElement(props.target);
        var lastPoint = getPoint(prevProps.target);
        var currentPoint = getPoint(props.target);

        if (isWindow(lastElement) && isWindow(currentElement)) {
          // Skip if is window
          reAlign = false;
        } else if (lastElement !== currentElement || // Element change
        lastElement && !currentElement && currentPoint || // Change from element to point
        lastPoint && currentPoint && currentElement || // Change from point to element
        currentPoint && !isSamePoint(lastPoint, currentPoint)) {
          reAlign = true;
        }

        // If source element size changed
        var preRect = this.sourceRect || {};
        if (!reAlign && source && (preRect.width !== sourceRect.width || preRect.height !== sourceRect.height)) {
          reAlign = true;
        }
      }

      this.sourceRect = sourceRect;
    }

    if (reAlign) {
      this.forceAlign();
    }

    if (props.monitorWindowResize && !props.disabled) {
      this.startMonitorWindowResize();
    } else {
      this.stopMonitorWindowResize();
    }
  };

  Align.prototype.componentWillUnmount = function componentWillUnmount() {
    this.stopMonitorWindowResize();
  };

  Align.prototype.startMonitorWindowResize = function startMonitorWindowResize() {
    if (!this.resizeHandler) {
      this.bufferMonitor = buffer(this.forceAlign, this.props.monitorBufferTime);
      this.resizeHandler = addEventListenerWrap(window, 'resize', this.bufferMonitor);
    }
  };

  Align.prototype.stopMonitorWindowResize = function stopMonitorWindowResize() {
    if (this.resizeHandler) {
      this.bufferMonitor.clear();
      this.resizeHandler.remove();
      this.resizeHandler = null;
    }
  };

  Align.prototype.render = function render() {
    var _this2 = this;

    var _props = this.props,
        childrenProps = _props.childrenProps,
        children = _props.children;

    var child = react_default.a.Children.only(children);
    if (childrenProps) {
      var newProps = {};
      var propList = Object.keys(childrenProps);
      propList.forEach(function (prop) {
        newProps[prop] = _this2.props[childrenProps[prop]];
      });

      return react_default.a.cloneElement(child, newProps);
    }
    return child;
  };

  return Align;
}(react["Component"]);

Align_Align.propTypes = {
  childrenProps: prop_types_default.a.object,
  align: prop_types_default.a.object.isRequired,
  target: prop_types_default.a.oneOfType([prop_types_default.a.func, prop_types_default.a.shape({
    clientX: prop_types_default.a.number,
    clientY: prop_types_default.a.number,
    pageX: prop_types_default.a.number,
    pageY: prop_types_default.a.number
  })]),
  onAlign: prop_types_default.a.func,
  monitorBufferTime: prop_types_default.a.number,
  monitorWindowResize: prop_types_default.a.bool,
  disabled: prop_types_default.a.bool,
  children: prop_types_default.a.any
};
Align_Align.defaultProps = {
  target: function target() {
    return window;
  },
  monitorBufferTime: 50,
  monitorWindowResize: false,
  disabled: false
};


/* harmony default export */ var es_Align = (Align_Align);
// CONCATENATED MODULE: ./node_modules/rc-align/es/index.js
// export this package's api


/* harmony default export */ var rc_align_es = (es_Align);
// EXTERNAL MODULE: ./node_modules/rc-animate/es/Animate.js + 5 modules
var Animate = __webpack_require__(339);

// CONCATENATED MODULE: ./node_modules/rc-trigger/es/LazyRenderBox.js







var LazyRenderBox_LazyRenderBox = function (_Component) {
  inherits_default()(LazyRenderBox, _Component);

  function LazyRenderBox() {
    classCallCheck_default()(this, LazyRenderBox);

    return possibleConstructorReturn_default()(this, _Component.apply(this, arguments));
  }

  LazyRenderBox.prototype.shouldComponentUpdate = function shouldComponentUpdate(nextProps) {
    return nextProps.hiddenClassName || nextProps.visible;
  };

  LazyRenderBox.prototype.render = function render() {
    var _props = this.props,
        hiddenClassName = _props.hiddenClassName,
        visible = _props.visible,
        props = objectWithoutProperties_default()(_props, ['hiddenClassName', 'visible']);

    if (hiddenClassName || react_default.a.Children.count(props.children) > 1) {
      if (!visible && hiddenClassName) {
        props.className += ' ' + hiddenClassName;
      }
      return react_default.a.createElement('div', props);
    }

    return react_default.a.Children.only(props.children);
  };

  return LazyRenderBox;
}(react["Component"]);

LazyRenderBox_LazyRenderBox.propTypes = {
  children: prop_types_default.a.any,
  className: prop_types_default.a.string,
  visible: prop_types_default.a.bool,
  hiddenClassName: prop_types_default.a.string
};


/* harmony default export */ var es_LazyRenderBox = (LazyRenderBox_LazyRenderBox);
// CONCATENATED MODULE: ./node_modules/rc-trigger/es/PopupInner.js







var PopupInner_PopupInner = function (_Component) {
  inherits_default()(PopupInner, _Component);

  function PopupInner() {
    classCallCheck_default()(this, PopupInner);

    return possibleConstructorReturn_default()(this, _Component.apply(this, arguments));
  }

  PopupInner.prototype.render = function render() {
    var props = this.props;
    var className = props.className;
    if (!props.visible) {
      className += ' ' + props.hiddenClassName;
    }
    return react_default.a.createElement(
      'div',
      {
        className: className,
        onMouseEnter: props.onMouseEnter,
        onMouseLeave: props.onMouseLeave,
        onMouseDown: props.onMouseDown,
        onTouchStart: props.onTouchStart,
        style: props.style
      },
      react_default.a.createElement(
        es_LazyRenderBox,
        { className: props.prefixCls + '-content', visible: props.visible },
        props.children
      )
    );
  };

  return PopupInner;
}(react["Component"]);

PopupInner_PopupInner.propTypes = {
  hiddenClassName: prop_types_default.a.string,
  className: prop_types_default.a.string,
  prefixCls: prop_types_default.a.string,
  onMouseEnter: prop_types_default.a.func,
  onMouseLeave: prop_types_default.a.func,
  onMouseDown: prop_types_default.a.func,
  onTouchStart: prop_types_default.a.func,
  children: prop_types_default.a.any
};


/* harmony default export */ var es_PopupInner = (PopupInner_PopupInner);
// CONCATENATED MODULE: ./node_modules/rc-trigger/es/Popup.js













var Popup_Popup = function (_Component) {
  inherits_default()(Popup, _Component);

  function Popup(props) {
    classCallCheck_default()(this, Popup);

    var _this = possibleConstructorReturn_default()(this, _Component.call(this, props));

    Popup_initialiseProps.call(_this);

    _this.state = {
      // Used for stretch
      stretchChecked: false,
      targetWidth: undefined,
      targetHeight: undefined
    };

    _this.savePopupRef = saveRef.bind(_this, 'popupInstance');
    _this.saveAlignRef = saveRef.bind(_this, 'alignInstance');
    return _this;
  }

  Popup.prototype.componentDidMount = function componentDidMount() {
    this.rootNode = this.getPopupDomNode();
    this.setStretchSize();
  };

  Popup.prototype.componentDidUpdate = function componentDidUpdate() {
    this.setStretchSize();
  };

  // Record size if stretch needed


  Popup.prototype.getPopupDomNode = function getPopupDomNode() {
    return react_dom_default.a.findDOMNode(this.popupInstance);
  };

  // `target` on `rc-align` can accept as a function to get the bind element or a point.
  // ref: https://www.npmjs.com/package/rc-align


  Popup.prototype.getMaskTransitionName = function getMaskTransitionName() {
    var props = this.props;
    var transitionName = props.maskTransitionName;
    var animation = props.maskAnimation;
    if (!transitionName && animation) {
      transitionName = props.prefixCls + '-' + animation;
    }
    return transitionName;
  };

  Popup.prototype.getTransitionName = function getTransitionName() {
    var props = this.props;
    var transitionName = props.transitionName;
    if (!transitionName && props.animation) {
      transitionName = props.prefixCls + '-' + props.animation;
    }
    return transitionName;
  };

  Popup.prototype.getClassName = function getClassName(currentAlignClassName) {
    return this.props.prefixCls + ' ' + this.props.className + ' ' + currentAlignClassName;
  };

  Popup.prototype.getPopupElement = function getPopupElement() {
    var _this2 = this;

    var savePopupRef = this.savePopupRef;
    var _state = this.state,
        stretchChecked = _state.stretchChecked,
        targetHeight = _state.targetHeight,
        targetWidth = _state.targetWidth;
    var _props = this.props,
        align = _props.align,
        visible = _props.visible,
        prefixCls = _props.prefixCls,
        style = _props.style,
        getClassNameFromAlign = _props.getClassNameFromAlign,
        destroyPopupOnHide = _props.destroyPopupOnHide,
        stretch = _props.stretch,
        children = _props.children,
        onMouseEnter = _props.onMouseEnter,
        onMouseLeave = _props.onMouseLeave,
        onMouseDown = _props.onMouseDown,
        onTouchStart = _props.onTouchStart;

    var className = this.getClassName(this.currentAlignClassName || getClassNameFromAlign(align));
    var hiddenClassName = prefixCls + '-hidden';

    if (!visible) {
      this.currentAlignClassName = null;
    }

    var sizeStyle = {};
    if (stretch) {
      // Stretch with target
      if (stretch.indexOf('height') !== -1) {
        sizeStyle.height = targetHeight;
      } else if (stretch.indexOf('minHeight') !== -1) {
        sizeStyle.minHeight = targetHeight;
      }
      if (stretch.indexOf('width') !== -1) {
        sizeStyle.width = targetWidth;
      } else if (stretch.indexOf('minWidth') !== -1) {
        sizeStyle.minWidth = targetWidth;
      }

      // Delay force align to makes ui smooth
      if (!stretchChecked) {
        sizeStyle.visibility = 'hidden';
        setTimeout(function () {
          if (_this2.alignInstance) {
            _this2.alignInstance.forceAlign();
          }
        }, 0);
      }
    }

    var newStyle = extends_default()({}, sizeStyle, style, this.getZIndexStyle());

    var popupInnerProps = {
      className: className,
      prefixCls: prefixCls,
      ref: savePopupRef,
      onMouseEnter: onMouseEnter,
      onMouseLeave: onMouseLeave,
      onMouseDown: onMouseDown,
      onTouchStart: onTouchStart,
      style: newStyle
    };
    if (destroyPopupOnHide) {
      return react_default.a.createElement(
        Animate["a" /* default */],
        {
          component: '',
          exclusive: true,
          transitionAppear: true,
          transitionName: this.getTransitionName()
        },
        visible ? react_default.a.createElement(
          rc_align_es,
          {
            target: this.getAlignTarget(),
            key: 'popup',
            ref: this.saveAlignRef,
            monitorWindowResize: true,
            align: align,
            onAlign: this.onAlign
          },
          react_default.a.createElement(
            es_PopupInner,
            extends_default()({
              visible: true
            }, popupInnerProps),
            children
          )
        ) : null
      );
    }

    return react_default.a.createElement(
      Animate["a" /* default */],
      {
        component: '',
        exclusive: true,
        transitionAppear: true,
        transitionName: this.getTransitionName(),
        showProp: 'xVisible'
      },
      react_default.a.createElement(
        rc_align_es,
        {
          target: this.getAlignTarget(),
          key: 'popup',
          ref: this.saveAlignRef,
          monitorWindowResize: true,
          xVisible: visible,
          childrenProps: { visible: 'xVisible' },
          disabled: !visible,
          align: align,
          onAlign: this.onAlign
        },
        react_default.a.createElement(
          es_PopupInner,
          extends_default()({
            hiddenClassName: hiddenClassName
          }, popupInnerProps),
          children
        )
      )
    );
  };

  Popup.prototype.getZIndexStyle = function getZIndexStyle() {
    var style = {};
    var props = this.props;
    if (props.zIndex !== undefined) {
      style.zIndex = props.zIndex;
    }
    return style;
  };

  Popup.prototype.getMaskElement = function getMaskElement() {
    var props = this.props;
    var maskElement = void 0;
    if (props.mask) {
      var maskTransition = this.getMaskTransitionName();
      maskElement = react_default.a.createElement(es_LazyRenderBox, {
        style: this.getZIndexStyle(),
        key: 'mask',
        className: props.prefixCls + '-mask',
        hiddenClassName: props.prefixCls + '-mask-hidden',
        visible: props.visible
      });
      if (maskTransition) {
        maskElement = react_default.a.createElement(
          Animate["a" /* default */],
          {
            key: 'mask',
            showProp: 'visible',
            transitionAppear: true,
            component: '',
            transitionName: maskTransition
          },
          maskElement
        );
      }
    }
    return maskElement;
  };

  Popup.prototype.render = function render() {
    return react_default.a.createElement(
      'div',
      null,
      this.getMaskElement(),
      this.getPopupElement()
    );
  };

  return Popup;
}(react["Component"]);

Popup_Popup.propTypes = {
  visible: prop_types_default.a.bool,
  style: prop_types_default.a.object,
  getClassNameFromAlign: prop_types_default.a.func,
  onAlign: prop_types_default.a.func,
  getRootDomNode: prop_types_default.a.func,
  align: prop_types_default.a.any,
  destroyPopupOnHide: prop_types_default.a.bool,
  className: prop_types_default.a.string,
  prefixCls: prop_types_default.a.string,
  onMouseEnter: prop_types_default.a.func,
  onMouseLeave: prop_types_default.a.func,
  onMouseDown: prop_types_default.a.func,
  onTouchStart: prop_types_default.a.func,
  stretch: prop_types_default.a.string,
  children: prop_types_default.a.node,
  point: prop_types_default.a.shape({
    pageX: prop_types_default.a.number,
    pageY: prop_types_default.a.number
  })
};

var Popup_initialiseProps = function _initialiseProps() {
  var _this3 = this;

  this.onAlign = function (popupDomNode, align) {
    var props = _this3.props;
    var currentAlignClassName = props.getClassNameFromAlign(align);
    // FIX: https://github.com/react-component/trigger/issues/56
    // FIX: https://github.com/react-component/tooltip/issues/79
    if (_this3.currentAlignClassName !== currentAlignClassName) {
      _this3.currentAlignClassName = currentAlignClassName;
      popupDomNode.className = _this3.getClassName(currentAlignClassName);
    }
    props.onAlign(popupDomNode, align);
  };

  this.setStretchSize = function () {
    var _props2 = _this3.props,
        stretch = _props2.stretch,
        getRootDomNode = _props2.getRootDomNode,
        visible = _props2.visible;
    var _state2 = _this3.state,
        stretchChecked = _state2.stretchChecked,
        targetHeight = _state2.targetHeight,
        targetWidth = _state2.targetWidth;


    if (!stretch || !visible) {
      if (stretchChecked) {
        _this3.setState({ stretchChecked: false });
      }
      return;
    }

    var $ele = getRootDomNode();
    if (!$ele) return;

    var height = $ele.offsetHeight;
    var width = $ele.offsetWidth;

    if (targetHeight !== height || targetWidth !== width || !stretchChecked) {
      _this3.setState({
        stretchChecked: true,
        targetHeight: height,
        targetWidth: width
      });
    }
  };

  this.getTargetElement = function () {
    return _this3.props.getRootDomNode();
  };

  this.getAlignTarget = function () {
    var point = _this3.props.point;

    if (point) {
      return point;
    }
    return _this3.getTargetElement;
  };
};

/* harmony default export */ var es_Popup = (Popup_Popup);
// CONCATENATED MODULE: ./node_modules/rc-trigger/es/index.js
















function noop() {}

function returnEmptyString() {
  return '';
}

function returnDocument() {
  return window.document;
}

var ALL_HANDLERS = ['onClick', 'onMouseDown', 'onTouchStart', 'onMouseEnter', 'onMouseLeave', 'onFocus', 'onBlur', 'onContextMenu'];

var IS_REACT_16 = !!react_dom["createPortal"];

var contextTypes = {
  rcTrigger: prop_types_default.a.shape({
    onPopupMouseDown: prop_types_default.a.func
  })
};

var es_Trigger = function (_React$Component) {
  inherits_default()(Trigger, _React$Component);

  function Trigger(props) {
    classCallCheck_default()(this, Trigger);

    var _this = possibleConstructorReturn_default()(this, _React$Component.call(this, props));

    es_initialiseProps.call(_this);

    var popupVisible = void 0;
    if ('popupVisible' in props) {
      popupVisible = !!props.popupVisible;
    } else {
      popupVisible = !!props.defaultPopupVisible;
    }

    _this.prevPopupVisible = popupVisible;

    _this.state = {
      popupVisible: popupVisible
    };
    return _this;
  }

  Trigger.prototype.getChildContext = function getChildContext() {
    return {
      rcTrigger: {
        onPopupMouseDown: this.onPopupMouseDown
      }
    };
  };

  Trigger.prototype.componentWillMount = function componentWillMount() {
    var _this2 = this;

    ALL_HANDLERS.forEach(function (h) {
      _this2['fire' + h] = function (e) {
        _this2.fireEvents(h, e);
      };
    });
  };

  Trigger.prototype.componentDidMount = function componentDidMount() {
    this.componentDidUpdate({}, {
      popupVisible: this.state.popupVisible
    });
  };

  Trigger.prototype.componentWillReceiveProps = function componentWillReceiveProps(_ref) {
    var popupVisible = _ref.popupVisible;

    if (popupVisible !== undefined) {
      this.setState({
        popupVisible: popupVisible
      });
    }
  };

  Trigger.prototype.componentDidUpdate = function componentDidUpdate(_, prevState) {
    var props = this.props;
    var state = this.state;
    var triggerAfterPopupVisibleChange = function triggerAfterPopupVisibleChange() {
      if (prevState.popupVisible !== state.popupVisible) {
        props.afterPopupVisibleChange(state.popupVisible);
      }
    };
    if (!IS_REACT_16) {
      this.renderComponent(null, triggerAfterPopupVisibleChange);
    }

    this.prevPopupVisible = prevState.popupVisible;

    // We must listen to `mousedown` or `touchstart`, edge case:
    // https://github.com/ant-design/ant-design/issues/5804
    // https://github.com/react-component/calendar/issues/250
    // https://github.com/react-component/trigger/issues/50
    if (state.popupVisible) {
      var currentDocument = void 0;
      if (!this.clickOutsideHandler && (this.isClickToHide() || this.isContextMenuToShow())) {
        currentDocument = props.getDocument();
        this.clickOutsideHandler = addEventListenerWrap(currentDocument, 'mousedown', this.onDocumentClick);
      }
      // always hide on mobile
      if (!this.touchOutsideHandler) {
        currentDocument = currentDocument || props.getDocument();
        this.touchOutsideHandler = addEventListenerWrap(currentDocument, 'touchstart', this.onDocumentClick);
      }
      // close popup when trigger type contains 'onContextMenu' and document is scrolling.
      if (!this.contextMenuOutsideHandler1 && this.isContextMenuToShow()) {
        currentDocument = currentDocument || props.getDocument();
        this.contextMenuOutsideHandler1 = addEventListenerWrap(currentDocument, 'scroll', this.onContextMenuClose);
      }
      // close popup when trigger type contains 'onContextMenu' and window is blur.
      if (!this.contextMenuOutsideHandler2 && this.isContextMenuToShow()) {
        this.contextMenuOutsideHandler2 = addEventListenerWrap(window, 'blur', this.onContextMenuClose);
      }
      return;
    }

    this.clearOutsideHandler();
  };

  Trigger.prototype.componentWillUnmount = function componentWillUnmount() {
    this.clearDelayTimer();
    this.clearOutsideHandler();
    clearTimeout(this.mouseDownTimeout);
  };

  Trigger.prototype.getPopupDomNode = function getPopupDomNode() {
    // for test
    if (this._component && this._component.getPopupDomNode) {
      return this._component.getPopupDomNode();
    }
    return null;
  };

  Trigger.prototype.getPopupAlign = function getPopupAlign() {
    var props = this.props;
    var popupPlacement = props.popupPlacement,
        popupAlign = props.popupAlign,
        builtinPlacements = props.builtinPlacements;

    if (popupPlacement && builtinPlacements) {
      return getAlignFromPlacement(builtinPlacements, popupPlacement, popupAlign);
    }
    return popupAlign;
  };

  /**
   * @param popupVisible    Show or not the popup element
   * @param event           SyntheticEvent, used for `pointAlign`
   */
  Trigger.prototype.setPopupVisible = function setPopupVisible(popupVisible, event) {
    var alignPoint = this.props.alignPoint;


    this.clearDelayTimer();

    if (this.state.popupVisible !== popupVisible) {
      if (!('popupVisible' in this.props)) {
        this.setState({ popupVisible: popupVisible });
      }
      this.props.onPopupVisibleChange(popupVisible);
    }

    // Always record the point position since mouseEnterDelay will delay the show
    if (alignPoint && event) {
      this.setPoint(event);
    }
  };

  Trigger.prototype.delaySetPopupVisible = function delaySetPopupVisible(visible, delayS, event) {
    var _this3 = this;

    var delay = delayS * 1000;
    this.clearDelayTimer();
    if (delay) {
      var point = event ? { pageX: event.pageX, pageY: event.pageY } : null;
      this.delayTimer = setTimeout(function () {
        _this3.setPopupVisible(visible, point);
        _this3.clearDelayTimer();
      }, delay);
    } else {
      this.setPopupVisible(visible, event);
    }
  };

  Trigger.prototype.clearDelayTimer = function clearDelayTimer() {
    if (this.delayTimer) {
      clearTimeout(this.delayTimer);
      this.delayTimer = null;
    }
  };

  Trigger.prototype.clearOutsideHandler = function clearOutsideHandler() {
    if (this.clickOutsideHandler) {
      this.clickOutsideHandler.remove();
      this.clickOutsideHandler = null;
    }

    if (this.contextMenuOutsideHandler1) {
      this.contextMenuOutsideHandler1.remove();
      this.contextMenuOutsideHandler1 = null;
    }

    if (this.contextMenuOutsideHandler2) {
      this.contextMenuOutsideHandler2.remove();
      this.contextMenuOutsideHandler2 = null;
    }

    if (this.touchOutsideHandler) {
      this.touchOutsideHandler.remove();
      this.touchOutsideHandler = null;
    }
  };

  Trigger.prototype.createTwoChains = function createTwoChains(event) {
    var childPros = this.props.children.props;
    var props = this.props;
    if (childPros[event] && props[event]) {
      return this['fire' + event];
    }
    return childPros[event] || props[event];
  };

  Trigger.prototype.isClickToShow = function isClickToShow() {
    var _props = this.props,
        action = _props.action,
        showAction = _props.showAction;

    return action.indexOf('click') !== -1 || showAction.indexOf('click') !== -1;
  };

  Trigger.prototype.isContextMenuToShow = function isContextMenuToShow() {
    var _props2 = this.props,
        action = _props2.action,
        showAction = _props2.showAction;

    return action.indexOf('contextMenu') !== -1 || showAction.indexOf('contextMenu') !== -1;
  };

  Trigger.prototype.isClickToHide = function isClickToHide() {
    var _props3 = this.props,
        action = _props3.action,
        hideAction = _props3.hideAction;

    return action.indexOf('click') !== -1 || hideAction.indexOf('click') !== -1;
  };

  Trigger.prototype.isMouseEnterToShow = function isMouseEnterToShow() {
    var _props4 = this.props,
        action = _props4.action,
        showAction = _props4.showAction;

    return action.indexOf('hover') !== -1 || showAction.indexOf('mouseEnter') !== -1;
  };

  Trigger.prototype.isMouseLeaveToHide = function isMouseLeaveToHide() {
    var _props5 = this.props,
        action = _props5.action,
        hideAction = _props5.hideAction;

    return action.indexOf('hover') !== -1 || hideAction.indexOf('mouseLeave') !== -1;
  };

  Trigger.prototype.isFocusToShow = function isFocusToShow() {
    var _props6 = this.props,
        action = _props6.action,
        showAction = _props6.showAction;

    return action.indexOf('focus') !== -1 || showAction.indexOf('focus') !== -1;
  };

  Trigger.prototype.isBlurToHide = function isBlurToHide() {
    var _props7 = this.props,
        action = _props7.action,
        hideAction = _props7.hideAction;

    return action.indexOf('focus') !== -1 || hideAction.indexOf('blur') !== -1;
  };

  Trigger.prototype.forcePopupAlign = function forcePopupAlign() {
    if (this.state.popupVisible && this._component && this._component.alignInstance) {
      this._component.alignInstance.forceAlign();
    }
  };

  Trigger.prototype.fireEvents = function fireEvents(type, e) {
    var childCallback = this.props.children.props[type];
    if (childCallback) {
      childCallback(e);
    }
    var callback = this.props[type];
    if (callback) {
      callback(e);
    }
  };

  Trigger.prototype.close = function close() {
    this.setPopupVisible(false);
  };

  Trigger.prototype.render = function render() {
    var _this4 = this;

    var popupVisible = this.state.popupVisible;
    var _props8 = this.props,
        children = _props8.children,
        forceRender = _props8.forceRender,
        alignPoint = _props8.alignPoint,
        className = _props8.className;

    var child = react_default.a.Children.only(children);
    var newChildProps = { key: 'trigger' };

    if (this.isContextMenuToShow()) {
      newChildProps.onContextMenu = this.onContextMenu;
    } else {
      newChildProps.onContextMenu = this.createTwoChains('onContextMenu');
    }

    if (this.isClickToHide() || this.isClickToShow()) {
      newChildProps.onClick = this.onClick;
      newChildProps.onMouseDown = this.onMouseDown;
      newChildProps.onTouchStart = this.onTouchStart;
    } else {
      newChildProps.onClick = this.createTwoChains('onClick');
      newChildProps.onMouseDown = this.createTwoChains('onMouseDown');
      newChildProps.onTouchStart = this.createTwoChains('onTouchStart');
    }
    if (this.isMouseEnterToShow()) {
      newChildProps.onMouseEnter = this.onMouseEnter;
      if (alignPoint) {
        newChildProps.onMouseMove = this.onMouseMove;
      }
    } else {
      newChildProps.onMouseEnter = this.createTwoChains('onMouseEnter');
    }
    if (this.isMouseLeaveToHide()) {
      newChildProps.onMouseLeave = this.onMouseLeave;
    } else {
      newChildProps.onMouseLeave = this.createTwoChains('onMouseLeave');
    }
    if (this.isFocusToShow() || this.isBlurToHide()) {
      newChildProps.onFocus = this.onFocus;
      newChildProps.onBlur = this.onBlur;
    } else {
      newChildProps.onFocus = this.createTwoChains('onFocus');
      newChildProps.onBlur = this.createTwoChains('onBlur');
    }

    var childrenClassName = classnames_default()(child && child.props && child.props.className, className);
    if (childrenClassName) {
      newChildProps.className = childrenClassName;
    }
    var trigger = react_default.a.cloneElement(child, newChildProps);

    if (!IS_REACT_16) {
      return react_default.a.createElement(
        es_ContainerRender,
        {
          parent: this,
          visible: popupVisible,
          autoMount: false,
          forceRender: forceRender,
          getComponent: this.getComponent,
          getContainer: this.getContainer
        },
        function (_ref2) {
          var renderComponent = _ref2.renderComponent;

          _this4.renderComponent = renderComponent;
          return trigger;
        }
      );
    }

    var portal = void 0;
    // prevent unmounting after it's rendered
    if (popupVisible || this._component || forceRender) {
      portal = react_default.a.createElement(
        es_Portal,
        {
          key: 'portal',
          getContainer: this.getContainer,
          didUpdate: this.handlePortalUpdate
        },
        this.getComponent()
      );
    }

    return [trigger, portal];
  };

  return Trigger;
}(react_default.a.Component);

es_Trigger.propTypes = {
  children: prop_types_default.a.any,
  action: prop_types_default.a.oneOfType([prop_types_default.a.string, prop_types_default.a.arrayOf(prop_types_default.a.string)]),
  showAction: prop_types_default.a.any,
  hideAction: prop_types_default.a.any,
  getPopupClassNameFromAlign: prop_types_default.a.any,
  onPopupVisibleChange: prop_types_default.a.func,
  afterPopupVisibleChange: prop_types_default.a.func,
  popup: prop_types_default.a.oneOfType([prop_types_default.a.node, prop_types_default.a.func]).isRequired,
  popupStyle: prop_types_default.a.object,
  prefixCls: prop_types_default.a.string,
  popupClassName: prop_types_default.a.string,
  className: prop_types_default.a.string,
  popupPlacement: prop_types_default.a.string,
  builtinPlacements: prop_types_default.a.object,
  popupTransitionName: prop_types_default.a.oneOfType([prop_types_default.a.string, prop_types_default.a.object]),
  popupAnimation: prop_types_default.a.any,
  mouseEnterDelay: prop_types_default.a.number,
  mouseLeaveDelay: prop_types_default.a.number,
  zIndex: prop_types_default.a.number,
  focusDelay: prop_types_default.a.number,
  blurDelay: prop_types_default.a.number,
  getPopupContainer: prop_types_default.a.func,
  getDocument: prop_types_default.a.func,
  forceRender: prop_types_default.a.bool,
  destroyPopupOnHide: prop_types_default.a.bool,
  mask: prop_types_default.a.bool,
  maskClosable: prop_types_default.a.bool,
  onPopupAlign: prop_types_default.a.func,
  popupAlign: prop_types_default.a.object,
  popupVisible: prop_types_default.a.bool,
  defaultPopupVisible: prop_types_default.a.bool,
  maskTransitionName: prop_types_default.a.oneOfType([prop_types_default.a.string, prop_types_default.a.object]),
  maskAnimation: prop_types_default.a.string,
  stretch: prop_types_default.a.string,
  alignPoint: prop_types_default.a.bool // Maybe we can support user pass position in the future
};
es_Trigger.contextTypes = contextTypes;
es_Trigger.childContextTypes = contextTypes;
es_Trigger.defaultProps = {
  prefixCls: 'rc-trigger-popup',
  getPopupClassNameFromAlign: returnEmptyString,
  getDocument: returnDocument,
  onPopupVisibleChange: noop,
  afterPopupVisibleChange: noop,
  onPopupAlign: noop,
  popupClassName: '',
  mouseEnterDelay: 0,
  mouseLeaveDelay: 0.1,
  focusDelay: 0,
  blurDelay: 0.15,
  popupStyle: {},
  destroyPopupOnHide: false,
  popupAlign: {},
  defaultPopupVisible: false,
  mask: false,
  maskClosable: true,
  action: [],
  showAction: [],
  hideAction: []
};

var es_initialiseProps = function _initialiseProps() {
  var _this5 = this;

  this.onMouseEnter = function (e) {
    var mouseEnterDelay = _this5.props.mouseEnterDelay;

    _this5.fireEvents('onMouseEnter', e);
    _this5.delaySetPopupVisible(true, mouseEnterDelay, mouseEnterDelay ? null : e);
  };

  this.onMouseMove = function (e) {
    _this5.fireEvents('onMouseMove', e);
    _this5.setPoint(e);
  };

  this.onMouseLeave = function (e) {
    _this5.fireEvents('onMouseLeave', e);
    _this5.delaySetPopupVisible(false, _this5.props.mouseLeaveDelay);
  };

  this.onPopupMouseEnter = function () {
    _this5.clearDelayTimer();
  };

  this.onPopupMouseLeave = function (e) {
    // https://github.com/react-component/trigger/pull/13
    // react bug?
    if (e.relatedTarget && !e.relatedTarget.setTimeout && _this5._component && _this5._component.getPopupDomNode && contains(_this5._component.getPopupDomNode(), e.relatedTarget)) {
      return;
    }
    _this5.delaySetPopupVisible(false, _this5.props.mouseLeaveDelay);
  };

  this.onFocus = function (e) {
    _this5.fireEvents('onFocus', e);
    // incase focusin and focusout
    _this5.clearDelayTimer();
    if (_this5.isFocusToShow()) {
      _this5.focusTime = Date.now();
      _this5.delaySetPopupVisible(true, _this5.props.focusDelay);
    }
  };

  this.onMouseDown = function (e) {
    _this5.fireEvents('onMouseDown', e);
    _this5.preClickTime = Date.now();
  };

  this.onTouchStart = function (e) {
    _this5.fireEvents('onTouchStart', e);
    _this5.preTouchTime = Date.now();
  };

  this.onBlur = function (e) {
    _this5.fireEvents('onBlur', e);
    _this5.clearDelayTimer();
    if (_this5.isBlurToHide()) {
      _this5.delaySetPopupVisible(false, _this5.props.blurDelay);
    }
  };

  this.onContextMenu = function (e) {
    e.preventDefault();
    _this5.fireEvents('onContextMenu', e);
    _this5.setPopupVisible(true, e);
  };

  this.onContextMenuClose = function () {
    if (_this5.isContextMenuToShow()) {
      _this5.close();
    }
  };

  this.onClick = function (event) {
    _this5.fireEvents('onClick', event);
    // focus will trigger click
    if (_this5.focusTime) {
      var preTime = void 0;
      if (_this5.preClickTime && _this5.preTouchTime) {
        preTime = Math.min(_this5.preClickTime, _this5.preTouchTime);
      } else if (_this5.preClickTime) {
        preTime = _this5.preClickTime;
      } else if (_this5.preTouchTime) {
        preTime = _this5.preTouchTime;
      }
      if (Math.abs(preTime - _this5.focusTime) < 20) {
        return;
      }
      _this5.focusTime = 0;
    }
    _this5.preClickTime = 0;
    _this5.preTouchTime = 0;
    if (event && event.preventDefault) {
      event.preventDefault();
    }
    var nextVisible = !_this5.state.popupVisible;
    if (_this5.isClickToHide() && !nextVisible || nextVisible && _this5.isClickToShow()) {
      _this5.setPopupVisible(!_this5.state.popupVisible, event);
    }
  };

  this.onPopupMouseDown = function () {
    var _context$rcTrigger = _this5.context.rcTrigger,
        rcTrigger = _context$rcTrigger === undefined ? {} : _context$rcTrigger;

    _this5.hasPopupMouseDown = true;

    clearTimeout(_this5.mouseDownTimeout);
    _this5.mouseDownTimeout = setTimeout(function () {
      _this5.hasPopupMouseDown = false;
    }, 0);

    if (rcTrigger.onPopupMouseDown) {
      rcTrigger.onPopupMouseDown.apply(rcTrigger, arguments);
    }
  };

  this.onDocumentClick = function (event) {
    if (_this5.props.mask && !_this5.props.maskClosable) {
      return;
    }

    var target = event.target;
    var root = Object(react_dom["findDOMNode"])(_this5);
    if (!contains(root, target) && !_this5.hasPopupMouseDown) {
      _this5.close();
    }
  };

  this.getRootDomNode = function () {
    return Object(react_dom["findDOMNode"])(_this5);
  };

  this.getPopupClassNameFromAlign = function (align) {
    var className = [];
    var _props9 = _this5.props,
        popupPlacement = _props9.popupPlacement,
        builtinPlacements = _props9.builtinPlacements,
        prefixCls = _props9.prefixCls,
        alignPoint = _props9.alignPoint,
        getPopupClassNameFromAlign = _props9.getPopupClassNameFromAlign;

    if (popupPlacement && builtinPlacements) {
      className.push(getAlignPopupClassName(builtinPlacements, prefixCls, align, alignPoint));
    }
    if (getPopupClassNameFromAlign) {
      className.push(getPopupClassNameFromAlign(align));
    }
    return className.join(' ');
  };

  this.getComponent = function () {
    var _props10 = _this5.props,
        prefixCls = _props10.prefixCls,
        destroyPopupOnHide = _props10.destroyPopupOnHide,
        popupClassName = _props10.popupClassName,
        action = _props10.action,
        onPopupAlign = _props10.onPopupAlign,
        popupAnimation = _props10.popupAnimation,
        popupTransitionName = _props10.popupTransitionName,
        popupStyle = _props10.popupStyle,
        mask = _props10.mask,
        maskAnimation = _props10.maskAnimation,
        maskTransitionName = _props10.maskTransitionName,
        zIndex = _props10.zIndex,
        popup = _props10.popup,
        stretch = _props10.stretch,
        alignPoint = _props10.alignPoint;
    var _state = _this5.state,
        popupVisible = _state.popupVisible,
        point = _state.point;


    var align = _this5.getPopupAlign();

    var mouseProps = {};
    if (_this5.isMouseEnterToShow()) {
      mouseProps.onMouseEnter = _this5.onPopupMouseEnter;
    }
    if (_this5.isMouseLeaveToHide()) {
      mouseProps.onMouseLeave = _this5.onPopupMouseLeave;
    }

    mouseProps.onMouseDown = _this5.onPopupMouseDown;
    mouseProps.onTouchStart = _this5.onPopupMouseDown;

    return react_default.a.createElement(
      es_Popup,
      extends_default()({
        prefixCls: prefixCls,
        destroyPopupOnHide: destroyPopupOnHide,
        visible: popupVisible,
        point: alignPoint && point,
        className: popupClassName,
        action: action,
        align: align,
        onAlign: onPopupAlign,
        animation: popupAnimation,
        getClassNameFromAlign: _this5.getPopupClassNameFromAlign
      }, mouseProps, {
        stretch: stretch,
        getRootDomNode: _this5.getRootDomNode,
        style: popupStyle,
        mask: mask,
        zIndex: zIndex,
        transitionName: popupTransitionName,
        maskAnimation: maskAnimation,
        maskTransitionName: maskTransitionName,
        ref: _this5.savePopup
      }),
      typeof popup === 'function' ? popup() : popup
    );
  };

  this.getContainer = function () {
    var props = _this5.props;

    var popupContainer = document.createElement('div');
    // Make sure default popup container will never cause scrollbar appearing
    // https://github.com/react-component/trigger/issues/41
    popupContainer.style.position = 'absolute';
    popupContainer.style.top = '0';
    popupContainer.style.left = '0';
    popupContainer.style.width = '100%';
    var mountNode = props.getPopupContainer ? props.getPopupContainer(Object(react_dom["findDOMNode"])(_this5)) : props.getDocument().body;
    mountNode.appendChild(popupContainer);
    return popupContainer;
  };

  this.setPoint = function (point) {
    var alignPoint = _this5.props.alignPoint;

    if (!alignPoint || !point) return;

    _this5.setState({
      point: {
        pageX: point.pageX,
        pageY: point.pageY
      }
    });
  };

  this.handlePortalUpdate = function () {
    if (_this5.prevPopupVisible !== _this5.state.popupVisible) {
      _this5.props.afterPopupVisibleChange(_this5.state.popupVisible);
    }
  };

  this.savePopup = function (node) {
    _this5._component = node;
  };
};

/* harmony default export */ var rc_trigger_es = (es_Trigger);
// CONCATENATED MODULE: ./node_modules/rc-tooltip/es/placements.js
var autoAdjustOverflow = {
  adjustX: 1,
  adjustY: 1
};

var targetOffset = [0, 0];

var placements = {
  left: {
    points: ['cr', 'cl'],
    overflow: autoAdjustOverflow,
    offset: [-4, 0],
    targetOffset: targetOffset
  },
  right: {
    points: ['cl', 'cr'],
    overflow: autoAdjustOverflow,
    offset: [4, 0],
    targetOffset: targetOffset
  },
  top: {
    points: ['bc', 'tc'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  bottom: {
    points: ['tc', 'bc'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  topLeft: {
    points: ['bl', 'tl'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  leftTop: {
    points: ['tr', 'tl'],
    overflow: autoAdjustOverflow,
    offset: [-4, 0],
    targetOffset: targetOffset
  },
  topRight: {
    points: ['br', 'tr'],
    overflow: autoAdjustOverflow,
    offset: [0, -4],
    targetOffset: targetOffset
  },
  rightTop: {
    points: ['tl', 'tr'],
    overflow: autoAdjustOverflow,
    offset: [4, 0],
    targetOffset: targetOffset
  },
  bottomRight: {
    points: ['tr', 'br'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  rightBottom: {
    points: ['bl', 'br'],
    overflow: autoAdjustOverflow,
    offset: [4, 0],
    targetOffset: targetOffset
  },
  bottomLeft: {
    points: ['tl', 'bl'],
    overflow: autoAdjustOverflow,
    offset: [0, 4],
    targetOffset: targetOffset
  },
  leftBottom: {
    points: ['br', 'bl'],
    overflow: autoAdjustOverflow,
    offset: [-4, 0],
    targetOffset: targetOffset
  }
};

/* harmony default export */ var es_placements = (placements);
// CONCATENATED MODULE: ./node_modules/rc-tooltip/es/Content.js






var Content_Content = function (_React$Component) {
  inherits_default()(Content, _React$Component);

  function Content() {
    classCallCheck_default()(this, Content);

    return possibleConstructorReturn_default()(this, _React$Component.apply(this, arguments));
  }

  Content.prototype.componentDidUpdate = function componentDidUpdate() {
    var trigger = this.props.trigger;

    if (trigger) {
      trigger.forcePopupAlign();
    }
  };

  Content.prototype.render = function render() {
    var _props = this.props,
        overlay = _props.overlay,
        prefixCls = _props.prefixCls,
        id = _props.id;

    return react_default.a.createElement(
      'div',
      { className: prefixCls + '-inner', id: id, role: 'tooltip' },
      typeof overlay === 'function' ? overlay() : overlay
    );
  };

  return Content;
}(react_default.a.Component);

Content_Content.propTypes = {
  prefixCls: prop_types_default.a.string,
  overlay: prop_types_default.a.oneOfType([prop_types_default.a.node, prop_types_default.a.func]).isRequired,
  id: prop_types_default.a.string,
  trigger: prop_types_default.a.any
};
/* harmony default export */ var es_Content = (Content_Content);
// CONCATENATED MODULE: ./node_modules/rc-tooltip/es/Tooltip.js











var Tooltip_Tooltip = function (_Component) {
  inherits_default()(Tooltip, _Component);

  function Tooltip() {
    var _temp, _this, _ret;

    classCallCheck_default()(this, Tooltip);

    for (var _len = arguments.length, args = Array(_len), _key = 0; _key < _len; _key++) {
      args[_key] = arguments[_key];
    }

    return _ret = (_temp = (_this = possibleConstructorReturn_default()(this, _Component.call.apply(_Component, [this].concat(args))), _this), _this.getPopupElement = function () {
      var _this$props = _this.props,
          arrowContent = _this$props.arrowContent,
          overlay = _this$props.overlay,
          prefixCls = _this$props.prefixCls,
          id = _this$props.id;

      return [react_default.a.createElement(
        'div',
        { className: prefixCls + '-arrow', key: 'arrow' },
        arrowContent
      ), react_default.a.createElement(es_Content, {
        key: 'content',
        trigger: _this.trigger,
        prefixCls: prefixCls,
        id: id,
        overlay: overlay
      })];
    }, _this.saveTrigger = function (node) {
      _this.trigger = node;
    }, _temp), possibleConstructorReturn_default()(_this, _ret);
  }

  Tooltip.prototype.getPopupDomNode = function getPopupDomNode() {
    return this.trigger.getPopupDomNode();
  };

  Tooltip.prototype.render = function render() {
    var _props = this.props,
        overlayClassName = _props.overlayClassName,
        trigger = _props.trigger,
        mouseEnterDelay = _props.mouseEnterDelay,
        mouseLeaveDelay = _props.mouseLeaveDelay,
        overlayStyle = _props.overlayStyle,
        prefixCls = _props.prefixCls,
        children = _props.children,
        onVisibleChange = _props.onVisibleChange,
        afterVisibleChange = _props.afterVisibleChange,
        transitionName = _props.transitionName,
        animation = _props.animation,
        placement = _props.placement,
        align = _props.align,
        destroyTooltipOnHide = _props.destroyTooltipOnHide,
        defaultVisible = _props.defaultVisible,
        getTooltipContainer = _props.getTooltipContainer,
        restProps = objectWithoutProperties_default()(_props, ['overlayClassName', 'trigger', 'mouseEnterDelay', 'mouseLeaveDelay', 'overlayStyle', 'prefixCls', 'children', 'onVisibleChange', 'afterVisibleChange', 'transitionName', 'animation', 'placement', 'align', 'destroyTooltipOnHide', 'defaultVisible', 'getTooltipContainer']);

    var extraProps = extends_default()({}, restProps);
    if ('visible' in this.props) {
      extraProps.popupVisible = this.props.visible;
    }
    return react_default.a.createElement(
      rc_trigger_es,
      extends_default()({
        popupClassName: overlayClassName,
        ref: this.saveTrigger,
        prefixCls: prefixCls,
        popup: this.getPopupElement,
        action: trigger,
        builtinPlacements: placements,
        popupPlacement: placement,
        popupAlign: align,
        getPopupContainer: getTooltipContainer,
        onPopupVisibleChange: onVisibleChange,
        afterPopupVisibleChange: afterVisibleChange,
        popupTransitionName: transitionName,
        popupAnimation: animation,
        defaultPopupVisible: defaultVisible,
        destroyPopupOnHide: destroyTooltipOnHide,
        mouseLeaveDelay: mouseLeaveDelay,
        popupStyle: overlayStyle,
        mouseEnterDelay: mouseEnterDelay
      }, extraProps),
      children
    );
  };

  return Tooltip;
}(react["Component"]);

Tooltip_Tooltip.propTypes = {
  trigger: prop_types_default.a.any,
  children: prop_types_default.a.any,
  defaultVisible: prop_types_default.a.bool,
  visible: prop_types_default.a.bool,
  placement: prop_types_default.a.string,
  transitionName: prop_types_default.a.oneOfType([prop_types_default.a.string, prop_types_default.a.object]),
  animation: prop_types_default.a.any,
  onVisibleChange: prop_types_default.a.func,
  afterVisibleChange: prop_types_default.a.func,
  overlay: prop_types_default.a.oneOfType([prop_types_default.a.node, prop_types_default.a.func]).isRequired,
  overlayStyle: prop_types_default.a.object,
  overlayClassName: prop_types_default.a.string,
  prefixCls: prop_types_default.a.string,
  mouseEnterDelay: prop_types_default.a.number,
  mouseLeaveDelay: prop_types_default.a.number,
  getTooltipContainer: prop_types_default.a.func,
  destroyTooltipOnHide: prop_types_default.a.bool,
  align: prop_types_default.a.object,
  arrowContent: prop_types_default.a.any,
  id: prop_types_default.a.string
};
Tooltip_Tooltip.defaultProps = {
  prefixCls: 'rc-tooltip',
  mouseEnterDelay: 0,
  destroyTooltipOnHide: false,
  mouseLeaveDelay: 0.1,
  align: {},
  placement: 'right',
  trigger: ['hover'],
  arrowContent: null
};


/* harmony default export */ var es_Tooltip = (Tooltip_Tooltip);
// CONCATENATED MODULE: ./node_modules/rc-tooltip/es/index.js


/* harmony default export */ var rc_tooltip_es = __webpack_exports__["default"] = (es_Tooltip);

/***/ }),

/***/ 3876:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);

// EXTERNAL MODULE: ./node_modules/lodash-es/_Symbol.js
var _Symbol = __webpack_require__(63);

// EXTERNAL MODULE: ./node_modules/lodash-es/_copyArray.js
var _copyArray = __webpack_require__(175);

// EXTERNAL MODULE: ./node_modules/lodash-es/_getTag.js + 2 modules
var _getTag = __webpack_require__(122);

// EXTERNAL MODULE: ./node_modules/lodash-es/isArrayLike.js
var isArrayLike = __webpack_require__(50);

// EXTERNAL MODULE: ./node_modules/lodash-es/isString.js
var isString = __webpack_require__(232);

// CONCATENATED MODULE: ./node_modules/lodash-es/_iteratorToArray.js
/**
 * Converts `iterator` to an array.
 *
 * @private
 * @param {Object} iterator The iterator to convert.
 * @returns {Array} Returns the converted array.
 */
function iteratorToArray(iterator) {
  var data,
      result = [];

  while (!(data = iterator.next()).done) {
    result.push(data.value);
  }
  return result;
}

/* harmony default export */ var _iteratorToArray = (iteratorToArray);

// EXTERNAL MODULE: ./node_modules/lodash-es/_mapToArray.js
var _mapToArray = __webpack_require__(717);

// EXTERNAL MODULE: ./node_modules/lodash-es/_setToArray.js
var _setToArray = __webpack_require__(277);

// EXTERNAL MODULE: ./node_modules/lodash-es/_stringToArray.js + 2 modules
var _stringToArray = __webpack_require__(731);

// EXTERNAL MODULE: ./node_modules/lodash-es/values.js
var values = __webpack_require__(212);

// CONCATENATED MODULE: ./node_modules/lodash-es/toArray.js











/** `Object#toString` result references. */
var mapTag = '[object Map]',
    setTag = '[object Set]';

/** Built-in value references. */
var symIterator = _Symbol["a" /* default */] ? _Symbol["a" /* default */].iterator : undefined;

/**
 * Converts `value` to an array.
 *
 * @static
 * @since 0.1.0
 * @memberOf _
 * @category Lang
 * @param {*} value The value to convert.
 * @returns {Array} Returns the converted array.
 * @example
 *
 * _.toArray({ 'a': 1, 'b': 2 });
 * // => [1, 2]
 *
 * _.toArray('abc');
 * // => ['a', 'b', 'c']
 *
 * _.toArray(1);
 * // => []
 *
 * _.toArray(null);
 * // => []
 */
function toArray(value) {
  if (!value) {
    return [];
  }
  if (Object(isArrayLike["a" /* default */])(value)) {
    return Object(isString["default"])(value) ? Object(_stringToArray["a" /* default */])(value) : Object(_copyArray["a" /* default */])(value);
  }
  if (symIterator && value[symIterator]) {
    return _iteratorToArray(value[symIterator]());
  }
  var tag = Object(_getTag["a" /* default */])(value),
      func = tag == mapTag ? _mapToArray["a" /* default */] : (tag == setTag ? _setToArray["a" /* default */] : values["default"]);

  return func(value);
}

/* harmony default export */ var lodash_es_toArray = __webpack_exports__["default"] = (toArray);


/***/ }),

/***/ 3880:
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
__webpack_require__.r(__webpack_exports__);

// EXTERNAL MODULE: ./node_modules/lodash-es/_arraySome.js
var _arraySome = __webpack_require__(716);

// EXTERNAL MODULE: ./node_modules/lodash-es/_baseIteratee.js + 9 modules
var _baseIteratee = __webpack_require__(79);

// EXTERNAL MODULE: ./node_modules/lodash-es/_baseEach.js + 1 modules
var _baseEach = __webpack_require__(174);

// CONCATENATED MODULE: ./node_modules/lodash-es/_baseSome.js


/**
 * The base implementation of `_.some` without support for iteratee shorthands.
 *
 * @private
 * @param {Array|Object} collection The collection to iterate over.
 * @param {Function} predicate The function invoked per iteration.
 * @returns {boolean} Returns `true` if any element passes the predicate check,
 *  else `false`.
 */
function baseSome(collection, predicate) {
  var result;

  Object(_baseEach["a" /* default */])(collection, function(value, index, collection) {
    result = predicate(value, index, collection);
    return !result;
  });
  return !!result;
}

/* harmony default export */ var _baseSome = (baseSome);

// EXTERNAL MODULE: ./node_modules/lodash-es/isArray.js
var isArray = __webpack_require__(22);

// EXTERNAL MODULE: ./node_modules/lodash-es/_isIterateeCall.js
var _isIterateeCall = __webpack_require__(211);

// CONCATENATED MODULE: ./node_modules/lodash-es/some.js






/**
 * Checks if `predicate` returns truthy for **any** element of `collection`.
 * Iteration is stopped once `predicate` returns truthy. The predicate is
 * invoked with three arguments: (value, index|key, collection).
 *
 * @static
 * @memberOf _
 * @since 0.1.0
 * @category Collection
 * @param {Array|Object} collection The collection to iterate over.
 * @param {Function} [predicate=_.identity] The function invoked per iteration.
 * @param- {Object} [guard] Enables use as an iteratee for methods like `_.map`.
 * @returns {boolean} Returns `true` if any element passes the predicate check,
 *  else `false`.
 * @example
 *
 * _.some([null, 0, 'yes', false], Boolean);
 * // => true
 *
 * var users = [
 *   { 'user': 'barney', 'active': true },
 *   { 'user': 'fred',   'active': false }
 * ];
 *
 * // The `_.matches` iteratee shorthand.
 * _.some(users, { 'user': 'barney', 'active': false });
 * // => false
 *
 * // The `_.matchesProperty` iteratee shorthand.
 * _.some(users, ['active', false]);
 * // => true
 *
 * // The `_.property` iteratee shorthand.
 * _.some(users, 'active');
 * // => true
 */
function some(collection, predicate, guard) {
  var func = Object(isArray["default"])(collection) ? _arraySome["a" /* default */] : _baseSome;
  if (guard && Object(_isIterateeCall["a" /* default */])(collection, predicate, guard)) {
    predicate = undefined;
  }
  return func(collection, Object(_baseIteratee["a" /* default */])(predicate, 3));
}

/* harmony default export */ var lodash_es_some = __webpack_exports__["default"] = (some);


/***/ })

}]);
//# sourceMappingURL=https://s3.pstatp.com/eesz/resource/bear/js/embed-sheet.82974078700753200c21.js.map