# Transcrição com identificação dos interlocutores

**Arquivo:** `G:\2026-10-22 15-55-55.mkv`  
**Duração:** 00:10:09

> Transcrição automática offline, revisada por contexto e características acústicas. Falas muito curtas podem exigir conferência auditiva. Termos técnicos incertos foram mantidos próximos ao reconhecimento original.

**[00:00:00] Murilo**

A MCU de qualquer forma Ela não vai receber as mensagens?

**[00:00:06] Érica**

Não, porque Não tá compilado pra RAVN, né? Se você olhar ali as mensagens Do Gateway Não tá compilado pra RAVN Só tá pros outros customers Tem que tirar a compilação específica Por isso que eu falei que precisa da modificação Porque precisa fazer E daí colocar o if de só Pra RAVN, né? De compilação pra não repassar Não fazer o Gateway Mas fazer a lógica da flag

**[00:00:36] Érica**

Entendeu? Você tá com o código aberto aí? A gente pode ver juntos

**[00:00:40] Murilo**

Deixa eu abrir Entendi

**[00:00:53] Murilo**

Abre errado Não é nessa É nessa aqui

**[00:01:53] Murilo**

Beleza

**[00:01:59] Murilo**

Tá, o que vai ter que colocar É ser um customer específico

**[00:02:06] Érica**

Isso, vai bem no começo No Gateway Default Só pra ver Que eu acho que ele tá lá O que não tava compilando Ou você já tirou?

**[00:02:19] Murilo**

Não, não

**[00:02:19] Érica**

Esse if de compilação O if de compilação Acho que tava logo em cima desse default Vai um pouquinho mais pra cima If de compilação

**[00:02:27] Murilo**

Não Tirei

**[00:02:29] Érica**

Não Tem certeza?

**[00:02:32] Murilo**

Uhum

**[00:02:33] Érica**

Deixa eu ver O código que tava aberto aqui Que eu achei que ele não tava compilando

**[00:02:52] Érica**

Question soft Ok Ah não, ele tá fora mesmo Parece que

**[00:03:02] Érica**

Não, não, não Tem que ter, não faz sentido Acho que você tirou sim, amigo

**[00:03:16] Érica**

Ou Pera, você tá na 2.27, né?

**[00:03:20] Murilo**

Tô na 2.27

**[00:03:22] Érica**

É que eu tô com a 2.30 aberta aqui Tô pensando se teria diferença 2.27 pra 2.30 Quando que a gente jogou pro Arquibis? Eu já não lembro Talvez seja da 2.30 pra frente Que tem isso

**[00:03:44] Murilo**

Hum É que tá na 2.31

**[00:03:49] Érica**

Isso Isso é fácil de ser checado depois Mas Na 2 Pelo menos a versão que eu tô aberto aqui Na 2.30.1 Ele Tem o if condicional Logo antes desse bloco Da callback do gateway default

**[00:04:09] Murilo**

Aham Bem aqui

**[00:04:11] Érica**

Isso, bem aí em cima É Ele tem o condicional

**[00:04:15] Murilo**

Pra não compilar pra RAVN

**[00:04:17] Érica**

Aham

**[00:04:17] Murilo**

Ah, tá Então, beleza

**[00:04:19] Érica**

Ok Então

**[00:04:21] Murilo**

Hum

**[00:04:23] Érica**

É aqui no caso Nesse caso que ele Que ele tá compilando Daí você só coloca É tipo o que você botou ali embaixo mesmo De só O envio A parte mesmo Se bem que se ele já tava fazendo aí pra RAVN É que não vai fazer diferença Que a gente não vai A gente não vai gerar essa versão pra RAVN Então acho que não vai precisar mexer É Talvez só botar a lógica de que a gente vai fazer isso A lógica de não enviar pra RAVN E começar a compilar de volta Só pra 2.31.1 Que é o que vai impactar pra CNH, entendeu?

**[00:04:58] Murilo**

Aham

**[00:04:59] Érica**

Então pra essa versão aí Pra 2.27.2 Pra 2.31 Deixa só Só adiciona Então só adiciona na lógica da flag E o fix lá do condicional E daí na 2.31.1 A gente coloca o Volta a compilar callback pra RAVN Mas Tira fora A parte do gateway em si

**[00:05:23] Murilo**

Tá, beleza Quando você diz tirar fora a parte do gateway

**[00:05:28] Érica**

É O CAN Send Data só O CAN Send Data não faz pra CNH Que não faz sentido

**[00:05:35] Murilo**

Ah tá, beleza Então só deixa a questão do recebimento mesmo

**[00:05:40] Érica**

Aí sim faz Isso, pra poder setar a flag Mas você entendeu o porquê, né?

**[00:05:46] Murilo**

Aham, porque Ah então, é por isso que eu tava Bati a cabeça que eu fiquei, ué, mas aqui pelo que eu entendi A RAVN vai receber É que eu não tenho Mas ali eu entendi Lá ela não vai receber o Callback

