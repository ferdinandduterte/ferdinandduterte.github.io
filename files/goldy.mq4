

#property copyright "Copyright 2020, sarce"
#property link      "sarce"
#property version   "1.00"

#include      <stdlib.mqh>

//=========================================================================================================================||
long     NomorAccount   = 0; //lock numb account . value 0 for no lock
string   NamaAccount    = "abcd"; //lock name . value abcd for no lock
datetime Expired        = D'23.01.2021';   // expired date setting
//=========================================================================================================================||

enum TimeFrame{
   current=0,     //current chart
   M1=1,          //M1
   M5=5,          //M5
   M15=15,        //M15
   M30=30,        //M30
   H1=60,         //H1
   H4=240,        //H4
   D1=1440,       //D1
   };
   
enum style {
   Normal = 0,
   Reverse = 1,
};


extern string  StartTime       = "00:00";
extern string  EndTime         = "23:59";
input style TradingStyle       = Normal;
input TimeFrame TF             = M5; //Trade only on TimeFrame
extern int     TPFirst         = 250;
extern int     RangeMinimal    = 250;
extern double  Lots            = 0.05; 
extern double  LotMultiply     = 1.4;
extern double  TPByCandle      = 0.5;
extern int     MaxOP           = 99;
extern double  CloseAllTrade   = 50000;
extern int     MagicNumber     = 12345;

extern string  SettingMA       = "--------------";
extern int     PeriodMA       = 200;
extern int     Shift          = 0;
extern ENUM_MA_METHOD MAMethod   = MODE_SMA;
extern ENUM_APPLIED_PRICE Applyto = PRICE_CLOSE;

bool           ShowInfo        = true;
int            Corner          = 1;              
int            PT              = 1,
               DIGIT,SlipPage;
double         POINT;  
int            xnumb           = 2147483647;
static datetime timeTradebuy;
static datetime timeTradesell;
long           useticket[];
string         comment_av      = "goldy";
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   timeTradebuy = candleTime(0);
   timeTradesell = candleTime(0);
   SlipPage = 4;
   AutoDigit(); 
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DelObject();
   Comment(""); 
}
//+------------------------------------------------------------------+
//| Expert start function                                   |
//+------------------------------------------------------------------+
void OnTick()
{
   if(IsTrade())
   {
      int eastate = 0;
      if(AccountNumber()!=NomorAccount && NomorAccount > 0)
      {
         Comment("Wrong account number");
         eastate = 1;
      }
      
      if(AccountName()!=NamaAccount && NamaAccount != "abcd")
      {
         Comment("Wrong account name");
         eastate = 1;
      }
      
      if(TimeCurrent() >= Expired)
      {
         Comment("EA Expired");
         eastate = 1;
      }
      if(eastate == 0)
      {
         if(TotalProfit() <= CloseAllTrade*-1 && CloseAllTrade > 0)
         {
            while(TotalOrder()> 0)
            {
               CloseOrder();
            }
         }
         settp();
         SetupTrade();
         av();
         if(TotalOrder(0) > 1)TPModif(0,0);
         if(TotalOrder(1) > 1)TPModif(1,0);
         DisplayShow();
         timeTradebuy  = candleTime(0);
         timeTradesell = candleTime(0);
      }
	}
}
//========================================

void SetupTrade()
{
   //bool buy1   = close(1) > ma(1);
   //bool sell1  = close(1) < ma(1);
   
   
   
     if(TradingStyle==0){
     
     bool buy1   = close(1) > ma(1);
     bool sell1  = close(1) < ma(1);
     
  }
  else if(TradingStyle==1){

     bool buy2   = close(1) < ma(1);
     bool sell2  = close(1) > ma(1); 
  
  }
   
   
   
   string comment = WindowExpertName();
   
   if(statetradetime()==1)
   {
      if(TotalOrder(0)+TotalOrderHistoryBar(0,0)==0)
      {  
         if(buy1 || buy2 )  
         {
            Order(0,comment,AskPrice(),SetupLot());
            timeTradebuy = candleTime(0);
         }   
      }
      
      if(TotalOrder(1)+TotalOrderHistoryBar(1,0)==0)
      {
         if(sell1 || sell2) 
         {
            Order(1,comment,BidPrice(),SetupLot());
            timeTradesell = candleTime(0);
         }
      }
   }
}

