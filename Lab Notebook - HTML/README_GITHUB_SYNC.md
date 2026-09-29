# Sincronização do TCC Lab Notebook com GitHub

Versões: Lab Notebook v50 · auxiliar local 1.0.0.

1. Execute `Iniciar_TCC_Lab_Notebook.bat` e mantenha a janela do auxiliar aberta.
2. No navegador, conecte a pasta `Lab Notebook - HTML` quando solicitado.
3. Trabalhe normalmente. O autosave continua sendo local e não faz push.
4. Quando quiser publicar um estado, clique em **Sincronizar com GitHub**.

O botão primeiro conclui um checkpoint (JSONs, renomeações e imagens). Somente se essa etapa terminar sem erro o auxiliar consulta `origin/main`, cria o commit e faz push. Se o remoto estiver à frente, houver conflito ou faltar conexão, o push é interrompido sem force e os dados locais são preservados.

O auxiliar aceita apenas os endpoints fixos de status e sincronização, executa Git somente na raiz autorizada do TCC e não recebe comandos nem caminhos do HTML. Nenhuma credencial é gravada no HTML ou nesses scripts; a autenticação é fornecida pelo Git Credential Manager/GitHub Desktop do Windows.
