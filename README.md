# TCC — Conversores CC-CC para aplicações espaciais

Repositório privado de trabalho do TCC, dedicado ao estudo, à simulação e à validação experimental de conversores CC-CC, com ênfase em topologias Cuk e multifásicas para aplicações espaciais.

Este repositório reúne o desenvolvimento do projeto e o acervo técnico utilizado na pesquisa: modelos de simulação, análises matemáticas, resultados experimentais, imagens, planilhas, artigos, livros, apostilas e normas.

## Estrutura do repositório

- `Analise Matematica/`: cálculos e desenvolvimento analítico.
- `Simulacao/`: modelos, versões anteriores e resultados de simulação.
- `Lab Notebook - HTML/`: caderno de laboratório, campanhas, dados e evidências experimentais.
- `Aquisições/`, `Estatisticas/` e `Imagens/`: dados adquiridos, planilhas e material visual.
- `Artigos/`, `Apostilas/`, `Livros/`, `Normas/` e `Notícias/`: referências e acervo bibliográfico.
- `LibreOffice/`: documentos de trabalho produzidos no LibreOffice.
- Arquivos `.psimsch` e `.smv` na raiz: esquemáticos e modelos principais do projeto.

## Como obter uma cópia completa

O projeto usa [Git LFS](https://git-lfs.com/) para arquivos grandes de simulação (`.smv`) e arquivos compactados (`.zip`). Instale e habilite o Git LFS antes de clonar:

```bash
git lfs install
git clone https://github.com/bmuoli/TCC.git
cd TCC
git lfs pull
```

## Atualização do repositório

Antes de enviar alterações, sincronize a cópia local e confira o que será incluído:

```bash
git pull --rebase
git add -A
git status
git commit -m "Descreva a alteração"
git push origin main
```

## Observações

- O repositório deve permanecer privado, pois contém materiais de pesquisa, dados de laboratório e documentos de referência de terceiros.
- Credenciais, chaves, arquivos temporários e o estado transitório do auxiliar de sincronização permanecem fora do versionamento por meio do `.gitignore`.
- Os documentos de terceiros são mantidos neste repositório exclusivamente como acervo de apoio acadêmico. Os direitos autorais continuam pertencendo aos respectivos autores e instituições.

