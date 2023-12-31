const fs = require('fs');
const path = require('path');

function replaceLink() {
  const path = "./CHANGELOG.md";
  const content = fs.readFileSync(path).toString();

  const commitRegex = /http:\/\/git\.byted\.org:29418\/ee\/lark\/ios-client\/commits\/([^)]+)/g;
  const closeRegex = /http:\/\/git\.byted\.org:29418\/ee\/lark\/ios-client\/issues\/([^)]+)/g;
  const titleRegex = /\[([^\]]+)\]\(http:\/\/git\.byted\.org:29418\/ee\/lark\/ios-client\/compare\/[^)]+\)/g;

  const newContent = content
    .replace(commitRegex, "https://review.byted.org/#/q/$1")
    .replace(closeRegex, "https://jira.bytedance.com/browse/LKI-$1")
    .replace(titleRegex, "$1");

  fs.writeFileSync(path, newContent);
}

replaceLink();
