
/*+----------------------------------------------------------------+
  |           UNIFAL - Universidade Federal de Alfenas.            |
  |             BACHARELADO EM CIÊNCIAS DA COMPUTAÇÃO.               |
  |                                                                |
  |  Trabalho..: Geracao de codigo MIPS                            |
  |  Disciplina: Compiladores                                      |
  |  Professor.: Luiz Eduardo da Silva                             |
  |  Aluno.....: João Felipe Martins Santana                         |
  |  Data......: 07/12/2024                                        |
  +----------------------------------------------------------------+*/

#include <stdio.h>

// Tabela de Simbolos
FILE *yyout;
enum
{
    INT,
    LOG
};

#define TAM_TAB 100
#define TAM_LIT 100

struct elemTabSimbolos
{
    char id[100]; // nome do identificador
    int end;      // endereco
    int tip;      // tipo
} tabSimb[TAM_TAB], elemTab;

int posTab = 0;

struct tabelaVariaveis
{
    char id[100];
    char valor[300];
} tabVar[TAM_LIT], elemLit;

int posLit = 0;

int buscaSimbolo(char *s)
{
    int i;
    for (i = posTab; strcmp(tabSimb[i].id, s) && i >= 0; i--)
        ;
    if (i == -1)
    {
        char msg[200];
        sprintf(msg, "Identificador [%s] não encontrado!", s);
        yyerror(msg);
    }
    return i;
}

void insereSimbolo(struct elemTabSimbolos elem)
{
    int i;
    if (posTab == TAM_TAB)
        yyerror("Tabela de Simbolos cheia!");
    for (i = posTab - 1; strcmp(tabSimb[i].id, elem.id) && i >= 0; i--)
        ;

    if (i != -1)
    {
        char msg[200];
        sprintf(msg, "Identificador [%s] duplicado", elem.id);
        yyerror(msg);
    }
    tabSimb[posTab++] = elem;
}

void geraData()
{
    fprintf(yyout, ".data\n");
    for (int i = 0; i < posTab; i++)
    {
        fprintf(yyout, "\t%s: .word 1\n", tabSimb[i].id);
    }
    fprintf(yyout, "\t_esp: .asciiz \" \"\n");
    fprintf(yyout, "\t_ent: .asciiz \"\\n\"\n");
    for (int i = 0; i < posLit; i++)
    {
        fprintf(yyout, "\t%s: .asciiz %s\n", tabVar[i].id, tabVar[i].valor);
    }
}

void insereLit(char *lit)
{
    int i;
    if (posLit == TAM_TAB)
        yyerror("Tabela de Variaveis cheia!");
    char tmp[100];
    sprintf(tmp, "_const%d", posLit);
    strcpy(elemLit.id, tmp);
    strcpy(elemLit.valor, lit);
    tabVar[posLit++] = elemLit;
}

// Pilha semantica
#define TAM_PIL 100
int pilha[TAM_PIL];
int topo = -1;

void empilha(int valor)
{
    if (topo == TAM_PIL)
    {
        yyerror("Pilha Semantica cheia");
    }
    pilha[++topo] = valor;
}

int desempilha(void)
{
    if (topo == -1)
    {
        yyerror("Pilha Semantica vazia!");
    }
    return pilha[topo--];
}

void testaTipo(int tipo1, int tipo2, int ret)
{
    int t1 = desempilha();
    int t2 = desempilha();
    if (t1 != tipo1 || t2 != tipo2)
        yyerror("Imcopatibilidade de tipo!");
    empilha(ret);
}