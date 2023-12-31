const switchContactEntry = (state, action) => {
  const { type } = action.payload;
  let entries = state.config.contactConfig.entries;
  console.log("switchContactEntry", entries);
  entries[type] =
    entries[type].length > 0 ? [] : [{ existsEnterpriseEmail: false }];
  return {
    ...state,
    config: {
      ...state.config,
      contactConfig: {
        ...state.config.contactConfig,
        entries: entries,
      },
    },
  };
};

const changeRecommendType = (state, action) => {
  const { index } = action.payload;
  const type = index === 0 ? "contact" : index === 1 ? "search" : "none";
  return {
    ...state,
    config: {
      ...state.config,
      recommendType: type,
    },
  };
};

export { switchContactEntry, changeRecommendType };
