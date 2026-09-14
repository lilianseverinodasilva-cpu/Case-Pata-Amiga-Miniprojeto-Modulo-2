# Data Warehouse & Business Intelligence: Case Pata Amiga Petshops

Vídeo sobre o projeto: https://drive.google.com/file/d/1eGRY22wx4Be5hTzcAC7Lmnf87RKVxAsT/view?usp=drive_link

## Índice
* [Sobre o Projeto](#sobre-o-projeto)
* [Etapas do Projeto](#etapas-do-projeto)
  * [Etapa 1: Diagnóstico da origem](#etapa-1-diagnóstico-da-origem)
  * [Tarefa 2: Tratamento dos dados](#tarefa-2-tratamento-dos-dados)
  * [Tarefa 3: Construir as dimensões](#tarefa-3-construir-as-dimensões)
  * [Tarefa 4: Construir a fato](#tarefa-4-construir-a-fato)
  * [Tarefa 5: Responder e recomendar](#tarefa-5-responder-e-recomendar)
* [Arquitetura de Dados & Modelo Dimensional](#arquitetura-de-dados--modelo-dimensional)
* [Principais insights e conclusões](#principais-insights-e-conclusões)
  * [P1: Onde está o gargalo da entrega?](#p1-onde-está-o-gargalo-da-entrega)
  * [P2: Qual categoria concentra o faturamento?](#p2-qual-categoria-concentra-o-faturamento)
  * [P3: O desconto funciona igual em todo canal?](#p3-o-desconto-funciona-igual-em-todo-canal)
  * [P4: Qual praça de atendimento concentra o faturamento?](#p4-qual-praça-de-atendimento-concentra-o-faturamento)
  * [P5: Onde abrir a próxima loja, e o que os dados NÃO permitem afirmar?](#p5-onde-abrir-a-próxima-loja-e-o-que-os-dados-não-permitem-afirmar)
* [Estrutura dos Arquivos do Projeto no Git](#estrutura-dos-arquivos-do-projeto-no-git)
* [Tecnologias e Ferramentas](#tecnologias-e-ferramentas)
* [Melhorias a serem implementadas](#melhorias-a-serem-implementadas)
* [Como Executar o Projeto](#como-executar-o-projeto)

---

## Sobre o Projeto

Este projeto foi desenvolvido por Lilian Severino da Silva, como o **Projeto Avaliativo do Módulo 2** do curso de Análise de Dados com Python, oferecido pelo **SCTec** em parceria com a **SET** do Estado de Santa Catarina.

O objetivo principal é construir um **Data Warehouse em MySQL** baseado em um **Star Schema (Modelo Estrela)** para a rede de petshops *Pata Amiga*, realizando o pipeline ETL (Extração, Transformação e Carga) da camada Staging para a camada Dimensional/Fato e extraindo *business insights* para responder a cinco perguntas estratégicas da diretoria:

1. **P1:** Onde está o gargalo da entrega? Qual o tempo médio, em dias, entre o pedido entrar no ERP e chegar na casa do cliente? E qual dos quatro intervalos do processo (Integração → Separação, Separação → Nota, Nota → Despacho, Despacho → Entrega) é o mais lento? O gargalo é o mesmo nos três portes de loja?
2. **P2:** Qual categoria concentra o faturamento? Do faturamento total da rede, quanto vem de cada categoria de produto? A categoria campeã é a mesma nos três portes de loja?
3. **P3:** O desconto funciona igual em todo canal?
4. **P4:** Qual praça de atendimento concentra o faturamento?
5. **P5:** Onde abrir a próxima loja, e o que os dados NÃO permitem afirmar?

O projeto foi organizado em cinco tarefas, descritas a seguir:

---

## Etapas do Projeto

### Etapa 1: Diagnóstico da origem

Das 3 tabelas de dados brutos disponibilizadas, podemos concluir que existem diversos erros/inadequações. Para isso, usa-se o arquivo `01-carga-staging`, já disponibilizado previamente, e confere-se os dados com o `00-conferencia`. Realizei comandos específicos de `SELECT` no SQL para encontrar as diferentes grafias das colunas mencionadas no diagnóstico de conferência.

#### Diagnóstico de Anomalias

| Diagnóstico | Valor Encontrado | Esperado |
| :--- | :---: | :---: |
| grafias distintas de categoria (no MySQL) | **18** | 18 |
| grafias distintas de nome de loja | **50** | 50 |
| grafias distintas de HouveDesconto | **12** | 12 |
| grafias distintas de CanalPedido | **8** | 8 |
| pedidos sem Cod Loja preenchido | **1.575** | 1.575 (~39%) |
| pedidos sem nome de loja (vao para a -1) | **3** | 3 |

**Grafias encontradas em `CategoriaProduto`, na `stg_pedido` e classificadas em ordem alfabética:**
> ACESSORIO, Acessorios, brinquedo, Brinquedos, Hig., Higiene, Higiene e Beleza, Med., MEDICAMENTO, Medicamentos, Petisco, Petiscos, Rac., RACAO, Racao Medicamentosa, Racao Seca, Servico, Servicos

**Grafias distintas de `Loja-Nome` em `stg_pedido`, classificadas por ordem alfabética (a primeira linha é vazia mesmo):**
> Pata Amiga Ararangua, Pata Amiga Blumenal Centro, pata amiga blumenau centro, Pata Amiga Blumenau Centro, Pata Amiga Blumenau Centro/SC, Pata Amiga Brusque, Pata Amiga Chapecó, Pata Amiga Chapeco/SC, Pata Amiga Concórdia, pata amiga criciuma, Pata Amiga Criciuma/SC, PATA AMIGA CURITIBANOS, Pata Amiga Florianópolis Norte, Pata Amiga Florianopolis Norte/SC, Pata Amiga Floripa Norte, PATA AMIGA GASPAR, Pata Amiga Gaspar, Pata Amiga Ibirama, Pata Amiga Ibirama/SC, Pata Amiga Indaial, Pata Amiga Itajaí Praia, Pata Amiga Itajai Praia/SC, PATA AMIGA ITAPOA, Pata Amiga Ituporanga, Pata Amiga Jaraguá do Sul, Pata Amiga Jgua do Sul, PATA AMIGA JOINVILLE SUL, Pata Amiga Joinville Sul/SC, Pata Amiga Lages, pata amiga laguna, Pata Amiga Laguna/SC, Pata Amiga Otacilio Costa, PATA AMIGA OTACILIO COSTA, PATA AMIGA PALHOCA, Pata Amiga Presidente Getulio, Pata Amiga Rio do Sul, PATA AMIGA RIO DOS CEDROS, Pata Amiga Santo Amaro da Imperatriz, Pata Amiga Sao Bento do Sul, Pata Amiga São Joaquim, Pata Amiga São Jose Kobrasol, Pata Amiga Sao Jose Kobrasol/SC, Pata Amiga São Miguel do Oeste, PATA AMIGA TAIO, Pata Amiga Timbo, Pata Amiga Tubarão, PATA AMIGA XANXERE

**Grafias distintas na coluna `HouveDesconto` da `stg_pedido`:**
> true, X, SIM, V, S, 1, Nao, N, false, F, 0

**Grafias distintas na coluna `CanalPedido` da `stg_pedido`:**
> SITE, App, App Pata Amiga, loja fisica, Whatsapp, Telefone, Tel.

#### Marcos de Entrega em Branco (Processos Logísticos Abertos)

| Marco | Em_branco | esperado |
| :--- | :---: | :---: |
| Dt Separacao Estoque | **1077** | 1077 |
| DtNotaFiscal | **1338** | 1338 |
| Dt_Despacho_Transportadora | **1665** | 1665 |
| DtEntregaCliente | **1953** | 1953 |

---

### Tarefa 2: Tratamento dos dados

Com base nos erros estruturais e de qualidade identificados na tarefa 1, as adequações arquiteturais e de pré-processamento fundamentam as etapas seguintes:

| Defeito | Onde | Conceito cobrado | Estratégia de Tratamento |
| :--- | :--- | :--- | :--- |
| Todas as colunas são texto | `todas as stg_` | staging × área de apresentação | Manter raw em texto e tipar na modelagem |
| Nomes fora de `snake_case` | `Cod Loja, QTD.Itens` | identificador entre delimitador | Padronizar identificadores |
| Dois formatos de data na MESMA tabela | `stg_pedido` | a máscara certa por coluna | Aplicar parser de data por formato |
| 18 grafias para 7 categorias | `CategoriaProduto` | dimensão guarda a grafia crua | Agrupar em `nome_categoria` mantendo crua |
| “Ração Medicamentosa” não é ração | `CategoriaProduto` | a ordem do CASE importa | Definir precedência rigorosa no CASE |
| Dezenas de grafias de loja | `Loja-Nome` | padronizar antes do lookup | Normalizar string antes do cruzamento |
| Cod Loja vazio em 39% das linhas | `stg_pedido` | resolver por nome | Realizar lookup via nome padronizado |
| 3 pedidos sem loja identificada | `stg_pedido` | linha -1; nunca FK nula | Direcionar para `sk_loja = -1` |
| Sim/não escrito de muitas maneiras | `HouveDesconto` | padronizar na carga da fato | Normalizar (S/SIM/1/X/V/TRUE $\rightarrow$ Sim) |
| Canal escrito de muitas maneiras | `CanalPedido` | padronizar; WHATS antes de APP | Avaliar `WHATS` antes de `APP` no CASE |
| Números em formatos misturados | `todas as numéricas` | a regra dos números | Converter separadores/tipos numéricos |
| Loja em mais de uma praça | `stg_loja_praca` | bridge table com fator | Usar tabela ponte com `fator_publico` |
| Cadastro só com a foto de hoje | `stg_loja` | o passado foi sobrescrito (limite da P5) | Assumir limitação de SCD Tipo 1 |
| 2 datas por pedido na fato | `stg_pedido` | role-playing dimension | Reutilizar `dim_tempo` (pedido e entrega) |
| Marco em branco = processo aberto | `stg_pedido` | FK → -1, e NULL nos dias | Atribuir `-1` na sk_entrega e `NULL` nos dias |
| Número do pedido sem atributos | `NumeroPedido` | dimensão degenerada | Manter `numero_pedido` direto na fato |

---

### Tarefa 3: Construir as dimensões

Aqui usa-se o arquivo `03-dimensoes`, disponibilizado previamente, e nele inseri os códigos para as devidas populações das tabelas dimensão pedidas. Depois, fiz a conferência com o arquivo 00, após a etapa 3, e todos os dados ficaram corretos. 
* *Regras aplicadas:* `dim_categoria` dimensiona 19 linhas (18 grafias cruas + `-1`) e agrupa em 8 categorias padronizadas (`nome_categoria` + `-1`). `dim_praca` e `bridge_loja_praca` estruturam as 13 praças e 48 relacionamentos N:N, garantindo soma de `fator_publico = 1,00` por loja. Dimensões prontas (`dim_tempo` com 236 linhas baseada em inteiro `YYYYMMDD`, e `dim_loja` com 33 linhas) validam a integridade.

---

### Tarefa 4: Construir a fato

Nesta etapa deve ser usado o arquivo `04-fato`, que foi devidamente completado com o código necessário para a efetiva criação e população da tabela `fato_pedido` (grão: 1 linha = 1 pedido; total de 4.044 linhas).
* *Tratamentos embutidos no INSERT:* Padronização de `houve_desconto` (17 variações mapeadas para Sim/Nao/Nao Informado) e `canal_pedido` (com testes sequenciais avaliando `WHATS` antes de `APP`). Geração de `sk_tempo_entrega = -1` para os 1.953 pedidos abertos e `sk_loja = -1` para os 3 órfãos. Cálculo de delta de dias logísticos (`dias_integracao_separacao`, `dias_separacao_nota`, `dias_nota_despacho`, `dias_despacho_entrega`, `dias_total_ate_entrega`), gravando `NULL` onde há marcos em branco. Validação de zero FKs nulas ou órfãs.

---

### Tarefa 5: Responder e recomendar

Nesta etapa foi necessário realizar consultas para responder às perguntas de negócio. Usou-se o arquivo `05-perguntas`, que precisava da criação dos códigos para as consultas (aplicando o rateio da praça na P4 via `fator_publico` para evitar estouro de faturamento da rede). Os resultados estão na seção `Principais Insights e Conclusões` aqui do ReadMe, neste git.

---

## Arquitetura de Dados & Modelo Dimensional

O modelo segue a modelagem dimensional em **Esquema Estrela (Star Schema)** com uma tabela fato centralizada e dimensões ao redor, além de uma tabela ponte para resolver o relacionamento N:N entre Lojas e Praças:

<img width="1438" height="678" alt="diagrama_case_pata_amiga" src="https://github.com/user-attachments/assets/7b7ba26e-4070-4526-95f9-a6053328100a" />
Disponível também em: "https://dbdocs.io/lilianseverinodasilva/diagrama_case_pata_amiga?view=relationships"

---

## Principais insights e conclusões 

### P1: Onde está o gargalo da entrega?

* **Diagnóstico e Localização do Gargalo:** O gargalo do processo de entrega está concentrado na etapa de expedição interna (**Nota Fiscal → Despacho**).
* **Tempo Médio Geral:** O fluxo completo (do ERP até o cliente) leva em média **7,93 a 7,95 dias** nas lojas Médias e Grandes, mas dobra para **15,16 dias** nas lojas de Pequeno porte.
* **Comportamento por Porte:** **Sim, o gargalo é a mesma etapa (Nota → Despacho) nos três portes de loja**. Contudo, nas lojas pequenas a espera é desproporcional, consumindo 8,53 dias apenas na expedição.

| Porte da Loja | Integração → Separação | Separação → Nota | Nota → Despacho | Despacho → Entrega | Tempo Total (Dias) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Pequena** | 3.02 | 0.69 | **8.53** | 2.86 | **15.16** |
| **Média** | 1.98 | 0.62 | **3.34** | 2.03 | **7.95** |
| **Grande** | 1.96 | 0.64 | **3.32** | 2.01 | **7.93** |
| **Não Informado** | 2.00 | 0.00 | **4.00** | 3.00 | **8.50** |

---

### P2: Qual categoria concentra o faturamento?

* **Concentração de Faturamento da Rede:** A categoria **Ração** lidera as vendas da rede, acumulando **R$ 1.076.202,55 (60,01%)** do faturamento total.
* **Unanimidade nos Portes:** **Sim, a categoria Ração é a campeã absoluta em todos os portes de loja**, seguida por Medicamentos (~17%) e Petiscos (~7%).

| Nome da Categoria | Faturamento Total (R$) | % do Total da Rede |
| :--- | :---: | :---: |
| **Racao** | 1076202.55 | **60.01** |
| **Medicamento** | 305904.03 | **17.06** |
| **Petisco** | 128590.16 | **7.17** |
| **Servico** | 94001.37 | **5.24** |
| **Higiene** | 92314.45 | **5.15** |
| **Acessorio** | 64661.39 | **3.61** |
| **Brinquedo** | 31634.56 | **1.76** |

---

### P3: O desconto funciona igual em todo canal?

* **Eficiência do Desconto & Performance dos Canais:** **Sim.** Em todos os canais de venda, a concessão de desconto impulsiona compras maiores, gerando um ticket médio 2,5 a 3 vezes superior às vendas sem desconto.
* **Relevância dos Canais Digitais:** O **App** (30,79%) e o **Site** (25,13%) representam **55,92% da receita total da rede**.

| Canal de Pedido | Ticket Médio COM Desconto | Ticket Médio SEM Desconto | Faturamento no Canal (R$) | % Faturamento Total |
| :--- | :---: | :---: | :---: | :---: |
| **App** | 488.04 | 167.63 | 552134.43 | **30.79** |
| **Site** | 501.92 | 189.68 | 450569.37 | **25.13** |
| **Loja Fisica** | 494.04 | 197.55 | 360677.22 | **20.11** |
| **WhatsApp** | 514.33 | 179.26 | 188678.63 | **10.52** |
| **Telefone** | 514.02 | 195.23 | 123419.29 | **6.88** |
| **Nao Informado** | 561.59 | 206.95 | 117829.57 | **6.57** |

---

### P4: Qual praça de atendimento concentra o faturamento?

* **Rateio de Faturamento por Praça:** O **Vale do Itajaí** lidera o faturamento rateado com **R$ 633.746,09 (35,34% do total)**, alinhado à sua base de 148.000 domicílios com pet.
* **Consistência do Rateio:** A aplicação do fator público da ponte garante que a soma das praças fecha com o faturamento das lojas identificadas.

| Nome da Praça | Regional | Domicílios com Pet | Faturamento Rateado (R$) | % Faturamento Total |
| :--- | :--- | :---: | :---: | :---: |
| **Vale do Itajai** | Regional Leste | 148000 | 633746.09 | **35.34** |
| **Grande Florianopolis** | Regional Leste | 132000 | 283546.75 | **15.81** |
| **Norte Industrial** | Regional Norte | 96000 | 175431.90 | **9.78** |
| **Litoral Sul** | Regional Sul | 58000 | 137051.20 | **7.64** |
| **Litoral Norte** | Regional Norte | 61000 | 128872.75 | **7.19** |

---

### P5: Onde abrir a próxima loja, e o que os dados NÃO permitem afirmar?

* **a) Recomendação Estratégica de Expansão:** O ranqueamento das lojas por **itens vendidos por mil habitantes** cruzado com o **tempo médio de entrega** evidencia que as maiores capitais e cidades já consolidadas (como Florianópolis, Joinville, Criciúma e Blumenau) apresentam baixos índices de consumo relativo por habitante (entre 2 e 5 itens/mil hab.) e entregas rápidas (em torno de 7 a 8 dias). 

Em contrapartida, as oportunidades reais de expansão e otimização logística concentram-se em municípios do interior e regiões periféricas — com destaque para **Rio dos Cedros, Presidente Getúlio, Ibirama, Itapoá, Santo Amaro da Imperatriz, Taió, Otacílio Costa e Ituporanga**. Nestas praças, o consumo relativo explode (chegando a mais de 41 itens por mil habitantes), mas a operação sofre com o **gargalo logístico severo**, apresentando prazos médios de entrega elevados que ultrapassam 14 a 16 dias. 

Recomenda-se que a diretoria invista na criação de **Dark Stores ou Lojas de Apoio Regional** nestes polos de alta demanda proporcional para encurtar as distâncias de despacho e absorver a repressão de consumo.

| Nome da Loja | Cidade | População | Total Itens | Itens / 1.000 Hab. | Tempo Médio Entrega (Dias) |
| :--- | :--- | :---: | :---: | :---: | :---: |
| Pata Amiga Rio dos Cedros | Rio dos Cedros | 11322 | 474 | 41.87 | 14.24 |
| Pata Amiga Presidente Getulio | Presidente Getúlio | 16359 | 570 | 34.84 | 14.16 |
| Pata Amiga Ibirama | Ibirama | 18613 | 597 | 32.07 | 15.39 |
| Pata Amiga Itapoa | Itapoá | 20586 | 534 | 25.94 | 15.39 |
| Pata Amiga Santo Amaro da Imperatriz | Santo Amaro da Imperatriz | 22357 | 530 | 23.71 | 15.88 |
| Pata Amiga Taio | Taió | 18173 | 352 | 19.37 | 14.57 |
| Pata Amiga Timbo | Timbó | 45011 | 804 | 17.86 | 7.70 |
| Pata Amiga Gaspar | Gaspar | 71133 | 1189 | 16.72 | 8.01 |
| Pata Amiga Otacilio Costa | Otacílio Costa | 18227 | 289 | 15.86 | 15.61 |
| Pata Amiga Ituporanga | Ituporanga | 25748 | 354 | 13.75 | 16.53 |
| Pata Amiga Rio do Sul | Rio do Sul | 73135 | 885 | 12.10 | 8.35 |
| Pata Amiga Sao Joaquim | São Joaquim | 27234 | 320 | 11.75 | 15.07 |
| Pata Amiga Laguna | Laguna | 46122 | 541 | 11.73 | 8.51 |
| Pata Amiga Indaial | Indaial | 71987 | 750 | 10.42 | 7.74 |
| Pata Amiga Ararangua | Araranguá | 68274 | 689 | 10.09 | 8.25 |
| Pata Amiga Tubarao | Tubarão | 105511 | 889 | 8.43 | 7.69 |
| Pata Amiga Jaragua do Sul | Jaraguá do Sul | 184579 | 1440 | 7.81 | 8.01 |
| Pata Amiga Curitibanos | Curitibanos | 39061 | 308 | 7.89 | 8.65 |
| Pata Amiga Sao Bento do Sul | São Bento do Sul | 87310 | 567 | 6.49 | 8.18 |
| Pata Amiga Concordia | Concórdia | 74641 | 470 | 6.30 | 7.74 |
| Pata Amiga Blumenau Centro | Blumenau | 361855 | 2002 | 5.53 | 7.80 |
| Pata Amiga Xanxere | Xanxerê | 52034 | 284 | 5.46 | 8.17 |
| Pata Amiga Palhoca | Palhoça | 168259 | 845 | 5.02 | 7.69 |
| Pata Amiga Sao Miguel do Oeste | São Miguel do Oeste | 41520 | 186 | 4.48 | 8.00 |
| Pata Amiga Brusque | Brusque | 143270 | 558 | 3.89 | 7.63 |
| Pata Amiga Criciuma | Criciúma | 217392 | 822 | 3.78 | 8.07 |
| Pata Amiga Lages | Lages | 158846 | 593 | 3.73 | 7.69 |
| Pata Amiga Sao Jose Kobrasol | São José | 250181 | 929 | 3.71 | 8.01 |
| Pata Amiga Chapeco | Chapecó | 254235 | 824 | 3.24 | 7.85 |
| Pata Amiga Joinville Sul | Joinville | 597658 | 1888 | 3.16 | 7.83 |
| Pata Amiga Itajai Praia | Itajaí | 264054 | 798 | 3.02 | 7.98 |
| Pata Amiga Florianopolis Norte | Florianópolis | 537213 | 1426 | 2.65 | 8.02 |

* **b) Faturamento por Faixa Atual & Limitação SCD Type 1:** Como o cadastro de franquias utiliza **SCD Type 1 (sobrescrita sem histórico)**, **os dados NÃO permitem responder quanto veio de lojas que JÁ ERAM Ouro na data do pedido**, pois a faixa atual sobrescreveu o status passado.

| Faixa Franquia Atual | Faturamento Total (R$) | % Faturamento Total |
| :--- | :---: | :---: |
| **Ouro** | 1011264.38 | **56.39** |
| **Diamante** | 382209.74 | **21.31** |
| **Prata** | 314812.03 | **17.55** |
| **Bronze** | 84036.06 | **4.69** |
| **Não Informado** | 986.30 | **0.05** |

* **c) Mensuração das Limitações e Dados Incompletos:**

| Pedidos Sem Loja | Entregas Não Concluídas | Itens em Branco | Valores em Branco |
| :---: | :---: | :---: | :---: |
| **3** | **1953** | **257** | **121** |
---

## Estrutura dos Arquivos do Projeto no Git

**Pasta Principal:**
* **.gitignore:** Arquivo para ignorar arquivos desnecessários no repositório.
* **requirements.txt:** Resumo das bibliotecas e ferramentas necessárias para a execução do projeto.
* **README.md:** Documentação principal do projeto.

**Pasta `sql/`:**
* **00-conferencia.sql:** Arquivo já disponibilizado previamente para verificação de dados.
* **01-carga-staging.sql:** Também já disponibilizado previamente. Aqui está a carga dos dados brutos para o banco SQL e criação da camada bronze/raw.
* **02-dimensoes-prontas.sql:** Criação estrutural das tabelas dimensionais e fato.
* **03-dimensoes.sql:** Carga, limpeza e padronização das dimensões.
* **04-fato.sql:** Inserção dos eventos de pedidos com tratamento de regras de negócio.
* **05-perguntas.sql:** Consultas finais respondendo às questões de negócio.

---

## Tecnologias e Ferramentas

* **Banco de Dados:** MySQL / SQL.
* **Arquitetura de Dados:** Modelagem Dimensional em Star Schema.
* **Ferramenta de Diagramação:** dbdiagram.io.
* **Controle de Versão:** Git e GitHub.

---
## Melhorias a serem implementadas

* Este projeto tem cunho educacional e não reflete dados reais. Porém, pensando num contexto real, o que pode ser feito, num processo vindouro, é a retenção histórica dos dados (SCD tipo 2) para assim poder fazer as análises ao longo do tempo, que foi um dos problemas encontrados na pergunta 5, por exemplo. Dados históricos também auxliam a entender a progressão das vendas e faturamento, bem como entender se há diferenças sazonais como, por exemplo, aumento ou diminuição de vendas no período de festas de fim de ano, com posterior criação de ações de marketing/venda específicas.
* Outro ponto a se salientar é que os dados vêm de fontes diferentes e aqui temos um recorte histórico determinado. Para otimizar a sugestão anterior, o ideal seria criar um pipeline que possa gerir todo o processo, da exportação à análise dos dados, especialmente na nuvem, para evitar a necessidade de equipamentos e servidores locais, que geram custo de manutenção e pessoal.

---

## Como Executar o Projeto

1. Clone este repositório:
   ```bash
   git clone [https://github.com/lilianseverinodasilva-cpu/Case-Pata-Amiga-Miniprojeto-Modulo-2.git](https://github.com/lilianseverinodasilva-cpu/Case-Pata-Amiga-Miniprojeto-Modulo-2.git)
Execução sequencial obrigatória: Execute os scripts SQL da pasta sql/ respeitando estritamente a ordem numérica de 01 a 05. Nota: Estes arquivos já contêm a implementação com os trechos desenvolvidos por você e os ganchos fornecidos pelo projeto.

01-carga-staging.sql

02-dimensoes-prontas.sql

03-dimensoes.sql

04-fato.sql

05-perguntas.sql

Validação e Conferência: Utilize o arquivo 00-conferencia.sql ao longo do processo para validar se os quantitativos intermediários e finais batem com o gabarito.

No SQL, ao final do projeto, seguindo estritamente a sequência numérica dos arquivos, o Banco de Dados deve estar assim:
<img width="252" height="178" alt="Captura de tela 2026-09-12 212045" src="https://github.com/user-attachments/assets/ccf862e4-cbf3-46f8-8f83-d5fe2d195009" />

---

Desenvolvido por Lilian Severino da Silva
