//+------------------------------------------------------------------+
//|                                                    graphloop.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, FXUA"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#define BUFLEN  256
struct CharArray {
   char a[BUFLEN];
   char b[BUFLEN];
   char c[BUFLEN];
};
#import "athena_win_apiclient.dll"
int athena_init(string symbol, string hostip, string port);
int glp_request_all_syms(CharArray& arr, int& nsyms);
int glp_send_new_quotes(double& asks[], double& bids[], int len, string tms, CharArray&, int&, int& pos[]);
int glp_get_loop();
int glp_add_sym_price(string sym, double ask, double bid);
int glp_compute_loop_return(double& loop_rtn);
int glp_clear_loop();
int glp_finish();
int athena_finish();
#import

#define QUOTE_PERIOD PERIOD_M5
#define CHECKPOS_PERIOD PERIOD_M1
#define MAXTRY 3
#define SLEEP_MS 10000

double TP_RETURN = 0.01f;
double SL_RETURN = 0.01f;
string timeBound = "2023.2.28 23:10";
string hostip    = "192.168.150.67";
string port      = "8888";
sinput ulong  m_magic   = 2512554564564;
string sym_x = "EURUSD";
double lot_size   = 0.2;
ulong m_slippage = 30;

string g_all_syms[];
int    g_num_syms;
int    g_pos_types[20];
CharArray g_trade_syms;
int       g_num_trade_syms;


CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol_Base;                // symbol info object
CAccountInfo   m_account;                    // account info wrapper
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Print("Connecting api server ...");
   athena_init(sym_x,hostip,port);
   Print("Api server connected");
   
   CharArray arr;
   string strarr[];
   glp_request_all_syms(arr,g_num_syms);
   PrintFormat("num of syms: %d\n",g_num_syms);   //int nsyms = StringSplit(arr.a, '\0',strarr);
   ArrayResize(g_all_syms,g_num_syms);
   int pos=0;
   for (int i =0; i < g_num_syms; i++) {
      string tmp = CharArrayToString(arr.a,pos,7);
      g_all_syms[i] = tmp;
      pos+=7;
   }
   checkValidity();
//---
   m_trade.SetExpertMagicNumber(m_magic);

    if(IsFillingTypeAllowed(SYMBOL_FILLING_FOK))
        m_trade.SetTypeFilling(ORDER_FILLING_FOK);
    else if(IsFillingTypeAllowed(SYMBOL_FILLING_IOC))
        m_trade.SetTypeFilling(ORDER_FILLING_IOC);
    else
        m_trade.SetTypeFilling(ORDER_FILLING_RETURN);

    m_trade.SetDeviationInPoints(m_slippage);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   glp_finish();
   athena_finish();
    Print("athena_finish called");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
    if(isQuoteTime() && PositionsTotal() == 0) {
       double asks[];
       double bids[];
       //CharArray trade_syms;
       //int num_trade_syms;
       datetime time_0 = iTime(NULL,QUOTE_PERIOD,0);
       string timestr = TimeToString(time_0);
       ArrayResize(asks,g_num_syms);
       ArrayResize(bids,g_num_syms);
       for(int i=0; i < g_num_syms; i++) {
            if (!m_symbol_Base.Name(g_all_syms[i])) {
               PrintFormat("ERROR! Failed to set symbol: %s",g_all_syms[i]);
               return;
            }
            if (!m_symbol_Base.RefreshRates()) {
               Print("Failed to refresh rates\n");
               return;
            }
            asks[i] = m_symbol_Base.Ask();
            bids[i] = m_symbol_Base.Bid();
       }
       glp_send_new_quotes(asks,bids,g_num_syms,timestr,g_trade_syms,g_num_trade_syms,g_pos_types);
       ArrayFree(asks);
       ArrayFree(bids);
       if(g_num_trade_syms==0) {
         Print("No action");
         return;
       }
       place_positions(g_trade_syms,g_num_trade_syms);
       glp_get_loop();
    }// end of quote time
    
    if(isCheckPosTime() && PositionsTotal() > 0) {
       int offset = 7;
       int pos = 0;
       for (int i=0; i < g_num_trade_syms; i++) {
           string symbol = CharArrayToString(g_trade_syms.a,pos,offset);
           pos+=offset;
           
            double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
            double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
            PrintFormat("sym: %s, ask: %f, bid: %f",symbol,ask,bid);
            glp_add_sym_price(symbol,ask,bid);
        }
        double loop_rtn;
        glp_compute_loop_return(loop_rtn);
        if(loop_rtn < 0.00) {
            closeAllPos();
            glp_clear_loop();
        } 
    } // end of check open positions
 }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---
   
  }
//+------------------------------------------------------------------+
void checkValidity() {
   for(int i=0; i < g_num_syms; i++) {
      string symbol = g_all_syms[i];
      if(SymbolInfoInteger(symbol, SYMBOL_DIGITS) <= 0){
         PrintFormat("Invalid symbol: %s",symbol);
         return;
      }
   }
   Print("All symbols are valid");
}

