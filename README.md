# 🏎️ GPX → CarSim Track Builder

**Ferramenta MATLAB para converter arquivos de GPS (.gpx) em dados de pista tridimensionais compatíveis com o CarSim.**

Desenvolvido pelo **Subsistema de Performance** da equipe FSAE **EESC-USP Tupã**.

---

## 📋 Sobre

Este projeto resolve um problema recorrente na equipe: a falta de um método preciso, científico e reprodutível para mapear pistas reais e importá-las no software de dinâmica veicular **CarSim**. Anteriormente, a geometria das curvas era estimada visualmente (usando Paint e métodos empíricos) — agora, o processo é 100% automatizado a partir de coordenadas GPS.

O software recebe um arquivo `.gpx` (padrão de intercâmbio de dados GPS), processa as coordenadas geodésicas (latitude, longitude, altitude), ajusta o traçado para o sistema de coordenadas nativo do CarSim e cria uma pasta exclusiva dentro de `output/` (no formato `<nome_da_pista>_<AAAA-MM-DD_HH-MM-SS>/`) contendo:

| Arquivo de saída | Conteúdo | Destino no CarSim |
|---|---|---|
| `rdedges.csv` | $X$ (m), $Y$ (m), $Z$ (m), Station (m) [Cabeçalho `0, 1, 2, 3`] | Road → 3D Surface / X-Y-Z Coordinates of Edges / Reference Line |
| `carsim_xyz.csv` | $X$ (m), $Y$ (m), $Z$ (m) [Cabeçalho `0, 1, 2`] | Road → X-Y-Z Coordinates (3 coordenadas) |
| `elevation.csv` | Station (m) × Elevação (m) | Road → Elevation (referência / validação) |
| `grade.csv` | Station (m) × Inclinação (%) | Road → Elevation (alternativa) |
| `track_data.mat` | Struct completa do MATLAB | Análise offline / telemetria / scripts |
| `track_diagnostics.png` | Imagem com 6 gráficos de diagnóstico | Registro visual e validação técnica |

> **Nota sobre Coordenadas 3D e Curvatura:** O CarSim possui suporte nativo à importação direta de coordenadas espaciais 3D através da tela **Road: 3D Surface (X-Y-Z Coordinates of Edges / Reference Line)** utilizando o formato `rdedges.csv` (cabeçalho `0, 1, 2, 3`). O próprio CarSim calcula a curvatura horizontal, a direção tangencial e a elevação de forma contínua e unificada, eliminando a necessidade de tabelas isoladas de curvatura e prevenindo discrepâncias numéricas entre eixos.

---

## 🧭 Referencial e Orientação Automática para o CarSim

No CarSim, o veículo é inicializado por padrão no ponto de origem $(X = 0, Y = 0, Z = 0)$ apontando no sentido positivo do eixo $X$ (Leste, heading $0^\circ$), delimitado pelas retas tracejadas do grid de referência.

Se a pista for importada com coordenadas geográficas locais puras e a reta de largada apontar para o Norte, Oeste ou diagonal, o carro inicializará fora do traçado ou virado de lado/ao contrário em relação às retas tracejadas do CarSim.

Para garantir compatibilidade imediata e sem ajustes manuais:
1. **Origem em $(0, 0, 0)$:** O primeiro ponto da pista é transladado exatamente para a origem $(X_1 = 0, Y_1 = 0, Z_1 = 0)$.
2. **Rotação Automática ($-\theta_0$):** Todas as coordenadas no plano horizontal são rotacionadas em relação à origem pelo ângulo inicial $-\theta_0$, alinhando o vetor da reta inicial rigorosamente com o eixo $+X$ (Leste).
3. **Invariância Geométrica:** A distância acumulada (Station $S$), o perfil de elevação, o *grade* e a curvatura $\kappa$ são invariantes sob translação e rotação rígida, preservando a física exata do traçado original.

---

## 🚀 Como Usar

### 1. Obtenha o arquivo GPX da pista

Desenhe o traçado da pista clicando nos pontos ao longo do percurso e exporte como `.gpx`.

