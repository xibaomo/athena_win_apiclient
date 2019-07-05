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
int classifyATick(float price, string pos_type);
int classifyAMinBar(float open,float high, float low, float close, float tickvol, string timeString);
int athena_finish();
int test_api_server(string hostip, string port);
#import

#define MAX_POS 200
#define MINBAR_SIZE 5
#define MAXTRY 2
#define SLEEP_MS 10000
#define MAX_RAND 32767
#define CURRENT_PERIOD PERIOD_M5

CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol_Base;                // symbol info object
CSymbolInfo    m_symbol_Hedge;               // symbol info object
CAccountInfo   m_account;                    // account info wrapper

//--- input parameters
sinput string hostip    = "192.168.1.103";
sinput string port      = "8888";

sinput ulong  m_magic   = 2512554564564;
string              InpHedge                = "USDCHF";
int    buy_tp = 200;
int    buy_sl  = 200;
int    sell_tp = 180;
int    sell_sl = 220;
double InpLots   = 0.01;
double InpVirtualProfit = 100.0;
int max_pos=0;
string timeBound = "2119.3.22 23:50";
//---
ulong m_slippage = 10;
long  m_start_time_in_sec = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
MqlRates lastRate;
int OnInit()
{
    Print("Connecting api server ...");
    athena_init(Symbol(),hostip,port);
    MathSrand(GetTickCount());
    Print("Api server connected");

    if (!m_symbol_Base.Name(Symbol())) {
        PrintFormat("Failed to set symbol name: %s",Symbol());
        return (INIT_FAILED);
    }
    if (!m_symbol_Hedge.Name(InpHedge)) {
      PrintFormat("Failed to set symbol name: %s",InpHedge);
      return (INIT_FAILED);
    }
    string err_text="";
    if(!CheckVolumeValue(InpLots,err_text)) {
        PrintFormat("Volume value check failed: %s",err_text);
        return (INIT_PARAMETERS_INCORRECT);
    }
    // send init time to api server
    MqlRates latestRate[1];
    if (CopyRates(Symbol(),CURRENT_PERIOD,1,1,latestRate) <= 0) {
        Print("Failed to get history latest min bar");
    }
    string timestr = TimeToString(latestRate[0].time);
    PrintFormat("Latest min bar: %s",timestr);
    string histTimeStr = sendInitTime(timestr);

    datetime histTime = StringToTime(histTimeStr);
    int histLen = (latestRate[0].time-histTime)/60;
    PrintFormat("%d min bars are requested.",histLen);
    PrintFormat("Latest min bar at server: %s",histTimeStr);

    if (histLen > 0) {
        histLen = sendPastMinBars(histTime,histLen+10);
        PrintFormat("History min bars sent to api server: %d", histLen);
    } else {
         float data[];
         sendHistoryMinBars(data,0,0);
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

int sendPastMinBars(datetime histTime,int histLen)
{
    MqlRates rates[];
    ArrayResize(rates,histLen);
    if (CopyRates(Symbol(),CURRENT_PERIOD,1,histLen,rates) <= 0) {
        Print("Failed to get history min bars");
    }

    // find latest min bar at server
    int k;
    for (k=0; k<histLen; k++) {
        if (rates[k].time == histTime)
            break;
    }
    int actualHistLen = histLen - k;
    int idx=k;
    float data[];
    ArrayResize(data,actualHistLen*MINBAR_SIZE);
    k=0;
    for (int i=idx+1; i < histLen; i++) {
        data[k++] = rates[i].open;
        data[k++] = rates[i].high;
        data[k++] = rates[i].low;
        data[k++] = rates[i].close;
        data[k++] = rates[i].tick_volume;
    }

    lastRate = rates[histLen-1];
    PrintFormat("Latest bar: %f,%f,%f,%f,%f",lastRate.open,lastRate.high,lastRate.low,lastRate.close,lastRate.tick_volume);
    sendHistoryMinBars(data,actualHistLen,MINBAR_SIZE);

    string t1 = TimeToString(rates[idx+1].time);
    string t2 = TimeToString(rates[histLen-1].time);
    PrintFormat("Min bars sent: %s to %s",t1,t2);

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
    if (!m_symbol_Base.RefreshRates() || !m_symbol_Hedge.RefreshRates()) {
        Print("Failed to refresh rates\n");
        return;
    }
    if(isTestEnd()) return;
    
    //inspectAllPositions(m_symbol_Base);

    int action=0;
    static datetime prevBar=0;
    datetime time_0 = iTime(0);
    if (time_0 == prevBar)
        return;
    prevBar = time_0;
    
    int num_pos = IsProfit();//---
    
    if (num_pos == MAX_POS) {
      closeMostProfitPos();
    }

    MqlRates rates[1];
    if (CopyRates(Symbol(),CURRENT_PERIOD,1,1,rates) > 0) {
        string timestr = TimeToString(rates[0].time);
        PrintFormat("%s, open: %f, high: %f, low: %f, close: %f, tickvol: %f",
                    timestr,rates[0].open,rates[0].high, rates[0].low, rates[0].close, rates[0].tick_volume);
    } else {
        Print("Failed to get the last min bar");
    }

    if (rates[0].time==lastRate.time ) {
        Print("Same as last min bar, skip");
        return;
    }

    string timestr = TimeToString(rates[0].time);
    action = classifyAMinBar(rates[0].open,rates[0].high,rates[0].low,rates[0].close, rates[0].tick_volume,timestr);
    
    float oracle = (float)MathRand()/(float)MAX_RAND;
    PrintFormat("Oracle gives %f",oracle);
    //if (oracle > 0.4) return;
    
    if (action == 0) {
        //Print("No action");
        //OpenSell(m_symbol_Base);
        OpenBuy(m_symbol_Base);
    } else if (action == 1) {
        PrintFormat("Buy at %f",m_symbol_Base.Ask());
        //OpenBuy(m_symbol_Base);
        OpenSell(m_symbol_Base);
    } else if (action == 2) {
        PrintFormat("Sell at %f",m_symbol_Base.Bid());
        OpenSell(m_symbol_Base);
    } else {
        PrintFormat("ERROR! Unrecognized action %d",action);
    }

    return;
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
void OpenBuy(CSymbolInfo &symbol)
{
    double check_open_long_lot=InpLots;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
    double check_volume_lot=m_trade.CheckVolume(symbol.Name(),check_open_long_lot,symbol.Ask(),ORDER_TYPE_BUY);

    int digits = (int)SymbolInfoInteger(symbol.Name(),SYMBOL_DIGITS);
    double price = symbol.Ask();
    double tp = NormalizeDouble(price + buy_tp*SymbolInfoDouble(symbol.Name(),SYMBOL_POINT),digits);
    double sl = NormalizeDouble(price - buy_sl*SymbolInfoDouble(symbol.Name(),SYMBOL_POINT),digits);

    if(check_volume_lot!=0.0) {
        if(check_volume_lot>=check_open_long_lot) {
            for (int i=0; i < MAXTRY; i++) {
                PrintFormat("Try buy: %dth",i);
                symbol.RefreshRates();
                if(m_trade.Buy(check_open_long_lot,symbol.Name(),symbol.Ask(),sl,tp)) {

                    if(m_trade.ResultDeal()==0) {
                        Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                        PrintResult(m_trade,symbol);
                    } else {
                        Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                        PrintResult(m_trade,symbol);
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
            return;
        }
    } else {
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

    int digits = (int)SymbolInfoInteger(symbol.Name(),SYMBOL_DIGITS);
    double price = symbol.Bid();
    double tp = NormalizeDouble(price - sell_tp*SymbolInfoDouble(symbol.Name(),SYMBOL_POINT),digits);
    double sl = NormalizeDouble(price + sell_sl*SymbolInfoDouble(symbol.Name(),SYMBOL_POINT),digits);

    if(check_volume_lot!=0.0) {
        if(check_volume_lot>=check_open_short_lot) {
            for (int i=0; i < MAXTRY; i++) {
                PrintFormat("Try sell: %dth",i);
                symbol.RefreshRates();
                if(m_trade.Sell(check_open_short_lot,symbol.Name(),symbol.Bid(),sl,tp)) {

                    if(m_trade.ResultDeal()==0) {
                        Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                        PrintResult(m_trade,symbol);
                    } else {
                        Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                        PrintResult(m_trade,symbol);
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
            return;
        }
    } else {
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
int IsProfit()
{
    double total_profit=0.0;
    int num_pos = PositionsTotal();
    if (max_pos < num_pos) max_pos = num_pos;
    PrintFormat("Total positions: %d, Max pos: %d",num_pos,max_pos);
    
    for(int i=PositionsTotal()-1; i>=0; i--) { // returns the number of current positions
        if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
            if((m_position.Symbol()==m_symbol_Base.Name() || m_position.Symbol()==InpHedge) && m_position.Magic()==m_magic) {
                total_profit=total_profit+m_position.Commission()+m_position.Swap()+m_position.Profit();
            }
    }
    PrintFormat("Total profit: %f",total_profit);
    
    if(total_profit>InpVirtualProfit) {
        PrintFormat("Total profit higher than %f, closing all positions...",InpVirtualProfit);
        for(int j=PositionsTotal()-1; j>=0; j--) { // returns the number of current positions
            if(m_position.SelectByIndex(j)) {// selects the position by index for further access to its properties
                if((m_position.Symbol()==m_symbol_Base.Name() || m_position.Symbol()==InpHedge) && m_position.Magic()==m_magic) {
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
    return num_pos;
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