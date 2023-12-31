#!/usr/bin/env node

const commitTypes = {
    // 需要关联issue和scope
    feat: {
        issue: true,
        scope: true
    },
    fix: {
        issue: true,
        scope: true
    },
    // 需要关联scope，可以没有关联issue
    test: {
        scope: true
    },
    refactor: {
        scope: true
    },
    // 既不需要scope也不需要issue
    perf: {},
    chore: {},
    build: {}
}

const scopes = [
    'lark', 'byteview', 'spacekit', 'appcenter', 'calendar', 'email'
];

const Errors = {
    NotMatch: 'NotMatch',
    NeedMessage: 'NeedMessage',
    NeedBlank: 'NeedBlank',
    UnknownType: 'UnknownType',
    NeedScope: 'NeedScope',
    UnknownScope: 'UnknownScope',
    NeedIssue: 'NeedIssue'
};

function check(msg) {
    const commitMessages = msg.trim().split("\n").filter(function (msg) {
        return msg.trim();
    });

    const matches = commitMessages[0].match(/^(\[[^\]]+\]\s*)?([^:(]+)(\(([^)]+)\))?:( )?([\s\S]+)?/i);

    if (!matches) {
        return {
            result: 0,
            error: Errors.NotMatch,
            message: "commit type和scope无法匹配，请检查commit message"
        };
    }

    if (!matches[5]) {
        return {
            result: 0,
            error: Errors.NeedBlank,
            message: "冒号后面需要加空格"
        };
    }

    if (!matches[6]) {
      return {
          result: 0,
          error: Errors.NeedMessage,
          message: "请填写commit message"
      };
    }

    const type = commitTypes[matches[2]];
    if (!type) {
        return {
            result: 0,
            error: Errors.UnknownType,
            message: "未知的commit type: " + matches[2]
        };
    }

    if (type.scope) {
        if (!matches[4]) {
            return {
                result: 0,
                error: Errors.NeedScope,
                message: "commit type [" + matches[2] + "] 必须添加scope"
            };
        }
        if (scopes.indexOf(matches[4]) < 0) {
            return {
                result: 0,
                error: Errors.UnknownScope,
                message: "未知的scope: " + matches[4]
            };
        }
    }

    if (type.issue) {
        const issueMatches = (commitMessages[commitMessages.length - 2] || "").trim().match(/^closes \[(SUITE|LBID|FEISHUFB)-(\d+)\](, ?\[(SUITE|LBID|FEISHUFB)-(\d+)\])*$/);
        if (!matches[1] && (!issueMatches || !issueMatches[1])) {
            return {
                result: 0,
                error: Errors.NeedIssue,
                message: "commit type [" + matches[2] + "] 必须添加关联的issue. issue format is closes [SUITE-XXX] or [LBID-XXX]"
            };
        }
    }

    return {
        result: 1
    };
}

function assertTrue(val, msg) {
  if (!val) {
    console.log(msg);
  }
}

function test() {
    const res1 = check("hhhhh");
    assertTrue(res1.error === Errors.NotMatch, "1[" + res1.message + "]");

    const res2 = check("abc: ggg");
    assertTrue(res2.error === Errors.UnknownType, "2[" + res2.message + "]");

    const res3 = check("feat: ggg");
    assertTrue(res3.error === Errors.NeedScope, "3[" + res3.message + "]");

    const res4 = check("feat(abc): ggg");
    assertTrue(res4.error === Errors.UnknownScope, "4[" + res4.message + "]");

    const res5 = check("feat(lark): test\n\n\nchangeId:fdfsfjskfjksfjsk");
    assertTrue(res5.error === Errors.NeedIssue, "5[" + res5.message + "]");

    const res5_1 = check("[LBID-xxx]feat(lark): test\n\n\nchangeId:fdfsfjskfjksfjsk");
    assertTrue(!res5_1.error, "5_1[" + res5.message + "]");

    const res6 = check("feat(lark): test\n\n\ncloses [SUITE-123]\n\n\nchangeId:fdfsfjskfjksfjsk");
    assertTrue(!res6.error, "6应该完全正确");

    const res7 = check("feat(lark): \n\n\nchangeId:fdfsfjskfjksfjsk");
    assertTrue(res7.error === Errors.NeedMessage, "7[" + res7.message + "]");

    const res8 = check("test: gggg");
    assertTrue(res8.error === Errors.NeedScope, "8[" + res7.message + "]");

    const res9 = check("test(lark): gggg");
    assertTrue(!res9.error, "9应该完全正确");

    const res10 = check("chore: gggg");
    assertTrue(!res10.error, "10应该完全正确");

    const res11 = check("test(chat):ggg");
    assertTrue(res11.error === Errors.NeedBlank, "11[" + res11.message + "]");

    const res12 = check("feat(lark): test\n\n\ncloses [LBID-123]\n\n\nchangeId:fdfsfjskfjksfjsk");
    assertTrue(!res12.error, "12应该完全正确");
}

function main() {
    const type = process.argv[2];
    if (type == "test") {
        test();
        return 1;
    }

    if (type == "check") {
        const res = check(process.argv[3]);
        if (res.error) {
          console.log("error: " + res.message);
        }
        return res.result;
    }

    console.log("命令类型不识别");
    return 0;
}

const res = main();
if (res) {
  console.log(res);
}