> **Recomendação:** Recomendamos fortemente o uso do site **[plotaroute.com](https://www.plotaroute.com/)** (ferramenta *Create a Route*). Ele é muito mais fácil e intuitivo para traçados de Fórmula SAE (estacionamentos, kartódromos e pátios de teste) do que alternativas como o *gpx.studio*, pois conta com o modo de desenho livre (*Straight / Freehand*) sem forçar a rota a seguir vias públicas. Ao terminar, faça o download no formato **.gpx** com a elevação ativada.

### 2. Execute no MATLAB

No console do MATLAB, execute:

```matlab
gpx_to_carsim
```

Uma janela de seleção de arquivo será aberta. Selecione o arquivo `.gpx` e o script executará todo o processamento automaticamente.

### 3. Importe no CarSim (Método do Bloco de Notas)

Para garantir que o CarSim reconheça as colunas sem conflitos de formatação ou problemas de separador decimal:

1. Acesse a pasta gerada em `output/<nome_da_pista>_<data_hora>/`.
2. Abra o arquivo **`rdedges.csv`** com o **Bloco de Notas (Notepad)** (ou qualquer editor de texto simples).
3. Pressione `Ctrl + A` para selecionar todo o texto e `Ctrl + C` para copiar.
4. No CarSim, acesse o menu de pistas: **Road: 3D Surface (X-Y-Z Coordinates of Edges)** ou **Road: Centerline & Edges (X-Y-Z Coordinates)**.
5. Clique na tabela de coordenadas e cole com `Ctrl + V`. O CarSim preencherá automaticamente as colunas $X$, $Y$, $Z$ e $S$ a partir do cabeçalho `0, 1, 2, 3`.
6. Ajuste a largura da pista (*width*, tipicamente 3 metros para FSAE) e o coeficiente de atrito ($\mu$).

> **Por que usar o Bloco de Notas?** Softwares de planilha como o Microsoft Excel frequentemente convertem os pontos decimais (`.`) em vírgulas (`,`) dependendo do idioma do Windows, o que corrompe a importação no CarSim. O Bloco de Notas preserva a formatação ASCII pura e limpa do arquivo.

---

## 📐 O que o Software Calcula

1. **Conversão Geodésica** — Converte (latitude, longitude, altitude) para coordenadas cartesianas locais ($X, Y, Z$) em metros usando a aproximação de Terra plana (*flat-Earth*).

2. **Detecção e Fechamento de Circuito** — Detecta circuitos fechados e une os extremos de forma contínua, aplicando condições de contorno periódicas na suavização.

3. **Alinhamento com CarSim** — Translada a largada para $(0, 0, 0)$ e rotaciona o traçado para iniciar apontando para $+X$ (Leste).

4. **Station $S$** — Distância acumulada ao longo da linha de centro da pista (variável independente fundamental do CarSim).

5. **Bordas da Pista (RdEdges $X, Y, Z, S$)** — Formatação exata com cabeçalho `0, 1, 2, 3` no arquivo `rdedges.csv` para geração imediata da superfície 3D no CarSim.

6. **Curvatura $\kappa(S)$ e Ângulo de Direção** — Calculados analiticamente para o gráfico de diagnóstico e validação técnica:

$$\kappa = \frac{X' \cdot Y'' - Y' \cdot X''}{(X'^2 + Y'^2)^{3/2}}$$

   - $\kappa > 0 \rightarrow$ curva para a esquerda
   - $\kappa < 0 \rightarrow$ curva para a direita

7. **Inclinação Longitudinal (*Grade*)** — Inclinação em \%, obtida da derivada da elevação em relação à Station.

8. **Filtro de Suavização** — Média móvel aplicada nas coordenadas espaciais para atenuar o ruído característico do GPS antes do cálculo de derivadas.

---

## 📁 Estrutura do Projeto

```
pistas/
├── gpx_to_carsim.m            % Script principal — execute este
├── parseGPX.m                 % Parser XML de arquivos .gpx
├── geo2local.m                % Conversão geodésica → cartesiana local
├── computeTrackGeometry.m     % Motor de cálculo (Station, fechamento, curvatura, grade)
├── plotTrackDiagnostics.m     % Geração dos 6 gráficos de diagnóstico
├── guia_software_pistas.tex   % Documentação completa em LaTeX
├── Track_mapping___GUIDE.pdf  % Manual compilado em PDF
└── output/                    % Gerada automaticamente
    └── <pista>_<timestamp>/   % Pasta exclusiva por execução
        ├── rdedges.csv        % Tabela 3D + Station para o CarSim (0, 1, 2, 3)
        ├── carsim_xyz.csv     % Coordenadas 3D (0, 1, 2)
        ├── elevation.csv      % Station vs Elevação
        ├── grade.csv          % Station vs Inclinação (%)
        ├── track_data.mat     % Struct completa do MATLAB
        └── track_diagnostics.png % Imagem dos gráficos de diagnóstico
```

---

## ⚙️ Configuração

O único parâmetro ajustável pelo usuário encontra-se no início de `gpx_to_carsim.m`:

```matlab
SMOOTH_WINDOW = 5;  % Tamanho da janela de média móvel (em pontos)
```

| Valor | Efeito |
|---|---|
| 3 | Preserva curvas muito fechadas (*hairpins*), porém mais suscetível a ruídos |
| **5** | **Equilíbrio padrão recomendado** |
| 7+ | Curvas bastante suaves, pode arredondar vértices fechados |

---

## 📊 Gráficos de Diagnóstico

O script gera automaticamente uma figura com 6 subplots (salva como `track_diagnostics.png` na pasta da pista):

| Painel | Descrição |
|---|---|
| **Mapa XY** | Vista superior com trajetória bruta vs suavizada e alinhamento no referencial CarSim |
| **Vista 3D** | Pista no espaço tridimensional com gradiente de cor por elevação |
| **Curvatura vs Station** | Perfil de curvatura $\kappa$ com raio de curva $R$ no eixo secundário |
| **Elevação vs Station** | Perfil longitudinal de altitude e variação $\Delta Z$ |
| **Grade vs Station** | Inclinação longitudinal (%) ao longo do percurso |
| **Heading vs Station** | Ângulo de direção da trajetória (em graus, iniciando em $0^\circ$) |

---

## 📝 Requisitos

- **MATLAB** R2020b ou superior (não requer toolboxes pagas adicionais)
- **CarSim** (para simulação veicular da pista)
- Navegador web (para acessar o [plotaroute.com](https://www.plotaroute.com/) ou [gpx.studio](https://gpx.studio/))

---

## 📖 Documentação Completa

O manual detalhado com formulação matemática, equações, alinhamento de referencial e guia de importação está disponível nos arquivos:

* 📄 Código-fonte: [`guia_software_pistas.tex`](guia_software_pistas.tex)
* 📕 Documento PDF compilado: [`Track_mapping___GUIDE.pdf`](Track_mapping___GUIDE.pdf)

---

## 👤 Autor

**Eduardo Yumoto Carvalheira** — Gerente de Performance

Equipe FSAE EESC-USP Tupã | São Carlos, SP
