/* App State Provider */

const AppStateContext = React.createContext();

const AppStateProvider = ({ children }) => {
  const [state, setState] = React.useState({
    streak: 7,
    currentTab: 'home',
    navParams: {},
  });

  const navigate = (tab, params = {}) => {
    setState(prev => ({ ...prev, currentTab: tab, navParams: params }));
  };

  return React.createElement(AppStateContext.Provider, { value: { state, setState, navigate } }, children);
};

const useAppState = () => React.useContext(AppStateContext);

Object.assign(window, { AppStateContext, AppStateProvider, useAppState });