datetime candleTime(int shift)
{
   return(iTime(Symbol(),TF,shift));
}

double close(int shift)
{
   return(iClose(Symbol(),TF,shift));
}

double ma(int shift)
{
   return(iMA(Symbol(), TF,PeriodMA,Shift,MAMethod,Applyto,shift));
}

//=======================================

double TotalPips()
{
   double totalPip = 0, pip = 0;
   string date     = TimeToString(TimeCurrent(),TIME_DATE);
   
   for(int i = OrdersHistoryTotal()-1; i >= 0; i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(StringFind(TimeToString(OrderCloseTime(),TIME_DATE),date) != -1)
            {
               if(OrderType() == OP_BUY)
               {
                  pip = (OrderClosePrice()-OrderOpenPrice())/POINT;
                  totalPip += pip;
               }

               if(OrderType() == OP_SELL)
               {
                  pip = (OrderOpenPrice()-OrderClosePrice())/POINT;
                  totalPip += pip;
               }
            }
         }
      }
   }
   
   return(totalPip);
}

int TotalOrder(int ordertype = -1)
{
   int Order = 0;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(ordertype == -1) 
               Order++;
            else if(ordertype == OrderType()) 
               Order++;
         }
      }
   }
   
   return(Order);
}

int TotalOrderBar(int ordertype = -1,int bar = 0)
{
   int Order = 0;

   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && iBarShift(Symbol(),Period(),OrderOpenTime())==0)
         {
            if(ordertype == -1) 
               Order++;
            else if(ordertype == OrderType()) 
               Order++;
         }
      }
   }
   
   return(Order);
}

double SetupLot()
{
   double lot    = 0, firstLot = 0,
          MinLot = MarketInfo(Symbol(),MODE_MINLOT),
          MaxLot = MarketInfo(Symbol(),MODE_MAXLOT); 
      
   for(int i = 0; i < OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            lot = MathMax(lot,OrderLots());
         }
      }
   }
   
   lot = Lots;

   if(MinLot == 0.01)
      firstLot = NormalizeDouble(firstLot,2);  
   else
      firstLot = NormalizeDouble(firstLot,1);
   
   if(lot == 0)
      lot = Lots;
      
   if(lot < MinLot) lot = MinLot;
   if(lot > MaxLot) lot = MaxLot;   
   
   if(MinLot == 0.01)
      lot = NormalizeDouble(lot,2);  
   else
      lot = NormalizeDouble(lot,1);
      
   return(lot);
}

double AskPrice(string symbol = "")
{
   if(symbol == "") symbol = Symbol();
   return(MarketInfo(symbol,MODE_ASK));
}

double BidPrice(string symbol = "")
{
   if(symbol == "") symbol = Symbol();
   return(MarketInfo(symbol,MODE_BID));
}

int StopLevel(string symbol = "")
{
   if(symbol == "") symbol = Symbol();
   return(MarketInfo(symbol,MODE_STOPLEVEL));
}

string OrderCmd(int ordertype)
{
   string label;

   switch(ordertype)
   {
      case 0: label = "Buy";        break;
      case 1: label = "Sell";       break;
      case 2: label = "Buy Limit";  break;
      case 3: label = "Sell Limit"; break;
      case 4: label = "Buy Stop";   break;
      case 5: label = "Sell Stop";  break;
   }

   return(label);
}

int Order(int ordertype, string comment, double price, double lot)
{
   int             ticket;
   double          sl = 0, tp = 0;
   color           clrs = clrRed;
   
   if(ordertype == 0 || ordertype == OP_BUYSTOP || ordertype == OP_BUYLIMIT)clrs = clrBlue;
   
   if(ordertype == OP_BUY || ordertype == OP_BUYSTOP || ordertype == OP_BUYLIMIT)  
   {
      if(TPFirst > 0 && TotalOrder(0)==0) tp = NormalizeDouble(price+(TPFirst*POINT),DIGIT);      
   }
   
   if(ordertype == OP_SELL || ordertype == OP_SELLSTOP || ordertype == OP_SELLLIMIT) 
   {
      if(TPFirst > 0 && TotalOrder(1)==0) tp = NormalizeDouble(price-(TPFirst*POINT),DIGIT);      
   }
              
   ticket = OrderSend(Symbol(),ordertype,lot,price,SlipPage,sl,tp,comment,MagicNumber,0,clrs);
   if(ticket == -1) ShowError("Order " + OrderCmd(ordertype));
   
   return(ticket);
}

