# Sincronização do TCC Lab Notebook com GitHub

Versões: Lab Notebook v51 · auxiliar local 1.1.0.

1. Abra o atalho **TCC Lab Notebook** na Área de Trabalho (ou execute `Iniciar_TCC_Lab_Notebook.bat` nesta pasta de ferramentas) e mantenha a janela do auxiliar aberta.
2. No navegador, conecte a pasta `Lab Notebook - HTML` quando solicitado.
3. Trabalhe normalmente. O autosave continua sendo local e não faz push.
4. Quando quiser publicar um estado, clique em **Sincronizar com GitHub**.

O botão primeiro conclui um checkpoint (JSONs, renomeações e imagens). Somente se essa etapa terminar sem erro o auxiliar consulta `origin/main`, cria o commit e faz push. Se o remoto estiver à frente, houver conflito ou faltar conexão, o push é interrompido sem force e os dados locais são preservados.

O auxiliar aceita apenas os endpoints fixos de status e sincronização, executa Git somente na raiz autorizada do TCC e não recebe comandos nem caminhos do HTML. Nenhuma credencial é gravada no HTML ou nesses scripts; a autenticação é fornecida pelo Git Credential Manager/GitHub Desktop do Windows.

Organização: o HTML ativo, `campanha.json`, os Test Cases e as evidências permanecem em `Lab Notebook - HTML`. O launcher, o auxiliar e versões anteriores do HTML ficam em `Configurações/Ferramentas/TCC Lab Notebook`.

Validação da instalação: sincronização incremental confirmada em 29/09/2026.
