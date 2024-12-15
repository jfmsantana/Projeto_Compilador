/*+----------------------------------------------------------------+
  |           UNIFAL - Universidade Federal de Alfenas.            |
  |             BACHARELADO EM CIÊNCIAS DA COMPUTAÇÃO.               |
  |                                                                |
  |  Trabalho..: Geracao de codigo MIPS                            |
  |  Disciplina: Compiladores                                      |
  |  Professor.: Luiz Eduardo da Silva                             |
  |  Aluno.....: João Felipe Martins Santana                  |
  |  Data......: 07/12/2024                                        |
  +----------------------------------------------------------------+*/

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lexico.c"
#include "utils.c"

int contaVar = 0;
int rotulo = 0;
int tipo;

%}


%token T_PROGRAMA
%token T_INICIO
%token T_FIMPROG
%token T_LEIA
%token T_ESCREVA
%token T_SE
%token T_ENTAO
%token T_SENAO
%token T_FIMSE
%token T_ENQUANTO
%token T_FACA
%token T_FIMENQTO

%token T_MAIS
%token T_MENOS
%token T_VEZES
%token T_DIV

%token T_MAIOR
%token T_MENOR
%token T_IGUAL

%token T_E
%token T_OU
%token T_NAO

%token T_ATRIB
%token T_ABRE
%token T_FECHA

%token T_INTEIRO
%token T_LOGICO
%token T_LITERAL
%token T_V
%token T_F

%token T_IDENTIF
%token T_NUMERO

%start programa

%left T_MAIS T_MENOS
%left T_VEZES T_DIV
%left T_MAIOR T_MENOR T_IGUAL
%left T_E T_OU


%%

programa 
    : cabecalho
    { 
        // INPP
        fprintf(yyout, ".text\n");
        fprintf(yyout, "\t.globl main\n");

    }
     variaveis T_INICIO
    {
        fprintf(yyout, "main:\tnop\n");

    }
    lista_comandos T_FIMPROG
    {
        // int conta = desempilha(); DMEM e T_FIMPROG
        fprintf(yyout, "fim:\tnop\n");
        fprintf(yyout, "\tli $v0, 10\n");
        fprintf(yyout, "\tli $a0, 0\n");
        fprintf(yyout, "\tsyscall\n");
        geraData();
    }
    ;

cabecalho 
    : T_PROGRAMA T_IDENTIF
    ;

variaveis
    :   /* nada */
    | declaracao_variaveis
    ;

declaracao_variaveis
    : tipo lista_variaveis declaracao_variaveis
    | tipo lista_variaveis
    ;

tipo
    : T_INTEIRO 
    {
        tipo = INT;
    }
    | T_LOGICO  
    { 
        tipo = LOG; 
    }
    ;

lista_variaveis
    : lista_variaveis T_IDENTIF 
    { 
        strcpy(elemTab.id, atomo);
        elemTab.end = contaVar++;
        elemTab.tip = tipo;
        insereSimbolo(elemTab);

    }
    | T_IDENTIF                 
    { 
        strcpy(elemTab.id, atomo);
        elemTab.end = contaVar++;
        elemTab.tip = tipo;
        insereSimbolo(elemTab);
        
    }
    ;

lista_comandos
    : lista_comandos comando
    | comando
    | /* nada */
    ;

comando
    : leitura
    | escrita
    | repeticao
    | selecao
    | atribuicao
    ;

leitura
    : T_LEIA T_IDENTIF 
    { 
        buscaSimbolo(atomo);
        // LEIA
        fprintf(yyout, "\tli $v0, 5\n");
        fprintf(yyout, "\tsyscall\n");
        fprintf(yyout, "\tsw $v0, %s\n", atomo); 
    }
    ;

escrita
    : T_ESCREVA expressao
    { 
        int tipo = desempilha();
        // ESCR
        fprintf(yyout, "\tli $v0, 1\n");
        fprintf(yyout, "\tsyscall\n"); 
        fprintf(yyout, "\tla $a0 _ent\n");
        fprintf(yyout, "\tli $v0, 4\n");
        fprintf(yyout, "\tsyscall\n");
    }
    | T_ESCREVA T_LITERAL
    {
        // ESCR
        
        insereLit(atomo);
        fprintf(yyout, "\tla $a0 %s\n", elemLit.id);
        fprintf(yyout, "\tli $v0, 4\n");
        fprintf(yyout, "\tsyscall\n");
    }
    ;

