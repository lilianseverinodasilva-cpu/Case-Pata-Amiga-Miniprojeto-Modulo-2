-- =====================================================================================
--  ARQUIVO 4:  A TABELA FATO
--  Case: Pata Amiga - rede de petshops de SC  |  MySQL 8.0
-- =====================================================================================
--  Rode depois de: 03-dimensoes.sql
--
--  UMA fato, UM unico INSERT ... SELECT. A tabela ja existe, vazia (arquivo 02).
--  4.044 linhas = 4.044 pedidos.
--
--  Regra geral: a limpeza dos dados fica nas dimensoes; a fato apenas procura a
--  linha correta (por JOIN). Nenhuma FK fica nula: quando o dado falta, ela
--  aponta para a linha -1 (CASE WHEN ... IS NULL THEN -1).
--
--  Sugestao: comece pelo esqueleto (numero_pedido + as duas FKs de tempo +
--  FROM), rode e confira 4.044 linhas; depois acrescente as colunas aos poucos.
-- =====================================================================================

USE dw_pata_amiga;

INSERT INTO fato_pedido (
    numero_pedido,
    sk_tempo_pedido,
    sk_tempo_entrega,
    sk_loja,
    sk_categoria,
    houve_desconto,
    canal_pedido,
    dt_pedido,
    qt_itens,
    vl_liquido,
    dias_integracao_separacao,
    dias_separacao_nota,
    dias_nota_despacho,
    dias_despacho_entrega,
    dias_total_ate_entrega
)
SELECT 
    p.`NumeroPedido` AS numero_pedido,

    -- sk_tempo_pedido: data no formato americano %m/%d/%Y %h:%i %p convertida em AAAAMMDD
    CAST(DATE_FORMAT(STR_TO_DATE(p.`DtHoraPedido`, '%m/%d/%Y %h:%i %p'), '%Y%m%d') AS SIGNED) AS sk_tempo_pedido,

    -- sk_tempo_entrega: data ISO convertida em AAAAMMDD; entrega em branco (processo aberto) vira -1
    COALESCE(
        CAST(DATE_FORMAT(
            CASE WHEN TRIM(COALESCE(p.`DtEntregaCliente`, '')) IN ('', '-', 'n/d') THEN NULL 
                 ELSE STR_TO_DATE(p.`DtEntregaCliente`, '%Y-%m-%d') 
            END, '%Y%m%d') AS SIGNED),
        -1
    ) AS sk_tempo_entrega,

    -- sk_loja: se nao achou par no LEFT JOIN, aponta para a linha -1
    COALESCE(dl.sk_loja, -1) AS sk_loja,

    -- sk_categoria: se nao achou par no LEFT JOIN, aponta para a linha -1
    COALESCE(dc.sk_categoria, -1) AS sk_categoria,

    -- houve_desconto: padronizado com CASE na própria fato (Sim / Nao / Nao Informado)
    CASE 
        WHEN UPPER(TRIM(p.`HouveDesconto`)) IN ('S', 'SIM', '1', 'X', 'TRUE', 'V') THEN 'Sim'
        WHEN UPPER(TRIM(p.`HouveDesconto`)) IN ('N', 'NAO', '0', 'FALSE', 'F') THEN 'Nao'
        ELSE 'Nao Informado'
    END AS houve_desconto,

    -- canal_pedido: padronizado com CASE na própria fato (WHATSAPP vem antes de APP)
    CASE 
        WHEN UPPER(p.`CanalPedido`) LIKE '%WHATS%' THEN 'WhatsApp'
        WHEN UPPER(p.`CanalPedido`) LIKE '%APP%'   THEN 'App'
        WHEN UPPER(p.`CanalPedido`) LIKE '%SITE%'  THEN 'Site'
        WHEN UPPER(p.`CanalPedido`) LIKE '%LOJA%'  THEN 'Loja Fisica'
        WHEN UPPER(p.`CanalPedido`) LIKE '%TEL%'   THEN 'Telefone'
        ELSE 'Nao Informado'
    END AS canal_pedido,

    -- dt_pedido: data/hora completa do pedido
    STR_TO_DATE(p.`DtHoraPedido`, '%m/%d/%Y %h:%i %p') AS dt_pedido,

    -- qt_itens: '' e '-' viram NULL
    CASE 
        WHEN TRIM(p.`QTD.Itens`) IN ('', '-', 'n/d') OR p.`QTD.Itens` IS NULL THEN NULL
        ELSE CAST(p.`QTD.Itens` AS SIGNED)
    END AS qt_itens,

    -- vl_liquido: '' e '-' viram NULL; remove "R$", espacos e trata milhar/virgula
    CASE 
        WHEN TRIM(REPLACE(p.`ValorLiquidoPedido(R$)`, 'R$', '')) IN ('', '-', 'n/d') OR p.`ValorLiquidoPedido(R$)` IS NULL THEN NULL
        WHEN p.`ValorLiquidoPedido(R$)` LIKE '%,%' THEN 
            CAST(REPLACE(REPLACE(REPLACE(REPLACE(p.`ValorLiquidoPedido(R$)`, 'R$', ''), ' ', ''), '.', ''), ',', '.') AS DECIMAL(15,2))
        ELSE 
            CAST(REPLACE(REPLACE(p.`ValorLiquidoPedido(R$)`, 'R$', ''), ' ', '') AS DECIMAL(15,2))
    END AS vl_liquido,

    -- os lags em dias: DATEDIFF. Etapa nao cumprida grava NULL. Use DATE() na integracao (ela tem hora).
    DATEDIFF(
        CASE WHEN TRIM(COALESCE(p.`Dt Separacao Estoque`, '')) IN ('', '-', 'n/d') THEN NULL ELSE STR_TO_DATE(p.`Dt Separacao Estoque`, '%Y-%m-%d') END,
        DATE(STR_TO_DATE(p.`DtHoraIntegracaoERP`, '%m/%d/%Y %h:%i %p'))
    ) AS dias_integracao_separacao,

    DATEDIFF(
        CASE WHEN TRIM(COALESCE(p.`DtNotaFiscal`, '')) IN ('', '-', 'n/d') THEN NULL ELSE STR_TO_DATE(p.`DtNotaFiscal`, '%Y-%m-%d') END,
        CASE WHEN TRIM(COALESCE(p.`Dt Separacao Estoque`, '')) IN ('', '-', 'n/d') THEN NULL ELSE STR_TO_DATE(p.`Dt Separacao Estoque`, '%Y-%m-%d') END
    ) AS dias_separacao_nota,

    DATEDIFF(
        CASE WHEN TRIM(COALESCE(p.`Dt_Despacho_Transportadora`, '')) IN ('', '-', 'n/d') THEN NULL ELSE STR_TO_DATE(p.`Dt_Despacho_Transportadora`, '%Y-%m-%d') END,
        CASE WHEN TRIM(COALESCE(p.`DtNotaFiscal`, '')) IN ('', '-', 'n/d') THEN NULL ELSE STR_TO_DATE(p.`DtNotaFiscal`, '%Y-%m-%d') END
    ) AS dias_nota_despacho,

    DATEDIFF(
        CASE WHEN TRIM(COALESCE(p.`DtEntregaCliente`, '')) IN ('', '-', 'n/d') THEN NULL ELSE STR_TO_DATE(p.`DtEntregaCliente`, '%Y-%m-%d') END,
        CASE WHEN TRIM(COALESCE(p.`Dt_Despacho_Transportadora`, '')) IN ('', '-', 'n/d') THEN NULL ELSE STR_TO_DATE(p.`Dt_Despacho_Transportadora`, '%Y-%m-%d') END
    ) AS dias_despacho_entrega,

    DATEDIFF(
        CASE WHEN TRIM(COALESCE(p.`DtEntregaCliente`, '')) IN ('', '-', 'n/d') THEN NULL ELSE STR_TO_DATE(p.`DtEntregaCliente`, '%Y-%m-%d') END,
        DATE(STR_TO_DATE(p.`DtHoraIntegracaoERP`, '%m/%d/%Y %h:%i %p'))
    ) AS dias_total_ate_entrega

