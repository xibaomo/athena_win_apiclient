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
int sendHistoryMinBars(float &arr[], int len, int minbar_size);
string sendInitTime(string timeString);
string askSymPair();
int sendPairHistX(float &arr[], int len, int n_pts);
float sendPairHistY(float &arr[], int len, int n_pts);
int sendMinPair(string timestr, float x, float y);

int classifyAMinBar(float open,float high, float low, float close, float tickvol, string timeString);
int registerPair(long tx,long ty);
long getPairedTicket(long tx);
int sendCurrentProfit(float profit);
int sendPositionProfit(float profit);
int sendSymbolHistory(float &arr[],int len, string sym);
int athena_finish();
int test_api_server(string hostip, string port);
#import

#define MAX_POS 100
#define MINBAR_SIZE 5
#define MAXTRY 2
#define SLEEP_MS 10000
#define MAX_RAND 32767
#define CURRENT_PERIOD PERIOD_M5
#define STOP_PERCENT 0.05
#define MAX_ALLOWED_POS 200
#define HISTORY_LEN 2000

#define TAKE_PROFIT 5
#define STOP_LOSS -10

CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol_Base;                // symbol info object
CSymbolInfo    m_symbol_Hedge;               // symbol info object
CAccountInfo   m_account;                    // account info wrapper

//--- input parameters
sinput string hostip    = "192.168.1.103";
sinput string port      = "8888";

sinput ulong  m_magic   = 2512554564564;
string              sym_x                = "EURUSD";
string              sym_y                = "USDCZK";