repeticao
    : T_ENQUANTO 
    {
        // ROTULO NADA
        fprintf(yyout, "L%d:\tnop\n", ++rotulo);
        empilha(rotulo);
    }
     expressao T_FACA 
    {
        int tipo = desempilha();
        if(tipo != LOG)
            yyerror("Incompatibilidade de tipos na repeticao");
        // DSVF ROTULO
        fprintf(yyout, "\tbeqz $a0, L%d\n", ++rotulo);
        empilha(rotulo);
    }
     lista_comandos T_FIMENQTO
    {
            int y = desempilha();
            int x = desempilha();
            // fprintf(yyout, "\tDSVS\tL%d\nL%d\tNADA\n", x, y);
        fprintf(yyout, "\tj L%d\n", x);
        fprintf(yyout, "L%d:\tnop\n", y);
    }
    ;

selecao
    : T_SE expressao T_ENTAO 
    {
        int tipo = desempilha();
        if(tipo != LOG)
            yyerror("Incompatibilidade de tipos na selecao");
        // DSVF ROTULO
        fprintf(yyout, "\tbeqz $a0, L%d\n", ++rotulo);
        empilha(rotulo);
    } lista_comandos T_SENAO 
    {
        int x = desempilha();
        // fprintf(yyout, "\tDSVS\tL%d\nL%d\tNADA\n", ++rotulo, x);
        fprintf(yyout, "\tj L%d\n", ++rotulo);
        fprintf(yyout, "L%d:\tnop\n", x);
        empilha(rotulo);
    }
    lista_comandos T_FIMSE
    {
        int x = desempilha();
        fprintf(yyout, "L%d:\tnop\n", x);
    }
    ;

atribuicao
    : T_IDENTIF
    { 
        int pos = buscaSimbolo(atomo);
        empilha(pos);
    }
     T_ATRIB expressao
    {
        int tipo = desempilha();
        int pos = desempilha();
        if(tipo != tabSimb[pos].tip)
            yyerror("Incompatibilidade de tipos");
        fprintf(yyout, "\tsw $a0, %s\n", tabSimb[pos].id);
    }
    ;

expressao
    : expressao T_MAIS 
    {
        fprintf(yyout, "\tsw $a0 0($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp -4\n"); 
    }
    expressao    
    {
        testaTipo(INT, INT, INT); 
        fprintf(yyout, "\tlw $t1 4($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp 4\n"); 
        fprintf(yyout, "\tadd $a0, $t1, $a0\n"); 
    }
    | expressao T_MENOS 
    {
        fprintf(yyout, "\tsw $a0 0($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp -4\n"); 
    }
     expressao   
    {
        testaTipo(INT, INT, INT); 
        fprintf(yyout, "\tlw $t1 4($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp 4\n"); 
        fprintf(yyout, "\tsub $a0, $t1, $a0\n"); 
    }
    | expressao T_VEZES 
    {
        fprintf(yyout, "\tsw $a0 0($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp -4\n"); 
    }
     expressao   
    {
        testaTipo(INT, INT, INT); 
        fprintf(yyout, "\tlw $t1 4($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp 4\n"); 
        fprintf(yyout, "\tmult $t1, $a0\n"); 
        fprintf(yyout, "\tmflo $a0\n"); 
    }
    | expressao T_DIV 
    {
        fprintf(yyout, "\tsw $a0 0($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp -4\n"); 
    }
     expressao     
    {
        testaTipo(INT, INT, INT); 
        fprintf(yyout, "\tlw $t1 4($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp 4\n"); 
        fprintf(yyout, "\tdiv $t1 $a0\n"); 
        fprintf(yyout, "\tmflo $a0\n"); 
    }
    | expressao T_MAIOR 
    {
        fprintf(yyout, "\tsw $a0 0($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp -4\n"); 
    }
    expressao   
    {
        testaTipo(INT, INT, LOG);  
        fprintf(yyout, "\tlw $t1 4($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp 4\n"); 
        fprintf(yyout, "\tslt $a0, $a0, $t1\n"); 
    }
    | expressao T_MENOR 
    {
        fprintf(yyout, "\tsw $a0 0($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp -4\n"); 
    }
    expressao   
    {
        testaTipo(INT, INT, LOG);   
        fprintf(yyout, "\tlw $t1 4($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp 4\n"); 
        fprintf(yyout, "\tslt $a0, $t1, $a0\n"); 
    }
    | expressao T_IGUAL 
    {
        fprintf(yyout, "\tsw $a0 0($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp -4\n"); 
    }
    expressao   
    {
        testaTipo(INT, INT, LOG);   
        fprintf(yyout, "\tlw $t1 4($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp 4\n");
        fprintf(yyout, "\tbeq $a0, $t1, L%d\n", ++rotulo);
        fprintf(yyout, "\tli $a0, 0\n"); 
        fprintf(yyout, "\tj L%d\n", ++rotulo);
        fprintf(yyout, "L%d:\tli $a0, 1\n", rotulo - 1);
        fprintf(yyout, "L%d:\tnop\n", rotulo);   
    }
    | expressao T_E 
    {
        fprintf(yyout, "\tsw $a0 0($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp -4\n"); 
    } expressao       
    {
        testaTipo(LOG, LOG, LOG); 
        fprintf(yyout, "\tlw $t1 4($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp 4\n");
        fprintf(yyout, "\tbeqz $a0, L%d\n", ++rotulo);
        fprintf(yyout, "\tbeqz $t1, L%d\n", rotulo);
        fprintf(yyout, "\tli $a0, 1\n"); 
        fprintf(yyout, "\tj L%d\n", ++rotulo);
        fprintf(yyout, "L%d:\tli $a0, 0\n", rotulo - 1);
        fprintf(yyout, "L%d:\tnop\n", rotulo);  
    }
    | expressao T_OU 
    {
        fprintf(yyout, "\tsw $a0 0($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp -4\n"); 
    } expressao      
    {
        testaTipo(LOG, LOG, LOG); 
        fprintf(yyout, "\tlw $t1 4($sp)\n"); 
        fprintf(yyout, "\taddiu $sp $sp 4\n");
        fprintf(yyout, "\tbnez $a0 L%d\n", ++rotulo);
        fprintf(yyout, "\tbnez $t1 L%d\n", rotulo);
        fprintf(yyout, "\tli $a0, 1\n"); 
        fprintf(yyout, "\tj L%d\n", ++rotulo);
        fprintf(yyout, "L%d:\tli $a0, 0\n", rotulo - 1);
        fprintf(yyout, "L%d:\tnop\n", rotulo); 
    }
    | termo
    ;