void CloseOrder(int ordertype = -1)
{   
   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(ordertype == -1)
            {
               if(OrderType() == OP_BUY) 
               {     
                  if(!OrderClose(OrderTicket(),OrderLots(),BidPrice(OrderSymbol()),SlipPage,Blue)) ShowError("Close " + OrderCmd(OrderType())); 
               }
               else if(OrderType() == OP_SELL)
               {      
                  if(!OrderClose(OrderTicket(),OrderLots(),AskPrice(OrderSymbol()),SlipPage,Red)) ShowError("Close " + OrderCmd(OrderType()));
               } 
               else
               {
                  if(!OrderDelete(OrderTicket())) ShowError("Delete Pending Order " + OrderCmd(OrderType()));
               }
            }
            else
            {
               if(OrderType() == ordertype)
               {
                  if(ordertype == OP_BUY)
                  {   
                     if(!OrderClose(OrderTicket(),OrderLots(),BidPrice(OrderSymbol()),SlipPage,Blue)) ShowError("Close " + OrderCmd(OrderType()));
                  } 
                  else if(ordertype == OP_SELL)   
                  {
                     if(!OrderClose(OrderTicket(),OrderLots(),AskPrice(OrderSymbol()),SlipPage,Red)) ShowError("Close " + OrderCmd(OrderType()));
                  } 
                  else
                  {
                     if(!OrderDelete(OrderTicket())) ShowError("Delete Pending Order " + OrderCmd(OrderType()));
                  }
               }
            }
         }
      }
   }
}

void CloseOrderbyTicket(int ordertype = -1,long ticket = 0)
{   
   for(int i = OrdersTotal()-1; i >= 0; i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderTicket()==ticket)
         {
            if(ordertype == -1)
            {
               if(OrderType() == OP_BUY) 
               {     
                  if(!OrderClose(OrderTicket(),OrderLots(),BidPrice(OrderSymbol()),SlipPage,Blue)) ShowError("Close " + OrderCmd(OrderType())); 
               }
               else if(OrderType() == OP_SELL)
               {      
                  if(!OrderClose(OrderTicket(),OrderLots(),AskPrice(OrderSymbol()),SlipPage,Red)) ShowError("Close " + OrderCmd(OrderType()));
               } 
               else
               {
                  if(!OrderDelete(OrderTicket())) ShowError("Delete Pending Order " + OrderCmd(OrderType()));
               }
            }
            else
            {
               if(OrderType() == ordertype)
               {
                  if(ordertype == OP_BUY)
                  {   
                     if(!OrderClose(OrderTicket(),OrderLots(),BidPrice(OrderSymbol()),SlipPage,Blue)) ShowError("Close " + OrderCmd(OrderType()));
                  } 
                  else if(ordertype == OP_SELL)   
                  {
                     if(!OrderClose(OrderTicket(),OrderLots(),AskPrice(OrderSymbol()),SlipPage,Red)) ShowError("Close " + OrderCmd(OrderType()));
                  } 
                  else
                  {
                     if(!OrderDelete(OrderTicket())) ShowError("Delete Pending Order " + OrderCmd(OrderType()));
                  }
               }
            }
         }
      }
   }
}

double TotalProfit(int type = -1)
{  
   double profit = 0;
   if(TotalOrder() > 0)
   {
      for(int i = 0; i < OrdersTotal(); i++)
      {
         if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
         {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) 
            {
               if(OrderType()==type || type == -1)
               {
                  profit += OrderProfit()+OrderSwap()+OrderCommission();
               }
            }
         }
      }
   }
   
   return(profit);
}