int    buy_tp = 2000;
int    buy_sl  = buy_tp;
int    sell_tp = buy_tp;
int    sell_sl = buy_sl;
double lot_size_x   = 0.02*1;
double lot_size_y = lot_size_x;
float hedge_factor;
double InpVirtualProfit = 5000.0;
int max_pos=0;
string timeBound = "2119.3.22 23:50";
int g_currAction = 0; // 0 - no action, 1 - buy, 2 - sell
int g_posPrev = 0;
//---
ulong m_slippage = 10;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
MqlRates lastRate;
int OnInit()
{
   closeAllPos();
    registerCurrentPositions();
    
    Print("Connecting api server ...");
    athena_init(Symbol(),hostip,port);
    Print("Api server connected");
    
    g_posPrev = PositionsTotal();  
    
    //string symPair = selectPair(); 
    string symPair = askSymPair();
    
    sym_x = StringSubstr(symPair,0,6);
    sym_y = StringSubstr(symPair,7,6);
    PrintFormat("Sym x: %s, Sym y: %s",sym_x,sym_y);
    PrintFormat("LR length: %d",HISTORY_LEN);
    
    if (!m_symbol_Base.Name(sym_x)) {
        PrintFormat("Failed to set symbol name: %s",sym_x);
        return (INIT_FAILED);
    }
    if (!m_symbol_Hedge.Name(sym_y)) {
      PrintFormat("Failed to set symbol name: %s",sym_y);
      return (INIT_FAILED);
    }
    string err_text="";
    if(!CheckVolumeValue(lot_size_x,err_text)) {
        PrintFormat("Volume value check failed: %s",err_text);
        return (INIT_PARAMETERS_INCORRECT);
    }
    // send init time to api server
    MqlRates latestRate[1];
    if (CopyRates(Symbol(),CURRENT_PERIOD,1,1,latestRate) <= 0) {
        Print("Failed to get history latest min bar");
    }

    sendPastMinBars(sym_x,HISTORY_LEN,"x");
    sendPastMinBars(sym_y,HISTORY_LEN,"y");
        
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

int sendPastMinBars(string sym, int histLen, string xy)
{
    MqlRates rates[];
    ArrayResize(rates,histLen);
    if (CopyRates(sym,CURRENT_PERIOD,1,histLen,rates) <= 0) {
        Print("Failed to get history min bars");
        return -1;
    }

    int actualHistLen = histLen;
    int idx=0;
    float data[];
    ArrayResize(data,actualHistLen*MINBAR_SIZE);
    int k=0;
    for (int i=idx; i < histLen; i++) {
        data[k++] = rates[i].open;
        data[k++] = rates[i].high;
        data[k++] = rates[i].low;
        data[k++] = rates[i].close;
        data[k++] = rates[i].tick_volume;
    }

    lastRate = rates[histLen-1];
    PrintFormat("Latest bar: %f,%f,%f,%f,%f",lastRate.open,lastRate.high,lastRate.low,lastRate.close,lastRate.tick_volume);
    PrintFormat("bars to send: %d",actualHistLen);
    
    if (xy == "x")
      sendPairHistX(data,actualHistLen,MINBAR_SIZE);
    if (xy == "y")
      hedge_factor = sendPairHistY(data,actualHistLen,MINBAR_SIZE);

    string t1 = TimeToString(rates[idx+1].time);
    string t2 = TimeToString(rates[histLen-1].time);
    PrintFormat("Min bars sent: %s to %s",t1,t2);
    
    PrintFormat("Hedge factor: %f",hedge_factor);

    ArrayFree(rates);
    ArrayFree(data);

    return actualHistLen;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
    athena_finish();
    Print("athena_finish called");
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

//---
    checkPairProfit();
    if (!m_symbol_Base.RefreshRates() || !m_symbol_Hedge.RefreshRates()) {
        Print("Failed to refresh rates\n");
        return;
    }
    if(isTestEnd()) return;
    
    //inspectAllPositions(m_symbol_Base);

    static datetime prevBar=0;
    datetime time_0 = iTime(0);
    if (time_0 == prevBar)
        return;
    prevBar = time_0;
    
    float pft = IsProfit();//---
    
    sendCurrentProfit(pft);

    MqlRates rates[1];
    if (CopyRates(sym_x,CURRENT_PERIOD,1,1,rates) > 0) {
        string timestr = TimeToString(rates[0].time);
        PrintFormat("%s, open: %f, high: %f, low: %f, close: %f, tickvol: %f",
                    timestr,rates[0].open,rates[0].high, rates[0].low, rates[0].close, rates[0].tick_volume);
    } else {
        PrintFormat("Failed to get the current min bar of %s",sym_x);
    }
    float px = rates[0].open;
    if (CopyRates(sym_y,CURRENT_PERIOD,1,1,rates) > 0) {
        string timestr = TimeToString(rates[0].time);
        PrintFormat("%s, open: %f, high: %f, low: %f, close: %f, tickvol: %f",
                    timestr,rates[0].open,rates[0].high, rates[0].low, rates[0].close, rates[0].tick_volume);
    } else {
        PrintFormat("Failed to get the current min bar of %s",sym_y);
    }
    
    float py = rates[0].open;

    string timestr = TimeToString(rates[0].time);
    int action = sendMinPair(timestr,px,py);
    if (PositionsTotal()>=200) return;
    
    if (action==0) {
      Print("No action");
      return;
    } 
    if ( g_currAction == 0) {
      //closeAllPos();
      //g_currAction = action;
    } else {
      return;
    }
    if (action == 2) {
      PrintFormat("Buy at %f",m_symbol_Base.Ask());
      long tx = OpenBuy(m_symbol_Base,lot_size_x);
      if (tx <= 0) {
         PrintFormat("Failed to place buy postion: %s",m_symbol_Base.Name());
         return;
      }
      double tmp = fabs(hedge_factor)/m_symbol_Hedge.Ask() * lot_size_x;
      //lot_size_y = NormalizeDouble(tmp,2);
      long ty = OpenBuy(m_symbol_Hedge,lot_size_y,IntegerToString(tx));
      
      if (ty <= 0) {
         PrintFormat("Failed to place buy postion: %s",m_symbol_Hedge.Name());
         m_trade.PositionClose(tx);
         return;
      }
      
      registerPair(tx,ty);
   }
   if (action == 1) {
      PrintFormat("Sell at %f",m_symbol_Base.Bid());
      long tx = OpenSell(m_symbol_Base,lot_size_x);
      if (tx <= 0) {
         PrintFormat("Failed to place sell postion: %s",m_symbol_Base.Name());
         return;
      }
      double tmp = fabs(hedge_factor)/m_symbol_Hedge.Ask() * lot_size_x;
      //lot_size_y = NormalizeDouble(tmp,2);
      long ty = OpenSell(m_symbol_Hedge,lot_size_y,IntegerToString(tx));
      
      if (ty <= 0) {
         PrintFormat("Failed to place sell postion: %s",m_symbol_Hedge.Name());
         m_trade.PositionClose(tx);
         return;
      }
      registerPair(tx,ty);
   }
   
   if (action==3) { // close all positions
      closeAllPos();
   }
 
    return;
}

void OnTrade()
{
   HistorySelect(0,TimeCurrent());
   Print("order placed");
   int posCurr = PositionsTotal();
   if (posCurr >= g_posPrev) {
    g_posPrev = posCurr;
    return; // new position created
   }
   
   sendLastProfit();
}

long lastTicket=-1;
//=======================  Private functions ======================================
string selectPair()
{
   int nsym = SymbolsTotal(false);
   PrintFormat("Total symbols: %d",nsym);
   for (int i=0; i < nsym; i++) {
      string sym  = SymbolName(i,false);
      sendSymHist(sym,HISTORY_LEN);
   }
   
   string sympair = askSymPair();
   
   return "";
}
void sendSymHist(string sym, int histLen)
{
    MqlRates rates[];
    ArrayResize(rates,histLen);
    if (CopyRates(sym,CURRENT_PERIOD,1,histLen,rates) <= 0) {
        Print("Failed to get history min bars");
        return;
    }

    int actualHistLen = histLen;
    int idx=0;
    float data[];
    ArrayResize(data,actualHistLen*1);
    int k=0;
    for (int i=idx; i < histLen; i++) {
        data[k++] = rates[i].open;
    }
    
    sendSymbolHistory(data,histLen,sym);

    ArrayFree(rates);
    ArrayFree(data);
}
void registerCurrentPositions()
{
   for(int i=0; i < PositionsTotal(); i++) {
      if (!m_position.SelectByIndex(i)) continue;
      long tx = m_position.Ticket();

      long idx = m_position.Identifier();
      string sty = m_position.Comment();
      if (sty == "") continue;
      long idy = StringToInteger(sty);
      
      if(idy <=0) Alert("Weird ticket");
      registerPair(idx,idy);
   }
}
void checkPairProfit()
{
   
   for (int i=0; i < PositionsTotal();i++) {
      double px=0.,py=0.;
      if(!m_position.SelectByIndex(i)) continue;
      long tx = m_position.Ticket();
      long ty = -1;
      long idx = m_position.Identifier();
      long idy = getPairedTicket(idx);
      if (idy <= 0) {
         if (m_position.Profit() > 0)
            m_trade.PositionClose(m_position.Ticket()); // close if not paired
         continue;
      }
      px = m_position.Profit();
      
      for (int j=0; j < PositionsTotal(); j++) {
         if(!m_position.SelectByIndex(j)) continue;
         if(m_position.Identifier() == idy) {
            py = m_position.Profit();
            ty = m_position.Ticket();
            break;
         }
         if (j == PositionsTotal()-1)
            Alert("Cannot find paried position by ticket");
      }

      if (px+py >= TAKE_PROFIT || px+py <= STOP_LOSS) {
         PrintFormat("Take profit: %f, closing postion pair",px+py); 
         m_trade.PositionClose(tx);
         m_trade.PositionClose(ty);
      }
   }
}

void sendLastProfit()
{
   long tk = HistoryDealGetTicket(HistoryDealsTotal()-1);
   if (tk == lastTicket) return;
   lastTicket = tk;
   switch(HistoryDealGetInteger(HistoryDealGetTicket(HistoryDealsTotal()-1),DEAL_ENTRY))
   {
      case DEAL_ENTRY_IN:
         if (PositionSelect(HistoryDealGetString(HistoryDealGetTicket(HistoryDealsTotal()-1),DEAL_SYMBOL)) == true){
            float pft = HistoryDealGetDouble(HistoryDealGetTicket(HistoryDealsTotal()-1),DEAL_PROFIT);
            if (pft>0)
            sendPositionProfit(pft);
         }
         else {
            float pft = HistoryDealGetDouble(HistoryDealGetTicket(HistoryDealsTotal()-1),DEAL_PROFIT);
            sendPositionProfit(pft);
         }
         break;
      case DEAL_ENTRY_OUT:
         if (PositionSelect(HistoryDealGetString(HistoryDealGetTicket(HistoryDealsTotal()-1),DEAL_SYMBOL)) == true){
            float pft = HistoryDealGetDouble(HistoryDealGetTicket(HistoryDealsTotal()-1),DEAL_PROFIT);
            sendPositionProfit(pft);
         }
         else {
            float pft = HistoryDealGetDouble(HistoryDealGetTicket(HistoryDealsTotal()-1),DEAL_PROFIT);
            sendPositionProfit(pft);
         }
         break;
      default:
         Alert("Reverse position. Not supported");
         break;
   }
}
//+------------------------------------------------------------------+
//| Get Time for specified bar index                                 |
//+------------------------------------------------------------------+
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=CURRENT_PERIOD)
{
    if(symbol==NULL)
        symbol=m_symbol_Base.Name();
    if(timeframe==0)
        timeframe=Period();
    datetime Time[1];
    datetime time=0; // D'1970.01.01 00:00:00'
    int copied=CopyTime(symbol,timeframe,index,1,Time);
    if(copied>0)
        time=Time[0];
    return(time);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates(CSymbolInfo &m_symbol)
{
//--- refresh rates
    if(!m_symbol.RefreshRates()) {
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
    if(volume<min_volume) {
        error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
        return(false);
    }
//--- maximal allowed volume of trade operations
    double max_volume=m_symbol_Base.LotsMax();
    if(volume>max_volume) {
        error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
        return(false);
    }
//--- get minimal step of volume changing
    double volume_step=m_symbol_Base.LotsStep();
    int ratio=(int)MathRound(volume/volume_step);
    if(MathAbs(ratio*volume_step-volume)>0.0000001) {
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
long OpenBuy(CSymbolInfo &symbol, double lotsize, string cmt="")
{
    double check_open_long_lot=lotsize;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
    double check_volume_lot=m_trade.CheckVolume(symbol.Name(),check_open_long_lot,symbol.Ask(),ORDER_TYPE_BUY);

    int digits = (int)SymbolInfoInteger(symbol.Name(),SYMBOL_DIGITS);
    double price = symbol.Ask();
    double tp = NormalizeDouble(price + STOP_PERCENT*price,digits);
    double sl = NormalizeDouble(price - STOP_PERCENT*price,digits);
    

    if(check_volume_lot!=0.0) {
        if(check_volume_lot>=check_open_long_lot) {
            for (int i=0; i < MAXTRY; i++) {
                PrintFormat("Try buy: %dth",i);
                symbol.RefreshRates();
                if(m_trade.Buy(check_open_long_lot,symbol.Name(),symbol.Ask(),sl,tp,cmt)) {

                    if(m_trade.ResultDeal()==0) {
                        Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                        PrintResult(m_trade,symbol);
                    } else {
                        Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                        PrintResult(m_trade,symbol);
                        return m_trade.ResultOrder();
                        break;
                    }
                }

                else {
                    Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                          ", description of result: ",m_trade.ResultRetcodeDescription());
                    PrintResult(m_trade,symbol);
                }
                Sleep(SLEEP_MS);
            }
        } else {
            Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
                  "< \"Lots\" (",DoubleToString(check_open_long_lot,2),")");
            return -1;
        }
    } else {
        Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
        return -1;
    }
//---r
   return -1;
}

//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
long OpenSell(CSymbolInfo &symbol,double lotsize, string cmt="")
{
    double check_open_short_lot=lotsize;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
    double check_volume_lot=m_trade.CheckVolume(symbol.Name(),check_open_short_lot,symbol.Bid(),ORDER_TYPE_SELL);

    int digits = (int)SymbolInfoInteger(symbol.Name(),SYMBOL_DIGITS);
    double price = symbol.Bid();
    double ask  = symbol.Ask();
    double pv = SymbolInfoDouble(symbol.Name(),SYMBOL_TRADE_TICK_VALUE) * SymbolInfoDouble(symbol.Name(),SYMBOL_POINT);
    double tp = NormalizeDouble(price - STOP_PERCENT*price,digits);
    double sl = NormalizeDouble(price + STOP_PERCENT*price,digits);

    if(check_volume_lot!=0.0) {
        if(check_volume_lot>=check_open_short_lot) {
            for (int i=0; i < MAXTRY; i++) {
                PrintFormat("Try sell: %dth",i);
                symbol.RefreshRates();
                if(m_trade.Sell(check_open_short_lot,symbol.Name(),symbol.Bid(),sl,tp,cmt)) {

                    if(m_trade.ResultDeal()==0) {
                        Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                        PrintResult(m_trade,symbol);
                    } else {
                        Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                        PrintResult(m_trade,symbol);
                        return m_trade.ResultOrder();
                        break;
                    }
                } else {
                    Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                          ", description of result: ",m_trade.ResultRetcodeDescription());
                    PrintResult(m_trade,symbol);
                }
                Sleep(SLEEP_MS);
            }
        } else {
            Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
                  "< \"Lots\" (",DoubleToString(check_open_short_lot,2),")");
            return -1;
        }
    } else {
        Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
        return -1;
    }
//---
   return -1;
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
    //DebugBreak();
}
//+------------------------------------------------------------------+
float IsProfit()
{
    double total_profit=0.0;
    int num_pos = PositionsTotal();
    if (max_pos < num_pos) max_pos = num_pos;
    PrintFormat("Total positions: %d, Max pos: %d",num_pos,max_pos);
    
    for(int i=PositionsTotal()-1; i>=0; i--) { // returns the number of current positions
        if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
            if((m_position.Symbol()==m_symbol_Base.Name() ) && m_position.Magic()==m_magic) {
                total_profit=total_profit+m_position.Commission()+m_position.Swap()+m_position.Profit();
            }
    }
    PrintFormat("Total profit: %f",total_profit);
    
    if(total_profit>InpVirtualProfit) {
        PrintFormat("Total profit higher than %f, closing all positions...",InpVirtualProfit);
        for(int j=PositionsTotal()-1; j>=0; j--) { // returns the number of current positions
            if(m_position.SelectByIndex(j)) {// selects the position by index for further access to its properties
                if((m_position.Symbol()==m_symbol_Base.Name()) && m_position.Magic()==m_magic) {
                    datetime t_cur = TimeCurrent();
                    datetime t_pos = m_position.Time();
                    if (t_cur - t_pos < 5*60) continue; // close positions older than 10 min
                    //if (m_position.Profit() < 0.1) continue;
                    m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
                    PrintFormat("Position closed: %d",m_position.Ticket());
                }
            }
        }
        
    }
    return total_profit;
}

