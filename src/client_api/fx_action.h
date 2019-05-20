#ifndef _CLIENT_API_FX_ACTION_H_
#define _CLIENT_API_FX_ACTION_H_

enum class FXAction {
    HISTORY = 10,
    HISTORY_MINBAR,
    CHECKIN,
    TICK,
    MINBAR,
    NOACTION,
    PLACE_BUY,
    PLACE_SELL,
    INIT_TIME,
    REQUEST_HISTORY_MINBAR,
    PROFIT,
    CLOSE_POS
};
#endif // _CLIENT_API_FX_ACTION_H_