void ShowError(string label)
{
	string Error;
	int    error = GetLastError();
	Error        = StringConcatenate("Terminal: ",TerminalName(),"\n",
	                                  label," error ",error,"\n",
	                                  ErrorDescription(error));
	if(error > 2) 
	{
	  if(IsTesting())
	     Comment(Error);
	  else   
	     Alert(Error);
   }
}
        
void AutoDigit()
{
   POINT = MarketInfo(Symbol(),MODE_POINT);
   DIGIT = MarketInfo(Symbol(),MODE_DIGITS);
   
   if (DIGIT == 3 || DIGIT == 5)
   {
      PT              = 10;
      
      TPFirst        *= 10;
      RangeMinimal   *= 10;
      SlipPage       *= 10;
   }
}

bool IsTrade()
{
   bool trade = true;
   
   if(!IsTesting())
   {
      if(!IsTradeAllowed()) 
      {
         Alert("Allow live trading is disable, press F7, \nselect Common tab, check Allow live trading");
         trade = false;
         Sleep(1000);
      }
   
      if(!IsExpertEnabled()) 
      {
         Alert("Expert Advisor is disable, click AutoTrading button to activate it ");
         trade = false;
         Sleep(1000);
      }   
   }
   
   return(trade);
}

void DelObject(string objectName = "")
{
   for(int i = ObjectsTotal()-1; i >= 0; i--)
	{
	   if(StringFind(ObjectName(i),WindowExpertName()) != -1)
	   {
	   	if(objectName == "")
	  			ObjectDelete(ObjectName(i));
	   	else
	   		if(StringFind(ObjectName(i),objectName) != -1) ObjectDelete(ObjectName(i));
		}
	}
}

void DisplayShow()
{
   if(ShowInfo)
   {
      //DelObject();     
      DisplayInfo("Balance",StringConcatenate("",DoubleToString(AccountBalance(),2)));
      if(AccountMargin() != 0) DisplayInfo("Equity",StringConcatenate("",DoubleToString(AccountEquity(),2)));
      if(AccountMargin() == 0) DisplayInfo("Equity",DoubleToStr(AccountBalance(),2));
      DisplayInfo("Spread",StringConcatenate("",MarketInfo(Symbol(),MODE_SPREAD)));
      if(AccountMargin() != 0)
      {
         DisplayInfo ("Margin",StringConcatenate(DoubleToString((AccountEquity()/AccountMargin())*100,2),"%"));
      }
      if(AccountMargin() == 0)
      {
         DisplayInfo ("Margin","-");
      }
      DisplayInfo("Profit",StringConcatenate("",DoubleToString(TotalProfit(),2)));
   }
}  

void DisplayInfo(string name, string value)
{
   color      LabelColor      = White,
              BackgroundColor = DarkGreen;
   string     Font            = "Arial", name1,name2,name3;
   int        FontSize        = 9,
              Space           = 15, 
              X1,X2,X3;
   static int Y;
           
   if(name == "Balance") Y = 30;
   else                  Y += Space;
   if(Corner % 2 == 0) {X1 = 10; X2 = 70; X3 = 80;}
   else                {X1 = 90; X2 = 80; X3 = 10;}
   
   string dot = ":";
   if(value == "")
   {
      dot = "";
      X1 = 10;
   }
             
   if(name != "")
   {        
      name1 = StringConcatenate(WindowExpertName(),name);
      name2 = StringConcatenate(WindowExpertName(),name,":");
      name3 = StringConcatenate(WindowExpertName(),name,"Value");
      
      ObjectDelete(name3);

      ObjectCreate(name1,OBJ_LABEL,0,0,0);           
      ObjectCreate(name2,OBJ_LABEL,0,0,0);      
      ObjectCreate(name3,OBJ_LABEL,0,0,0);
            
      ObjectSetText(name1,name,FontSize,Font, LabelColor); 
      ObjectSetText(name2,dot,FontSize,Font,LabelColor); 
      ObjectSetText(name3,value,FontSize,Font,LabelColor);
            
      ObjectSet(name1,OBJPROP_CORNER,Corner);      
      ObjectSet(name2,OBJPROP_CORNER,Corner); 
      ObjectSet(name3,OBJPROP_CORNER,Corner);
            
      ObjectSet(name1,OBJPROP_XDISTANCE, X1);       
      ObjectSet(name2,OBJPROP_XDISTANCE, X2);  
      ObjectSet(name3,OBJPROP_XDISTANCE, X3);
            
      ObjectSet(name1,OBJPROP_YDISTANCE,Y);        
      ObjectSet(name2,OBJPROP_YDISTANCE,Y);   
      ObjectSet(name3,OBJPROP_YDISTANCE,Y);
   }
}