void closeMostProfitPos()
{
   double max_profit = 0.;
   int ticket = -1;
   for (int i = PositionsTotal()-1; i>=0; i--) {
      if (m_position.SelectByIndex(i)) {
         if (m_position.Profit() > max_pos) {
            max_profit = m_position.Profit();
            ticket = m_position.Ticket();
         }
      }
   }
   if (ticket >= 0) {
      m_trade.PositionClose(ticket);
      PrintFormat("Position closed. Profit: %f, ticket %d",max_profit,ticket);
   }
}

void closeAllPos()
{
   int ticket = -1;
   for (int i = PositionsTotal()-1; i>=0; i--) {
      if (m_position.SelectByIndex(i)) {
            ticket = m_position.Ticket();
            m_trade.PositionClose(ticket);
      }
   }
}
void inspectAllPositions(CSymbolInfo& symbol)
{
   PrintFormat("Inspect all positions: %d",PositionsTotal());
   MqlTick last_tick;
   float ask,bid;
   if (SymbolInfoTick(symbol.Name(),last_tick)) {
      ask = last_tick.ask;
      bid = last_tick.bid;
   }
   Print("last tick obtained");
   for (int i = PositionsTotal()-1;i >=0; i++) {
      if (m_position.SelectByIndex(i)) {
         
         if (m_position.Symbol() != symbol.Name()) continue;
         PrintFormat("%s,%s",m_position.Symbol(),symbol.Name());
         
         if (m_position.PositionType() == POSITION_TYPE_BUY && bid > 0.) {
            PrintFormat("check buy position, bid: %f",bid);
            
            if (m_position.TakeProfit() <= bid || m_position.StopLoss() >= bid) {
               m_trade.PositionClose(m_position.Ticket());
               PrintFormat("Position closed: %d",m_position.Ticket());
            }
            Print("check buy position done");
         }
         if (m_position.PositionType() == POSITION_TYPE_SELL && ask > 0.) {
            PrintFormat("Check sell position, ask: %f",ask);
            if (m_position.TakeProfit() >= ask || m_position.StopLoss() <= ask) {
               m_trade.PositionClose(m_position.Ticket());
               PrintFormat("Position closed: %d",m_position.Ticket());
            }
            Print("check sell position done");
         }
      }
   }
}

bool isTestEnd()
{
   datetime t_current = TimeCurrent();
   datetime time_bound = StringToTime(timeBound);
   if (t_current - time_bound >=0)
      return true;
      
   return false;
}