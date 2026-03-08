//+------------------------------------------------------------------+
//|                                                    GARGANTUA.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link "https://www.mql5.com"
#property version "1.00"
#property tester_indicator "Free Indicators\\Keltner Channel"

// Definição da estratégia
#define ESTRATEGIA "GARGANTUA_251222" // Nome do robô
#define MAGIC_NUMBER 353799           // Identificador do robô (Precisa ser um número único)

//Definição das operações
input string ConfiguracaoOperacao = "";          // ----------------Configuração da operação
input int QtdContratosEntrada = 1;               // Quantidade de contratos na entrada
input int AlvoFinanceiro = 40;                   // Valor do alvo em reais
input int PerdaFinanceira = 600;                // Valor do stop em reais
input float TamanhoTick = 5;                     // Tamanho do tick (ex: 5 para WIN, 0.5 para WDO)

input string ConfiguracaoGradiente = ""; // ----------------Configuração do gradiente
input int DistanciaEntreNiveis = 60;     // Distância entre níveis de entrada (em pontos)
input int QtdNiveis = 3;                 // Quantidade de níveis de entrada (1 a 10)
input int Nivel1 = 1;                    // Nível 1
input int Nivel2 = 2;                    // Nível 2
input int Nivel3 = 3;                    // Nível 3
input int Nivel4 = 4;                    // Nível 4
input int Nivel5 = 5;                    // Nível 5
input int Nivel6 = 6;                    // Nível 6
input int Nivel7 = 7;                    // Nível 7
input int Nivel8 = 8;                    // Nível 8
input int Nivel9 = 9;                    // Nível 9
input int Nivel10 = 10;                  // Nível 10

//Inicialização das variável de data
MqlDateTime dt;

// Definição dos handlers
int handleKeltner;
double KeltnerChannelUpper[];
double KeltnerChannelLower[];

//Definição das libs
#include <Calendario.mqh>
#include <Entradas.mqh>
#include <Operacao.mqh>
#include <Coloracao.mqh>
//
#include "Horario.mqh"
#include "Sinal.mqh"


//Configuracao gradiente
int Nivel[] = {Nivel1, Nivel2, Nivel3, Nivel4, Nivel5, Nivel6, Nivel7, Nivel8, Nivel9, Nivel10};

//Definição das variáveis globais
double PosicaoAntiga = 0;
double PrecoVendaOriginal = 0;
double PrecoCompraOriginal = 0;

datetime HorarioDeEntradaOperacao = {0};
datetime HorarioLimiteDeEntradaOperacao = {0};
datetime HorarioEncerramentoOperacao = {0};

//Controle de mudança de candle com sinal ativo
double AberturaAntiga = 0;
MqlDateTime HorarioInicioAguardo = {0}; // Variável temporária para armazenar a data e hora que as posições foram encerradas
bool AguardandoApagarOrdens = false;

//Controle
bool DeveAtualizarAlvoStop = false;
bool DeveCriarGradiente = false;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(60);

   InitCTrade();

   ColorirFundo();

//--- Inicializa os canais de keltner
   if(InitKeltnerChannel() != INIT_SUCCEEDED)
     {
      printf("Falha ao inicializar os canais de keltner.");
      return (INIT_FAILED);
     }
   printf("Keltner Channel inicializado com sucesso");
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   PreparaKeltnerChannel();
//
   Comment(
      ESTRATEGIA, "\n",
      "Qtd Posicao: ", PositionsTotal(), "\n",
      "Qtd Ordem: ", OrdersTotal(), "\n",
      "Gatilho de entrada: ", GatilhoDeEntrada(), "\n",
      "Sinal de venda: ", SinalDeVenda(), "\n",
      "Sinal de compra: ", SinalDeCompra(), "\n",
      "EA rodando - Último tick: ", TimeToString(TimeCurrent(), TIME_SECONDS)
   );
