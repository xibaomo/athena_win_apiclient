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
int request_all_syms(CharArray& arr, int& nsyms);
#import

string timeBound = "2023.2.28 23:10";
string hostip    = "192.168.150.67";
string port      = "8888";
sinput ulong  m_magic   = 2512554564564;
string sym_x = "EURUSD";
double lot_size   = 0.1;
ulong m_slippage = 10;

string g_all_syms[];
int    g_num_syms;

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
   request_all_syms(arr,g_num_syms);
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
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
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