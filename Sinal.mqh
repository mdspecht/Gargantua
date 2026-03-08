//+------------------------------------------------------------------+
//|                                                        Sinal.mqh |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

//Definição dos inputs
input string ConfiguracaoKeltnerChannel = "";      // ----------------Configuração dos canais de keltner
input int KeltnerChannel_Periodo = 17;             // Período dos canais de keltner
input double KeltnerChannel_Desvio = 0.8;          // Desvio padrão dos canais de keltner


//+------------------------------------------------------------------+
//| Inicialização dos canais de keltner                                                                 |
//+------------------------------------------------------------------+
int InitKeltnerChannel()
  {
   printf("KeltnerChannel_Periodo: " + (string) KeltnerChannel_Periodo);
   printf("KeltnerChannel_Desvio: " + (string) KeltnerChannel_Desvio);

   handleKeltner = iCustom(
                      _Symbol,
                      _Period,
                      "Free Indicators\\Keltner Channel",
                      KeltnerChannel_Periodo,          // EMA period
                      KeltnerChannel_Periodo,          // ATR period
                      KeltnerChannel_Desvio,         // Multiplier
                      PRICE_CLOSE  // Applied price
                   );


   if(handleKeltner == INVALID_HANDLE)
     {
      printf("Erro ao criar o Keltner Channel");
      return INIT_FAILED;
     }

   return INIT_SUCCEEDED;
  }
//+------------------------------------------------------------------+
//| Prepara série dos canais de keltner                                                                 |
//+------------------------------------------------------------------+
void PreparaKeltnerChannel()
  {
   if(!ArraySetAsSeries(KeltnerChannelUpper, true))
     {
      printf("Erro %d ao definir ArraySetAsSeries para KeltnerChannelUpper", GetLastError());
     }
   if(!ArraySetAsSeries(KeltnerChannelLower, true))
     {
      printf("Erro %d ao definir ArraySetAsSeries para KeltnerChannelLower", GetLastError());
     }

   if(CopyBuffer(handleKeltner, 0, 0, 10, KeltnerChannelUpper) <= 0)
     {
      printf("Erro %d na copia de dados BollingerBandsUpper: ", GetLastError());
     }
   if(CopyBuffer(handleKeltner, 2, 0, 10, KeltnerChannelLower) <= 0)
     {
      printf("Erro %d na copia de dados KeltnerChannelLower: ", GetLastError());
     }
//
//   printf("KeltnerChannelUpper[0]: " + (string) KeltnerChannelUpper[0]);
//   printf("KeltnerChannelUpper[1]: " + (string) KeltnerChannelUpper[1]);
//
//   printf("KeltnerChannelLower[0]: " + (string) KeltnerChannelLower[0]);
//   printf("KeltnerChannelLower[1]: " + (string) KeltnerChannelLower[1]);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SinalDeVenda()
  {
   bool condA = iClose(_Symbol, _Period, 1) < KeltnerChannelLower[1];
   return condA;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SinalDeCompra()
  {
   bool condA =  iClose(_Symbol, _Period, 1) > KeltnerChannelUpper[1];
   return condA;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AvaliarSinalVerdadeiro(double _AberturaAntiga)
  {
   if(SinalDeVenda() == false && HasPosition() == false && HasSellStopPendingOrders() == true)
     {
      printf("Cancelando ordem de entrada, pois o sinal de venda não é mais válido...");
      CancelPendingOrders();
     }

   if(SinalDeCompra() == false && HasPosition() == false && HasBuyStopPendingOrders() == true)
     {
      printf("Cancelando ordem de entrada, pois o sinal de compra não é mais válido...");
      CancelPendingOrders();
     }

   if(HorarioPermiteOperacao() == false && HasPosition() == false && HasSellStopPendingOrders() == true)
     {
      printf("Cancelando ordem de entrada, pois o sinal o horário de operação não é mais válido...");
      CancelPendingOrders();
     }

   if(HorarioPermiteOperacao() == false && HasPosition() == false && HasBuyStopPendingOrders() == true)
     {
      printf("Cancelando ordem de entrada, pois o sinal o horário de operação não é mais válido...");
      CancelPendingOrders();
     }

   if(HasPosition() == false && _AberturaAntiga != iOpen(_Symbol, _Period, 1) && HasPendingOrders() ) //&& AguardandoApagarOrdens == false
     {
      printf("Candle mudou, cancelando ordens pendentes...");
      CancelPendingOrders();
     }
  }
//+------------------------------------------------------------------+
