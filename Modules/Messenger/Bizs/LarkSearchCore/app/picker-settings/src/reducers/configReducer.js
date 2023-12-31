import searchConfigString from "../config/search.json";
import {
  switchContactEntry,
  changeRecommendType,
} from "@/reducers/configRecommendReducer";

const searchConfig = JSON.parse(searchConfigString);
/**
 {
    config: {
        searchConfig: {
            entities: {
                chatters: []
            }
        },
        featureConfig: {},
        recommendType: "none",
        contactConfig: {}
    },
    editEntity: {
        entity: {},
        isNew: false,
        index: 0
    }
 }
 */
export const configReducer = (state, action) => {
  console.log("configReducer----------", action);
  switch (action.event) {
    case "delete_entity":
      return deleteEntity(state, action);
    case "add_entity":
      return addEntity(state, action);
    case "edit_entity":
      return editEntity(state, action);
    case "saveEditEntity":
      return saveEditEntity(state, action);
    case "cancel_edit_entity":
      return cancelEditEntity(state, action);
    case "changeRecommendType":
      return changeRecommendType(state, action);
    case "switchContactEntry":
      return switchContactEntry(state, action);
    case "change_feature_config":
      return changeFeatureConfig(state, action);
    default:
      return state;
  }
};

const deleteEntity = (state, action) => {
  const { entity, index } = action.payload;
  const { entities } = state.config.searchConfig;
  switch (entity.type) {
    case "chatter":
      entities.chatters.splice(index, 1);
      break;
    case "chat":
      entities.chats.splice(index, 1);
      break;
    case "userGroup":
      entities.userGroups.splice(index, 1);
      break;
    case "dynamicUserGroup":
      entities.dynamicUserGroups.splice(index, 1);
      break;
    case "doc":
      entities.docs.splice(index, 1);
      break;
    case "wiki":
      entities.wikis.splice(index, 1);
      break;
    case "wikiSpace":
      entities.wikiSpaces.splice(index, 1);
      break;
    default:
      break;
  }
  return {
    ...state,
    config: {
      ...state.config,
      searchConfig: {
        ...state.config.searchConfig,
        entities: entities,
      },
    },
  };
};

const addEntity = (state, action) => {
  console.log("addEntity", searchConfig);
  const { type } = action.payload;
  let entity = {};
  const { entities } = state.config.searchConfig;
  switch (type) {
    case "chatter":
      entity = searchConfig.entities.chatters[0];
      entities.chatters.push(entity);
      break;
    case "chat":
      entity = searchConfig.entities.chats[0];
      entities.chats.push(entity);
      break;
    case "userGroup":
      entity = searchConfig.entities.userGroups[0];
      entities.userGroups.push(entity);
      break;
    case "dynamicUserGroup":
      entity = searchConfig.entities.dynamicUserGroups[0];
      entities.dynamicUserGroups.push(entity);
      break;
    case "doc":
      entity = searchConfig.entities.docs[0];
      entities.docs.push(entity);
      break;
    case "wiki":
      entity = searchConfig.entities.wikis[0];
      entities.wikis.push(entity);
      break;
    case "wikiSpace":
      entity = searchConfig.entities.wikiSpaces[0];
      if (entities.wikiSpaces === undefined) {
        entities.wikiSpaces = [entity];
      } else {
        entities.wikiSpaces.push(entity);
      }
      break;
    default:
      break;
  }
  return {
    ...state,
    config: {
      ...state.config,
      searchConfig: {
        ...state.config.searchConfig,
        entities: entities,
      },
    },
  };
};

const editEntity = (state, action) => {
  const { entity, index } = action.payload;
  return {
    ...state,
    editEntity: {
      entity: entity,
      isNew: false,
      index: index,
    },
  };
};

const cancelEditEntity = (state, action) => {
  return {
    ...state,
    editEntity: null,
  };
};

const saveEditEntity = (state, action) => {
  const { entity } = action.payload;
  const { entities } = state.config.searchConfig;
  const index = state.editEntity.index;
  console.log("saveEditEntity", entity.type, index);
  switch (entity.type) {
    case "chatter":
      entities.chatters[index] = entity;
      break;
    case "chat":
      entities.chats[index] = entity;
      break;
    case "userGroup":
      entities.userGroups[index] = entity;
      break;
    case "dynamicUserGroup":
      entities.dynamicUserGroups[index] = entity;
      break;
    case "doc":
      entities.docs[index] = entity;
      break;
    case "wiki":
      entities.wikis[index] = entity;
      break;
    case "wikiSpace":
      entities.wikiSpaces[index] = entity;
      break;
    default:
      break;
  }
  return {
    ...state,
    config: {
      ...state.config,
      searchConfig: {
        ...state.config.searchConfig,
        entities: entities,
      },
    },
    editEntity: null,
  };
};

const changeFeatureConfig = (state, action) => {
  const { key, value } = action.payload;
  const keys = key.split(".");
  let featureConfig = state.config.featureConfig;
  let result = featureConfig;
  keys.forEach((k, i) => {
    if (i === keys.length - 1) {
      featureConfig[k] = value;
    } else {
      featureConfig = featureConfig[k];
    }
  });
  return {
    ...state,
    config: {
      ...state.config,
      featureConfig: result,
    },
  };
};