double last_price(int ordertype = -1)
{
   int i;
   double price;
   for(i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS)&&OrderType()==ordertype) 
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         price = NormalizeDouble(OrderOpenPrice(),DIGIT);
      }
   }
   return(price);
}

double last_lot(int ordertype = -1)
{
   int i;
   double lot;
   for(i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS)&&OrderType()==ordertype) 
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         lot = OrderLots();
      }
   }
   return(lot);
}

void av()
{
   double price,lot;
   if(TotalOrder(0) > 0 && TotalOrderBar(0,0)==0 && TotalOrder(0) < MaxOP)
   {
      price = NormalizeDouble(last_price(0)-(RangeMinimal*POINT),DIGIT);
      lot   = NormalizeDouble(last_lot(0)*LotMultiply,2);
      if(LotMultiply > 1 && lot == last_lot(0))
      {
         lot+=0.01;
      } 
      
      if(AskPrice() <= price && close(1) <= price)
      {
         if(Order(0,comment_av,AskPrice(),lot)!=-1)
         {
            timeTradebuy = candleTime(0);
         }
      }
   }
   
   if(TotalOrder(1) > 0 && TotalOrderBar(1,0)==0 && TotalOrder(1) < MaxOP)
   {
      price = NormalizeDouble(last_price(1)+(RangeMinimal*POINT),DIGIT);
      lot   = NormalizeDouble(last_lot(1)*LotMultiply,2);
      if(LotMultiply > 1 && lot == last_lot(1))
      {
         lot+=0.01;
      } 
      
      if(BidPrice() >= price && close(1) >= price)
      {
         if(Order(1,comment_av,BidPrice(),lot)!=-1)
         {
            timeTradesell = candleTime(0);
         }
      }
   }
}

int TotalOrderHistoryBar(int ordertype = -1, int bar = 0)
{
   int total = 0;
   
   for(int i = OrdersHistoryTotal()-1; i >= 0; i--)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            int selectbar = iBarShift(Symbol(),Period(),OrderCloseTime());
            
            if(selectbar == bar)
            {
               if(ordertype == -1 || OrderType()==ordertype)
               {
                  total += 1;
               }
            }
         }
      }
   }
   return(total);
}

void TPModif(int ordertype = -1, double price = 0)
{
   bool q;
   int i;
   for(i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
      {
         if(OrderType()==ordertype && OrderSymbol()==Symbol() && OrderMagicNumber()==MagicNumber && OrderTakeProfit()!=price)  
           q = OrderModify(OrderTicket(),OrderOpenPrice(),OrderStopLoss(),price,OrderExpiration(),clrWhite);
      }                   
   }
} 

double last_profit(int ordertype = -1)
{
   int i;
   double prof = 0;
   for(i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS)&&OrderType()==ordertype) 
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         prof = OrderProfit()+OrderSwap()+OrderCommission();
      }
   }
   return(prof);
}

string last_com(int ordertype = -1)
{
   int i;
   string com = "";
   for(i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS)&&OrderType()==ordertype) 
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
      {
         com = OrderComment();
      }
   }
   return(com);
}

double profitbyticket(int ordertype = -1,long ticket = 0)
{
   int i;
   double prof = 0;
   for(i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS)&&OrderType()==ordertype) 
      if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderTicket()==ticket)
      {
         prof = OrderProfit()+OrderSwap()+OrderCommission();
      }
   }
   return(prof);
}