//

   if(HouveAlteracaoDePosicao())
     {
      printf("#####Posição foi alterada de %.2f para %.2f", PosicaoAntiga, Position());

      if((PosicaoAntiga != 0) && (Position() == 0))
        {
         printf("Posição encerrada");
         CancelPendingOrders();
        }

      if((PosicaoAntiga == 0) && (Position() < 0))
        {
         printf("Primeira entrada de venda com %.2f contratos", Position());
         DeveAtualizarAlvoStop = true;
         DeveCriarGradiente = true;
        }

      if((PosicaoAntiga == 0) && (Position() > 0))
        {
         printf("Primeira entrada de compra com %.2f contratos", Position());
         DeveAtualizarAlvoStop = true;
         DeveCriarGradiente = true;
        }

      if((PosicaoAntiga > 0) && (Position() > PosicaoAntiga))
        {
         printf("Nível de gradiente comprado com %.2f contratos", QtdContratosEntrada);
         DeveAtualizarAlvoStop = true;
        }

      PosicaoAntiga = Position();

     }
//

   if(DeveAtualizarAlvoStop)
     {
      if(IsSold())
        {
         //double PrecoStop = GetAveragePrice() + (PerdaFinanceira * TamanhoTick) / SellPosition();
         //double PrecoAlvo = GetAveragePrice() - (AlvoFinanceiro * TamanhoTick) / SellPosition();
         //AtualizaAlvoeStop(PrecoStop, PrecoAlvo, "ordem de venda");
        }
      //
      if(IsBought())
        {
         double PrecoStop = GetAveragePrice() - (PerdaFinanceira * TamanhoTick) / BuyPosition();
         double PrecoAlvo = GetAveragePrice() + (AlvoFinanceiro * TamanhoTick) / BuyPosition();
         AtualizaAlvoeStop(PrecoStop, PrecoAlvo, "ordem de compra");
        }
      DeveAtualizarAlvoStop = false;
     }

/////////////////////////////////////////////////////////////////////////////////////////////////

if(DeveCriarGradiente)
  {
   if(IsSold())
     {
      if(QtdNiveis != 0)
        {
         printf("Criando gradiente de venda...");
         for(int i = 0; i < QtdNiveis; i++)
           {
            double PrecoVendaGradiente = PrecoVendaOriginal + (DistanciaEntreNiveis * (i + 1));
            SellLimit(QtdContratosEntrada * Nivel[i], PrecoVendaGradiente, "Ordem de venda nível " + (string)(i + 1));
           }
        }
     }
   //
   if(IsBought())
     {
      if(QtdNiveis != 0)
        {
         printf("Criando gradiente de compra...");
         for(int i = 0; i < QtdNiveis; i++)
           {
            double PrecoCompraGradiente = PrecoCompraOriginal - (DistanciaEntreNiveis * (i + 1));
            BuyLimit(QtdContratosEntrada * Nivel[i], PrecoCompraGradiente, "Ordem de compra nível " + (string)(i + 1));
           }
        }
     }
   DeveCriarGradiente = false;
  }

/////////////////////////////////////////////////////////////////////////////////////////////////

   if(GatilhoDeEntrada())
     {
      if(SinalDeVenda())
        {
         PrecoVendaOriginal = iLow(_Symbol, _Period, 1);
         AberturaAntiga = iOpen(_Symbol, _Period, 1);
         // if(iClose(_Symbol, _Period, 0) >= PrecoVendaOriginal)
         //   SellStop(QtdContratosEntrada, PrecoVendaOriginal, "SELL STOP de entrada de venda");
         // else
         //    SellLimit(QtdContratosEntrada, PrecoVendaOriginal, "SELL LIMIT de entrada de venda");
        }

      if(SinalDeCompra())
        {
         PrecoCompraOriginal = NormalizarPreco(iHigh(_Symbol, _Period, 1));
         AberturaAntiga = iOpen(_Symbol, _Period, 1);
         if(iClose(_Symbol, _Period, 0) <= PrecoCompraOriginal)
            BuyStop(QtdContratosEntrada, PrecoCompraOriginal, "BUY STOP de entrada de compra");
         else
            BuyLimit(QtdContratosEntrada, PrecoCompraOriginal, "BUY LIMIT de entrada de compra");
        }

     }

   AvaliarSinalVerdadeiro(AberturaAntiga);
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   AtualizaHorario();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GatilhoDeEntrada()
  {
   return HorarioPermiteOperacao() && OrdersTotal() == 0 && PositionsTotal() == 0;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HouveAlteracaoDePosicao()
  {
   return PosicaoAntiga != Position();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NormalizarPreco(double preco)
  {
   double tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   return NormalizeDouble(MathRound(preco / tick) * tick, _Digits);
  }
//+------------------------------------------------------------------+
