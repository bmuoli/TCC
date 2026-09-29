TCC LAB NOTEBOOK

Estrutura criada automaticamente pelo aplicativo.

campanha.json      -> estado geral, preparação de projeto e todos os Test Cases
preparacao_projeto.json -> checklist/pendências de Mathcad, perdas e pior caso
resumo.csv         -> tabela resumida para consulta rápida
TC-XX_.../dados.json
TC-XX_.../Historico/<data_hora>_dados.json
TC-XX_.../Teste_Pratico/<Direto|Reverso>/<Si|SiC>/Evidencias/<Assunto>/<Tipo>/<Sinal opcional>/<arquivos>
TC-XX_.../Simulacao/<Direto|Reverso>/<Si|SiC>/Arquivo/<arquivo>
TC-XX_.../Simulacao/<Direto|Reverso>/<Si|SiC>/Evidencias/<Componente>/<Sinal opcional>/<imagens>

Não renomeie pastas de Test Cases enquanto estiver usando o aplicativo.
Os componentes (L1...Ln, C1...Cn e Q1...Qn) são configurados individualmente em cada Test Case.
Para formas de onda, cada componente possui sinais selecionáveis (I/V nos passivos e VDS/VGS/IDS/IGS nas chaves).

As imagens permanecem em arquivos originais; não são incorporadas ao JSON.

A seção Preparação e análises de projeto é independente dos Test Cases e serve para acompanhar Mathcad, perdas e definição do pior caso.

A seção Caracterização preliminar de componentes mantém, no próprio HTML, imagens representativas e resumos preliminares dos semicondutores e indutores já medidos, para posterior aproveitamento no relatório.

O Radar de pendências mostra o percentual global da campanha. Ele considera as 5 tarefas de preparação, cada combinação habilitada de Test Case + direção + tecnologia de chave e os lembretes manuais de "Não esquecer". Cada execução pode ser concluída ou reaberta individualmente.

Cada Test Case é o agrupador principal. Dentro dele, Teste_Pratico e Simulacao ficam separados por direção (Direto/Reverso) e por tecnologia de chave (Si/SiC). Assim, o mesmo ensaio pode ser repetido com semicondutores diferentes sem sobrescrever resultados.

Ao salvar um Test Case, uma cópia do estado atual também é criada em Historico.

Autosave e sincronização:
- Ao colar uma imagem, o HTML confirma o recebimento imediatamente e mostra uma prévia; a gravação ocorre em uma fila de fundo.
- Ctrl+V de imagem funciona também fora da caixa de colagem, desde que o foco não esteja em um campo de texto ou no painel de simulação.
- Com a pasta conectada, imagens coladas, enviadas ou arrastadas são gravadas no disco em segundo plano.
- Campos e configurações são sincronizados automaticamente após cerca de 650 ms sem digitação.
- Existe ainda um autosave de segurança periódico.
- O botão "Criar checkpoint" gera um snapshot no Histórico; ele não é mais necessário para preservar uma medição.
- O navegador tenta lembrar a última pasta selecionada e reconecta automaticamente quando a permissão ainda está válida.

Proteção contra duplicação:
- O botão Salvar TC fica bloqueado enquanto uma gravação está em andamento.
- Imagens idênticas são identificadas por hash SHA-256 e não são adicionadas novamente.
- Evidências salvas podem ser renomeadas diretamente no card; o arquivo físico é renomeado junto.
- O nome completo fica visível em um campo de duas linhas e pode ser editado novamente a qualquer momento.
- Evidências salvas podem ser movidas para Lixeira e restauradas depois.
- Se um arquivo for apagado manualmente fora do HTML, a galeria mostra apenas um aviso compacto de arquivo ausente, evitando cartões vazios.

Nos testes TC-01, TC-02, TC-03, TC-04 e TC-04.02 existe um pacote específico de coleta da chave:
VDS, VGS, ID/IDS e temperatura do encapsulamento (Tc). Ao inserir a evidência correspondente,
o checklist da execução é marcado automaticamente.

Nomes dos Test Cases:
- O nome descritivo de cada TC pode ser editado diretamente na barra lateral pelo ícone de lápis.
- O identificador (ex.: TC-04.02) permanece fixo.
- A edição altera o nome exibido no HTML, resumo.csv e relatórios, mas não renomeia a pasta física existente; isso evita quebrar os caminhos das evidências.

Registro prévio para o relatório:
- A seção "Caracterização preliminar de componentes" possui modo de edição.
- Títulos, textos, observações e células das tabelas podem ser alterados diretamente no HTML.
- As alterações são persistidas em campanha.json e reutilizadas no relatório.
- Foi incluído um registro preliminar de resistência série dos cabos/conexões de aproximadamente 60 mΩ, totalmente editável.
- As imagens de caracterização e as figuras geradas no relatório usam tamanho mais compacto.

Gerador de relatório:
- O botão "Gerar relatório" permite selecionar vários Test Cases e quais seções entram no documento.
- O botão "Relatório deste TC" abre o mesmo gerador com o Test Case atual pré-selecionado.
- Cada imagem salva possui opção "Incluir esta imagem no relatório" e campo de legenda.
- As figuras são numeradas automaticamente em ordem de aparecimento.
- "Prévia / PDF" abre um relatório autocontido pronto para imprimir/salvar em PDF pelo navegador.
- "Exportar TEX + HTML + imagens" cria relatorio.tex, relatorio.html e uma pasta figuras, preservando os arquivos originais.

Exportação de imagens:
- "Exportar execução" copia todas as imagens salvas da combinação ativa (TC + direção + Si/SiC) para uma pasta escolhida.
- Cada grupo de componente/assunto possui um botão "Exportar" para copiar somente suas imagens.
- A exportação copia os arquivos e não altera nem apaga os originais. Itens da Lixeira não são exportados.

Nomes de formas de onda:
- Para formas de onda, o arquivo usa diretamente o sinal, sem repetir "Forma_de_onda".
- Ex.: Indutor_L1_Tensao_V_01.png, Indutor_L1_Corrente_A_01.png.
- Em Forma de onda, Assunto e Sinal aceitam seleção múltipla. "Geral · todos" é somente um atalho para marcar todas as grandezas; o arquivo salvo registra explicitamente Vin, Iin, Vout, Iout, VDS, VGS, IDS etc., sem usar "Geral" como descrição.

TC-04.02:
- É uma repetição do TC-04 para variação da frequência de comutação.
- Ao migrar uma campanha existente, a configuração do TC-04 é copiada para TC-04.02.
- Resultados, imagens, notas, simulação e estado de conclusão não são copiados.

Fluxo de evidências:
1. Selecione um ou mais Assuntos e o Tipo. Em Forma de onda, múltiplos assuntos podem compartilhar a mesma imagem.
2. Setup sempre fica disponível em Assunto. Ao selecionar Setup, o Tipo fica somente em Fotografia.
3. Para Setup, use o campo "Nome do setup / conversor" para personalizar o nome do arquivo.
4. Cole um print com Ctrl+V ou faça upload de um arquivo.
5. Ajuste o nome sugerido, se necessário.
6. Clique em "Salvar TC na pasta" para criar fisicamente os arquivos.

Simulação:
- Marque "Simulação" no Registro técnico.
- Anexe o arquivo de simulação e/ou imagens.
- Para imagens, selecione o componente e, quando aplicável, o sinal.
- Ao salvar o TC, o material é gravado na pasta Simulacao.
- A simulação pode ser adicionada em outro dia: basta abrir o HTML, selecionar a mesma pasta do projeto e continuar no mesmo Test Case.
