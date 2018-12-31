//+------------------------------------------------------------------+
//|                                                      testdll.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, FXUA"
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>

#import "athena_win_apiclient.dll"
int athena_init(string symbol, string hostip, string port);
int sendHistoryTicks(float &arr[], int len, string pos_type);
int classifyATick(float price, string pos_type);
int athena_finish();
int test_api_server(string hostip, string port);
#import

CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol_Base;                // symbol info object
CSymbolInfo    m_symbol_Hedge;               // symbol info object
CAccountInfo   m_account;                    // account info wrapper

//--- input parameters
sinput string hostip    = "192.168.1.103";
sinput string port      = "8888";
input  double InpLots   = 0.1;
sinput ulong  m_magic   = 2512554564564;
input  int    stopProfitPoint = 100;
input  int    stopLossPoint   = 100;
input  int    tickInterval    = 30;
//---
ulong m_slippage = 10;
long  m_start_time_in_sec = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
  {   
   athena_init(Symbol(),hostip,port);
   Print("Api server connected");
   
   if (!m_symbol_Base.Name(Symbol())) {
      PrintFormat("Failed to set symbol name: %s",Symbol());
      return (INIT_FAILED);
   }
   string err_text="";
   if(!CheckVolumeValue(InpLots,err_text)) {
      PrintFormat("Volume value check failed: %s",err_text);
      return (INIT_PARAMETERS_INCORRECT);
   }
   
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
   athena_finish();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if (!m_symbol_Base.RefreshRates()) {
      Print("Failed to refresh rates\n");
      return;
   }
   int action=0;
   double ask = m_symbol_Base.Ask();
   if (ask > 0) {
      
      static datetime prevBuyTime = TimeCurrent();
      datetime nowBuyTime = TimeCurrent();
      if (nowBuyTime - prevBuyTime < tickInterval)
         return;
      
      //PrintFormat("Valid Buy tick: %f",ask);
      prevBuyTime = nowBuyTime; 
      //action = classifyATick(ask,"buy");
      
      action = 0;
      
      if (action == 1) {
         PrintFormat("buy at %f",ask);
         OpenBuy(m_symbol_Base);
      }  
   }
   
   double bid = m_symbol_Base.Bid();
   if (bid > 0) {
      static datetime prevSellTime = TimeCurrent();
      datetime nowSellTime = TimeCurrent();
      if (nowSellTime - prevSellTime < tickInterval)
         return;
         
      //PrintFormat("Valid Sell tick: %f",bid);
      prevSellTime = nowSellTime;
      action = classifyATick(bid,"sell");
      
      //action =0;
      
      if (action == 2) {
         PrintFormat("Sell at %f",bid);
         OpenSell(m_symbol_Base);
      }
   }
   
   return;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates(CSymbolInfo &m_symbol)
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print("RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
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
//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=m_symbol_Base.LotsMin();
   if(volume<min_volume)
     {
      error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }
//--- maximal allowed volume of trade operations
   double max_volume=m_symbol_Base.LotsMax();
   if(volume>max_volume)
     {
      error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }
//--- get minimal step of volume changing
   double volume_step=m_symbol_Base.LotsStep();
   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                     volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
   return(true);
  }
  
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(CSymbolInfo &symbol)
  {
   double check_open_long_lot=InpLots;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(symbol.Name(),check_open_long_lot,symbol.Ask(),ORDER_TYPE_BUY);

   int digits = (int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS);
   double price = symbol.Ask();
   double tp = NormalizeDouble(price + stopProfitPoint*SymbolInfoDouble(Symbol(),SYMBOL_POINT),digits);
   double sl = NormalizeDouble(price - stopLossPoint*SymbolInfoDouble(Symbol(),SYMBOL_POINT),digits);
   
   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=check_open_long_lot)
        {
         if(m_trade.Buy(check_open_long_lot,NULL,symbol.Ask(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,symbol);
              }
            else
              {
               Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,symbol);
              }
           }
         else
           {
            Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< \"Lots\" (",DoubleToString(check_open_long_lot,2),")");
         return;
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return;
     }
//---
  }
  
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(CSymbolInfo &symbol)
  {
   double check_open_short_lot=InpLots;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(symbol.Name(),check_open_short_lot,symbol.Bid(),ORDER_TYPE_SELL);

   int digits = (int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS);
   double price = symbol.Bid();
   double tp = NormalizeDouble(price - stopProfitPoint*SymbolInfoDouble(Symbol(),SYMBOL_POINT),digits);
   double sl = NormalizeDouble(price + stopLossPoint*SymbolInfoDouble(Symbol(),SYMBOL_POINT),digits);
   
   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=check_open_short_lot)
        {
         if(m_trade.Sell(check_open_short_lot,NULL,symbol.Bid(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,symbol);
              }
            else
              {
               Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,symbol);
              }
           }
         else
           {
            Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< \"Lots\" (",DoubleToString(check_open_short_lot,2),")");
         return;
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return;
     }
//---
  }
  
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResult(CTrade &trade,CSymbolInfo &symbol)
  {
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result: "+trade.ResultRetcodeDescription());
   Print("deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("current bid price: "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("current ask price: "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("broker comment: "+trade.ResultComment());
   DebugBreak();
  }
//+------------------------------------------------------------------+
