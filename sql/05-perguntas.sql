-- =====================================================================================
--  ARQUIVO 5:  AS CINCO PERGUNTAS DE NEGOCIO
--  Case: Pata Amiga - rede de petshops de SC  |  MySQL 8.0
-- =====================================================================================
--  Rode depois de: 04-fato.sql
--
--  Cada pergunta e UMA consulta: um SELECT com JOIN e GROUP BY. A subconsulta
--  aparece na P2 e na P5, e serve para trazer o total da rede como denominador.
-- =====================================================================================

USE dw_pata_amiga;

-- =====================================================================================
--  P1 - ONDE ESTA O GARGALO DO PROCESSO DE ENTREGA?
-- =====================================================================================
--  Media (AVG) dos quatro intervalos ja calculados na carga, agrupada por porte
--  de loja. AVG ignora NULL - por isso a etapa nao cumprida foi gravada como NULL.
--  dias_total_ate_entrega e o processo inteiro, nao um dos quatro intervalos.

-- >>> ESCREVA AQUI a consulta da P1

SELECT 
    dl.porte AS porte_loja,
    ROUND(AVG(f.dias_integracao_separacao), 2) AS avg_integracao_separacao,
    ROUND(AVG(f.dias_separacao_nota), 2)       AS avg_separacao_nota,
    ROUND(AVG(f.dias_nota_despacho), 2)        AS avg_nota_despacho,
    ROUND(AVG(f.dias_despacho_entrega), 2)     AS avg_despacho_entrega,
    ROUND(AVG(f.dias_total_ate_entrega), 2)   AS avg_tempo_total_dias
FROM fato_pedido f
JOIN dim_loja dl ON f.sk_loja = dl.sk_loja
GROUP BY dl.porte
ORDER BY FIELD(dl.porte, 'Pequena', 'Media', 'Grande', 'Nao Informado');


-- =====================================================================================
--  P2 - QUAL CATEGORIA CONCENTRA O FATURAMENTO?
-- =====================================================================================
--  Esta e a pergunta que paga a dim_categoria. Agrupe pelo nome_categoria
--  PADRONIZADO (nunca pela grafia crua). O percentual do total usa uma
--  subconsulta com o faturamento da rede como denominador.

-- >>> ESCREVA AQUI a consulta da P2

SELECT 
    dc.nome_categoria,
    SUM(f.vl_liquido) AS faturamento_total,
    ROUND(100.0 * SUM(f.vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS pct_do_total
FROM fato_pedido f
JOIN dim_categoria dc ON f.sk_categoria = dc.sk_categoria
GROUP BY dc.nome_categoria
ORDER BY faturamento_total DESC;


SELECT 
    dl.porte AS porte_loja,
    dc.nome_categoria,
    SUM(f.vl_liquido) AS faturamento_porte,
    ROUND(100.0 * SUM(f.vl_liquido) / SUM(SUM(f.vl_liquido)) OVER (PARTITION BY dl.porte), 2) AS pct_no_porte
FROM fato_pedido f
JOIN dim_categoria dc ON f.sk_categoria = dc.sk_categoria
JOIN dim_loja dl ON f.sk_loja = dl.sk_loja
GROUP BY dl.porte, dc.nome_categoria
ORDER BY FIELD(dl.porte, 'Pequena', 'Media', 'Grande'), faturamento_porte DESC;


-- =====================================================================================
--  P3 - O DESCONTO FUNCIONA IGUAL EM TODO CANAL?
-- =====================================================================================
--  Aqui NAO ha JOIN: desconto e canal foram padronizados na carga e moram na
--  propria fato. Compare o TICKET MEDIO com e sem desconto DENTRO de cada canal.
--  Confira se o WhatsApp aparece - se nao, o CASE do arquivo 04 testou APP antes
--  de WHATS.

-- >>> ESCREVA AQUI a consulta da P3

SELECT 
    canal_pedido,
    -- Ticket Médio dos pedidos COM desconto
    ROUND(AVG(CASE WHEN houve_desconto = 'Sim' THEN vl_liquido END), 2) AS ticket_medio_com_desconto,
    
    -- Ticket Médio dos pedidos SEM desconto
    ROUND(AVG(CASE WHEN houve_desconto = 'Nao' THEN vl_liquido END), 2) AS ticket_medio_sem_desconto,
    
    -- Faturamento total do canal
    SUM(vl_liquido) AS faturamento_canal,
    
    -- Percentual do faturamento do canal sobre o total da rede
    ROUND(100.0 * SUM(vl_liquido) / (SELECT SUM(vl_liquido) FROM fato_pedido), 2) AS pct_faturamento_total
FROM fato_pedido
GROUP BY canal_pedido
ORDER BY faturamento_canal DESC;

-- =====================================================================================
--  P4 - QUAL PRACA DE ATENDIMENTO CONCENTRA O FATURAMENTO?
-- =====================================================================================
--  Esta e a pergunta que paga a dim_praca e a ponte.
--  Caminho: fato_pedido -> dim_loja -> bridge_loja_praca -> dim_praca (a ponte
--  entra pelo cod_loja). O JOIN com a ponte DUPLICA a linha do pedido, uma por
--  praca - isso esta certo. Multiplique por b.fator_publico para o faturamento
--  nao ser contado duas vezes.

-- >>> ESCREVA AQUI a consulta da P4

SELECT 
    dp.nome_praca,
    dp.regional,
    dp.domicilios_com_pet,
    -- Faturamento rateado pelo fator do público da praça
    ROUND(SUM(f.vl_liquido * b.fator_publico), 2) AS faturamento_rateado,
    -- Percentual do faturamento da praça sobre o total da rede
    ROUND(
        100.0 * SUM(f.vl_liquido * b.fator_publico) / (SELECT SUM(vl_liquido) FROM fato_pedido), 
        2
    ) AS pct_faturamento_total
FROM fato_pedido f
JOIN dim_loja dl         ON f.sk_loja = dl.sk_loja
JOIN bridge_loja_praca b ON dl.cod_loja = b.cod_loja
JOIN dim_praca dp        ON b.sk_praca = dp.sk_praca
GROUP BY dp.nome_praca, dp.regional, dp.domicilios_com_pet
ORDER BY faturamento_rateado DESC;


-- Teste de rateio das praças

SELECT 
    (SELECT SUM(vl_liquido) FROM fato_pedido WHERE sk_loja <> -1) AS fat_lojas_identificadas,
    ROUND(SUM(f.vl_liquido * b.fator_publico), 2) AS fat_soma_pracas_rateada
FROM fato_pedido f
JOIN dim_loja dl         ON f.sk_loja = dl.sk_loja
JOIN bridge_loja_praca b ON dl.cod_loja = b.cod_loja;


-- =====================================================================================
--  P5 - ONDE ABRIR A PROXIMA LOJA, E O QUE OS DADOS NAO PERMITEM AFIRMAR?
-- =====================================================================================
--  (a) Ranqueie as lojas por itens POR MIL HABITANTES (numerador na fato,
--      denominador na dimensao), calculado AQUI na consulta - nunca gravado
--      pronto. Cruze com o tempo medio de entrega.
--  (b) Mostre o faturamento por faixa de franquia e explique por que ele NAO
--      responde "quanto veio de lojas que JA ERAM Ouro na data do pedido": o
--      cadastro so tem a foto de hoje.
--  (c) Meca o que ficou de fora: pedidos sem loja, entregas nao concluidas,
--      itens e valores em branco.

-- >>> ESCREVA AQUI as consultas da P5
