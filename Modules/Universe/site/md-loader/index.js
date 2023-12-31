const path = require('path');
const fs = require('fs-extra');
const loaderUtils = require('loader-utils');
const fm = require('front-matter');
const codeRegex = /<code src="(\S+?)"(\s+?)\/>/g;

/**
 * 处理 \<code src="xx" /> 部分
 * @param {String} content
 * @param {String} demoDir
 * @return {{ dependencies: Array.<String>, body: String }}
 */
function replaceCodeTag(content, demoDir) {
  const dependencies = [];
  content = content.replace(codeRegex, (_match, srcAttr) => {
    const filePath = path.resolve(demoDir, srcAttr);
    if (!fs.existsSync(filePath)) {
      return '';
    }
    dependencies.push(filePath);
    const content = fs.readFileSync(filePath);
    const ext = filePath.split('.').pop();
    return `\`\`\`${ext}
${content}
\`\`\``;
  });

  return {
    dependencies,
    body: content,
  };
}

/**
 * @typedef {{ order: number, title: string, skip: boolean }} Attribute
 * @param {String} source
 * @param {String} demoDir
 * @return {{ attributes: Attribute, body: String, dependencies: Array.<string> }}
 */
function getMetaFromMd(source, demoDir) {
  const fmSource = fm(source);
  let { attributes, body: raw } = fmSource;

  raw = `\n## ${attributes.title}\n${raw}`;
  // 先将 <code src="xxxx" /> 处理成 ```ext  ``` 形式
  const { body, dependencies } = replaceCodeTag(raw, demoDir);

  return {
    attributes,
    body,
    dependencies,
  };
}

/**
 * @typedef {{ order: number, title: string, skip: boolean }} Attribute
 * @typedef {{ attributes: Attribute, body: String, dependencies: Array.<String> }} Demo
 * @param {string} context 路径
 * @param {{ demoDir: string }} options 配置
 * @return {Array.<Demo>}
 */
function getMetas(context, options) {
  const demoDir = path.resolve(context, options.demoDir || 'demo');
  const files = fs.readdirSync(demoDir);
  const metadata = files
    .map(file => {
      const demoPath = path.resolve(demoDir, file);
      const source = fs.readFileSync(demoPath, 'utf8');
      if (/\.md$/.test(file)) {
        const ret = getMetaFromMd(source, path.resolve(context, demoDir));
        ret.dependencies.push(demoPath);
        return ret;
      }
    })
    .filter(i => Boolean(i))
    .filter(i => !i.attributes.skip);
  metadata.sort((a, b) => a.attributes.order - b.attributes.order);

  return metadata;
}

module.exports = function (content) {
  const options = loaderUtils.getOptions(this) || {};
  const placeholder = '%%Content%%';
  let body = '';
  let needReplaceDemo = true;

  try {
    const metas = getMetas(this.context, options);

    metas.forEach(meta => {
      body += `\n${meta.body}`;
      meta.dependencies.forEach(file => this.addDependency(file));
    });
  } catch (err) {
    if (err.syscall === 'scandir' && err.code === 'ENOENT') {
      needReplaceDemo = false;
    } else {
      console.error(err);
    }
  }
  try {
    const demoDir = path.resolve(this.context, options.demoDir || 'demo');
    const result = replaceCodeTag(content, demoDir);

    content = result.body;
    result.dependencies.forEach(file => this.addDependency(file));
  } catch (err) {
    if (err.syscall === 'scandir' && err.code === 'ENOENT') {
      needReplaceDemo = false;
    } else {
      console.error(err);
    }
  }

  return content.replace(placeholder, body).concat('<SiteFab />');
};
