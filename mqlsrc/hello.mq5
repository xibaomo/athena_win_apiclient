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

               // account info wrapper

//| Expert initialization function                                   |
//+------------------------------------------------------------------+
CSymbolInfo    m_symbol_Base; 
CSymbolInfo    m_symbol_Hedge;
int OnInit()
  {
   if (!m_symbol_Base.Name("EURHKD"))
      Alert("fails to set symbol name");
   m_symbol_Hedge.Name("USDCZK");
   double tx = m_symbol_Base.TickValue();
   double ty = m_symbol_Hedge.TickValue();
   
   double ly = tx/ty/0.1679;
   
   PrintFormat("value of point %f",m_symbol_Base.Point());
   PrintFormat("tick size: %f",m_symbol_Base.TickSize());
   PrintFormat("tick value: %f",m_symbol_Base.TickValue());
   PrintFormat("tick value: %f",m_symbol_Hedge.TickValue());
   PrintFormat("min lots: %f",m_symbol_Base.LotsMin());
   
   PrintFormat("lot size y= %f",ly);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   //athena_finish();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
PrintFormat("tick value: %f",m_symbol_Base.TickValue());
   PrintFormat("tick value: %f",m_symbol_Hedge.TickValue());
   //Print ("new tick ...");
   return;
  }
