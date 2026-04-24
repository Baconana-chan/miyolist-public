import { useEffect, useState } from "preact/hooks";
import {
  getOnlineStatus,
  initializeOnlineStatus,
  subscribeOnlineStatus,
} from "../network/onlineStatus";

export function useOnlineStatus() {
  const [online, setOnline] = useState<boolean>(() => getOnlineStatus());

  useEffect(() => {
    initializeOnlineStatus();
    return subscribeOnlineStatus(setOnline);
  }, []);

  return online;
}