//+------------------------------------------------------------------+
//| Checks if the specified filling mode is allowed                  |
//+------------------------------------------------------------------+
bool IsFillingTypeAllowed(int fill_type)
{
//--- Obtain the value of the property that describes allowed filling modes
    int filling=m_symbol_Base.TradeFillFlags();
//--- Return true, if mode fill_type is allowed
    return((filling & fill_type)==fill_type);
}

bool isQuoteTime() {
   static datetime prevBar=0;
   datetime time_0 = iTime(NULL,QUOTE_PERIOD,0); // opening time of the bar
   if (time_0 == prevBar)
     return false;
   prevBar = time_0;
   return true;
}

bool isCheckPosTime() {
   static datetime prevBar=0;
   datetime time_0 = iTime(NULL,CHECKPOS_PERIOD,0); // opening time of the bar
   if (time_0 == prevBar)
     return false;
   prevBar = time_0;
   return true;
}

void place_positions(CharArray& trade_syms, int num) {
    int offset = 7;
    int pos = 0;
    for (int i=0; i < num; i++) {
        string tmp = CharArrayToString(trade_syms.a,pos,offset);
        pos+=offset;
        if(!m_symbol_Base.Name(tmp)) {
            PrintFormat("ERROR! Failed to set symbol: %s",tmp);
            return;
        }
        if (!m_symbol_Base.RefreshRates()) {
            Print("Failed to refresh rates\n");
            return;
        }
        
        if (g_pos_types[i] > 0) {
            OpenBuy(m_symbol_Base,lot_size);
        }
        if (g_pos_types[i] < 0) {
            OpenSell(m_symbol_Base,lot_size);
        }
    }
}
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
ulong OpenBuy(CSymbolInfo &symbol, double lotsize, string cmt="")
{
    double check_open_long_lot=lotsize;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
    double check_volume_lot=m_trade.CheckVolume(symbol.Name(),check_open_long_lot,symbol.Ask(),ORDER_TYPE_BUY);

    int digits = (int)SymbolInfoInteger(symbol.Name(),SYMBOL_DIGITS);
    double price = symbol.Ask();
    double tp = NormalizeDouble(price + TP_RETURN*price,digits);
    double sl = NormalizeDouble(price - SL_RETURN*price,digits);
    
    if(check_volume_lot!=0.0) {
        if(check_volume_lot>=check_open_long_lot) {
            for (int i=0; i < MAXTRY; i++) {
                PrintFormat("Try buy: %dth",i);
                symbol.RefreshRates();
                if(m_trade.Buy(check_open_long_lot,symbol.Name(),symbol.Ask(),sl,tp,cmt)) {

                    if(m_trade.ResultDeal()==0) {
                        Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                        //PrintResult(m_trade,symbol);
                    } else {
                        Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                        //PrintResult(m_trade,symbol);
                        return m_trade.ResultOrder();
                        break;
                    }
                }

                else {
                    Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                          ", description of result: ",m_trade.ResultRetcodeDescription());
                    //PrintResult(m_trade,symbol);
                }
                Sleep(SLEEP_MS);
            }
        } else {
            Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
                  "< \"Lots\" (",DoubleToString(check_open_long_lot,2),")");
            return 0;
        }
    } else {
        Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
        return 0;
    }
//---r
   return 0;
}

//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
ulong OpenSell(CSymbolInfo &symbol,double lotsize, string cmt="")
{
    double check_open_short_lot=lotsize;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
    double check_volume_lot=m_trade.CheckVolume(symbol.Name(),check_open_short_lot,symbol.Bid(),ORDER_TYPE_SELL);

    int digits = (int)SymbolInfoInteger(symbol.Name(),SYMBOL_DIGITS);
    double price = symbol.Bid();
    double pv = SymbolInfoDouble(symbol.Name(),SYMBOL_TRADE_TICK_VALUE) * SymbolInfoDouble(symbol.Name(),SYMBOL_POINT);
    double tp = NormalizeDouble(price - TP_RETURN*price,digits);
    double sl = NormalizeDouble(price + SL_RETURN*price,digits);

    if(check_volume_lot!=0.0) {
        if(check_volume_lot>=check_open_short_lot) {
            for (int i=0; i < MAXTRY; i++) {
                PrintFormat("Try sell: %dth",i);
                symbol.RefreshRates();
                if(m_trade.Sell(check_open_short_lot,symbol.Name(),symbol.Bid(),sl,tp,cmt)) {

                    if(m_trade.ResultDeal()==0) {
                        Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                        //PrintResult(m_trade,symbol);
                    } else {
                        Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                        //PrintResult(m_trade,symbol);
                        return m_trade.ResultOrder();
                        break;
                    }
                } else {
                    Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                          ", description of result: ",m_trade.ResultRetcodeDescription());
                    //PrintResult(m_trade,symbol);
                }
                Sleep(SLEEP_MS);
            }
        } else {
            Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
                  "< \"Lots\" (",DoubleToString(check_open_short_lot,2),")");
            return 0;
        }
    } else {
        Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
        return 0;
    }
//---
   return 0;
}

void closeAllPos()
{
   while (PositionsTotal()>0) {
      for (int i = PositionsTotal()-1; i>=0; i--) {
         if (m_position.SelectByIndex(i)) {
               ulong ticket = m_position.Ticket();
               m_trade.PositionClose(ticket);
         }
      }
   }
}