termo
    : T_NUMERO      
    { 
        fprintf(yyout, "\tli $a0 %s\n", atomo); 
        empilha(INT);

    }
    | T_IDENTIF     
    { 
        int pos = buscaSimbolo(atomo);
        fprintf(yyout, "\tlw $a0 %s\n", atomo); 
        empilha(tabSimb[pos].tip);
    }
    | T_V           
    { 
        fprintf(yyout, "\tlw $a0 1\n"); 
        empilha(LOG);
    }
    | T_F           
    {
        fprintf(yyout, "\tlw $a0 0\n");
        empilha(LOG);
    }
    | T_NAO termo   
    {
        int x = desempilha();
        if(x != LOG)
            yyerror("Incompatibilidade de tipos");
        // NEGA
        // fprintf(yyout, "\tlw $t1 4($sp)\n"); 
        // fprintf(yyout, "\taddiu $sp $sp 4\n");
        fprintf(yyout, "\tbeqz $a0, L%d\n", ++rotulo);
        fprintf(yyout, "\tli $a0, 0\n"); 
        fprintf(yyout, "\tj L%d\n", ++rotulo);
        fprintf(yyout, "L%d:\tli $a0, 1\n", rotulo - 1);
        fprintf(yyout, "L%d:\tnop\n", rotulo); 
        empilha(LOG);
    }
    | T_ABRE expressao T_FECHA
    ;




%%

int main (int argc, char *argv[]) {
    char nameIn[100], nameOut[30], *p;
    if(argc < 2) {
        printf("Use:\n\t%s <arquivo>[.simples]\n\n", argv[0]);
        return 10;
    }
    p = strstr(argv[1], ".simples");
    if(p) *p = '\0';
    
    // Definindo o caminho dos arquivos de entrada e saída



    strcpy(nameIn, argv[1]);
    strcpy(nameOut, argv[1]);
    strcat(nameIn, ".simples");
    strcat(nameOut, ".asm");
    yyin = fopen(nameIn, "r");
    yyout = fopen(nameOut, "w");
    if (!yyin) {
        perror("Erro ao abrir o arquivo");
        return 1;
    }
    yyparse();
    return 0;
}