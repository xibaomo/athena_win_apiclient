#ifndef _CLIENT_API_FX_ACTION_H_
#define _CLIENT_API_FX_ACTION_H_

enum class FXAction {
    HISTORY = 10,
    BUY_TICK,
    SELL_TICK,
    NOACTION,
    PLACE_BUY,
    PLACE_SELL
};
#endif // _CLIENT_API_FX_ACTION_H_