FROM stg_pedido p

-- LOJA (LEFT JOIN dim_loja): limpe o nome no ON (REPLACE tira '/SC' e espaco duplo + CASE para 3 grafias)
LEFT JOIN dim_loja dl
  ON dl.chave_loja = UPPER(
        CASE 
            WHEN UPPER(TRIM(REPLACE(REPLACE(p.`Loja-Nome`, '/SC', ''), '  ', ' '))) = 'PATA AMIGA BLUMENAL CENTRO' 
                THEN 'PATA AMIGA BLUMENAU CENTRO'
            WHEN UPPER(TRIM(REPLACE(REPLACE(p.`Loja-Nome`, '/SC', ''), '  ', ' '))) = 'PATA AMIGA FLORIPA NORTE' 
                THEN 'PATA AMIGA FLORIANOPOLIS NORTE'
            WHEN UPPER(TRIM(REPLACE(REPLACE(p.`Loja-Nome`, '/SC', ''), '  ', ' '))) = 'PATA AMIGA JARAGUA DO SUL' 
                OR UPPER(TRIM(REPLACE(REPLACE(p.`Loja-Nome`, '/SC', ''), '  ', ' '))) = 'PATA AMIGA JGUA DO SUL'
                THEN 'PATA AMIGA JARAGUA DO SUL'
            ELSE TRIM(REPLACE(REPLACE(p.`Loja-Nome`, '/SC', ''), '  ', ' '))
        END
     )

