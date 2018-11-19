//+------------------------------------------------------------------+
//|                                                      testdll.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#import "athena_win_apiclient.dll"
int athena_init(string symbol, string hostip, string port);
int sendHistoryTicks(float &arr[], int len, string pos_type);
int classifyATick(float price, string pos_type);
int athena_finish();
int test_api_server(string hostip, string port);
#import

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
  {
   string hostip = "73.92.253.8";
   string port="8888";
   
   athena_init("EURUSD",hostip,port);
   int a=-1;
   for (int i=0;i<510;i++) {
      a=classifyATick(1.0,"buy");
   }
   
   athena_finish();
   //int a = test_api_server(hostip,port);
   PrintFormat("%d\n",a);
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
