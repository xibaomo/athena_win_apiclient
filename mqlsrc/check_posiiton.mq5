//+------------------------------------------------------------------+
//|                                               check_posiiton.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int m_counter = 1;
int OnInit()
  {
//---
//---

   checkPositions();
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
   int total = PositionsTotal();
   if (total == 0) {
      if (m_counter%2 == 0)
         placeBuyOrder(m_counter);
      else
         placeSellOrder(m_counter);
        
      m_counter++;
   } else {
      closePosition();
   }
  }
//+------------------------------------------------------------------+
int stopProfitPoint = 50;
int stopLossPoint = 5;
void placeBuyOrder(int id) 
{
   MqlTradeRequest request = {0};
   MqlTradeResult  result = {0};
   
   int digits = (int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS);

   double price = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   request.action = TRADE_ACTION_DEAL;
   request.symbol = Symbol();
   request.volume = 0.1;
   request.type = ORDER_TYPE_BUY;
   request.price = price;
   request.deviation = 3;
   request.magic = id;
   request.tp = NormalizeDouble(price + stopProfitPoint*SymbolInfoDouble(Symbol(),SYMBOL_POINT),digits);
   request.sl = NormalizeDouble(price - stopLossPoint*SymbolInfoDouble(Symbol(),SYMBOL_POINT),digits);
  
   
   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());
}

void placeSellOrder(int id) 
{
   MqlTradeRequest request = {0};
   MqlTradeResult  result = {0};
   
   int digits = (int)SymbolInfoInteger(Symbol(),SYMBOL_DIGITS);
   
   double price = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   request.action = TRADE_ACTION_DEAL;
   request.symbol = Symbol();
   request.volume = 0.1;
   request.type = ORDER_TYPE_SELL;
   request.price = price;
   request.deviation = 3;
   request.magic = id;
   request.tp = NormalizeDouble(price - stopProfitPoint*SymbolInfoDouble(Symbol(),SYMBOL_POINT),digits);
   request.sl = NormalizeDouble(price + stopLossPoint*SymbolInfoDouble(Symbol(),SYMBOL_POINT),digits);
  
   
   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());
}

void checkPositions()
{
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total = PositionsTotal();
   
   for (int i = 0; i< total; i++) {
      ulong position_ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double order_price = PositionGetDouble(POSITION_PRICE_OPEN);
      double cur_price = PositionGetDouble(POSITION_PRICE_CURRENT);
      double cp = SymbolInfoDouble(position_symbol,SYMBOL_BID);
      double cc = SymbolInfoDouble(position_symbol,SYMBOL_ASK);
      printf("");
   }
}

void closePosition()
{
   MqlTradeRequest request;
   MqlTradeResult  result;
   int total = PositionsTotal();
   
   for(int i = 0; i< total; i++) {
   //------- GET info of order
      ulong position_ticket = PositionGetTicket(i);
      string position_symbol = PositionGetString(POSITION_SYMBOL);
      int digits = (int)SymbolInfoInteger(position_symbol,SYMBOL_DIGITS);
      ulong magic = PositionGetInteger(POSITION_MAGIC);
      double volume = PositionGetDouble(POSITION_VOLUME);
      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE) PositionGetInteger(POSITION_TYPE);
      
      //---------------- close position if profit ------------
      ZeroMemory(request);
      ZeroMemory(result);
      request.action = TRADE_ACTION_DEAL;
      request.position = position_ticket;
      request.symbol = position_symbol;
      request.volume = volume;
      request.deviation = 2;
      request.magic = magic;
      bool isClose = false;
      
      double orderPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      if (type == POSITION_TYPE_BUY) {
         double curPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         
         if (curPrice > orderPrice) {
            request.price = SymbolInfoDouble(position_symbol,SYMBOL_BID);
            request.type = ORDER_TYPE_SELL;
            isClose = true;
         }
      } else {
         double curPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
         if (curPrice < orderPrice) {
            request.price = SymbolInfoDouble(position_symbol,SYMBOL_ASK);
            request.type = ORDER_TYPE_BUY;
            isClose = true;
         }
       
      }
      if(isClose && !OrderSend(request,result))
         PrintFormat("Order send error %d", GetLastError());  
   }
}