double firstprofit(int type)
{
   double prof = 0;
   datetime EarliestOrder = D'2099/12/31';
   
   for (int i = 0; i < OrdersTotal(); i++) 
   {
      if (OrderSelect(i, SELECT_BY_POS)) 
      {
         if (OrderType() == type && OrderSymbol() == Symbol() && OrderMagicNumber()==MagicNumber) 
         {
            if (EarliestOrder > OrderOpenTime()) 
            {
                EarliestOrder = OrderOpenTime();
                prof = OrderProfit()+OrderSwap()+OrderCommission();
            }
         }  
      }
   }      
   return(prof);
}

void settp()
{
   int    count = 0;
   double tot = 0;
   int    i;
   int    totalorder;
   
   if(StringFind(last_com(0),comment_av)!=-1 && last_profit(0)+firstprofit(0) >= TPByCandle && timeTradebuy != candleTime(0))
   {
      totalorder = TotalOrder(0);
      
      tot = last_profit(0)+firstprofit(0);
      setticketarray(0);
      for(i=1; i<=totalorder-2; i++)
      {
         if(tot+profitbyticket(0,useticket[i]) >= TPByCandle)
         {
            tot+=profitbyticket(0,useticket[i]);
            count+=1;
         }
         else
         {
            break;
         }
      }
      
      CloseOrderbyTicket(0,useticket[totalorder-1]);
      for(i=0; i<=count; i++)
      {
         CloseOrderbyTicket(0,useticket[i]);
      }
   }
   
   if(StringFind(last_com(1),comment_av)!=-1 && last_profit(1)+firstprofit(1) >= TPByCandle && timeTradesell != candleTime(1))
   {
      totalorder = TotalOrder(1);
      
      tot = last_profit(1)+firstprofit(1);
      setticketarray(1);
      for(i=1; i<=totalorder-2; i++)
      {
         if(tot+profitbyticket(1,useticket[i]) >= TPByCandle)
         {
            tot+=profitbyticket(1,useticket[i]);
            count+=1;
         }
         else
         {
            break;
         }
      }
      
      CloseOrderbyTicket(1,useticket[totalorder-1]);
      for(i=0; i<=count; i++)
      {
         CloseOrderbyTicket(1,useticket[i]);
      }
   }
}

void setticketarray(int type)
{
   ArrayFree(useticket);
   ArrayResize(useticket,TotalOrder(type));
   int count = 0;
   for(int i=0; i<OrdersTotal(); i++)
   {
      if(OrderSelect(i,SELECT_BY_POS)&&OrderType()==type) 
      {
         if (OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            useticket[count] = OrderTicket();
            count+=1;
         }
      }
   }
}

int statetradetime()
{
   int statetrade = 0;
   
   int count = 1;
   
   string timestring = TimeToStr(TimeCurrent(),TIME_MINUTES|TIME_SECONDS);
   int hour   = StrToInteger(StringSubstr(timestring,0,2));
   int minute = StrToInteger(StringSubstr(timestring,3,2)); 
   
   for(int i=1; i<=1; i++)
   {   
      int starthour   = StrToInteger(StringSubstr(StartTime,0,2));
      int startminute = StrToInteger(StringSubstr(StartTime,3,2));
   
      int endhour     = StrToInteger(StringSubstr(EndTime,0,2));
      int endminute   = StrToInteger(StringSubstr(EndTime,3,2));
      
      bool usetime = true;
      
      if(usetime == true)
      {
         if(starthour <= endhour)
         {
            if(hour == starthour)
            {
               if(starthour != endhour)
               {
                  if(minute >= startminute)
                  {
                     statetrade = 1;
                  }
               }
               if(starthour == endhour)
               {
                  if(minute >= startminute && minute <= endminute)
                  {
                     statetrade = 1;
                  }
               }
            }
            if(hour > starthour)
            {
               if(hour < endhour)
               {
                  statetrade = 1;
               }
               if(hour == endhour && minute <= endminute)
               {
                  statetrade = 1;
               }
            }
         }
      
         if(starthour > endhour)
         {
            if(hour == starthour && minute >= startminute)
            {
               statetrade = 1;
               
            }
            if(hour > starthour)
            {
               statetrade = 1;
               
            }
            if(hour < endhour)
            {
               statetrade = 1;
               
            }
            if(hour == endhour && minute <= endminute)
            {
               statetrade = 1;
            }
         } 
      }
   }
   return(statetrade);
}