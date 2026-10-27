# Lab Notebook público

Esta pasta contém a visualização pública, somente de leitura, do Lab Notebook.

- A interface editorial continua em `Lab Notebook - HTML/TCC_Lab_Notebook_v51.html`.
- O painel público lê `Lab Notebook - HTML/campanha.json` diretamente da branch `main`.
- Testes e execuções sem medições, curvas ou evidências são ocultados automaticamente.
- Evidências marcadas como excluídas do relatório (`reportInclude: false`) não aparecem no painel.
- O workflow `.github/workflows/public-lab-pages.yml` publica esta pasta no GitHub Pages após cada push para `main`.
- Durante a publicação, a versão atual de `campanha.json` e somente as evidências vinculadas e permitidas no relatório são incluídas no site.

URL esperada depois de habilitar **Settings → Pages → Source: GitHub Actions**:

`https://bmuoli.github.io/TCC/`
