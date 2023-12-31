const getEntityName = (entity) => {
  if (entity.type === "chatter") {
    return "人员";
  } else if (entity.type === "chat") {
    return "群组";
  } else if (entity.type === "userGroup") {
    return "用户组";
  } else if (entity.type === "doc") {
    return "文档";
  } else if (entity.type === "wiki") {
    return "知识库";
  } else if (entity.type === "wikiSpace") {
    return "知识空间";
  }
  return "unknown";
};

const getEntities = (entities) => {
  let result = [];
  result = result.concat(entities.chatters);
  result = result.concat(entities.chats);
  result = result.concat(entities.docs);
  result = result.concat(entities.wikis);
  if (entities.wikiSpaces !== undefined) {
    result = result.concat(entities.wikiSpaces);
  }
  return result;
};

export { getEntities, getEntityName };