**[00:05:58] Érica**

É que eu tenho que olhar pelas entregas lá Que agora de cabeça eu não vou lembrar Mas Eu acho que foi o que a gente mudou Depois Quando foi confirmado o ST Agora A arquitetura A gente não precisa fazer o gateway Porque o ST tá no mesmo barramento Eu acho que na 2.27 não tava Eu já não vou lembrar Mas , amigo Dá pra checar isso depois, mas Se não tiver, daí Só adiciona a mesma lógica Não precisa Daí não precisa modificar o que já tava Da CNH Tipo, esse if condicional que você botou aí Não precisa, porque daí segue o geral, né? Porque a gente só vai gerar o bug fix Pra Star e pra Kaiman

**[00:06:48] Érica**

Só pra não ficar código Que não faz sentido, sabe?

**[00:06:53] Murilo**

Pera, perdão, amiga Eu tava Eu devanei Qual o if que você falou que não ia precisar?

**[00:06:58] Érica**

Esse if do BDS CAN Send Data Tipo, nessa versão, na 2.27.2 A gente não vai gerar nada pra CNH

**[00:07:06] Murilo**

Ah, tá

**[00:07:06] Érica**

Não precisa adicionar esse can

**[00:07:08] Murilo**

Ou ele já tava assim

**[00:07:10] Érica**

Ele já tava assim? Ele já tava assim

**[00:07:12] Murilo**

Aham, por isso que eu tô

**[00:07:14] Érica**

Ah, então talvez seja que a gente só jogou pra fora

**[00:07:17] Murilo**

É, a gente só jogou pra fora Só fez o Tuk

**[00:07:24] Murilo**

Tá Tava, tanto que aqui tá do

**[00:07:27] Érica**

Aham, então talvez seja que a gente só jogou pra fora

**[00:07:27] Murilo**

Tá, cadê, cadê, cadê, cadê, cadê? Tanto dois

**[00:07:30] Érica**

Aqui Então, é Então, segue o Segue o A lógica de Editar o menos possível

**[00:07:36] Murilo**

Tá bom

**[00:07:37] Érica**

Perfeito Só adicionar a lógica

**[00:07:40] Murilo**

Tá, só adicionar aqui por cima, beleza

**[00:07:44] Érica**

Perfeito Então, vai aí no teu tempo Entre hoje e amanhã É Arruma o que você achar que faz sentido Pensa aí no nome Se deixa a flag desse jeito E daí Tipo, o serviço ali As coisas, tipo Comentar melhor Botem define O que fizer sentido como define Principalmente essa lógica ali do serviço Então O onze Deixar bem explícito Que é o seu reset Ah, tá bonito Comentar ali a lógica do nibble O porquê que é o zero, zero Copia lá o que o O Adri mandou na mensagem Como explicação E tenta deixar as coisas como define Só pra ficar mais bonitinho

**[00:08:25] Murilo**

Tá bom

**[00:08:25] Érica**

E daí quando você Convergir Você me avisa Que eu olho de volta Pra Pra revisar Daí a mesma coisa Daí só extrapolar a mesma lógica Lá pro REC E pro Function Design Ficarem atualizados também Daí a lógica é amanhã A gente ficar Andando por isso Então Quando você quiser que eu revise alguma coisa Quando você quiser alinhar alguma coisa Você me avisa E enquanto eu não estiver Fazendo isso Eu vou Voltar a olhar os test cases Com a minha Com os meninos Então os meninos vão fazer a revisão O Kupka vai fazer a escrita O Igor vai fazer a revisão do teu E eu vou olhar o conteúdo dos dois Perfeito

**[00:09:08] Murilo**

Em paralelo Enquanto Tava Tava na reunião Eu tinha pedido pro Igor Só rodar um logzinho Pra ver Pra RAVN Pra ver se dava algum erro Ele falou que deu boa também lá Mas nesse na 2.27 Então Aparentemente não deu realmente problema Que é Ele tá recebendo

**[00:09:28] Érica**

Tá

**[00:09:29] Murilo**

Então Aí eu olho na 2.31 Com calma Também Tá Vou fazer as coisas 2.27

**[00:09:34] Érica**

Aham Daí a gente converge isso Amanhã Eu vou tentar dormir Com a ideia na cabeça Pra ver se eu penso em mais algum gap Que a gente não tá considerando

**[00:09:44] Murilo**

Tá bom

**[00:09:46] Érica**

Mas é que esse também Por mim Eu já caduquei Hoje Não vai sair muito mais

**[00:09:50] Murilo**

Tá bom Beleza

**[00:09:53] Érica**

Tá bom De nada, amigo Qualquer coisa avisa

**[00:09:57] Murilo**

Ok

**[00:09:57] Érica**

Tchau, tchau

**[00:09:58] Murilo**

Tchau, tchau

**[00:09:59] Érica**

Tchau

**[00:10:07] Érica [atribuição incerta]**

Tchau