-- CATEGORIA (LEFT JOIN dim_categoria): uma linha so - ON dc.categoria_origem = p.`CategoriaProduto`
LEFT JOIN dim_categoria dc
  ON dc.categoria_origem = p.`CategoriaProduto`;


--  Roteiro das colunas:
--
--  * sk_tempo_pedido / sk_tempo_entrega: a chave e a data no formato AAAAMMDD.
--    Monte com CAST(DATE_FORMAT(<a data>, '%Y%m%d') AS SIGNED). A data do PEDIDO
--    vem no formato americano com AM/PM: a mascara e '%m/%d/%Y %h:%i %p'
--    (STR_TO_DATE). Usar '%d/%m/%Y' NAO da erro - ela devolve NULL e datas
--    erradas em silencio, que e pior. Os marcos da entrega ja vem em ISO:
--    DATE() basta. Entrega em branco -> -1.
--
--  * sk_loja, sk_categoria: vem de LEFT JOIN; se nao achou par, -1.
--
--  * LOJA (LEFT JOIN dim_loja): limpe o nome no ON. REPLACE tira '/SC' e o espaco
--    duplo; um CASE resolve 3 grafias (digitacao, apelido, abreviacao). Acento e
--    maiuscula nao atrapalham: a collation padrao do MySQL trata 'Timbo', 'TIMBO'
--    e 'Timbo' com acento como o mesmo texto.
--
--  * CATEGORIA (LEFT JOIN dim_categoria): uma linha so -
--    ON dc.categoria_origem = p.`CategoriaProduto`.
--
--  * houve_desconto e canal_pedido: padronize com CASE e grave na PROPRIA fato
--    (nao ha dimensao para eles). O de-para completo dos dois campos esta no
--    ENUNCIADO, na secao 7 ("Como padronizar o desconto e o canal").
--    A ordem importa: 'WHATSAPP' contem 'APP',
--    entao teste WHATS antes de APP.
--
--  * dinheiro e itens: '' e '-' viram NULL; tire "R$" e trate o milhar.
--
--  * os lags em dias: DATEDIFF(<fim>, <inicio>). Etapa nao cumprida grava NULL,
--    nunca 0. Use DATE() em volta da integracao (ela tem hora).

-- =====================================================================================
--  Confira o resultado com o 00-conferencia.sql (bloco "DEPOIS DO 04").
-- =====================================================================================
