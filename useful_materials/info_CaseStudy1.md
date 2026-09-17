innanzitutto ho pensato che non ha senso mettere CRIq come variabile target, ma di metterla al posto dell'educazione (più completa) e di mettere quindi come test NPSI di outcome MoCa, Matrici Attentive e APACS. Spero di non scombinarti troppo il lavoro. Gli ERP rimangono sempre gli stessi (N400 e P300 latenza/ampiezza) (farei entrambe le cose ale per completezza). Sti cambiamenti perchè in letteratura davvero c'è davvero poco come correlazioni tra i test che abbiamo scelto inizialmente e erp. 

Andando sul tecnico

*Logica di fondo*
Essendo che abbiamo una popolazione con ictus ischemico destro (PATHS), la lesione è il driver principale della variabilità: più è grave, più si abbassano linguaggio e attenzione, e di conseguenza i test e gli ERP. Usiamo due "abilità nascoste" (linguaggio e attenzione) solo come motore interno: NON vanno esportate nel CSV (Dataset-Case1), servono solo a generare i numeri correlati.

Passo 1 — variabili di base (da SALVARE)
• `gravita_lesione`: random 0–10 (10 = più grave)
• `eta`: random 50–80
• `sesso`: random 0/1
• `criq`: random 70–130 (media ~100), debolmente anticorrelato con età -> ho pensato che va a sostuire l'education

*Passo 2 — abilità nascoste (NON salvare)*
• `abilita_linguaggio` = − gravita_lesione (forte) − eta (debole) + rumore
• `abilita_attenzione` = − gravita_lesione (forte) − eta (debole) + rumore

*Passo 3 — ERP e test (tutti da SALVARE)*
Ognuno = formula lineare delle variabili sopra + rumore gaussiano. "+" alza, "−" abbassa.
• `n400_ampiezza` = + abilita_linguaggio
• `n400_latenza` = − abilita_linguaggio, + eta
• `p300_ampiezza` = + abilita_attenzione
• `p300_latenza` = − abilita_attenzione, + eta
• `apacs` = + abilita_linguaggio, + criq, − eta
• `matrici_attentive` = + abilita_attenzione, + criq, − eta
• `moca` = + abilita_linguaggio (debole), + abilita_attenzione (debole), − eta

*Range realistici*
• n400_ampiezza 1–6 µV · n400_latenza 350–500 ms
• p300_ampiezza 5–20 µV · p300_latenza 300–450 ms (fino a 500 per i più gravi)
• apacs / matrici_attentive / moca: scala 0–100

*Specifico popolazione clinica*: le distribuzioni di apacs, matrici_attentive e moca vanno spostate verso il basso, con una coda di valori bassi (pazienti più colpiti) — non simmetriche attorno a un valore alto. Latenze ERP verso l'estremo alto per i pazienti più gravi.

*Target dei coefficienti* (regressione `outcome ~ ERP + eta + sesso + criq`, β standardizzati, n ≈ 60):
• p300_latenza → matrici_attentive ≈ −0.32
• p300_ampiezza → matrici_attentive ≈ +0.30
• n400_latenza → apacs ≈ −0.30
• n400_ampiezza → apacs ≈ +0.18 (volutamente debole)
• eta ≈ −0.35 e criq ≈ +0.30 su ogni test
• sesso ≈ 0 ovunque

*Taratura rumore*: più rumore = coefficienti più bassi. Regola finché l'R² di ogni regressione sta tra 0.25 e 0.40 (non oltre, altrimenti sembra finto).

Da esportare nel CSV*: gravita_lesione, eta, sesso, criq + le colonne di ERP/test. NON esportare le due abilità nascoste.