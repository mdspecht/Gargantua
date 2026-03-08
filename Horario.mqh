//+------------------------------------------------------------------+
//|                                                      Horario.mqh |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

// Definição dos horários
input string ConfiguracaoHorarioOperacao = "";     // ----------------Configuração dos horários de operação
input int InpHorarioDeEntradaOperacao = 906;       // Horário para entrada em novas operações
input int InpHorarioLimiteDeEntradaOperacao = 940; // Horário limite para entrada em novas operações
input int InpHorarioEncerramentoOperacao = 958;    // Horário para encerrar todas as operações abertas



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HorarioPermiteOperacao()
  {
//   printf("TimeCurrent(): " + (string) TimeCurrent());
//   printf("HorarioDeEntradaOperacao: " + (string) HorarioDeEntradaOperacao);
//   printf("HorarioLimiteDeEntradaOperacao: " + (string) HorarioLimiteDeEntradaOperacao);
//
   bool HorarioEntrada = (TimeCurrent() >= HorarioDeEntradaOperacao) && (TimeCurrent() <= HorarioLimiteDeEntradaOperacao);
   return HorarioEntrada; // && !Payroll(); //&& !Feriado() && !FimDeSemana() && !SuperQuarta() && !IPP()
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AtualizaHorario()
  {
   HorarioDeEntradaOperacao = StringToTime(StringFormat("%02d:%02d", InpHorarioDeEntradaOperacao / 100, InpHorarioDeEntradaOperacao % 100));
   HorarioLimiteDeEntradaOperacao = StringToTime(StringFormat("%02d:%02d", InpHorarioLimiteDeEntradaOperacao / 100, InpHorarioLimiteDeEntradaOperacao % 100));
   HorarioEncerramentoOperacao = StringToTime(StringFormat("%02d:%02d", InpHorarioEncerramentoOperacao / 100, InpHorarioEncerramentoOperacao % 100));
  }
//+------------------------------------------------------------------+
